import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'brand.dart';
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
      case 'sn':
        return sn;
      case 'nd':
        return nd;
      case 'toi':
        return toi;
      default:
        return en;
    }
  }

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

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiseaseLibraryScreen(lang: _lang)),
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

  Future<void> _showResultInfo() async {
    await _showInfoSheet(
      icon: Icons.fact_check_rounded,
      title: ui(
        'Check your result',
        'Tarisa mhedzisiro',
        'Hlola impumela',
        'Langa mbuyanda',
      ),
      message: ui(
        'After a scan, CropMedic shows the crop, the most likely condition, confidence and practical next steps. Start with a leaf photo to see a real result.',
        'Mushure mescan, CropMedic inoratidza chirimwa, chirwere chingangove chiripo, chivimbo uye zvekuita. Tanga nemufananidzo weshizha kuti uone mhedzisiro.',
        'Ngemva kwescan, CropMedic ikhombisa isilimo, isifo esingaba khona, ukuthembeka kanye lezinyathelo ezilandelayo. Qala ngomfanekiso weqabunga.',
        'Mwamana scan, CropMedic itondeezya mulimo, bulwazi buboneka, kululama azya kucita. Tanga na foto yashizha.',
      ),
      primaryLabel: tr('scanLeaf'),
      primaryAction: _openScan,
      secondaryLabel: tr('uploadPhoto'),
      secondaryAction: () {
        _pickGallery();
      },
    );
  }

  Future<void> _showGuidanceInfo() async {
    await _showInfoSheet(
      icon: Icons.spa_rounded,
      title: ui(
        'Get guidance',
        'Wana mazano',
        'Thola isiqondiso',
        'Jana lugwasyo',
      ),
      message: ui(
        'Guidance appears with a supported diagnosis. You can also browse the disease library for symptoms, prevention and practical first steps.',
        'Mazano anoonekwa kana scan yawana chirwere chinotsigirwa. Unogonawo kushandisa raibhurari yezvirwere kuona zviratidzo nekudzivirira.',
        'Isiqondiso siyavela lapho ukuhlolwa kuthola isifo esisekelwayo. Ungabuye usebenzise umtapo wezifo ukubona izimpawu lokuvikela.',
        'Lugwasyo luboneka naa scan yajana bulwazi. Ulamvwa kusebenzisa layiburari yabuzwayi kubona zibonakaliso akuzwidilila.',
      ),
      primaryLabel: ui(
        'Open disease library',
        'Vhura raibhurari',
        'Vula umtapo',
        'Jula layiburari',
      ),
      primaryAction: _openLibrary,
      secondaryLabel: tr('scanLeaf'),
      secondaryAction: _openScan,
    );
  }

  Future<void> _showReportsInfo() async {
    await _showInfoSheet(
      icon: Icons.description_rounded,
      title: ui(
        'Printable reports',
        'Mareport anoprintwa',
        'Imibiko eprintwayo',
        'Ma-report aamaprinta',
      ),
      message: ui(
        'A report is created from a completed diagnosis. Scan or upload a leaf first. On the result screen, tap “Create printable report” to download PDF or Word.',
        'Report inogadzirwa mushure mekuongororwa. Tanga waskena kana kuisa mufananidzo weshizha. Paresult screen sarudza “Gadzira report inoprintwa” kuti uwane PDF kana Word.',
        'Umbiko wenziwa ngemva kokuhlolwa. Qala ngokuskena kumbe ukufaka umfanekiso weqabunga. Kuresult screen khetha umbiko oprintwayo ukuze uthole PDF kumbe Word.',
        'Report ikonziwa mwamana scan. Tanga wascan na kuuploada foto yashizha. Paresult screen salazya report yaamaprinta kuti udanilode PDF na Word.',
      ),
      primaryLabel: tr('scanLeaf'),
      primaryAction: _openScan,
      secondaryLabel: tr('uploadPhoto'),
      secondaryAction: () {
        _pickGallery();
      },
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
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Palette.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: Palette.primary, size: 30),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: Palette.primaryDark,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  style: const TextStyle(
                    color: Palette.textDim,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      primaryAction();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      primaryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      secondaryAction();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.primaryDark,
                      side: const BorderSide(color: Palette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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
                            title: _busy ? tr('checkingPhoto') : tr('scanLeaf'),
                            primary: true,
                            onTap: _busy ? null : _openScan,
                          ),
                          const SizedBox(height: 10),
                          _BigAction(
                            icon: Icons.photo_library_rounded,
                            title: tr('uploadPhoto'),
                            onTap: _busy
                                ? null
                                : () {
                                    _pickGallery();
                                  },
                          ),
                          const SizedBox(height: 13),
                          _supportedCrops(),
                          const SizedBox(height: 24),
                          _sectionTitle(
                            ui(
                              'Farmer tools',
                              'Zvishandiso zvemurimi',
                              'Amathuluzi omlimi',
                              'Zyakubelensya mulimi',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ui(
                              'Useful information when you are not scanning a leaf.',
                              'Mashoko anobatsira kunyange usiri kuskena shizha.',
                              'Ulwazi oluncedayo lalapho ungasikeni iqabunga.',
                              'Makani aagwasya nokuba utasikeni shizha.',
                            ),
                            style: const TextStyle(
                              color: Palette.textDim,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ToolCard(
                            icon: Icons.menu_book_rounded,
                            title: ui(
                              'Crop disease library',
                              'Raibhurari yezvirwere',
                              'Umtapo wezifo zezilimo',
                              'Layiburari yabuzwayi',
                            ),
                            text: ui(
                              'Symptoms, prevention and practical first steps.',
                              'Zviratidzo, kudzivirira nezvekutanga kuita.',
                              'Izimpawu, ukuvikela lokuqala ukukwenza.',
                              'Zibonakaliso, kuzwidilila azya kutanguna.',
                            ),
                            onTap: _openLibrary,
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.cloud_rounded,
                            title: ui(
                              'Weather & crop risk',
                              'Mamiriro ekunze nenjodzi',
                              'Isimo sezulu lengozi',
                              'Mvula anjodzi',
                            ),
                            text: ui(
                              'Live conditions plus simple disease and spraying alerts.',
                              'Mamiriro aripo pamwe neyambiro yezvirwere nekupfapfaidza.',
                              'Isimo samanje lezixwayiso zezifo lokufafaza.',
                              'Mvula lino alulayo lwabuzwayi akuspreeja.',
                            ),
                            onTap: _openWeather,
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.support_agent_rounded,
                            title: ui(
                              'Extension services',
                              'Rubatsiro rwevarimisi',
                              'Usizo lwabalimi',
                              'Lugwasyo lwabalimi',
                            ),
                            text: ui(
                              'Find agricultural offices and verified public contacts.',
                              'Tsvaga mahofisi nemacontact anoongororwa.',
                              'Thola amahofisi lama-contact aqinisekisiweyo.',
                              'Jana maofesi amacontact asinizidwe.',
                            ),
                            onTap: _openHelp,
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle(tr('howItWorks')),
                          const SizedBox(height: 6),
                          Text(
                            ui(
                              'Tap any step — these cards are now interactive.',
                              'Baya padanho — makadhi aya ava kushanda.',
                              'Cindezela inyathelo — amakhadi la asebenza.',
                              'Baya padanho — makadi aya alasebenza.',
                            ),
                            style: const TextStyle(
                              color: Palette.textDim,
                              fontSize: 12.5,
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
                                  onTap: _openScan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StepCard(
                                  number: '2',
                                  icon: Icons.fact_check_rounded,
                                  title: tr('checkResult'),
                                  text: tr('checkResultDesc'),
                                  onTap: _showResultInfo,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StepCard(
                                  number: '3',
                                  icon: Icons.spa_rounded,
                                  title: tr('getGuidance'),
                                  text: tr('getGuidanceDesc'),
                                  onTap: _showGuidanceInfo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _ReportCard(
                            title: ui(
                              'Printable reports',
                              'Mareport anoprintwa',
                              'Imibiko eprintwayo',
                              'Ma-report aamaprinta',
                            ),
                            text: ui(
                              'PDF and Word reports are available after a completed diagnosis.',
                              'PDF neWord reports zvinowanikwa mushure mekuongororwa.',
                              'Imibiko yePDF leWord itholakala ngemva kokuhlolwa.',
                              'PDF na Word reports zilajanwa mwamana scan.',
                            ),
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: Palette.primaryDark,
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
        height: _lang == 'en' ? 245 : 282,
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
                  stops: [0, .62, 1],
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
                          fontSize: _lang == 'en' ? 31 : 26,
                          height: 1.02,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.8,
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
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 7),
      child: Row(
        children: [
          _NavItem(icon: Icons.home_rounded, label: tr('home'), active: true),
          _NavItem(
            icon: Icons.camera_alt_outlined,
            label: tr('scan'),
            onTap: _openScan,
          ),
          _NavItem(
            icon: Icons.menu_book_outlined,
            label: ui('Library', 'Raibhurari', 'Umtapo', 'Layiburari'),
            onTap: _openLibrary,
          ),
          _NavItem(
            icon: Icons.cloud_outlined,
            label: ui('Weather', 'Mamiriro', 'Isimo', 'Mvula'),
            onTap: _openWeather,
          ),
          _NavItem(
            icon: Icons.support_agent_outlined,
            label: tr('help'),
            onTap: _openHelp,
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
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: primary ? brandGradient : null,
            color: primary ? null : Palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primary ? Palette.primaryDark : Palette.primary,
              width: primary ? 0 : 1.25,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: primary ? Colors.white : Palette.primaryDark,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: primary ? Colors.white : Palette.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: primary ? Colors.white : Palette.primaryDark,
                size: 27,
              ),
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

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                decoration: BoxDecoration(
                  color: Palette.primarySoft,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: Palette.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Palette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Palette.textDim,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Palette.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AppCard(
          color: const Color(0xFFF2F6EE),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Palette.primarySoft,
                child: Icon(Icons.description_rounded, color: Palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Palette.textDim,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: Palette.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Palette.primary),
            ],
          ),
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

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Palette.border),
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
                Expanded(
                  child: Text(
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
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Palette.primary,
                  size: 17,
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 43,
                height: 31,
                decoration: BoxDecoration(
                  color: active ? Palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(
                  icon,
                  color: active ? Palette.primaryDark : Palette.textDim,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Palette.primaryDark : Palette.textDim,
                  fontSize: 9.5,
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
