// Mobile / desktop implementation: write the bytes to a temp file and return
// its path so the caller can Open or Share it.
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveReportBytes(List<int> bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
