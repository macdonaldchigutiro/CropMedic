import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'brand.dart';
import 'crop_catalog.dart';
import 'diagnosis_flow.dart';
import 'disease_library_v1_screen.dart';
import 'extension_help_screen.dart';
import 'history_screen.dart';
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
  bool? _serviceReachable;
  List<CropOption> _diagnosisCrops = supportedCrops;

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
      if (!mounted) return;
      setState(() {
        _serviceReachable = true;
        if (options.isNotEmpty) _diagnosisCrops = options;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _serviceReachable = false);
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
    if (!mounted) return;
    setState(() => _busy = true);
    await startDiagnosisFlow(context, bytes, _lang, presetCrop: presetCrop);
    if (mounted) setState(() => _busy = false);
  }

  void _openScan({String? crop}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanScreen(lang: _lang, presetCrop: crop)),
    );
  }

  void _openLibrary({String? crop}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiseaseLibraryV1Screen(lang: _lang, initialCrop: crop),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryScreen(lang: _lang)),
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
                          ui('Supported in CropMedic V1', 'Inotsigirwa muCropMedic V1', 'Isekwa yiCropMedic V1', 'Ilagwasigwa muCropMedic V1'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Container(
                color: Palette.bg.withOpacity(.98),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _hero(),
                          const SizedBox(height: 14),
                          _PrimaryAction(
                            icon: Icons.camera_alt_rounded,
                            title: _busy
                                ? tr('checkingPhoto')
                                : ui('Scan affected crop', 'Skena chirimwa chakabatwa', 'Skena isilimo esithintekileyo', 'Skena mulimo wajatwa'),
                            onTap: _busy ? null : () => _openScan(),
                          ),
                          const SizedBox(height: 9),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _pickGallery(),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(tr('uploadPhoto')),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle(ui('Supported crops', 'Zvirimwa zvinotsigirwa', 'Izilimo ezisekelwayo', 'Milimo ilagwasigwa')),
                          const SizedBox(height: 6),
                          Text(
                            ui(
                              'CropMedic V1 is deliberately focused on four crops: Maize, Tomato, Potato and Bell pepper.',
                              'CropMedic V1 yakatarisana nezvirimwa zvina: Chibage, Madomasi, Mbatatisi neMhiripiri.',
                              'CropMedic V1 igxile ezilimweni ezine: Umumbu, Utamatisi, Amazambane loUpelepele.',
                              'CropMedic V1 ilagwasya milimo iine: Maize, Tomato, Potato a Bell pepper.',
                            ),
                            style: const TextStyle(color: Palette.textDim, fontSize: 12.8, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.75,
                            children: _diagnosisCrops
                                .map((crop) => _CropCard(
                                      crop: crop,
                                      lang: _lang,
                                      onTap: () => _showCropActions(crop),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 26),
                          _sectionTitle(ui('Farmer tools', 'Zvishandiso zvemurimi', 'Amathuluzi omlimi', 'Zyakubelensya mulimi')),
                          const SizedBox(height: 12),
                          _ToolCard(
                            icon: Icons.history_rounded,
                            title: ui('Saved diagnoses', 'Ongororo dzakachengetwa', 'Ukuhlolwa okulondoloziweyo', 'Buyandule bwakabikkwa'),
                            text: ui('Review completed diagnoses and saved guidance on this device.', 'Tarisa ongororo nemazano akachengetwa pafoni iyi.', 'Bheka ukuhlolwa lesiqondiso esigcinwe kulolu cingo.', 'Langa buyandule amalayilile akabikkwa mucipangizo.'),
                            onTap: _openHistory,
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.menu_book_rounded,
                            title: ui('Disease library', 'Raibhurari yezvirwere', 'Umtapo wezifo', 'Layiburari yabuzwayi'),
                            text: ui('Offline symptoms, prevention and practical first steps for the four supported crops.', 'Zviratidzo, kudzivirira nezvekutanga kuita pasina internet.', 'Izimpawu, ukuvikela lokuqala ukukwenza ngaphandle kwe-inthanethi.', 'Zibonakaliso, kuzwidilila azya kutanguna kucita offline.'),
                            onTap: () => _openLibrary(),
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.cloud_rounded,
                            title: ui('Weather & crop risk', 'Mamiriro ekunze nenjodzi', 'Isimo sezulu lengozi', 'Mvula anjodzi'),
                            text: ui('Live weather plus simple crop-risk alerts.', 'Mamiriro aripo pamwe neyambiro yenjodzi.', 'Isimo samanje lezixwayiso zezingozi.', 'Mvula lino alulayo lwanjodzi.'),
                            onTap: _openWeather,
                          ),
                          const SizedBox(height: 10),
                          _ToolCard(
                            icon: Icons.support_agent_rounded,
                            title: ui('Extension services', 'Rubatsiro rwevarimisi', 'Usizo lwabalimi', 'Lugwasyo lwabalimi'),
                            text: ui('Find verified agricultural support contacts where available.', 'Tsvaga macontact erubatsiro rwekurima akasimbiswa.', 'Thola ama-contact osizo lwezolimo aqinisekisiweyo.', 'Jana macontact alugwasyo lwamilimo asinizidwe.'),
                            onTap: _openHelp,
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5DE),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Palette.gold),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ui(
                                      'AI diagnosis needs an internet connection in V1. The disease library and saved diagnosis history remain available on the device.',
                                      'AI diagnosis inoda internet muV1. Raibhurari yezvirwere nenhoroondo yakachengetwa zvinoramba zviripo pafoni.',
                                      'Ukuhlolwa nge-AI kudinga i-inthanethi kuV1. Umtapo wezifo lembali yokuhlolwa kuhlala kulolu cingo.',
                                      'AI diagnosis ilacida internet muV1. Layiburari yabuzwayi abwakabikkwa zilasala mucipangizo.',
                                    ),
                                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
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
    final connected = _serviceReachable;
    final statusText = connected == null
        ? ui('Checking AI service', 'Kutarisa AI service', 'Ukuhlola i-AI service', 'Kulanga AI service')
        : connected
            ? ui('AI service connected', 'AI service yakabatana', 'I-AI service ixhunyiwe', 'AI service yakamantidwe')
            : ui('Offline mode', 'Offline mode', 'Offline mode', 'Offline mode');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F8EE), Color(0xFFE2F0DA)],
        ),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Palette.surface.withOpacity(.8), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected == false ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                      size: 16,
                      color: connected == false ? Palette.gold : Palette.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(statusText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Spacer(),
              const Text('🌽  🍅  🥔  🫑', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ui('Fast crop health checks, focused on four crops.', 'Ongororo inokurumidza yezvirimwa zvina.', 'Ukuhlolwa okusheshayo kwezilimo ezine.', 'Buyandule bwamilimo iine bwakufwambaana.'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 30,
              height: 1.02,
              fontWeight: FontWeight.w800,
              color: Palette.primaryDark,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ui(
              'Take a clear photo, confirm the crop, then CropMedic checks supported diseases and gives practical next steps.',
              'Tora mufananidzo wakajeka, simbisa chirimwa, CropMedic yobva yaongorora zvirwere zvinotsigirwa nekupa mazano.',
              'Thatha umfanekiso ocacileyo, qinisekisa isilimo, iCropMedic ihlole izifo ezisekelwayo ikunike amanyathelo alandelayo.',
              'Tola foto icena, sinizya mulimo, CropMedic iyandule bulwazi bulagwasigwa ikupe malayilile.',
            ),
            style: const TextStyle(color: Palette.textDim, fontSize: 14, height: 1.4),
          ),
        ],
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
          _NavItem(icon: Icons.history_rounded, label: ui('History', 'Nhoroondo', 'Imbali', 'Bwakabikkwa'), onTap: _openHistory),
          _NavItem(icon: Icons.menu_book_outlined, label: ui('Library', 'Raibhurari', 'Umtapo', 'Layiburari'), onTap: () => _openLibrary()),
          _NavItem(icon: Icons.support_agent_outlined, label: tr('help'), onTap: _openHelp),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.w800, color: Palette.primaryDark),
      );
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _PrimaryAction({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w800)),
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
                decoration: BoxDecoration(
                  color: active ? Palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(icon, color: active ? Palette.primaryDark : Palette.textDim, size: 20),
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
