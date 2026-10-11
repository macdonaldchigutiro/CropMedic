import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'brand.dart';
import 'scan_screen.dart';
import 'theme.dart';

class UnsupportedImageScreen extends StatelessWidget {
  final Uint8List image;
  final Diagnosis diagnosis;
  final String lang;

  const UnsupportedImageScreen({
    super.key,
    required this.image,
    required this.diagnosis,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                children: [
                  const CropMedicBrand(compact: true, showTagline: false),
                  const SizedBox(height: 26),
                  const Text(
                    'Try another photo',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Palette.primaryDark,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    color: const Color(0xFFF2F6E7),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.memory(
                                image,
                                width: double.infinity,
                                height: 190,
                                fit: BoxFit.cover,
                                color: Colors.white.withOpacity(0.12),
                                colorBlendMode: BlendMode.srcATop,
                              ),
                            ),
                            const Positioned(
                              right: 14,
                              top: -10,
                              child: CircleAvatar(
                                radius: 27,
                                backgroundColor: Palette.amber,
                                child: Icon(Icons.priority_high_rounded, color: Colors.white, size: 31),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "We couldn’t confirm this is a supported crop leaf.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: Palette.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          diagnosis.message ??
                              'Take a clear photo of one maize, tomato, potato, or bell pepper leaf.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Palette.textDim, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AppCard(
                    child: Column(
                      children: [
                        _TipRow(icon: Icons.eco_rounded, title: 'Use one leaf', text: 'Take a close-up of a single supported crop leaf.'),
                        _TipRow(icon: Icons.wb_sunny_outlined, title: 'Use good light', text: 'Natural daylight works best.'),
                        _TipRow(icon: Icons.center_focus_strong_rounded, title: 'Keep the leaf in focus', text: 'Make sure the leaf is sharp and not blurred.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Palette.alertSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.block_rounded, color: Palette.alert),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'CropMedic cannot diagnose faces, hands, other objects, or non-crop plants.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: 'Try again',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ScanScreen(lang: lang)),
                      );
                    },
                  ),
                  const SizedBox(height: 11),
                  SecondaryActionButton(
                    label: 'Back to home',
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TipRow({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(color: Palette.textDim, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
