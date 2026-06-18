// Reusable vehicle-report export: data model + PDF/Excel generators + the
// chooser → generate → save → open/share flow. Shared by the fleet-wide
// Vehicle Report screen and the per-vehicle details screen so both produce an
// identical document (Overview, Revenue, Expense, Maintenance per vehicle).
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/core/utils/report_saver.dart';
import 'package:vego/core/widgets/trip_filter.dart' show tripSortKey;
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/services.dart';
import 'package:vego/domain/models/vehicles.dart';

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
enum ReportExportFormat { pdf, excel }

/// Per-vehicle figures + the period trips/services that drive the detail pages.
class VehicleStat {
  final Vehicles vehicle;
  final double revenue;
  final double tripExpense;
  final double maintenanceExpense;
  final int tripCount;
  final List<BookingInfo> trips;
  final List<Services> services;

  const VehicleStat({
    required this.vehicle,
    required this.revenue,
    required this.tripExpense,
    required this.maintenanceExpense,
    required this.tripCount,
    this.trips = const [],
    this.services = const [],
  });

  double get expense => tripExpense + maintenanceExpense;
  double get net => revenue - expense;
  double get toll => trips.fold<double>(0, (s, t) => s + (t.tollCharges ?? 0));
  double get repair =>
      trips.fold<double>(0, (s, t) => s + (t.repairingCharges ?? 0));
  double get driverCharges =>
      trips.fold<double>(0, (s, t) => s + (t.driverCharges ?? 0));
  double get fuelCharges =>
      trips.fold<double>(0, (s, t) => s + (t.fuelCharges ?? 0));
  bool get hasActivity =>
      tripCount > 0 || maintenanceExpense > 0 || services.isNotEmpty;
}

/// Everything a report document renders, computed once and shared by the UI and
/// the exporters so the file always matches what is on screen.
class ReportSnapshot {
  final String title; // e.g. "Vehicle Report" or "Tata Nexon Report"
  final String periodLabel; // e.g. "Month" / "Custom" / "Last 7 Days"
  final String dateRangeLabel; // e.g. "01 Jun 2026 - 30 Jun 2026"
  final List<VehicleStat> stats;
  final double totalRevenue;
  final double totalExpense;
  final int activeVehicles;
  final int totalVehicles;
  final int tripCount;

  const ReportSnapshot({
    required this.title,
    required this.periodLabel,
    required this.dateRangeLabel,
    required this.stats,
    required this.totalRevenue,
    required this.totalExpense,
    required this.activeVehicles,
    required this.totalVehicles,
    required this.tripCount,
  });

  double get net => totalRevenue - totalExpense;
}

// ── Formatting helpers ─────────────────────────────────────────────────────
final NumberFormat _moneyFmt = NumberFormat('#,##0', 'en_IN');
String _money(double v) =>
    '${v < 0 ? '-' : ''}Rs. ${_moneyFmt.format(v.abs())}';
String _fmtDate(DateTime? d) =>
    d == null ? '-' : DateFormat('dd MMM yyyy').format(d);
String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

String _statusName(Vehicles v) {
  if (v.StatusName != null && v.StatusName!.trim().isNotEmpty) {
    return v.StatusName!.trim();
  }
  switch (v.StatusId) {
    case 1:
      return 'Available';
    case 2:
      return 'Engaged';
    case 3:
      return 'Maintenance';
    default:
      return '-';
  }
}

String _fileBase(String title) {
  final cleaned = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? 'Report' : trimmed;
}

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC FLOW: chooser → generate → save → open/share
// ═══════════════════════════════════════════════════════════════════════════
Future<void> runVehicleReportExport(
  BuildContext context,
  ReportSnapshot snap,
) async {
  final fmt = await showModalBottomSheet<ReportExportFormat>(
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
    final isPdf = fmt == ReportExportFormat.pdf;
    final bytes =
        isPdf ? await VehicleReportPdf.build(snap) : await VehicleReportExcel.build(snap);
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
            format: ReportExportFormat.pdf,
            icon: Icons.picture_as_pdf_rounded,
            color: _Tok.red,
            bg: _Tok.redSoft,
            label: 'PDF Document',
            sub: 'Formatted, ready to print or share',
          ),
          const SizedBox(height: 10),
          _option(
            context,
            format: ReportExportFormat.excel,
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
    required ReportExportFormat format,
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
  final ReportExportFormat format;
  const _ExportReadySheet({required this.path, required this.format});

  @override
  Widget build(BuildContext context) {
    final isPdf = format == ReportExportFormat.pdf;
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
                  subject: 'Vehicle Report',
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
class VehicleReportPdf {
  static final _accent = PdfColor.fromHex('#3D5AFE');
  static final _dark = PdfColor.fromHex('#1A237E');
  static final _td = PdfColor.fromHex('#0F1729');
  static final _tg = PdfColor.fromHex('#6B7280');
  static final _dl = PdfColor.fromHex('#E6EAF2');
  static final _green = PdfColor.fromHex('#10B981');
  static final _orange = PdfColor.fromHex('#F59E0B');
  static final _red = PdfColor.fromHex('#EF4444');
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

  static pw.Widget _overview(Vehicles v) {
    final pairs = <List<String>>[
      ['Name', v.name ?? '-'],
      ['Number', v.number ?? '-'],
      ['Type', v.Type ?? '-'],
      ['Fuel Type', v.FuelType ?? '-'],
      ['Capacity', v.capacity != null ? '${v.capacity} seats' : '-'],
      [
        'Mileage',
        (v.mileage != null && v.mileage!.trim().isNotEmpty)
            ? '${v.mileage} km/l'
            : '-'
      ],
      ['Per Km Charge', v.perKmCharge != null ? _money(v.perKmCharge!) : '-'],
      ['Status', _statusName(v)],
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
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(2.6),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _accent),
          children: [
            _cell('#', _hStyle, a: pw.TextAlign.center),
            _cell('Date', _hStyle),
            _cell('Customer', _hStyle),
            _cell('Route', _hStyle),
            _cell('Status', _hStyle),
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
              _cell(t.customer_name ?? '-', _rStyle),
              _cell(route, _gStyle),
              _cell(t.tripStatus ?? '-', _gStyle),
              _cell(_money(t.amountReceived ?? 0), _rStyle,
                  a: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _expenseTable(VehicleStat s) {
    pw.TableRow row(String label, double value, {bool total = false}) =>
        pw.TableRow(
          decoration: total ? pw.BoxDecoration(color: _greenSoft) : null,
          children: [
            _cell(label, total ? _bStyle : _rStyle),
            _cell(_money(value), total ? _bStyle : _rStyle,
                a: pw.TextAlign.right),
          ],
        );
    return pw.Table(
      border: pw.TableBorder.all(color: _dl, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        row('Toll Charges', s.toll),
        row('Repairing Charges', s.repair),
        row('Driver Charges', s.driverCharges),
        row('Fuel Charges', s.fuelCharges),
        row('Maintenance', s.maintenanceExpense),
        row('Total Expense', s.expense, total: true),
      ],
    );
  }

  static pw.Widget _maintTable(List<Services> services) {
    return pw.Table(
      border: pw.TableBorder.all(color: _dl, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(2.6),
        4: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _orange),
          children: [
            _cell('#', _hStyle, a: pw.TextAlign.center),
            _cell('Date', _hStyle),
            _cell('Service', _hStyle),
            _cell('Notes', _hStyle),
            _cell('Cost', _hStyle, a: pw.TextAlign.right),
          ],
        ),
        ...services.asMap().entries.map((e) {
          final s = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key % 2 == 0 ? PdfColors.white : _bgP,
            ),
            children: [
              _cell('${e.key + 1}', _gStyle, a: pw.TextAlign.center),
              _cell(_fmtDate(s.serviceDate), _gStyle),
              _cell(s.serviceName ?? '-', _rStyle),
              _cell(s.description ?? '-', _gStyle),
              _cell(_money(s.serviceCost ?? 0), _rStyle, a: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _vehicleDetail(
    VehicleStat s,
    int index, {
    bool pageBreak = true,
  }) {
    final v = s.vehicle;
    final n = s.net;
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
              index > 0 ? '$index. ${v.name ?? 'Unknown'}' : (v.name ?? 'Unknown'),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              v.number ?? 'No plate',
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
          _kpi('Revenue', _money(s.revenue), _green),
          pw.SizedBox(width: 8),
          _kpi('Expense', _money(s.expense), _orange),
          pw.SizedBox(width: 8),
          _kpi(n >= 0 ? 'Net Profit' : 'Net Loss', _money(n.abs()),
              n >= 0 ? _green : _red),
          pw.SizedBox(width: 8),
          _kpi('Trips', '${s.tripCount}', _accent),
        ],
      ),
      pw.SizedBox(height: 14),
      _sectionBar('Overview'),
      pw.SizedBox(height: 6),
      _overview(v),
      pw.SizedBox(height: 14),
      _sectionBar('Revenue  -  Trips (${s.tripCount})'),
      pw.SizedBox(height: 6),
      s.trips.isEmpty ? _note('No trips in this period.') : _tripsTable(s.trips),
      pw.SizedBox(height: 14),
      _sectionBar('Expense Breakdown'),
      pw.SizedBox(height: 6),
      _expenseTable(s),
      pw.SizedBox(height: 14),
      _sectionBar('Maintenance (${s.services.length})'),
      pw.SizedBox(height: 6),
      s.services.isEmpty
          ? _note('No maintenance in this period.')
          : _maintTable(s.services),
    ];
  }

  static Future<List<int>> build(ReportSnapshot snap) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final net = snap.net;
    final detailed = snap.stats.where((s) => s.hasActivity).toList();
    // A single-vehicle report skips the redundant summary table and leads with
    // the detail; a fleet report keeps the summary then one detail page each.
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
              _kpi('Total Revenue', _money(snap.totalRevenue), _green),
              pw.SizedBox(width: 10),
              _kpi('Total Expense', _money(snap.totalExpense), _orange),
              pw.SizedBox(width: 10),
              _kpi(
                net >= 0 ? 'Net Profit' : 'Net Loss',
                _money(net.abs()),
                net >= 0 ? _green : _red,
              ),
              pw.SizedBox(width: 10),
              _kpi(
                isSingle ? 'Trips' : 'Active / Total',
                isSingle
                    ? '${snap.tripCount}'
                    : '${snap.activeVehicles} / ${snap.totalVehicles}',
                _accent,
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
            _sectionBar('Per Vehicle Summary'),
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
                    _cell('Vehicle', _hStyle),
                    _cell('Number', _hStyle),
                    _cell('Trips', _hStyle, a: pw.TextAlign.center),
                    _cell('Revenue', _hStyle, a: pw.TextAlign.right),
                    _cell('Expense', _hStyle, a: pw.TextAlign.right),
                    _cell('Net', _hStyle, a: pw.TextAlign.right),
                  ],
                ),
                ...snap.stats.asMap().entries.map((e) {
                  final s = e.value;
                  final vn = s.net;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: e.key % 2 == 0 ? PdfColors.white : _bgP,
                    ),
                    children: [
                      _cell('${e.key + 1}', _gStyle, a: pw.TextAlign.center),
                      _cell(s.vehicle.name ?? 'Unknown', _rStyle),
                      _cell(s.vehicle.number ?? '-', _gStyle),
                      _cell('${s.tripCount}', _gStyle, a: pw.TextAlign.center),
                      _cell(_money(s.revenue), _rStyle, a: pw.TextAlign.right),
                      _cell(_money(s.expense), _gStyle, a: pw.TextAlign.right),
                      _cell(
                        _money(vn),
                        pw.TextStyle(
                          color: vn >= 0 ? _green : _red,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        a: pw.TextAlign.right,
                      ),
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
                      _money(snap.totalRevenue),
                      pw.TextStyle(
                        color: _green,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      a: pw.TextAlign.right,
                    ),
                    _cell(_money(snap.totalExpense), _bStyle,
                        a: pw.TextAlign.right),
                    _cell(
                      _money(net),
                      pw.TextStyle(
                        color: net >= 0 ? _green : _red,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      a: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          ],
          // Per-vehicle detail. For a single vehicle the first detail flows on
          // the cover page (no page break); a fleet starts each on a new page.
          if (isSingle && detailed.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            ..._vehicleDetail(detailed.first, 0, pageBreak: false),
          ] else
            for (var i = 0; i < detailed.length; i++)
              ..._vehicleDetail(detailed[i], i + 1),
        ],
      ),
    );

    return pdf.save();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXCEL GENERATOR
// ═══════════════════════════════════════════════════════════════════════════
class VehicleReportExcel {
  static final _headerStyle = xls.CellStyle(
    bold: true,
    fontColorHex: xls.ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: xls.ExcelColor.fromHexString('#3D5AFE'),
    horizontalAlign: xls.HorizontalAlign.Center,
  );
  static final _maintHeaderStyle = xls.CellStyle(
    bold: true,
    fontColorHex: xls.ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: xls.ExcelColor.fromHexString('#F59E0B'),
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

  static String _sheetName(VehicleStat s, int idx, Set<String> used) {
    var base = (s.vehicle.number?.trim().isNotEmpty ?? false)
        ? s.vehicle.number!.trim()
        : (s.vehicle.name?.trim().isNotEmpty ?? false
            ? s.vehicle.name!.trim()
            : 'Vehicle $idx');
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

  static Future<List<int>> build(ReportSnapshot snap) async {
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

    summaryNum('Total Revenue', snap.totalRevenue);
    summaryNum('Total Expense', snap.totalExpense);
    summaryNum(snap.net >= 0 ? 'Net Profit' : 'Net Loss', snap.net);
    meta('Active / Total Vehicles',
        '${snap.activeVehicles} / ${snap.totalVehicles}');
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
      'Vehicle',
      'Number',
      'Trips',
      'Revenue',
      'Expense',
      'Maintenance',
      'Net',
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
        xls.TextCellValue(s.vehicle.name ?? 'Unknown'),
        xls.TextCellValue(s.vehicle.number ?? '-'),
        xls.IntCellValue(s.tripCount),
        xls.DoubleCellValue(s.revenue),
        xls.DoubleCellValue(s.tripExpense),
        xls.DoubleCellValue(s.maintenanceExpense),
        xls.DoubleCellValue(s.net),
      ]);
      r++;
    }
    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue('TOTAL'),
      xls.TextCellValue(''),
      xls.IntCellValue(snap.tripCount),
      xls.DoubleCellValue(snap.totalRevenue),
      xls.DoubleCellValue(
        snap.stats.fold<double>(0, (a, s) => a + s.tripExpense),
      ),
      xls.DoubleCellValue(
        snap.stats.fold<double>(0, (a, s) => a + s.maintenanceExpense),
      ),
      xls.DoubleCellValue(snap.net),
    ]);
    for (var c = 0; c < headers.length; c++) {
      _style(sheet, c, r, _totalStyle);
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 8);
    for (var c = 4; c <= 7; c++) {
      sheet.setColumnWidth(c, 14);
    }

    final used = <String>{summaryName};
    final detailed = snap.stats.where((s) => s.hasActivity).toList();
    for (var i = 0; i < detailed.length; i++) {
      _buildVehicleSheet(excel, detailed[i], i + 1, used);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel workbook');
    }
    return bytes;
  }

  static void _buildVehicleSheet(
    xls.Excel excel,
    VehicleStat stat,
    int idx,
    Set<String> used,
  ) {
    final v = stat.vehicle;
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
      xls.TextCellValue('${v.name ?? 'Unknown'}  (${v.number ?? '-'})'),
    ]);
    _style(sheet, 0, r, _titleStyle);
    r++;
    blank();

    section('Overview');
    kv('Type', xls.TextCellValue(v.Type ?? '-'));
    kv('Fuel Type', xls.TextCellValue(v.FuelType ?? '-'));
    kv('Capacity',
        xls.TextCellValue(v.capacity != null ? '${v.capacity} seats' : '-'));
    kv(
      'Mileage',
      xls.TextCellValue(
        (v.mileage != null && v.mileage!.trim().isNotEmpty)
            ? '${v.mileage} km/l'
            : '-',
      ),
    );
    kv(
      'Per Km Charge',
      v.perKmCharge != null
          ? xls.DoubleCellValue(v.perKmCharge!)
          : xls.TextCellValue('-'),
    );
    kv('Status', xls.TextCellValue(_statusName(v)));
    blank();

    section('Profit & Loss');
    kv('Revenue', xls.DoubleCellValue(stat.revenue));
    kv('Expense', xls.DoubleCellValue(stat.expense));
    kv(stat.net >= 0 ? 'Net Profit' : 'Net Loss',
        xls.DoubleCellValue(stat.net));
    kv('Trips', xls.IntCellValue(stat.tripCount));
    blank();

    section('Revenue - Trips (${stat.tripCount})');
    const tHeaders = ['#', 'Date', 'Customer', 'Route', 'Status', 'Received'];
    sheet.appendRow(tHeaders.map((h) => xls.TextCellValue(h)).toList());
    for (var c = 0; c < tHeaders.length; c++) {
      _style(sheet, c, r, _headerStyle);
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
          xls.TextCellValue(t.customer_name ?? '-'),
          xls.TextCellValue(
              '${t.pickupLocation ?? '-'} -> ${t.dropLocation ?? '-'}'),
          xls.TextCellValue(t.tripStatus ?? '-'),
          xls.DoubleCellValue(t.amountReceived ?? 0),
        ]);
        r++;
      }
    }
    blank();

    section('Expense Breakdown');
    kv('Toll Charges', xls.DoubleCellValue(stat.toll));
    kv('Repairing Charges', xls.DoubleCellValue(stat.repair));
    kv('Driver Charges', xls.DoubleCellValue(stat.driverCharges));
    kv('Fuel Charges', xls.DoubleCellValue(stat.fuelCharges));
    kv('Maintenance', xls.DoubleCellValue(stat.maintenanceExpense));
    sheet.appendRow([
      xls.TextCellValue('Total Expense'),
      xls.DoubleCellValue(stat.expense),
    ]);
    _style(sheet, 0, r, _totalStyle);
    _style(sheet, 1, r, _totalStyle);
    r++;
    blank();

    section('Maintenance (${stat.services.length})');
    const mHeaders = ['#', 'Date', 'Service', 'Notes', 'Cost'];
    sheet.appendRow(mHeaders.map((h) => xls.TextCellValue(h)).toList());
    for (var c = 0; c < mHeaders.length; c++) {
      _style(sheet, c, r, _maintHeaderStyle);
    }
    r++;
    if (stat.services.isEmpty) {
      sheet.appendRow([xls.TextCellValue('No maintenance in this period.')]);
      r++;
    } else {
      for (var i = 0; i < stat.services.length; i++) {
        final s = stat.services[i];
        sheet.appendRow([
          xls.IntCellValue(i + 1),
          xls.TextCellValue(_fmtDate(s.serviceDate)),
          xls.TextCellValue(s.serviceName ?? '-'),
          xls.TextCellValue(s.description ?? '-'),
          xls.DoubleCellValue(s.serviceCost ?? 0),
        ]);
        r++;
      }
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 30);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 14);
  }
}
