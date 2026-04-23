class FootPressure {
  FootPressure({
    required this.sensors,
    required this.heel,
    required this.toe,
  });

  final Map<String, double> sensors;
  final double heel;
  final double toe;

  factory FootPressure.fromJson(Map<String, dynamic> json) {
    final sensors = <String, double>{};
    for (var index = 1; index <= 16; index++) {
      final key = 'p$index';
      sensors[key] = (json[key] as num?)?.toDouble() ?? 0;
    }

    return FootPressure(
      sensors: sensors,
      heel: (json['heel'] as num?)?.toDouble() ?? 0,
      toe: (json['toe'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        ...sensors,
        'heel': heel,
        'toe': toe,
      };

  double get averagePressure {
    if (sensors.isEmpty) {
      return 0;
    }
    return sensors.values.reduce((a, b) => a + b) / sensors.length;
  }

  double get peakPressure {
    if (sensors.isEmpty) {
      return 0;
    }
    return sensors.values.reduce((a, b) => a > b ? a : b);
  }
}

class GaitClassification {
  const GaitClassification({
    required this.result,
    this.condition,
    required this.confidence,
  });

  final String result;
  final String? condition;
  final double confidence;

  factory GaitClassification.fromJson(Map<String, dynamic> json) {
    return GaitClassification(
      result: (json['result'] as String? ?? 'unknown').toLowerCase(),
      condition: json['condition'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'result': result,
        'condition': condition,
        'confidence': confidence,
      };

  bool get isNormal => result == 'normal';
}

class GaitFeatures {
  const GaitFeatures({
    required this.stancePhase,
    required this.gaitVelocity,
    required this.stepLength,
    required this.doubleSupportTime,
    required this.strideLength,
    required this.stepFrequency,
    required this.symmetryIndex,
  });

  final double stancePhase;
  final double gaitVelocity;
  final double stepLength;
  final double doubleSupportTime;
  final double strideLength;
  final double stepFrequency;
  final double symmetryIndex;

  factory GaitFeatures.fromJson(Map<String, dynamic> json) {
    return GaitFeatures(
      stancePhase: (json['stance_phase'] as num?)?.toDouble() ?? 0,
      gaitVelocity: (json['gait_velocity'] as num?)?.toDouble() ?? 0,
      stepLength: (json['step_length'] as num?)?.toDouble() ?? 0,
      doubleSupportTime:
          (json['double_support_time'] as num?)?.toDouble() ?? 0,
      strideLength: (json['stride_length'] as num?)?.toDouble() ?? 0,
      stepFrequency: (json['step_frequency'] as num?)?.toDouble() ?? 0,
      symmetryIndex: (json['symmetry_index'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stance_phase': stancePhase,
        'gait_velocity': gaitVelocity,
        'step_length': stepLength,
        'double_support_time': doubleSupportTime,
        'stride_length': strideLength,
        'step_frequency': stepFrequency,
        'symmetry_index': symmetryIndex,
      };

  Map<String, double> asMap() => {
        'stance_phase': stancePhase,
        'gait_velocity': gaitVelocity,
        'step_length': stepLength,
        'double_support_time': doubleSupportTime,
        'stride_length': strideLength,
        'step_frequency': stepFrequency,
        'symmetry_index': symmetryIndex,
      };
}

class GaitData {
  const GaitData({
    required this.timestamp,
    required this.left,
    required this.right,
    required this.classification,
    required this.features,
  });

  final int timestamp;
  final FootPressure left;
  final FootPressure right;
  final GaitClassification classification;
  final GaitFeatures features;

  factory GaitData.fromJson(Map<String, dynamic> json) {
    return GaitData(
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      left: FootPressure.fromJson(json['left'] as Map<String, dynamic>? ?? {}),
      right:
          FootPressure.fromJson(json['right'] as Map<String, dynamic>? ?? {}),
      classification: GaitClassification.fromJson(
        json['classification'] as Map<String, dynamic>? ?? {},
      ),
      features: GaitFeatures.fromJson(
        json['features'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'left': left.toJson(),
        'right': right.toJson(),
        'classification': classification.toJson(),
        'features': features.toJson(),
      };

  DateTime get recordedAt =>
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
}
