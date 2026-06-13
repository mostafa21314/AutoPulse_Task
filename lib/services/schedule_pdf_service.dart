import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/driving_profile.dart';
import '../models/service_record.dart';
import 'maintenance_model.dart';
import 'pdf_saver.dart';

/// Builds and presents the maintenance-schedule PDF deliverable.
///
/// The document has two parts, per the brief:
///   1. the modelling logic and how each variable was accounted for, and
///   2. the adjusted maintenance schedule for the next 80,000 km from today.
class SchedulePdfService {
  static const _accent = PdfColor.fromInt(0xFF00C4CC);

  /// Generates the PDF from the [record] + driving [profile] and opens the
  /// platform print/save dialog (a download on web).
  Future<void> generate({
    required ServiceRecord record,
    required DrivingProfile profile,
  }) async {
    final plan = MaintenanceModel.build(record, profile);

    // Unicode fonts with an Arabic fallback — the default PDF font (Helvetica)
    // cannot render Arabic glyphs (plate, customer name) and throws otherwise.
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
        fontFallback: [await PdfGoogleFonts.notoSansArabicRegular()],
      ),
    );
    final today = DateTime.now();
    final dateStr =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _header(record, plan, dateStr),
          pw.SizedBox(height: 20),
          ..._modellingSection(plan, profile),
          pw.SizedBox(height: 20),
          ..._scheduleSection(plan),
        ],
      ),
    );

    await savePdf(
      await doc.save(),
      'maintenance_schedule_${record.vehicle.makeModel.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _header(ServiceRecord record, MaintenancePlan plan, String date) {
    final v = record.vehicle;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Maintenance Schedule',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          v.makeModel.isEmpty ? 'Vehicle' : v.makeModel,
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Divider(color: _accent, thickness: 2),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 24,
          runSpacing: 4,
          children: [
            _kv('VIN', v.vin),
            _kv('Plate', v.plate),
            _kv('Current odometer', '${_fmt(plan.currentOdoKm)} km'),
            _kv('Generated', date),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _modellingSection(
      MaintenancePlan plan, DrivingProfile profile) {
    return [
        _sectionTitle('1. Modelling logic'),
        pw.SizedBox(height: 6),
        pw.Bullet(
          text: 'baseline_interval = manufacturer-recommended km per item.',
        ),
        pw.Bullet(
          text: 'Each driving choice contributes a per-component multiplier '
              '(see the factors column).',
        ),
        pw.Bullet(
          text: 'adjusted_interval = baseline x (product of factor multipliers), '
              'rounded to the nearest 500 km.',
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Driving profile',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _profileLine('Speed',
                  profile.overspeeding ? 'Overspeeding' : 'Normal speeds'),
              _profileLine('Environment',
                  profile.offRoad ? 'Off-road / rough terrain' : 'Urban'),
              _profileLine('Braking',
                  profile.suddenBraking ? 'Sudden / hard' : 'Smooth'),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 9,
          ),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellStyle: const pw.TextStyle(fontSize: 9),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.6),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.1),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
          },
          headers: const [
            'Item',
            'Baseline',
            'Factors applied',
            'Mult.',
            'Adjusted',
          ],
          data: [
            for (final s in plan.statuses)
              [
                s.component.name,
                '${_fmt(s.component.baselineKm)} km',
                s.factors.isEmpty
                    ? 'None (baseline)'
                    : s.factors.map((f) => f.reason).join('; '),
                s.multiplier.toStringAsFixed(2),
                '${_fmt(s.intervalKm)} km',
              ],
          ],
        ),
    ];
  }

  List<pw.Widget> _scheduleSection(MaintenancePlan plan) {
    return [
        _sectionTitle(
          '2. Adjusted schedule — next ${_fmt(plan.horizonKm)} km',
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Horizon: ${_fmt(plan.currentOdoKm)} km to ${_fmt(plan.currentOdoKm + plan.horizonKm)} km.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),

        // Per-component current standing.
        pw.Text('Current standing',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 9,
          ),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
          },
          headers: const [
            'Item',
            'Interval',
            'Last done',
            'Next due',
            'Status',
          ],
          data: [
            for (final s in plan.statuses)
              [
                s.component.name,
                '${_fmt(s.intervalKm)} km',
                '${_fmt(s.lastDoneKm)} km',
                '${_fmt(s.nextDueKm)} km',
                _statusLabel(s.status),
              ],
          ],
        ),
        pw.SizedBox(height: 16),

        // Projected timeline of occurrences within the horizon.
        pw.Text('Projected services',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 9,
          ),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
          },
          headers: const ['Due at', 'Item', 'Status'],
          data: [
            for (final s in plan.schedule)
              ['${_fmt(s.dueAtKm)} km', s.item, _statusLabel(s.status)],
          ],
        ),
    ];
  }

  pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
        ),
      );

  pw.Widget _profileLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );

  pw.Widget _kv(String label, String value) => pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: value.isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );

  String _statusLabel(ServiceStatus s) => switch (s) {
        ServiceStatus.overdue => 'OVERDUE',
        ServiceStatus.dueSoon => 'DUE SOON',
        ServiceStatus.scheduled => 'SCHEDULED',
      };

  /// Thousands separators: 196772 -> "196,772".
  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
