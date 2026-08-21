import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/district_data.dart';

class DatabaseService {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get _db {
    try {
      _firestoreInstance ??= FirebaseFirestore.instance;
      return _firestoreInstance;
    } catch (e) {
      debugPrint("Firestore instance access info: $e");
      return null;
    }
  }

  double _parseNum(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is Map) {
      if (val['doubleValue'] != null) return double.tryParse(val['doubleValue'].toString()) ?? fallback;
      if (val['integerValue'] != null) return double.tryParse(val['integerValue'].toString()) ?? fallback;
    }
    return double.tryParse(val.toString()) ?? fallback;
  }

  // Stream active districts data for real-time map updates
  Stream<List<DistrictData>> streamDistricts() async* {
    if (_db != null) {
      try {
        yield* _db!.collection('districts').snapshots().map((snapshot) =>
            snapshot.docs.map((doc) => DistrictData.fromFirestore(doc.data(), doc.id)).toList());
        return;
      } catch (e) {
        debugPrint("Firestore stream error, falling back to REST: $e");
      }
    }

    // Fallback: Fetch via Firestore REST API if SDK stream fails or uninitialized
    try {
      final res = await http.get(Uri.parse('https://firestore.googleapis.com/v1/projects/sipanda-semarang/databases/(default)/documents/districts'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['documents'] != null) {
          List<DistrictData> list = [];
          for (var doc in json['documents']) {
            final nameParts = (doc['name'] as String).split('/');
            final docId = nameParts.last;
            final fields = doc['fields'] ?? {};
            
            Map<String, dynamic> rawMap = {
              'name': fields['name']?['stringValue'] ?? docId,
              'rainfall': _parseNum(fields['rainfall'], 0),
              'temp': _parseNum(fields['temp'], 28),
              'humidity': _parseNum(fields['humidity'], 75),
              'flood_prob': _parseNum(fields['flood_prob'], 10),
              'ml_risk': fields['ml_risk']?['stringValue'] ?? 'aman',
              'override_risk': fields['override_risk']?['stringValue'],
              'weather_desc': fields['weather_desc']?['stringValue'] ?? 'Cerah',
              'last_updated': fields['last_updated']?['timestampValue'] ?? DateTime.now().toIso8601String(),
            };

            list.add(DistrictData.fromFirestore(rawMap, docId));
          }
          yield list;
        }
      }
    } catch (e) {
      debugPrint("REST API fetch fallback error: $e");
    }
  }

  // Fetch historical time-series logs once (capped at max 10 recent items for clean UI)
  Future<List<DistrictHistoryData>> getDistrictHistory(String districtId, {int limit = 10}) async {
    List<DistrictHistoryData> list = [];

    if (_db != null) {
      try {
        final snapshot = await _db!
            .collection('districts')
            .doc(districtId)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        if (snapshot.docs.isNotEmpty) {
          list = snapshot.docs
              .map((doc) => DistrictHistoryData.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          if (list.length > limit) {
            list = list.sublist(list.length - limit);
          }
          return list;
        }
      } catch (e) {
        debugPrint("Firestore history SDK fetch error, falling back to REST: $e");
      }
    }

    // Fallback via REST API
    try {
      final url = 'https://firestore.googleapis.com/v1/projects/sipanda-semarang/databases/(default)/documents/districts/$districtId/history?pageSize=50';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['documents'] != null) {
          for (var doc in json['documents']) {
            final nameParts = (doc['name'] as String).split('/');
            final docId = nameParts.last;
            final fields = doc['fields'] ?? {};
            
            Map<String, dynamic> rawMap = {
              'timestamp': fields['timestamp']?['timestampValue'] ?? DateTime.now().toIso8601String(),
              'rainfall': _parseNum(fields['rainfall'], 0),
              'temp': _parseNum(fields['temp'], 28),
              'humidity': _parseNum(fields['humidity'], 75),
              'flood_prob': _parseNum(fields['flood_prob'], 10),
              'ml_risk': fields['ml_risk']?['stringValue'] ?? 'aman',
              'weather_desc': fields['weather_desc']?['stringValue'] ?? 'Cerah',
            };

            list.add(DistrictHistoryData.fromFirestore(rawMap, docId));
          }
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          if (list.length > limit) {
            list = list.sublist(list.length - limit);
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint("REST API history fetch error: $e");
    }

    return list;
  }

  // Fetch historical time-series logs filtered by date range for Excel Export
  Future<List<DistrictHistoryData>> getDistrictHistoryByDateRange(
    String districtId, {
    required DateTime startDate,
    required DateTime endDate,
    int limit = 500,
  }) async {
    List<DistrictHistoryData> list = [];
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    if (_db != null) {
      try {
        final snapshot = await _db!
            .collection('districts')
            .doc(districtId)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final all = snapshot.docs
              .map((doc) => DistrictHistoryData.fromFirestore(doc.data(), doc.id))
              .toList();
          return all.where((item) =>
            item.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
            item.timestamp.isBefore(end.add(const Duration(seconds: 1)))
          ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
      } catch (e) {
        debugPrint("Firestore range fetch error: $e");
      }
    }

    // Fallback via REST API
    try {
      final url = 'https://firestore.googleapis.com/v1/projects/sipanda-semarang/databases/(default)/documents/districts/$districtId/history?pageSize=100';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['documents'] != null) {
          for (var doc in json['documents']) {
            final nameParts = (doc['name'] as String).split('/');
            final docId = nameParts.last;
            final fields = doc['fields'] ?? {};

            Map<String, dynamic> rawMap = {
              'timestamp': fields['timestamp']?['timestampValue'] ?? DateTime.now().toIso8601String(),
              'rainfall': _parseNum(fields['rainfall'], 0),
              'temp': _parseNum(fields['temp'], 28),
              'humidity': _parseNum(fields['humidity'], 75),
              'flood_prob': _parseNum(fields['flood_prob'], 10),
              'ml_risk': fields['ml_risk']?['stringValue'] ?? 'aman',
              'weather_desc': fields['weather_desc']?['stringValue'] ?? 'Cerah',
            };

            final item = DistrictHistoryData.fromFirestore(rawMap, docId);
            if (item.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
                item.timestamp.isBefore(end.add(const Duration(seconds: 1)))) {
              list.add(item);
            }
          }
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        }
      }
    } catch (e) {
      debugPrint("REST API range history fetch error: $e");
    }

    return list;
  }

  // Set Manual Override from Admin Dashboard
  Future<void> setOverride(String districtId, RiskLevel newRisk) async {
    if (_db != null) {
      await _db!.collection('districts').doc(districtId).update({
        'override_risk': newRisk.name,
        'override_timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Clear Manual Override from Admin Dashboard
  Future<void> clearOverride(String districtId) async {
    if (_db != null) {
      await _db!.collection('districts').doc(districtId).update({
        'override_risk': FieldValue.delete(),
      });
    }
  }

  // Enter Ground Truth for ML Retraining
  Future<void> logGroundTruth(String districtId, bool wasFlooded) async {
    if (_db != null) {
      await _db!.collection('ground_truths').add({
        'district_id': districtId,
        'actual_flooded': wasFlooded,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update config variables
  Future<void> updateConfig(int apiIntervalMins, int uiRenderThrottleSecs) async {
    if (_db != null) {
      await _db!.collection('config').doc('system').set({
        'api_sync_interval_mins': apiIntervalMins,
        'ui_render_throttle_secs': uiRenderThrottleSecs,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
