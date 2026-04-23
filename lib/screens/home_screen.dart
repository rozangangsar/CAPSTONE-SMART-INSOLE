import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gait_data.dart';
import '../providers/websocket_provider.dart';
import '../widgets/foot_heatmap.dart';
import '../widgets/gait_result_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveData = ref.watch(websocketStreamProvider);

    return liveData.when(
      data: (data) => _HomeContent(data: data),
      loading: () => const _CenteredState(
        icon: Icons.wifi_tethering,
        title: 'Connecting to gait stream',
        subtitle: 'Waiting for smart insole data...',
      ),
      error: (error, stackTrace) => const _CenteredState(
        icon: Icons.wifi_off,
        title: 'WebSocket connection failed',
        subtitle: 'Check endpoint and insole stream source.',
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.data,
  });

  final GaitData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 940;
          final heatmaps = stacked
              ? Column(
                  children: [
                    FootHeatmap(
                      title: 'Left Foot',
                      pressure: data.left,
                      isRightFoot: false,
                    ),
                    const SizedBox(height: 16),
                    FootHeatmap(
                      title: 'Right Foot',
                      pressure: data.right,
                      isRightFoot: true,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: FootHeatmap(
                        title: 'Left Foot',
                        pressure: data.left,
                        isRightFoot: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FootHeatmap(
                        title: 'Right Foot',
                        pressure: data.right,
                        isRightFoot: true,
                      ),
                    ),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveBanner(recordedAt: data.recordedAt),
              const SizedBox(height: 16),
              heatmaps,
              const SizedBox(height: 16),
              GaitResultCard(classification: data.classification),
              const SizedBox(height: 16),
              _FeatureGrid(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({
    required this.recordedAt,
  });

  final DateTime recordedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFF4EE39A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Live stream active | ${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}:${recordedAt.second.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.data,
  });

  final GaitData data;

  @override
  Widget build(BuildContext context) {
    final features = <MapEntry<String, String>>[
      MapEntry('Stance Phase', '${data.features.stancePhase.toStringAsFixed(1)} %'),
      MapEntry('Gait Velocity', '${data.features.gaitVelocity.toStringAsFixed(2)} m/s'),
      MapEntry('Step Length', '${data.features.stepLength.toStringAsFixed(2)} m'),
      MapEntry(
        'Double Support',
        '${data.features.doubleSupportTime.toStringAsFixed(2)} s',
      ),
      MapEntry('Stride Length', '${data.features.strideLength.toStringAsFixed(2)} m'),
      MapEntry(
        'Step Frequency',
        '${data.features.stepFrequency.toStringAsFixed(1)} steps/min',
      ),
      MapEntry('Symmetry Index', '${data.features.symmetryIndex.toStringAsFixed(1)} %'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final feature in features)
          Container(
            width: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1A237E).withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.key,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF55658D),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF1A237E)),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65759E),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
