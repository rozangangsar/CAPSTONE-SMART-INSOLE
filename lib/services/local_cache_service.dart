import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

final localCacheServiceProvider = Provider<LocalCacheService>(
  (ref) => LocalCacheService(),
);

class LocalCacheService {
  static const _sessionsKey = 'smart_insole_sessions';
  static const _baselineKey = 'smart_insole_calibration_baseline';
  static const _baselineUpdatedAtKey = 'smart_insole_calibration_updated_at';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<SessionRecord>> loadSessions() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SessionRecord.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  }

  Future<void> saveSession(SessionRecord session) async {
    final prefs = await _prefs;
    final sessions = await loadSessions();
    final updated = [session, ...sessions];
    await prefs.setString(
      _sessionsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<Map<String, double>> loadCalibrationBaseline() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_baselineKey);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: (entry.value as num?)?.toDouble() ?? 0,
    };
  }

  Future<void> saveCalibrationBaseline(Map<String, double> baseline) async {
    final prefs = await _prefs;
    await prefs.setString(_baselineKey, jsonEncode(baseline));
    await prefs.setString(
      _baselineUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> loadCalibrationUpdatedAt() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_baselineUpdatedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
