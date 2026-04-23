import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gait_data.dart';
import '../services/local_cache_service.dart';
import 'websocket_provider.dart';

class CalibrationState {
  const CalibrationState({
    required this.isCalibrating,
    required this.baseline,
    required this.updatedAt,
    this.error,
  });

  final bool isCalibrating;
  final Map<String, double> baseline;
  final DateTime? updatedAt;
  final String? error;

  factory CalibrationState.initial() => const CalibrationState(
        isCalibrating: false,
        baseline: {},
        updatedAt: null,
      );

  CalibrationState copyWith({
    bool? isCalibrating,
    Map<String, double>? baseline,
    DateTime? updatedAt,
    String? error,
    bool clearError = false,
  }) {
    return CalibrationState(
      isCalibrating: isCalibrating ?? this.isCalibrating,
      baseline: baseline ?? this.baseline,
      updatedAt: updatedAt ?? this.updatedAt,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CalibrationNotifier extends StateNotifier<CalibrationState> {
  CalibrationNotifier(this.ref) : super(CalibrationState.initial()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    final cache = ref.read(localCacheServiceProvider);
    final baseline = await cache.loadCalibrationBaseline();
    final updatedAt = await cache.loadCalibrationUpdatedAt();
    state = state.copyWith(
      baseline: baseline,
      updatedAt: updatedAt,
      clearError: true,
    );
  }

  Future<void> startCalibration() async {
    state = state.copyWith(isCalibrating: true, clearError: true);
    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      final liveData = ref.read(websocketStreamProvider).valueOrNull;
      final baseline = _extractBaseline(liveData);
      final cache = ref.read(localCacheServiceProvider);
      await cache.saveCalibrationBaseline(baseline);
      state = state.copyWith(
        isCalibrating: false,
        baseline: baseline,
        updatedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isCalibrating: false,
        error: error.toString(),
      );
    }
  }

  Map<String, double> _extractBaseline(GaitData? liveData) {
    if (liveData == null) {
      return {
        for (var i = 1; i <= 16; i++) 'left_p$i': 0,
        for (var i = 1; i <= 16; i++) 'right_p$i': 0,
      };
    }

    return {
      for (final entry in liveData.left.sensors.entries)
        'left_${entry.key}': entry.value,
      for (final entry in liveData.right.sensors.entries)
        'right_${entry.key}': entry.value,
    };
  }
}

final calibrationProvider =
    StateNotifierProvider<CalibrationNotifier, CalibrationState>(
  CalibrationNotifier.new,
);

final calibrationBaselineValuesProvider = Provider<Map<String, double>>(
  (ref) => ref.watch(calibrationProvider).baseline,
);
