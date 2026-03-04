#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS_PATH = ROOT / "TrustCare" / "Localizable.xcstrings"
OUTPUT_DIR = ROOT / "scripts" / "generated_l10n_phase1"

MARKDOWN_CANDIDATES = [
    ROOT / "TrustCare_Translations_11_Languages_FIXED.md",
    ROOT / "docs" / "TrustCare_Translations_11_Languages_FIXED.md",
    Path("/Users/kaanporsuk/Documents/TrustCare/Prompts/TrustCare_Translations_11_Languages_FIXED.md"),
]

TARGET_LANGS = ["es", "fr", "it", "ro", "pt", "uk", "ru", "sv", "cs", "hu"]


def resolve_markdown_path(cli_markdown: str | None) -> Path:
    if cli_markdown:
        candidate = Path(cli_markdown).expanduser().resolve()
        if candidate.exists():
            return candidate
        raise FileNotFoundError(f"Provided markdown path not found: {candidate}")

    for candidate in MARKDOWN_CANDIDATES:
        if candidate.exists():
            return candidate

    searched = "\n".join(f"- {path}" for path in MARKDOWN_CANDIDATES)
    raise FileNotFoundError(
        "Missing markdown file. Searched:\n"
        f"{searched}\n"
        "Pass --markdown /absolute/or/relative/path/to/TrustCare_Translations_11_Languages_FIXED.md"
    )


def normalize_placeholders(text: str) -> str:
    value = text.replace("\\u00a0", " ").strip()
    value = re.sub(r"%\d+\$@", "%@", value)
    value = re.sub(r"%\d+\$lld", "%lld", value)
    value = re.sub(r"%\d+\$ld", "%ld", value)
    value = re.sub(r"\s+", " ", value)
    return value


def parse_markdown_translations(markdown_path: Path) -> dict[str, dict[str, str]]:
    content = markdown_path.read_text(encoding="utf-8")
    by_lang: dict[str, dict[str, str]] = {lang: {} for lang in TARGET_LANGS}

    current_lang = None
    heading_re = re.compile(r"^# .*\(([-a-zA-Z_]+)\)\s*$")
    pair_re = re.compile(r'^-\s+"(.*)"\s+→\s+"(.*)"\s*$')

    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        heading_match = heading_re.match(line)
        if heading_match:
            code = heading_match.group(1).lower().strip()
            current_lang = code if code in by_lang else None
            continue

        if current_lang is None:
            continue

        pair_match = pair_re.match(line)
        if not pair_match:
            continue

        source = normalize_placeholders(pair_match.group(1))
        target = normalize_placeholders(pair_match.group(2))

        if source:
            by_lang[current_lang][source] = target

    return by_lang


def ensure_localization_entry(entry: dict, lang: str, value: str) -> None:
    localizations = entry.setdefault("localizations", {})
    localizations[lang] = {
        "stringUnit": {
            "state": "translated",
            "value": value,
        }
    }


def merge_translations(xcstrings: dict, translations_by_lang: dict[str, dict[str, str]]) -> int:
    updated = 0
    strings = xcstrings.get("strings", {})

    for key, entry in strings.items():
        if not isinstance(entry, dict):
            continue

        localizations = entry.get("localizations", {})
        en_value = localizations.get("en", {}).get("stringUnit", {}).get("value")
        candidates = []
        if isinstance(en_value, str):
            candidates.append(normalize_placeholders(en_value))
        candidates.append(normalize_placeholders(key))

        for lang, lang_map in translations_by_lang.items():
            translation = None
            for candidate in candidates:
                if candidate in lang_map:
                    translation = lang_map[candidate]
                    break

            if translation is None:
                continue

            current = localizations.get(lang, {}).get("stringUnit", {}).get("value")
            if current != translation:
                ensure_localization_entry(entry, lang, translation)
                updated += 1

    return updated


def build_plural_localization(forms: dict[str, str], format_specifier: str = "lld") -> dict:
    return {
        "stringUnit": {
            "state": "translated",
            "value": "%#@count@",
        },
        "substitutions": {
            "count": {
                "argNum": 1,
                "formatSpecifier": format_specifier,
                "variations": {
                    "plural": {
                        category: {
                            "stringUnit": {
                                "state": "translated",
                                "value": text,
                            }
                        }
                        for category, text in forms.items()
                    }
                },
            }
        },
    }


def apply_profile_reviews_pluralization(xcstrings: dict) -> None:
    strings = xcstrings.setdefault("strings", {})
    key = "profile_reviews_count %lld"
    entry = strings.setdefault(key, {"extractionState": "stale", "localizations": {}})

    plural_forms = {
        "en": {"one": "%lld Review", "other": "%lld Reviews"},
        "tr": {"one": "%lld Değerlendirme", "other": "%lld Değerlendirme"},
        "de": {"one": "%lld Bewertung", "other": "%lld Bewertungen"},
        "pl": {"one": "%lld Recenzja", "few": "%lld Recenzje", "many": "%lld Recenzji", "other": "%lld Recenzji"},
        "nl": {"one": "%lld Beoordeling", "other": "%lld Beoordelingen"},
        "da": {"one": "%lld Anmeldelse", "other": "%lld Anmeldelser"},
        "es": {"one": "%lld Reseña", "other": "%lld Reseñas"},
        "fr": {"one": "%lld Avis", "other": "%lld Avis"},
        "it": {"one": "%lld Recensione", "other": "%lld Recensioni"},
        "ro": {"one": "%lld Recenzie", "few": "%lld Recenzii", "other": "%lld Recenzii"},
        "pt": {"one": "%lld Avaliação", "other": "%lld Avaliações"},
        "sv": {"one": "%lld Recension", "other": "%lld Recensioner"},
        "hu": {"one": "%lld Értékelés", "other": "%lld Értékelés"},
        "ru": {"one": "%lld Отзыв", "few": "%lld Отзыва", "many": "%lld Отзывов", "other": "%lld Отзыва"},
        "uk": {"one": "%lld Відгук", "few": "%lld Відгуки", "many": "%lld Відгуків", "other": "%lld Відгуку"},
        "cs": {"one": "%lld Recenze", "few": "%lld Recenze", "many": "%lld Recenzí", "other": "%lld Recenze"},
    }

    localizations = entry.setdefault("localizations", {})
    for lang, forms in plural_forms.items():
        localizations[lang] = build_plural_localization(forms)


def write_strings_exports(translations_by_lang: dict[str, dict[str, str]]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for lang, mapping in translations_by_lang.items():
        lines = []
        for source in sorted(mapping.keys()):
            target = mapping[source]
            escaped_source = source.replace("\\", "\\\\").replace('"', '\\"')
            escaped_target = target.replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'"{escaped_source}" = "{escaped_target}";')
        (OUTPUT_DIR / f"{lang}.strings").write_text("\n".join(lines) + "\n", encoding="utf-8")


def snapshot_key_locales(xcstrings: dict) -> tuple[set[str], dict[str, set[str]]]:
    strings = xcstrings.get("strings", {})
    keys = set(strings.keys())
    key_locales: dict[str, set[str]] = {}
    for key, entry in strings.items():
        if not isinstance(entry, dict):
            key_locales[key] = set()
            continue
        localizations = entry.get("localizations", {})
        key_locales[key] = set(localizations.keys()) if isinstance(localizations, dict) else set()
    return keys, key_locales


def validate_preservation(before: dict, after: dict) -> None:
    before_keys, before_key_locales = snapshot_key_locales(before)
    after_keys, after_key_locales = snapshot_key_locales(after)

    missing_keys = before_keys - after_keys
    if missing_keys:
        sample = ", ".join(sorted(list(missing_keys))[:10])
        raise RuntimeError(f"Validation failed: keys removed from xcstrings (sample): {sample}")

    locale_losses: list[str] = []
    for key in sorted(before_keys):
        lost_locales = before_key_locales[key] - after_key_locales.get(key, set())
        if lost_locales:
            locale_losses.append(f"{key}: {', '.join(sorted(lost_locales))}")

    if locale_losses:
        sample = " | ".join(locale_losses[:10])
        raise RuntimeError(f"Validation failed: locale removals detected (sample): {sample}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Safely merge Phase 1 markdown translations into Localizable.xcstrings"
    )
    parser.add_argument(
        "--markdown",
        help="Path to TrustCare_Translations_11_Languages_FIXED.md",
        default=None,
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    markdown_path = resolve_markdown_path(args.markdown)

    if not XCSTRINGS_PATH.exists():
        raise FileNotFoundError(f"Missing xcstrings file: {XCSTRINGS_PATH}")

    translations_by_lang = parse_markdown_translations(markdown_path)

    xcstrings = json.loads(XCSTRINGS_PATH.read_text(encoding="utf-8"))
    before_snapshot = json.loads(json.dumps(xcstrings))
    updated_count = merge_translations(xcstrings, translations_by_lang)
    apply_profile_reviews_pluralization(xcstrings)
    validate_preservation(before_snapshot, xcstrings)

    XCSTRINGS_PATH.write_text(
        json.dumps(xcstrings, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    write_strings_exports(translations_by_lang)

    print(f"Markdown source: {markdown_path}")
    print(f"Updated localization entries: {updated_count}")
    print(f"Wrote strings exports to: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
