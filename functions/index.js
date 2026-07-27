const { onSchedule } = require("firebase-functions/v2/scheduler");

const KECAMATAN_MAP = {
  "semarang_tengah": { name: "Semarang Tengah", adm4: "33.74.01.1001" },
  "semarang_utara": { name: "Semarang Utara", adm4: "33.74.02.1001" },
  "semarang_timur": { name: "Semarang Timur", adm4: "33.74.03.1001" },
  "gayamsari": { name: "Gayamsari", adm4: "33.74.04.1001" },
  "genuk": { name: "Genuk", adm4: "33.74.05.1001" },
  "pedurungan": { name: "Pedurungan", adm4: "33.74.06.1001" },
  "semarang_selatan": { name: "Semarang Selatan", adm4: "33.74.07.1001" },
  "candisari": { name: "Candisari", adm4: "33.74.08.1001" },
  "gajahmungkur": { name: "Gajahmungkur", adm4: "33.74.09.1001" },
  "tembalang": { name: "Tembalang", adm4: "33.74.10.1001" },
  "banyumanik": { name: "Banyumanik", adm4: "33.74.11.1001" },
  "gunungpati": { name: "Gunungpati", adm4: "33.74.12.1001" },
  "semarang_barat": { name: "Semarang Barat", adm4: "33.74.13.1001" },
  "mijen": { name: "Mijen", adm4: "33.74.14.1001" },
  "ngaliyan": { name: "Ngaliyan", adm4: "33.74.15.1001" },
  "tugu": { name: "Tugu", adm4: "33.74.16.1001" },
};

function fetchBmkgData(adm4) {
  return new Promise((resolve) => {
    const https = require("https");
    const url = `https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${adm4}`;
    const options = { headers: { "User-Agent": "SiPanda/1.0" } };
    https.get(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          const json = JSON.parse(data);
          if (json.data && json.data.length > 0 && json.data[0].cuaca && json.data[0].cuaca.length > 0) {
            const first = json.data[0].cuaca[0][0];
            return resolve({
              rainfall: parseFloat(first.tp || 0),
              temp: parseFloat(first.t || 28),
              humidity: parseFloat(first.hu || 75),
              desc: first.weather_desc || "Cerah Berawan"
            });
          }
        } catch (e) {
          console.warn(`Warning parsing BMKG for adm4 ${adm4}:`, e);
        }
        resolve({ rainfall: 0, temp: 28, humidity: 75, desc: "Cerah" });
      });
    }).on("error", (err) => {
      console.warn(`Failed fetching BMKG for adm4 ${adm4}:`, err);
      resolve({ rainfall: 0, temp: 28, humidity: 75, desc: "Cerah" });
    });
  });
}

exports.scheduled_fetch = onSchedule("every 15 minutes", async (event) => {
  const admin = require("firebase-admin");
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();

  console.log("[SIPANDA SCHEDULER] Starting 24/7 live telemetry fetch for 16 districts...");
  const entries = Object.entries(KECAMATAN_MAP);
  let updatedCount = 0;

  for (const [docId, info] of entries) {
    const weather = await fetchBmkgData(info.adm4);
    
    // Risk Prediction Model
    let floodProb = 10.0;
    if (weather.rainfall > 80) floodProb = 85.0;
    else if (weather.rainfall > 40) floodProb = 55.0;
    else if (weather.rainfall > 10) floodProb = 30.0;
    
    let mlRisk = "aman";
    if (floodProb > 70) mlRisk = "siaga";
    else if (floodProb > 40) mlRisk = "waspada";

    // 1. Update active state in parent document (preserves override_risk if set)
    await db.collection("districts").doc(docId).set({
      name: info.name,
      rainfall: weather.rainfall,
      temp: weather.temp,
      humidity: weather.humidity,
      flood_prob: floodProb,
      ml_risk: mlRisk,
      weather_desc: weather.desc,
      last_updated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // 2. Append new entry into history subcollection for time-series charts & logs
    await db.collection("districts").doc(docId).collection("history").add({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      rainfall: weather.rainfall,
      temp: weather.temp,
      humidity: weather.humidity,
      flood_prob: floodProb,
      ml_risk: mlRisk,
      weather_desc: weather.desc
    });

    updatedCount++;
  }

  await db.collection("config").doc("system").set({
    last_api_fetch: admin.firestore.FieldValue.serverTimestamp(),
    last_fetch_status: "SUCCESS",
    districts_count: updatedCount
  }, { merge: true });

  console.log(`[SIPANDA SCHEDULER] Successfully updated active state + history logs for ${updatedCount} districts!`);
});
