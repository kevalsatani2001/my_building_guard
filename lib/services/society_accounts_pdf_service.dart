import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/society_expense_model.dart';
import '../services/society_accounts_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

class SocietyAccountsPdfService {
  /// Render Gujarati text to high-res image for vector PDF inclusion
  static Future<pw.MemoryImage> _renderShapedText({
    required String text,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
  }) async {
    final cleanText = text.trim().isEmpty ? ' ' : text.trim();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: cleanText,
        style: TextStyle(
          fontSize: fontSize * 3.0,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final width = (textPainter.width + 8).ceil().clamp(1, 4000);
    final height = (textPainter.height + 4).ceil().clamp(1, 2000);
    final img = await picture.toImage(width, height);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(pngBytes!.buffer.asUint8List());
  }

  static bool _hasGujarati(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0A80 && rune <= 0x0AFF) return true;
    }
    return false;
  }

  /// Generate high quality multi-page PDF statement for Society Accounts
  static Future<Uint8List> generateStatementPdf({
    required SocietyFinancialSummary summary,
    required List<SocietyExpense> expenses,
    String? societyName,
    String? societyCode,
  }) async {
    final pdf = pw.Document();
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final effectiveSocName = (societyName != null && societyName.isNotEmpty)
        ? societyName
        : SocietyService.instance.currentSocietyName;
    final effectiveSocCode = (societyCode != null && societyCode.isNotEmpty)
        ? societyCode
        : SocietyService.instance.currentSocietyId;

    // Pre-render Gujarati headers
    final socNameImg = await _renderShapedText(
      text: effectiveSocName,
      fontSize: 16,
      color: const Color(0xFF0F766E),
      fontWeight: FontWeight.w900,
    );

    final titleImg = await _renderShapedText(
      text: 'સોસાયટી નાણાકીય હિસાબ & ઓડિટ સ્ટેટમેન્ટ (Financial Accounts Statement)',
      fontSize: 11,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
    );

    final savingsTitleImg = await _renderShapedText(
      text: 'કુલ ચોખ્ખી બચત / તિજોરી ફંડ (Net Treasury Savings):',
      fontSize: 11,
      color: const Color(0xFF065F46),
      fontWeight: FontWeight.bold,
    );

    // Build Table Rows for Expenses
    final List<pw.TableRow> expenseRows = [];
    expenseRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
        children: [
          _buildHeaderCell('તારીખ (Date)'),
          _buildHeaderCell('ખર્ચ વિગત (Particulars)'),
          _buildHeaderCell('કેટેગરી (Category)'),
          _buildHeaderCell('કોને ચૂકવ્યા (Payee)'),
          _buildHeaderCell('મોડ (Mode)'),
          _buildHeaderCell('રકમ (Amount)', alignRight: true),
        ],
      ),
    );

    for (int i = 0; i < expenses.length; i++) {
      final exp = expenses[i];
      final isEven = i % 2 == 0;
      final rowColor = isEven ? PdfColors.white : const PdfColor(0.96, 0.98, 0.99);

      final expTitleImg = _hasGujarati(exp.title)
          ? pw.Image(
              await _renderShapedText(
                text: exp.title,
                fontSize: 8.5,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              height: 12,
              fit: pw.BoxFit.contain,
            )
          : pw.Text(exp.title, style: const pw.TextStyle(fontSize: 8.5));

      final catImg = pw.Image(
        await _renderShapedText(
          text: exp.category.titleGujarati,
          fontSize: 8,
          color: const Color(0xFF334155),
        ),
        height: 11,
        fit: pw.BoxFit.contain,
      );

      final payeeImg = _hasGujarati(exp.paidTo)
          ? pw.Image(
              await _renderShapedText(
                text: exp.paidTo.isNotEmpty ? exp.paidTo : '-',
                fontSize: 8,
                color: const Color(0xFF475569),
              ),
              height: 11,
              fit: pw.BoxFit.contain,
            )
          : pw.Text(exp.paidTo.isNotEmpty ? exp.paidTo : '-', style: const pw.TextStyle(fontSize: 8));

      expenseRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            _buildDataCell(dateFmt.format(exp.expenseDate)),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: expTitleImg,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: catImg,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: payeeImg,
            ),
            _buildDataCell(exp.paymentModeLabel.split(' ')[0]),
            _buildDataCell(currencyFmt.format(exp.amount), alignRight: true, isBold: true),
          ],
        ),
      );
    }

    // Category Summary Rows
    final List<pw.TableRow> categorySummaryRows = [];
    categorySummaryRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E293B)),
        children: [
          _buildHeaderCell('ખર્ચ કેટેગરી (Expense Category)'),
          _buildHeaderCell('કુલ રકમ (Total Spent)', alignRight: true),
          _buildHeaderCell('હિસ્સો (% Share)', alignRight: true),
        ],
      ),
    );

    final sortedCategories = summary.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final cat = SocietyExpenseCategory.fromKey(entry.key);
      final percent = summary.totalExpenses > 0
          ? ((entry.value / summary.totalExpenses) * 100).toStringAsFixed(1)
          : '0.0';

      final catLabelImg = pw.Image(
        await _renderShapedText(
          text: '${cat.titleGujarati} (${cat.titleEnglish})',
          fontSize: 8.5,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        height: 12,
        fit: pw.BoxFit.contain,
      );

      categorySummaryRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: catLabelImg,
            ),
            _buildDataCell(currencyFmt.format(entry.value), alignRight: true, isBold: true),
            _buildDataCell('$percent %', alignRight: true),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 32,
                      height: 32,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF0F766E),
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'BG',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Image(socNameImg, height: 18, fit: pw.BoxFit.contain),
                        pw.Text(
                          'Society Code: $effectiveSocCode | Smart Guard ERP Ledger',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT DATE: ${dateFmt.format(now)}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'STATUS: AUDITED & VERIFIED',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF047857)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF0F766E)),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'My Building Guard • Digital Society Financial Governance System',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.Center(
            child: pw.Image(titleImg, height: 14, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 12),

          // 1. FINANCIAL SUMMARY HIGHLIGHT CARDS
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.97, 0.99, 0.98),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFA7F3D0), width: 1),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryMetricBox(
                      title: 'કુલ જમા આવક (Total Income)',
                      amount: currencyFmt.format(summary.totalIncome),
                      subtitle: 'મેન્ટેનન્સ + તહેવાર ફાળો (${summary.paidBillsCount} બિલો ચૂકવાયેલ)',
                      color: const PdfColor.fromInt(0xFF0F766E),
                    ),
                    _buildSummaryMetricBox(
                      title: 'કુલ થયેલ ખર્ચ (Total Expenses)',
                      amount: currencyFmt.format(summary.totalExpenses),
                      subtitle: '${expenses.length} ખર્ચાઓ ચૂકવાયેલ (વોચમેન, સફાઈ, લાઈટ વગેરે)',
                      color: const PdfColor.fromInt(0xFFDC2626),
                    ),
                    _buildSummaryMetricBox(
                      title: 'આ માસનો ખર્ચ (This Month)',
                      amount: currencyFmt.format(summary.thisMonthExpense),
                      subtitle: 'ચાલુ મહિના દરમિયાન થયેલ ખર્ચ',
                      color: const PdfColor.fromInt(0xFF4338CA),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: const PdfColor.fromInt(0xFFA7F3D0), thickness: 0.8),
                pw.SizedBox(height: 6),
                // NET TREASURY BALANCE ROW
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(savingsTitleImg, height: 15, fit: pw.BoxFit.contain),
                    pw.Text(
                      currencyFmt.format(summary.currentSavings),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: summary.currentSavings >= 0
                            ? const PdfColor.fromInt(0xFF047857)
                            : const PdfColor.fromInt(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // 2. CATEGORY BREAKDOWN TABLE
          pw.Text(
            'EXPENSE DISTRIBUTION BY CATEGORY (કેટેગરી મુજબ ખર્ચ વિગત):',
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: const PdfColor(0.85, 0.9, 0.92), width: 0.5),
            children: categorySummaryRows,
          ),
          pw.SizedBox(height: 18),

          // 3. DETAILED EXPENSE LEDGER TABLE
          pw.Text(
            'DETAILED EXPENSE LEDGER (તમામ થયેલ ખર્ચાઓની વિગતવાર યાદી):',
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: const PdfColor(0.85, 0.9, 0.92), width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(65),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FixedColumnWidth(55),
              5: pw.FixedColumnWidth(75),
            },
            children: expenseRows,
          ),
          pw.SizedBox(height: 24),

          // 4. OFFICIAL DIGITAL SIGNATURE AND AUDIT CLAUSE
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: const PdfColor(0.85, 0.9, 0.92)),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AUDIT DECLARATION / ઓડિટ પ્રમાણપત્ર:',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'આ નાણાકીય હિસાબ સોસાયટી રજીસ્ટર મુજબ સાચો અને ચકાસેલ છે.\nતમામ સભ્યો આ હિસાબ My Building Guard એપ્લિકેશન પર પારદર્શક રીતે જોઈ શકે છે.',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 100,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.8)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'સોસાયટી પ્રમુખ / ખજાનચી',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Authorized Signatory',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, {bool alignRight = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: const PdfColor(0.1, 0.15, 0.2),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryMetricBox({
    required String title,
    required String amount,
    required String subtitle,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 155,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            amount,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}

class SocietyAccountsPdfPreviewScreen extends StatelessWidget {
  final SocietyFinancialSummary summary;
  final List<SocietyExpense> expenses;
  final String? societyName;
  final String? societyCode;

  const SocietyAccountsPdfPreviewScreen({
    super.key,
    required this.summary,
    required this.expenses,
    this.societyName,
    this.societyCode,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final safeFileName = 'Society_Accounts_Statement_$dateStr.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PremiumAppBar(
        title: 'સોસાયટી હિસાબ અહેવાલ (PDF)',
        subtitle: 'Official Accounts & Audit Statement',
        actions: [
          PremiumAppBarAction(
            icon: Icons.print_rounded,
            tooltip: 'પ્રિન્ટ કરો',
            color: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFCCFBF1),
            onTap: () async {
              final pdfBytes = await SocietyAccountsPdfService.generateStatementPdf(
                summary: summary,
                expenses: expenses,
                societyName: societyName,
                societyCode: societyCode,
              );
              await Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        build: (format) => SocietyAccountsPdfService.generateStatementPdf(
          summary: summary,
          expenses: expenses,
          societyName: societyName,
          societyCode: societyCode,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: safeFileName,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F766E)),
              SizedBox(height: 12),
              Text(
                'સોસાયટી હિસાબ સ્ટેટમેન્ટ તૈયાર થઈ રહ્યું છે...',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
