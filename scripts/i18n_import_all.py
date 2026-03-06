#!/usr/bin/env python3
"""Validate and import all translated docs/i18n/strings_*.json files."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


LANG_FILE_PATTERN = re.compile(r"^strings_([a-z]{2})\.json$")


def infer_language_code(file_name: str) -> str | None:
    match = LANG_FILE_PATTERN.match(file_name)
    if not match:
        return None
    return match.group(1)


def run_script(script_path: Path, file_path: Path, lang: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(script_path), str(file_path), lang],
        capture_output=True,
        text=True,
    )


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    docs_i18n_dir = repo_root / "docs" / "i18n"

    validate_script = repo_root / "scripts" / "i18n_validate_one_language.py"
    import_script = repo_root / "scripts" / "i18n_import_one_language.py"

    if not docs_i18n_dir.exists():
        print(f"ERROR: Missing directory: {docs_i18n_dir}", file=sys.stderr)
        return 2

    files = sorted(docs_i18n_dir.glob("strings_*.json"))
    if not files:
        print(f"ERROR: No strings_*.json files found in {docs_i18n_dir}", file=sys.stderr)
        return 2

    print("Import summary:")

    for file_path in files:
        lang = infer_language_code(file_path.name)
        if lang is None:
            continue
        if lang == "en":
            continue

        validate_result = run_script(validate_script, file_path, lang)
        if validate_result.returncode != 0:
            if validate_result.stdout:
                print(validate_result.stdout.rstrip(), file=sys.stderr)
            if validate_result.stderr:
                print(validate_result.stderr.rstrip(), file=sys.stderr)
            print(
                f"ERROR: Validation failed for {lang} ({file_path.name}). Import stopped.",
                file=sys.stderr,
            )
            return validate_result.returncode

        import_result = run_script(import_script, file_path, lang)
        if import_result.returncode != 0:
            if import_result.stdout:
                print(import_result.stdout.rstrip(), file=sys.stderr)
            if import_result.stderr:
                print(import_result.stderr.rstrip(), file=sys.stderr)
            print(
                f"ERROR: Import failed for {lang} ({file_path.name}). Import stopped.",
                file=sys.stderr,
            )
            return import_result.returncode

        line = import_result.stdout.strip()
        if line:
            print(line)
        else:
            print(f"language={lang} imported_count=0 skipped_locked=0 missing_keys=0")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
