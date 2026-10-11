import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFFF4F7F2);
  static const bgTop = Color(0xFFE8F3E6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF0F6EF);
  static const primary = Color(0xFF2F7D32);
  static const primaryDark = Color(0xFF1F5E25);
  static const primarySoft = Color(0xFFDFF0DD);
  static const accent = Color(0xFF2B8C7D);
  static const amber = Color(0xFFE89B18);
  static const alert = Color(0xFFC74444);
  static const text = Color(0xFF183022);
  static const textDim = Color(0xFF68796D);
  static const border = Color(0xFFDCE7DC);

  // Backwards-compatible aliases while older widgets are migrated.
  static const neonGreen = primary;
  static const neonCyan = accent;
  static const glass = surface;
  static const glassBorder = border;
}

const neonGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Palette.primary, Palette.accent],
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
          colors: [Palette.bgTop, Palette.bg, Palette.bg],
          stops: [0, 0.34, 1],
        ),
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E2B16),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
