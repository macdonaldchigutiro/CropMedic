import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'result_screen.dart';
import 'scanner_frame.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Palette.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CropMedicApp());
}

class CropMedicApp extends StatelessWidget {
  const CropMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Medic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: const ColorScheme.dark(
          primary: Palette.neonGreen,
          secondary: Palette.neonCyan,
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
  Uint8List? _bytes;
  String _lang = 'en';
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _bytes = bytes;
      _busy = true;
    });

    try {
      final diagnosis = await predict(bytes, _lang);
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) =>
              ResultScreen(image: bytes, diagnosis: diagnosis),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _pick(source),
        ),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 16),
                _languagePicker(),
                const SizedBox(height: 20),
                Expanded(child: ScannerFrame(image: _bytes, busy: _busy)),
                const SizedBox(height: 12),
                const Text(
                  'Tip: use daylight and avoid shadows',
                  style: TextStyle(color: Palette.textDim, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _scanButton(),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Palette.neonCyan),
                  label: const Text(
                    'Choose from gallery',
                    style: TextStyle(color: Palette.neonCyan),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => neonGradient.createShader(rect),
          child: const Text(
            'CROP MEDIC',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AI PLANT HEALTH SCANNER',
          style: TextStyle(
            color: Palette.textDim,
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _languagePicker() {
    const langs = {'en': 'English', 'sn': 'Shona', 'nd': 'Ndebele'};
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: langs.entries.map((e) {
        final selected = _lang == e.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => setState(() => _lang = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? Palette.neonGreen.withOpacity(0.15)
                    : Palette.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Palette.neonGreen : Palette.glassBorder,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: selected ? Palette.neonGreen : Palette.textDim,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _scanButton() {
    return GestureDetector(
      onTap: _busy ? null : () => _pick(ImageSource.camera),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: neonGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Palette.neonGreen.withOpacity(0.45),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.center_focus_strong_rounded, color: Palette.bg),
            SizedBox(width: 10),
            Text(
              'SCAN LEAF',
              style: TextStyle(
                color: Palette.bg,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
