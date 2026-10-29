import 'dart:async';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';
import '../services/society_service.dart';
import '../services/maintenance_receipt_pdf_service.dart';
import 'package:building_guard/l10n/app_strings.dart';

/// Modular maintenance widgets & sheets for Resident/Member Screen.
class MemberMaintenanceSheet {
  /// Live alert banner displayed on resident dashboard if there are unpaid bills.
  static Widget buildMaintenanceBanner(
    BuildContext context, {
    required String currentUserId,
  }) {
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('maintenance_bills')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .where('memberId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final bills = snapshot.data!.docs
            .map((d) => MaintenanceBill.fromFirestore(d))
            .toList();

        final unpaid =
            bills.where((b) => b.status != MaintenanceStatus.paid).toList();
        if (unpaid.isEmpty) return const SizedBox.shrink();

        final bill = unpaid.first;
        final isReview = bill.status == MaintenanceStatus.underReview;
        final isOverdue = bill.status == MaintenanceStatus.overdue;

        final bannerColor = isReview
            ? const Color(0xFF1E40AF)
            : (isOverdue ? const Color(0xFFB91C1C) : const Color(0xFF0F766E));

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bannerColor, bannerColor.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bannerColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  isReview
                      ? Icons.hourglass_top_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isReview
                          ? 'UPI પેમેન્ટ ચકાસણી હેઠળ છે'.tr
                          : 'બાકી: ${currencyFmt.format(bill.totalPayable)} • છેલ્લી તા: ${DateFormat("dd/MM").format(bill.dueDate)}'.tr,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => showMaintenancePortal(
                  context,
                  currentUserId: currentUserId,
                  initialBill: bill,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bannerColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  isReview ? 'વિગત'.tr : 'હમણાં ચૂકવો'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens the Maintenance Portal modal bottom sheet with Pay & History tabs.
  static Future<void> showMaintenancePortal(
    BuildContext context, {
    required String currentUserId,
    MaintenanceBill? initialBill,
  }) async {
    final settings = await MaintenanceService.instance.getPaymentSettings();
    final societyName = await MaintenanceReceiptPdfService.getSocietyName(
      SocietyService.instance.societyId,
    );

    // Fetch user details for unit/block matching and auto-linking
    String userBlock = '';
    String userUnit = '';
    String userName = '';
    String userPhone = '';
    try {
      final userDoc = await AppFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get()
          .timeout(const Duration(seconds: 2));
      final uData = userDoc.data() ?? {};
      userBlock = (uData['blockName'] ?? '').toString().trim();
      userUnit = (uData['unitNumber'] ?? '').toString().trim();
      userName = (uData['name'] ?? '').toString().trim();
      userPhone = (uData['phone'] ?? '').toString().trim();
    } catch (_) {}

    // Link any unassigned bills for this unit in the background
    if (userUnit.isNotEmpty) {
      unawaited(MaintenanceService.instance.linkMemberBillsIfUnassigned(
        currentUserId: currentUserId,
        blockName: userBlock,
        unitNumber: userUnit,
        memberName: userName,
        memberPhone: userPhone,
      ));
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberMaintenanceSheetContent(
        currentUserId: currentUserId,
        initialBill: initialBill,
        settings: settings,
        societyName: societyName,
        userBlock: userBlock,
        userUnit: userUnit,
      ),
    );
  }

  /// Shows digital receipt dialog for paid maintenance bill with full PDF view and download actions.
  static void showReceiptDialog(
    BuildContext context,
    MaintenanceBill bill, {
    String? societyName,
  }) {
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final paidDate = bill.paidAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(bill.paidAt!)
        : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0F766E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'મેન્ટેનન્સ ચુકવણી રસીદ'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bill.receiptNumber.isNotEmpty
                              ? 'રસીદ નં: ${bill.receiptNumber}'.tr
                              : 'ડિજિટલ રસીદ'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount highlight card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ચૂકવેલ રકમ (PAID)'.tr,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFmt.format(bill.totalPayable),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'સફળતાપૂર્વક પ્રમાણિત (VERIFIED)'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Details box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _receiptItem('બિલિંગ મહિનો'.tr, bill.billTitle),
                    _receiptItem('ફ્લેટ / યુનિટ'.tr, bill.flatDisplay),
                    _receiptItem('સભ્યનું નામ'.tr, bill.memberName.isNotEmpty ? bill.memberName : '-'),
                    _receiptItem('ચુકવણી પદ્ધતિ'.tr, bill.paymentMode.isNotEmpty ? bill.paymentMode.toUpperCase() : 'UPI'),
                    if (bill.utrNumber.isNotEmpty)
                      _receiptItem('UTR / ટ્રાન્ઝેક્શન નં'.tr, bill.utrNumber),
                    if (bill.chequeNumber.isNotEmpty)
                      _receiptItem('ચેક નંબર'.tr, bill.chequeNumber),
                    _receiptItem('ચુકવણી તારીખ'.tr, paidDate),
                    if (bill.verifiedBy.isNotEmpty)
                      _receiptItem(
                        'ચકાસણી કરનાર'.tr,
                        (bill.verifiedBy.trim().toLowerCase() == 'admin' ||
                                (bill.verifiedBy.trim().length >= 20 &&
                                    !bill.verifiedBy.trim().contains(' ')))
                            ? 'સોસાયટી એડમિન'.tr
                            : bill.verifiedBy.trim(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        MaintenanceReceiptPdfService.viewReceiptPdf(
                          context,
                          bill,
                          societyName: societyName,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text('PDF જુઓ'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        MaintenanceReceiptPdfService.downloadReceiptPdf(
                          context,
                          bill,
                          societyName: societyName,
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: Text('PDF ડાઉનલોડ'.tr),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      final pdfBytes =
                          await MaintenanceReceiptPdfService.generateReceiptPdf(
                        bill,
                        societyName: societyName,
                      );
                      final safeReceiptNo = (bill.receiptNumber.trim().isNotEmpty
                              ? bill.receiptNumber.trim()
                              : 'REC_${bill.id.length > 6 ? bill.id.substring(0, 6) : bill.id}')
                          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename: 'Maintenance_Receipt_$safeReceiptNo.pdf',
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text('રસીદ PDF શેર કરો (Share)'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _receiptItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Content widget for the maintenance portal bottom sheet with TabController.
class _MemberMaintenanceSheetContent extends StatefulWidget {
  final String currentUserId;
  final MaintenanceBill? initialBill;
  final Map<String, dynamic> settings;
  final String societyName;
  final String userBlock;
  final String userUnit;

  const _MemberMaintenanceSheetContent({
    required this.currentUserId,
    this.initialBill,
    required this.settings,
    required this.societyName,
    this.userBlock = '',
    this.userUnit = '',
  });

  @override
  State<_MemberMaintenanceSheetContent> createState() =>
      _MemberMaintenanceSheetContentState();
}

class _MemberMaintenanceSheetContentState
    extends State<_MemberMaintenanceSheetContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _utrController;
  late final Stream<List<MaintenanceBill>> _billsStream;
  final currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final startsAtHistory = widget.initialBill != null &&
        widget.initialBill!.status == MaintenanceStatus.paid;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: startsAtHistory ? 1 : 0,
    );
    _utrController = TextEditingController();
    _billsStream = _createBillsStream();
  }

  Stream<List<MaintenanceBill>> _createBillsStream() {
    final societyId = SocietyService.instance.societyId;
    final streamMember = AppFirestore.instance
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: societyId)
        .where('memberId', isEqualTo: widget.currentUserId)
        .snapshots();

    if (widget.userUnit.trim().isEmpty) {
      return streamMember.map((snap) => snap.docs
          .map((d) => MaintenanceBill.fromFirestore(d))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }

    final streamUnit = AppFirestore.instance
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: societyId)
        .where('unitNumber', isEqualTo: widget.userUnit.trim())
        .snapshots();

    final cleanUserBlock =
        SocietyService.instance.logicalBlockName(widget.userBlock);
    final controller = StreamController<List<MaintenanceBill>>.broadcast();
    final Map<String, MaintenanceBill> memberBills = {};
    final Map<String, MaintenanceBill> unitBills = {};

    void emitCombined() {
      if (controller.isClosed) return;
      final Map<String, MaintenanceBill> all = Map.from(memberBills);
      for (final entry in unitBills.entries) {
        final b = entry.value;
        final cleanB = b.cleanBlockName;
        if (cleanUserBlock.isEmpty ||
            cleanB == cleanUserBlock ||
            b.blockName == widget.userBlock ||
            cleanUserBlock == b.blockName) {
          all[entry.key] = b;
        }
      }
      final sorted = all.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(sorted);
    }

    StreamSubscription? sub1;
    StreamSubscription? sub2;

    sub1 = streamMember.listen((snap) {
      memberBills.clear();
      for (final d in snap.docs) {
        memberBills[d.id] = MaintenanceBill.fromFirestore(d);
      }
      emitCombined();
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    });

    sub2 = streamUnit.listen((snap) {
      unitBills.clear();
      for (final d in snap.docs) {
        unitBills[d.id] = MaintenanceBill.fromFirestore(d);
      }
      emitCombined();
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    });

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };

    return controller.stream;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upiId = (widget.settings['upiId'] ?? '').toString().trim();
    final payeeName = (widget.settings['upiPayeeName'] ?? 'Society Maintenance')
        .toString()
        .trim();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF0F766E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'મેન્ટેનન્સ & ઓનલાઇન પેમેન્ટ'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${widget.societyName} • ડિજિટલ રસીદો'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: Colors.grey.shade700,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Modern Pill TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF475569),
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Icon(Icons.payment_rounded, size: 18),
                    text: 'ચુકવણી (Pay)'.tr,
                  ),
                  Tab(
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'ઇતિહાસ & રસીદો'.tr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Views with Live Bills Stream
            Expanded(
              child: StreamBuilder<List<MaintenanceBill>>(
                stream: _billsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                    );
                  }

                  final bills = snapshot.data ?? [];

                  final unpaid = bills
                      .where((b) => b.status != MaintenanceStatus.paid)
                      .toList();

                  final paidBills = bills
                      .where((b) => b.status == MaintenanceStatus.paid)
                      .toList();

                  final latestPaidBill =
                      paidBills.isNotEmpty ? paidBills.first : null;

                  final activeBill = widget.initialBill ??
                      (unpaid.isNotEmpty ? unpaid.first : null);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: PAY / ALL-CLEAR SCREEN
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: activeBill == null ||
                                activeBill.status == MaintenanceStatus.paid
                            ? _buildAllClearView(
                                context,
                                latestPaidBill: latestPaidBill,
                                totalPaidCount: paidBills.length,
                              )
                            : _buildActiveBillPaySection(
                                context: context,
                                bill: activeBill,
                                upiId: upiId,
                                payeeName: payeeName,
                                currencyFmt: currencyFmt,
                                utrController: _utrController,
                                parentCtx: context,
                              ),
                      ),

                      // TAB 2: HISTORY & RECEIPTS
                      bills.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'હજુ સુધી કોઈ બિલ કે રસીદ મળી નથી.'.tr,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'સોસાયટી દ્વારા બિલ જનરેટ થશે ત્યારે અહીં લિસ્ટ થશે.'.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                final b = bills[index];
                                return _buildHistoryBillCard(
                                  context: context,
                                  bill: b,
                                  currencyFmt: currencyFmt,
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ultra-Premium All-Clear Status View with Quick Access to Latest Paid Receipt PDF
  Widget _buildAllClearView(
    BuildContext context, {
    required MaintenanceBill? latestPaidBill,
    required int totalPaidCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. HERO CELEBRATION BANNER
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA7F3D0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '🎉 તમામ મેન્ટેનન્સ બિલ ચૂકવાઈ ગયા છે!'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'તમારું કોઈ બાકી લેણું નથી • સોસાયટી ખાતું સંપૂર્ણ ક્લિયર છે.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 5),
                    Text(
                      'STATUS: ZERO DUES PENDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. LATEST PAID RECEIPT CARD (With View & Download PDF buttons)
        if (latestPaidBill != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF0F766E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'છેલ્લી ચુકવણીની રસીદ'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            latestPaidBill.receiptNumber.isNotEmpty
                                ? 'રસીદ નં: ${latestPaidBill.receiptNumber}'.tr
                                : 'ડિજિટલ વેરિફાઇડ રસીદ'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'PAID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 22),

                // Bill Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestPaidBill.billTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ફ્લેટ: ${latestPaidBill.flatDisplay}'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            latestPaidBill.paidAt != null
                                ? 'તારીખ: ${DateFormat('dd MMM yyyy, hh:mm a').format(latestPaidBill.paidAt!)}'
                                : '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFmt.format(latestPaidBill.totalPayable),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        Text(
                          latestPaidBill.paymentMode.isNotEmpty
                              ? latestPaidBill.paymentMode.toUpperCase()
                              : 'ONLINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (latestPaidBill.utrNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'UTR: ${latestPaidBill.utrNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 2 Action Buttons: View PDF & Download PDF
                Row(
                  children: [
                    // Button 1: View Receipt PDF
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          MaintenanceReceiptPdfService.viewReceiptPdf(
                            context,
                            latestPaidBill,
                            societyName: widget.societyName,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text('રસીદ PDF જુઓ'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(
                              color: Color(0xFF0F766E), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Button 2: Download Receipt PDF
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          MaintenanceReceiptPdfService.downloadReceiptPdf(
                            context,
                            latestPaidBill,
                            societyName: widget.societyName,
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('PDF ડાઉનલોડ'.tr),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. JUMP TO HISTORY TAB SHORTCUT
        InkWell(
          onTap: () => _tabController.animateTo(1),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'બધી જૂની રસીદો & ઇતિહાસ જુઓ'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$totalPaidCount રસીદો ઉપલબ્ધ છે • ક્લિક કરી વિગત જુઓ'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// History Card for Tab 2
  Widget _buildHistoryBillCard({
    required BuildContext context,
    required MaintenanceBill bill,
    required NumberFormat currencyFmt,
  }) {
    final isPaid = bill.status == MaintenanceStatus.paid;
    final isReview = bill.status == MaintenanceStatus.underReview;

    final paidDate = bill.paidAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(bill.paidAt!)
        : DateFormat('dd MMM yyyy').format(bill.dueDate);

    // Payment mode styling
    final modeLower = bill.paymentMode.toLowerCase().trim();
    IconData modeIcon = Icons.payment_rounded;
    Color modeColor = const Color(0xFF475569);
    Color modeBg = const Color(0xFFF1F5F9);

    if (modeLower.contains('cash')) {
      modeIcon = Icons.payments_rounded;
      modeColor = const Color(0xFFB45309);
      modeBg = const Color(0xFFFEF3C7);
    } else if (modeLower.contains('online') || modeLower.contains('upi')) {
      modeIcon = Icons.account_balance_rounded;
      modeColor = const Color(0xFF0284C7);
      modeBg = const Color(0xFFE0F2FE);
    } else if (modeLower.contains('cheque')) {
      modeIcon = Icons.receipt_long_rounded;
      modeColor = const Color(0xFF7E22CE);
      modeBg = const Color(0xFFF3E8FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF0F766E).withValues(alpha: 0.18)
              : (isReview
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                  : const Color(0xFFEF4444).withValues(alpha: 0.25)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPaid
                ? const Color(0xFF0F766E).withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status Icon, Title & Date, Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPaid
                          ? const [Color(0xFFE6FFFA), Color(0xFFCCFBF1)]
                          : (isReview
                              ? [Colors.blue.shade50, Colors.blue.shade100]
                              : [Colors.red.shade50, Colors.red.shade100]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPaid
                        ? Icons.verified_rounded
                        : (isReview
                            ? Icons.hourglass_top_rounded
                            : Icons.warning_amber_rounded),
                    color: isPaid
                        ? const Color(0xFF0F766E)
                        : (isReview ? Colors.blue.shade800 : Colors.red.shade700),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isPaid
                                ? Icons.event_available_rounded
                                : Icons.schedule_rounded,
                            size: 12,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isPaid ? paidDate : 'મુદત: $paidDate'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPaid
                          ? 'ચૂકવેલ'.tr
                          : (isReview ? 'ચકાસણી હેઠળ'.tr : 'બાકી રકમ'.tr),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currencyFmt.format(bill.totalPayable),
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: isPaid
                            ? const Color(0xFF0F766E)
                            : (isReview
                                ? Colors.blue.shade900
                                : Colors.red.shade800),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Receipt & Payment Details Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 13,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      bill.receiptNumber.isNotEmpty
                          ? 'રસીદ: ${bill.receiptNumber}'.tr
                          : (bill.isPaid
                              ? 'ડિજિટલ વેરિફાઇડ રસીદ'.tr
                              : 'બિલ નં: ${bill.id.length > 8 ? bill.id.substring(0, 8) : bill.id}'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: modeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(modeIcon, size: 10, color: modeColor),
                        const SizedBox(width: 3),
                        Text(
                          bill.paymentMode.isNotEmpty
                              ? bill.paymentMode.toUpperCase()
                              : 'ONLINE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: modeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bill.utrNumber.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'UTR: ${bill.utrNumber.length > 6 ? "${bill.utrNumber.substring(0, 6)}.." : bill.utrNumber}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontFamily: 'monospace',
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isPaid) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // View Receipt PDF
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MaintenanceReceiptPdfService.viewReceiptPdf(
                            context,
                            bill,
                            societyName: widget.societyName,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 14,
                                color: Color(0xFF059669),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'જુઓ'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Download Receipt PDF
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MaintenanceReceiptPdfService.downloadReceiptPdf(
                            context,
                            bill,
                            societyName: widget.societyName,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ડાઉનલોડ'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isReview) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.blue.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'UTR: ${bill.utrNumber} • એડમિન ચકાસણી હેઠળ છે.'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.payment_rounded, size: 15),
                  label: Text('હમણાં ચૂકવો (Pay Now)'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBillPaySection({
    required BuildContext context,
    required MaintenanceBill bill,
    required String upiId,
    required String payeeName,
    required NumberFormat currencyFmt,
    required TextEditingController utrController,
    required BuildContext parentCtx,
  }) {
    final uri = MaintenanceService.instance.buildUpiUri(
      upiId: upiId,
      payeeName: payeeName,
      amount: bill.totalPayable,
      note: '${bill.billTitle} - Flat ${bill.flatDisplay}',
    );

    if (bill.status == MaintenanceStatus.underReview) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.hourglass_bottom_rounded,
                size: 52, color: Colors.blue.shade800),
            const SizedBox(height: 12),
            Text(
              'UPI પેમેન્ટ ચકાસણી હેઠળ છે'.tr,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'તમારો સબમિટ થયેલ UTR: ${bill.utrNumber}\nરકમ: ${currencyFmt.format(bill.totalPayable)}'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'ચેરમેન/એડમિન આ રકમ વેરિફાય કરશે એટલે તરત જ તમને ડિજિટલ રસીદ મળી જશે અને PDF ડાઉનલોડ થઈ શકશે.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bill Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF99F6E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.billTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bill.status.labelGujarati,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'કુલ ચૂકવવાપાત્ર: ${currencyFmt.format(bill.totalPayable)}'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'છેલ્લી તારીખ: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (upiId.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'સોસાયટી દ્વારા હજુ સુધી UPI ID સેટ કરવામાં આવ્યો નથી. કૃપા કરીને એડમિનનો સંપર્ક કરી રોકડ અથવા ચેકથી ચુકવણી કરો.'.tr,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 1-Tap UPI Pay Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'UPI એપ ખૂલી શકી નથી. નીચે આપેલ QR કોડ સ્કેન કરો.'.tr,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ભૂલ: $e'.tr)),
                    );
                  }
                }
              },
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: Text(
                'Google Pay / PhonePe થી ચૂકવો (1-Tap)'.tr,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // QR Code Container
          Center(
            child: Column(
              children: [
                Text(
                  'અથવા અન્ય મોબાઈલથી સ્કેન કરો:'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: QrImageView(
                      data: uri.toString(),
                      version: QrVersions.auto,
                      size: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'UPI ID: $upiId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 28),

          // UTR Input Field
          Text(
            'પેમેન્ટ કર્યા પછી અહીં UTR નંબર દાખલ કરો:'.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: utrController,
            decoration: InputDecoration(
              labelText: '૧૨-આંકડાનો UTR / ટ્રાન્ઝેક્શન નંબર *'.tr,
              hintText: 'દા.ત. 4289XXXXXXXX'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.receipt_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                final utr = utrController.text.trim();
                if (utr.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('કૃપા કરીને માન્ય UTR નંબર દાખલ કરો'.tr),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                await MaintenanceService.instance.submitUpiPayment(
                  billId: bill.id,
                  utrNumber: utr,
                );

                if (parentCtx.mounted) {
                  Navigator.pop(parentCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('UPI પેમેન્ટ વેરિફિકેશન માટે સબમિટ થઈ ગયું!'.tr),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'ચુકવણી કન્ફર્મ કરો'.tr,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
