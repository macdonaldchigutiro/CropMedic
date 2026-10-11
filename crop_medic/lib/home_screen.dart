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
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                color: Palette.bg.withOpacity(0.94),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _hero(),
                          const SizedBox(height: 14),
                          _mainActions(),
                          const SizedBox(height: 13),
                          _supportedCrops(),
                          const SizedBox(height: 26),
                          _sectionHeader('How it works'),
                          const SizedBox(height: 12),
                          _howItWorks(),
                          const SizedBox(height: 18),
                          _bottomCards(),
                        ],
                      ),
                    ),
                    _bottomNav(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: CropMedicBrand(compact: true, showTagline: false),
        ),
        const SizedBox(width: 8),
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
    const imageUrl =
        'https://images.unsplash.com/photo-1762610744861-493bc400e80f?auto=format&fit=crop&w=1200&q=85';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9F2DF), Color(0xFFF7E6B8)],
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.eco_rounded,
                        size: 150,
                        color: Color(0x664B8A56),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, 0.52, 1],
                  colors: [
                    Color(0xFFF7F7EFFF),
                    Color(0xEEF3F5E7),
                    Color(0x19FFFFFF),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 245,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Healthy crops\nstart with\none photo',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Palette.primaryDark,
                          fontSize: 34,
                          height: 0.98,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                        ),
                      ),
                      SizedBox(height: 13),
                      Text(
                        'Find crop problems early and get expert guidance in seconds.',
                        style: TextStyle(
                          color: Palette.textDim,
                          fontSize: 15.5,
                          height: 1.38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainActions() {
    return Column(
      children: [
        _BigAction(
          icon: Icons.camera_alt_rounded,
          title: _busy ? 'Checking photo…' : 'Scan a leaf',
          primary: true,
          onTap: _busy ? null : _openScan,
        ),
        const SizedBox(height: 10),
        _BigAction(
          icon: Icons.photo_library_rounded,
          title: 'Upload photo',
          onTap: _busy ? null : _pickGallery,
        ),
      ],
    );
  }

  Widget _supportedCrops() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.border),
      ),
      child: const Row(
        children: [
          Expanded(child: _CropMini(emoji: '🌽', label: 'Maize')),
          Expanded(child: _CropMini(emoji: '🍅', label: 'Tomato')),
          Expanded(child: _CropMini(emoji: '🥔', label: 'Potato')),
          Expanded(child: _CropMini(emoji: '🫑', label: 'Pepper')),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Georgia',
        color: Palette.primaryDark,
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _howItWorks() {
    return Row(
      children: const [
        Expanded(
          child: _StepCard(
            number: '1',
            icon: Icons.camera_alt_rounded,
            title: 'Take photo',
            text: 'Snap a clear leaf photo',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StepCard(
            number: '2',
            icon: Icons.fact_check_rounded,
            title: 'Check result',
            text: 'Get an instant diagnosis',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StepCard(
            number: '3',
            icon: Icons.spa_rounded,
            title: 'Get guidance',
            text: 'Follow simple advice',
          ),
        ),
      ],
    );
  }

  Widget _bottomCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(child: _RecentResultCard()),
        SizedBox(width: 10),
        Expanded(child: _PhotoTipsCard()),
      ],
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Row(
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
          _NavItem(icon: Icons.camera_alt_outlined, label: 'Scan', onTap: _openScan),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: () => _placeholder('History is coming next.'),
          ),
          _NavItem(
            icon: Icons.help_outline_rounded,
            label: 'Help',
            onTap: () => _placeholder('Help is coming next.'),
          ),
        ],
      ),
    );
  }

  void _placeholder(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool primary;
  final VoidCallback? onTap;

  const _BigAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 66,
          decoration: BoxDecoration(
            gradient: primary ? brandGradient : null,
            color: primary ? null : Palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primary ? Palette.primaryDark : Palette.primary,
              width: primary ? 0 : 1.2,
            ),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x25126044),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primary ? Colors.white : Palette.primaryDark, size: 27),
              const SizedBox(width: 13),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: primary ? Colors.white : Palette.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 13),
              Icon(
                Icons.chevron_right_rounded,
                color: primary ? Colors.white : Palette.primaryDark,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropMini extends StatelessWidget {
  final String emoji;
  final String label;
  const _CropMini({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 25)),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 10.5,
                backgroundColor: Palette.gold,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: Palette.primary, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Palette.textDim,
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResultCard extends StatelessWidget {
  const _RecentResultCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent result',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Palette.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDDEBCC), Color(0xFFF0D99A)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, size: 55, color: Palette.primary),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Tomato', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text(
            'Early Blight',
            style: TextStyle(color: Palette.alert, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View details',
                  style: TextStyle(
                    color: Palette.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 15, color: Palette.primaryDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTipsCard extends StatelessWidget {
  const _PhotoTipsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      radius: 21,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo tips',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Palette.primaryDark,
            ),
          ),
          SizedBox(height: 11),
          _MiniTip(icon: Icons.wb_sunny_outlined, title: 'Good light'),
          _MiniTip(icon: Icons.eco_rounded, title: 'Whole leaf'),
          _MiniTip(icon: Icons.center_focus_strong_rounded, title: 'Clear focus'),
        ],
      ),
    );
  }
}

class _MiniTip extends StatelessWidget {
  final IconData icon;
  final String title;
  const _MiniTip({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Palette.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? Palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: active ? Palette.primaryDark : const Color(0xFF455049),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: active ? Palette.primaryDark : const Color(0xFF455049),
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
