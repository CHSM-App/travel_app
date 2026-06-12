// Reusable customer-report export: data model + PDF/Excel generators + the
// chooser → generate → save → open/share flow. Shared by the fleet-wide
// Customer list screen and the per-customer history screen so both produce an
// identical document (Overview, Account summary, Trips per customer).
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/utils/report_saver.dart';
import 'package:travel_agency_app/core/widgets/trip_filter.dart' show tripSortKey;
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';

// ── Design tokens (mirror the report screens) ──────────────────────────────
class _Tok {
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F4FA);
  static const accent = AppColors.brandPrimary;
  static const text1 = Color(0xFF0F1729);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFFA3ABBD);
  static const divider = Color(0xFFE6EAF2);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFD1FAE5);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0xFFFEE2E2);
}

/// Export target chosen from the export sheet.
enum CustomerReportExportFormat { pdf, excel }

/// Per-customer figures + the period trips that drive the detail pages.
class CustomerReportStat {
  final Customer customer;
  final List<BookingInfo> trips;

  const CustomerReportStat({required this.customer, this.trips = const []});

  int get tripCount => trips.length;
  double get received =>
      trips.fold<double>(0, (s, t) => s + (t.amountReceived ?? 0));
  double get approved =>
      trips.fold<double>(0, (s, t) => s + (t.amountApprove ?? 0));
  double get pending {
    double p = 0;
    for (final t in trips) {
      final due = (t.amountApprove ?? 0) - (t.amountReceived ?? 0);
      if (due > 0) p += due;
    }
    return p;
  }

  bool get hasActivity => tripCount > 0;
}

/// Everything a report document renders, computed once and shared by the UI and
/// the exporters so the file always matches what is on screen.
class CustomerReportSnapshot {
  final String title; // e.g. "Customer Report" or "Anita Report"
  final String periodLabel; // e.g. "All" / "Last 30 Days" / "Custom"
  final String dateRangeLabel; // e.g. "01 Jun 2026 - 30 Jun 2026"
  final List<CustomerReportStat> stats;
  final double totalReceived;
  final double totalApproved;
  final int activeCustomers;
  final int totalCustomers;
  final int tripCount;

  const CustomerReportSnapshot({
    required this.title,
    required this.periodLabel,
    required this.dateRangeLabel,
    required this.stats,
    required this.totalReceived,
    required this.totalApproved,
    required this.activeCustomers,
    required this.totalCustomers,
    required this.tripCount,
  });

  double get totalPending {
    final p = totalApproved - totalReceived;
    return p > 0 ? p : 0;
  }
}

// ── Formatting helpers ─────────────────────────────────────────────────────
final NumberFormat _moneyFmt = NumberFormat('#,##0', 'en_IN');
String _money(double v) =>
    '${v < 0 ? '-' : ''}Rs. ${_moneyFmt.format(v.abs())}';
String _fmtDate(DateTime? d) =>
    d == null ? '-' : DateFormat('dd MMM yyyy').format(d);
String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

String _fileBase(String title) {
  final cleaned = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? 'Report' : trimmed;
}

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC FLOW: chooser → generate → save → open/share
// ═══════════════════════════════════════════════════════════════════════════
Future<void> runCustomerReportExport(
  BuildContext context,
  CustomerReportSnapshot snap,
) async {
  final fmt = await showModalBottomSheet<CustomerReportExportFormat>(
    context: context,
    backgroundColor: _Tok.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ExportChooserSheet(
      title: snap.title,
      periodLabel: snap.periodLabel,
      rangeLabel: snap.dateRangeLabel,
    ),
  );
  if (fmt == null || !context.mounted) return;

  // Blocking spinner while the file is generated + saved.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: _Tok.accent),
    ),
  );

  String? path;
  var ok = false;
  try {
    final isPdf = fmt == CustomerReportExportFormat.pdf;
    final bytes = isPdf
        ? await CustomerReportPdf.build(snap)
        : await CustomerReportExcel.build(snap);
    final fileName =
        '${_fileBase(snap.title)}_${_stamp()}.${isPdf ? 'pdf' : 'xlsx'}';
    path = await saveReportBytes(bytes, fileName);
    ok = true;
  } catch (_) {
    ok = false;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // dismiss the spinner

  if (!ok) {
    _snack(context, 'Export failed. Please try again.', error: true);
    return;
  }
  if (path == null) {
    _snack(context, 'Report downloaded');
    return;
  }
  await showModalBottomSheet(
    context: context,
    backgroundColor: _Tok.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExportReadySheet(path: path!, format: fmt),
  );
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? _Tok.red : _Tok.text1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ── Chooser sheet ──────────────────────────────────────────────────────────
class _ExportChooserSheet extends StatelessWidget {
  final String title;
  final String periodLabel;
  final String rangeLabel;
  const _ExportChooserSheet({
    required this.title,
    required this.periodLabel,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _Tok.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    color: _Tok.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Tok.text1,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$periodLabel  ·  $rangeLabel',
                      style: const TextStyle(
                        color: _Tok.text2,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _option(
            context,
            format: CustomerReportExportFormat.pdf,
            icon: Icons.picture_as_pdf_rounded,
            color: _Tok.red,
            bg: _Tok.redSoft,
            label: 'PDF Document',
            sub: 'Formatted, ready to print or share',
          ),
          const SizedBox(height: 10),
          _option(
            context,
            format: CustomerReportExportFormat.excel,
            icon: Icons.table_chart_rounded,
            color: _Tok.green,
            bg: _Tok.greenSoft,
            label: 'Excel Spreadsheet',
            sub: 'Editable .xlsx with all figures',
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required CustomerReportExportFormat format,
    required IconData icon,
    required Color color,
    required Color bg,
    required String label,
    required String sub,
  }) {
    return Material(
      color: _Tok.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(format),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Tok.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _Tok.text1,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: _Tok.text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _Tok.text3, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ready sheet (open + share) ──────────────────────────────────────────────
class _ExportReadySheet extends StatelessWidget {
  final String path;
  final CustomerReportExportFormat format;
  const _ExportReadySheet({required this.path, required this.format});

  @override
  Widget build(BuildContext context) {
    final isPdf = format == CustomerReportExportFormat.pdf;
    final color = isPdf ? _Tok.red : _Tok.green;
    final bg = isPdf ? _Tok.redSoft : _Tok.greenSoft;
    final icon =
        isPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded;
    final fileName = path.split(RegExp(r'[\\/]')).last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _Tok.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 12),
          const Text(
            'Report Ready!',
            style: TextStyle(
              color: _Tok.text1,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fileName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _Tok.text2, fontSize: 10.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _Tok.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                OpenFile.open(path);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                'Open ${isPdf ? 'PDF' : 'Excel'}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _Tok.accent,
                side: BorderSide(color: _Tok.accent.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                share_plus.Share.shareXFiles(
                  [share_plus.XFile(path)],
                  subject: 'Customer Report',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text(
                'Share',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PDF GENERATOR
// ═══════════════════════════════════════════════════════════════════════════
class CustomerReportPdf {
  static final _accent = PdfColor.fromHex('#3D5AFE');
  static final _dark = PdfColor.fromHex('#1A237E');
  static final _td = PdfColor.fromHex('#0F1729');
  static final _tg = PdfColor.fromHex('#6B7280');
  static final _dl = PdfColor.fromHex('#E6EAF2');
  static final _green = PdfColor.fromHex('#10B981');
  static final _orange = PdfColor.fromHex('#F59E0B');
  static final _bgP = PdfColor.fromHex('#F5F7FB');
  static final _greenSoft = PdfColor.fromHex('#E8F8F1');

  static final _hStyle = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
  );
  static final _rStyle = pw.TextStyle(color: _td, fontSize: 8.5);
  static final _gStyle = pw.TextStyle(color: _tg, fontSize: 8.5);
  static final _bStyle =
      pw.TextStyle(color: _td, fontSize: 8.5, fontWeight: pw.FontWeight.bold);

  static pw.Widget _cell(
    String t,
    pw.TextStyle s, {
    pw.TextAlign a = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(t, style: s, textAlign: a),
      );

  static pw.Widget _kpi(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _dl),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(label, style: pw.TextStyle(color: _tg, fontSize: 8)),
            ],
          ),
        ),
      );

  static pw.Widget _sectionBar(String title) => pw.Row(
        children: [
          pw.Container(width: 4, height: 13, color: _accent),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _td,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      );

  static pw.Widget _note(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: pw.BoxDecoration(
          color: _bgP,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _dl),
        ),
        child: pw.Text(text, style: _gStyle),
      );

  static pw.Widget _overview(Customer c) {
    final pairs = <List<String>>[
      ['Name', c.name ?? '-'],
      ['Phone', (c.phone != null && c.phone!.trim().isNotEmpty) ? c.phone!.trim() : '-'],
      ['Address', (c.address != null && c.address!.trim().isNotEmpty) ? c.address!.trim() : '-'],
      ['Licence No', (c.licenceNo != null && c.licenceNo!.trim().isNotEmpty) ? c.licenceNo!.trim() : '-'],
      ['Licence Expiry', _fmtDate(c.licenceExpiry)],
    ];
    final rows = <pw.TableRow>[];
    for (var i = 0; i < pairs.length; i += 2) {
      final left = pairs[i];
      final right = i + 1 < pairs.length ? pairs[i + 1] : ['', ''];
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: (i ~/ 2) % 2 == 0 ? PdfColors.white : _bgP,
        ),
        children: [
          _cell(left[0], _gStyle),
          _cell(left[1], _bStyle),
          _cell(right[0], _gStyle),
          _cell(right[1], _bStyle),
        ],
      ));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _dl, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  static pw.Widget _tripsTable(List<BookingInfo> trips) {
    return pw.Table(
      border: pw.TableBorder.all(color: _dl, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(2.6),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _accent),
          children: [
            _cell('#', _hStyle, a: pw.TextAlign.center),
            _cell('Date', _hStyle),
            _cell('Route', _hStyle),
            _cell('Status', _hStyle),
            _cell('Approved', _hStyle, a: pw.TextAlign.right),
            _cell('Received', _hStyle, a: pw.TextAlign.right),
          ],
        ),
        ...trips.asMap().entries.map((e) {
          final t = e.value;
          final route =
              '${t.pickupLocation ?? '-'} -> ${t.dropLocation ?? '-'}';
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key % 2 == 0 ? PdfColors.white : _bgP,
            ),
            children: [
              _cell('${e.key + 1}', _gStyle, a: pw.TextAlign.center),
              _cell(_fmtDate(tripSortKey(t)), _gStyle),
              _cell(route, _gStyle),
              _cell(t.tripStatus ?? '-', _gStyle),
              _cell(_money(t.amountApprove ?? 0), _gStyle,
                  a: pw.TextAlign.right),
              _cell(_money(t.amountReceived ?? 0), _rStyle,
                  a: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _customerDetail(
    CustomerReportStat s,
    int index, {
    bool pageBreak = true,
  }) {
    final c = s.customer;
    return [
      if (pageBreak) pw.NewPage(),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [_accent, _dark],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              index > 0 ? '$index. ${c.name ?? 'Unknown'}' : (c.name ?? 'Unknown'),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              (c.phone != null && c.phone!.trim().isNotEmpty)
                  ? c.phone!.trim()
                  : 'No phone',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          _kpi('Received', _money(s.received), _green),
          pw.SizedBox(width: 8),
          _kpi('Approved', _money(s.approved), _accent),
          pw.SizedBox(width: 8),
          _kpi('Pending', _money(s.pending), _orange),
          pw.SizedBox(width: 8),
          _kpi('Trips', '${s.tripCount}', _dark),
        ],
      ),
      pw.SizedBox(height: 14),
      _sectionBar('Overview'),
      pw.SizedBox(height: 6),
      _overview(c),
      pw.SizedBox(height: 14),
      _sectionBar('Trips (${s.tripCount})'),
      pw.SizedBox(height: 6),
      s.trips.isEmpty ? _note('No trips in this period.') : _tripsTable(s.trips),
    ];
  }

  static Future<List<int>> build(CustomerReportSnapshot snap) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final detailed = snap.stats.where((s) => s.hasActivity).toList();
    // A single-customer report skips the redundant summary table and leads with
    // the detail; a roster report keeps the summary then one detail page each.
    final isSingle = snap.stats.length == 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  '${snap.title}  -  ${snap.periodLabel}',
                  style: pw.TextStyle(color: _tg, fontSize: 9),
                ),
              ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _dl)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(snap.title,
                  style: pw.TextStyle(color: _tg, fontSize: 8)),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(color: _tg, fontSize: 8),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Cover header band
          pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_accent, _dark],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  snap.title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Period: ${snap.periodLabel}  (${snap.dateRangeLabel})',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Generated: $dateStr',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          // KPI summary
          pw.Row(
            children: [
              _kpi('Total Received', _money(snap.totalReceived), _green),
              pw.SizedBox(width: 10),
              _kpi('Approved', _money(snap.totalApproved), _accent),
              pw.SizedBox(width: 10),
              _kpi('Pending', _money(snap.totalPending), _orange),
              pw.SizedBox(width: 10),
              _kpi(
                isSingle ? 'Trips' : 'Active / Total',
                isSingle
                    ? '${snap.tripCount}'
                    : '${snap.activeCustomers} / ${snap.totalCustomers}',
                _dark,
              ),
            ],
          ),
          if (!isSingle) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              '${snap.tripCount} trip${snap.tripCount == 1 ? '' : 's'} in this period',
              style: pw.TextStyle(color: _tg, fontSize: 9),
            ),
            pw.SizedBox(height: 18),
            _sectionBar('Per Customer Summary'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _dl, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),
                1: const pw.FlexColumnWidth(2.4),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(0.9),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(1.6),
                6: const pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _accent),
                  children: [
                    _cell('#', _hStyle, a: pw.TextAlign.center),
                    _cell('Customer', _hStyle),
                    _cell('Phone', _hStyle),
                    _cell('Trips', _hStyle, a: pw.TextAlign.center),
                    _cell('Received', _hStyle, a: pw.TextAlign.right),
                    _cell('Pending', _hStyle, a: pw.TextAlign.right),
                    _cell('Approved', _hStyle, a: pw.TextAlign.right),
                  ],
                ),
                ...snap.stats.asMap().entries.map((e) {
                  final s = e.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: e.key % 2 == 0 ? PdfColors.white : _bgP,
                    ),
                    children: [
                      _cell('${e.key + 1}', _gStyle, a: pw.TextAlign.center),
                      _cell(s.customer.name ?? 'Unknown', _rStyle),
                      _cell(
                        (s.customer.phone != null &&
                                s.customer.phone!.trim().isNotEmpty)
                            ? s.customer.phone!.trim()
                            : '-',
                        _gStyle,
                      ),
                      _cell('${s.tripCount}', _gStyle, a: pw.TextAlign.center),
                      _cell(_money(s.received), _rStyle, a: pw.TextAlign.right),
                      _cell(_money(s.pending), _gStyle, a: pw.TextAlign.right),
                      _cell(_money(s.approved), _rStyle,
                          a: pw.TextAlign.right),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _greenSoft),
                  children: [
                    _cell('', _gStyle),
                    _cell('TOTAL', _bStyle),
                    _cell('', _gStyle),
                    _cell('${snap.tripCount}', _bStyle, a: pw.TextAlign.center),
                    _cell(
                      _money(snap.totalReceived),
                      pw.TextStyle(
                        color: _green,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      a: pw.TextAlign.right,
                    ),
                    _cell(_money(snap.totalPending), _bStyle,
                        a: pw.TextAlign.right),
                    _cell(_money(snap.totalApproved), _bStyle,
                        a: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
          ],
          // Per-customer detail. For a single customer the first detail flows on
          // the cover page (no page break); a roster starts each on a new page.
          if (isSingle && detailed.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            ..._customerDetail(detailed.first, 0, pageBreak: false),
          ] else
            for (var i = 0; i < detailed.length; i++)
              ..._customerDetail(detailed[i], i + 1),
        ],
      ),
    );

    return pdf.save();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXCEL GENERATOR
// ═══════════════════════════════════════════════════════════════════════════
class CustomerReportExcel {
  static final _headerStyle = xls.CellStyle(
    bold: true,
    fontColorHex: xls.ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: xls.ExcelColor.fromHexString('#3D5AFE'),
    horizontalAlign: xls.HorizontalAlign.Center,
  );
  static final _titleStyle = xls.CellStyle(bold: true, fontSize: 14);
  static final _sectionStyle = xls.CellStyle(
    bold: true,
    fontColorHex: xls.ExcelColor.fromHexString('#1A237E'),
  );
  static final _boldStyle = xls.CellStyle(bold: true);
  static final _totalStyle = xls.CellStyle(
    bold: true,
    backgroundColorHex: xls.ExcelColor.fromHexString('#E8F8F1'),
  );

  static void _style(xls.Sheet sheet, int col, int row, xls.CellStyle style) {
    sheet
        .cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .cellStyle = style;
  }

  static String _sheetName(CustomerReportStat s, int idx, Set<String> used) {
    var base = (s.customer.name?.trim().isNotEmpty ?? false)
        ? s.customer.name!.trim()
        : 'Customer $idx';
    base = base.replaceAll(RegExp(r'[\\/\?\*\[\]:]'), ' ').trim();
    var name = '$idx. $base';
    if (name.length > 31) name = name.substring(0, 31);
    var candidate = name;
    var k = 1;
    while (used.contains(candidate)) {
      final suffix = ' ($k)';
      final head = name.length + suffix.length > 31
          ? name.substring(0, 31 - suffix.length)
          : name;
      candidate = '$head$suffix';
      k++;
    }
    used.add(candidate);
    return candidate;
  }

  static Future<List<int>> build(CustomerReportSnapshot snap) async {
    final excel = xls.Excel.createExcel();
    const summaryName = 'Summary';
    final sheet = excel[summaryName];
    excel.setDefaultSheet(summaryName);
    for (final s in excel.sheets.keys.toList()) {
      if (s != summaryName) excel.delete(s);
    }

    int r = 0;
    sheet.appendRow([xls.TextCellValue(snap.title)]);
    _style(sheet, 0, r, _titleStyle);
    r++;
    void meta(String k, String v) {
      sheet.appendRow([xls.TextCellValue(k), xls.TextCellValue(v)]);
      _style(sheet, 0, r, _boldStyle);
      r++;
    }

    meta('Period', snap.periodLabel);
    meta('Date Range', snap.dateRangeLabel);
    meta('Generated',
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()));
    sheet.appendRow([]);
    r++;

    void summaryNum(String k, double v) {
      sheet.appendRow([xls.TextCellValue(k), xls.DoubleCellValue(v)]);
      _style(sheet, 0, r, _boldStyle);
      r++;
    }

    summaryNum('Total Received', snap.totalReceived);
    summaryNum('Total Approved', snap.totalApproved);
    summaryNum('Total Pending', snap.totalPending);
    meta('Active / Total Customers',
        '${snap.activeCustomers} / ${snap.totalCustomers}');
    sheet.appendRow([
      xls.TextCellValue('Trips in Period'),
      xls.IntCellValue(snap.tripCount),
    ]);
    _style(sheet, 0, r, _boldStyle);
    r++;
    sheet.appendRow([]);
    r++;

    const headers = [
      '#',
      'Customer',
      'Phone',
      'Trips',
      'Received',
      'Pending',
      'Approved',
    ];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());
    for (var c = 0; c < headers.length; c++) {
      _style(sheet, c, r, _headerStyle);
    }
    r++;
    for (var i = 0; i < snap.stats.length; i++) {
      final s = snap.stats[i];
      sheet.appendRow([
        xls.IntCellValue(i + 1),
        xls.TextCellValue(s.customer.name ?? 'Unknown'),
        xls.TextCellValue(
          (s.customer.phone != null && s.customer.phone!.trim().isNotEmpty)
              ? s.customer.phone!.trim()
              : '-',
        ),
        xls.IntCellValue(s.tripCount),
        xls.DoubleCellValue(s.received),
        xls.DoubleCellValue(s.pending),
        xls.DoubleCellValue(s.approved),
      ]);
      r++;
    }
    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue('TOTAL'),
      xls.TextCellValue(''),
      xls.IntCellValue(snap.tripCount),
      xls.DoubleCellValue(snap.totalReceived),
      xls.DoubleCellValue(snap.totalPending),
      xls.DoubleCellValue(snap.totalApproved),
    ]);
    for (var c = 0; c < headers.length; c++) {
      _style(sheet, c, r, _totalStyle);
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 8);
    for (var c = 4; c <= 6; c++) {
      sheet.setColumnWidth(c, 14);
    }

    final used = <String>{summaryName};
    final detailed = snap.stats.where((s) => s.hasActivity).toList();
    for (var i = 0; i < detailed.length; i++) {
      _buildCustomerSheet(excel, detailed[i], i + 1, used);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel workbook');
    }
    return bytes;
  }

  static void _buildCustomerSheet(
    xls.Excel excel,
    CustomerReportStat stat,
    int idx,
    Set<String> used,
  ) {
    final c = stat.customer;
    final sheet = excel[_sheetName(stat, idx, used)];
    int r = 0;

    void blank() {
      sheet.appendRow([]);
      r++;
    }

    void section(String title) {
      sheet.appendRow([xls.TextCellValue(title)]);
      _style(sheet, 0, r, _sectionStyle);
      r++;
    }

    void kv(String k, xls.CellValue value) {
      sheet.appendRow([xls.TextCellValue(k), value]);
      _style(sheet, 0, r, _boldStyle);
      r++;
    }

    sheet.appendRow([
      xls.TextCellValue(
        '${c.name ?? 'Unknown'}'
        '${(c.phone != null && c.phone!.trim().isNotEmpty) ? '  (${c.phone!.trim()})' : ''}',
      ),
    ]);
    _style(sheet, 0, r, _titleStyle);
    r++;
    blank();

    section('Overview');
    kv(
      'Phone',
      xls.TextCellValue(
        (c.phone != null && c.phone!.trim().isNotEmpty) ? c.phone!.trim() : '-',
      ),
    );
    kv(
      'Address',
      xls.TextCellValue(
        (c.address != null && c.address!.trim().isNotEmpty)
            ? c.address!.trim()
            : '-',
      ),
    );
    kv(
      'Licence No',
      xls.TextCellValue(
        (c.licenceNo != null && c.licenceNo!.trim().isNotEmpty)
            ? c.licenceNo!.trim()
            : '-',
      ),
    );
    kv('Licence Expiry', xls.TextCellValue(_fmtDate(c.licenceExpiry)));
    blank();

    section('Account');
    kv('Received', xls.DoubleCellValue(stat.received));
    kv('Approved', xls.DoubleCellValue(stat.approved));
    kv('Pending', xls.DoubleCellValue(stat.pending));
    kv('Trips', xls.IntCellValue(stat.tripCount));
    blank();

    section('Trips (${stat.tripCount})');
    const tHeaders = [
      '#',
      'Date',
      'Route',
      'Status',
      'Approved',
      'Received',
    ];
    sheet.appendRow(tHeaders.map((h) => xls.TextCellValue(h)).toList());
    for (var col = 0; col < tHeaders.length; col++) {
      _style(sheet, col, r, _headerStyle);
    }
    r++;
    if (stat.trips.isEmpty) {
      sheet.appendRow([xls.TextCellValue('No trips in this period.')]);
      r++;
    } else {
      for (var i = 0; i < stat.trips.length; i++) {
        final t = stat.trips[i];
        sheet.appendRow([
          xls.IntCellValue(i + 1),
          xls.TextCellValue(_fmtDate(tripSortKey(t))),
          xls.TextCellValue(
              '${t.pickupLocation ?? '-'} -> ${t.dropLocation ?? '-'}'),
          xls.TextCellValue(t.tripStatus ?? '-'),
          xls.DoubleCellValue(t.amountApprove ?? 0),
          xls.DoubleCellValue(t.amountReceived ?? 0),
        ]);
        r++;
      }
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 32);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
  }
}
