import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'diagnosis_flow.dart';
import 'localization.dart';
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

  String tr(String key) => AppText.t(_lang, key);

  double get _heroTitleSize {
    switch (_lang) {
      case 'sn':
      case 'nd':
        return 25;
      case 'toi':
        return 27;
      default:
        return 31;
    }
  }

  double get _heroHeight => _lang == 'en' ? 245 : 282;

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

  void _placeholder(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                color: Palette.bg.withOpacity(0.96),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _hero(),
                          const SizedBox(height: 14),
                          _BigAction(
                            icon: Icons.camera_alt_rounded,
                            title: _busy ? tr('checkingPhoto') : tr('scanLeaf'),
                            primary: true,
                            onTap: _busy ? null : _openScan,
                          ),
                          const SizedBox(height: 10),
                          _BigAction(
                            icon: Icons.photo_library_rounded,
                            title: tr('uploadPhoto'),
                            onTap: _busy ? null : _pickGallery,
                          ),
                          const SizedBox(height: 13),
                          _supportedCrops(),
                          const SizedBox(height: 24),
                          Text(
                            tr('howItWorks'),
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Palette.primaryDark,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _StepCard(
                                  number: '1',
                                  icon: Icons.camera_alt_rounded,
                                  title: tr('takePhoto'),
                                  text: tr('takePhotoDesc'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StepCard(
                                  number: '2',
                                  icon: Icons.fact_check_rounded,
                                  title: tr('checkResult'),
                                  text: tr('checkResultDesc'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StepCard(
                                  number: '3',
                                  icon: Icons.spa_rounded,
                                  title: tr('getGuidance'),
                                  text: tr('getGuidanceDesc'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _RecentResultCard(
                                  title: tr('recentResult'),
                                  viewDetails: tr('viewDetails'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PhotoTipsCard(
                                  title: tr('photoTips'),
                                  goodLight: tr('goodLight'),
                                  wholeLeaf: tr('wholeLeaf'),
                                  clearFocus: tr('clearFocus'),
                                ),
                              ),
                            ],
                          ),
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
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1000&q=85';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: _heroHeight,
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
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 145,
                      color: Color(0x664B8A56),
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
                  stops: [0, 0.62, 1],
                  colors: [
                    Color(0xFFF8F8F2),
                    Color(0xF2F4F5E9),
                    Color(0x22FFFFFF),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('heroTitle'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Palette.primaryDark,
                          fontSize: _heroTitleSize,
                          height: 1.02,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('heroSubtitle'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Palette.textDim,
                          fontSize: _lang == 'en' ? 14.5 : 13,
                          height: 1.34,
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

  Widget _supportedCrops() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Row(
        children: [
          _NavItem(icon: Icons.home_rounded, label: tr('home'), active: true),
          _NavItem(
            icon: Icons.camera_alt_outlined,
            label: tr('scan'),
            onTap: _openScan,
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: tr('history'),
            onTap: () => _placeholder(tr('historyComing')),
          ),
          _NavItem(
            icon: Icons.help_outline_rounded,
            label: tr('help'),
            onTap: () => _placeholder(tr('helpComing')),
          ),
        ],
      ),
    );
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: primary ? brandGradient : null,
              color: primary ? null : Palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: primary ? Palette.primaryDark : Palette.primary,
                width: primary ? 0 : 1.25,
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
                Icon(
                  icon,
                  color: primary ? Colors.white : Palette.primaryDark,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: primary ? Colors.white : Palette.primaryDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: primary ? Colors.white : Palette.primaryDark,
                  size: 27,
                ),
              ],
            ),
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
        Text(emoji, style: const TextStyle(fontSize: 24)),
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
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
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
              Icon(icon, color: Palette.primary, size: 23),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Palette.textDim,
              fontSize: 10,
              height: 1.22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResultCard extends StatelessWidget {
  final String title;
  final String viewDetails;

  const _RecentResultCard({required this.title, required this.viewDetails});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 17,
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
              child: Icon(Icons.eco_rounded, size: 54, color: Palette.primary),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Tomato', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text(
            'Early Blight',
            style: TextStyle(color: Palette.alert, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              viewDetails,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Palette.primaryDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTipsCard extends StatelessWidget {
  final String title;
  final String goodLight;
  final String wholeLeaf;
  final String clearFocus;

  const _PhotoTipsCard({
    required this.title,
    required this.goodLight,
    required this.wholeLeaf,
    required this.clearFocus,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Palette.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          _MiniTip(icon: Icons.wb_sunny_outlined, title: goodLight),
          _MiniTip(icon: Icons.eco_rounded, title: wholeLeaf),
          _MiniTip(icon: Icons.center_focus_strong_rounded, title: clearFocus),
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: const BoxDecoration(
              color: Palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Palette.primary, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? Palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  color: active ? Palette.primaryDark : Palette.textDim,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Palette.primaryDark : Palette.textDim,
                  fontSize: 11,
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
