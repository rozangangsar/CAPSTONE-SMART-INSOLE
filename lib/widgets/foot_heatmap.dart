import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/gait_data.dart';

class FootHeatmap extends StatefulWidget {
  const FootHeatmap({
    super.key,
    required this.title,
    required this.pressure,
    required this.isRightFoot,
  });

  final String title;
  final FootPressure pressure;
  final bool isRightFoot;

  @override
  State<FootHeatmap> createState() => _FootHeatmapState();
}

class _FootHeatmapState extends State<FootHeatmap> {
  late Map<String, double> _from;
  late Map<String, double> _to;

  @override
  void initState() {
    super.initState();
    _from = Map<String, double>.from(widget.pressure.sensors);
    _to = Map<String, double>.from(widget.pressure.sensors);
  }

  @override
  void didUpdateWidget(covariant FootHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.pressure.sensors, widget.pressure.sensors)) {
      _from = Map<String, double>.from(_to);
      _to = Map<String, double>.from(widget.pressure.sensors);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avgPressure = widget.pressure.averagePressure;
    final accent = _zoneColor(avgPressure / 60);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              _MiniMetric(label: 'AVG', value: '${avgPressure.toStringAsFixed(1)} kPa'),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 0.62,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 380),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final interpolated = <String, double>{};
                for (var i = 1; i <= 16; i++) {
                  final key = 'p$i';
                  interpolated[key] =
                      lerpDouble(_from[key] ?? 0, _to[key] ?? 0, value) ?? 0;
                }

                return CustomPaint(
                  painter: _FootHeatmapPainter(
                    values: interpolated,
                    isRightFoot: widget.isRightFoot,
                    baseColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniMetric(
                label: 'HEEL',
                value: '${widget.pressure.heel.toStringAsFixed(1)} kPa',
              ),
              _MiniMetric(
                label: 'TOE',
                value: '${widget.pressure.toe.toStringAsFixed(1)} kPa',
              ),
              _MiniMetric(
                label: 'PEAK',
                value: '${widget.pressure.peakPressure.toStringAsFixed(1)} kPa',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF55658D),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _FootHeatmapPainter extends CustomPainter {
  _FootHeatmapPainter({
    required this.values,
    required this.isRightFoot,
    required this.baseColor,
  });

  final Map<String, double> values;
  final bool isRightFoot;
  final Color baseColor;

  static const _positions = <Offset>[
    Offset(0.49, 0.82),
    Offset(0.34, 0.78),
    Offset(0.64, 0.74),
    Offset(0.36, 0.67),
    Offset(0.58, 0.64),
    Offset(0.28, 0.57),
    Offset(0.46, 0.55),
    Offset(0.67, 0.55),
    Offset(0.32, 0.44),
    Offset(0.49, 0.41),
    Offset(0.66, 0.40),
    Offset(0.40, 0.28),
    Offset(0.58, 0.27),
    Offset(0.32, 0.15),
    Offset(0.50, 0.11),
    Offset(0.68, 0.14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = baseColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = baseColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.02)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.04,
        size.width * 0.02,
        size.height * 0.28,
        size.width * 0.10,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.84,
        size.width * 0.30,
        size.height * 0.98,
        size.width * 0.50,
        size.height * 0.98,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.98,
        size.width * 0.82,
        size.height * 0.84,
        size.width * 0.90,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.98,
        size.height * 0.28,
        size.width * 0.85,
        size.height * 0.04,
        size.width * 0.50,
        size.height * 0.02,
      )
      ..close();

    canvas.drawPath(path, outline);
    canvas.drawPath(path, stroke);

    for (var index = 0; index < _positions.length; index++) {
      final key = 'p${index + 1}';
      final point = _positions[index];
      final dx = (isRightFoot ? 1 - point.dx : point.dx) * size.width;
      final dy = point.dy * size.height;
      final value = values[key] ?? 0;
      final color = _zoneColor(value / 60);

      final zonePaint = Paint()
        ..color = color.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

      canvas.drawCircle(Offset(dx, dy), size.width * 0.082, glowPaint);
      canvas.drawCircle(Offset(dx, dy), size.width * 0.070, zonePaint);

      final idPainter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: value > 35 ? Colors.white : const Color(0xFF16224D),
            fontSize: size.width * 0.033,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      idPainter.paint(
        canvas,
        Offset(dx - idPainter.width / 2, dy - idPainter.height / 2 - 7),
      );

      final valuePainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: value > 35 ? Colors.white : const Color(0xFF16224D),
            fontSize: size.width * 0.026,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valuePainter.paint(
        canvas,
        Offset(dx - valuePainter.width / 2, dy - valuePainter.height / 2 + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FootHeatmapPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.isRightFoot != isRightFoot ||
        oldDelegate.baseColor != baseColor;
  }
}

Color _zoneColor(double normalized) {
  final value = normalized.clamp(0.0, 1.0);
  if (value < 0.5) {
    return Color.lerp(Colors.blue, Colors.yellow, value / 0.5)!;
  }
  return Color.lerp(Colors.yellow, Colors.red, (value - 0.5) / 0.5)!;
}
