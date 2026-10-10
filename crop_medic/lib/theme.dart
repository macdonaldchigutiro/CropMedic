import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF050B14);
  static const bgTop = Color(0xFF0A1B2E);
  static const neonGreen = Color(0xFF00FF9D);
  static const neonCyan = Color(0xFF00E5FF);
  static const amber = Color(0xFFFFB020);
  static const alert = Color(0xFFFF5C7A);
  static const text = Color(0xFFE8F4FF);
  static const textDim = Color(0xFF7F98B2);
  static const glass = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
}

const neonGradient = LinearGradient(
  colors: [Palette.neonGreen, Palette.neonCyan],
);

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bgTop, Palette.bg],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _glow(Palette.neonCyan, 300),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _glow(Palette.neonGreen, 320),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glow(Color c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [c.withOpacity(0.16), c.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.glassBorder),
      ),
      child: child,
    );
  }
}
