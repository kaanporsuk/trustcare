#!/usr/bin/env python3
"""
Seed sample Adana providers into Supabase.

Usage:
  pip install supabase
  export SUPABASE_URL="https://<project>.supabase.co"
  export SUPABASE_SERVICE_ROLE_KEY="<service_role_key>"
  python scripts/seed_providers.py
"""

from __future__ import annotations

import os
import sys
from typing import Any, Dict, List

from supabase import Client, create_client


PROVIDERS: List[Dict[str, Any]] = [
    {
        "name": "Seyhan Aile Sağlığı Merkezi",
        "clinic_name": "Seyhan ASM",
        "address": "Reşatbey Mah., Atatürk Cd. No:112, Seyhan/Adana",
        "city": "Adana",
        "latitude": 36.9918,
        "longitude": 35.3306,
        "phone": "+90 322 455 10 10",
        "specialty_name": "General Practice",
    },
    {
        "name": "Çukurova Aile Sağlığı Kliniği",
        "clinic_name": "Çukurova ASM",
        "address": "Güzelyalı Mah., Turgut Özal Blv. No:58, Çukurova/Adana",
        "city": "Adana",
        "latitude": 37.0472,
        "longitude": 35.2866,
        "phone": "+90 322 455 10 11",
        "specialty_name": "Family Medicine",
    },
    {
        "name": "Adana Şehir Hastanesi",
        "clinic_name": "Adana Şehir Hastanesi",
        "address": "Yüreğir Mah., Dr. Mithat Özsan Blv., Yüreğir/Adana",
        "city": "Adana",
        "latitude": 37.0203,
        "longitude": 35.4147,
        "phone": "+90 322 455 20 00",
        "specialty_name": "Hospital (General)",
    },
    {
        "name": "Eczane Akdeniz",
        "clinic_name": "Eczane Akdeniz",
        "address": "Ziyapaşa Mah., Baraj Yolu Cd. No:44, Seyhan/Adana",
        "city": "Adana",
        "latitude": 36.9865,
        "longitude": 35.3274,
        "phone": "+90 322 455 30 01",
        "specialty_name": "Pharmacy",
    },
    {
        "name": "Eczane Çukurova",
        "clinic_name": "Eczane Çukurova",
        "address": "Belediye Evleri Mah., T. Özal Blv. No:125, Çukurova/Adana",
        "city": "Adana",
        "latitude": 37.0581,
        "longitude": 35.2789,
        "phone": "+90 322 455 30 02",
        "specialty_name": "Pharmacy",
    },
    {
        "name": "Diş Hekimi Burak Yıldız",
        "clinic_name": "Yıldız Ağız ve Diş Sağlığı",
        "address": "Cemalpaşa Mah., Gazipaşa Blv. No:89, Seyhan/Adana",
        "city": "Adana",
        "latitude": 36.9936,
        "longitude": 35.3239,
        "phone": "+90 322 455 40 10",
        "specialty_name": "General Dentistry",
    },
    {
        "name": "Vizyon Göz Merkezi",
        "clinic_name": "Vizyon Göz",
        "address": "Kurtuluş Mah., Ziyapaşa Blv. No:21, Seyhan/Adana",
        "city": "Adana",
        "latitude": 36.9912,
        "longitude": 35.3196,
        "phone": "+90 322 455 50 20",
        "specialty_name": "Ophthalmology",
    },
    {
        "name": "Psikiyatri Uzmanı Dr. Elif Aydın",
        "clinic_name": "Aydın Psikiyatri Kliniği",
        "address": "Mahfesığmaz Mah., Öğretmenler Blv. No:74, Çukurova/Adana",
        "city": "Adana",
        "latitude": 37.0618,
        "longitude": 35.2738,
        "phone": "+90 322 455 60 30",
        "specialty_name": "Psychiatry",
    },
    {
        "name": "Adana Saç Ekimi ve Estetik Merkezi",
        "clinic_name": "Nova Hair & Aesthetic",
        "address": "Yeni Mah., Turhan Cemal Beriker Blv. No:210, Seyhan/Adana",
        "city": "Adana",
        "latitude": 36.9777,
        "longitude": 35.3332,
        "phone": "+90 322 455 70 40",
        "specialty_name": "Hair Transplant",
    },
    {
        "name": "FizyoAdana Rehabilitasyon Merkezi",
        "clinic_name": "FizyoAdana",
        "address": "Yurt Mah., Alparslan Türkeş Blv. No:145, Çukurova/Adana",
        "city": "Adana",
        "latitude": 37.0509,
        "longitude": 35.2897,
        "phone": "+90 322 455 80 50",
        "specialty_name": "Physical Therapy / Physiotherapy",
    },
]


def get_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def load_specialty_map(client: Client) -> Dict[str, Dict[str, Any]]:
    response = (
        client.table("specialties")
        .select("id,name,name_tr,survey_type")
        .eq("is_active", True)
        .execute()
    )

    rows = response.data or []
    mapping: Dict[str, Dict[str, Any]] = {}
    for row in rows:
        name = (row.get("name") or "").strip()
        name_tr = (row.get("name_tr") or "").strip()
        if name:
            mapping[name.lower()] = row
        if name_tr:
            mapping[name_tr.lower()] = row
    return mapping


def provider_exists(client: Client, name: str, address: str) -> bool:
    result = (
        client.table("providers")
        .select("id")
        .eq("name", name)
        .eq("address", address)
        .limit(1)
        .execute()
    )
    return bool(result.data)


def build_payload(provider: Dict[str, Any], specialty_row: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "name": provider["name"],
        "specialty": specialty_row["name"],
        "specialty_id": specialty_row["id"],
        "survey_type": specialty_row["survey_type"],
        "clinic_name": provider["clinic_name"],
        "address": provider["address"],
        "city": provider["city"],
        "country_code": "TR",
        "latitude": provider["latitude"],
        "longitude": provider["longitude"],
        "phone": provider["phone"],
        "is_active": True,
        "is_claimed": False,
        "is_featured": False,
        "data_source": "system",
    }


def insert_provider(client: Client, payload: Dict[str, Any]) -> None:
    try:
        client.table("providers").insert(payload).execute()
    except Exception:
        fallback = dict(payload)
        fallback.pop("specialty_id", None)
        fallback.pop("survey_type", None)
        client.table("providers").insert(fallback).execute()


def main() -> int:
    try:
        supabase_url = get_env("SUPABASE_URL")
        service_key = get_env("SUPABASE_SERVICE_ROLE_KEY")
    except RuntimeError as exc:
        print(f"❌ {exc}")
        print("\nSet these first:")
        print("  export SUPABASE_URL='https://<project>.supabase.co'")
        print("  export SUPABASE_SERVICE_ROLE_KEY='<service_role_key>'")
        return 1

    client = create_client(supabase_url, service_key)
    specialty_map = load_specialty_map(client)

    inserted = 0
    skipped = 0

    for provider in PROVIDERS:
        specialty_key = provider["specialty_name"].strip().lower()
        specialty_row = specialty_map.get(specialty_key)
        if not specialty_row:
            print(f"⚠️ Specialty not found for {provider['name']}: {provider['specialty_name']}")
            skipped += 1
            continue

        if provider_exists(client, provider["name"], provider["address"]):
            print(f"↷ Skipped existing: {provider['name']}")
            skipped += 1
            continue

        payload = build_payload(provider, specialty_row)
        insert_provider(client, payload)
        inserted += 1
        print(f"✅ Inserted: {provider['name']} ({specialty_row['name']})")

    print("\nDone.")
    print(f"Inserted: {inserted}")
    print(f"Skipped:  {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
