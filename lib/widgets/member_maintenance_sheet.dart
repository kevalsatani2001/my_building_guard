import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';
import '../services/society_service.dart';

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
            ? Colors.blue.shade800
            : (isOverdue ? Colors.red.shade700 : Colors.teal.shade800);

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
                          ? 'UPI પેમેન્ટ ચકાસણી હેઠળ છે'
                          : 'બાકી: ${currencyFmt.format(bill.totalPayable)} • છેલ્લી તા: ${DateFormat("dd/MM").format(bill.dueDate)}',
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
                  isReview ? 'વિગત' : 'હમણાં ચૂકવો',
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
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final utrController = TextEditingController();

    final settings = await MaintenanceService.instance.getPaymentSettings();
    final upiId = (settings['upiId'] ?? '').toString().trim();
    final payeeName = (settings['upiPayeeName'] ?? 'Society Maintenance')
        .toString()
        .trim();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'મેન્ટેનન્સ & ઓનલાઇન પેમેન્ટ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.payment_rounded, size: 18),
                      text: 'ચુકવણી (Pay)',
                    ),
                    Tab(
                      icon: Icon(Icons.history_rounded, size: 18),
                      text: 'ઇતિહાસ & રસીદો',
                    ),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: AppFirestore.instance
                        .collection('maintenance_bills')
                        .where('societyId',
                            isEqualTo: SocietyService.instance.societyId)
                        .where('memberId', isEqualTo: currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final bills = docs
                          .map((d) => MaintenanceBill.fromFirestore(d))
                          .toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      final unpaid = bills
                          .where((b) => b.status != MaintenanceStatus.paid)
                          .toList();
                      final activeBill =
                          initialBill ?? (unpaid.isNotEmpty ? unpaid.first : null);

                      return TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: activeBill == null ||
                                    activeBill.status == MaintenanceStatus.paid
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 40),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 64,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            '🎉 તમામ મેન્ટેનન્સ બિલ ચૂકવાઈ ગયા છે!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'તમારી કોઈ બાકી રકમ નથી. જૂની રસીદો બીજા ટેબમાં ઉપલબ્ધ છે.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _buildActiveBillPaySection(
                                    context: context,
                                    bill: activeBill,
                                    upiId: upiId,
                                    payeeName: payeeName,
                                    currencyFmt: currencyFmt,
                                    utrController: utrController,
                                    parentCtx: ctx,
                                  ),
                          ),
                          bills.isEmpty
                              ? const Center(
                                  child: Text('હજુ સુધી કોઈ બિલ મળ્યા નથી.'),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: bills.length,
                                  itemBuilder: (context, index) {
                                    final b = bills[index];
                                    return Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          b.billTitle,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'રકમ: ${currencyFmt.format(b.totalPayable)} • ${DateFormat('dd MMM yyyy').format(b.dueDate)}',
                                        ),
                                        trailing: b.status ==
                                                MaintenanceStatus.paid
                                            ? FilledButton.tonalIcon(
                                                onPressed: () =>
                                                    showReceiptDialog(context, b),
                                                icon: const Icon(
                                                    Icons.receipt_long,
                                                    size: 16),
                                                label: const Text('રસીદ'),
                                              )
                                            : Chip(
                                                label: Text(
                                                  b.status.labelGujarati,
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                                backgroundColor: b.status ==
                                                        MaintenanceStatus
                                                            .underReview
                                                    ? Colors.blue.shade50
                                                    : Colors.red.shade50,
                                              ),
                                      ),
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
        ),
      ),
    );
  }

  static Widget _buildActiveBillPaySection({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.hourglass_bottom_rounded,
                size: 48, color: Colors.blue.shade800),
            const SizedBox(height: 10),
            const Text(
              'UPI પેમેન્ટ ચકાસણી હેઠળ છે',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'તમારો સબમિટ થયેલ UTR: ${bill.utrNumber}\nરકમ: ${currencyFmt.format(bill.totalPayable)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              'ચેરમેન/એડમિન આ રકમ વેરિફાય કરશે એટલે તરત જ તમને ડિજિટલ રસીદ મળી જશે.',
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.shade200),
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
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Chip(
                    label: Text(
                      bill.status.labelGujarati,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'કુલ ચૂકવવાપાત્ર: ${currencyFmt.format(bill.totalPayable)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal.shade900,
                ),
              ),
              Text(
                'છેલ્લી તારીખ: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (upiId.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'સોસાયટી દ્વારા હજુ સુધી UPI ID સેટ કરવામાં આવ્યો નથી. કૃપા કરીને એડમિનનો સંપર્ક કરી રોકડ અથવા ચેકથી ચુકવણી કરો.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
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
                      const SnackBar(
                        content: Text(
                          'UPI એપ ખૂલી શકી નથી. નીચે આપેલ QR કોડ સ્કેન કરો.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ભૂલ: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: const Text(
                'Google Pay / PhonePe થી ચૂકવો (1-Tap)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'અથવા અન્ય મોબાઈલથી સ્કેન કરો:',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
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
                const SizedBox(height: 4),
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
          const Text(
            'પેમેન્ટ કર્યા પછી અહીં UTR નંબર દાખલ કરો:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: utrController,
            decoration: const InputDecoration(
              labelText: '૧૨-આંકડાનો UTR / ટ્રાન્ઝેક્શન નંબર *',
              hintText: 'દા.ત. 4289XXXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final utr = utrController.text.trim();
                if (utr.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('કૃપા કરીને માન્ય UTR નંબર દાખલ કરો'),
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
                    const SnackBar(
                      content:
                          Text('UPI પેમેન્ટ વેરિફિકેશન માટે સબમિટ થઈ ગયું!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('ચુકવણી કન્ફર્મ કરો'),
            ),
          ),
        ],
      ],
    );
  }

  /// Shows digital receipt for paid maintenance bill with sharing capability.
  static void showReceiptDialog(BuildContext context, MaintenanceBill bill) {
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final paidDate = bill.paidAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(bill.paidAt!)
        : '-';

    final receiptText = '''
================================
🏛️ ${bill.billTitle} રસીદ
================================
રસીદ નં: ${bill.receiptNumber}
તારીખ: $paidDate
ફ્લેટ: ${bill.flatDisplay}
સભ્ય: ${bill.memberName}
રકમ: ${currencyFmt.format(bill.totalPayable)}
ચુકવણી પદ્ધતિ: ${bill.paymentMode.toUpperCase()}
${bill.utrNumber.isNotEmpty ? "UTR / Ref: ${bill.utrNumber}" : ""}
${bill.chequeNumber.isNotEmpty ? "ચેક નં: ${bill.chequeNumber}" : ""}
સ્ટેટસ: પેઇડ (Paid & Verified)
================================
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('ડિજિટલ રસીદ'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      currencyFmt.format(bill.totalPayable),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade900,
                      ),
                    ),
                    Text(
                      'રસીદ નં: ${bill.receiptNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              _receiptItem('બિલ', bill.billTitle),
              _receiptItem('ફ્લેટ', bill.flatDisplay),
              _receiptItem('રીત', bill.paymentMode.toUpperCase()),
              if (bill.utrNumber.isNotEmpty)
                _receiptItem('UTR', bill.utrNumber),
              _receiptItem('તારીખ', paidDate),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: receiptText,
                  subject: 'મેન્ટેનન્સ રસીદ - ${bill.flatDisplay}',
                ),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('શેર કરો'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('બંધ કરો'),
          ),
        ],
      ),
    );
  }

  static Widget _receiptItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
