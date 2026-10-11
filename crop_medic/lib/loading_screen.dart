import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'brand.dart';
import 'localization.dart';
import 'theme.dart';

class LoadingScreen extends StatelessWidget {
  final Uint8List image;
  final String lang;

  const LoadingScreen({super.key, required this.image, required this.lang});

  String tr(String key) => AppText.t(lang, key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CropMedicBrand(compact: true, showTagline: false),
                    ),
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 230,
                          height: 230,
                          child: CircularProgressIndicator(
                            strokeWidth: 8,
                            color: Palette.primary,
                            backgroundColor: Palette.primarySoft,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Image.memory(
                            image,
                            width: 172,
                            height: 172,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Text(
                      tr('checkingLeaf'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 31,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: Palette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('takesSeconds'),
                      style: const TextStyle(
                        color: Palette.textDim,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _ProgressStep(
                      icon: Icons.search_rounded,
                      text: tr('analysingLeaf'),
                    ),
                    _ProgressStep(
                      icon: Icons.auto_awesome_rounded,
                      text: tr('lookingProblems'),
                    ),
                    _ProgressStep(
                      icon: Icons.spa_rounded,
                      text: tr('findingAdvice'),
                    ),
                    const Spacer(),
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

class _ProgressStep extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ProgressStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 18,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Palette.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
