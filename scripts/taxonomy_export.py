#!/usr/bin/env python3
"""Export canonical taxonomy IDs to English JSON for translation workflows."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

TUPLE_PATTERN = re.compile(r"\(\s*\d+\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*\)")
ACRONYM_WORDS = {
    "ent": "ENT",
    "ivf": "IVF",
    "prp": "PRP",
    "tcm": "TCM",
    "obgyn": "OBGYN",
    "lasik": "LASIK",
}


def humanize_entity_id(entity_id: str) -> str:
    core = entity_id
    for prefix in ("SPEC_", "SERV_", "FAC_"):
        if core.startswith(prefix):
            core = core[len(prefix):]
            break

    words = [w for w in core.lower().split("_") if w]
    rendered: list[str] = []

    for word in words:
        if word in ACRONYM_WORDS:
            rendered.append(ACRONYM_WORDS[word])
        else:
            rendered.append(word.capitalize())

    return " ".join(rendered)


def parse_mapping_tuples(sql_text: str) -> list[tuple[str, str]]:
    start_marker = "WITH mapping(legacy_id, entity_id, entity_type) AS ("
    end_marker = "INSERT INTO taxonomy_entities"

    start = sql_text.find(start_marker)
    end = sql_text.find(end_marker)
    if start == -1 or end == -1 or end <= start:
        raise ValueError("Unable to find canonical mapping block in SQL migration.")

    block = sql_text[start:end]
    rows: list[tuple[str, str]] = []
    for entity_id, entity_type in TUPLE_PATTERN.findall(block):
        rows.append((entity_id, entity_type))

    if not rows:
        raise ValueError("No taxonomy tuples found in canonical mapping block.")

    return rows


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    migration_path = repo_root / "supabase" / "migrations" / "20260305000000_seed_canonical_ontology.sql"

    docs_output_path = repo_root / "docs" / "taxonomy" / "taxonomy_en.json"
    resource_output_path = repo_root / "TrustCare" / "Resources" / "TaxonomyI18n" / "en.json"

    sql_text = migration_path.read_text(encoding="utf-8")
    tuples = parse_mapping_tuples(sql_text)

    items: list[dict[str, str]] = []
    for entity_id, entity_type in tuples:
        items.append(
            {
                "id": entity_id,
                "type": entity_type,
                "en": humanize_entity_id(entity_id),
            }
        )

    items.sort(key=lambda item: (item["type"], item["id"]))

    docs_payload = {
        "meta": {
            "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "source": str(migration_path.relative_to(repo_root)),
            "entry_count": len(items),
        },
        "items": items,
    }

    docs_output_path.parent.mkdir(parents=True, exist_ok=True)
    docs_output_path.write_text(json.dumps(docs_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    resource_map = {item["id"]: item["en"] for item in items}
    resource_output_path.parent.mkdir(parents=True, exist_ok=True)
    resource_output_path.write_text(json.dumps(resource_map, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
