import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/map/semarang_filtered.geojson');
  final jsonString = file.readAsStringSync();
  final geoJson = jsonDecode(jsonString);
  
  Map<String, List<double>> kecamatanCenters = {};
  
  if (geoJson['features'] != null) {
    for (var feature in geoJson['features']) {
      final geometry = feature['geometry'];
      final properties = feature['properties'] ?? {};
      final String kecamatanName = (properties['KECAMATAN'] ?? properties['nm_kecamatan'] ?? '').toString();

      if (geometry != null) {
        String type = geometry['type'];
        List<dynamic> coords = geometry['coordinates'];

        if (type == 'Polygon') {
          final ring = coords[0];
          double latSum = 0;
          double lngSum = 0;
          
          for (var coord in ring) {
            latSum += coord[1];
            lngSum += coord[0];
          }
          
          if (ring.isNotEmpty && kecamatanName.isNotEmpty) {
            kecamatanCenters[kecamatanName] = [latSum / ring.length, lngSum / ring.length];
          }
        } else if (type == 'MultiPolygon') {
          for (var polygonCoords in coords) {
            final ring = polygonCoords[0];
            double latSum = 0;
            double lngSum = 0;
            
            for (var coord in ring) {
              latSum += coord[1];
              lngSum += coord[0];
            }
            
            if (ring.isNotEmpty && kecamatanName.isNotEmpty && !kecamatanCenters.containsKey(kecamatanName)) {
              kecamatanCenters[kecamatanName] = [latSum / ring.length, lngSum / ring.length];
            }
          }
        }
      }
    }
  }

  print('--- DAFTAR KECAMATAN & TITIK PUSAT (LAT, LNG) ---');
  kecamatanCenters.forEach((name, center) {
    print('- ${name.toUpperCase()}: ${center[0].toStringAsFixed(5)}, ${center[1].toStringAsFixed(5)}');
  });
}
