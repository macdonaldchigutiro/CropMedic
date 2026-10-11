import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'result_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Palette.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const CropMedicApp());
}

class CropMedicApp extends StatelessWidget {
  const CropMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropMedic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.primary,
          brightness: Brightness.light,
          primary: Palette.primary,
          secondary: Palette.accent,
          surface: Palette.surface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Palette.text,
              displayColor: Palette.text,
            ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  String _lang = 'en';
  bool _busy = false;

  static const _languages = {
    'en': 'English',
    'sn': 'Shona',
    'nd': 'Ndebele',
    'toi': 'Tonga',
  };

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 88,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    setState(() => _busy = true);

    try {
      final diagnosis = await predict(bytes, _lang);
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(image: bytes, diagnosis: diagnosis),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _pick(source),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                children: [
                  _topBar(),
                  const SizedBox(height: 30),
                  _hero(),
                  const SizedBox(height: 22),
                  _actions(),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Supported crops',
                    'CropMedic currently recognises 19 conditions across these crops.',
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CropPill(icon: Icons.grass_rounded, label: 'Maize'),
                      _CropPill(icon: Icons.local_florist_rounded, label: 'Tomato'),
                      _CropPill(icon: Icons.spa_rounded, label: 'Potato'),
                      _CropPill(icon: Icons.eco_rounded, label: 'Bell pepper'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _sectionTitle(
                    'Get a better diagnosis',
                    'A clear photo helps CropMedic know when to diagnose — and when not to guess.',
                  ),
                  const SizedBox(height: 14),
                  const _PhotoTips(),
                  const SizedBox(height: 30),
                  _sectionTitle(
                    'How it works',
                    'Simple enough to use in the field.',
                  ),
                  const SizedBox(height: 14),
                  const _HowItWorks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CropMedic',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'AI crop health assistant',
                style: TextStyle(color: Palette.textDim, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _lang,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _languages.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _lang = value);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.primaryDark, Palette.primary, Palette.accent],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2633693C),
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 650;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'ZIMBABWE v2 MODEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'What does your crop need?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Take a clear leaf photo. CropMedic checks the image, identifies supported crop diseases and gives practical next steps.',
                style: TextStyle(
                  color: Color(0xFFE9F6E9),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          );

          final art = Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded,
                size: 76, color: Colors.white),
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 22), Center(child: art)],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 30),
              art,
            ],
          );
        },
      ),
    );
  }

  Widget _actions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 620;
        final camera = _ActionCard(
          icon: Icons.camera_alt_rounded,
          title: 'Scan a leaf',
          subtitle: 'Use your camera for a fresh photo',
          primary: true,
          busy: _busy,
          onTap: _busy ? null : () => _pick(ImageSource.camera),
        );
        final gallery = _ActionCard(
          icon: Icons.photo_library_rounded,
          title: 'Choose a photo',
          subtitle: 'Upload a clear leaf image from your device',
          busy: _busy,
          onTap: _busy ? null : () => _pick(ImageSource.gallery),
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: camera),
              const SizedBox(width: 14),
              Expanded(child: gallery),
            ],
          );
        }
        return Column(
          children: [camera, const SizedBox(height: 12), gallery],
        );
      },
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: Palette.textDim, height: 1.4),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final bool busy;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primary ? Palette.primary : Palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primary ? Palette.primary : Palette.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100E2B16),
              blurRadius: 20,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withOpacity(0.16)
                    : Palette.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: busy && primary
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      icon,
                      color: primary ? Colors.white : Palette.primary,
                      size: 27,
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy && primary ? 'Analysing photo…' : title,
                    style: TextStyle(
                      color: primary ? Colors.white : Palette.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary
                          ? Colors.white.withOpacity(0.82)
                          : Palette.textDim,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: primary ? Colors.white : Palette.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CropPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CropPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Palette.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: const [
          _Tip(icon: Icons.center_focus_strong_rounded, text: 'One leaf fills the photo'),
          _Tip(icon: Icons.wb_sunny_outlined, text: 'Use bright natural light'),
          _Tip(icon: Icons.blur_off_rounded, text: 'Keep the leaf sharp'),
          _Tip(icon: Icons.block_rounded, text: 'Avoid people and unrelated objects'),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = const [
          _StepCard(number: '1', title: 'Take a photo', text: 'Capture one clear crop leaf.'),
          _StepCard(number: '2', title: 'AI checks it', text: 'CropMedic compares supported conditions.'),
          _StepCard(number: '3', title: 'See next steps', text: 'Get a result, confidence and practical guidance.'),
        ];
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  const _StepCard({required this.number, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Palette.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(color: Palette.textDim, height: 1.35)),
        ],
      ),
    );
  }
}
