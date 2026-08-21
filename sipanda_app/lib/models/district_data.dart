enum RiskLevel { aman, waspada, siaga }

class ForecastPoint {
  final int hourOffset;
  final String timeLabel;
  final double rainfall;
  final double temp;
  final double humidity;
  final RiskLevel risk;
  final double floodProbability;
  final bool isPrediction;

  ForecastPoint({
    required this.hourOffset,
    required this.timeLabel,
    required this.rainfall,
    required this.temp,
    required this.humidity,
    required this.risk,
    required this.floodProbability,
    this.isPrediction = true,
  });

  factory ForecastPoint.fromMap(Map<String, dynamic> map) {
    RiskLevel parseRisk(String val) {
      switch (val.toLowerCase()) {
        case 'siaga': return RiskLevel.siaga;
        case 'waspada': return RiskLevel.waspada;
        default: return RiskLevel.aman;
      }
    }

    return ForecastPoint(
      hourOffset: (map['hour_offset'] ?? 1).toInt(),
      timeLabel: map['time_label'] ?? '+${map['hour_offset'] ?? 1} Jam',
      rainfall: (map['rainfall'] ?? 0.0).toDouble(),
      temp: (map['temp'] ?? 28.0).toDouble(),
      humidity: (map['humidity'] ?? 75.0).toDouble(),
      risk: parseRisk(map['risk'] ?? 'aman'),
      floodProbability: (map['flood_prob'] ?? 0.0).toDouble(),
      isPrediction: map['is_prediction'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour_offset': hourOffset,
      'time_label': timeLabel,
      'rainfall': rainfall,
      'temp': temp,
      'humidity': humidity,
      'risk': risk.name,
      'flood_prob': floodProbability,
      'is_prediction': isPrediction,
    };
  }
}

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
  final List<ForecastPoint> forecast3h;

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
    this.forecast3h = const [],
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

    List<ForecastPoint> parsedForecast = [];
    if (data['forecast_3h'] != null && data['forecast_3h'] is List) {
      parsedForecast = (data['forecast_3h'] as List)
          .map((item) => ForecastPoint.fromMap(Map<String, dynamic>.from(item)))
          .toList();
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
      forecast3h: parsedForecast,
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
      'forecast_3h': forecast3h.map((f) => f.toMap()).toList(),
    };
  }
}
