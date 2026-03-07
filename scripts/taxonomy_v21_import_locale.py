#!/usr/bin/env python3
"""Import localized taxonomy v2.1 labels/aliases by canonical ID.

This script updates locale runtime files under TrustCare/Resources/TaxonomyV21 and enforces:
- canonical-ID keyed imports only
- no English overwrite
- deterministic sorted output
- strict canonical coverage validation
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

SHIPPED_LOCALES = [
    "en",
    "tr",
    "de",
    "pl",
    "nl",
    "da",
    "es",
    "fr",
    "it",
    "ro",
    "pt",
    "uk",
    "ru",
    "sv",
    "cs",
    "hu",
]


class DuplicateKeyError(ValueError):
    pass


def no_duplicate_pairs_hook(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"Duplicate key '{key}' detected in JSON input")
        result[key] = value
    return result


def load_json_no_duplicates(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=no_duplicate_pairs_hook)


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def canonical_ids_from_proposal(proposal: dict[str, Any]) -> list[str]:
    taxonomy = proposal["taxonomy"]
    concern_domains = proposal["symptom_concern_domains"]

    ids = [
        item["canonical_id"]
        for bucket in ("specialties", "treatment_procedures", "facility_types")
        for item in taxonomy[bucket]
    ]
    ids.extend(item["canonical_id"] for item in concern_domains)
    return sorted(set(ids))


def normalize_labels(payload: dict[str, Any]) -> dict[str, str]:
    if "entries" in payload:
        entries = payload["entries"]
        if not isinstance(entries, list):
            raise ValueError("'entries' must be a list")

        labels: dict[str, str] = {}
        for entry in entries:
            if not isinstance(entry, dict):
                raise ValueError("Each entry must be an object")
            canonical_id = entry.get("canonical_id")
            label = entry.get("label")
            if not isinstance(canonical_id, str):
                raise ValueError("Each entry must include string canonical_id")
            if canonical_id in labels:
                raise ValueError(f"Duplicate canonical_id '{canonical_id}' in entries")
            if not isinstance(label, str):
                raise ValueError(f"Entry {canonical_id} must include string label")
            labels[canonical_id] = label
        return labels

    labels = payload.get("labels")
    if not isinstance(labels, dict):
        raise ValueError("Input must contain either 'entries' list or 'labels' object")

    normalized: dict[str, str] = {}
    for key, value in labels.items():
        if not isinstance(key, str):
            raise ValueError("Label keys must be strings")
        if not isinstance(value, str):
            raise ValueError(f"Label value for {key} must be a string")
        normalized[key] = value
    return normalized


def normalize_aliases(payload: dict[str, Any]) -> dict[str, list[str]] | None:
    if "aliases" not in payload and "entries" not in payload:
        return None

    if "aliases" in payload:
        aliases_obj = payload["aliases"]
        if not isinstance(aliases_obj, dict):
            raise ValueError("'aliases' must be an object when present")
        normalized: dict[str, list[str]] = {}
        for key, value in aliases_obj.items():
            if not isinstance(key, str):
                raise ValueError("Alias keys must be strings")
            if not isinstance(value, list):
                raise ValueError(f"Alias value for {key} must be an array")
            cleaned = []
            for alias in value:
                if not isinstance(alias, str):
                    raise ValueError(f"Alias entries for {key} must be strings")
                trimmed = alias.strip()
                if not trimmed:
                    raise ValueError(f"Alias entries for {key} cannot be empty")
                cleaned.append(trimmed)
            normalized[key] = cleaned
        return normalized

    entries = payload["entries"]
    aliases: dict[str, list[str]] = {}
    for entry in entries:
        canonical_id = entry.get("canonical_id")
        if not isinstance(canonical_id, str):
            raise ValueError("Each entry must include string canonical_id")
        values = entry.get("aliases", [])
        if not isinstance(values, list):
            raise ValueError(f"Entry {canonical_id} aliases must be an array")
        cleaned = []
        for alias in values:
            if not isinstance(alias, str):
                raise ValueError(f"Alias entries for {canonical_id} must be strings")
            trimmed = alias.strip()
            if not trimmed:
                raise ValueError(f"Alias entries for {canonical_id} cannot be empty")
            cleaned.append(trimmed)
        aliases[canonical_id] = cleaned
    return aliases


def validate_exact_id_set(id_to_value: dict[str, Any], canonical_ids: list[str], value_label: str) -> None:
    expected = set(canonical_ids)
    actual = set(id_to_value.keys())

    missing = sorted(expected - actual)
    extra = sorted(actual - expected)

    if missing:
        raise ValueError(f"Missing {value_label} IDs: {missing}")
    if extra:
        raise ValueError(f"Unknown {value_label} IDs: {extra}")


def dedupe_keep_order(values: list[str]) -> list[str]:
    seen = set()
    ordered: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        ordered.append(value)
    return ordered


def main() -> None:
    parser = argparse.ArgumentParser(description="Import v2.1 locale labels/aliases by canonical ID")
    parser.add_argument("--locale", required=True, help="Target locale code, e.g. tr")
    parser.add_argument("--input", required=True, help="Path to import JSON payload")
    parser.add_argument("--source-tag", default="manual_translation_import", help="Source tag for metadata")
    parser.add_argument("--dry-run", action="store_true", help="Validate only, do not write files")
    args = parser.parse_args()

    locale = args.locale.strip().lower()
    if locale not in SHIPPED_LOCALES:
        raise SystemExit(f"Unsupported locale '{locale}'. Allowed: {SHIPPED_LOCALES}")
    if locale == "en":
        raise SystemExit("Refusing to import into 'en'. English source is proposal-governed and immutable here.")

    repo_root = Path(__file__).resolve().parents[1]
    proposal_path = repo_root / "docs" / "taxonomy" / "trustcare_taxonomy_v2_1_proposal.json"
    labels_path = repo_root / "TrustCare" / "Resources" / "TaxonomyV21" / "labels" / f"taxonomy_v21_locale_labels_{locale}.json"
    aliases_path = repo_root / "TrustCare" / "Resources" / "TaxonomyV21" / "aliases" / f"taxonomy_v21_aliases_{locale}.json"
    payload_path = (repo_root / args.input).resolve() if not Path(args.input).is_absolute() else Path(args.input)

    proposal = load_json_no_duplicates(proposal_path)
    canonical_ids = canonical_ids_from_proposal(proposal)

    payload = load_json_no_duplicates(payload_path)
    if not isinstance(payload, dict):
        raise SystemExit("Import payload must be a JSON object")

    labels = normalize_labels(payload)
    validate_exact_id_set(labels, canonical_ids, "label")

    for canonical_id, label in labels.items():
        if not label.strip():
            raise SystemExit(f"Empty label value for {canonical_id}")

    aliases = normalize_aliases(payload)
    if aliases is not None:
        validate_exact_id_set(aliases, canonical_ids, "alias")
        aliases = {key: dedupe_keep_order(value) for key, value in aliases.items()}

    existing_alias_payload = load_json_no_duplicates(aliases_path)
    if aliases is None:
        existing_aliases = existing_alias_payload.get("aliases")
        if not isinstance(existing_aliases, dict):
            raise SystemExit(f"Existing aliases file malformed: {aliases_path}")
        aliases = {
            canonical_id: list(existing_aliases.get(canonical_id, []))
            for canonical_id in canonical_ids
        }

    labels_payload = {
        "meta": {
            "version": "taxonomy_v2_1",
            "locale": locale,
            "entry_count": len(canonical_ids),
            "status": "imported",
            "source": str(payload_path.relative_to(repo_root)),
            "source_tag": args.source_tag,
        },
        "labels": {canonical_id: labels[canonical_id].strip() for canonical_id in canonical_ids},
    }

    aliases_payload = {
        "meta": {
            "version": "taxonomy_v2_1",
            "locale": locale,
            "entry_count": len(canonical_ids),
            "status": "imported",
            "source": str(payload_path.relative_to(repo_root)),
            "source_tag": args.source_tag,
        },
        "aliases": {canonical_id: aliases[canonical_id] for canonical_id in canonical_ids},
    }

    if args.dry_run:
        print("Validated locale import payload")
        print(f"- locale: {locale}")
        print(f"- canonical IDs: {len(canonical_ids)}")
        print(f"- labels: {len(labels_payload['labels'])}")
        print(f"- aliases: {len(aliases_payload['aliases'])}")
        return

    write_json(labels_path, labels_payload)
    write_json(aliases_path, aliases_payload)

    print("Imported taxonomy locale files")
    print(f"- locale: {locale}")
    print(f"- labels: {labels_path.relative_to(repo_root)}")
    print(f"- aliases: {aliases_path.relative_to(repo_root)}")


if __name__ == "__main__":
    main()
