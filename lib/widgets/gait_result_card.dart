import 'package:flutter/material.dart';

import '../models/gait_data.dart';

class GaitResultCard extends StatelessWidget {
  const GaitResultCard({
    super.key,
    required this.classification,
  });

  final GaitClassification classification;

  @override
  Widget build(BuildContext context) {
    final isNormal = classification.isNormal;
    final accent = isNormal ? const Color(0xFF1B8E5A) : const Color(0xFFD63649);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isNormal ? 'NORMAL' : 'ABNORMAL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(classification.confidence * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          if (!isNormal && classification.condition != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(classification.condition!),
                  backgroundColor: accent.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Confidence score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: classification.confidence.clamp(0.0, 1.0),
              backgroundColor: accent.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}
