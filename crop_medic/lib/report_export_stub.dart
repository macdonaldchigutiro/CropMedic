import 'dart:typed_data';

Future<void> downloadWordReport(String html, String filename) async {
  throw UnsupportedError('Word report download is currently enabled in the web preview.');
}

Future<void> downloadPdfReport(Uint8List bytes, String filename) async {
  throw UnsupportedError('PDF download is currently enabled in the web preview.');
}
