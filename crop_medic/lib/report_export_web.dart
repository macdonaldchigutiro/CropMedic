import 'dart:html' as html;

Future<void> downloadWordReport(String reportHtml, String filename) async {
  final blob = html.Blob([reportHtml], 'application/msword');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<void> printHtmlReport(String reportHtml) async {
  final popup = html.window.open('', 'cropmedic_report');
  popup.document.open();
  popup.document.write(reportHtml);
  popup.document.close();
  await Future<void>.delayed(const Duration(milliseconds: 350));
  popup.print();
}
