import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFFFBF8F0);
  static const bgTop = Color(0xFFF4F3E9);
  static const surface = Color(0xFFFFFEFA);
  static const surfaceSoft = Color(0xFFF2F6EE);
  static const primary = Color(0xFF126044);
  static const primaryDark = Color(0xFF083D2F);
  static const primaryMid = Color(0xFF1D7654);
  static const primarySoft = Color(0xFFE4F0E5);
  static const sage = Color(0xFF8EAA85);
  static const accent = Color(0xFF248B67);
  static const gold = Color(0xFFD5A238);
  static const goldSoft = Color(0xFFF8EAC4);
  static const amber = Color(0xFFE7A51A);
  static const alert = Color(0xFFB83C31);
  static const alertSoft = Color(0xFFFCE5E0);
  static const text = Color(0xFF15372D);
  static const textDim = Color(0xFF66766E);
  static const border = Color(0xFFDCE6DA);

  // Backwards-compatible aliases while older widgets are migrated.
  static const neonGreen = primary;
  static const neonCyan = accent;
  static const glass = surface;
  static const glassBorder = border;
}

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Palette.primaryDark, Palette.primaryMid],
);

const neonGradient = brandGradient;

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF6), Palette.bg, Color(0xFFF4F8F1)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _SoftOrb(color: Color(0x1A83B97B), size: 260),
          ),
          const Positioned(
            bottom: -120,
            left: -90,
            child: _SoftOrb(color: Color(0x16D5A238), size: 300),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _SoftOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Border? border;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.border,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100A2E20),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlassCard extends AppCard {
  const GlassCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(18),
    super.color,
  });
}

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Palette.primary.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: 25),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            if (!loading) const Icon(Icons.arrow_forward_rounded, size: 21),
          ],
        ),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.primaryDark,
          side: const BorderSide(color: Palette.primary, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
