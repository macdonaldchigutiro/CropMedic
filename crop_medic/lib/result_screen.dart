import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'brand.dart';
import 'localization.dart';
import 'report_screen.dart';
import 'scan_screen.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List image;
  final Diagnosis diagnosis;
  final String lang;

  const ResultScreen({
    super.key,
    required this.image,
    required this.diagnosis,
    required this.lang,
  });

  String tr(String key) => AppText.t(lang, key);

  String get reportLabel {
    switch (lang) {
      case 'sn': return 'Gadzira report inoprintwa';
      case 'nd': return 'Dala umbiko oprintwayo';
      case 'toi': return 'Konza report yaamaprinta';
      default: return 'Create printable report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthy = diagnosis.isHealthy;
    final statusColor = healthy ? Palette.primary : Palette.alert;
    final statusBg = healthy ? Palette.primarySoft : Palette.alertSoft;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                      const CropMedicBrand(compact: true, showTagline: false),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('scanResult'),
                    style: const TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, color: Palette.primaryDark, letterSpacing: -0.9),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.memory(image, width: 145, height: 165, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(healthy ? Icons.check_circle_rounded : Icons.warning_rounded, color: statusColor, size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            healthy ? tr('leafHealthy') : tr('diseaseDetected'),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(tr('crop'), style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                  Text(diagnosis.crop, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text(tr('result'), style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                  Text(
                                    healthy ? tr('healthy') : diagnosis.disease,
                                    style: TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: statusColor),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${(diagnosis.confidence * 100).round()}% ${tr('confidence')}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Palette.border),
                        const SizedBox(height: 10),
                        Text(
                          healthy
                              ? tr('healthySummary')
                              : '${tr('diseaseSummaryStart')} ${diagnosis.disease.toLowerCase()} ${tr('diseaseSummaryEnd')}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (diagnosis.advice.isNotEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('nextSteps'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Palette.primaryDark)),
                          const SizedBox(height: 14),
                          for (int i = 0; i < diagnosis.advice.length; i++) _AdviceRow(index: i, text: diagnosis.advice[i]),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: reportLabel,
                    icon: Icons.description_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReportScreen(image: image, diagnosis: diagnosis, lang: lang)),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SecondaryActionButton(
                    label: tr('backHome'),
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                  const SizedBox(height: 10),
                  SecondaryActionButton(
                    label: tr('scanAnother'),
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ScanScreen(lang: lang)));
                    },
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

class _AdviceRow extends StatelessWidget {
  final int index;
  final String text;
  const _AdviceRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Palette.gold,
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45, fontSize: 15.5))),
        ],
      ),
    );
  }
}
