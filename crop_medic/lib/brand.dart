import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

class CropMedicMark extends StatelessWidget {
  final double size;
  const CropMedicMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CropMedicMarkPainter()),
    );
  }
}

class _CropMedicMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftLeaf = Path()
      ..moveTo(w * .50, h * .90)
      ..cubicTo(w * .28, h * .80, w * .10, h * .62, w * .12, h * .30)
      ..cubicTo(w * .30, h * .33, w * .46, h * .48, w * .50, h * .90)
      ..close();

    final rightLeaf = Path()
      ..moveTo(w * .50, h * .90)
      ..cubicTo(w * .72, h * .80, w * .90, h * .62, w * .88, h * .30)
      ..cubicTo(w * .70, h * .33, w * .54, h * .48, w * .50, h * .90)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF083D2F), Color(0xFF176447)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [Color(0xFF2E714B), Color(0xFFA1B578)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(leftLeaf, leftPaint);
    canvas.drawPath(rightLeaf, rightPaint);

    final vein = Paint()
      ..color = const Color(0xFFF9F6EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .055
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * .50, h * .89), Offset(w * .31, h * .46), vein);
    canvas.drawLine(Offset(w * .50, h * .89), Offset(w * .69, h * .46), vein);

    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB98528), Color(0xFFE3C16A), Color(0xFFB98528)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .075
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: Offset(w * .50, h * .30),
      width: w * .56,
      height: h * .42,
    );
    canvas.drawArc(arcRect, math.pi * 1.12, math.pi * .76, false, gold);

    final crossPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6C66F), Color(0xFFB78125)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final cross = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .50, h * .30),
        width: w * .13,
        height: h * .31,
      ),
      Radius.circular(w * .02),
    );
    final crossBar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * .50, h * .30),
        width: w * .31,
        height: h * .13,
      ),
      Radius.circular(w * .02),
    );
    canvas.drawRRect(cross, crossPaint);
    canvas.drawRRect(crossBar, crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CropMedicBrand extends StatelessWidget {
  final bool compact;
  final bool showTagline;
  const CropMedicBrand({
    super.key,
    this.compact = false,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 43.0 : 58.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CropMedicMark(size: markSize),
        SizedBox(width: compact ? 9 : 13),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: compact ? 23 : 31,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Palette.primaryDark,
                  letterSpacing: -1.0,
                ),
                children: const [
                  TextSpan(text: 'Crop'),
                  TextSpan(
                    text: 'Medic',
                    style: TextStyle(color: Palette.primaryMid),
                  ),
                ],
              ),
            ),
            if (showTagline && !compact) ...[
              const SizedBox(height: 5),
              const Text(
                'AI crop health assistant',
                style: TextStyle(
                  color: Palette.textDim,
                  fontSize: 12.5,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class LanguagePill extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const LanguagePill({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const languages = {
    'en': 'English',
    'sn': 'Shona',
    'nd': 'Ndebele',
    'toi': 'Tonga',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A2E20),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          borderRadius: BorderRadius.circular(18),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: languages.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 18),
                      const SizedBox(width: 7),
                      Text(entry.value),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
