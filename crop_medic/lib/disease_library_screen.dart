import 'package:flutter/material.dart';

import 'brand.dart';
import 'theme.dart';

class DiseaseLibraryScreen extends StatefulWidget {
  final String lang;
  const DiseaseLibraryScreen({super.key, required this.lang});

  @override
  State<DiseaseLibraryScreen> createState() => _DiseaseLibraryScreenState();
}

class _DiseaseLibraryScreenState extends State<DiseaseLibraryScreen> {
  String _crop = 'All';

  String _ui(String en, String sn, String nd, String toi) {
    switch (widget.lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _crop == 'All'
        ? diseaseLibrary
        : diseaseLibrary.where((d) => d.crop == _crop).toList();

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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _ui('Crop library', 'Raibhurari yezvirimwa', 'Umtapo wezilimo', 'Layiburari yamilimo'),
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
                    _ui(
                      'Learn common symptoms, prevention and practical first steps.',
                      'Dzidza zviratidzo, kudzivirira nezvekutanga kuita.',
                      'Funda izimpawu, ukuvikela kanye lokuqala ukukwenza.',
                      'Ziba zibonakaliso, kuzwidilila azya kutanguna kucita.',
                    ),
                    style: const TextStyle(color: Palette.textDim, fontSize: 15.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Maize', 'Tomato', 'Potato', 'Bell pepper']
                        .map((crop) => ChoiceChip(
                              label: Text(crop),
                              selected: _crop == crop,
                              onSelected: (_) => setState(() => _crop = crop),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ...items.map((d) => Padding(
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
                                  child: const Icon(Icons.eco_rounded, color: Palette.primary, size: 30),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.crop, style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        d.name,
                                        style: const TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Palette.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        d.shortSymptom,
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
                      )),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5DE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'General guidance only. For severe or spreading disease, confirm treatment with a qualified extension officer or registered agro-dealer.',
                      style: TextStyle(fontSize: 12.5, height: 1.4),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
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
            Text(d.crop, style: const TextStyle(color: Palette.textDim, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              d.name,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 18),
            _section('What to look for', d.symptoms),
            _section('What helps it spread', d.spread),
            _section('What to do now', d.actions),
            _section('Prevention', d.prevention),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> lines) {
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
                    Expanded(child: Text(line, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DiseaseInfo {
  final String crop;
  final String name;
  final String shortSymptom;
  final List<String> symptoms;
  final List<String> spread;
  final List<String> actions;
  final List<String> prevention;

  const DiseaseInfo({
    required this.crop,
    required this.name,
    required this.shortSymptom,
    required this.symptoms,
    required this.spread,
    required this.actions,
    required this.prevention,
  });
}

const diseaseLibrary = <DiseaseInfo>[
  DiseaseInfo(
    crop: 'Maize',
    name: 'Northern Leaf Blight',
    shortSymptom: 'Long grey-green to tan lesions that expand along the leaf.',
    symptoms: ['Long cigar-shaped lesions on leaves.', 'Older lower leaves are often affected first.', 'Severe infection can dry large parts of the leaf.'],
    spread: ['Warm, humid weather and long periods of leaf wetness.', 'Infected crop residue can carry disease between seasons.'],
    actions: ['Remove badly affected leaves where practical.', 'Avoid overhead irrigation late in the day.', 'Ask an extension officer or agro-dealer before choosing a fungicide.'],
    prevention: ['Rotate maize with non-host crops.', 'Manage infected crop residue.', 'Use tolerant varieties where available.'],
  ),
  DiseaseInfo(
    crop: 'Maize',
    name: 'Common Rust',
    shortSymptom: 'Small cinnamon-brown raised pustules on both leaf surfaces.',
    symptoms: ['Small raised reddish-brown pustules.', 'Pustules may appear on both sides of the leaf.', 'Heavy infection can reduce green leaf area.'],
    spread: ['Cool to moderate temperatures with moisture.', 'Spores move easily by wind.'],
    actions: ['Monitor spread across the field.', 'Do not remove healthy leaves unnecessarily.', 'Seek local advice if infection is severe early in crop growth.'],
    prevention: ['Use resistant varieties where suitable.', 'Plant on time for the local season.', 'Keep fields well balanced nutritionally.'],
  ),
  DiseaseInfo(
    crop: 'Maize',
    name: 'Gray Leaf Spot',
    shortSymptom: 'Rectangular grey or tan lesions running between leaf veins.',
    symptoms: ['Small rectangular spots that become grey or tan.', 'Lesions are usually limited by leaf veins.', 'Many lesions can join together and dry the leaf.'],
    spread: ['High humidity and frequent rain.', 'Continuous maize and infected residues increase pressure.'],
    actions: ['Scout lower and middle leaves regularly.', 'Improve airflow where crop is very dense.', 'Confirm treatment need with an extension professional.'],
    prevention: ['Rotate crops.', 'Use tolerant hybrids.', 'Manage residues after harvest.'],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: 'Early Blight',
    shortSymptom: 'Brown spots with concentric rings, often on older lower leaves.',
    symptoms: ['Dark brown leaf spots with target-like rings.', 'Yellowing around lesions.', 'Lower leaves often show symptoms first.'],
    spread: ['Warm weather, splashing water and infected debris.', 'Plant stress can increase severity.'],
    actions: ['Remove badly infected lower leaves.', 'Water at soil level rather than wetting foliage.', 'Keep diseased leaves out of the growing area.'],
    prevention: ['Rotate tomatoes with unrelated crops.', 'Stake or space plants to improve airflow.', 'Use clean seedlings and avoid working wet plants.'],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: 'Late Blight',
    shortSymptom: 'Fast-spreading dark water-soaked patches, especially in cool wet weather.',
    symptoms: ['Irregular dark water-soaked lesions.', 'White growth may appear on leaf undersides in humid conditions.', 'Leaves and stems can collapse quickly.'],
    spread: ['Cool wet weather and prolonged leaf wetness.', 'Wind-blown spores can move between fields.'],
    actions: ['Separate severely affected plants where practical.', 'Avoid moving through wet crops.', 'Seek extension advice quickly because late blight can spread fast.'],
    prevention: ['Use clean planting material.', 'Avoid overhead irrigation where possible.', 'Destroy infected volunteer plants and crop debris.'],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: 'Septoria Leaf Spot',
    shortSymptom: 'Many small circular spots with pale centres and dark margins.',
    symptoms: ['Numerous small round spots on lower leaves.', 'Spots often have grey centres with dark borders.', 'Affected leaves yellow and may drop.'],
    spread: ['Rain splash, overhead watering and infected debris.', 'Warm humid conditions favour infection.'],
    actions: ['Remove heavily spotted lower leaves.', 'Water at the base of plants.', 'Keep foliage dry when possible.'],
    prevention: ['Rotate crops and clean up residues.', 'Space plants for airflow.', 'Avoid handling plants when leaves are wet.'],
  ),
  DiseaseInfo(
    crop: 'Potato',
    name: 'Early Blight',
    shortSymptom: 'Brown target-like spots on older leaves with yellowing around them.',
    symptoms: ['Concentric-ring lesions on older leaves.', 'Yellow tissue around spots.', 'Severe disease causes premature leaf loss.'],
    spread: ['Warm conditions, moisture and plant stress.', 'Infected residues can carry disease.'],
    actions: ['Remove heavily infected foliage where practical.', 'Reduce plant stress through good watering and nutrition.', 'Confirm fungicide decisions locally.'],
    prevention: ['Rotate away from potato and tomato crops.', 'Use clean seed potatoes.', 'Manage crop debris after harvest.'],
  ),
  DiseaseInfo(
    crop: 'Potato',
    name: 'Late Blight',
    shortSymptom: 'Dark rapidly enlarging lesions during cool humid weather.',
    symptoms: ['Dark irregular leaf lesions.', 'White growth can appear at lesion edges underneath leaves.', 'Stems and tubers may also become infected.'],
    spread: ['Cool humid weather, rain and wind-blown spores.', 'Infected tubers and volunteer plants can be sources.'],
    actions: ['Act quickly when symptoms are suspected.', 'Keep infected foliage away from healthy crops.', 'Contact an extension officer for local control advice.'],
    prevention: ['Use certified clean seed.', 'Destroy volunteer potatoes.', 'Monitor closely during wet cool periods.'],
  ),
  DiseaseInfo(
    crop: 'Bell pepper',
    name: 'Bacterial Spot',
    shortSymptom: 'Small dark water-soaked spots that can become brown and angular.',
    symptoms: ['Small dark spots on leaves.', 'Spots may become angular and leaves can yellow.', 'Fruit can develop raised rough lesions.'],
    spread: ['Splashing rain, overhead irrigation and contaminated seed or tools.', 'Warm wet weather increases spread.'],
    actions: ['Remove badly infected leaves and fruit.', 'Avoid working plants while wet.', 'Disinfect tools between affected areas.'],
    prevention: ['Start with clean seed or seedlings.', 'Rotate crops.', 'Avoid overhead watering when possible.'],
  ),
];
