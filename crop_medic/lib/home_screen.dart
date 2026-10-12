import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
import 'crop_catalog.dart';
import 'diagnosis_flow.dart';
import 'disease_library_screen.dart';
import 'extension_help_screen.dart';
import 'localization.dart';
import 'scan_screen.dart';
import 'theme.dart';
import 'weather_screen.dart';

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

  String ui(String en, String sn, String nd, String toi) {
    switch (_lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  Future<void> _pickGallery({String? presetCrop}) async {
    if (_busy) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
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
      presetCrop: presetCrop,
    );
    if (mounted) setState(() => _busy = false);
  }

  void _openScan({String? crop}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanScreen(lang: _lang, presetCrop: crop),
      ),
    );
  }

  void _openLibrary({String? crop}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiseaseLibraryScreen(lang: _lang, initialCrop: crop),
      ),
    );
  }

  void _openWeather() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeatherScreen(lang: _lang)),
    );
  }

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExtensionHelpScreen(lang: _lang)),
    );
  }

  Future<void> _showCropActions(CropOption crop) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(crop.emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.label(_lang),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Palette.primaryDark,
                          ),
                        ),
                        Text(
                          ui('AI diagnosis supported', 'AI inotsigira kuongorora', 'Ukuhlolwa nge-AI kuyasebenza', 'AI ilakuyandula'),
                          style: const TextStyle(color: Palette.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openScan(crop: crop.id);
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(ui('Scan this crop', 'Skena chirimwa ichi', 'Skena isilimo lesi', 'Skena mulimo ooyu')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openLibrary(crop: crop.id);
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(ui('Open crop library', 'Vhura raibhurari yechirimwa', 'Vula umtapo wesilimo', 'Jula layiburari yamulimo')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoadmapCrop(CropOption crop) async {
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
              Text(crop.emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 8),
              Text(
                crop.label(_lang),
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 27, fontWeight: FontWeight.w800, color: Palette.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                ui(
                  'This crop is in the CropMedic v3 expansion roadmap. AI diagnosis is not enabled yet because we still need suitable training data and field validation.',
                  'Chirimwa ichi chiri muhurongwa hweCropMedic v3. AI haisati yavhurwa nekuti tinoda data yekudzidzisa uye kuyedza muminda.',
                  'Isilimo lesi sisehlelweni seCropMedic v3. Ukuhlolwa nge-AI akukavulwa ngoba kusadingeka idatha lokuhlolwa emasimini.',
                  'Mulimo ooyu uli mulukwe lwaCropMedic v3. AI tayilavulwa nkaambo tulacida data akuyesya muminda.',
                ),
                style: const TextStyle(color: Palette.textDim, fontSize: 15, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResultInfo() async {
    await _showInfoSheet(
      icon: Icons.fact_check_rounded,
      title: ui('Check your result', 'Tarisa mhedzisiro', 'Hlola impumela', 'Langa mbuyanda'),
      message: ui(
        'CropMedic identifies or confirms the crop first, then shows the most likely condition, confidence and practical next steps.',
        'CropMedic inotanga yaziva kana kusimbisa chirimwa, yobva yaratidza chirwere chingangove chiripo, chivimbo uye zvekuita.',
        'CropMedic iqala ngokubona kumbe ukuqinisekisa isilimo, bese ikhombisa isifo esingaba khona, ukuthembeka lezinyathelo ezilandelayo.',
        'CropMedic itanga yaziba naa kusinizya mulimo, lyoonse itondezya bulwazi, kululama azya kucita.',
      ),
      primaryLabel: tr('scanLeaf'),
      primaryAction: () => _openScan(),
      secondaryLabel: tr('uploadPhoto'),
      secondaryAction: () => _pickGallery(),
    );
  }

  Future<void> _showGuidanceInfo() async {
    await _showInfoSheet(
      icon: Icons.spa_rounded,
      title: ui('Get guidance', 'Wana mazano', 'Thola isiqondiso', 'Jana lugwasyo'),
      message: ui(
        'Guidance appears with a supported diagnosis. You can also browse the disease library for symptoms, prevention and practical first steps.',
        'Mazano anoonekwa kana scan yawana chirwere chinotsigirwa. Unogonawo kushandisa raibhurari yezvirwere.',
        'Isiqondiso siyavela lapho ukuhlolwa kuthola isifo esisekelwayo. Ungabuye usebenzise umtapo wezifo.',
        'Lugwasyo luboneka naa scan yajana bulwazi. Ulamvwa kusebenzisa layiburari yabuzwayi.',
      ),
      primaryLabel: ui('Open disease library', 'Vhura raibhurari', 'Vula umtapo', 'Jula layiburari'),
      primaryAction: () => _openLibrary(),
      secondaryLabel: tr('scanLeaf'),
      secondaryAction: () => _openScan(),
    );
  }

  Future<void> _showReportsInfo() async {
    await _showInfoSheet(
      icon: Icons.description_rounded,
      title: ui('Printable reports', 'Mareport anoprintwa', 'Imibiko eprintwayo', 'Ma-report aamaprinta'),
      message: ui(
        'A report is created from a completed diagnosis. Scan or upload a crop image first, then create a PDF or Word report from the result screen.',
        'Report inogadzirwa mushure mekuongororwa. Tanga waskena kana kuisa mufananidzo, wobva wagadzira PDF kana Word paresult screen.',
        'Umbiko wenziwa ngemva kokuhlolwa. Qala ngokuskena kumbe ukufaka umfanekiso, ubusudala iPDF kumbe iWord.',
        'Report ikonziwa mwamana scan. Tanga wascan naa kuuploada foto, lyoonse konza PDF naa Word.',
      ),
      primaryLabel: tr('scanLeaf'),
      primaryAction: () => _openScan(),
      secondaryLabel: tr('uploadPhoto'),
      secondaryAction: () => _pickGallery(),
    );
  }

  Future<void> _showInfoSheet({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback primaryAction,
    required String secondaryLabel,
    required VoidCallback secondaryAction,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Palette.primarySoft,
                  child: Icon(icon, color: Palette.primary, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 25, fontWeight: FontWeight.w800, color: Palette.primaryDark)),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Palette.textDim, fontSize: 14.5, height: 1.45)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  primaryAction();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(primaryLabel),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  secondaryAction();
                },
                child: Text(secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
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
                color: Palette.bg.withOpacity(.97),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _hero(),
                          const SizedBox(height: 14),
                          _BigAction(
                            icon: Icons.camera_alt_rounded,
                            title: _busy ? tr('checkingPhoto') : ui('Scan affected crop', 'Skena chirimwa chakabatwa', 'Skena isilimo esithintekileyo', 'Skena mulimo wajatwa'),
                            primary: true,
                            onTap: _busy ? null : () => _openScan(),
                          ),
                          const SizedBox(height: 10),
                          _BigAction(
                            icon: Icons.photo_library_rounded,
                            title: tr('uploadPhoto'),
                            onTap: _busy ? null : () => _pickGallery(),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle(ui('AI-supported crops', 'Zvirimwa zvinotsigirwa neAI', 'Izilimo ezisekelwa yi-AI', 'Milimo ilagwasigwa neAI')),
                          const SizedBox(height: 6),
                          Text(
                            ui(
                              'Tap a crop to scan it directly or open its disease library.',
                              'Baya pachirimwa kuti uchiskena kana kuvhura raibhurari yacho.',
                              'Cindezela isilimo ukuze usiskene kumbe uvule umtapo waso.',
                              'Baya mulimo kuti usikene naa kujula layiburari yayo.',
                            ),
                            style: const TextStyle(color: Palette.textDim, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.8,
                            children: supportedCrops
                                .map((crop) => _CropCard(
                                      crop: crop,
                                      lang: _lang,
                                      onTap: () => _showCropActions(crop),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle(ui('More crops being added', 'Zvimwe zvirimwa zviri kuwedzerwa', 'Ezinye izilimo ziyengezwa', 'Milimo imwi ilakuboolesigwa')),
                          const SizedBox(height: 6),
                          Text(
                            ui(
                              'These are in the CropMedic v3 roadmap. They are visible now so farmers can see what is coming, but AI diagnosis stays off until each crop is trained and validated.',
                              'Izvi zviri muhurongwa hweCropMedic v3. Zviri kuoneka kuti murimi azive zviri kuuya, asi AI ichavhurwa chete mushure mekudzidzisa nekuyedza.',
                              'Lezi zisehlelweni seCropMedic v3. Ziyabonakala ukuze abalimi babone okuzayo, kodwa i-AI izavulwa ngemva kokuqeqetshwa lokuhlolwa.',
                              'Eeyi ili mulukwe lwaCropMedic v3. Ilaboneka kuti mulimi azibe zilakuboola, pele AI ilavulwa mwamana kujisya akuyesya.',
                            ),
                            style: const TextStyle(color: Palette.textDim, fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: roadmapCrops
                                .map((crop) => ActionChip(
                                      avatar: Text(crop.emoji),
                                      label: Text(crop.label(_lang)),
                                      onPressed: () => _showRoadmapCrop(crop),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 26),
                          _sectionTitle(ui('Farmer tools', 'Zvishandiso zvemurimi', 'Amathuluzi omlimi', 'Zyakubelensya mulimi')),
                          const SizedBox(height: 12),
                          _ToolCard(
                            icon: Icons.menu_book_rounded,
                            title: ui('Crop disease library', 'Raibhurari yezvirwere', 'Umtapo wezifo zezilimo', 'Layiburari yabuzwayi'),
                            text: ui('Symptoms, prevention and practical first steps.', 'Zviratidzo, kudzivirira nezvekutanga kuita.', 'Izimpawu, ukuvikela lokuqala ukukwenza.', 'Zibonakaliso, kuzwidilila azya kutanguna.'),
                            onTap: () => _openLibrary(),
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.cloud_rounded,
                            title: ui('Weather & crop risk', 'Mamiriro ekunze nenjodzi', 'Isimo sezulu lengozi', 'Mvula anjodzi'),
                            text: ui('Live conditions plus simple disease and spraying alerts.', 'Mamiriro aripo pamwe neyambiro yezvirwere nekupfapfaidza.', 'Isimo samanje lezixwayiso zezifo lokufafaza.', 'Mvula lino alulayo lwabuzwayi akuspreeja.'),
                            onTap: _openWeather,
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.support_agent_rounded,
                            title: ui('Extension services', 'Rubatsiro rwevarimisi', 'Usizo lwabalimi', 'Lugwasyo lwabalimi'),
                            text: ui('Find agricultural offices and verified public contacts.', 'Tsvaga mahofisi nemacontact anoongororwa.', 'Thola amahofisi lama-contact aqinisekisiweyo.', 'Jana maofesi amacontact asinizidwe.'),
                            onTap: _openHelp,
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle(tr('howItWorks')),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _StepCard(number: '1', icon: Icons.camera_alt_rounded, title: ui('Take photo', 'Tora foto', 'Thatha isithombe', 'Tola foto'), text: ui('Photograph the affected area.', 'Tora chikamu chakabatwa.', 'Thatha indawo ethintekileyo.', 'Tola cibeela cajatwa.'), onTap: () => _openScan())),
                              const SizedBox(width: 8),
                              Expanded(child: _StepCard(number: '2', icon: Icons.eco_rounded, title: ui('Confirm crop', 'Simbisa chirimwa', 'Qinisekisa isilimo', 'Sinizya mulimo'), text: ui('AI suggests; you confirm.', 'AI inofungidzira, iwe unosimbisa.', 'AI iyaqagela, wena uqinisekise.', 'AI ilabona, ulasinizya.'), onTap: _showResultInfo)),
                              const SizedBox(width: 8),
                              Expanded(child: _StepCard(number: '3', icon: Icons.fact_check_rounded, title: ui('Get diagnosis', 'Wana ongororo', 'Thola ukuhlolwa', 'Jana buyandule'), text: ui('See condition and guidance.', 'Ona chirwere nemazano.', 'Bona isifo lesiqondiso.', 'Bona bulwazi alugwasyo.'), onTap: _showGuidanceInfo)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _ReportCard(
                            title: ui('Printable reports', 'Mareport anoprintwa', 'Imibiko eprintwayo', 'Ma-report aamaprinta'),
                            text: ui('PDF and Word reports are available after a completed diagnosis.', 'PDF neWord reports zvinowanikwa mushure mekuongororwa.', 'Imibiko yePDF leWord itholakala ngemva kokuhlolwa.', 'PDF na Word reports zilajanwa mwamana scan.'),
                            onTap: _showReportsInfo,
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

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontFamily: 'Georgia', fontSize: 25, fontWeight: FontWeight.w800, color: Palette.primaryDark),
      );

  Widget _header() {
    return Row(
      children: [
        const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
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
    const imageUrl = 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1000&q=85';
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: _lang == 'en' ? 238 : 270,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => Container(color: Palette.primarySoft),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, .62, 1],
                  colors: [Color(0xFFF8F8F2), Color(0xF2F4F5E9), Color(0x22FFFFFF)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 255,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ui('What does your crop need today?', 'Chirimwa chako chinoda rubatsiro rwei nhasi?', 'Isilimo sakho sidinga usizo bani lamuhla?', 'Mulimo wako ulacida lugwasyo nzi sunu?'),
                        style: TextStyle(fontFamily: 'Georgia', color: Palette.primaryDark, fontSize: _lang == 'en' ? 31 : 26, height: 1.02, fontWeight: FontWeight.w700, letterSpacing: -.8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ui('Photograph an affected plant. CropMedic estimates the crop, asks you to confirm it, then checks for supported diseases.', 'Tora mufananidzo wechirimwa chakabatwa. CropMedic inofungidzira chirimwa, yokukumbira kusimbisa, yobva yaongorora zvirwere zvinotsigirwa.', 'Thatha umfanekiso wesilimo esithintekileyo. CropMedic iqagela isilimo, ikucele usiqinisekise, bese ihlola izifo ezisekelwayo.', 'Tola foto yamulimo wajatwa. CropMedic ilabona mulimo, ikubuzye kusinizya, lyoonse iyandule bulwazi bulagwasigwa.'),
                        style: const TextStyle(color: Palette.textDim, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500),
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

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.border)),
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 7),
      child: Row(
        children: [
          _NavItem(icon: Icons.home_rounded, label: tr('home'), active: true),
          _NavItem(icon: Icons.camera_alt_outlined, label: tr('scan'), onTap: () => _openScan()),
          _NavItem(icon: Icons.menu_book_outlined, label: ui('Library', 'Raibhurari', 'Umtapo', 'Layiburari'), onTap: () => _openLibrary()),
          _NavItem(icon: Icons.cloud_outlined, label: ui('Weather', 'Mamiriro', 'Isimo', 'Mvula'), onTap: _openWeather),
          _NavItem(icon: Icons.support_agent_outlined, label: tr('help'), onTap: _openHelp),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final CropOption crop;
  final String lang;
  final VoidCallback onTap;

  const _CropCard({required this.crop, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border),
          ),
          child: Row(
            children: [
              Text(crop.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.label(lang), style: const TextStyle(fontWeight: FontWeight.w900, color: Palette.primaryDark)),
                    const SizedBox(height: 2),
                    const Text('AI ✓', style: TextStyle(fontSize: 11, color: Palette.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Palette.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool primary;
  final VoidCallback? onTap;

  const _BigAction({required this.icon, required this.title, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: primary ? brandGradient : null,
            color: primary ? null : Palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary ? Palette.primaryDark : Palette.primary, width: primary ? 0 : 1.25),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary ? Colors.white : Palette.primaryDark, size: 26),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontFamily: 'Georgia', color: primary ? Colors.white : Palette.primaryDark, fontSize: 18, fontWeight: FontWeight.w700))),
              Icon(Icons.chevron_right_rounded, color: primary ? Colors.white : Palette.primaryDark, size: 27),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  const _ToolCard({required this.icon, required this.title, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: Palette.primarySoft, borderRadius: BorderRadius.circular(17)),
              child: Icon(icon, color: Palette.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Palette.primaryDark)),
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(color: Palette.textDim, fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.primary),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  const _ReportCard({required this.title, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AppCard(
        color: const Color(0xFFF2F6EE),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Palette.primarySoft, child: Icon(Icons.description_rounded, color: Palette.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(color: Palette.textDim, height: 1.35)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.primary),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  const _StepCard({required this.number, required this.icon, required this.title, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
          decoration: BoxDecoration(color: const Color(0xFFF2F6EE), borderRadius: BorderRadius.circular(20), border: Border.all(color: Palette.border)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 10.5, backgroundColor: Palette.gold, child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 6),
                  Icon(icon, color: Palette.primary, size: 23),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.15)),
              const SizedBox(height: 5),
              Expanded(child: Text(text, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Palette.textDim, fontSize: 10, height: 1.22))),
              const Icon(Icons.arrow_forward_rounded, color: Palette.primary, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 43,
                height: 31,
                decoration: BoxDecoration(color: active ? Palette.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                child: Icon(icon, color: active ? Palette.primaryDark : Palette.textDim, size: 20),
              ),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Palette.primaryDark : Palette.textDim, fontSize: 9.5, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
