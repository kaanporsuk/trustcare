#!/usr/bin/env python3
"""Validate one translated i18n JSON file before importing into Localizable.xcstrings."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable

PLACEHOLDER_PATTERN = re.compile(
    r"%#@[^@]+@|%(?:\d+\$)?[+#0\- ']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|L|z|j|t|q)?[@dDuUxXoOfeEgGcCsSpaAF%]"
)


def extract_placeholders(text: str) -> Counter[str]:
    """Extract printf/plural placeholders as a multiset, excluding escaped percent signs."""
    tokens = []
    for match in PLACEHOLDER_PATTERN.finditer(text):
        token = match.group(0)
        if token == "%%":
            continue
        tokens.append(token)
    return Counter(tokens)


def load_entries(file_path: Path) -> Iterable[dict[str, object]]:
    payload = json.loads(file_path.read_text(encoding="utf-8"))
    entries = payload.get("entries", [])
    if not isinstance(entries, list):
        raise ValueError("JSON payload must contain an 'entries' list.")
    return entries


def validate_entries(entries: Iterable[dict[str, object]], lang: str) -> list[str]:
    errors: list[str] = []

    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"Entry #{index} is not an object.")
            continue

        key = entry.get("key")
        en_text = entry.get("en")
        locked = bool(entry.get("locked", False))

        if not isinstance(key, str) or not key:
            errors.append(f"Entry #{index} has invalid or empty 'key'.")
            continue

        if locked:
            continue

        if not isinstance(en_text, str):
            errors.append(f"Key '{key}': missing or invalid 'en' source text.")
            continue

        translation = entry.get(lang)
        if not isinstance(translation, str) or not translation.strip():
            errors.append(f"Key '{key}': missing or empty '{lang}' translation while locked=false.")
            continue

        en_placeholders = extract_placeholders(en_text)
        tr_placeholders = extract_placeholders(translation)
        if en_placeholders != tr_placeholders:
            errors.append(
                "Key '{key}': placeholder mismatch for '{lang}'. expected={expected} got={got}".format(
                    key=key,
                    lang=lang,
                    expected=sorted(en_placeholders.elements()),
                    got=sorted(tr_placeholders.elements()),
                )
            )

    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate one translated language JSON file.")
    parser.add_argument("file_path", help="Path to docs/i18n/strings_<lang>.json")
    parser.add_argument("language_code", help="Target language code (e.g. tr, de)")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    file_path = Path(args.file_path)
    lang = args.language_code.strip()

    if lang == "en":
        print("Validation skipped: language 'en' is not importable.")
        return 0

    if not file_path.exists():
        print(f"ERROR: File not found: {file_path}", file=sys.stderr)
        return 2

    try:
        entries = load_entries(file_path)
        errors = validate_entries(entries, lang)
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: Failed to validate {file_path}: {exc}", file=sys.stderr)
        return 2

    if errors:
        print(f"ERROR: Validation failed for language '{lang}' in {file_path}", file=sys.stderr)
        for err in errors:
            print(f" - {err}", file=sys.stderr)
        return 1

    print(f"Validation passed: {lang} ({file_path})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
