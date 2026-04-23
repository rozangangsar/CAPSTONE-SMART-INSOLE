import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gait_data.dart';
import '../models/session.dart';
import '../services/local_cache_service.dart';
import 'websocket_provider.dart';

class SessionRecorderState {
  const SessionRecorderState({
    required this.patientName,
    required this.isRecording,
    required this.isSaving,
    required this.startedAt,
    required this.elapsed,
    required this.sampleCount,
    this.latestData,
    this.error,
  });

  final String patientName;
  final bool isRecording;
  final bool isSaving;
  final DateTime? startedAt;
  final Duration elapsed;
  final int sampleCount;
  final GaitData? latestData;
  final String? error;

  factory SessionRecorderState.initial() => const SessionRecorderState(
        patientName: '',
        isRecording: false,
        isSaving: false,
        startedAt: null,
        elapsed: Duration.zero,
        sampleCount: 0,
      );

  SessionRecorderState copyWith({
    String? patientName,
    bool? isRecording,
    bool? isSaving,
    DateTime? startedAt,
    Duration? elapsed,
    int? sampleCount,
    GaitData? latestData,
    String? error,
    bool clearStartedAt = false,
    bool clearError = false,
  }) {
    return SessionRecorderState(
      patientName: patientName ?? this.patientName,
      isRecording: isRecording ?? this.isRecording,
      isSaving: isSaving ?? this.isSaving,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      sampleCount: sampleCount ?? this.sampleCount,
      latestData: latestData ?? this.latestData,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final cachedSessionsProvider = FutureProvider<List<SessionRecord>>((ref) async {
  final cache = ref.watch(localCacheServiceProvider);
  return cache.loadSessions();
});

class SessionRecorderNotifier extends StateNotifier<SessionRecorderState> {
  SessionRecorderNotifier(this.ref) : super(SessionRecorderState.initial()) {
    ref.listen<AsyncValue<GaitData>>(websocketStreamProvider, (previous, next) {
      next.whenData(_onIncomingData);
    });
  }

  final Ref ref;
  Timer? _ticker;

  void setPatientName(String value) {
    state = state.copyWith(patientName: value, clearError: true);
  }

  Future<void> startRecording() async {
    final name = state.patientName.trim().isEmpty
        ? 'Unknown Patient'
        : state.patientName.trim();

    _ticker?.cancel();
    state = state.copyWith(
      patientName: name,
      isRecording: true,
      isSaving: false,
      startedAt: DateTime.now(),
      elapsed: Duration.zero,
      sampleCount: 0,
      clearError: true,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = state.startedAt;
      if (!state.isRecording || startedAt == null) {
        return;
      }
      state = state.copyWith(
        elapsed: DateTime.now().difference(startedAt),
      );
    });
  }

  Future<void> stopRecording() async {
    if (!state.isRecording || state.startedAt == null) {
      return;
    }

    _ticker?.cancel();
    state = state.copyWith(isSaving: true, isRecording: false, clearError: true);

    try {
      final session = SessionRecord.fromLiveData(
        patientName: state.patientName,
        startedAt: state.startedAt!,
        endedAt: DateTime.now(),
        sampleCount: state.sampleCount,
        latestData: state.latestData,
      );
      final cache = ref.read(localCacheServiceProvider);
      await cache.saveSession(session);
      ref.invalidate(cachedSessionsProvider);

      state = state.copyWith(
        isSaving: false,
        elapsed: Duration.zero,
        sampleCount: 0,
        clearStartedAt: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error.toString());
    }
  }

  void _onIncomingData(GaitData data) {
    if (!state.isRecording) {
      state = state.copyWith(latestData: data);
      return;
    }

    state = state.copyWith(
      latestData: data,
      sampleCount: state.sampleCount + 1,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final sessionRecorderProvider =
    StateNotifierProvider<SessionRecorderNotifier, SessionRecorderState>(
  SessionRecorderNotifier.new,
);
