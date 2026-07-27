import json

input_path = r"d:\AntiGravity\AntiGravity-Project\SiPanda\sipanda_app\assets\map\Kecamatan.json"
output_path = r"d:\AntiGravity\AntiGravity-Project\SiPanda\sipanda_app\assets\map\semarang_filtered.geojson"

print("Loading 1GB JSON into memory... this may take a moment.")
with open(input_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

features = data.get('features', [])
print(f"Total features in dataset: {len(features)}")

if features:
    print("Sample keys in the first feature properties:")
    print(features[0].get('properties', {}).keys())

semarang_features = []
for feature in features:
    props = feature.get('properties', {})
    match = False
    for k, v in props.items():
        if isinstance(v, str) and 'semarang' in v.lower():
            match = True
            break
            
    if match:
        semarang_features.append(feature)

print(f"Found {len(semarang_features)} features for Semarang region.")

out_data = {
    "type": "FeatureCollection",
    "features": semarang_features
}

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(out_data, f)

print("Saved filtered GeoJSON!")
