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
  static final Map<String, pw.MemoryImage> _textCache = {};
  static final Map<String, Size> _textSizeCache = {};

  /// Render Gujarati/Indic text using Flutter's native HarfBuzz shaping engine into a 300 DPI image
  static Future<pw.MemoryImage> _renderShapedText({
    required String text,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
    double? maxWidth,
  }) async {
    final cleanText = text.trim().isEmpty ? ' ' : text.trim();
    final cacheKey =
        '$cleanText|$fontSize|${color.toARGB32()}|${fontWeight.value}|$textAlign|${maxWidth?.toInt() ?? 0}';
    if (_textCache.containsKey(cacheKey)) {
      return _textCache[cacheKey]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: cleanText,
        style: TextStyle(
          fontSize: fontSize * 3.0, // 3x scale for ultra-sharp 300 DPI
          color: color,
          fontWeight: fontWeight,
          height: 1.25,
        ),
      ),
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
    );

    if (maxWidth != null && maxWidth > 0) {
      textPainter.layout(maxWidth: maxWidth * 3.0);
    } else {
      textPainter.layout();
    }

    textPainter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final width = textPainter.width.ceil().clamp(1, 4000);
    final height = textPainter.height.ceil().clamp(1, 2000);
    final img = await picture.toImage(width, height);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final memImg = pw.MemoryImage(pngBytes!.buffer.asUint8List());
    _textCache[cacheKey] = memImg;
    _textSizeCache[cacheKey] = Size(textPainter.width / 3.0, textPainter.height / 3.0);
    return memImg;
  }

  static bool _hasNonLatin(String text) {
    for (final rune in text.runes) {
      if (rune > 0x007F) return true;
    }
    return false;
  }

  /// Safe text widget: renders via Canvas image if containing non-Latin / Gujarati glyphs.
  /// Enforces true natural dimensions so multi-line text never squishes.
  static Future<pw.Widget> _buildSafeText({
    required String text,
    required double fontSize,
    required PdfColor fallbackColor,
    required Color renderColor,
    pw.FontWeight pwWeight = pw.FontWeight.normal,
    FontWeight uiWeight = FontWeight.normal,
    pw.TextAlign pwAlign = pw.TextAlign.left,
    TextAlign uiAlign = TextAlign.left,
    double? maxWidth,
    double? height,
    pw.Font? font,
  }) async {
    final clean = text.trim().isEmpty ? '-' : text.trim();

    if (_hasNonLatin(clean)) {
      final img = await _renderShapedText(
        text: clean,
        fontSize: fontSize,
        color: renderColor,
        fontWeight: uiWeight,
        textAlign: uiAlign,
        maxWidth: maxWidth,
      );
      final cacheKey =
          '$clean|$fontSize|${renderColor.toARGB32()}|${uiWeight.value}|$uiAlign|${maxWidth?.toInt() ?? 0}';
      final naturalSize = _textSizeCache[cacheKey] ?? Size(fontSize * 5, fontSize * 1.3);

      final effHeight = height ?? naturalSize.height;
      final effWidth = height != null
          ? (naturalSize.width * (height / naturalSize.height))
          : naturalSize.width;

      return pw.Image(
        img,
        width: effWidth,
        height: effHeight,
        fit: pw.BoxFit.contain,
      );
    } else {
      return pw.Text(
        clean,
        textAlign: pwAlign,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pwWeight,
          color: fallbackColor,
          font: font,
        ),
      );
    }
  }

  /// Helper to get clean ASCII payment mode string (never outputs Gujarati / non-Latin)
  static String _cleanPaymentMode(String rawMode) {
    final m = rawMode.toLowerCase().trim();
    if (m.contains('cash') || m.contains('રોકડ')) return 'CASH';
    if (m.contains('upi') || m.contains('qr')) return 'UPI';
    if (m.contains('cheque') || m.contains('ચેક')) return 'CHEQUE';
    if (m.contains('bank') ||
        m.contains('neft') ||
        m.contains('imps') ||
        m.contains('transfer') ||
        m.contains('ઓનલાઇન') ||
        m.contains('online')) {
      return 'ONLINE';
    }
    if (_hasNonLatin(rawMode)) {
      return 'RECORDED';
    }
    return rawMode.trim().toUpperCase();
  }

  /// Renders a photorealistic official digital rubber stamp for the Statement
  static Future<pw.MemoryImage> _renderStatementStamp({
    required String dateStr,
    required String societyName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const scale = 3.0;
    const width = 210.0 * scale;
    const height = 100.0 * scale;

    const primaryColor = Color(0xFF047857);
    const lightBgColor = Color(0x12047857);

    final rect = Rect.fromLTWH(5 * scale, 5 * scale, (210.0 - 10) * scale, (100.0 - 10) * scale);
    final rrectOuter = RRect.fromRectAndRadius(rect, Radius.circular(10 * scale));
    final rrectInner = RRect.fromRectAndRadius(rect.deflate(3.5 * scale), Radius.circular(7 * scale));

    // Background ink wash
    final bgPaint = Paint()
      ..color = lightBgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrectOuter, bgPaint);

    // Outer & Inner Borders
    final outerBorder = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;
    canvas.drawRRect(rrectOuter, outerBorder);

    final innerBorder = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(rrectInner, innerBorder);

    // Text elements
    final headerPainter = TextPainter(
      text: TextSpan(
        text: '★ OFFICIAL AUDIT VERIFIED ★',
        style: TextStyle(
          fontSize: 7.0 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 1.0 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 14 * scale);
    headerPainter.paint(canvas, Offset(rect.center.dx - headerPainter.width / 2, rect.top + 6 * scale));

    canvas.drawLine(
      Offset(rect.left + 10 * scale, rect.top + 18 * scale),
      Offset(rect.right - 10 * scale, rect.top + 18 * scale),
      innerBorder,
    );

    // Main Stamp Text: AUDITED
    final mainPainter = TextPainter(
      text: TextSpan(
        text: 'AUDITED',
        style: TextStyle(
          fontSize: 22.0 * scale,
          fontWeight: FontWeight.w900,
          color: primaryColor,
          letterSpacing: 2.5 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    mainPainter.paint(canvas, Offset(rect.center.dx - mainPainter.width / 2, rect.top + 21 * scale));

    canvas.drawLine(
      Offset(rect.left + 10 * scale, rect.top + 55 * scale),
      Offset(rect.right - 10 * scale, rect.top + 55 * scale),
      innerBorder,
    );

    // Gujarati: સત્તાવાર ઓડિટ હિસાબ
    final gujPainter = TextPainter(
      text: TextSpan(
        text: 'સત્તાવાર ઓડિટ હિસાબ',
        style: TextStyle(
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    gujPainter.paint(canvas, Offset(rect.center.dx - gujPainter.width / 2, rect.top + 58 * scale));

    // Date
    final datePainter = TextPainter(
      text: TextSpan(
        text: 'DATE: $dateStr',
        style: TextStyle(
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    datePainter.paint(canvas, Offset(rect.center.dx - datePainter.width / 2, rect.top + 74 * scale));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(pngBytes!.buffer.asUint8List());
  }

  /// Generate high quality multi-page PDF statement for Society Accounts
  static Future<Uint8List> generateStatementPdf({
    required SocietyFinancialSummary summary,
    required List<SocietyExpense> expenses,
    String? societyName,
    String? societyCode,
  }) async {
    final pdf = pw.Document();

    // Load Latin fonts
    pw.Font latinRegular;
    pw.Font latinBold;
    try {
      latinRegular = await PdfGoogleFonts.notoSansRegular().timeout(const Duration(seconds: 2));
      latinBold = await PdfGoogleFonts.notoSansBold().timeout(const Duration(seconds: 2));
    } catch (_) {
      latinRegular = pw.Font.helvetica();
      latinBold = pw.Font.helveticaBold();
    }

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();

    final effectiveSocName = (societyName != null && societyName.isNotEmpty)
        ? societyName
        : SocietyService.instance.currentSocietyName;
    final effectiveSocCode = (societyCode != null && societyCode.isNotEmpty)
        ? societyCode
        : SocietyService.instance.currentSocietyId;
    final safeSocCode = effectiveSocCode.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    final displaySocCode = safeSocCode.isNotEmpty ? safeSocCode : 'SOC-ERP';

    final dateStr = dateFmt.format(now);
    final stampImage = await _renderStatementStamp(dateStr: dateStr, societyName: effectiveSocName);

    // Pre-render Gujarati headers & titles cleanly
    final socNameImg = await _renderShapedText(
      text: effectiveSocName,
      fontSize: 14,
      color: const Color(0xFF0F766E),
      fontWeight: FontWeight.w900,
      maxWidth: 280,
    );

    final titleGujImg = await _renderShapedText(
      text: 'સોસાયટી નાણાકીય ખાતાવહી & પાસબુક અહેવાલ (Financial Statement & Ledger)',
      fontSize: 10,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.w800,
      maxWidth: 440,
    );

    final periodStr = summary.ledgerEntries.isNotEmpty
        ? 'Period: ${dateFmt.format(summary.ledgerEntries.first.date)} to ${dateFmt.format(now)}'
        : 'Statement as on: $dateStr';

    // Pre-render section labels & headers
    final openingBalanceLabelImg = await _renderShapedText(
      text: 'શરૂઆતની સિલક',
      fontSize: 7.2,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
    );

    final closingBalanceLabelImg = await _renderShapedText(
      text: 'વર્તમાન આખર સિલક',
      fontSize: 7.5,
      color: const Color(0xFF065F46),
      fontWeight: FontWeight.bold,
    );

    final passbookSectionTitleImg = await _renderShapedText(
      text: 'તારીખવાર ખાતાવહી & ચાલુ સિલક',
      fontSize: 8,
      color: const Color(0xFF0F766E),
      fontWeight: FontWeight.bold,
    );

    final catSectionTitleImg = await _renderShapedText(
      text: 'ખર્ચ મુજબ વિભાજન',
      fontSize: 8,
      color: const Color(0xFF0F766E),
      fontWeight: FontWeight.bold,
    );

    final kpiInflowGujImg = await _renderShapedText(
      text: '(કુલ આવક)',
      fontSize: 6.8,
      color: const Color(0xFF047857),
      fontWeight: FontWeight.bold,
    );

    final kpiOutflowGujImg = await _renderShapedText(
      text: '(કુલ ખર્ચ)',
      fontSize: 6.8,
      color: const Color(0xFFDC2626),
      fontWeight: FontWeight.bold,
    );

    final kpiSavingsGujImg = await _renderShapedText(
      text: '(વર્તમાન આખર સિલક)',
      fontSize: 6.8,
      color: const Color(0xFF065F46),
      fontWeight: FontWeight.bold,
    );

    final kpiSavingsSubGujImg = await _renderShapedText(
      text: summary.currentSavings >= 0 ? '(બચત અનામત)' : '(ખોટ સિલક)',
      fontSize: 6.0,
      color: summary.currentSavings >= 0 ? const Color(0xFF047857) : const Color(0xFFDC2626),
      fontWeight: FontWeight.w600,
    );

    final presSignImg = await _renderShapedText(
      text: 'સોસાયટી પ્રમુખ / ચેરમેન',
      fontSize: 7.5,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
    );

    final tresSignImg = await _renderShapedText(
      text: 'સોસાયટી સેક્રેટરી / ખજાનચી',
      fontSize: 7.5,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
    );

    // Table Header widgets with clean English text + Shaped Gujarati sub-labels
    final dateHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DATE', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'તારીખ', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final particularsHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('TRANSACTION PARTICULARS', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'ખાતાવહી વિગત / ફ્લેટ / કોને ચૂકવ્યા', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final categoryHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CATEGORY', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'પ્રકાર / હેતુ', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final modeHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('MODE', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'મોડ', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final creditHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('CREDIT (+)', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'જમા આવક', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final debitHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('DEBIT (-)', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'ઉધાર ખર્ચ', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    final balanceHeaderWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('BALANCE', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
        pw.Image(await _renderShapedText(text: 'ચાલુ સિલક (Rs.)', fontSize: 6, color: Colors.white70), height: 8),
      ],
    );

    // BUILD CHRONOLOGICAL DATE-WISE LEDGER TABLE ROWS
    final List<pw.TableRow> ledgerRows = [];
    ledgerRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: dateHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: particularsHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: categoryHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5), child: modeHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: creditHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: debitHeaderWidget),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5), child: balanceHeaderWidget),
        ],
      ),
    );

    // Initial Opening Balance Row
    ledgerRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor(0.95, 0.96, 0.98)),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text('START', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, font: latinBold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('OPENING BALANCE (', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, font: latinBold)),
                    pw.Image(openingBalanceLabelImg, height: 9),
                    pw.Text(')', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, font: latinBold)),
                  ],
                ),
                pw.Text('Beginning of recorded statement ledger', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text('Treasury', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: pw.Text('-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text('-', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text('-', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text('Rs. 0', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
          ),
        ],
      ),
    );

    // Transaction rows
    for (int i = 0; i < summary.ledgerEntries.length; i++) {
      final item = summary.ledgerEntries[i];
      final isEven = i % 2 == 0;
      final rowColor = isEven ? PdfColors.white : const PdfColor(0.98, 0.99, 1.0);

      // Clean ASCII payment mode (CASH, ONLINE, UPI, CHEQUE)
      final cleanMode = _cleanPaymentMode(item.paymentMode);

      PdfColor modeBgColor;
      PdfColor modeTextColor;
      switch (cleanMode) {
        case 'CASH':
          modeBgColor = const PdfColor(0.99, 0.95, 0.82);
          modeTextColor = const PdfColor.fromInt(0xFF92400E);
          break;
        case 'UPI':
          modeBgColor = const PdfColor(0.95, 0.91, 0.99);
          modeTextColor = const PdfColor.fromInt(0xFF6B21A8);
          break;
        case 'CHEQUE':
          modeBgColor = const PdfColor(0.93, 0.95, 1.0);
          modeTextColor = const PdfColor.fromInt(0xFF3730A3);
          break;
        case 'ONLINE':
        default:
          modeBgColor = const PdfColor(0.88, 0.95, 0.99);
          modeTextColor = const PdfColor.fromInt(0xFF0369A1);
          break;
      }

      // Title & Subtitle with natural proportional heights so 2-line entries never squish
      final titleWidget = await _buildSafeText(
        text: item.title,
        fontSize: 7.5,
        fallbackColor: const PdfColor.fromInt(0xFF0F172A),
        renderColor: const Color(0xFF0F172A),
        pwWeight: pw.FontWeight.bold,
        uiWeight: FontWeight.w700,
        maxWidth: 175,
        font: latinBold,
      );

      final subWidget = await _buildSafeText(
        text: item.subtitle,
        fontSize: 6.5,
        fallbackColor: const PdfColor.fromInt(0xFF64748B),
        renderColor: const Color(0xFF64748B),
        maxWidth: 175,
        font: latinRegular,
      );

      final catWidget = await _buildSafeText(
        text: item.categoryLabel,
        fontSize: 7,
        fallbackColor: const PdfColor.fromInt(0xFF334155),
        renderColor: const Color(0xFF334155),
        maxWidth: 87,
        font: latinRegular,
      );

      final isPositiveBalance = item.runningBalance >= 0;

      ledgerRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            // Date
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Text(
                dateFmt.format(item.date),
                style: pw.TextStyle(fontSize: 7.2, font: latinRegular, color: PdfColors.grey900),
              ),
            ),
            // Particulars
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (item.subtitle.isNotEmpty && item.subtitle != '-') ...[
                    pw.SizedBox(height: 1),
                    subWidget,
                  ],
                ],
              ),
            ),
            // Category
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: catWidget,
            ),
            // Mode Badge
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: modeBgColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    cleanMode,
                    style: pw.TextStyle(
                      fontSize: 6.2,
                      fontWeight: pw.FontWeight.bold,
                      color: modeTextColor,
                      font: latinBold,
                    ),
                  ),
                ),
              ),
            ),
            // Credit (+)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Text(
                item.isCredit ? currencyFmt.format(item.amount) : '-',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7.2,
                  fontWeight: item.isCredit ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: item.isCredit ? const PdfColor.fromInt(0xFF047857) : PdfColors.grey400,
                  font: item.isCredit ? latinBold : latinRegular,
                ),
              ),
            ),
            // Debit (-)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Text(
                !item.isCredit ? currencyFmt.format(item.amount) : '-',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7.2,
                  fontWeight: !item.isCredit ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: !item.isCredit ? const PdfColor.fromInt(0xFFDC2626) : PdfColors.grey400,
                  font: !item.isCredit ? latinBold : latinRegular,
                ),
              ),
            ),
            // Running Net Balance
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: pw.BoxDecoration(
                  color: isPositiveBalance
                      ? const PdfColor(0.94, 0.99, 0.96)
                      : const PdfColor(0.99, 0.94, 0.94),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  currencyFmt.format(item.runningBalance),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 7.2,
                    fontWeight: pw.FontWeight.bold,
                    font: latinBold,
                    color: isPositiveBalance
                        ? const PdfColor.fromInt(0xFF047857)
                        : const PdfColor.fromInt(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // FINAL SUMMARY ROW AT BOTTOM OF LEDGER
    ledgerRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor(0.92, 0.98, 0.95)),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('FINAL CLOSING BALANCE (', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold, color: const PdfColor.fromInt(0xFF065F46))),
                pw.Image(closingBalanceLabelImg, height: 9),
                pw.Text(')', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold, color: const PdfColor.fromInt(0xFF065F46))),
              ],
            ),
          ),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
          // Total Credits
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: pw.Text(
              currencyFmt.format(summary.totalIncome),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 7.8, fontWeight: pw.FontWeight.bold, font: latinBold, color: const PdfColor.fromInt(0xFF047857)),
            ),
          ),
          // Total Debits
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: pw.Text(
              currencyFmt.format(summary.totalExpenses),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 7.8, fontWeight: pw.FontWeight.bold, font: latinBold, color: const PdfColor.fromInt(0xFFDC2626)),
            ),
          ),
          // Final Closing Treasury Balance
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: pw.BoxDecoration(
                color: summary.currentSavings >= 0
                    ? const PdfColor(0.85, 0.98, 0.9)
                    : const PdfColor(0.99, 0.88, 0.88),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(
                currencyFmt.format(summary.currentSavings),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.2,
                  fontWeight: pw.FontWeight.bold,
                  font: latinBold,
                  color: summary.currentSavings >= 0
                      ? const PdfColor.fromInt(0xFF047857)
                      : const PdfColor.fromInt(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // BUILD CATEGORY BREAKDOWN TABLE
    final expCatHeaderImg = await _renderShapedText(text: 'ખર્ચ પ્રકાર', fontSize: 6, color: Colors.white70);
    final spentHeaderImg = await _renderShapedText(text: 'કુલ રકમ', fontSize: 6, color: Colors.white70);
    final shareHeaderImg = await _renderShapedText(text: 'હિસ્સો', fontSize: 6, color: Colors.white70);

    final List<pw.TableRow> categorySummaryRows = [];
    categorySummaryRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E293B)),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXPENSE CATEGORY', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
                pw.Image(expCatHeaderImg, height: 8),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('TOTAL SPENT', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
                pw.Image(spentHeaderImg, height: 8),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('SHARE (%)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, font: latinBold)),
                pw.Image(shareHeaderImg, height: 8),
              ],
            ),
          ),
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

      final catLabelWidget = await _buildSafeText(
        text: '${cat.titleGujarati} (${cat.titleEnglish})',
        fontSize: 7.5,
        fallbackColor: const PdfColor.fromInt(0xFF0F172A),
        renderColor: const Color(0xFF0F172A),
        pwWeight: pw.FontWeight.bold,
        uiWeight: FontWeight.w700,
        maxWidth: 280,
        height: 10,
      );

      categorySummaryRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: catLabelWidget,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                currencyFmt.format(entry.value),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                '$percent %',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 7.5, font: latinRegular),
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
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
                          fontSize: 13,
                          font: latinBold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Image(socNameImg, height: 14, fit: pw.BoxFit.contain),
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          'Society Code: $displaySocCode | Official ERP Financial Ledger',
                          style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, font: latinRegular),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT DATE: $dateStr',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: latinBold),
                    ),
                    pw.Text(
                      'STATUS: AUDITED & CERTIFIED',
                      style: pw.TextStyle(fontSize: 7.5, color: const PdfColor.fromInt(0xFF047857), fontWeight: pw.FontWeight.bold, font: latinBold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.2, color: const PdfColor.fromInt(0xFF0F766E)),
            pw.SizedBox(height: 3),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'My Building Guard • Official Financial Ledger & Treasury Passbook',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, font: latinRegular),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, font: latinRegular),
            ),
          ],
        ),
        build: (context) => [
          // Subtitle and Period
          pw.Center(
            child: pw.Column(
              children: [
                pw.Image(titleGujImg, height: 12, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  periodStr,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold, font: latinBold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // 1. FINANCIAL SUMMARY KPI BOX
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.97, 0.99, 0.98),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFA7F3D0), width: 1.0),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiCard(
                  englishTitle: 'TOTAL INFLOW',
                  gujaratiTitleImg: kpiInflowGujImg,
                  amount: currencyFmt.format(summary.totalIncome),
                  subtitle: '${summary.paidBillsCount} Maintenance Bills Paid',
                  amountColor: const PdfColor.fromInt(0xFF047857),
                  latinBold: latinBold,
                  latinRegular: latinRegular,
                ),
                _buildKpiCard(
                  englishTitle: 'TOTAL OUTFLOW',
                  gujaratiTitleImg: kpiOutflowGujImg,
                  amount: currencyFmt.format(summary.totalExpenses),
                  subtitle: '${expenses.length} Expenses Incurred',
                  amountColor: const PdfColor.fromInt(0xFFDC2626),
                  latinBold: latinBold,
                  latinRegular: latinRegular,
                ),
                _buildKpiCard(
                  englishTitle: 'NET SAVINGS',
                  gujaratiTitleImg: kpiSavingsGujImg,
                  amount: currencyFmt.format(summary.currentSavings),
                  subtitle: summary.currentSavings >= 0 ? 'Surplus Reserve Fund' : 'Deficit Balance',
                  subtitleGujImg: kpiSavingsSubGujImg,
                  amountColor: summary.currentSavings >= 0 ? const PdfColor.fromInt(0xFF065F46) : const PdfColor.fromInt(0xFFDC2626),
                  latinBold: latinBold,
                  latinRegular: latinRegular,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // 2. CHRONOLOGICAL DATE-WISE PASSBOOK LEDGER TABLE
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'DATE-WISE PASSBOOK LEDGER  •  ',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: latinBold, color: PdfColors.black),
                  ),
                  pw.Image(passbookSectionTitleImg, height: 10),
                ],
              ),
              pw.Text(
                'Total Entries: ${summary.ledgerEntries.length}',
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, font: latinRegular),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: const PdfColor(0.85, 0.9, 0.92), width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(50), // Date
              1: pw.FlexColumnWidth(2.5), // Particulars
              2: pw.FlexColumnWidth(1.3), // Category
              3: pw.FixedColumnWidth(42), // Mode
              4: pw.FixedColumnWidth(58), // Credit
              5: pw.FixedColumnWidth(58), // Debit
              6: pw.FixedColumnWidth(66), // Balance
            },
            children: ledgerRows,
          ),
          pw.SizedBox(height: 12),

          // 3. CATEGORY DISTRIBUTION TABLE
          if (categorySummaryRows.length > 1) ...[
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'EXPENSE SUMMARY BY CATEGORY  •  ',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: latinBold, color: PdfColors.black),
                ),
                pw.Image(catSectionTitleImg, height: 10),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: const PdfColor(0.85, 0.9, 0.92), width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.0),
                1: pw.FixedColumnWidth(95),
                2: pw.FixedColumnWidth(75),
              },
              children: categorySummaryRows,
            ),
            pw.SizedBox(height: 12),
          ],

          // 4. OFFICIAL DIGITAL VERIFICATION STAMP AND SIGNATURE BLOCK
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.99, 0.99, 0.99),
              border: pw.Border.all(color: const PdfColor(0.85, 0.9, 0.92)),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OFFICIAL AUDIT & AUTHENTICITY DECLARATION:',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '1. This statement represents the true society financial ledger as recorded in My Building Guard ERP.\n'
                      '2. Date-wise running balances reflect all settled maintenance receipts and verified expense entries.\n'
                      '3. Members can audit these transactions real-time in the resident mobile application.',
                      style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700, font: latinRegular),
                    ),
                  ],
                ),
                pw.Image(stampImage, width: 95, fit: pw.BoxFit.contain),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Signatory Lines
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 3),
                  pw.Image(presSignImg, height: 10),
                  pw.Text('Authorized Signatory (President)', style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600, font: latinRegular)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 3),
                  pw.Image(tresSignImg, height: 10),
                  pw.Text('Authorized Auditor (Treasurer)', style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600, font: latinRegular)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard({
    required String englishTitle,
    required pw.MemoryImage gujaratiTitleImg,
    required String amount,
    required String subtitle,
    required PdfColor amountColor,
    required pw.Font latinBold,
    required pw.Font latinRegular,
    pw.MemoryImage? subtitleGujImg,
  }) {
    // Strip ANY non-Latin character from the raw subtitle to strictly prevent missing-glyph XXXX
    final safeSubtitle = subtitle.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();

    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(englishTitle, style: pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700, font: latinBold)),
              pw.SizedBox(width: 3),
              pw.Image(gujaratiTitleImg, height: 8),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            amount,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: amountColor, font: latinBold),
          ),
          pw.SizedBox(height: 1.5),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(safeSubtitle, style: pw.TextStyle(fontSize: 6.2, color: PdfColors.grey600, font: latinRegular)),
              if (subtitleGujImg != null) ...[
                pw.SizedBox(width: 2.5),
                pw.Image(subtitleGujImg, height: 7.5),
              ],
            ],
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
    final safeFileName = 'Society_Passbook_Statement_$dateStr.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PremiumAppBar(
        title: 'સોસાયટી નાણાકીય સ્ટેટમેન્ટ (PDF)',
        subtitle: 'Date-wise Treasury Passbook & Ledger',
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
                'તારીખવાર ખાતાવહી & પાસબુક તૈયાર થઈ રહી છે...',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
