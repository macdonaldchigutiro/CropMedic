import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<File> _writeReportBytes(Uint8List bytes, String filename) async {
  final directory = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${directory.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> downloadWordReport(String html, String filename) async {
  final bytes = Uint8List.fromList(html.codeUnits);
  final file = await _writeReportBytes(bytes, filename);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/msword')],
    subject: 'CropMedic report',
  );
}

Future<void> downloadPdfReport(Uint8List bytes, String filename) async {
  final file = await _writeReportBytes(bytes, filename);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: 'CropMedic report',
  );
}
