import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'crop_catalog.dart';
import 'diagnosis_flow.dart';
import 'localization.dart';
import 'theme.dart';

class ScanScreen extends StatefulWidget {
  final String lang;
  final String? presetCrop;

  const ScanScreen({
    super.key,
    required this.lang,
    this.presetCrop,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  late String _lang;

  String tr(String key) => AppText.t(_lang, key);

  String ui(String en, String sn, String nd, String toi) {
    switch (_lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
  }

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
    await startDiagnosisFlow(
      context,
      bytes,
      _lang,
      presetCrop: widget.presetCrop,
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _capture() async {
    if (_busy) return;
    try {
      await _pick(ImageSource.camera);
    } catch (_) {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Palette.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('cameraDesktopTitle'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: Palette.primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('cameraDesktopText'),
                    style: const TextStyle(
                      color: Palette.textDim,
                      height: 1.45,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: tr('choosePhoto'),
                    icon: Icons.photo_library_rounded,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _pick(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showTip(String title, String body, IconData icon) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Palette.primary, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          color: Palette.primaryDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Palette.textDim,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const imageUrl =
        'https://images.unsplash.com/photo-1762610744861-493bc400e80f?auto=format&fit=crop&w=1200&q=85';
    final selectedCrop = widget.presetCrop == null ? null : cropById(widget.presetCrop!);

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
                          value: _lang,
                          enabled: !_busy,
                          onChanged: (value) {
                            if (value != null) setState(() => _lang = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.presetCrop == null
                          ? ui('Scan the affected plant', 'Skena chikamu chakabatwa', 'Skena ingxenye ethintekileyo', 'Skena cibeela cajatwa')
                          : ui('Scan ${selectedCrop?.label(_lang) ?? widget.presetCrop}', 'Skena ${selectedCrop?.label(_lang) ?? widget.presetCrop}', 'Skena ${selectedCrop?.label(_lang) ?? widget.presetCrop}', 'Skena ${selectedCrop?.label(_lang) ?? widget.presetCrop}'),
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 38,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: Palette.primaryDark,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ui(
                        'Photograph the clearest affected area. CropMedic can estimate the crop first, then asks you to confirm it.',
                        'Tora mufananidzo wakajeka wechikamu chakabatwa. CropMedic inogona kutanga yafungidzira chirimwa yobva yakukumbira kusimbisa.',
                        'Thatha umfanekiso ocacileyo wengxenye ethintekileyo. CropMedic ingaqala iqagele isilimo bese ikucela usiqinisekise.',
                        'Tola foto icena yacibeela cajatwa. CropMedic ilabona mulimo kutanga akubuzya kusinizya.',
                      ),
                      style: const TextStyle(color: Palette.textDim, fontSize: 15.5, height: 1.4),
                    ),
                    if (selectedCrop != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Text(selectedCrop.emoji),
                          label: Text(
                            ui(
                              'Selected crop: ${selectedCrop.label(_lang)}',
                              'Chirimwa chasarudzwa: ${selectedCrop.label(_lang)}',
                              'Isilimo esikhethiweyo: ${selectedCrop.label(_lang)}',
                              'Mulimo wasalilwe: ${selectedCrop.label(_lang)}',
                            ),
                          ),
                        ),
                      ),
                    ],
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
                    Row(
                      children: [
                        Expanded(
                          child: _Tip(
                            icon: Icons.center_focus_strong_rounded,
                            title: ui('Affected area', 'Chikamu chakabatwa', 'Indawo ethintekileyo', 'Cibeela cajatwa'),
                            subtitle: ui('Keep it visible', 'Chionekwe', 'Sibonakale', 'Ciboneke'),
                            onTap: () => _showTip(
                              ui('Show the affected area', 'Ratidza chikamu chakabatwa', 'Khombisa indawo ethintekileyo', 'Tondezya cibeela cajatwa'),
                              ui('Include enough healthy tissue around the damage so CropMedic can compare patterns.', 'Sanganisira chikamu chine hutano chiri pedyo kuti CropMedic ienzezane nemaitiro.', 'Faka lengxenye ephilileyo eduze ukuze CropMedic iqathanise amaphetheni.', 'Tondezya acibeela cipona afwi kuti CropMedic iyeezanisye.'),
                              Icons.center_focus_strong_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Tip(
                            icon: Icons.wb_sunny_outlined,
                            title: tr('goodLight'),
                            subtitle: tr('useDaylight'),
                            onTap: () => _showTip(tr('goodLight'), tr('tipLightBody'), Icons.wb_sunny_outlined),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Tip(
                            icon: Icons.photo_camera_back_rounded,
                            title: ui('One subject', 'Chinhu chimwe', 'Into eyodwa', 'Cintu comwe'),
                            subtitle: ui('Avoid clutter', 'Bvisa zvakawanda', 'Gwema ukuxokozela', 'Tandika bintu'),
                            onTap: () => _showTip(
                              ui('Keep one crop prominent', 'Isa chirimwa chimwe pachena', 'Gcina isilimo esisodwa sicacile', 'Mulimo omwe ube acena'),
                              ui('Avoid hands, tools, people and busy backgrounds covering the crop.', 'Usavhare chirimwa nemaoko, maturusi, vanhu kana zvinhu zvakawanda kumashure.', 'Gwema izandla, amathuluzi, abantu lezizinda ezixokozelayo zivala isilimo.', 'Tandika maanza, zyakubelensya, bantu azintu zyinji kumbele.'),
                              Icons.photo_camera_back_rounded,
                            ),
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
                          label: tr('home'),
                          onTap: _busy ? null : () => Navigator.pop(context),
                        ),
                        Semantics(
                          button: true,
                          label: tr('scanLeaf'),
                          child: GestureDetector(
                            onTap: _busy ? null : _capture,
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
                                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 38),
                            ),
                          ),
                        ),
                        _RoundAction(
                          icon: Icons.photo_library_rounded,
                          label: tr('gallery'),
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
  final VoidCallback onTap;

  const _Tip({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
          decoration: BoxDecoration(color: Palette.surfaceSoft, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Icon(icon, color: icon == Icons.wb_sunny_outlined ? Palette.gold : Palette.primary, size: 27),
              const SizedBox(height: 7),
              Text(title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Palette.textDim, fontSize: 10.5)),
              const SizedBox(height: 3),
              const Icon(Icons.info_outline_rounded, size: 14, color: Palette.textDim),
            ],
          ),
        ),
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
          SizedBox(
            width: 78,
            child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Palette.textDim, fontSize: 12)),
          ),
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
