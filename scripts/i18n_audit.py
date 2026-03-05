#!/usr/bin/env python3
"""Generate missing translation and hardcoded-string report for TrustCare."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set, Tuple

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS_PATH = ROOT / "TrustCare" / "Localizable.xcstrings"
REPORT_PATH = ROOT / "Docs" / "i18n_missing_report.md"
SWIFT_ROOT = ROOT / "TrustCare"

TEXT_LITERAL_RE = re.compile(r"Text\(\s*\"([^\"\\]*(?:\\.[^\"\\]*)*)\"\s*\)")
BUTTON_LITERAL_RE = re.compile(r"Button\(\s*\"([^\"\\]*(?:\\.[^\"\\]*)*)\"(?:\s*,[^\)]*)?\)")


@dataclass
class HardcodedEntry:
    file_path: str
    line_number: int
    expression: str
    literal: str


def load_catalog(path: Path) -> Dict:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def collect_languages(strings: Dict[str, Dict]) -> List[str]:
    langs: Set[str] = set()
    for payload in strings.values():
        localizations = payload.get("localizations", {})
        langs.update(localizations.keys())
    return sorted(langs)


def find_missing_keys(strings: Dict[str, Dict], languages: List[str]) -> Dict[str, List[str]]:
    missing: Dict[str, List[str]] = {lang: [] for lang in languages}
    for key, payload in strings.items():
        localizations = payload.get("localizations", {})
        for lang in languages:
            entry = localizations.get(lang)
            string_unit = entry.get("stringUnit") if isinstance(entry, dict) else None
            value = string_unit.get("value") if isinstance(string_unit, dict) else None
            if not isinstance(value, str) or not value.strip():
                missing[lang].append(key)
    return missing


def should_flag_literal(literal: str) -> bool:
    text = literal.strip()
    if not text:
        return False

    # Key-like tokens are not hardcoded UI copy (e.g., "menu_help", "add_provider_title").
    if re.fullmatch(r"[a-z0-9]+(?:_[a-z0-9]+)+", text):
        return False

    # If there are no alphabetic characters, this likely isn't user-facing copy.
    if not re.search(r"[A-Za-z]", text):
        return False

    return True


def scan_hardcoded_literals(swift_root: Path) -> List[HardcodedEntry]:
    results: List[HardcodedEntry] = []
    for swift_file in sorted(swift_root.rglob("*.swift")):
        try:
            content = swift_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            content = swift_file.read_text(encoding="utf-8", errors="ignore")

        for regex, expr_name in ((TEXT_LITERAL_RE, "Text"), (BUTTON_LITERAL_RE, "Button")):
            for match in regex.finditer(content):
                literal = match.group(1)
                if not should_flag_literal(literal):
                    continue
                line_number = content.count("\n", 0, match.start()) + 1
                relative_path = swift_file.relative_to(ROOT).as_posix()
                results.append(
                    HardcodedEntry(
                        file_path=relative_path,
                        line_number=line_number,
                        expression=expr_name,
                        literal=literal,
                    )
                )

    results.sort(key=lambda item: (item.file_path, item.line_number, item.expression))
    return results


def render_report(
    languages: List[str],
    missing_by_lang: Dict[str, List[str]],
    hardcoded: List[HardcodedEntry],
) -> str:
    lines: List[str] = []
    lines.append("# i18n Missing Translations Report")
    lines.append("")
    lines.append(f"- Source catalog: `{XCSTRINGS_PATH.relative_to(ROOT).as_posix()}`")
    lines.append(f"- Swift scan root: `{SWIFT_ROOT.relative_to(ROOT).as_posix()}`")
    lines.append("")

    lines.append("## Languages Present")
    lines.append("")
    if languages:
        lines.append(", ".join(f"`{lang}`" for lang in languages))
    else:
        lines.append("No languages found in the catalog.")
    lines.append("")

    lines.append("## Missing Keys By Language")
    lines.append("")
    for lang in languages:
        missing_keys = sorted(missing_by_lang.get(lang, []))
        lines.append(f"### `{lang}`")
        lines.append("")
        lines.append(f"Missing count: **{len(missing_keys)}**")
        lines.append("")
        if missing_keys:
            for key in missing_keys:
                lines.append(f"- `{key}`")
        else:
            lines.append("- None")
        lines.append("")

    lines.append("## Hardcoded Swift String Literals (Text/Button)")
    lines.append("")
    lines.append(
        "Potentially user-visible hardcoded literals found via `Text(\"...\")` and `Button(\"...\")` scanning."
    )
    lines.append("")
    lines.append(f"Total findings: **{len(hardcoded)}**")
    lines.append("")

    if hardcoded:
        for entry in hardcoded:
            lines.append(
                f"- `{entry.file_path}:{entry.line_number}` `{entry.expression}` -> `{entry.literal}`"
            )
    else:
        lines.append("- None")

    lines.append("")
    return "\n".join(lines)


def main() -> None:
    catalog = load_catalog(XCSTRINGS_PATH)
    strings = catalog.get("strings", {})

    if not isinstance(strings, dict):
        raise SystemExit("Unexpected Localizable.xcstrings structure: missing 'strings' object")

    languages = collect_languages(strings)
    missing_by_lang = find_missing_keys(strings, languages)
    hardcoded = scan_hardcoded_literals(SWIFT_ROOT)

    report = render_report(languages, missing_by_lang, hardcoded)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(report, encoding="utf-8")

    print(f"Generated report: {REPORT_PATH.relative_to(ROOT).as_posix()}")
    print(f"Languages: {len(languages)}")
    print(f"Hardcoded findings: {len(hardcoded)}")


if __name__ == "__main__":
    main()
