import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

class ScannerFrame extends StatefulWidget {
  final Uint8List? image;
  final bool busy;
  const ScannerFrame({super.key, this.image, this.busy = false});

  @override
  State<ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<ScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: const Color(0xFF08131F),
              child: widget.image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.eco_rounded,
                            size: 64, color: Palette.neonGreen),
                        SizedBox(height: 12),
                        Text(
                          'Place one leaf in the frame',
                          style: TextStyle(color: Palette.textDim),
                        ),
                      ],
                    )
                  : Image.memory(widget.image!, fit: BoxFit.cover),
            ),
          ),
          if (widget.busy)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(color: Palette.bg.withOpacity(0.45)),
            ),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final y = 16 + (h - 32) * Curves.easeInOut.transform(_c.value);
              return Positioned(
                left: 16,
                right: 16,
                top: y,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: neonGradient,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.neonGreen.withOpacity(0.7),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: CustomPaint(painter: _BracketPainter()),
          ),
          if (widget.busy)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Palette.neonGreen,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ANALYSING LEAF',
                    style: TextStyle(
                      color: Palette.neonGreen,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.neonCyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = Palette.neonCyan.withOpacity(0.35)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    const m = 10.0;
    const l = 36.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(m, m + l)
      ..lineTo(m, m)
      ..lineTo(m + l, m)
      ..moveTo(w - m - l, m)
      ..lineTo(w - m, m)
      ..lineTo(w - m, m + l)
      ..moveTo(m, h - m - l)
      ..lineTo(m, h - m)
      ..lineTo(m + l, h - m)
      ..moveTo(w - m - l, h - m)
      ..lineTo(w - m, h - m)
      ..lineTo(w - m, h - m - l);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
