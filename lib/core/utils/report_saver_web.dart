// Web implementation: turn the bytes into a Blob and trigger a browser
// download. There is no addressable file path on web, so return null.
// ignore_for_file: deprecated_member_use
import 'dart:html' as html;

Future<String?> saveReportBytes(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return null;
}
