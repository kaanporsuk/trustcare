#!/usr/bin/env python3
"""Export English localization strings from Localizable.xcstrings for translation workflows."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path


LANGUAGES = [
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


def extract_string_unit_value(node: object) -> str | None:
    """Recursively look for a stringUnit value in xcstrings node variants."""
    if not isinstance(node, dict):
        return None

    string_unit = node.get("stringUnit")
    if isinstance(string_unit, dict):
        value = string_unit.get("value")
        if isinstance(value, str):
            return value

    variations = node.get("variations")
    if isinstance(variations, dict):
        for variation_bucket in variations.values():
            if isinstance(variation_bucket, dict):
                for variant_node in variation_bucket.values():
                    found = extract_string_unit_value(variant_node)
                    if found is not None:
                        return found

    for value in node.values():
        found = extract_string_unit_value(value)
        if found is not None:
            return found

    return None


def load_english_entries(catalog_path: Path) -> list[dict[str, object]]:
    data = json.loads(catalog_path.read_text(encoding="utf-8"))
    strings = data.get("strings", {})
    if not isinstance(strings, dict):
        return []

    extracted: list[tuple[str, str]] = []
    for key, payload in strings.items():
        if not isinstance(key, str) or not isinstance(payload, dict):
            continue

        localizations = payload.get("localizations")
        if not isinstance(localizations, dict):
            continue

        en_payload = localizations.get("en")
        en_value = extract_string_unit_value(en_payload)
        if isinstance(en_value, str):
            extracted.append((key, en_value))

    extracted.sort(key=lambda item: item[0])

    return [
        {"key": key, "en": value, "context": [], "note": ""}
        for key, value in extracted
    ]


def collect_swift_files(root: Path) -> list[Path]:
    trustcare_dir = root / "TrustCare"
    return sorted(
        path
        for path in trustcare_dir.rglob("*.swift")
        if path.is_file()
    )


def attach_context(entries: list[dict[str, object]], swift_files: list[Path], root: Path) -> None:
    file_contents: list[tuple[Path, str]] = []
    for swift_file in swift_files:
        try:
            file_contents.append((swift_file, swift_file.read_text(encoding="utf-8")))
        except UnicodeDecodeError:
            file_contents.append((swift_file, swift_file.read_text(encoding="utf-8", errors="ignore")))

    for entry in entries:
        key = entry.get("key")
        if not isinstance(key, str) or not key:
            entry["context"] = []
            continue

        matches = set()
        for swift_file, contents in file_contents:
            if key in contents:
                matches.add(str(swift_file.relative_to(root)))

        entry["context"] = sorted(matches)


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    catalog_path = repo_root / "TrustCare" / "Localizable.xcstrings"
    output_path = repo_root / "Docs" / "i18n" / "strings_en.json"

    entries = load_english_entries(catalog_path)
    swift_files = collect_swift_files(repo_root)
    attach_context(entries, swift_files, repo_root)

    payload = {
        "meta": {
            "app": "TrustCare",
            "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "languages": LANGUAGES,
        },
        "entries": entries,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
