import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/session.dart';

class ParameterLineChart extends StatelessWidget {
  const ParameterLineChart({
    super.key,
    required this.sessions,
    required this.metricKey,
    required this.title,
    required this.color,
  });

  final List<SessionRecord> sessions;
  final String metricKey;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _ChartShell(
        title: title,
        child: const _EmptyChart(message: 'No sessions cached yet'),
      );
    }

    final recent = sessions.take(8).toList().reversed.toList();
    final spots = <FlSpot>[
      for (var index = 0; index < recent.length; index++)
        FlSpot(index.toDouble(), recent[index].features[metricKey] ?? 0),
    ];

    return _ChartShell(
      title: title,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _intervalFor(spots),
            getDrawingHorizontalLine: (value) => FlLine(
              color: color.withValues(alpha: 0.10),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recent.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${recent[index].endedAt.day}/${recent[index].endedAt.month}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3.5,
              color: color,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SymmetryBarChart extends StatelessWidget {
  const SymmetryBarChart({
    super.key,
    required this.sessions,
  });

  final List<SessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _ChartShell(
        title: 'Symmetry Index',
        child: _EmptyChart(message: 'No symmetry history yet'),
      );
    }

    final recent = sessions.take(6).toList().reversed.toList();
    return _ChartShell(
      title: 'Symmetry Index',
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 25,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1A237E).withValues(alpha: 0.10),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recent.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      recent[index].patientName.split(' ').first,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < recent.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: recent[i].features['symmetry_index'] ?? 0,
                    width: 22,
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A237E),
                        Color(0xFF4FC3F7),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1A237E).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65759E),
            ),
      ),
    );
  }
}

double _intervalFor(List<FlSpot> spots) {
  if (spots.isEmpty) {
    return 1;
  }
  final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  if (maxY <= 1) {
    return 0.25;
  }
  if (maxY <= 5) {
    return 1;
  }
  if (maxY <= 25) {
    return 5;
  }
  return 10;
}
