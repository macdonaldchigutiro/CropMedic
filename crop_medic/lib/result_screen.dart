import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List image;
  final Diagnosis diagnosis;

  const ResultScreen({super.key, required this.image, required this.diagnosis});

  Color get _statusColor {
    if (diagnosis.lowConfidence) return Palette.amber;
    return diagnosis.isHealthy ? Palette.neonGreen : Palette.alert;
  }

  String get _statusLabel {
    if (diagnosis.lowConfidence) return 'NEEDS A SECOND LOOK';
    return diagnosis.isHealthy ? 'HEALTHY' : 'DISEASE DETECTED';
  }

  @override
  Widget build(BuildContext context) {
    final title = diagnosis.isHealthy ? 'Healthy leaf' : diagnosis.disease;
    final alternatives = diagnosis.topPredictions.length > 1
        ? diagnosis.topPredictions.skip(1).toList()
        : <PredictionCandidate>[];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Palette.text),
                  ),
                  const Text(
                    'SCAN RESULT',
                    style: TextStyle(
                      color: Palette.textDim,
                      letterSpacing: 3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(image, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Center(
                child: _ConfidenceRing(
                  value: diagnosis.confidence,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Palette.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                diagnosis.crop,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.textDim),
              ),
              if (diagnosis.lowConfidence) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Palette.amber),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'The image is not conclusive enough for a confident result. '
                          'Check the other possibilities below and confirm with an '
                          'agronomist or extension officer before treatment.',
                          style: TextStyle(color: Palette.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'OTHER POSSIBILITIES',
                  style: TextStyle(
                    color: Palette.neonCyan,
                    letterSpacing: 3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final candidate in alternatives)
                  _AlternativeTile(candidate: candidate),
              ],
              const SizedBox(height: 24),
              const Text(
                'WHAT TO DO',
                style: TextStyle(
                  color: Palette.neonCyan,
                  letterSpacing: 3,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < diagnosis.advice.length; i++)
                _AdviceTile(index: i, text: diagnosis.advice[i]),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: neonGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.neonGreen.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SCAN ANOTHER LEAF',
                      style: TextStyle(
                        color: Palette.bg,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  final PredictionCandidate candidate;

  const _AlternativeTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.disease,
                    style: const TextStyle(
                      color: Palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    candidate.crop,
                    style: const TextStyle(
                      color: Palette.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(candidate.confidence * 100).round()}%',
              style: const TextStyle(
                color: Palette.neonCyan,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  final int index;
  final String text;
  const _AdviceTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 250),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.neonGreen),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Palette.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Palette.text, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceRing extends StatelessWidget {
  final double value;
  final Color color;
  const _ConfidenceRing({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _RingPainter(v, color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}%',
                    style: const TextStyle(
                      color: Palette.text,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'CONFIDENCE',
                    style: TextStyle(
                      color: Palette.textDim,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  _RingPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = Palette.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * value;

    final glow = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
