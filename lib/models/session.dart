import 'gait_data.dart';

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.patientName,
    required this.startedAt,
    required this.endedAt,
    required this.result,
    this.condition,
    required this.confidence,
    required this.sampleCount,
    required this.features,
    required this.leftAveragePressure,
    required this.rightAveragePressure,
  });

  final String id;
  final String patientName;
  final DateTime startedAt;
  final DateTime endedAt;
  final String result;
  final String? condition;
  final double confidence;
  final int sampleCount;
  final Map<String, double> features;
  final double leftAveragePressure;
  final double rightAveragePressure;

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as Map<String, dynamic>? ?? {};
    return SessionRecord(
      id: json['id'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown Patient',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endedAt:
          DateTime.tryParse(json['endedAt'] as String? ?? '') ?? DateTime.now(),
      result: json['result'] as String? ?? 'unknown',
      condition: json['condition'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      features: {
        for (final entry in rawFeatures.entries)
          entry.key: (entry.value as num?)?.toDouble() ?? 0,
      },
      leftAveragePressure:
          (json['leftAveragePressure'] as num?)?.toDouble() ?? 0,
      rightAveragePressure:
          (json['rightAveragePressure'] as num?)?.toDouble() ?? 0,
    );
  }

  factory SessionRecord.fromLiveData({
    required String patientName,
    required DateTime startedAt,
    required DateTime endedAt,
    required int sampleCount,
    required GaitData? latestData,
  }) {
    final features = latestData?.features.asMap() ?? <String, double>{};
    return SessionRecord(
      id: '${startedAt.microsecondsSinceEpoch}-${endedAt.microsecondsSinceEpoch}',
      patientName: patientName,
      startedAt: startedAt,
      endedAt: endedAt,
      result: latestData?.classification.result ?? 'unknown',
      condition: latestData?.classification.condition,
      confidence: latestData?.classification.confidence ?? 0,
      sampleCount: sampleCount,
      features: features,
      leftAveragePressure: latestData?.left.averagePressure ?? 0,
      rightAveragePressure: latestData?.right.averagePressure ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'result': result,
        'condition': condition,
        'confidence': confidence,
        'sampleCount': sampleCount,
        'features': features,
        'leftAveragePressure': leftAveragePressure,
        'rightAveragePressure': rightAveragePressure,
      };

  bool get isNormal => result.toLowerCase() == 'normal';

  double get leftWeightRatio {
    final total = leftAveragePressure + rightAveragePressure;
    if (total == 0) {
      return 0.5;
    }
    return leftAveragePressure / total;
  }

  double get rightWeightRatio => 1 - leftWeightRatio;
}
