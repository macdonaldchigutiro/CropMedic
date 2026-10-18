import 'package:flutter/material.dart';

import 'brand.dart';
import 'diagnosis_history.dart';
import 'theme.dart';

class HistoryScreen extends StatefulWidget {
  final String lang;

  const HistoryScreen({super.key, required this.lang});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<DiagnosisHistoryEntry> _entries = const [];

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
    _reload();
  }

  Future<void> _reload() async {
    final entries = await DiagnosisHistoryStore.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ui('Clear saved diagnoses?', 'Bvisa ongororo dzakachengetwa?', 'Sula ukuhlolwa okulondoloziweyo?', 'Jaya buyandule bwakabikkwa?')),
        content: Text(ui(
          'This removes diagnosis history stored on this device. It does not affect your reports or the AI model.',
          'Izvi zvinobvisa nhoroondo yakachengetwa pafoni iyi. Hazvichinji mareport kana AI model.',
          'Lokhu kususa imbali yokuhlolwa egcinwe kulolu cingo. Akuthinti imibiko kumbe i-AI model.',
          'Eeci cijaya buyandule bwakabikkwa mucipangizo. Tacicinyi mareport naa AI model.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(ui('Cancel', 'Kanzura', 'Khansela', 'Lesya'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(ui('Clear', 'Bvisa', 'Sula', 'Jaya'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await DiagnosisHistoryStore.clear();
    await _reload();
  }

  String _date(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }

  void _showDetails(DiagnosisHistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .45,
        maxChildSize: .9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Palette.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text(entry.crop, style: const TextStyle(color: Palette.textDim, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              entry.disease,
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 30, fontWeight: FontWeight.w800, color: Palette.primaryDark),
            ),
            const SizedBox(height: 8),
            Text('${(entry.confidence * 100).round()}% ${ui('confidence', 'chivimbo', 'ukuthembeka', 'kululama')} · ${_date(entry.createdAt)}'),
            const SizedBox(height: 18),
            if (entry.advice.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ui('Saved guidance', 'Mazano akachengetwa', 'Isiqondiso esigciniweyo', 'Malayilile akabikkwa'),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Palette.primaryDark),
                    ),
                    const SizedBox(height: 10),
                    for (final line in entry.advice)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
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
            const SizedBox(height: 14),
            Text(
              ui(
                'Saved history is for reference. If the crop has changed or symptoms are spreading, take a new photo and run a fresh diagnosis.',
                'Nhoroondo ndeyekutarisa chete. Kana chirimwa chachinja kana zviratidzo zvichipararira, tora mufananidzo mutsva woongorora zvakare.',
                'Imbali ngeyokubheka kuphela. Nxa isilimo sitshintshile kumbe izimpawu zisabalala, thatha umfanekiso omutsha uhlolisise futhi.',
                'Bwakabikkwa mbwakulanga alikke. Naa mulimo wacinja naa zibonakaliso zilazwidila, tola foto impya uyandule alimwi.',
              ),
              style: const TextStyle(color: Palette.textDim, fontSize: 12.5, height: 1.4),
            ),
          ],
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                        const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                        if (_entries.isNotEmpty)
                          IconButton(
                            tooltip: ui('Clear history', 'Bvisa nhoroondo', 'Sula imbali', 'Jaya bwakabikkwa'),
                            onPressed: _clear,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: Palette.primary))
                        : _entries.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                                itemCount: _entries.length,
                                itemBuilder: (_, index) {
                                  final entry = _entries[index];
                                  final healthy = entry.disease.toLowerCase() == 'healthy';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 11),
                                    child: InkWell(
                                      onTap: () => _showDetails(entry),
                                      borderRadius: BorderRadius.circular(22),
                                      child: AppCard(
                                        padding: const EdgeInsets.all(14),
                                        radius: 22,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: healthy ? Palette.primarySoft : Palette.alertSoft,
                                              child: Icon(
                                                healthy ? Icons.check_circle_rounded : Icons.eco_rounded,
                                                color: healthy ? Palette.primary : Palette.alert,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(entry.crop, style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                                  const SizedBox(height: 2),
                                                  Text(entry.disease, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Palette.primaryDark)),
                                                  const SizedBox(height: 4),
                                                  Text('${(entry.confidence * 100).round()}% · ${_date(entry.createdAt)}', style: const TextStyle(fontSize: 11.5, color: Palette.textDim)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right_rounded, color: Palette.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: Palette.primarySoft,
              child: Icon(Icons.history_rounded, color: Palette.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              ui('No saved diagnoses yet', 'Hapana ongororo dzakachengetwa', 'Akukho ukuhlolwa okulondoloziweyo', 'Takuna buyandule bwakabikkwa'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.w800, color: Palette.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              ui(
                'Completed diagnoses will appear here automatically on this device.',
                'Ongororo dzapera dzichazongochengetwa pano pafoni iyi.',
                'Ukuhlolwa okupheleleyo kuzagcinwa lapha kulolu cingo.',
                'Buyandule bwamana bulakabikkwa muno mucipangizo.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.textDim, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
