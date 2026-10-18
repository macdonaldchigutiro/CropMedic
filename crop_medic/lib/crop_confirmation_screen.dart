import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'brand.dart';
import 'crop_catalog.dart';
import 'theme.dart';

class CropConfirmationScreen extends StatefulWidget {
  final Uint8List image;
  final CropGuess guess;
  final String lang;

  const CropConfirmationScreen({
    super.key,
    required this.image,
    required this.guess,
    required this.lang,
  });

  @override
  State<CropConfirmationScreen> createState() => _CropConfirmationScreenState();
}

class _CropConfirmationScreenState extends State<CropConfirmationScreen> {
  String? _selectedCrop;
  List<CropOption> _diagnosisCrops = supportedCrops;

  String ui(String en, String sn, String nd, String toi) {
    switch (widget.lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  @override
  void initState() {
    super.initState();
    final releaseIds = supportedCrops.map((c) => c.id).toSet();
    if (widget.guess.accepted && releaseIds.contains(widget.guess.crop)) {
      _selectedCrop = widget.guess.crop;
    }
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await fetchCapabilities();
      final releaseIds = supportedCrops.map((c) => c.id).toSet();
      final options = <CropOption>[];
      for (final id in capabilities.diagnosisSupportedCrops) {
        if (!releaseIds.contains(id)) continue;
        final crop = cropById(id);
        if (crop != null && !options.any((item) => item.id == crop.id)) {
          options.add(crop);
        }
      }
      if (!mounted || options.isEmpty) return;
      setState(() {
        _diagnosisCrops = options;
        if (_selectedCrop != null && !options.any((c) => c.id == _selectedCrop)) {
          _selectedCrop = null;
        }
      });
    } catch (_) {
      // Keep the four-crop V1 fallback. The backend still enforces support.
    }
  }

  Future<void> _showUnsupportedCropInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Palette.primarySoft,
                child: Icon(Icons.eco_outlined, color: Palette.primary, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                ui(
                  'CropMedic V1 supports four crops',
                  'CropMedic V1 inotsigira zvirimwa zvina',
                  'CropMedic V1 isekela izilimo ezine',
                  'CropMedic V1 ilagwasya milimo iine',
                ),
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Palette.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ui(
                  'For this release, AI diagnosis is available for Maize, Tomato, Potato and Bell pepper only. If your crop is different, do not choose a similar-looking crop just to get a result.',
                  'Mu release iyi AI diagnosis iripo paChibage, Madomasi, Mbatatisi neMhiripiri chete. Kana chirimwa chako chakasiyana, usasarudza chakafanana kuti uwane result.',
                  'Kulolu hlelo ukuhlolwa nge-AI kusekela Umumbu, Utamatisi, Amazambane loUpelepele kuphela. Nxa isilimo sakho sihlukile, ungakhethi esifananayo ukuze uthole impumela.',
                  'Mu release eeyi AI diagnosis ilagwasya Maize, Tomato, Potato a Bell pepper alikke. Naa mulimo wako wakasiyana, utasali ubonala kulingana kuti ujane mbuyanda.',
                ),
                style: const TextStyle(color: Palette.textDim, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final releaseIds = supportedCrops.map((c) => c.id).toSet();
    final guessSupported = widget.guess.accepted && releaseIds.contains(widget.guess.crop);
    final guessPercent = (widget.guess.confidence * 100).round();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    ui('Confirm the crop', 'Simbisa chirimwa', 'Qinisekisa isilimo', 'Sinizya mulimo'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Palette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ui(
                      'Crop identification and disease diagnosis are separate steps. Confirm the crop before CropMedic checks disease.',
                      'Kuziva chirimwa nekuongorora chirwere matanho akasiyana. Simbisa chirimwa CropMedic isati yaongorora chirwere.',
                      'Ukubona isilimo lokuhlola isifo yizinyathelo ezehlukene. Qinisekisa isilimo iCropMedic ingakahloli isifo.',
                      'Kuziba mulimo akuyandula bulwazi matanho akasiyana. Sinizya mulimo CropMedic inga kayanduli bulwazi.',
                    ),
                    style: const TextStyle(color: Palette.textDim, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1.45,
                      child: Image.memory(widget.image, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (guessSupported)
                    AppCard(
                      color: const Color(0xFFEAF5E9),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Palette.primarySoft,
                            child: Icon(Icons.auto_awesome_rounded, color: Palette.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ui('CropMedic suggests', 'CropMedic inofungidzira', 'CropMedic iyaqagela', 'CropMedic iyabona'),
                                  style: const TextStyle(color: Palette.textDim, fontSize: 12.5),
                                ),
                                Text(
                                  '${widget.guess.crop} · $guessPercent%',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Palette.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AppCard(
                      color: const Color(0xFFFFF5DE),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: Palette.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ui(
                                'Please choose one of the four supported crops below.',
                                'Sarudza chimwe chezvirimwa zvina zvinotsigirwa pazasi.',
                                'Khetha esinye sezilimo ezine ezisekelwayo ngezansi.',
                                'Sala omwe wamilimo iine ilagwasigwa ansi.',
                              ),
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: _diagnosisCrops.map((crop) {
                      final selected = _selectedCrop == crop.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedCrop = crop.id),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected ? Palette.primarySoft : Palette.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? Palette.primary : Palette.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(crop.emoji, style: const TextStyle(fontSize: 25)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  crop.label(widget.lang),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selected ? Palette.primaryDark : Palette.text,
                                  ),
                                ),
                              ),
                              if (selected) const Icon(Icons.check_circle_rounded, color: Palette.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _showUnsupportedCropInfo,
                    icon: const Icon(Icons.info_outline_rounded),
                    label: Text(ui('My crop is different', 'Chirimwa changu chakasiyana', 'Isilimo sami sihlukile', 'Mulimo wangu wakasiyana')),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _selectedCrop == null ? null : () => Navigator.pop(context, _selectedCrop),
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        ui('Continue to diagnosis', 'Enderera kuongororo', 'Qhubeka ekuhlolweni', 'Yinka mukuyandula'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
