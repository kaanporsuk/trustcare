import overpy
import json
import time
from supabase import create_client, Client

# --- 1. CONFIGURATION ---
# Your REAL Supabase Credentials
SUPABASE_URL = "https://wabgklhhrviqcfdiwofu.supabase.co" 
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDkxNzgwOSwiZXhwIjoyMDg2NDkzODA5fQ.MAR9LkZyEB2XXU4Si21OP01R4Z_zDR7JFhwolQ-Xwd0"

# The Target: Adana
TARGET_AREA = "Adana"
OUTPUT_FILE = "adana_data.json"

# Connect to Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
api = overpy.Overpass()

def fetch_adana_data():
    print(f"🌍 Connecting to OpenStreetMap to scan {TARGET_AREA}...")
    print("   (This might take 10-20 seconds)...")

    # Query for Hospitals, Clinics, Dentists, Pharmacies, Doctors
    query = f"""
    [out:json][timeout:60];
    area["name"="{TARGET_AREA}"]->.searchArea;
    (
      node["amenity"~"hospital|clinic|dentist|pharmacy|doctors"](area.searchArea);
      way["amenity"~"hospital|clinic|dentist|pharmacy|doctors"](area.searchArea);
      node["healthcare"~"physiotherapist|psychotherapist"](area.searchArea);
    );
    out center;
    """
    
    try:
        result = api.query(query)
    except Exception as e:
        print(f"❌ Error fetching data: {e}")
        return []

    items = result.nodes + result.ways
    print(f"✅ FOUND {len(items)} health locations in Adana!")
    
    providers = []
    
    for item in items:
        tags = item.tags
        name = tags.get("name")
        
        # Skip items with no name (useless for the app)
        if not name: continue

        # Get Coordinates
        lat = float(item.lat) if hasattr(item, 'lat') else float(item.center_lat)
        lon = float(item.lon) if hasattr(item, 'lon') else float(item.center_lon)

        # Smart Specialty Detection
        amenity = tags.get("amenity", "").lower()
        healthcare = tags.get("healthcare", "").lower()
        specialty = "Health Center" # Default

        if "pharmacy" in amenity: specialty = "Pharmacy"
        elif "dentist" in amenity: specialty = "Dentist"
        elif "hospital" in amenity: specialty = "Hospital"
        elif "clinic" in amenity: specialty = "Clinic"
        elif "doctors" in amenity: specialty = "Doctor's Office"
        elif "physiotherapist" in healthcare: specialty = "Physiotherapist"

        # Address Logic
        street = tags.get("addr:street", "")
        district = tags.get("addr:district", "")
        full_address = f"{street} {district}, Adana".strip()
        if len(full_address) < 7: full_address = "Adana, Turkey"

        # Build the Record
        provider = {
            "name": name,
            "specialty": specialty,
            "address": full_address,
            "latitude": lat,
            "longitude": lon,
            "country_code": "TR",
            "is_active": True,
            "review_count": 0,
            "rating_overall": 0
        }
        providers.append(provider)

    # Save to a file first (Safety)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(providers, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Saved {len(providers)} locations to '{OUTPUT_FILE}'")
    return providers

def upload_to_supabase(data):
    if not data:
        print("⚠️ No data to upload.")
        return

    print(f"🚀 Uploading {len(data)} providers to Supabase...")
    
    # Upload in batches of 50 to avoid crashing
    chunk_size = 50
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i + chunk_size]
        try:
            # Upsert = Insert if new, Update if exists (prevents duplicates)
            supabase.table("providers").upsert(
                chunk, on_conflict="name,latitude,longitude", ignore_duplicates=True
            ).execute()
            print(f"   ✅ Batch {i} uploaded successfully.")
        except Exception as e:
            print(f"   ⚠️ Error on batch {i}: {e}")

    print("🎉 SUCCESS! Adana is now live in your app.")

# --- RUN IT ---
if __name__ == "__main__":
    data = fetch_adana_data()
    
    # Optional: Pause here if you want to inspect the JSON file first.
    # Otherwise, upload immediately:
    if len(data) > 0:
        print("Wait 3 seconds before uploading...")
        time.sleep(3)
        upload_to_supabase(data)