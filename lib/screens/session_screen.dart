import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionRecorderProvider);
    final notifier = ref.read(sessionRecorderProvider.notifier);
    final latest = state.latestData;
    final messenger = ScaffoldMessenger.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: notifier.setPatientName,
            decoration: const InputDecoration(
              labelText: 'Patient name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Text(
                  _formatElapsed(state.elapsed),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A237E),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.isRecording ? 'Recording live gait session' : 'Ready to record',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF55658D),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 22),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  width: state.isRecording ? 112 : 96,
                  height: state.isRecording ? 112 : 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (state.isRecording
                                ? const Color(0xFFD63649)
                                : const Color(0xFF1A237E))
                            .withValues(alpha: 0.28),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.large(
                    heroTag: 'session_fab',
                    backgroundColor: state.isRecording
                        ? const Color(0xFFD63649)
                        : const Color(0xFF1A237E),
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            if (state.isRecording) {
                              await notifier.stopRecording();
                              if (!mounted) {
                                return;
                              }
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Session saved')),
                              );
                              return;
                            }

                            notifier.setPatientName(_controller.text);
                            await notifier.startRecording();
                          },
                    child: Icon(
                      state.isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _LivePreviewCard(
                      label: 'Samples',
                      value: '${state.sampleCount}',
                    ),
                    _LivePreviewCard(
                      label: 'Result',
                      value: latest?.classification.result.toUpperCase() ?? '--',
                    ),
                    _LivePreviewCard(
                      label: 'Confidence',
                      value: latest == null
                          ? '--'
                          : '${(latest.classification.confidence * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: latest == null
                ? const Text('No live parameter preview yet')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live parameter preview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _LivePreviewCard(
                            label: 'Stance Phase',
                            value: '${latest.features.stancePhase.toStringAsFixed(1)} %',
                          ),
                          _LivePreviewCard(
                            label: 'Velocity',
                            value: '${latest.features.gaitVelocity.toStringAsFixed(2)} m/s',
                          ),
                          _LivePreviewCard(
                            label: 'Step Length',
                            value: '${latest.features.stepLength.toStringAsFixed(2)} m',
                          ),
                          _LivePreviewCard(
                            label: 'Stride Length',
                            value: '${latest.features.strideLength.toStringAsFixed(2)} m',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF55658D),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatElapsed(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
