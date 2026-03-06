#!/usr/bin/env python3
"""Import one translated i18n JSON file into TrustCare/Localizable.xcstrings."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import one language into Localizable.xcstrings.")
    parser.add_argument("file_path", help="Path to docs/i18n/strings_<lang>.json")
    parser.add_argument("language_code", help="Target language code (e.g. tr, de)")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    file_path = Path(args.file_path)
    lang = args.language_code.strip()

    if lang == "en":
        print("language=en imported_count=0 skipped_locked=0 missing_keys=0")
        return 0

    repo_root = Path(__file__).resolve().parents[1]
    catalog_path = repo_root / "TrustCare" / "Localizable.xcstrings"

    if not file_path.exists():
        print(f"ERROR: File not found: {file_path}", file=sys.stderr)
        return 2
    if not catalog_path.exists():
        print(f"ERROR: Catalog not found: {catalog_path}", file=sys.stderr)
        return 2

    try:
        source_payload = json.loads(file_path.read_text(encoding="utf-8"))
        entries = source_payload.get("entries", [])
        if not isinstance(entries, list):
            raise ValueError("Source file must contain an 'entries' list.")

        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        strings = catalog.get("strings")
        if not isinstance(strings, dict):
            raise ValueError("Localizable.xcstrings must contain a 'strings' object.")
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: Failed to load JSON: {exc}", file=sys.stderr)
        return 2

    imported_count = 0
    skipped_locked = 0
    missing_keys = 0

    for entry in entries:
        if not isinstance(entry, dict):
            continue

        key = entry.get("key")
        if not isinstance(key, str) or not key:
            continue

        if bool(entry.get("locked", False)):
            skipped_locked += 1
            continue

        translation = entry.get(lang)
        if not isinstance(translation, str) or not translation.strip():
            continue

        string_payload = strings.get(key)
        if not isinstance(string_payload, dict):
            missing_keys += 1
            continue

        localizations = string_payload.setdefault("localizations", {})
        if not isinstance(localizations, dict):
            localizations = {}
            string_payload["localizations"] = localizations

        localizations[lang] = {
            "stringUnit": {
                "state": "translated",
                "value": translation,
            }
        }
        imported_count += 1

    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        f"language={lang} imported_count={imported_count} "
        f"skipped_locked={skipped_locked} missing_keys={missing_keys}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
