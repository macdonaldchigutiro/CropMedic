import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'diagnosis_flow.dart';
import 'scan_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  String _lang = 'en';
  bool _busy = false;

  Future<void> _pickGallery() async {
    if (_busy) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() => _busy = true);
    await startDiagnosisFlow(context, bytes, _lang);
    if (mounted) setState(() => _busy = false);
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanScreen(lang: _lang)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _hero(),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: 'Scan a leaf',
                    icon: Icons.camera_alt_rounded,
                    onPressed: _busy ? null : _openScan,
                  ),
                  const SizedBox(height: 11),
                  SecondaryActionButton(
                    label: 'Upload photo',
                    icon: Icons.photo_library_rounded,
                    onPressed: _busy ? null : _pickGallery,
                  ),
                  const SizedBox(height: 14),
                  _supportedCrops(),
                  const SizedBox(height: 26),
                  _howItWorks(),
                  const SizedBox(height: 18),
                  _photoTips(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Palette.surface,
            border: Border(top: BorderSide(color: Palette.border)),
          ),
          child: NavigationBar(
            selectedIndex: 0,
            backgroundColor: Palette.surface,
            indicatorColor: Palette.primarySoft,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Scan'),
              NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
              NavigationDestination(icon: Icon(Icons.help_outline_rounded), label: 'Help'),
            ],
            onDestinationSelected: (index) {
              if (index == 1) {
                _openScan();
              } else if (index == 2 || index == 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(index == 2 ? 'History is coming next.' : 'Help is coming next.')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const CropMedicBrand(compact: true, showTagline: false),
        const Spacer(),
        LanguagePill(
          value: _lang,
          enabled: !_busy,
          onChanged: (value) {
            if (value != null) setState(() => _lang = value);
          },
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F4DD), Color(0xFFE5F0DF), Color(0xFFF7EBC8)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x100A2E20), blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            bottom: -14,
            child: Icon(Icons.eco_rounded, size: 150, color: Color(0x594E955D)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Healthy crops start with one photo',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                    color: Palette.primaryDark,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Find crop problems early and get practical guidance in seconds.',
                  style: TextStyle(
                    color: Palette.textDim,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportedCrops() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.border),
      ),
      child: const Row(
        children: [
          _CropBadge(icon: Icons.grass_rounded, label: 'Maize'),
          _CropBadge(icon: Icons.local_florist_rounded, label: 'Tomato'),
          _CropBadge(icon: Icons.spa_rounded, label: 'Potato'),
          _CropBadge(icon: Icons.eco_rounded, label: 'Pepper'),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Palette.primaryDark),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: _StepCard(number: '1', icon: Icons.camera_alt_rounded, title: 'Take photo', text: 'Snap one clear leaf.')),
            SizedBox(width: 9),
            Expanded(child: _StepCard(number: '2', icon: Icons.fact_check_rounded, title: 'Check result', text: 'See what we found.')),
            SizedBox(width: 9),
            Expanded(child: _StepCard(number: '3', icon: Icons.spa_rounded, title: 'Get guidance', text: 'Follow simple advice.')),
          ],
        ),
      ],
    );
  }

  Widget _photoTips() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Photo tips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 14),
          _TipRow(icon: Icons.wb_sunny_outlined, title: 'Good light', text: 'Take the photo in daylight.'),
          _TipRow(icon: Icons.eco_rounded, title: 'Whole leaf', text: 'Show the entire leaf.'),
          _TipRow(icon: Icons.center_focus_strong_rounded, title: 'Clear focus', text: 'Keep the leaf sharp.'),
        ],
      ),
    );
  }
}

class _CropBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CropBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Palette.primary, size: 23),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _StepCard({required this.number, required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 13),
      decoration: BoxDecoration(
        color: Palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: Palette.gold,
                child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 7),
              Icon(icon, color: Palette.primary, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 3),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Palette.textDim, fontSize: 11, height: 1.25)),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Palette.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, color: Palette.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: Palette.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
