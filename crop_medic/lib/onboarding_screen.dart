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
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                children: [
                  Row(
                    children: [
                      const CropMedicBrand(compact: true, showTagline: false),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openHome(context),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Healthy crops start with one photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: Palette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Detect crop problems early and get simple, practical guidance in seconds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Palette.textDim,
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDDEDD7), Color(0xFFF5EBCB)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: const [
                        Positioned(
                          right: 26,
                          bottom: 18,
                          child: Icon(Icons.eco_rounded, size: 140, color: Color(0xFF4D9361)),
                        ),
                        Positioned(
                          left: 28,
                          top: 28,
                          child: CropMedicMark(size: 72),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Benefit(
                    icon: Icons.camera_alt_rounded,
                    title: 'Scan crop leaves',
                    subtitle: 'Take one clear photo of a leaf.',
                  ),
                  const _Benefit(
                    icon: Icons.fact_check_rounded,
                    title: 'Get clear results',
                    subtitle: 'See what CropMedic found in plain language.',
                  ),
                  const _Benefit(
                    icon: Icons.spa_rounded,
                    title: 'Follow simple advice',
                    subtitle: 'Get practical next steps you can use in the field.',
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _openHome(context),
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        radius: 18,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Palette.primary, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Palette.textDim, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
