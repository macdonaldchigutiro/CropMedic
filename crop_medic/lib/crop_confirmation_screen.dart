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
    if (widget.guess.accepted && widget.guess.crop.isNotEmpty) {
      _selectedCrop = widget.guess.crop;
    }
  }

  void _showRoadmap() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .5,
        maxChildSize: .9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ui(
                'More crops are coming',
                'Zvimwe zvirimwa zviri kuuya',
                'Ezinye izilimo ziyeza',
                'Milimo imwi ilakuboola',
              ),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ui(
                'These crops are in the CropMedic expansion roadmap, but AI diagnosis is not enabled for them yet. We will only switch them on after training and field validation.',
                'Zvirimwa izvi zviri muhurongwa hwekuwedzera CropMedic, asi AI haisati yagadzirirwa kuzviongorora. Zvichavhurwa mushure mekudzidzisa nekuyedza muminda.',
                'Lezi zilimo zisehlelo lokwandisa iCropMedic, kodwa ukuhlolwa nge-AI akukavulwa. Sizakuvula ngemva kokuqeqetsha lokuhlola emasimini.',
                'Milimo eyi ili mulukwe lwaCropMedic, pele AI tayilayandulwi ino. Ilakuvulwa mwamana kujisya akuyesya muminda.',
              ),
              style: const TextStyle(color: Palette.textDim, height: 1.45),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roadmapCrops
                  .map((crop) => Chip(label: Text('${crop.emoji} ${crop.label(widget.lang)}')))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guessCrop = widget.guess.crop;
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    ui(
                      'Which crop is this?',
                      'Chirimwa chipi ichi?',
                      'Yisiphi isilimo lesi?',
                      'Ngomulimo nzi ooyu?',
                    ),
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
                      'CropMedic first estimates the crop, then you confirm or correct it before disease diagnosis.',
                      'CropMedic inotanga yafungidzira chirimwa, wobva wasimbisa kana kugadzirisa isati yaongorora chirwere.',
                      'CropMedic iqala iqagele isilimo, wena usiqinisekise kumbe usilungise ingakahloli isifo.',
                      'CropMedic itanga yabona mulimo, ulasinizya naa kuulungamya inga kayandula bulwazi.',
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
                  if (widget.guess.accepted)
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
                                  ui('CropMedic thinks this is', 'CropMedic inofunga kuti ichi', 'CropMedic icabanga ukuthi lesi', 'CropMedic iyabona kuti ooyu'),
                                  style: const TextStyle(color: Palette.textDim, fontSize: 12.5),
                                ),
                                Text(
                                  '$guessCrop · $guessPercent%',
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
                          const Icon(Icons.help_outline_rounded, color: Palette.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ui(
                                'CropMedic is not confident enough to identify the crop automatically. Please choose it below.',
                                'CropMedic haina chokwadi chakakwana. Sarudza chirimwa pazasi.',
                                'CropMedic ayiqiniseki ngokwanele. Khetha isilimo ngezansi.',
                                'CropMedic tayisinizyi. Sala mulimo ansi.',
                              ),
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    ui('Confirm or choose crop', 'Simbisa kana sarudza chirimwa', 'Qinisekisa kumbe khetha isilimo', 'Sinizya naa sala mulimo'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Palette.primaryDark),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.25,
                    children: supportedCrops.map((crop) {
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
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _showRoadmap,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(
                      ui(
                        'My crop is not listed',
                        'Chirimwa changu hachisi pano',
                        'Isilimo sami asikho lapha',
                        'Mulimo wangu takuli',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _selectedCrop == null
                          ? null
                          : () => Navigator.pop(context, _selectedCrop),
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
                  const SizedBox(height: 12),
                  Text(
                    ui(
                      'Automatic crop identification is currently a bootstrap feature for the four supported crops. Farmer confirmation is required.',
                      'Kuziva chirimwa otomatiki kuchiri kwekutanga pazvirimwa zvina zvinotsigirwa. Murimi anofanira kusimbisa.',
                      'Ukubona isilimo ngokuzenzakalela kuseyisigaba sokuqala ezilimweni ezine. Umlimi kumele aqinisekise.',
                      'Kuziba mulimo kuli mukutalika kumilimo yone. Mulimi ulasinizya.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.textDim, fontSize: 11.5, height: 1.35),
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
