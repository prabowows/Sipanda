import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipanda_app/core/theme.dart';
import 'package:sipanda_app/core/services/bmkg_service.dart';

enum MapMode { hujan, suhu, kelembapan }

class GeoPolygon {
  final String kecamatanName;
  final List<LatLng> points;
  GeoPolygon(this.kecamatanName, this.points);
}

class RiskGisMap extends StatefulWidget {
  final Function(String)? onKecamatanTapped;

  const RiskGisMap({super.key, this.onKecamatanTapped});

  @override
  State<RiskGisMap> createState() => RiskGisMapState();
}

class RiskGisMapState extends State<RiskGisMap> with TickerProviderStateMixin {
  List<GeoPolygon> _rawPolygons = [];
  List<Polygon> _polygons = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  final Map<String, LatLng> _kecamatanCenters = {};
  
  LatLng? _searchedLocation;
  LatLng? get searchedLocation => _searchedLocation;
  String? _searchedKecamatan;
  MapMode _currentMode = MapMode.hujan;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  void refreshPolygons() {
    _generatePolygons();
  }

  void searchAndMoveToKecamatan(String rawQuery) {
    if (_kecamatanCenters.isEmpty) return;
    String query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return;
    
    // Find matching district
    for (String kecName in _kecamatanCenters.keys) {
      if (kecName.contains(query)) {
        // Found! Animate move and zoom to the center of the district
        _animatedMapMove(_kecamatanCenters[kecName]!, 11.0);
        
        setState(() {
          _searchedLocation = _kecamatanCenters[kecName];
          _searchedKecamatan = kecName.toUpperCase();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Terdeteksi: Kecamatan ${_searchedKecamatan}', style: const TextStyle(fontWeight: FontWeight.bold)),
             backgroundColor: SipandaTheme.primary,
             duration: const Duration(seconds: 2),
           )
        );
        return; // Stop after first match
      }
    }
    
    // If not found
    setState(() {
      _searchedLocation = null;
      _searchedKecamatan = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kecamatan "$query" tidak ditemukan.'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      )
    );
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _onMarkerTapped(String kecName, LatLng location) {
     _animatedMapMove(location, 12.0);
     setState(() {
       _searchedLocation = location;
       _searchedKecamatan = kecName.toUpperCase();
     });
     if (widget.onKecamatanTapped != null) {
        widget.onKecamatanTapped!(kecName);
     }
  }

  Future<void> _loadGeoJson() async {
    try {
      // Reverted to optimized GeoJSON (from 1GB back to 2MB) because the raw file caused OOM / Loading crashes
      final String jsonString = await rootBundle.loadString('assets/map/semarang_filtered.geojson');
      final Map<String, dynamic> geoJson = jsonDecode(jsonString);
      
      // Parse Features
      if (geoJson['features'] != null) {
        for (var feature in geoJson['features']) {
          final geometry = feature['geometry'];
          final properties = feature['properties'] ?? {};
          final String kecamatanName = (properties['KECAMATAN'] ?? properties['nm_kecamatan'] ?? '').toString().toLowerCase();

          if (geometry != null) {
            String type = geometry['type'];
            List<dynamic> coords = geometry['coordinates'];

            if (type == 'Polygon') {
              final ring = coords[0];
              List<LatLng> points = [];
              double latSum = 0, lngSum = 0;
              for (var coord in ring) {
                points.add(LatLng(coord[1], coord[0]));
                latSum += coord[1]; lngSum += coord[0];
              }
              if (points.isNotEmpty && kecamatanName.isNotEmpty) {
                _kecamatanCenters[kecamatanName] = LatLng(latSum / points.length, lngSum / points.length);
              }
              _rawPolygons.add(GeoPolygon(kecamatanName, points));
            } else if (type == 'MultiPolygon') {
              for (var polygonCoords in coords) {
                final ring = polygonCoords[0];
                List<LatLng> points = [];
                double latSum = 0, lngSum = 0;
                for (var coord in ring) {
                  points.add(LatLng(coord[1], coord[0]));
                  latSum += coord[1]; lngSum += coord[0];
                }
                if (points.isNotEmpty && kecamatanName.isNotEmpty && !_kecamatanCenters.containsKey(kecamatanName)) {
                  _kecamatanCenters[kecamatanName] = LatLng(latSum / points.length, lngSum / points.length);
                }
                _rawPolygons.add(GeoPolygon(kecamatanName, points));
              }
            }
          }
        }
      }
      
      if (mounted) {
        _generatePolygons();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading GeoJSON: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generatePolygons() {
    List<Polygon> newPolygons = [];
    
    for (var geo in _rawPolygons) {
      Color fillColor = Colors.grey.withOpacity(0.2); 
      
      final forecasts = BmkgService.getForecast(geo.kecamatanName);
      if (forecasts != null && forecasts.isNotEmpty) {
        final f = forecasts.first; 
        
        if (_currentMode == MapMode.hujan) {
           fillColor = f.rainColor.withOpacity(0.4);
        } else if (_currentMode == MapMode.suhu) {
           fillColor = f.tempColor.withOpacity(0.4);
        } else if (_currentMode == MapMode.kelembapan) {
           fillColor = f.huColor.withOpacity(0.4);
        }
      }
      
      newPolygons.add(
        Polygon(
          points: geo.points,
          color: fillColor,
          isFilled: true,
          borderColor: Colors.transparent,
          borderStrokeWidth: 0.0,
        )
      );
    }
    
    if (mounted) {
      setState(() {
        _polygons = newPolygons;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(-7.025, 110.415), // Centered for whole Semarang
            initialZoom: 11.5, // Closer zoom per user request
            backgroundColor: SipandaTheme.background,
          ),
          children: [
            TileLayer(
               urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
               subdomains: const ['a', 'b', 'c', 'd'],
            ),
            PolygonLayer(
              polygons: _polygons,
            ),
            MarkerLayer(
              markers: _kecamatanCenters.entries.map((entry) {
                final isSelected = _searchedKecamatan == entry.key.toUpperCase();
                return Marker(
                  point: entry.value,
                  width: isSelected ? 80 : 40,
                  height: isSelected ? 80 : 40,
                  child: GestureDetector(
                    onTap: () => _onMarkerTapped(entry.key, entry.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.redAccent : SipandaTheme.primary,
                          size: isSelected ? 50 : 25,
                        ),
                        if (isSelected)
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                             decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                             child: Text(entry.key.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                           )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Mode Filter Buttons
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 140, left: 16),
            child: _buildMapFilter(),
          ),
        ),
        
        // Legend
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 140, right: 16),
            child: _buildLegend(),
          ),
        ),

        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: SipandaTheme.primary),
          ),
      ]
    );
  }

  Widget _buildMapFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterButton(MapMode.hujan, Icons.water_drop, 'Hujan'),
          _filterButton(MapMode.suhu, Icons.thermostat, 'Suhu'),
          _filterButton(MapMode.kelembapan, Icons.air, 'Lembap'),
        ],
      )
    );
  }

  Widget _filterButton(MapMode mode, IconData icon, String label) {
    final isActive = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
        _generatePolygons();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? SipandaTheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? SipandaTheme.primary : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? SipandaTheme.primary : Colors.grey))
          ],
        )
      )
    );
  }

  Widget _buildLegend() {
    String unit = '';
    String low = '', med = '', high = '';
    String lowLbl = 'Aman', medLbl = 'Waspada', highLbl = 'Bahaya';
    
    if (_currentMode == MapMode.hujan) {
      unit = 'Curah Hujan (mm)';
      low = '0-5'; med = '5-10'; high = '>10';
      lowLbl = 'Cerah'; medLbl = 'Sedang'; highLbl = 'Lebat';
    } else if (_currentMode == MapMode.suhu) {
      unit = 'Suhu (°C)';
      low = '0-30'; med = '30-35'; high = '>35';
      lowLbl = 'Normal'; medLbl = 'Panas'; highLbl = 'Sangat Panas';
    } else {
      unit = 'Kelembapan (%)';
      low = '60-100'; med = '40-60'; high = '<40';
      lowLbl = 'Lembap'; medLbl = 'Sedang'; highLbl = 'Kering';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prediksi 3 Jam: $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          _legendRow(Colors.greenAccent, low, lowLbl),
          const SizedBox(height: 4),
          _legendRow(Colors.orangeAccent, med, medLbl),
          const SizedBox(height: 4),
          _legendRow(Colors.redAccent, high, highLbl),
        ],
      )
    );
  }

  Widget _legendRow(Color color, String range, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        SizedBox(width: 40, child: Text(range, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
