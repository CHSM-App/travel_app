// Cross-platform delivery for generated report files (PDF / Excel).
//
// The actual implementation is swapped at compile time:
//   - mobile / desktop  -> report_saver_io.dart  (writes a temp file)
//   - web               -> report_saver_web.dart (triggers a browser download)
//
// This split is required because the web path needs `dart:html` (unavailable on
// mobile) while the mobile path needs `dart:io` + path_provider (unavailable on
// web).
import 'report_saver_io.dart'
    if (dart.library.html) 'report_saver_web.dart' as impl;

/// Persists [bytes] under [fileName] for the current platform.
///
/// Returns the on-disk file path on mobile/desktop so the caller can offer
/// Open / Share. On web the file is downloaded straight away and `null` is
/// returned (there is no addressable local path).
Future<String?> saveReportBytes(List<int> bytes, String fileName) =>
    impl.saveReportBytes(bytes, fileName);
