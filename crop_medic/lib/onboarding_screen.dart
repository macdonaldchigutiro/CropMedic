import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand.dart';
import 'home_screen.dart';
import 'theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _openHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cropmedic_seen_onboarding', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> points,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Palette.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Palette.primary, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Palette.primaryDark,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: Palette.textDim,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final point in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Palette.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(fontSize: 14.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryActionButton(
                    label: 'Continue to CropMedic',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openHome(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const imageUrl =
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=900&q=85';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                color: Palette.bg.withOpacity(0.97),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CropMedicBrand(
                              compact: true,
                              showTagline: false,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Healthy crops\nstart with\none photo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 38,
                              height: 0.98,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.1,
                              color: Palette.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'Detect crop problems early and get expert guidance in seconds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.textDim,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox(
                              height: 205,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFDCEBD6),
                                            Color(0xFFF2E5B8),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.eco_rounded,
                                          size: 115,
                                          color: Palette.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x12000000),
                                          Color(0x33083D2F),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 18,
                                    bottom: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xEFFFFFFF),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(999),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 17,
                                            color: Palette.gold,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Simple crop diagnosis',
                                            style: TextStyle(
                                              color: Palette.primaryDark,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Benefit(
                            icon: Icons.camera_alt_rounded,
                            title: 'Scan crop leaves',
                            subtitle: 'Take a clear photo of one leaf.',
                            onTap: () => _showFeature(
                              context,
                              icon: Icons.camera_alt_rounded,
                              title: 'Scan crop leaves',
                              description:
                                  'CropMedic guides you to take a clear leaf photo before sending it for diagnosis.',
                              points: const [
                                'Photograph one whole leaf in good light.',
                                'Use the camera or choose an existing photo.',
                                'Unclear or unsupported photos can be rejected instead of forcing a diagnosis.',
                              ],
                            ),
                          ),
                          _Benefit(
                            icon: Icons.fact_check_rounded,
                            title: 'Get clear results',
                            subtitle: 'Know what CropMedic found quickly.',
                            onTap: () => _showFeature(
                              context,
                              icon: Icons.fact_check_rounded,
                              title: 'Get clear results',
                              description:
                                  'Results are designed to be easy to understand, with the crop, likely problem and confidence shown clearly.',
                              points: const [
                                'See whether the leaf appears healthy or diseased.',
                                'See the main diagnosis and confidence level.',
                                'Low-confidence results ask for another photo instead of pretending to be certain.',
                              ],
                            ),
                          ),
                          _Benefit(
                            icon: Icons.spa_rounded,
                            title: 'Follow simple advice',
                            subtitle: 'Get practical next steps for your crop.',
                            onTap: () => _showFeature(
                              context,
                              icon: Icons.spa_rounded,
                              title: 'Follow simple advice',
                              description:
                                  'CropMedic turns the result into practical next steps and tells you when professional help is sensible.',
                              points: const [
                                'Read simple crop-care and prevention guidance.',
                                'Use the disease library and weather-risk tools for more context.',
                                'Create a printable report to keep or share with an extension officer.',
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      decoration: const BoxDecoration(
                        color: Palette.bg,
                        border: Border(
                          top: BorderSide(color: Palette.border),
                        ),
                      ),
                      child: PrimaryActionButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => _openHome(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Palette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Palette.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Palette.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Palette.textDim,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Palette.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
