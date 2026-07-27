const fs = require('fs');

const inputPath = 'd:/AntiGravity/AntiGravity-Project/SiPanda/sipanda_app/assets/map/Kecamatan.json';
const outputPath = 'd:/AntiGravity/AntiGravity-Project/SiPanda/sipanda_app/assets/map/semarang_filtered.geojson';

console.log("Loading massive JSON dataset...");
try {
    const rawData = fs.readFileSync(inputPath, 'utf8');
    const data = JSON.parse(rawData);

    const features = data.features || [];
    console.log(`Total features parsed: ${features.length}`);

    const semarangFeatures = features.filter(f => {
        if (!f.properties) return false;
        
        let match = false;
        for (const key in f.properties) {
            const val = f.properties[key];
            if (typeof val === 'string' && val.toLowerCase().includes('semarang')) {
                match = true;
                break;
            }
        }
        return match;
    });

    console.log(`Matched ${semarangFeatures.length} features for Semarang.`);

    const outputData = {
        type: "FeatureCollection",
        features: semarangFeatures
    };

    fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2), 'utf8');
    console.log("Saved semarang_filtered.geojson successfully!");
} catch(err) {
    console.error("Error processing:", err);
}
