#!/usr/bin/env python3
"""Import my_reviews_empty_subtitle translations from 7Feb perfected files into Localizable.xcstrings."""

from __future__ import annotations

import json
from pathlib import Path

LOCALES = ["cs", "da", "de", "es", "fr", "hu", "it", "nl", "pl", "pt", "ro", "ru", "sv", "tr", "uk"]
KEY = "my_reviews_empty_subtitle"


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    package_root = repo_root / "docs" / "7Feb_Translations"
    master_path = package_root / "trustcare_translation_source_master.json"
    xcstrings_path = repo_root / "TrustCare" / "Localizable.xcstrings"

    master = json.loads(master_path.read_text(encoding="utf-8"))
    ui_entries = master.get("ui_strings", [])
    english_value = None
    for row in ui_entries:
        if row.get("key") == KEY:
            english_value = row.get("english_label")
            break
    if not isinstance(english_value, str) or not english_value.strip():
        raise ValueError(f"Missing English UI reference for key '{KEY}' in source master")

    by_locale: dict[str, str] = {}
    for locale in LOCALES:
        source_path = package_root / f"trustcare_translation_{locale}_perfected.json"
        data = json.loads(source_path.read_text(encoding="utf-8"))
        translated = None
        for row in data.get("ui_strings", []):
            if row.get("key") == KEY:
                translated = row.get("translated_label")
                break
        if not isinstance(translated, str) or not translated.strip():
            raise ValueError(f"Missing translated label for {locale}:{KEY}")
        by_locale[locale] = translated.strip()

    xcstrings = json.loads(xcstrings_path.read_text(encoding="utf-8"))
    strings = xcstrings.setdefault("strings", {})
    entry = strings.setdefault(KEY, {})
    localizations = entry.setdefault("localizations", {})

    localizations["en"] = {
        "stringUnit": {
            "state": "new",
            "value": english_value.strip(),
        }
    }

    for locale, value in by_locale.items():
        localizations[locale] = {
            "stringUnit": {
                "state": "translated",
                "value": value,
            }
        }

    xcstrings_path.write_text(json.dumps(xcstrings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("Imported UI key into Localizable.xcstrings")
    print(f"- key: {KEY}")
    print(f"- locales: {len(LOCALES)} + en")


if __name__ == "__main__":
    main()
