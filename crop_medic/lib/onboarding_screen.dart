import 'package:flutter/material.dart';

import 'brand.dart';
import 'home_screen.dart';
import 'theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                          Row(
                            children: [
                              const CropMedicBrand(
                                compact: true,
                                showTagline: false,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _openHome(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Palette.primaryDark,
                                ),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
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
                          const _Benefit(
                            icon: Icons.camera_alt_rounded,
                            title: 'Scan crop leaves',
                            subtitle: 'Take a clear photo of one leaf.',
                          ),
                          const _Benefit(
                            icon: Icons.fact_check_rounded,
                            title: 'Get clear results',
                            subtitle: 'Know what CropMedic found quickly.',
                          ),
                          const _Benefit(
                            icon: Icons.spa_rounded,
                            title: 'Follow simple advice',
                            subtitle: 'Get practical next steps for your crop.',
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

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 19,
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
          ],
        ),
      ),
    );
  }
}
