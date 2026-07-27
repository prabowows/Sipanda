import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('d:\\AntiGravity\\AntiGravity-Project\\SiPanda\\sipanda_app\\assets\\map\\semarang_filtered.geojson');
  final jsonString = file.readAsStringSync();
  final data = jsonDecode(jsonString);
  final features = data['features'] as List;
  
  List<String> names = [];
  for (var f in features) {
    if (f['properties'] != null) {
      String n = f['properties']['KECAMATAN'] ?? f['properties']['nm_kecamatan'] ?? "UNKNOWN";
      if (!names.contains(n)) {
        names.add(n);
      }
    }
  }
  print(names);
}
