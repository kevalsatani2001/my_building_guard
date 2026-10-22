import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'society_service.dart';

/// મોડેલ: સહી પત્રક માટે સભ્ય/યુનિટ રેકોર્ડ
class MemberSignatureRecord {
  final int srNo;
  final String wingOrBlock;
  final String unitNumber;
  final String memberName;
  final String phone;
  final String unitType;
  final bool isOccupied;

  MemberSignatureRecord({
    required this.srNo,
    required this.wingOrBlock,
    required this.unitNumber,
    required this.memberName,
    required this.phone,
    this.unitType = 'flat',
    this.isOccupied = true,
  });
}

/// સર્વિસ: સભ્ય સહી પત્રક (Member Signature / Consent Sheet) PDF જનરેટર
class MemberSignatureSheetPdfService {
  static final Map<String, pw.MemoryImage> _textCache = {};
  static final Map<String, Size> _textSizeCache = {};

  /// Render Gujarati/Indic text using Flutter's native HarfBuzz shaping engine into a 300 DPI ultra-sharp image
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

  /// Safe Shaped Widget: Guarantees 0 missing glyphs (no XXXXX tofu boxes) by rendering via Canvas with exact natural dimensions
  static Future<pw.Widget> _buildSafeShapedText({
    required String text,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
    double? maxWidth,
  }) async {
    final clean = text.trim().isEmpty ? ' ' : text.trim();
    final img = await _renderShapedText(
      text: clean,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxWidth: maxWidth,
    );
    final cacheKey =
        '$clean|$fontSize|${color.toARGB32()}|${fontWeight.value}|$textAlign|${maxWidth?.toInt() ?? 0}';
    final naturalSize = _textSizeCache[cacheKey] ?? Size(fontSize * 5, fontSize * 1.3);

    return pw.Image(
      img,
      width: naturalSize.width,
      height: naturalSize.height,
      fit: pw.BoxFit.contain,
    );
  }

  static bool _hasNonLatin(String text) {
    for (final rune in text.runes) {
      if (rune > 0x007F) return true;
    }
    return false;
  }

  /// Official Rubber Stamp for Register
  static Future<pw.MemoryImage> _renderOfficialRegisterStamp({
    required String dateStr,
    required String societyName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const scale = 3.0;
    const width = 180.0 * scale;
    const height = 90.0 * scale;

    const primaryColor = Color(0xFF1E3A8A); // Deep Navy
    const lightBgColor = Color(0x101E3A8A);

    final rect = Rect.fromLTWH(4 * scale, 4 * scale, (180.0 - 8) * scale, (90.0 - 8) * scale);
    final rrectOuter = RRect.fromRectAndRadius(rect, Radius.circular(8 * scale));
    final rrectInner = RRect.fromRectAndRadius(rect.deflate(3 * scale), Radius.circular(6 * scale));

    final bgPaint = Paint()
      ..color = lightBgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrectOuter, bgPaint);

    final outerBorder = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRRect(rrectOuter, outerBorder);

    final innerBorder = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * scale;
    canvas.drawRRect(rrectInner, innerBorder);

    final headerPainter = TextPainter(
      text: TextSpan(
        text: '★ OFFICIAL SOCIETY REGISTER ★',
        style: TextStyle(
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 0.8 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 10 * scale);
    headerPainter.paint(canvas, Offset(rect.center.dx - headerPainter.width / 2, rect.top + 5 * scale));

    canvas.drawLine(
      Offset(rect.left + 8 * scale, rect.top + 16 * scale),
      Offset(rect.right - 8 * scale, rect.top + 16 * scale),
      innerBorder,
    );

    final mainPainter = TextPainter(
      text: TextSpan(
        text: 'VERIFIED',
        style: TextStyle(
          fontSize: 18.0 * scale,
          fontWeight: FontWeight.w900,
          color: primaryColor,
          letterSpacing: 2.0 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    mainPainter.paint(canvas, Offset(rect.center.dx - mainPainter.width / 2, rect.top + 20 * scale));

    canvas.drawLine(
      Offset(rect.left + 8 * scale, rect.top + 50 * scale),
      Offset(rect.right - 8 * scale, rect.top + 50 * scale),
      innerBorder,
    );

    final gujPainter = TextPainter(
      text: TextSpan(
        text: 'સત્તાવાર સભ્ય સંમતિ રજીસ્ટર',
        style: TextStyle(
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    gujPainter.paint(canvas, Offset(rect.center.dx - gujPainter.width / 2, rect.top + 53 * scale));

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
    datePainter.paint(canvas, Offset(rect.center.dx - datePainter.width / 2, rect.top + 68 * scale));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(pngBytes!.buffer.asUint8List());
  }

  /// PDF જનરેશન મુખ્ય મેથડ
  static Future<Uint8List> generateSignatureSheetPdf({
    required String societyName,
    required String city,
    required String purposeTitle,
    required String resolutionNumber,
    required String purposeDescription,
    required DateTime eventDate,
    required String selectedWing,
    required List<MemberSignatureRecord> members,
    bool includeRemarksColumn = true,
    bool includeContactColumn = true,
  }) async {
    final pdf = pw.Document();

    pw.Font latinRegular;
    pw.Font latinBold;

    try {
      latinRegular = await PdfGoogleFonts.notoSansRegular().timeout(const Duration(seconds: 2));
      latinBold = await PdfGoogleFonts.notoSansBold().timeout(const Duration(seconds: 2));
    } catch (_) {
      latinRegular = pw.Font.helvetica();
      latinBold = pw.Font.helveticaBold();
    }

    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateStr = dateFmt.format(eventDate);
    final stampImg = await _renderOfficialRegisterStamp(dateStr: dateStr, societyName: societyName);

    // 🌟 Pre-render all Gujarati Labels cleanly via Canvas TextPainter shaping
    final socNameImg = await _buildSafeShapedText(
      text: societyName.isEmpty ? 'સોસાયટી સભ્ય સહી પત્રક' : societyName,
      fontSize: 16,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.w900,
      maxWidth: 400,
    );

    final titleGujImg = await _buildSafeShapedText(
      text: 'સભ્ય સંમતિ / સહી પત્રક (MEMBER CONSENT & SIGNATURE REGISTER)',
      fontSize: 10.5,
      color: const Color(0xFF1E3A8A),
      fontWeight: FontWeight.w800,
      maxWidth: 480,
    );

    final purposeTitleImg = await _buildSafeShapedText(
      text: purposeTitle.isEmpty ? 'સામાન્ય સભા ઠરાવ / સભ્ય સંમતિ' : purposeTitle,
      fontSize: 11.5,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
      maxWidth: 460,
    );

    pw.Widget? purposeDescWidget;
    if (purposeDescription.trim().isNotEmpty) {
      purposeDescWidget = await _buildSafeShapedText(
        text: purposeDescription.trim(),
        fontSize: 9.0,
        color: const Color(0xFF334155),
        fontWeight: FontWeight.normal,
        maxWidth: 460,
      );
    }

    // Purpose Box Meta Labels
    final subjectHeadingImg = await _buildSafeShapedText(
      text: 'વિષય / ઠરાવ હેતુ:',
      fontSize: 8.5,
      color: const Color(0xFF1E3A8A),
      fontWeight: FontWeight.bold,
    );

    final resolutionImg = await _buildSafeShapedText(
      text: resolutionNumber.isNotEmpty ? 'સંદર્ભ: $resolutionNumber' : 'સંદર્ભ: સામાન્ય ઠરાવ',
      fontSize: 8,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.bold,
    );

    final dateImg = await _buildSafeShapedText(
      text: 'તારીખ: $dateStr',
      fontSize: 8,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.bold,
    );

    final wingImg = await _buildSafeShapedText(
      text: selectedWing == 'ALL'
          ? 'પરિસર: તમામ એકમો (All)'
          : 'પરિસર: ${SocietyService.instance.formatBlockDisplayName(selectedWing)}',
      fontSize: 8,
      color: const Color(0xFF1E3A8A),
      fontWeight: FontWeight.bold,
    );

    final notesHeadingImg = await _buildSafeShapedText(
      text: 'સંમતિ શરતો / નોંધ:',
      fontSize: 7.5,
      color: const Color(0xFF475569),
      fontWeight: FontWeight.bold,
    );

    // Table Sub-label Shaped Widgets (High Quality)
    final subWingImg = await _buildSafeShapedText(text: 'વિંગ/બ્લોક', fontSize: 6.5, color: Colors.white70);
    final subUnitImg = await _buildSafeShapedText(text: 'ફ્લેટ/દુકાન', fontSize: 6.5, color: Colors.white70);
    final subNameImg = await _buildSafeShapedText(text: 'સભ્યનું નામ', fontSize: 6.5, color: Colors.white70);
    final subPhoneImg = await _buildSafeShapedText(text: 'મોબાઈલ નંબર', fontSize: 6.5, color: Colors.white70);
    final subConsentImg = await _buildSafeShapedText(text: 'સંમતિ / મંતવ્ય', fontSize: 6.5, color: Colors.white70);
    final subSignImg = await _buildSafeShapedText(text: 'સભ્યની સહી (Sign)', fontSize: 7, color: Colors.white70);

    // Consent Agree Checkbox Label in each row
    final consentAgreeWidget = await _buildSafeShapedText(
      text: 'સંમત',
      fontSize: 7.5,
      color: const Color(0xFF475569),
    );

    // Footer Signatories Shaped Widgets
    final totalMembersImg = await _buildSafeShapedText(
      text: 'કુલ સભ્યો / એકમો: ${members.length}',
      fontSize: 8.5,
      color: const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
    );

    final checkDateImg = await _buildSafeShapedText(
      text: 'ચકાસણી તારીખ: $dateStr',
      fontSize: 8,
      color: const Color(0xFF475569),
    );

    final signatory1Img = await _buildSafeShapedText(
      text: 'કમિટી સભ્યની સહી',
      fontSize: 8,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.bold,
    );

    final signatory2Img = await _buildSafeShapedText(
      text: 'સેક્રેટરી / મંત્રીની સહી',
      fontSize: 8,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.bold,
    );

    final signatory3Img = await _buildSafeShapedText(
      text: 'ચેરમેન / પ્રમુખ & સિક્કો',
      fontSize: 8,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.bold,
    );

    // Build Table Header Row
    final headerWidgets = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Center(
          child: pw.Text('SR.', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, font: latinBold)),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Center(
          child: pw.Column(
            children: [
              pw.Text('WING', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
              subWingImg,
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Center(
          child: pw.Column(
            children: [
              pw.Text('UNIT NO.', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
              subUnitImg,
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MEMBER NAME', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
              subNameImg,
            ],
          ),
        ),
      ),
    ];

    if (includeContactColumn) {
      headerWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text('CONTACT', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
                subPhoneImg,
              ],
            ),
          ),
        ),
      );
    }

    if (includeRemarksColumn) {
      headerWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text('CONSENT', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
                subConsentImg,
              ],
            ),
          ),
        ),
      );
    }

    headerWidgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Center(
          child: pw.Column(
            children: [
              pw.Text('SIGNATURE', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, font: latinBold)),
              subSignImg,
            ],
          ),
        ),
      ),
    );

    // Pre-render multi-page header society name safely
    final pageHeaderSocWidget = _hasNonLatin(societyName)
        ? await _buildSafeShapedText(
            text: societyName.isNotEmpty ? societyName : 'MEMBER SIGNATURE REGISTER',
            fontSize: 8.5,
            color: const Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            maxWidth: 350,
          )
        : pw.Text(
            societyName.isNotEmpty ? societyName : 'MEMBER SIGNATURE REGISTER',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              font: latinBold,
              color: const PdfColor.fromInt(0xFF1E3A8A),
            ),
          );

    pw.Widget? cityWidget;
    if (city.isNotEmpty) {
      if (_hasNonLatin(city)) {
        cityWidget = await _buildSafeShapedText(
          text: city,
          fontSize: 7.5,
          color: const Color(0xFF475569),
          fontWeight: FontWeight.normal,
        );
      } else {
        cityWidget = pw.Text(
          city.toUpperCase(),
          style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, font: latinRegular),
        );
      }
    }

    // Pre-cache member name, wing and unit widgets
    final Map<int, pw.Widget> memberNameWidgets = {};
    final Map<int, pw.Widget> wingWidgets = {};
    final Map<int, pw.Widget> unitWidgets = {};
    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      if (_hasNonLatin(m.memberName)) {
        memberNameWidgets[i] = await _buildSafeShapedText(
          text: m.memberName,
          fontSize: 9.0,
          color: m.isOccupied ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          fontWeight: m.isOccupied ? FontWeight.w600 : FontWeight.normal,
          maxWidth: 160,
        );
      } else {
        memberNameWidgets[i] = pw.Text(
          m.memberName.isEmpty ? '-' : m.memberName,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: m.isOccupied ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: m.isOccupied ? const PdfColor(0.06, 0.09, 0.16) : PdfColors.grey500,
            font: latinRegular,
          ),
        );
      }

      if (_hasNonLatin(m.wingOrBlock)) {
        wingWidgets[i] = await _buildSafeShapedText(
          text: m.wingOrBlock,
          fontSize: 8.5,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.bold,
          maxWidth: 40,
        );
      } else {
        wingWidgets[i] = pw.Text(
          m.wingOrBlock,
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold),
        );
      }

      if (_hasNonLatin(m.unitNumber)) {
        unitWidgets[i] = await _buildSafeShapedText(
          text: m.unitNumber,
          fontSize: 8.5,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.bold,
          maxWidth: 46,
        );
      } else {
        unitWidgets[i] = pw.Text(
          m.unitNumber,
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold),
        );
      }
    }

    final List<pw.TableRow> tableRows = [];
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
        children: headerWidgets,
      ),
    );

    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final isEven = i % 2 == 0;
      final rowBg = isEven ? const PdfColor(1, 1, 1) : const PdfColor(0.97, 0.98, 0.99);

      final rowCells = <pw.Widget>[
        // Sr No
        pw.Container(
          height: 30,
          alignment: pw.Alignment.center,
          child: pw.Text('${m.srNo}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
        ),
        // Wing
        pw.Container(
          height: 30,
          alignment: pw.Alignment.center,
          child: wingWidgets[i] ?? pw.Text(m.wingOrBlock, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
        ),
        // Unit
        pw.Container(
          height: 30,
          alignment: pw.Alignment.center,
          child: unitWidgets[i] ?? pw.Text(m.unitNumber, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold)),
        ),
        // Name
        pw.Container(
          height: 30,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6),
          alignment: pw.Alignment.centerLeft,
          child: memberNameWidgets[i] ?? pw.Text(m.memberName, style: const pw.TextStyle(fontSize: 8)),
        ),
      ];

      // Contact
      if (includeContactColumn) {
        rowCells.add(
          pw.Container(
            height: 30,
            alignment: pw.Alignment.center,
            child: pw.Text(
              m.phone.isNotEmpty ? m.phone : '-',
              style: pw.TextStyle(fontSize: 8, font: latinRegular, color: PdfColors.grey700),
            ),
          ),
        );
      }

      // Consent / Remarks (using pre-rendered shaped Gujarati text so NO XXXXX)
      if (includeRemarksColumn) {
        rowCells.add(
          pw.Container(
            height: 30,
            alignment: pw.Alignment.center,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: const PdfColor(0.5, 0.5, 0.5), width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 4),
                consentAgreeWidget,
              ],
            ),
          ),
        );
      }

      // Signature (Spacious physical box with dot line)
      rowCells.add(
        pw.Container(
          height: 30,
          padding: const pw.EdgeInsets.fromLTRB(4, 2, 4, 3),
          alignment: pw.Alignment.bottomCenter,
          child: pw.Container(
            height: 1,
            color: const PdfColor(0.85, 0.88, 0.92),
          ),
        ),
      );

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowBg),
          children: rowCells,
        ),
      );
    }

    // PDF Table Column Widths
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    int colIdx = 0;
    columnWidths[colIdx++] = const pw.FixedColumnWidth(26); // Sr
    columnWidths[colIdx++] = const pw.FixedColumnWidth(38); // Wing
    columnWidths[colIdx++] = const pw.FixedColumnWidth(46); // Unit
    columnWidths[colIdx++] = const pw.FlexColumnWidth(3.2); // Name
    if (includeContactColumn) {
      columnWidths[colIdx++] = const pw.FixedColumnWidth(74); // Phone
    }
    if (includeRemarksColumn) {
      columnWidths[colIdx++] = const pw.FixedColumnWidth(54); // Consent
    }
    columnWidths[colIdx++] = const pw.FlexColumnWidth(2.2); // Sign

    // MultiPage Setup
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 22, 22, 24),
        header: (context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pageHeaderSocWidget,
                  pw.Text(
                    'PAGE ${context.pageNumber} OF ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 7.5, font: latinBold, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          }
          return pw.SizedBox.shrink();
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MyBuildingGuard ERP • Official Member Consent & Signature Register',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, font: latinBold, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // 🏢 1. Official Society Header Block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.97, 0.98, 1.0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 1.0),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        socNameImg,
                        if (cityWidget != null) ...[
                          pw.SizedBox(height: 2),
                          cityWidget,
                        ],
                        pw.SizedBox(height: 6),
                        titleGujImg,
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Rubber stamp
                  pw.Image(stampImg, width: 85, height: 42),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 📋 2. Purpose / Resolution Metadata Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(1, 1, 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFF1E3A8A), width: 1.2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Row with Purpose Title & Meta Details
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('SUBJECT / ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, font: latinBold, color: const PdfColor.fromInt(0xFF1E3A8A))),
                                subjectHeadingImg,
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            purposeTitleImg,
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          resolutionImg,
                          pw.SizedBox(height: 2),
                          dateImg,
                          pw.SizedBox(height: 2),
                          wingImg,
                        ],
                      ),
                    ],
                  ),

                  // Optional Detailed Description Note
                  if (purposeDescWidget != null) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(height: 0.5, color: const PdfColor.fromInt(0xFFE2E8F0)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        notesHeadingImg,
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: purposeDescWidget),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 📊 3. Member Signature Table
            pw.Table(
              border: pw.TableBorder.all(
                color: const PdfColor.fromInt(0xFFCBD5E1),
                width: 0.8,
              ),
              columnWidths: columnWidths,
              children: tableRows,
            ),
            pw.SizedBox(height: 16),

            // ✍️ 4. Final Signatories & Verification Block
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.98, 0.99, 1.0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      totalMembersImg,
                      checkDateImg,
                    ],
                  ),
                  pw.SizedBox(height: 36),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                          pw.SizedBox(height: 4),
                          signatory1Img,
                          pw.SizedBox(height: 2),
                          pw.Text('(Committee Member)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                          pw.SizedBox(height: 4),
                          signatory2Img,
                          pw.SizedBox(height: 2),
                          pw.Text('(Secretary Sign)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 120, height: 1, color: PdfColors.grey800),
                          pw.SizedBox(height: 4),
                          signatory3Img,
                          pw.SizedBox(height: 2),
                          pw.Text('(Chairman & Seal)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
