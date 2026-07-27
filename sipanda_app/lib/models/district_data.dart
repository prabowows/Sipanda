enum RiskLevel { aman, waspada, siaga }

class DistrictHistoryData {
  final String id;
  final DateTime timestamp;
  final double rainfall;
  final double temp;
  final double humidity;
  final double floodProbability;
  final RiskLevel mlRiskLevel;
  final String weatherDesc;

  DistrictHistoryData({
    required this.id,
    required this.timestamp,
    required this.rainfall,
    required this.temp,
    required this.humidity,
    required this.floodProbability,
    required this.mlRiskLevel,
    required this.weatherDesc,
  });

  factory DistrictHistoryData.fromFirestore(Map<String, dynamic> data, String documentId) {
    RiskLevel parseRisk(String val) {
      switch (val.toLowerCase()) {
        case 'siaga': return RiskLevel.siaga;
        case 'waspada': return RiskLevel.waspada;
        default: return RiskLevel.aman;
      }
    }

    DateTime parseTime(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      try {
        return raw.toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return DistrictHistoryData(
      id: documentId,
      timestamp: parseTime(data['timestamp']),
      rainfall: (data['rainfall'] ?? 0).toDouble(),
      temp: (data['temp'] ?? 28).toDouble(),
      humidity: (data['humidity'] ?? 75).toDouble(),
      floodProbability: (data['flood_prob'] ?? 0).toDouble(),
      mlRiskLevel: parseRisk(data['ml_risk'] ?? 'aman'),
      weatherDesc: data['weather_desc'] ?? 'Cerah',
    );
  }
}

class DistrictData {
  final String id;
  final String name;
  final RiskLevel mlRiskLevel;
  final RiskLevel? overriddenRiskLevel;
  final DateTime lastUpdated;
  final double currentRainfall;
  final double temp;
  final double humidity;
  final double floodProbability;
  final String weatherDesc;

  DistrictData({
    required this.id,
    required this.name,
    required this.mlRiskLevel,
    this.overriddenRiskLevel,
    required this.lastUpdated,
    required this.currentRainfall,
    required this.temp,
    required this.humidity,
    required this.floodProbability,
    required this.weatherDesc,
  });

  RiskLevel get activeRiskLevel => overriddenRiskLevel ?? mlRiskLevel;

  factory DistrictData.fromFirestore(Map<String, dynamic> data, String documentId) {
    RiskLevel parseRisk(String val) {
      switch (val.toLowerCase()) {
        case 'siaga': return RiskLevel.siaga;
        case 'waspada': return RiskLevel.waspada;
        default: return RiskLevel.aman;
      }
    }

    DateTime parseTime(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      try {
        return raw.toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return DistrictData(
      id: documentId,
      name: data['name'] ?? '',
      mlRiskLevel: parseRisk(data['ml_risk'] ?? 'aman'),
      overriddenRiskLevel: data['override_risk'] != null ? parseRisk(data['override_risk']) : null,
      lastUpdated: parseTime(data['last_updated']),
      currentRainfall: (data['rainfall'] ?? 0).toDouble(),
      temp: (data['temp'] ?? 28).toDouble(),
      humidity: (data['humidity'] ?? 75).toDouble(),
      floodProbability: (data['flood_prob'] ?? 0).toDouble(),
      weatherDesc: data['weather_desc'] ?? 'Cerah',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ml_risk': mlRiskLevel.name,
      'override_risk': overriddenRiskLevel?.name,
      'last_updated': lastUpdated,
      'rainfall': currentRainfall,
      'temp': temp,
      'humidity': humidity,
      'flood_prob': floodProbability,
      'weather_desc': weatherDesc,
    };
  }
}
