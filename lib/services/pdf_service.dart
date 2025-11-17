import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:iot/widget.dart';

class PdfService {
  static Future<void> generateAndSharePdf(
    Map<String, dynamic>? firebaseData,
    String userEmail,
  ) async {
    final pdf = pw.Document();
    final metrics = metricsFromFirebase(firebaseData);
    final now = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 50),
        build: (pw.Context context) {
          return [
            _buildHeader(now, userEmail),
            pw.SizedBox(height: 25),
            _buildMetricsGrid(metrics),
            _buildFooter(now),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<File> generatePdfFile(
    Map<String, dynamic>? firebaseData,
    String userEmail,
    Directory directory,
  ) async {
    final pdf = pw.Document();
    final metrics = metricsFromFirebase(firebaseData);
    final now = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 50),
        build: (pw.Context context) {
          return [
            _buildHeader(now, userEmail),
            pw.SizedBox(height: 25),
            _buildMetricsGrid(metrics),
            _buildFooter(now),
          ];
        },
      ),
    );

    final fileName = 'IoT_Dashboard_${now.millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(DateTime now, String userEmail) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HEALTH METRICS REPORT',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'USER ID',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  userEmail.split('@')[0].toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Report Date',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _formatDate(now),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.black, thickness: 0.5),
      ],
    );
  }

  static pw.Widget _buildMetricsGrid(List<MetricBlock> metrics) {
    final displayMetrics = metrics.where((m) => !m.fullWidth).toList();
    
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _buildTableCell('PARAMETER', isHeader: true),
            _buildTableCell('VALUE', isHeader: true),
            _buildTableCell('UNIT', isHeader: true),
          ],
        ),
        ...displayMetrics.map((metric) {
          return pw.TableRow(
            children: [
              _buildTableCell(metric.name),
              _buildTableCell(metric.value, isValue: true),
              _buildTableCell(metric.unit),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isValue = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : (isValue ? 12 : 10),
          fontWeight: isHeader || isValue
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime now) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Divider(color: PdfColors.black, thickness: 0.5),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Generated: ${_formatDateTime(now)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Text(
              'Page 1 of 1',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

