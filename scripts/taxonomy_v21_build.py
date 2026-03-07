#!/usr/bin/env python3
"""Build TrustCare taxonomy v2.1 runtime resources from the authoritative docs/taxonomy proposal.

This script generates:
- runtime base canonical resource
- runtime concern-domain mapping resource
- runtime locale label/alias resources (en fully populated, other locales scaffolded)
- a proposal-aligned Supabase migration for exhaustive taxonomy + concern-domain upserts
"""

from __future__ import annotations

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

ENTITY_TYPE_TO_DB = {
    "specialty": "specialty",
    "treatment_procedure": "service",
    "facility_type": "facility",
}

# Known proposal link typos / legacy IDs that must map to canonical runtime IDs.
LINK_ID_REMAP = {
    "SPEC_GENERAL_DENTISTRY": "SPEC_DENTISTRY_GENERAL",
}


def sort_entity_key(row: dict[str, Any]) -> tuple[str, str]:
    return row["entity_type"], row["canonical_id"]


def load_proposal(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def build_taxonomy_rows(proposal: dict[str, Any]) -> list[dict[str, Any]]:
    taxonomy = proposal["taxonomy"]
    rows: list[dict[str, Any]] = []

    for source_key in ("specialties", "treatment_procedures", "facility_types"):
        for item in taxonomy[source_key]:
            rows.append(
                {
                    "canonical_id": item["canonical_id"],
                    "entity_type": "specialty" if source_key == "specialties" else (
                        "treatment_procedure" if source_key == "treatment_procedures" else "facility_type"
                    ),
                    "display_english_label": item["display_english_label"],
                    "aliases_english": item.get("search_aliases", []),
                    "launch_scope": "v2_1_core",
                }
            )

    rows.sort(key=sort_entity_key)
    return rows


def build_concern_rows(proposal: dict[str, Any]) -> list[dict[str, Any]]:
    taxonomy_ids = {
        item["canonical_id"]
        for bucket in ("specialties", "treatment_procedures", "facility_types")
        for item in proposal["taxonomy"][bucket]
    }

    def normalize_links(ids: list[str], concern_id: str, link_type: str) -> list[str]:
        normalized: list[str] = []
        unknown: list[str] = []

        for value in ids:
            candidate = LINK_ID_REMAP.get(value, value)
            if candidate in taxonomy_ids:
                normalized.append(candidate)
            else:
                unknown.append(value)

        if unknown:
            raise ValueError(
                f"Concern {concern_id} contains unknown {link_type} link IDs: {unknown}"
            )

        # Keep source order stable while removing accidental duplicates.
        seen = set()
        ordered: list[str] = []
        for value in normalized:
            if value in seen:
                continue
            seen.add(value)
            ordered.append(value)
        return ordered

    concerns = []
    for item in proposal["symptom_concern_domains"]:
        concern_id = item["canonical_id"]
        concerns.append(
            {
                "canonical_id": concern_id,
                "display_english_label": item["display_english_label"],
                "example_inputs": item.get("example_inputs", []),
                "likely_specialty_ids": normalize_links(item.get("likely_specialty_ids", []), concern_id, "specialty"),
                "likely_treatment_procedure_ids": normalize_links(item.get("likely_treatment_ids", []), concern_id, "treatment"),
                "likely_facility_type_ids": normalize_links(item.get("likely_facility_type_ids", []), concern_id, "facility"),
                "urgency_sensitive": bool(item.get("urgency_sensitive", False)),
                "launch_scope": "v2_1_core",
            }
        )

    concerns.sort(key=lambda row: row["canonical_id"])
    return concerns


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    return f"'{sql_escape(str(value))}'"


def values_block(rows: list[tuple[Any, ...]]) -> str:
    formatted = []
    for row in rows:
        formatted.append("(" + ", ".join(sql_literal(v) for v in row) + ")")
    return ",\n    ".join(formatted)


def build_migration_sql(
    taxonomy_rows: list[dict[str, Any]],
    concern_rows: list[dict[str, Any]],
    migration_name: str,
) -> str:
    taxonomy_values = []
    taxonomy_label_values = []
    taxonomy_v21_values = []
    alias_values = []

    for idx, row in enumerate(taxonomy_rows):
        canonical_id = row["canonical_id"]
        entity_type = row["entity_type"]
        display_label = row["display_english_label"]
        db_entity_type = ENTITY_TYPE_TO_DB[entity_type]
        sort_priority = idx

        taxonomy_values.append((canonical_id, db_entity_type, display_label, None, sort_priority))
        taxonomy_label_values.append((canonical_id, "en", display_label, None))
        taxonomy_v21_values.append((canonical_id, entity_type, display_label, "v2_1_core"))

        for alias in row.get("aliases_english", []):
            alias_values.append((canonical_id, "en", alias, "proposal_v21"))

    concern_values = []
    concern_link_values = []
    concern_id_values = []

    for row in concern_rows:
        concern_id = row["canonical_id"]
        concern_id_values.append((concern_id,))
        concern_values.append(
            (
                concern_id,
                row["display_english_label"],
                "v2_1_core",
                "medium" if row.get("urgency_sensitive", False) else "low",
                None,
            )
        )

        for linked in row.get("likely_specialty_ids", []):
            concern_link_values.append((concern_id, linked, "specialty", 1.0))
        for linked in row.get("likely_treatment_procedure_ids", []):
            concern_link_values.append((concern_id, linked, "treatment_procedure", 1.0))
        for linked in row.get("likely_facility_type_ids", []):
            concern_link_values.append((concern_id, linked, "facility_type", 1.0))

    taxonomy_id_values = [(row["canonical_id"],) for row in taxonomy_rows]

    return f"""-- Proposal-driven exhaustive taxonomy v2.1 alignment
-- Generated by scripts/taxonomy_v21_build.py from docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json

BEGIN;

-- Upsert canonical entities used by DB-facing taxonomy search paths.
INSERT INTO public.taxonomy_entities (id, entity_type, default_name, icon_key, sort_priority)
VALUES
    {values_block(taxonomy_values)}
ON CONFLICT (id) DO UPDATE
SET
    entity_type = EXCLUDED.entity_type,
    default_name = EXCLUDED.default_name,
    icon_key = EXCLUDED.icon_key,
    sort_priority = EXCLUDED.sort_priority,
    updated_at = now();

INSERT INTO public.taxonomy_labels (entity_id, locale, label, short_label)
VALUES
    {values_block(taxonomy_label_values)}
ON CONFLICT (entity_id, locale) DO UPDATE
SET
    label = EXCLUDED.label,
    short_label = EXCLUDED.short_label,
    updated_at = now();

INSERT INTO public.taxonomy_v21_entities (canonical_id, entity_type, display_english_label, launch_scope)
VALUES
    {values_block(taxonomy_v21_values)}
ON CONFLICT (canonical_id) DO UPDATE
SET
    entity_type = EXCLUDED.entity_type,
    display_english_label = EXCLUDED.display_english_label,
    launch_scope = EXCLUDED.launch_scope,
    updated_at = now();

-- Remove stale v2.1 entity rows outside the proposal corpus.
DELETE FROM public.taxonomy_v21_aliases
WHERE canonical_id NOT IN (
    SELECT id_col FROM (VALUES
        {values_block(taxonomy_id_values)}
    ) AS t(id_col)
);

DELETE FROM public.taxonomy_v21_entities
WHERE canonical_id NOT IN (
    SELECT id_col FROM (VALUES
        {values_block(taxonomy_id_values)}
    ) AS t(id_col)
);

-- Keep alias data aligned with proposal-driven canonical IDs.
DELETE FROM public.taxonomy_aliases
WHERE locale = 'en'
  AND entity_id IN (
      SELECT id_col FROM (VALUES
          {values_block(taxonomy_id_values)}
      ) AS t(id_col)
  );

DELETE FROM public.taxonomy_v21_aliases
WHERE locale = 'en'
  AND canonical_id IN (
      SELECT id_col FROM (VALUES
          {values_block(taxonomy_id_values)}
      ) AS t(id_col)
  );

INSERT INTO public.taxonomy_aliases (entity_id, locale, alias_raw, tag)
VALUES
    {values_block(alias_values) if alias_values else "('SPEC_PLACEHOLDER', 'en', 'placeholder', 'noop')"}
ON CONFLICT (entity_id, locale, alias_normalized) DO UPDATE
SET
    tag = EXCLUDED.tag,
    updated_at = now();

INSERT INTO public.taxonomy_v21_aliases (canonical_id, locale, alias_raw, source_tag)
VALUES
    {values_block(alias_values) if alias_values else "('SPEC_PLACEHOLDER', 'en', 'placeholder', 'noop')"}
ON CONFLICT (canonical_id, locale, alias_normalized) DO UPDATE
SET
    source_tag = EXCLUDED.source_tag,
    updated_at = now();

-- The placeholder branch is only used when alias_values is empty; remove it immediately.
DELETE FROM public.taxonomy_aliases WHERE entity_id = 'SPEC_PLACEHOLDER';
DELETE FROM public.taxonomy_v21_aliases WHERE canonical_id = 'SPEC_PLACEHOLDER';

-- Concern domain alignment.
DELETE FROM public.taxonomy_symptom_links;
DELETE FROM public.taxonomy_symptom_concerns
WHERE canonical_id NOT IN (
    SELECT id_col FROM (VALUES
        {values_block(concern_id_values)}
    ) AS t(id_col)
);

INSERT INTO public.taxonomy_symptom_concerns (canonical_id, display_english_label, launch_scope, urgency_flag, care_setting_hint)
VALUES
    {values_block(concern_values)}
ON CONFLICT (canonical_id) DO UPDATE
SET
    display_english_label = EXCLUDED.display_english_label,
    launch_scope = EXCLUDED.launch_scope,
    urgency_flag = EXCLUDED.urgency_flag,
    care_setting_hint = EXCLUDED.care_setting_hint,
    updated_at = now();

INSERT INTO public.taxonomy_symptom_links (symptom_id, linked_canonical_id, linked_entity_type, link_weight)
VALUES
    {values_block(concern_link_values)}
ON CONFLICT (symptom_id, linked_canonical_id) DO UPDATE
SET
    linked_entity_type = EXCLUDED.linked_entity_type,
    link_weight = EXCLUDED.link_weight;

COMMIT;
"""


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]

    proposal_path = repo_root / "docs" / "taxonomy" / "trustcare_taxonomy_v2_1_proposal.json"
    output_root = repo_root / "TrustCare" / "Resources" / "TaxonomyV21"

    proposal = load_proposal(proposal_path)
    taxonomy_rows = build_taxonomy_rows(proposal)
    concern_rows = build_concern_rows(proposal)

    base_payload = {
        "meta": {
            "version": "taxonomy_v2_1",
            "editorial_locale": "en",
            "entry_count": len(taxonomy_rows),
            "concern_entry_count": len(concern_rows),
            "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
        },
        "taxonomy": taxonomy_rows,
    }

    concern_payload = {
        "meta": {
            "version": "taxonomy_v2_1",
            "editorial_locale": "en",
            "entry_count": len(concern_rows),
            "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
        },
        "concern_domains": concern_rows,
    }

    english_labels = {
        row["canonical_id"]: row["display_english_label"]
        for row in taxonomy_rows
    }
    english_labels.update({
        row["canonical_id"]: row["display_english_label"]
        for row in concern_rows
    })

    canonical_ids = [row["canonical_id"] for row in taxonomy_rows] + [row["canonical_id"] for row in concern_rows]
    canonical_ids = sorted(set(canonical_ids))

    english_aliases = {
        row["canonical_id"]: list(row.get("aliases_english", []))
        for row in taxonomy_rows
    }
    for concern in concern_rows:
        english_aliases[concern["canonical_id"]] = list(concern.get("example_inputs", []))

    write_json(output_root / "base" / "taxonomy_v21_base_en.json", base_payload)
    write_json(output_root / "concerns" / "taxonomy_v21_concern_domains_en.json", concern_payload)

    for locale in SHIPPED_LOCALES:
        if locale == "en":
            labels_payload = {
                "meta": {
                    "version": "taxonomy_v2_1",
                    "locale": locale,
                    "entry_count": len(english_labels),
                    "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
                },
                "labels": dict(sorted(english_labels.items())),
            }
            aliases_payload = {
                "meta": {
                    "version": "taxonomy_v2_1",
                    "locale": locale,
                    "entry_count": len(english_aliases),
                    "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
                },
                "aliases": dict(sorted(english_aliases.items())),
            }
        else:
            labels_payload = {
                "meta": {
                    "version": "taxonomy_v2_1",
                    "locale": locale,
                    "entry_count": len(canonical_ids),
                    "status": "scaffold",
                    "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
                },
                "labels": {canonical_id: "" for canonical_id in canonical_ids},
            }
            aliases_payload = {
                "meta": {
                    "version": "taxonomy_v2_1",
                    "locale": locale,
                    "entry_count": len(canonical_ids),
                    "status": "scaffold",
                    "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
                },
                "aliases": {canonical_id: [] for canonical_id in canonical_ids},
            }

        write_json(output_root / "labels" / f"taxonomy_v21_locale_labels_{locale}.json", labels_payload)
        write_json(output_root / "aliases" / f"taxonomy_v21_aliases_{locale}.json", aliases_payload)

    # Keep legacy root resources synchronized for compatibility fallbacks.
    write_json(repo_root / "TrustCare" / "Resources" / "taxonomy_v21_canonical_en.json", {**base_payload, "symptom_concerns": concern_rows})
    write_json(repo_root / "TrustCare" / "Resources" / "taxonomy_v21_labels_en.json", {
        "meta": {
            "version": "taxonomy_v2_1",
            "locale": "en",
            "entry_count": len(english_labels),
            "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
        },
        "labels": dict(sorted(english_labels.items())),
    })
    write_json(repo_root / "TrustCare" / "Resources" / "taxonomy_v21_symptom_concern_en.json", {
        "meta": {
            "version": "taxonomy_v2_1",
            "editorial_locale": "en",
            "entry_count": len(concern_rows),
            "source": "docs/taxonomy/trustcare_taxonomy_v2_1_proposal.json",
        },
        "symptom_concerns": concern_rows,
    })

    migration_name = "20260307113000_taxonomy_v21_exhaustive_alignment.sql"
    migration_path = repo_root / "supabase" / "migrations" / migration_name
    migration_sql = build_migration_sql(taxonomy_rows, concern_rows, migration_name)
    migration_path.write_text(migration_sql, encoding="utf-8")

    print("Built taxonomy v2.1 runtime resources from authoritative proposal")
    print(f"- taxonomy entities: {len(taxonomy_rows)}")
    print(f"- concern domains: {len(concern_rows)}")
    print(f"- locales scaffolded: {len(SHIPPED_LOCALES)}")
    print(f"- migration: {migration_path.relative_to(repo_root)}")


if __name__ == "__main__":
    main()
