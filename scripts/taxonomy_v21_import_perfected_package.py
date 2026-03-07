#!/usr/bin/env python3
"""Import 7Feb perfected translation package into active TaxonomyV21 runtime resources.

Uses existing locale import pipeline (taxonomy_v21_import_locale.py) after converting
package shape into canonical labels/aliases payloads keyed by canonical ID.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any

LOCALES = ["cs", "da", "de", "es", "fr", "hu", "it", "nl", "pl", "pt", "ro", "ru", "sv", "tr", "uk"]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def canonical_ids_from_proposal(proposal: dict[str, Any]) -> tuple[list[str], set[str]]:
    taxonomy_ids = [
        item["canonical_id"]
        for bucket in ("specialties", "treatment_procedures", "facility_types")
        for item in proposal["taxonomy"][bucket]
    ]
    concern_ids = [item["canonical_id"] for item in proposal["symptom_concern_domains"]]
    all_ids = sorted(set(taxonomy_ids + concern_ids))
    return all_ids, set(concern_ids)


def ensure_no_duplicate_ids(rows: list[dict[str, Any]], field_name: str, locale: str) -> None:
    ids = [row.get("canonical_id") for row in rows]
    dups = sorted({value for value in ids if ids.count(value) > 1})
    if dups:
        raise ValueError(f"[{locale}] duplicate canonical_id in {field_name}: {dups}")


def build_payload(locale_data: dict[str, Any], canonical_ids: list[str], concern_ids: set[str], locale: str) -> dict[str, Any]:
    taxonomy_labels = locale_data.get("taxonomy_labels", [])
    concern_labels = locale_data.get("concern_labels", [])
    taxonomy_aliases = locale_data.get("taxonomy_aliases", [])
    concern_examples = locale_data.get("concern_example_inputs", [])

    if not isinstance(taxonomy_labels, list):
        raise ValueError(f"[{locale}] taxonomy_labels must be a list")
    if not isinstance(concern_labels, list):
        raise ValueError(f"[{locale}] concern_labels must be a list")
    if not isinstance(taxonomy_aliases, list):
        raise ValueError(f"[{locale}] taxonomy_aliases must be a list")
    if not isinstance(concern_examples, list):
        raise ValueError(f"[{locale}] concern_example_inputs must be a list")

    ensure_no_duplicate_ids(taxonomy_labels, "taxonomy_labels", locale)
    ensure_no_duplicate_ids(concern_labels, "concern_labels", locale)
    ensure_no_duplicate_ids(taxonomy_aliases, "taxonomy_aliases", locale)
    ensure_no_duplicate_ids(concern_examples, "concern_example_inputs", locale)

    labels: dict[str, str] = {}
    for row in taxonomy_labels:
        canonical_id = row.get("canonical_id")
        translated = row.get("translated_label")
        if not isinstance(canonical_id, str):
            raise ValueError(f"[{locale}] taxonomy_labels has non-string canonical_id")
        if not isinstance(translated, str) or not translated.strip():
            raise ValueError(f"[{locale}] empty translated_label for {canonical_id}")
        labels[canonical_id] = translated.strip()

    for row in concern_labels:
        canonical_id = row.get("canonical_id")
        translated = row.get("translated_label")
        if not isinstance(canonical_id, str):
            raise ValueError(f"[{locale}] concern_labels has non-string canonical_id")
        if not isinstance(translated, str) or not translated.strip():
            raise ValueError(f"[{locale}] empty concern translated_label for {canonical_id}")
        labels[canonical_id] = translated.strip()

    aliases: dict[str, list[str]] = {canonical_id: [] for canonical_id in canonical_ids}

    for row in taxonomy_aliases:
        canonical_id = row.get("canonical_id")
        translated = row.get("translated_aliases", [])
        if not isinstance(canonical_id, str):
            raise ValueError(f"[{locale}] taxonomy_aliases has non-string canonical_id")
        if not isinstance(translated, list):
            raise ValueError(f"[{locale}] taxonomy_aliases translated_aliases must be a list for {canonical_id}")
        cleaned = [value.strip() for value in translated if isinstance(value, str) and value.strip()]
        aliases[canonical_id] = cleaned

    for row in concern_examples:
        canonical_id = row.get("canonical_id")
        translated = row.get("translated_example_inputs", [])
        if not isinstance(canonical_id, str):
            raise ValueError(f"[{locale}] concern_example_inputs has non-string canonical_id")
        if canonical_id not in concern_ids:
            raise ValueError(f"[{locale}] concern_example_inputs has unknown concern id {canonical_id}")
        if not isinstance(translated, list):
            raise ValueError(f"[{locale}] concern_example_inputs translated_example_inputs must be a list for {canonical_id}")
        cleaned = [value.strip() for value in translated if isinstance(value, str) and value.strip()]
        if not cleaned:
            raise ValueError(f"[{locale}] concern_example_inputs empty for {canonical_id}")
        aliases[canonical_id] = cleaned

    expected = set(canonical_ids)
    actual = set(labels.keys())
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing:
        raise ValueError(f"[{locale}] missing label IDs: {missing}")
    if extra:
        raise ValueError(f"[{locale}] unknown label IDs: {extra}")

    alias_actual = set(aliases.keys())
    alias_missing = sorted(expected - alias_actual)
    alias_extra = sorted(alias_actual - expected)
    if alias_missing:
        raise ValueError(f"[{locale}] missing alias IDs: {alias_missing}")
    if alias_extra:
        raise ValueError(f"[{locale}] unknown alias IDs: {alias_extra}")

    return {
        "meta": {
            "locale": locale,
            "source": "docs/7Feb_Translations",
        },
        "labels": {canonical_id: labels[canonical_id] for canonical_id in canonical_ids},
        "aliases": {canonical_id: aliases[canonical_id] for canonical_id in canonical_ids},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Import perfected locale package into TaxonomyV21 runtime")
    parser.add_argument("--dry-run", action="store_true", help="Validate package and generated payloads only")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    package_root = repo_root / "docs" / "7Feb_Translations"
    proposal_path = repo_root / "docs" / "taxonomy" / "trustcare_taxonomy_v2_1_proposal.json"
    importer_path = repo_root / "scripts" / "taxonomy_v21_import_locale.py"
    temp_root = repo_root / "docs" / "7Feb_Translations" / "_generated_import_payloads"

    proposal = load_json(proposal_path)
    canonical_ids, concern_ids = canonical_ids_from_proposal(proposal)

    temp_root.mkdir(parents=True, exist_ok=True)

    for locale in LOCALES:
        source_path = package_root / f"trustcare_translation_{locale}_perfected.json"
        if not source_path.exists():
            raise FileNotFoundError(f"Missing source file: {source_path}")

        source_data = load_json(source_path)
        payload = build_payload(source_data, canonical_ids, concern_ids, locale)

        generated_path = temp_root / f"taxonomy_v21_import_{locale}.json"
        generated_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        cmd = [
            "python3",
            str(importer_path),
            "--locale",
            locale,
            "--input",
            str(generated_path),
            "--source-tag",
            "7feb_perfected_import",
        ]
        if args.dry_run:
            cmd.append("--dry-run")

        subprocess.run(cmd, check=True, cwd=repo_root)

    print("Completed perfected package import")
    print(f"- locales: {len(LOCALES)}")
    print(f"- payloads: {temp_root.relative_to(repo_root)}")
    print(f"- mode: {'dry-run' if args.dry_run else 'write'}")


if __name__ == "__main__":
    main()
