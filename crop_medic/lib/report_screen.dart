import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'api.dart';
import 'brand.dart';
import 'report_export.dart';
import 'theme.dart';

class ReportScreen extends StatelessWidget {
  final Uint8List image;
  final Diagnosis diagnosis;
  final String lang;

  const ReportScreen({
    super.key,
    required this.image,
    required this.diagnosis,
    required this.lang,
  });

  String t(String en, String sn, String nd, String toi) {
    switch (lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  String get languageName {
    switch (lang) {
      case 'sn': return 'Shona';
      case 'nd': return 'Ndebele';
      case 'toi': return 'Tonga';
      default: return 'English';
    }
  }

  String get _safeCrop => diagnosis.crop.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  String get reportTitle => t('Crop health report', 'Report yehutano hwechirimwa', 'Umbiko wempilakahle yesilimo', 'Report yabubotu bwamulimo');
  String get statusText => diagnosis.isHealthy
      ? t('Leaf looks healthy', 'Shizha rinoratidzika rine utano', 'Iqabunga libonakala liphilile', 'Shizha liboneka libotu')
      : t('Disease detected', 'Chirwere chawonekwa', 'Kutholakale isifo', 'Bulwazi bwajanwa');
  String get cropLabel => t('Crop', 'Chirimwa', 'Isilimo', 'Mulimo');
  String get resultLabel => t('Result', 'Mhedzisiro', 'Impumela', 'Mbuyanda');
  String get confidenceLabel => t('Confidence', 'Chivimbo', 'Ukuthembeka', 'Kululama');
  String get nextStepsLabel => t('Recommended next steps', 'Zvekuita zvinokurudzirwa', 'Okulandelayo okunconywayo', 'Zyakucita zilandelako');
  String get alternativesLabel => t('Other possibilities considered', 'Zvimwe zvingangove zviri izvo', 'Okunye okucatshangelweyo', 'Zvimbi zyakulangisisigwa');
  String get noteLabel => t('Important note', 'Cherechedzo yakakosha', 'Isixwayiso esiqakathekileyo', 'Ciyeezyo cikankamanisya');
  String get disclaimer => t(
        'CropMedic supports crop-health decisions but does not replace a qualified agricultural extension officer, agronomist, laboratory diagnosis, or registered product label. Seek professional help when disease is severe, spreading quickly, or treatment is uncertain.',
        'CropMedic inobatsira pakuita sarudzo dzeutano hwechirimwa asi haitore nzvimbo yemukuru wezvekurima ane hunyanzvi, agronomist, ongororo yeraboritari kana mirau yechigadzirwa chakanyoreswa. Tsvaga rubatsiro rwenyanzvi kana chirwere chakanyanya, chichipararira nekukurumidza kana kurapwa kusina kujeka.',
        'CropMedic iyancedisa ekuthatheni izinqumo zempilakahle yesilimo kodwa ayithathi indawo yesisebenzi sezolimo esiqeqeshiweyo, agronomist, ukuhlolwa elabhorethri kumbe imiyalelo yomkhiqizo obhalisiweyo. Cela usizo lochwepheshe nxa isifo sinzima, sisabalala masinyane kumbe ukwelatshwa kungacacanga.',
        'CropMedic ilagwasya mukusalazya makani abubotu bwamulimo pele tayibikkwi mubusena bwamuntu wasikulima ulizyi, agronomist, kusunka kulaboratory na malayilile aproduct iregistridwe. Jana lugwasyo lwabazyi naa bulwazi buli bunkaka, bulaanda cakufwambaana na naa kulapa kutasalali.',
      );

  String _html() {
    final esc = const HtmlEscape();
    final photo = base64Encode(image);
    final date = DateTime.now();
    final dateText = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final advice = diagnosis.advice.map((a) => '<li>${esc.convert(a)}</li>').join();
    final alternatives = diagnosis.topPredictions
        .take(3)
        .map((p) => '<li>${esc.convert(p.crop)} - ${esc.convert(p.disease)} (${(p.confidence * 100).round()}%)</li>')
        .join();

    return '''<!doctype html>
<html><head><meta charset="utf-8"><title>CropMedic Report</title>
<style>
body{font-family:Arial,sans-serif;color:#15352c;margin:36px;line-height:1.45}
.header{display:flex;align-items:center;justify-content:space-between;border-bottom:3px solid #15654d;padding-bottom:16px;margin-bottom:24px}
.brand{font-size:28px;font-weight:800;color:#0f5d46}.tag{color:#777;font-size:12px}
.photo{width:100%;max-width:520px;border-radius:18px;margin:14px 0}.box{border:1px solid #dfe8df;border-radius:16px;padding:18px;margin:16px 0;background:#fbfcf8}
h1{color:#0f5d46;margin:0 0 8px}.status{display:inline-block;padding:6px 10px;border-radius:999px;background:#e5f2e7;font-weight:700}
.small{color:#65736e;font-size:12px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.label{color:#6b7773;font-size:12px}.value{font-size:20px;font-weight:800}.footer{margin-top:28px;padding-top:14px;border-top:1px solid #ddd;color:#777;font-size:11px}
</style></head><body>
<div class="header"><div><div class="brand">CropMedic</div><div class="tag">AI crop health assistant</div></div><div class="small">Date: $dateText<br>Language: $languageName</div></div>
<h1>${esc.convert(reportTitle)}</h1>
<span class="status">${esc.convert(statusText)}</span>
<img class="photo" src="data:image/jpeg;base64,$photo" alt="Crop image">
<div class="box grid">
<div><div class="label">${esc.convert(cropLabel)}</div><div class="value">${esc.convert(diagnosis.crop)}</div></div>
<div><div class="label">${esc.convert(resultLabel)}</div><div class="value">${esc.convert(diagnosis.isHealthy ? t('Healthy', 'Rine utano', 'Philile', 'Libotu') : diagnosis.disease)}</div></div>
<div><div class="label">${esc.convert(confidenceLabel)}</div><div class="value">${(diagnosis.confidence * 100).round()}%</div></div>
<div><div class="label">CropMedic</div><div class="value">Zimbabwe v2</div></div>
</div>
${diagnosis.advice.isNotEmpty ? '<div class="box"><h2>${esc.convert(nextStepsLabel)}</h2><ol>$advice</ol></div>' : ''}
${alternatives.isNotEmpty ? '<div class="box"><h2>${esc.convert(alternativesLabel)}</h2><ul>$alternatives</ul></div>' : ''}
<div class="box"><h2>${esc.convert(noteLabel)}</h2><p>${esc.convert(disclaimer)}</p></div>
<div class="footer">CropMedic - $languageName</div>
</body></html>''';
  }

  Future<Uint8List> _pdfBytes() async {
    final doc = pw.Document();
    final photo = pw.MemoryImage(image);
    final date = DateTime.now();
    final dateText = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final green = PdfColor.fromHex('#0F5D46');
    final muted = PdfColor.fromHex('#66736E');
    final soft = PdfColor.fromHex('#F2F6EE');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CropMedic', style: pw.TextStyle(fontSize: 27, fontWeight: pw.FontWeight.bold, color: green)),
                  pw.Text('AI crop health assistant', style: pw.TextStyle(fontSize: 10, color: muted)),
                ],
              ),
              pw.Text('Date: $dateText\nLanguage: $languageName', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: muted)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: green, thickness: 2),
          pw.SizedBox(height: 14),
          pw.Text(reportTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Text(statusText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: green)),
          ),
          pw.SizedBox(height: 14),
          pw.ClipRRect(
            horizontalRadius: 14,
            verticalRadius: 14,
            child: pw.Image(photo, height: 230, fit: pw.BoxFit.cover),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: soft, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Row(
              children: [
                pw.Expanded(child: _pdfField(cropLabel, diagnosis.crop, green, muted)),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _pdfField(resultLabel, diagnosis.isHealthy ? t('Healthy', 'Rine utano', 'Philile', 'Libotu') : diagnosis.disease, green, muted)),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _pdfField(confidenceLabel, '${(diagnosis.confidence * 100).round()}%', green, muted)),
              ],
            ),
          ),
          if (diagnosis.advice.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(nextStepsLabel, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: green)),
            pw.SizedBox(height: 8),
            ...List.generate(diagnosis.advice.length, (i) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(color: green, shape: pw.BoxShape.circle),
                      child: pw.Text('${i + 1}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Text(diagnosis.advice[i], style: const pw.TextStyle(fontSize: 11, lineSpacing: 3))),
                  ],
                ),
              );
            }),
          ],
          if (diagnosis.topPredictions.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(alternativesLabel, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: green)),
            pw.SizedBox(height: 6),
            ...diagnosis.topPredictions.take(3).map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('- ${p.crop} - ${p.disease}: ${(p.confidence * 100).round()}%', style: const pw.TextStyle(fontSize: 10.5)),
                )),
          ],
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#D8E1D7')), borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(noteLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: green)),
                pw.SizedBox(height: 5),
                pw.Text(disclaimer, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2.5)),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Text('CropMedic - Zimbabwe v2 - $languageName', style: pw.TextStyle(fontSize: 8, color: muted)),
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfField(String label, String value, PdfColor green, PdfColor muted) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: muted)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green)),
      ],
    );
  }

  Future<void> _downloadWord(BuildContext context) async {
    try {
      await downloadWordReport(_html(), 'CropMedic_${_safeCrop}_report.doc');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Word report downloaded.', 'Word report yadhawunirodhwa.', 'Umbiko weWord udawunilodiwe.', 'Word report yadanilodwa.'))));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final bytes = await _pdfBytes();
      await downloadPdfReport(bytes, 'CropMedic_${_safeCrop}_report.pdf');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('PDF report downloaded.', 'PDF report yadhawunirodhwa.', 'Umbiko wePDF udawunilodiwe.', 'PDF report yadanilodwa.'))));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t('Create report', 'Gadzira report', 'Dala umbiko', 'Konza report'),
                    style: const TextStyle(fontFamily: 'Georgia', fontSize: 34, fontWeight: FontWeight.w800, color: Palette.primaryDark),
                  ),
                  const SizedBox(height: 7),
                  Text('${t('Printable diagnosis report', 'Report yekuongorora inoprintwa', 'Umbiko wokuhlola oprintwayo', 'Report yascan yaamaprinta')} · $languageName', style: const TextStyle(color: Palette.textDim, fontSize: 15)),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(image, height: 190, width: double.infinity, fit: BoxFit.cover)),
                        const SizedBox(height: 16),
                        Text(diagnosis.crop, style: const TextStyle(color: Palette.textDim, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(diagnosis.isHealthy ? t('Healthy', 'Rine utano', 'Philile', 'Libotu') : diagnosis.disease, style: const TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.w800, color: Palette.primaryDark)),
                        const SizedBox(height: 6),
                        Text('${(diagnosis.confidence * 100).round()}% $confidenceLabel'),
                        const SizedBox(height: 16),
                        const Divider(color: Palette.border),
                        const SizedBox(height: 10),
                        Text(t('Included in report', 'Zviri mu report', 'Okusembikweni', 'Zili mu report'), style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          t(
                            '• crop photo\n• diagnosis and confidence\n• recommended next steps\n• alternative predictions\n• safety note',
                            '• mufananidzo wechirimwa\n• kuongorora nechivimbo\n• zvekuita zvinotevera\n• zvimwe zvingangove\n• cherechedzo yekuchengeteka',
                            '• isithombe sesilimo\n• impumela lokuthembeka\n• okulandelayo\n• ezinye impumela\n• isixwayiso sokuphepha',
                            '• foto yamulimo\n• mbuyanda akululama\n• zyakucita\n• zyakulangisisigwa\n• ciyeezyo cakusalala',
                          ),
                          style: const TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(label: t('Download PDF report', 'Dhawunirodha PDF report', 'Dawuniloda umbiko wePDF', 'Daniloda PDF report'), icon: Icons.picture_as_pdf_rounded, onPressed: () => _downloadPdf(context)),
                  const SizedBox(height: 10),
                  SecondaryActionButton(label: t('Download Word report', 'Dhawunirodha Word report', 'Dawuniloda umbiko weWord', 'Daniloda Word report'), icon: Icons.description_rounded, onPressed: () => _downloadWord(context)),
                  const SizedBox(height: 14),
                  Text(
                    t(
                      'The web preview downloads a real PDF and a Word-compatible .doc file. Mobile share/print integration is the next step.',
                      'Paweb unowana PDF chaiyo neWord-compatible .doc. Kugovera nekuprinta pafoni ndicho chinotevera.',
                      'Kuwebhu uthola iPDF yangempela lefayela le.doc elivulwa yiWord. Ukwabelana lokuphrinta efonini yisinyathelo esilandelayo.',
                      'Paweb ujana PDF ncobeni a .doc iijulwa aWord. Kushare akuprinta pafoni ndicilalako.',
                    ),
                    style: const TextStyle(color: Palette.textDim, fontSize: 12.5, height: 1.4),
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
