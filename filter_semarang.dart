import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'd:/AntiGravity/AntiGravity-Project/SiPanda/sipanda_app/assets/map/Kecamatan.json';
  final outputPath = 'd:/AntiGravity/AntiGravity-Project/SiPanda/sipanda_app/assets/map/semarang_filtered.geojson';

  print("Loading massive JSON dataset into Dart VM...");
  
  try {
    final file = File(inputPath);
    final rawData = await file.readAsString();
    
    print("Parsing JSON...");
    final data = jsonDecode(rawData) as Map<String, dynamic>;
    
    final features = data['features'] as List<dynamic>? ?? [];
    print('Total features parsed: ${features.length}');

    final semarangFeatures = [];
    
    for (var f in features) {
      final properties = f['properties'] as Map<String, dynamic>?;
      if (properties == null) continue;
      
      bool match = false;
      for (var val in properties.values) {
        if (val is String && val.toLowerCase().contains('semarang')) {
          match = true;
          break;
        }
      }
      
      if (match) {
        semarangFeatures.add(f);
      }
    }

    print('Matched ${semarangFeatures.length} features for Semarang.');

    final outputData = {
      "type": "FeatureCollection",
      "features": semarangFeatures
    };

    final outFile = File(outputPath);
    await outFile.writeAsString(jsonEncode(outputData));
    print("Saved semarang_filtered.geojson successfully!");
    
  } catch(e) {
    print('Error: $e');
  }
}
