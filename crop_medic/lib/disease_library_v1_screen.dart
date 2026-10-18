import 'package:flutter/material.dart';

import 'brand.dart';
import 'crop_catalog.dart';
import 'disease_library_screen.dart' show DiseaseInfo, LT, diseaseLibrary;
import 'theme.dart';

class DiseaseLibraryV1Screen extends StatefulWidget {
  final String lang;
  final String? initialCrop;

  const DiseaseLibraryV1Screen({
    super.key,
    required this.lang,
    this.initialCrop,
  });

  @override
  State<DiseaseLibraryV1Screen> createState() => _DiseaseLibraryV1ScreenState();
}

class _DiseaseLibraryV1ScreenState extends State<DiseaseLibraryV1Screen> {
  late String _crop;

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
    final allowed = supportedCrops.map((e) => e.id).toSet();
    _crop = widget.initialCrop != null && allowed.contains(widget.initialCrop)
        ? widget.initialCrop!
        : 'All';
  }

  String cropLabel(String crop) {
    if (crop == 'All') return ui('All', 'Zvose', 'Konke', 'Zyoonse');
    return cropById(crop)?.label(widget.lang) ?? crop;
  }

  List<DiseaseInfo> get _v1Diseases {
    final allowed = supportedCrops.map((e) => e.id).toSet();
    return diseaseLibrary.where((d) => allowed.contains(d.crop)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final source = _v1Diseases;
    final items = _crop == 'All' ? source : source.where((d) => d.crop == _crop).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ui('Crop disease library', 'Raibhurari yezvirwere', 'Umtapo wezifo zezilimo', 'Layiburari yabuzwayi'),
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
                      'Offline reference guidance for the four crops supported in CropMedic V1.',
                      'Mazano anowanikwa pasina internet pazvirimwa zvina zvinotsigirwa muCropMedic V1.',
                      'Isiqondiso esisebenza ngaphandle kwe-inthanethi sezilimo ezine ezisekelwa yiCropMedic V1.',
                      'Malayilile aamili offline kumilimo iine ilagwasigwa muCropMedic V1.',
                    ),
                    style: const TextStyle(color: Palette.textDim, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', ...supportedCrops.map((c) => c.id)]
                        .map((crop) => ChoiceChip(
                              label: Text(cropLabel(crop)),
                              selected: _crop == crop,
                              onSelected: (_) => setState(() => _crop = crop),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ...items.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDisease(d),
                        borderRadius: BorderRadius.circular(22),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          radius: 22,
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Palette.primarySoft,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(child: Text(cropById(d.crop)?.emoji ?? '🌿', style: const TextStyle(fontSize: 28))),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cropLabel(d.crop), style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.name.text(widget.lang),
                                      style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w800, color: Palette.primaryDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.shortSymptom.text(widget.lang),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Palette.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF5DE), borderRadius: BorderRadius.circular(18)),
                    child: Text(
                      ui(
                        'General guidance only. For severe or spreading disease, confirm treatment with a qualified extension officer or registered agro-dealer.',
                        'Aya mazano akajairika chete. Kana chirwere chakanyanya kana kupararira, simbisa kurapwa neextension officer kana agro-dealer akanyoreswa.',
                        'Lesi yiseluleko esijwayelekileyo kuphela. Nxa isifo sinzima kumbe sisabalala, qinisekisa ukwelatshwa lesiphathamandla se-extension kumbe i-agro-dealer ebhalisiweyo.',
                        'Aaya malayilile aajwayelekile alikke. Naa bulwazi buli buyumu naa bulazwidila, sinizya bulapi kumugwasyi wabalimi naa agro-dealer wasinizidwe.',
                      ),
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
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

  void _showDisease(DiseaseInfo d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .94,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(color: Palette.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text(cropLabel(d.crop), style: const TextStyle(color: Palette.textDim, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              d.name.text(widget.lang),
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 30, fontWeight: FontWeight.w800, color: Palette.primaryDark),
            ),
            const SizedBox(height: 18),
            _section(ui('What to look for', 'Zvekutarisa', 'Okumele ukubone', 'Zyakulanga'), d.symptoms),
            _section(ui('What helps it spread', 'Zvinobatsira kupararira', 'Okusiza ukusabalala', 'Zyigwasya kuzwidila'), d.spread),
            _section(ui('What to do now', 'Zvekuita izvozvi', 'Okumele ukwenze khathesi', 'Zyakucita lino'), d.actions),
            _section(ui('Prevention', 'Kudzivirira', 'Ukuvikela', 'Kuzwidilila'), d.prevention),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<LT> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Palette.primaryDark)),
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(radius: 3, backgroundColor: Palette.primary),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(line.text(widget.lang), style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
