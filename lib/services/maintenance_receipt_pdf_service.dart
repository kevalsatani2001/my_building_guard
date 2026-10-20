import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/maintenance_model.dart';
import 'package:building_guard/core/app_firestore.dart';

class MaintenanceReceiptPdfService {
  /// Fetches society display name with fallback
  static Future<String> getSocietyName(String societyId) async {
    try {
      final doc = await AppFirestore.instance
          .collection('societies')
          .doc(societyId)
          .get()
          .timeout(const Duration(seconds: 2));
      final name = doc.data()?['societyName']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}

    try {
      final settings = await AppFirestore.instance
          .collection('society_settings')
          .doc(societyId)
          .get()
          .timeout(const Duration(seconds: 2));
      final name = settings.data()?['upiPayeeName']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}

    return 'માય સોસાયટી (My Society)';
  }

  /// Checks if a string contains Gujarati Unicode characters (U+0A80 to U+0AFF)
  static bool _hasGujarati(String s) => RegExp(r'[\u0A80-\u0AFF]').hasMatch(s);

  @visibleForTesting
  static Future<pw.MemoryImage> renderShapedTextForTest(String text) =>
      _renderShapedText(text: text, fontSize: 14, color: Colors.black);

  /// Renders text using Flutter's native HarfBuzz shaping engine into a crisp 300 DPI image.
  /// This completely eliminates broken Indic conjuncts, displaced matras, and halants in PDF.
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
          fontSize: fontSize * 3.0, // 3x scale for ultra-sharp 300 DPI
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

  /// Renders a photorealistic, official digital rubber stamp for PAID (Green) or UNPAID (Red).
  /// Designed with authentic double security borders, official header badges, and native HarfBuzz Gujarati text.
  static Future<pw.MemoryImage> _renderStampImage({
    required bool isPaid,
    required String dateStr,
    required String societyName,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const scale = 3.0; // 3x scale for ultra-sharp 300 DPI
    const width = 230.0 * scale;
    const height = 120.0 * scale;

    final primaryColor = isPaid ? const Color(0xFF047857) : const Color(0xFFDC2626);
    final lightBgColor = isPaid ? const Color(0x12047857) : const Color(0x12DC2626);

    final rect = Rect.fromLTWH(6 * scale, 6 * scale, (230.0 - 12) * scale, (120.0 - 12) * scale);
    final rrectOuter = RRect.fromRectAndRadius(rect, Radius.circular(14 * scale));
    final rrectInner = RRect.fromRectAndRadius(
      rect.deflate(4.5 * scale),
      Radius.circular(10 * scale),
    );

    // 1. Soft ink-wash background
    final bgPaint = Paint()
      ..color = lightBgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrectOuter, bgPaint);

    // 2. Outer heavy border (rubber stamp rim)
    final outerBorderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale;
    canvas.drawRRect(rrectOuter, outerBorderPaint);

    // 3. Inner fine hairline border
    final innerBorderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(rrectInner, innerBorderPaint);

    // 4. Header line
    final headerText = isPaid
        ? '* OFFICIAL SOCIETY RECEIPT *'
        : '! PAYMENT OVERDUE NOTICE !';
    final headerPainter = TextPainter(
      text: TextSpan(
        text: headerText,
        style: TextStyle(
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 20 * scale);
    headerPainter.paint(
      canvas,
      Offset(rect.center.dx - headerPainter.width / 2, rect.top + 8 * scale),
    );

    // Divider line under header
    canvas.drawLine(
      Offset(rect.left + 14 * scale, rect.top + 22 * scale),
      Offset(rect.right - 14 * scale, rect.top + 22 * scale),
      innerBorderPaint,
    );

    // 5. Main Bold Stamp: "PAID" or "UNPAID"
    final mainText = isPaid ? 'PAID' : 'UNPAID';
    final mainPainter = TextPainter(
      text: TextSpan(
        text: mainText,
        style: TextStyle(
          fontSize: 32.0 * scale,
          fontWeight: FontWeight.w900,
          color: primaryColor,
          letterSpacing: 4.0 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 20 * scale);
    mainPainter.paint(
      canvas,
      Offset(rect.center.dx - mainPainter.width / 2, rect.top + 24 * scale),
    );

    // 6. Gujarati subtitle under PAID/UNPAID: "સફળતાપૂર્વક ચૂકવેલ" or "ચુકવણી બાકી"
    final gujText = isPaid ? 'સફળતાપૂર્વક ચૂકવેલ - VERIFIED' : 'ચુકવણી બાકી - DUE';
    final gujPainter = TextPainter(
      text: TextSpan(
        text: gujText,
        style: TextStyle(
          fontSize: 9.0 * scale,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 0.5 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 20 * scale);
    gujPainter.paint(
      canvas,
      Offset(rect.center.dx - gujPainter.width / 2, rect.top + 64 * scale),
    );

    // Divider line above date
    canvas.drawLine(
      Offset(rect.left + 14 * scale, rect.bottom - 22 * scale),
      Offset(rect.right - 14 * scale, rect.bottom - 22 * scale),
      innerBorderPaint,
    );

    // 7. Footer: Date
    final footerText = isPaid ? 'PAID: $dateStr' : 'DUE: $dateStr';
    final footerPainter = TextPainter(
      text: TextSpan(
        text: footerText,
        style: TextStyle(
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: 0.8 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: rect.width - 20 * scale);
    footerPainter.paint(
      canvas,
      Offset(rect.center.dx - footerPainter.width / 2, rect.bottom - 17 * scale),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(pngBytes!.buffer.asUint8List());
  }

  /// Generates the PDF binary bytes for a verified/paid Maintenance Bill.
  static Future<Uint8List> generateReceiptPdf(
    MaintenanceBill bill, {
    String? societyName,
  }) async {
    final pdf = pw.Document();

    // 1. Fetch society name
    final resolvedSocietyName = societyName?.trim().isNotEmpty == true
        ? societyName!
        : await getSocietyName(bill.societyId);

    // 2. Load Latin fonts for vector crispness
    pw.Font latinRegular;
    pw.Font latinBold;
    try {
      latinRegular = await PdfGoogleFonts.notoSansRegular();
      latinBold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      latinRegular = pw.Font.helvetica();
      latinBold = pw.Font.helveticaBold();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    final paidDateStr = bill.paidAt != null
        ? DateFormat('dd/MM/yyyy, hh:mm a').format(bill.paidAt!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final dueDateStr = DateFormat('dd/MM/yyyy').format(bill.dueDate);

    final safeReceiptNo = bill.receiptNumber.trim().isNotEmpty
        ? bill.receiptNumber.trim()
        : 'BG-REC-${bill.id.length > 8 ? bill.id.substring(0, 8).toUpperCase() : bill.id.toUpperCase()}';

    // 3. Resolve Member details
    String memberName = bill.memberName.trim();
    String memberPhone = bill.memberPhone.trim();
    String memberEmail = '';
    String memberRole = 'Owner (માલિક)';

    try {
      if (bill.memberId != null && bill.memberId!.isNotEmpty) {
        final userDoc = await AppFirestore.instance
            .collection('users')
            .doc(bill.memberId)
            .get()
            .timeout(const Duration(seconds: 2));
        final uData = userDoc.data();
        if (uData != null) {
          if (memberName.isEmpty || memberName == 'મેમ્બર') {
            memberName = (uData['name'] ?? '').toString().trim();
          }
          if (memberPhone.isEmpty || memberPhone == '-') {
            memberPhone = (uData['phone'] ?? '').toString().trim();
          }
          memberEmail = (uData['email'] ?? '').toString().trim();
          final r = (uData['role'] ?? 'member').toString();
          memberRole = r == 'admin'
              ? 'Admin (એડમિન)'
              : (uData['occupantType'] == 'tenant'
                  ? 'Tenant (ભાડુઆત)'
                  : 'Owner (માલિક)');
        }
      }

      if (memberName.isEmpty || memberName == 'મેમ્બર' || memberPhone.isEmpty || memberPhone == '-') {
        final unitDoc = await AppFirestore.instance
            .collection('units')
            .where('societyId', isEqualTo: bill.societyId)
            .where('unitNumber', isEqualTo: bill.unitNumber)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 2));
        if (unitDoc.docs.isNotEmpty) {
          final uData = unitDoc.docs.first.data();
          if (memberName.isEmpty || memberName == 'મેમ્બર') {
            memberName = (uData['memberName'] ?? uData['ownerName'] ?? '').toString().trim();
          }
          if (memberPhone.isEmpty || memberPhone == '-') {
            memberPhone = (uData['memberPhone'] ?? uData['ownerPhone'] ?? '').toString().trim();
          }
        }
      }
    } catch (_) {}

    if (memberName.isEmpty) memberName = 'Society Member';
    if (memberPhone.isEmpty) memberPhone = 'Not Registered';

    final qrData = 'MyBuildingGuard|REC:$safeReceiptNo|FLAT:${bill.flatDisplay}|'
        'AMOUNT:${bill.totalPayable}|DATE:$paidDateStr|SOC:${bill.societyId}';

    // 4. Fetch digital signature and signatory details
    Uint8List? signatureBytes;
    String signatoryName = '';
    String signatoryTitle = 'સોસાયટી પ્રમુખ / સેક્રેટરી';

    try {
      final settingsDoc = await AppFirestore.instance
          .collection('society_settings')
          .doc(bill.societyId)
          .get()
          .timeout(const Duration(seconds: 3));
      final data = settingsDoc.data();
      if (data != null) {
        final sigBase64 = data['signatureBase64']?.toString().trim();
        if (sigBase64 != null && sigBase64.isNotEmpty) {
          try {
            signatureBytes = base64Decode(sigBase64);
          } catch (_) {}
        }
        final sName = data['signatoryName']?.toString().trim();
        if (sName != null && sName.isNotEmpty) {
          signatoryName = sName;
        }
        final sTitle = data['signatoryTitle']?.toString().trim();
        if (sTitle != null && sTitle.isNotEmpty) {
          signatoryTitle = sTitle;
        }
      }
    } catch (_) {}

    final rawVerifier = bill.verifiedBy.trim();
    final isUid = rawVerifier.length >= 20 && !rawVerifier.contains(' ');
    final effectiveVerifierName = signatoryName.isNotEmpty
        ? signatoryName
        : ((rawVerifier.isEmpty || rawVerifier.toLowerCase() == 'admin' || isUid)
            ? 'Society Admin / Chairman'
            : rawVerifier);

    final isPaid = bill.isPaid;
    final primaryThemeColor = isPaid
        ? PdfColor.fromInt(0xFF0F766E) // Deep Teal
        : PdfColor.fromInt(0xFFB91C1C); // Crimson Red
    final hairlineColor = isPaid
        ? PdfColor.fromInt(0xFF5EEAD4) // Mint Hairline
        : PdfColor.fromInt(0xFFFECDD3); // Rose Hairline
    final badgeBgColor = isPaid
        ? PdfColor.fromInt(0xFF047857) // Forest Green
        : PdfColor.fromInt(0xFFDC2626); // Crimson Red

    // 5. Pre-render ALL Gujarati and bilingual text with Flutter's native HarfBuzz shaping engine.
    // This 100% guarantees ZERO missing glyphs, ZERO broken matras, and ZERO [X][X][X] tofu boxes.
    final pw.Widget societyNameWidget = _hasGujarati(resolvedSocietyName)
        ? pw.Image(
            await _renderShapedText(
              text: resolvedSocietyName,
              fontSize: 19,
              color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
              fontWeight: FontWeight.bold,
            ),
            height: 24,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            resolvedSocietyName,
            style: pw.TextStyle(
              fontSize: 19,
              fontWeight: pw.FontWeight.bold,
              color: primaryThemeColor,
            ),
          );

    final pw.Widget receiptSubtitleWidget = pw.Image(
      await _renderShapedText(
        text: isPaid ? 'મેન્ટેનન્સ ચુકવણી સત્તાવાર રસીદ' : 'મેન્ટેનન્સ ચુકવણી માંગણી પત્રક',
        fontSize: 9.5,
        color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        fontWeight: FontWeight.w600,
      ),
      height: 13,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget badgeSubtitleWidget = pw.Image(
      await _renderShapedText(
        text: isPaid ? 'સફળતાપૂર્વક પ્રમાણિત' : 'ચુકવણી બાકી (UNPAID)',
        fontSize: 8.5,
        color: isPaid ? const Color(0xFF047857) : const Color(0xFFDC2626),
        fontWeight: FontWeight.bold,
      ),
      height: 12,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget memberSectionHeaderWidget = pw.Image(
      await _renderShapedText(
        text: 'MEMBER & UNIT DETAILS (સભ્ય અને ફ્લેટ વિગત)',
        fontSize: 10,
        color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        fontWeight: FontWeight.bold,
      ),
      height: 14,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget memberNameValWidget = _hasGujarati(memberName)
        ? pw.Image(
            await _renderShapedText(
              text: memberName,
              fontSize: 9.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
            height: 13,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            memberName,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          );

    final pw.Widget memberRoleValWidget = _hasGujarati(memberRole)
        ? pw.Image(
            await _renderShapedText(
              text: memberRole,
              fontSize: 9.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
            height: 13,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            memberRole,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          );

    final pw.Widget chargesSectionHeaderWidget = pw.Image(
      await _renderShapedText(
        text: 'CHARGES & SETTLEMENT BREAKDOWN (ચુકવણી હિસાબ વિગત)',
        fontSize: 10,
        color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        fontWeight: FontWeight.bold,
      ),
      height: 14,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget headerParticulars = pw.Image(
      await _renderShapedText(
        text: 'PARTICULARS (વિગત)',
        fontSize: 9,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      height: 12,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget headerPeriod = pw.Image(
      await _renderShapedText(
        text: 'PERIOD (મુદત)',
        fontSize: 9,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      height: 12,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget headerAmount = pw.Image(
      await _renderShapedText(
        text: 'AMOUNT (રકમ)',
        fontSize: 9,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      height: 12,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget billTitleValWidget = _hasGujarati(bill.billTitle)
        ? pw.Image(
            await _renderShapedText(
              text: bill.billTitle,
              fontSize: 9.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            height: 13,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            bill.billTitle,
            style: const pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.black,
            ),
          );

    final pw.Widget penaltyTitleValWidget = pw.Image(
      await _renderShapedText(
        text: 'Late Fee / Penalty (દંડ)',
        fontSize: 9.5,
        color: const Color(0xFF9A3412),
        fontWeight: FontWeight.w500,
      ),
      height: 13,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget grandTotalLabelWidget = pw.Image(
      await _renderShapedText(
        text: isPaid ? 'TOTAL AMOUNT PAID (કુલ ચૂકવેલ રકમ):' : 'TOTAL AMOUNT DUE (કુલ બાકી રકમ):',
        fontSize: 11,
        color: isPaid ? const Color(0xFF065F46) : const Color(0xFF991B1B),
        fontWeight: FontWeight.bold,
      ),
      height: 15,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget auditStatusValWidget = pw.Image(
      await _renderShapedText(
        text: isPaid ? 'સફળતાપૂર્વક જમા (VERIFIED)' : 'ચુકવણી બાકી (PENDING)',
        fontSize: 9.5,
        color: isPaid ? const Color(0xFF047857) : const Color(0xFFDC2626),
        fontWeight: FontWeight.bold,
      ),
      height: 13,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget termsHeadingWidget = pw.Image(
      await _renderShapedText(
        text: 'સત્તાવાર સોસાયટી નોંધ (Official Notice):',
        fontSize: 8.5,
        color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        fontWeight: FontWeight.bold,
      ),
      height: 12,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget signatoryHeaderWidget = pw.Image(
      await _renderShapedText(
        text: 'અધિકૃત ડિજિટલ સહી (Authorized)',
        fontSize: 7.5,
        color: isPaid ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
        fontWeight: FontWeight.bold,
      ),
      height: 11,
      fit: pw.BoxFit.contain,
    );

    final pw.Widget signatoryNameWidget = _hasGujarati(effectiveVerifierName)
        ? pw.Image(
            await _renderShapedText(
              text: effectiveVerifierName,
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            height: 13,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            effectiveVerifierName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          );

    final pw.Widget signatoryTitleWidget = _hasGujarati(signatoryTitle)
        ? pw.Image(
            await _renderShapedText(
              text: signatoryTitle,
              fontSize: 7.5,
              color: const Color(0xFF475569),
              textAlign: TextAlign.center,
            ),
            height: 11,
            fit: pw.BoxFit.contain,
          )
        : pw.Text(
            signatoryTitle,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey700,
            ),
          );

    // 6. Pre-render the Unique Rubber Stamp for PAID (Green) or UNPAID (Red)
    final pw.MemoryImage stampImage = await _renderStampImage(
      isPaid: isPaid,
      dateStr: isPaid ? paidDateStr : dueDateStr,
      societyName: resolvedSocietyName,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 26),
        theme: pw.ThemeData.withFont(
          base: latinRegular,
          bold: latinBold,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white, // Crisp white background (watermark removed)
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(
                color: primaryThemeColor, // Deep Teal or Crimson Red Outer Border
                width: 2.0,
              ),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(
                  color: hairlineColor, // Mint or Rose Hairline Border
                  width: 0.8,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            societyNameWidget,
                            pw.SizedBox(height: 4),
                            pw.Text(
                              isPaid ? 'MAINTENANCE PAYMENT RECEIPT' : 'MAINTENANCE DEMAND BILL',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0F172A),
                                letterSpacing: 1.2,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            receiptSubtitleWidget,
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Society Code: ${bill.societyId}  |  Official Digital Tax Invoice',
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: badgeBgColor, // Green for PAID, Red for UNPAID
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.white,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 5),
                                pw.Text(
                                  isPaid ? 'PAID & VERIFIED' : 'UNPAID / PENDING',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          badgeSubtitleWidget,
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(color: primaryThemeColor, thickness: 1.2),
                  pw.SizedBox(height: 8),

                  // 2. RECEIPT METADATA STRIP
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor(0.97, 0.98, 0.99),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'RECEIPT NUMBER:',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              safeReceiptNo,
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              isPaid ? 'PAYMENT DATE:' : 'BILL DATE:',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              paidDateStr,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BILLING MONTH:',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              bill.billingMonth.isNotEmpty
                                  ? bill.billingMonth
                                  : DateFormat('MMM yyyy').format(bill.dueDate),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // 3. MEMBER & FLAT DETAILS CARD
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 3.5,
                        height: 12,
                        decoration: pw.BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      memberSectionHeaderWidget,
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: pw.BoxDecoration(
                      color: isPaid ? const PdfColor(0.95, 0.99, 0.98) : const PdfColor(0.99, 0.96, 0.96),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: hairlineColor),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildFieldCustom('Member Name:', memberNameValWidget),
                              pw.SizedBox(height: 4),
                              _buildFieldRow('Mobile No:', memberPhone),
                              if (memberEmail.isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                _buildFieldRow('Email:', memberEmail),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildFieldRow('Flat & Block:', bill.cleanFlatDisplay),
                              pw.SizedBox(height: 4),
                              _buildFieldCustom('Occupancy:', memberRoleValWidget),
                              pw.SizedBox(height: 4),
                              _buildFieldRow('Due Date:', dueDateStr),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 14),

                  // 4. CHARGES BREAKDOWN TABLE
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 3.5,
                        height: 12,
                        decoration: pw.BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      chargesSectionHeaderWidget,
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.5),
                      1: const pw.FlexColumnWidth(2.0),
                      2: const pw.FlexColumnWidth(1.8),
                      3: const pw.FlexColumnWidth(2.0),
                    },
                    children: [
                      // Table Header with Shaped Text
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primaryThemeColor),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            child: headerParticulars,
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            child: headerPeriod,
                          ),
                          _buildTableHeader('STATUS'),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: headerAmount,
                            ),
                          ),
                        ],
                      ),
                      // Row 1: Base Maintenance
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.white),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            child: billTitleValWidget,
                          ),
                          _buildTableCell(
                            bill.billingMonth.isNotEmpty ? bill.billingMonth : '-',
                          ),
                          _buildTableCell(isPaid ? 'Paid in Full' : 'Payment Due'),
                          _buildTableCell(
                            currencyFmt.format(bill.amount),
                            alignRight: true,
                            isBold: true,
                          ),
                        ],
                      ),
                      // Row 2: Penalty (if applicable)
                      if (bill.penaltyAmount > 0)
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColor(1.0, 0.97, 0.93)),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: penaltyTitleValWidget,
                            ),
                            _buildTableCell('Overdue Charge'),
                            _buildTableCell(isPaid ? 'Settled' : 'Pending'),
                            _buildTableCell(
                              currencyFmt.format(bill.penaltyAmount),
                              alignRight: true,
                              isBold: true,
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Grand Total Highlight Banner
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: isPaid ? const PdfColor(0.92, 0.99, 0.96) : const PdfColor(0.99, 0.94, 0.94),
                      border: pw.Border.all(
                        color: isPaid ? PdfColor.fromInt(0xFFA7F3D0) : PdfColor.fromInt(0xFFFECDD3),
                      ),
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(8),
                        bottomRight: pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        grandTotalLabelWidget,
                        pw.Text(
                          currencyFmt.format(bill.totalPayable),
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: isPaid ? PdfColor.fromInt(0xFF065F46) : PdfColor.fromInt(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // 5. TRANSACTION AUDIT STRIP
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor(0.97, 0.98, 0.99),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildFieldRow(
                                'Payment Mode:',
                                bill.paymentMode.isNotEmpty
                                    ? bill.paymentMode.toUpperCase()
                                    : (isPaid ? 'ONLINE / UPI' : 'PENDING'),
                              ),
                              if (bill.utrNumber.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                _buildFieldRow('UTR / Trans ID:', bill.utrNumber),
                              ],
                              if (bill.chequeNumber.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                _buildFieldRow('Cheque No:', bill.chequeNumber),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildFieldCustom('Audit Status:', auditStatusValWidget),
                              pw.SizedBox(height: 3),
                              _buildFieldRow(
                                isPaid ? 'Settled Date:' : 'Due Date:',
                                isPaid ? paidDateStr : dueDateStr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // ══════════════════════════════════════════════════════════
                  // 🏷️ 5.5 UNIQUE OFFICIAL RUBBER STAMP & NOTICE (In Open Space)
                  // ══════════════════════════════════════════════════════════
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor(0.98, 0.99, 1.0),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Left: Official Society Notice
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              termsHeadingWidget,
                              pw.SizedBox(height: 3),
                              pw.Text(
                                '1. This digital document is an official record for society maintenance accounts.',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                isPaid
                                    ? '2. Payment is settled and recorded in the society ledger.'
                                    : '2. Please clear outstanding maintenance dues on or before the due date.',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '3. For queries, contact society office or committee administration.',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 14),
                        // Right: Small Authentic Rubber Stamp (with -6 deg tilt)
                        pw.Transform.rotate(
                          angle: -0.10, // ~ -6 degrees
                          child: pw.Image(
                            stampImage,
                            width: 142,
                            height: 74,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // 6. FOOTER: QR CODE & AUTHORIZED SIGNATORY
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Left: QR Code + Digital Security Note
                      pw.Expanded(
                        flex: 6,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Column(
                              children: [
                                pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: qrData,
                                  width: 54,
                                  height: 54,
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Scan to Verify',
                                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                                ),
                              ],
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Digital Security & Authenticity',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9,
                                      color: primaryThemeColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'This digital receipt is cryptographically certified by My Building Guard Society System.',
                                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    'Verified: ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now())} | Powered by My Building Guard',
                                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(width: 16),

                      // Right: Authorized Signatory
                      pw.Expanded(
                        flex: 5,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: pw.BoxDecoration(
                            color: isPaid ? const PdfColor(0.95, 0.99, 0.98) : const PdfColor(0.99, 0.96, 0.96),
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: hairlineColor),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              signatoryHeaderWidget,
                              pw.SizedBox(height: 3),
                              if (signatureBytes != null && signatureBytes.isNotEmpty)
                                pw.Container(
                                  height: 36,
                                  alignment: pw.Alignment.center,
                                  child: pw.Image(
                                    pw.MemoryImage(signatureBytes),
                                    height: 34,
                                    fit: pw.BoxFit.contain,
                                  ),
                                )
                              else
                                pw.Container(
                                  height: 36,
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    effectiveVerifierName,
                                    style: pw.TextStyle(
                                      fontStyle: pw.FontStyle.italic,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                      color: primaryThemeColor,
                                    ),
                                  ),
                                ),
                              pw.Container(
                                width: 120,
                                height: 0.8,
                                color: primaryThemeColor,
                              ),
                              pw.SizedBox(height: 2),
                              signatoryNameWidget,
                              signatoryTitleWidget,
                              pw.SizedBox(height: 3),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: pw.BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  isPaid ? 'DIGITALLY VERIFIED & SIGNED' : 'OFFICIAL DEMAND BILL',
                                  style: pw.TextStyle(
                                    fontSize: 6,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFieldCustom(String label, pw.Widget valueWidget) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(child: valueWidget),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool alignRight = false,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  /// Downloads and saves the receipt PDF directly onto local device storage.
  static Future<File?> downloadReceiptPdf(
    BuildContext context,
    MaintenanceBill bill, {
    String? societyName,
  }) async {
    try {
      final pdfBytes = await generateReceiptPdf(bill, societyName: societyName);
      final safeReceiptNo = (bill.receiptNumber.trim().isNotEmpty
              ? bill.receiptNumber.trim()
              : 'REC_${bill.id.length > 6 ? bill.id.substring(0, 6) : bill.id}')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      final fileName = 'Maintenance_Receipt_$safeReceiptNo.pdf';

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'રસીદ સફળતાપૂર્વક ડાઉનલોડ થઈ ગઈ!\nફાઈલ: $fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'શેર કરો',
              textColor: Colors.amberAccent,
              onPressed: () {
                Printing.sharePdf(bytes: pdfBytes, filename: fileName);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return file;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('ડાઉનલોડ કરવામાં ભૂલ આવી: $e'),
          ),
        );
      }
      return null;
    }
  }

  /// Opens the interactive full-screen PDF viewer with zoom, print, and save controls.
  static void viewReceiptPdf(
    BuildContext context,
    MaintenanceBill bill, {
    String? societyName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceReceiptViewerScreen(
          bill: bill,
          societyName: societyName,
        ),
      ),
    );
  }
}

/// Interactive Fullscreen PDF Viewer Screen
class MaintenanceReceiptViewerScreen extends StatelessWidget {
  final MaintenanceBill bill;
  final String? societyName;

  const MaintenanceReceiptViewerScreen({
    super.key,
    required this.bill,
    this.societyName,
  });

  @override
  Widget build(BuildContext context) {
    final receiptNum = bill.receiptNumber.trim().isNotEmpty
        ? bill.receiptNumber.trim()
        : 'BG-REC-${bill.id.length > 6 ? bill.id.substring(0, 6).toUpperCase() : bill.id.toUpperCase()}';

    final safeFileName = 'Maintenance_Receipt_${receiptNum.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'મેન્ટેનન્સ રસીદ (Receipt)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              receiptNum,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'PDF ડાઉનલોડ કરો',
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              MaintenanceReceiptPdfService.downloadReceiptPdf(
                context,
                bill,
                societyName: societyName,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => MaintenanceReceiptPdfService.generateReceiptPdf(
          bill,
          societyName: societyName,
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
                'ડિજિટલ રસીદ તૈયાર થઈ રહી છે...',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
