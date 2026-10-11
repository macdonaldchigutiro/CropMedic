import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'diagnosis_flow.dart';
import 'theme.dart';

class ScanScreen extends StatefulWidget {
  final String lang;
  const ScanScreen({super.key, required this.lang});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() => _busy = true);
    await startDiagnosisFlow(context, bytes, widget.lang);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    const imageUrl =
        'https://images.unsplash.com/photo-1762610744861-493bc400e80f?auto=format&fit=crop&w=1200&q=85';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                color: Palette.bg.withOpacity(0.94),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: CropMedicBrand(compact: true, showTagline: false),
                        ),
                        const SizedBox(width: 6),
                        LanguagePill(
                          value: widget.lang,
                          enabled: false,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Scan a leaf',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 40,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: Palette.primaryDark,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Place one leaf inside the frame.',
                      style: TextStyle(color: Palette.textDim, fontSize: 16.5),
                    ),
                    const SizedBox(height: 18),
                    AspectRatio(
                      aspectRatio: 0.92,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFDDEDD5), Color(0xFFF4E4B7)],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 180,
                                    color: Color(0xFF4A8B58),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(child: CustomPaint(painter: _FramePainter())),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: _Tip(
                            icon: Icons.eco_rounded,
                            title: 'Whole leaf',
                            subtitle: 'Show the entire leaf',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _Tip(
                            icon: Icons.wb_sunny_outlined,
                            title: 'Good light',
                            subtitle: 'Use daylight',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _Tip(
                            icon: Icons.center_focus_strong_rounded,
                            title: 'Clear focus',
                            subtitle: 'Keep it sharp',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RoundAction(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          onTap: _busy ? null : () => Navigator.pop(context),
                        ),
                        GestureDetector(
                          onTap: _busy ? null : () => _pick(ImageSource.camera),
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: brandGradient,
                              border: Border.all(color: Palette.goldSoft, width: 6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26083D2F),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(27),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                          ),
                        ),
                        _RoundAction(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: _busy ? null : () => _pick(ImageSource.gallery),
                        ),
                      ],
                    ),
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

class _Tip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Tip({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
      decoration: BoxDecoration(
        color: Palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: icon == Icons.wb_sunny_outlined ? Palette.gold : Palette.primary,
            size: 27,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.textDim, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RoundAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Palette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Palette.border),
            ),
            child: Icon(icon, color: Palette.primaryDark),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Palette.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const m = 24.0;
    const l = 44.0;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(m, m + l)
      ..lineTo(m, m)
      ..lineTo(m + l, m)
      ..moveTo(w - m - l, m)
      ..lineTo(w - m, m)
      ..lineTo(w - m, m + l)
      ..moveTo(m, h - m - l)
      ..lineTo(m, h - m)
      ..lineTo(m + l, h - m)
      ..moveTo(w - m - l, h - m)
      ..lineTo(w - m, h - m)
      ..lineTo(w - m, h - m - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
