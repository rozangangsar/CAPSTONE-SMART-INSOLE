import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gait_data.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/websocket_provider.dart';
import '../widgets/parameter_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _normalRanges = <String, String>{
    'stance_phase': '60-62 %',
    'gait_velocity': '1.0-1.4 m/s',
    'step_length': '0.5-0.8 m',
    'double_support_time': '0.18-0.24 s',
    'stride_length': '1.1-1.5 m',
    'step_frequency': '90-120 steps/min',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(cachedSessionsProvider);
    final liveData = ref.watch(websocketStreamProvider).valueOrNull;

    return sessionsAsync.when(
      data: (sessions) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TabBar(
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Parameters'),
                  Tab(text: 'Charts'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ParametersTab(
                    liveData: liveData,
                    latestSession: sessions.isEmpty ? null : sessions.first,
                    normalRanges: _normalRanges,
                  ),
                  _ChartsTab(sessions: sessions),
                  _HistoryTab(sessions: sessions),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
    );
  }
}

class _ParametersTab extends StatelessWidget {
  const _ParametersTab({
    required this.liveData,
    required this.latestSession,
    required this.normalRanges,
  });

  final GaitData? liveData;
  final SessionRecord? latestSession;
  final Map<String, String> normalRanges;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) {
      return const Center(
        child: Text('No live parameters or saved sessions yet'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Parameter')),
              DataColumn(label: Text('Left')),
              DataColumn(label: Text('Right')),
              DataColumn(label: Text('Normal Range')),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(Text(row.label)),
                    DataCell(Text(row.left)),
                    DataCell(Text(row.right)),
                    DataCell(Text(row.normalRange)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ParameterRow> _buildRows() {
    final sourceMap = liveData?.features.asMap() ?? latestSession?.features;
    if (sourceMap == null || sourceMap.isEmpty) {
      return const [];
    }

    final leftRatio = _leftBias();
    final items = <_ParameterRow>[];

    for (final entry in normalRanges.entries) {
      final value = sourceMap[entry.key] ?? 0;
      final delta = (leftRatio - 0.5) * 0.35;
      final left = value * (1 + delta);
      final right = value * (1 - delta);

      items.add(
        _ParameterRow(
          label: _labelFor(entry.key),
          left: _format(entry.key, left),
          right: _format(entry.key, right),
          normalRange: entry.value,
        ),
      );
    }

    return items;
  }

  double _leftBias() {
    if (liveData != null) {
      final total = liveData!.left.averagePressure + liveData!.right.averagePressure;
      if (total == 0) {
        return 0.5;
      }
      return liveData!.left.averagePressure / total;
    }
    return latestSession?.leftWeightRatio ?? 0.5;
  }

  String _labelFor(String key) {
    switch (key) {
      case 'stance_phase':
        return 'Stance phase %';
      case 'gait_velocity':
        return 'Gait velocity';
      case 'step_length':
        return 'Step length';
      case 'double_support_time':
        return 'Double support time';
      case 'stride_length':
        return 'Stride length';
      case 'step_frequency':
        return 'Step frequency';
      default:
        return key;
    }
  }

  String _format(String key, double value) {
    switch (key) {
      case 'stance_phase':
        return '${value.toStringAsFixed(1)} %';
      case 'gait_velocity':
      case 'step_length':
      case 'stride_length':
        return '${value.toStringAsFixed(2)} m';
      case 'double_support_time':
        return '${value.toStringAsFixed(2)} s';
      case 'step_frequency':
        return value.toStringAsFixed(1);
      default:
        return value.toStringAsFixed(2);
    }
  }
}

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({
    required this.sessions,
  });

  final List<SessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ParameterLineChart(
              sessions: sessions,
              metricKey: 'gait_velocity',
              title: 'Gait Velocity Over Sessions',
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SymmetryBarChart(sessions: sessions),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.sessions,
  });

  final List<SessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No recorded sessions yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final accent =
            session.isNormal ? const Color(0xFF1B8E5A) : const Color(0xFFD63649);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.10),
                foregroundColor: accent,
                child: Icon(session.isNormal ? Icons.check : Icons.warning_amber),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.patientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.endedAt.day}/${session.endedAt.month}/${session.endedAt.year} | ${session.endedAt.hour.toString().padLeft(2, '0')}:${session.endedAt.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF65759E),
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    session.isNormal ? 'Normal' : 'Abnormal',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(session.confidence * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParameterRow {
  const _ParameterRow({
    required this.label,
    required this.left,
    required this.right,
    required this.normalRange,
  });

  final String label;
  final String left;
  final String right;
  final String normalRange;
}
