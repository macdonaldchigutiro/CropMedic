import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeFromSplash();
  }

  Future<void> _routeFromSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('cropmedic_seen_onboarding') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
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
