import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  /// Generates the PDF binary bytes for a verified/paid Maintenance Bill.
  static Future<Uint8List> generateReceiptPdf(
    MaintenanceBill bill, {
    String? societyName,
  }) async {
    final pdf = pw.Document();

    // Fetch society name if not provided
    final resolvedSocietyName = societyName?.trim().isNotEmpty == true
        ? societyName!
        : await getSocietyName(bill.societyId);

    // Font loading with fallback for Gujarati & English support
    pw.Font regularFont;
    pw.Font boldFont;
    try {
      regularFont = await PdfGoogleFonts.notoSansGujaratiRegular();
      boldFont = await PdfGoogleFonts.notoSansGujaratiBold();
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
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

    final qrData = 'MyBuildingGuard|REC:$safeReceiptNo|FLAT:${bill.flatDisplay}|'
        'AMOUNT:${bill.totalPayable}|DATE:$paidDateStr|SOC:${bill.societyId}';

    // Fetch society settings for digital signature and signatory details
    Uint8List? signatureBytes;
    String signatoryName = '';
    String signatoryTitle = 'સોસાયટી એડમિન / ચેરમેન';

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
            ? 'સોસાયટી એડમિન / ચેરમેન'
            : rawVerifier);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal800, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. HEADER SECTION
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            resolvedSocietyName,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'મેન્ટેનન્સ ચુકવણી ડિજિટલ રસીદ',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal800,
                            ),
                          ),
                          pw.Text(
                            'MAINTENANCE PAYMENT RECEIPT',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Society ID: ${bill.societyId}',
                            style: const pw.TextStyle(
                              fontSize: 9,
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
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green700,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            'PAID & VERIFIED',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'ડિજિટલી પ્રમાણિત',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.teal700, thickness: 1.5),
                pw.SizedBox(height: 12),

                // 2. RECEIPT METADATA BAR
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('રસીદ નં (Receipt No):',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            safeReceiptNo,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ચુકવણી તારીખ (Payment Date):',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            paidDateStr,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('બિલિંગ મહિનો (Month):',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            bill.billingMonth.isNotEmpty
                                ? bill.billingMonth
                                : DateFormat('MMM yyyy').format(bill.dueDate),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // 3. MEMBER & FLAT DETAILS
                pw.Text(
                  'સભ્ય & ફ્લેટ વિગતો (Member & Unit Details)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.teal200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('સભ્યનું નામ:', bill.memberName.isNotEmpty ? bill.memberName : 'મેમ્બર'),
                            pw.SizedBox(height: 6),
                            _buildInfoRow('મોબાઇલ નંબર:', bill.memberPhone.isNotEmpty ? bill.memberPhone : '-'),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('ફ્લેટ / મકાન નં:', bill.flatDisplay),
                            pw.SizedBox(height: 6),
                            _buildInfoRow('છેલ્લી તારીખ:', dueDateStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // 4. FINANCIAL CHARGES TABLE
                pw.Text(
                  'ચુકવણી વિગતો (Charges Breakdown)',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                      children: [
                        _buildTableHeader('વિગત (Particulars)'),
                        _buildTableHeader('મહિનો / મુદત (Period)'),
                        _buildTableHeader('રકમ (Amount)', alignRight: true),
                      ],
                    ),
                    // Base Amount
                    pw.TableRow(
                      children: [
                        _buildTableCell(bill.billTitle),
                        _buildTableCell(bill.billingMonth.isNotEmpty ? bill.billingMonth : '-'),
                        _buildTableCell(currencyFmt.format(bill.amount), alignRight: true),
                      ],
                    ),
                    // Penalty if applicable
                    if (bill.penaltyAmount > 0)
                      pw.TableRow(
                        children: [
                          _buildTableCell('મુદતવીતી દંડ (Late Fee / Penalty)'),
                          _buildTableCell('ઓવરડ્યુ ચાર્જ'),
                          _buildTableCell(currencyFmt.format(bill.penaltyAmount), alignRight: true),
                        ],
                      ),
                    // Total Paid Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'કુલ ચૂકવેલ રકમ (TOTAL PAID)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'સંપૂર્ણ ચૂકતે (Full Payment)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            currencyFmt.format(bill.totalPayable),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // 5. TRANSACTION SETTLEMENT DETAILS
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'ચુકવણી પદ્ધતિ (Mode):',
                              bill.paymentMode.isNotEmpty
                                  ? bill.paymentMode.toUpperCase()
                                  : 'ONLINE / UPI',
                            ),
                            if (bill.utrNumber.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              _buildInfoRow('UTR / ટ્રાન્ઝેક્શન નં:', bill.utrNumber),
                            ],
                            if (bill.chequeNumber.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              _buildInfoRow('ચેક નંબર:', bill.chequeNumber),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('ચકાસણી સ્થિતિ:', 'સફળતાપૂર્વક જમા (VERIFIED)'),
                            pw.SizedBox(height: 4),
                            _buildInfoRow('ચકાસણી તારીખ:', paidDateStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // 6. FOOTER WITH QR CODE & AUTHORIZED DIGITAL SIGNATURE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Left Column: QR Code + Digital Security Note
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
                                width: 56,
                                height: 56,
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'સ્કેન કરી ચકાસો',
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '🔒 ડિજિટલ સિક્યોરિટી & માન્યતા:',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9.5,
                                    color: PdfColors.teal900,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'આ ડિજિટલ રસીદ My Building Guard સુરક્ષા પ્રણાલી દ્વારા કાયદેસર અને આપમેળે પ્રમાણિત છે. QR કોડ સ્કેન કરીને વિગતો વેરિફાય કરી શકો છો.',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'જનરેટ: ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now())} • Powered by My Building Guard',
                                  style: const pw.TextStyle(
                                    fontSize: 7,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 20),

                    // Right Column: Official Authorized Digital Signature
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal50,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(color: PdfColors.teal200, width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'અધિકૃત ડિજિટલ સહી (Authorized)',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal900,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            if (signatureBytes != null && signatureBytes.isNotEmpty)
                              pw.Container(
                                height: 38,
                                alignment: pw.Alignment.center,
                                child: pw.Image(
                                  pw.MemoryImage(signatureBytes),
                                  height: 36,
                                  fit: pw.BoxFit.contain,
                                ),
                              )
                            else
                              pw.Container(
                                height: 38,
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  effectiveVerifierName,
                                  style: pw.TextStyle(
                                    fontStyle: pw.FontStyle.italic,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    color: PdfColors.teal900,
                                  ),
                                ),
                              ),
                            pw.Container(
                              width: 140,
                              height: 1,
                              color: PdfColors.teal700,
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              effectiveVerifierName,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.Text(
                              signatoryTitle,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green700,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                '✓ DIGITALLY VERIFIED & SIGNED',
                                style: pw.TextStyle(
                                  fontSize: 6.5,
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
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9.5,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(
          fontSize: 10,
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
