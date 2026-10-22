import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_model.dart';
import '../models/user_model.dart';
import '../services/maintenance_reminder_service.dart';
import '../services/maintenance_service.dart';
import '../services/society_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartMaintenanceReminderSheet {
  // =========================================================================
  // ૧. સિંગલ બિલ માટે WhatsApp & પુશ રિમાઇન્ડર શીટ
  // =========================================================================
  static Future<void> showSingle({
    required BuildContext context,
    required MaintenanceBill bill,
    String? societyNameOverride,
  }) async {
    final service = MaintenanceReminderService.instance;
    final paymentSettings = await MaintenanceService.instance.getPaymentSettings();
    final upiId = (paymentSettings['upiId'] ?? '').toString().trim();
    final upiPayee = (paymentSettings['upiPayeeName'] ?? '').toString().trim();
    final societyName = societyNameOverride ?? SocietyService.instance.societyName;

    final customNoteController = TextEditingController();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final messagePreview = service.buildWhatsAppReminderMessage(
            bill: bill,
            societyName: societyName,
            upiId: upiId,
            upiPayeeName: upiPayee,
            customNote: customNoteController.text,
          );

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'સ્માર્ટ મેન્ટેનન્સ રીમાઇન્ડર',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ફ્લેટ ${bill.cleanFlatDisplay} • ${bill.memberName.isNotEmpty ? bill.memberName : 'સભ્ય'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Body content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bill Summary Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.billTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'છેલ્લી તારીખ: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹ ${bill.totalPayable.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                  const Text(
                                    'બાકી રકમ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB45309),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Custom note input
                        TextField(
                          controller: customNoteController,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: 'ખાસ નોંધ ઉમેરો (વૈકલ્પિક)',
                            hintText: 'દા.ત. કૃપા કરીને સોસાયટી ઓફિસે મળવું...',
                            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Message Preview Title
                        const Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF0F766E)),
                            SizedBox(width: 6),
                            Text(
                              'WhatsApp મેસેજ પ્રિવ્યુ (Message Preview):',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Chat Bubble Preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7FCE8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC7F3C9)),
                          ),
                          child: Text(
                            messagePreview,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Color(0xFF14532D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      // Direct Push Notification button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final sent = await service.sendDirectPushReminder(
                              bill: bill,
                              societyName: societyName,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sent
                                        ? '✅ સભ્યને એપ પુશ નોટિફિકેશન સફળતાપૂર્વક મોકલાઈ ગયું.'
                                        : 'નોટિફિકેશન સેવ થયું (FCM ટોકન ઉપલબ્ધ નહોતું).',
                                  ),
                                  backgroundColor: sent ? const Color(0xFF059669) : Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications_active_rounded, size: 16),
                          label: const Text('એપ પુશ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Direct WhatsApp Launch button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await service.sendSingleWhatsAppReminder(
                              context: context,
                              bill: bill,
                              societyName: societyName,
                              upiId: upiId,
                              upiPayeeName: upiPayee,
                              customNote: customNoteController.text,
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 17, color: Colors.white),
                          label: const Text(
                            'WhatsApp પર મોકલો',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 3,
                            shadowColor: const Color(0xFF25D366).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // ૨. બલ્ક / કતાર WhatsApp & પુશ રિમાઇન્ડર ડેસ્ક (Queue Dispatcher Modal)
  // =========================================================================
  static Future<void> showBatchQueue({
    required BuildContext context,
    required String billingMonth,
    required String monthTitle,
    required List<MaintenanceBill> allBills,
  }) async {
    final pendingBills = allBills
        .where((b) => b.status == MaintenanceStatus.pending || b.status == MaintenanceStatus.overdue)
        .toList();

    if (pendingBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('આ મહિના માટે કોઈ બાકી મેન્ટેનન્સ બિલ નથી.'),
          backgroundColor: Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final service = MaintenanceReminderService.instance;
    final paymentSettings = await MaintenanceService.instance.getPaymentSettings();
    final upiId = (paymentSettings['upiId'] ?? '').toString().trim();
    final upiPayee = (paymentSettings['upiPayeeName'] ?? '').toString().trim();
    final societyName = SocietyService.instance.societyName;

    // Detect user role & wing restrictions
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await AppFirestore.instance.collection('users').doc(currentUserUid).get();
    final userData = userDoc.data() ?? {};
    final currentUser = UserModel.fromMap(userData, currentUserUid);

    String? restrictedBlock;
    if (currentUser.isWingAdmin && !currentUser.isSuperAdmin) {
      restrictedBlock = currentUser.blockName ?? currentUser.subGroup;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BatchQueueSheetWidget(
        pendingBills: pendingBills,
        billingMonth: billingMonth,
        monthTitle: monthTitle,
        societyName: societyName,
        upiId: upiId,
        upiPayee: upiPayee,
        service: service,
        restrictedBlock: restrictedBlock,
      ),
    );
  }
}

class _BatchQueueSheetWidget extends StatefulWidget {
  final List<MaintenanceBill> pendingBills;
  final String billingMonth;
  final String monthTitle;
  final String societyName;
  final String upiId;
  final String upiPayee;
  final MaintenanceReminderService service;
  final String? restrictedBlock;

  const _BatchQueueSheetWidget({
    required this.pendingBills,
    required this.billingMonth,
    required this.monthTitle,
    required this.societyName,
    required this.upiId,
    required this.upiPayee,
    required this.service,
    this.restrictedBlock,
  });

  @override
  State<_BatchQueueSheetWidget> createState() => _BatchQueueSheetWidgetState();
}

class _BatchQueueSheetWidgetState extends State<_BatchQueueSheetWidget> {
  String _selectedBlock = 'all';
  String _searchQuery = '';
  final Set<String> _sentBillIds = {};
  bool _isSendingBulkPush = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.restrictedBlock != null && widget.restrictedBlock!.isNotEmpty) {
      _selectedBlock = widget.restrictedBlock!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _allBlocks {
    final blocks = <String>{};
    for (final b in widget.pendingBills) {
      if (b.cleanBlockName.isNotEmpty) {
        blocks.add(b.cleanBlockName);
      }
    }
    return ['all', ...blocks.toList()..sort()];
  }

  List<MaintenanceBill> get _filteredBills {
    return widget.pendingBills.where((b) {
      if (_selectedBlock != 'all' && b.cleanBlockName != _selectedBlock) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchFlat = b.cleanFlatDisplay.toLowerCase().contains(q);
        final matchName = b.memberName.toLowerCase().contains(q);
        final matchPhone = b.memberPhone.contains(q);
        if (!matchFlat && !matchName && !matchPhone) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBills;
    final totalPendingAmount = filtered.fold<double>(0.0, (acc, b) => acc + b.totalPayable);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'સ્માર્ટ રીમાઇન્ડર કતાર (Queue)',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.monthTitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${filtered.length} બાકી',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Block Selector & Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                // Wing / Block custom pills
                if (widget.restrictedBlock == null && _allBlocks.length > 2)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _allBlocks.map((blk) {
                        final isSel = _selectedBlock == blk;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedBlock = blk),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                  width: isSel ? 1.5 : 1.0,
                                ),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSel) ...[
                                    const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    blk == 'all' ? 'બધા બ્લોક્સ (${widget.pendingBills.length})' : 'વિંગ $blk',
                                    style: TextStyle(
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 10),

                // Premium Search Box
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'ફ્લેટ, નામ કે મોબાઈલ નંબર શોધો...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19, color: Color(0xFF0F766E)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 17, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dual-Metric Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, size: 16, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'બાકી સભ્યો',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                        ),
                        Text(
                          '${filtered.length} સભ્યો',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: const Color(0xFFFCD34D),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'કુલ બાકી રકમ',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                        ),
                        Text(
                          '₹ ${totalPendingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of Pending Bills
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'પસંદ કરેલા ફિલ્ટર મુજબ કોઈ બાકી સભ્ય નથી.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, idx) {
                      final b = filtered[idx];
                      final isSent = _sentBillIds.contains(b.id);
                      final hasPhone = b.memberPhone.trim().isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: isSent ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSent ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                            width: isSent ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Unit Badge (Squircle)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.home_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    b.cleanFlatDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name & Phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.memberName.isNotEmpty ? b.memberName : 'સભ્ય',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (hasPhone) ...[
                                        const Icon(Icons.phone_outlined, size: 11, color: Color(0xFF64748B)),
                                        const SizedBox(width: 3),
                                        Text(
                                          b.memberPhone,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'નંબર નથી',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ₹ ${b.totalPayable.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 1-Tap WhatsApp Button / Status
                            if (isSent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'મોકલાઈ ગયું',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: hasPhone
                                    ? () async {
                                        HapticFeedback.lightImpact();
                                        final ok = await widget.service.sendSingleWhatsAppReminder(
                                          context: context,
                                          bill: b,
                                          societyName: widget.societyName,
                                          upiId: widget.upiId,
                                          upiPayeeName: widget.upiPayee,
                                        );
                                        if (ok) {
                                          setState(() => _sentBillIds.add(b.id));
                                        }
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: hasPhone
                                        ? const LinearGradient(
                                            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                                          )
                                        : null,
                                    color: hasPhone ? null : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: hasPhone
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF25D366).withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_rounded,
                                        size: 13,
                                        color: hasPhone ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: hasPhone ? Colors.white : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar: Bulk App Push Trigger
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSendingBulkPush || filtered.isEmpty
                    ? null
                    : () async {
                        setState(() => _isSendingBulkPush = true);
                        try {
                          final res = await MaintenanceService.instance.sendDueReminders(
                            billingMonth: widget.billingMonth,
                            billTitle: widget.monthTitle,
                          );
                          final pushCount = res['pushCount'] ?? 0;
                          final notifCount = res['notifCount'] ?? 0;

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ $notifCount સભ્યોને એપ નોટિફિકેશન મોકલાઈ! ($pushCount ને પુશ મળ્યો)',
                                ),
                                backgroundColor: const Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ભૂલ: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSendingBulkPush = false);
                        }
                      },
                icon: _isSendingBulkPush
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.notifications_active_rounded, size: 20),
                label: Text(
                  _isSendingBulkPush
                      ? 'પુશ નોટિફિકેશન મોકલાઈ રહ્યું છે...'
                      : 'તમામ બાકી સભ્યોને એપ પુશ મોકલો (${filtered.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
