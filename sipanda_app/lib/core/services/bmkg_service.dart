import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/district_data.dart';

class WeatherData {
  final String datetime; // local_datetime
  final double t; // temp
  final double hu; // humidity
  final double tp; // rain
  final String weatherDesc; 

  WeatherData({
    required this.datetime,
    required this.t,
    required this.hu,
    required this.tp,
    required this.weatherDesc,
  });

  // Unified weather status labels and color mapping (matching map risk layer)
  String get rainLabel {
    if (tp > 10) return 'Lebat';
    if (tp >= 5) return 'Sedang';
    return 'Cerah';
  }

  Color get rainColor {
    if (tp > 10) return Colors.redAccent;
    if (tp >= 5) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String get tempLabel {
    if (t > 35) return 'Sangat Panas';
    if (t >= 30) return 'Panas';
    return 'Normal';
  }

  Color get tempColor {
    if (t > 35) return Colors.redAccent;
    if (t >= 30) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String get huLabel {
    if (hu < 40) return 'Kering';
    if (hu <= 60) return 'Sedang';
    return 'Lembap';
  }

  Color get huColor {
    if (hu < 40) return Colors.redAccent;
    if (hu <= 60) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}

class BmkgService {
  static const Map<String, String> kecamatanCodes = {
    'semarang tengah': '33.74.01',
    'semarang utara': '33.74.02',
    'semarang timur': '33.74.03',
    'gayamsari': '33.74.04',
    'genuk': '33.74.05',
    'pedurungan': '33.74.06',
    'semarang selatan': '33.74.07',
    'candisari': '33.74.08',
    'gajahmungkur': '33.74.09',
    'tembalang': '33.74.10',
    'banyumanik': '33.74.11',
    'gunungpati': '33.74.12',
    'semarang barat': '33.74.13',
    'mijen': '33.74.14',
    'ngaliyan': '33.74.15',
    'tugu': '33.74.16',
  };

  // Separate Cache for active state vs full history
  static final Map<String, List<WeatherData>> _activeCache = {};
  static final Map<String, List<WeatherData>> _historyCache = {};

  // Synchronize active cache directly from Firestore real-time district data
  static void updateFromFirestore(List<DistrictData> districts) {
    for (var district in districts) {
      final key = district.name.toLowerCase().trim();
      final item = WeatherData(
        datetime: district.lastUpdated.toIso8601String(),
        t: district.temp,
        hu: district.humidity,
        tp: district.currentRainfall,
        weatherDesc: district.weatherDesc,
      );
      _activeCache[key] = [item];
      
      // Do not overwrite history cache if history has already been fetched!
      if (!_historyCache.containsKey(key) || _historyCache[key]!.isEmpty) {
        _historyCache[key] = [item];
      }
    }
  }

  // Update history cache for a specific district with full historical time-series logs
  static void updateHistoryFromFirestore(String kecamatanName, List<DistrictHistoryData> historyList) {
    final key = kecamatanName.toLowerCase().trim();
    if (historyList.isEmpty) return;

    List<WeatherData> weatherList = historyList.map((h) => WeatherData(
      datetime: h.timestamp.toIso8601String(),
      t: h.temp,
      hu: h.humidity,
      tp: h.rainfall,
      weatherDesc: h.weatherDesc,
    )).toList();

    _historyCache[key] = weatherList;
  }

  // Fallback parallel fetch if offline / uninitialized
  static Future<void> fetchAllParallel() async {
    List<Future<void>> futures = [];
    for (var entry in kecamatanCodes.entries) {
      futures.add(_fetchSingle(entry.key, entry.value));
    }
    await Future.wait(futures);
  }

  static Future<void> _fetchSingle(String kecamatan, String code) async {
    try {
      final url = 'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=$code.1001';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<WeatherData> forecasts = [];
        
        if (data['data'] != null && data['data'].isNotEmpty) {
          final cuacaList = data['data'][0]['cuaca'] as List<dynamic>;
          
          if (cuacaList.isNotEmpty) {
            final todayArray = cuacaList[0];
            for (var item in todayArray) {
              forecasts.add(WeatherData(
                datetime: item['local_datetime'].toString(),
                t: double.tryParse(item['t'].toString()) ?? 0.0,
                hu: double.tryParse(item['hu'].toString()) ?? 0.0,
                tp: double.tryParse(item['tp'].toString()) ?? 0.0,
                weatherDesc: item['weather_desc'].toString(),
              ));
            }
          }
        }
        
        if (forecasts.isNotEmpty) {
          _activeCache[kecamatan] = forecasts;
          if (!_historyCache.containsKey(kecamatan)) {
            _historyCache[kecamatan] = forecasts;
          }
        }
      }
    } catch (e) {
      print('Error fetching $kecamatan: $e');
    }
  }

  // Get active forecast item for metric chips
  static List<WeatherData>? getForecast(String kecamatan) {
    return _activeCache[kecamatan.toLowerCase().trim()];
  }

  // Get full historical forecast array for time-series charts & history table
  static List<WeatherData>? getHistoryForecast(String kecamatan) {
    final key = kecamatan.toLowerCase().trim();
    return _historyCache[key] ?? _activeCache[key];
  }
}
