import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/map/semarang_filtered.geojson');
  final jsonString = file.readAsStringSync();
  final geoJson = jsonDecode(jsonString);
  
  final Set<String> kotaSemarang = {
    'ngaliyan', 'tugu', 'semarang utara', 'semarang timur', 
    'semarang tengah', 'semarang selatan', 'semarang barat', 
    'pedurungan', 'gayamsari', 'genuk', 'candisari', 
    'gajahmungkur', 'tembalang', 'mijen', 'banyumanik', 'gunungpati'
  };

  List<dynamic> filteredFeatures = [];
  
  if (geoJson['features'] != null) {
    for (var feature in geoJson['features']) {
      final properties = feature['properties'] ?? {};
      final String kecamatanName = (properties['KECAMATAN'] ?? properties['nm_kecamatan'] ?? '').toString().toLowerCase();

      if (kotaSemarang.contains(kecamatanName)) {
        filteredFeatures.add(feature);
      }
    }
  }

  geoJson['features'] = filteredFeatures;
  
  file.writeAsStringSync(jsonEncode(geoJson));
  print('Berhasil memfilter data! Tersisa ${filteredFeatures.length} kecamatan Kota Semarang.');
}
