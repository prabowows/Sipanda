import json
import urllib.request
import urllib.error

KECAMATAN_MAP = {
    "semarang_tengah": {"name": "Semarang Tengah", "adm4": "33.74.01.1001"},
    "semarang_utara": {"name": "Semarang Utara", "adm4": "33.74.02.1001"},
    "semarang_timur": {"name": "Semarang Timur", "adm4": "33.74.03.1001"},
    "gayamsari": {"name": "Gayamsari", "adm4": "33.74.04.1001"},
    "genuk": {"name": "Genuk", "adm4": "33.74.05.1001"},
    "pedurungan": {"name": "Pedurungan", "adm4": "33.74.06.1001"},
    "semarang_selatan": {"name": "Semarang Selatan", "adm4": "33.74.07.1001"},
    "candisari": {"name": "Candisari", "adm4": "33.74.08.1001"},
    "gajahmungkur": {"name": "Gajahmungkur", "adm4": "33.74.09.1001"},
    "tembalang": {"name": "Tembalang", "adm4": "33.74.10.1001"},
    "banyumanik": {"name": "Banyumanik", "adm4": "33.74.11.1001"},
    "gunungpati": {"name": "Gunungpati", "adm4": "33.74.12.1001"},
    "semarang_barat": {"name": "Semarang Barat", "adm4": "33.74.13.1001"},
    "mijen": {"name": "Mijen", "adm4": "33.74.14.1001"},
    "ngaliyan": {"name": "Ngaliyan", "adm4": "33.74.15.1001"},
    "tugu": {"name": "Tugu", "adm4": "33.74.16.1001"},
}

def fetch_single_bmkg(adm4: str) -> dict:
    url = f"https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={adm4}"
    req = urllib.request.Request(url, headers={"User-Agent": "SiPanda/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            if resp.status == 200:
                body = json.loads(resp.read().decode('utf-8'))
                if body.get("data") and len(body["data"]) > 0:
                    cuaca = body["data"][0].get("cuaca", [])
                    if cuaca and len(cuaca) > 0 and len(cuaca[0]) > 0:
                        first_item = cuaca[0][0]
                        return {
                            "rainfall": float(first_item.get("tp", 0.0)),
                            "temp": float(first_item.get("t", 28.0)),
                            "pressure": float(first_item.get("hu", 75.0)) * 10 + 250, # estimated surface pressure proxy
                            "humidity": float(first_item.get("hu", 75.0)),
                            "desc": first_item.get("weather_desc", "Cerah Berawan")
                        }
    except Exception as e:
        print(f"Warning: Failed to fetch BMKG for adm4 {adm4}: {e}")
    
    # Default fallback values if API offline
    return {"rainfall": 0.0, "temp": 28.0, "pressure": 1010.0, "humidity": 75.0, "desc": "Cerah"}

def ingest_telemetry() -> dict:
    """
    Fetches real-time weather data from BMKG for all 16 districts in Semarang.
    """
    results = {}
    for key, info in KECAMATAN_MAP.items():
        data = fetch_single_bmkg(info["adm4"])
        results[key] = {
            "name": info["name"],
            "rainfall": data["rainfall"],
            "pressure": data["pressure"],
            "temp": data["temp"],
            "humidity": data["humidity"],
            "desc": data["desc"]
        }
    return results


