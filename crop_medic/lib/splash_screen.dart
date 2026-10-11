import 'dart:async';

import 'package:flutter/material.dart';

import 'brand.dart';
import 'onboarding_screen.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CropMedicMark(size: 108),
                const SizedBox(height: 26),
                const CropMedicBrand(showTagline: false),
                const SizedBox(height: 12),
                const Text(
                  'AI crop health assistant',
                  style: TextStyle(
                    color: Palette.textDim,
                    fontSize: 16,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 42),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: Palette.gold,
                    backgroundColor: Palette.primarySoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
