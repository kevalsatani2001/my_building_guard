import 'dart:async';

import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';
import '../services/society_service.dart';
import 'admin_society_bank_settings_screen.dart';

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> {
  final MaintenanceService _service = MaintenanceService.instance;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  late String _selectedMonth; // Format: YYYY-MM
  String _statusFilter = 'all'; // 'all', 'pending', 'under_review', 'paid'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('yyyy-MM').format(now);
  }

  List<String> _getAvailableMonths() {
    final now = DateTime.now();
    final List<String> months = [];
    // Last 6 months and next 1 month
    for (int i = 1; i >= -5; i--) {
      final d = DateTime(now.year, now.month + i, 1);
      months.add(DateFormat('yyyy-MM').format(d));
    }
    return months;
  }

  String _formatMonthDisplay(String yyyyMm) {
    try {
      final parts = yyyyMm.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      return DateFormat('MMMM yyyy').format(d);
    } catch (_) {
      return yyyyMm;
    }
  }

  void _showSnackBar(String message, [Color color = Colors.black87]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('કૉલ શરૂ કરી શકાયો નહીં: $phone', Colors.red);
    }
  }

  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ફાયરબેઝ પરમિશન જરૂરી છે'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firestore Rules માં ડેટા લખવાની પરમિશન બ્લોક થયેલી છે.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('ઉકેલવા માટેનાં પગલાં:'),
            Text('૧. Firebase Console ઓપન કરો.'),
            Text('૨. Build -> Firestore Database -> Rules ટેબ ખોલો.'),
            Text('૩. ત્યાં allow read, write રૂલ પેસ્ટ કરી વાદળી "Publish" બટન દબાવો.'),
            SizedBox(height: 8),
            Text(
              'નોંધ: Realtime Database નહીં, પણ Cloud Firestore ના Rules પબ્લિશ કરવા જરૂરી છે.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('સમજાયું'),
          ),
        ],
      ),
    );
  }

  // --- ડાયલોગ ૧: ૧-ક્લિક બલ્ક બિલ જનરેશન ---
  Future<void> _showBulkGenerateDialog() async {
    final settings = await _service.getPaymentSettings();
    final defaultAmt = (settings['defaultAmount'] as num?)?.toDouble() ?? 1500.0;
    final dueDay = (settings['dueDay'] as num?)?.toInt() ?? 10;

    if (!mounted) return;

    final titleController = TextEditingController(
      text: '${_formatMonthDisplay(_selectedMonth)} મેન્ટેનન્સ',
    );
    final amountController =
        TextEditingController(text: defaultAmt.toStringAsFixed(0));
    DateTime dueDate = DateTime(
      int.parse(_selectedMonth.split('-')[0]),
      int.parse(_selectedMonth.split('-')[1]),
      dueDay,
    );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('બલ્ક બિલ જનરેટ કરો'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'મહિનો: ${_formatMonthDisplay(_selectedMonth)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'બિલનું શીર્ષક (Title)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'રકમ (પ્રતિ ફ્લેટ)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('છેલ્લી તારીખ (Due Date)'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDlgState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0;
                final title = titleController.text.trim();
                if (amt <= 0 || title.isEmpty) {
                  _showSnackBar('કૃપા કરીને માન્ય રકમ અને શીર્ષક દાખલ કરો', Colors.orange);
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final result = await _service.generateBulkBills(
                    billingMonth: _selectedMonth,
                    billTitle: title,
                    amount: amt,
                    dueDate: dueDate,
                  );
                  _showSnackBar(
                    'સફળતા: ${result['created']} નવા બિલ બન્યા! (${result['skipped']} પહેલાથી બનેલા હતા)',
                    Colors.green,
                  );
                } catch (e) {
                  _showSnackBar('ભૂલ: $e', Colors.red);
                  if (e.toString().contains('permission-denied') && mounted) {
                    _showPermissionErrorDialog();
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text('બધા ફ્લેટ્સ માટે જનરેટ કરો'),
            ),
          ],
        ),
      ),
    );
  }

  // --- સોસાયટી UPI & એકાઉન્ટ સેટિંગ્સ (Dedicated Modern Screen) ---
  Future<void> _showPaymentSettingsDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  // --- ડાયલોગ ૩: પેન્ડિંગ રીમાઇન્ડર મોકલવું ---
  Future<void> _sendReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('રીમાઇન્ડર એલર્ટ મોકલો'),
        content: Text(
          'શું તમે ${_formatMonthDisplay(_selectedMonth)} ના બાકી રહેલા તમામ સભ્યોને મોબાઈલ પર પુશ નોટિફિકેશન રીમાઇન્ડર મોકલવા માંગો છો?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ના'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('હા, મોકલો'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final sentCount = await _service.sendDueReminders(
        billingMonth: _selectedMonth,
        billTitle: '${_formatMonthDisplay(_selectedMonth)} મેન્ટેનન્સ',
      );
      _showSnackBar(
        '$sentCount સભ્યોને રીમાઇન્ડર એલર્ટ સફળતાપૂર્વક મોકલાઈ ગયું!',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('રીમાઇન્ડર મોકલવામાં ભૂલ: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ડાયલોગ ૪.૧: ફ્લેટ માટે ડાયનેમિક UPI QR કોડ બતાવો (તત્કાલ પોપ-અપ) ---
  void _showBillQrDialog(MaintenanceBill bill) {
    try {
      final cached = _service.cachedOrFallbackSettings;
      String currentUpiId = (cached['upiId'] ?? '').toString().trim();
      String currentPayeeName = (cached['upiPayeeName'] ?? 'Society Maintenance').toString().trim();
      if (currentPayeeName.isEmpty) currentPayeeName = 'Society Maintenance';

      final upiInputController = TextEditingController(text: currentUpiId);
      bool isEditingUpi = currentUpiId.isEmpty;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final effectiveUpiId = currentUpiId.isEmpty ? 'society@upi' : currentUpiId;
          final note = 'Maint ${bill.flatDisplay} ${bill.billingMonth}';
          final uri = _service.buildUpiUri(
            upiId: effectiveUpiId,
            payeeName: currentPayeeName,
            amount: bill.totalPayable,
            note: note,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.qr_code_2_rounded, color: Colors.teal.shade800, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ફ્લેટ ${bill.cleanFlatDisplay} પેમેન્ટ QR',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        bill.memberName.isNotEmpty ? bill.memberName : 'માસિક મેન્ટેનન્સ',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.08),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: QrImageView(
                              data: uri.toString(),
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (cxt, err) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'QR કોડ લોડ કરવામાં ભૂલ આવી',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'રકમ: ${_currencyFormat.format(bill.totalPayable)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'મેમ્બર તેમના મોબાઈલની કોઈપણ UPI એપ\n(Google Pay, PhonePe, Paytm, BHIM)\nથી આ QR સ્કેન કરી શકે છે.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  if (!isEditingUpi && currentUpiId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'UPI: $currentUpiId',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: currentUpiId));
                              _showSnackBar('UPI ID કૉપી થઈ ગયો!', Colors.green);
                            },
                            child: const Icon(Icons.copy_rounded, size: 16, color: Colors.teal),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                isEditingUpi = true;
                              });
                            },
                            child: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note, size: 18, color: Colors.orange.shade800),
                              const SizedBox(width: 4),
                              Text(
                                currentUpiId.isEmpty
                                    ? 'સોસાયટી UPI ID સેટ કરો:'
                                    : 'UPI ID બદલો:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: upiInputController,
                            decoration: const InputDecoration(
                              hintText: 'દા.ત. 98250xxxxx@upi / gpay',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonal(
                              onPressed: () {
                                final entered = upiInputController.text.trim();
                                if (entered.isNotEmpty) {
                                  setDialogState(() {
                                    currentUpiId = entered;
                                    isEditingUpi = false;
                                  });
                                  unawaited(_service.savePaymentSettings(
                                    upiId: entered,
                                    upiPayeeName: currentPayeeName,
                                    defaultAmount: bill.amount,
                                  ));
                                  _showSnackBar('UPI ID સેવ થઈ ગયો!', Colors.green);
                                }
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: const Text('સેવ & QR અપડેટ કરો', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
              TextButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'નમસ્તે ${bill.memberName.isNotEmpty ? bill.memberName : 'સભ્ય'},\n'
                          'તમારું ફ્લેટ ${bill.cleanFlatDisplay} નું ${bill.billTitle} નું મેન્ટેનન્સ બિલ ${_currencyFormat.format(bill.totalPayable)} બાકી છે.\n\n'
                          'ઓનલાઇન UPI થી ચૂકવવા નીચેની લિંક પર ક્લિક કરો:\n'
                          '${uri.toString()}\n\n'
                          'અથવા UPI ID પર પે કરો: $effectiveUpiId\n'
                          '- સોસાયટી મેનેજમેન્ટ',
                      subject: 'મેન્ટેનન્સ બિલ UPI પેમેન્ટ - ${bill.cleanFlatDisplay}',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('શેર કરો'),
              ),
              if (bill.status != MaintenanceStatus.paid)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showOfflinePaymentDialog(bill, initialMode: 'upi');
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('પેમેન્ટ મળ્યું'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('બંધ કરો'),
                ),
            ],
          );
        },
      ),
    );
    } catch (e, stack) {
      debugPrint('Error showing bill QR dialog: $e\n$stack');
      _showSnackBar('QR કોડ ખૂલવામાં સમસ્યા આવી: $e', Colors.red);
    }
  }

  // --- ડાયલોગ ૪.૨: સોસાયટી સામાન્ય QR કોડ (તત્કાલ પોપ-અપ) ---
  void _showGeneralSocietyQrDialog() {
    try {
      final cached = _service.cachedOrFallbackSettings;
      String currentUpiId = (cached['upiId'] ?? '').toString().trim();
      String currentPayeeName = (cached['upiPayeeName'] ?? 'Society Maintenance').toString().trim();
      final defaultAmt = (cached['defaultAmount'] as num?)?.toDouble() ?? 1500.0;

      final upiInputController = TextEditingController(text: currentUpiId);
      bool isEditingUpi = currentUpiId.isEmpty;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final effectiveUpiId = currentUpiId.isEmpty ? 'society@upi' : currentUpiId;
          final uri = _service.buildUpiUri(
            upiId: effectiveUpiId,
            payeeName: currentPayeeName,
            amount: defaultAmt,
            note: 'Society Maintenance',
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: Colors.teal, size: 26),
                SizedBox(width: 8),
                Text('સોસાયટી પેમેન્ટ QR'),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentPayeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade200, width: 2),
                      ),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: QrImageView(
                          data: uri.toString(),
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (cxt, err) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'QR કોડ લોડ કરવામાં ભૂલ આવી',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  Text(
                    'ડિફૉલ્ટ રકમ: ${_currencyFormat.format(defaultAmt)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                  ),
                  const SizedBox(height: 8),

                  if (!isEditingUpi && currentUpiId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('UPI: $currentUpiId', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: currentUpiId));
                              _showSnackBar('UPI ID કૉપી થઈ ગયો!', Colors.green);
                            },
                            child: const Icon(Icons.copy_rounded, size: 16, color: Colors.teal),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                isEditingUpi = true;
                              });
                            },
                            child: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note, size: 18, color: Colors.orange.shade800),
                              const SizedBox(width: 4),
                              Text(
                                currentUpiId.isEmpty
                                    ? 'સોસાયટી UPI ID સેટ કરો:'
                                    : 'UPI ID બદલો:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: upiInputController,
                            decoration: const InputDecoration(
                              hintText: 'દા.ત. 98250xxxxx@upi',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonal(
                              onPressed: () {
                                final entered = upiInputController.text.trim();
                                if (entered.isNotEmpty) {
                                  setDialogState(() {
                                    currentUpiId = entered;
                                    isEditingUpi = false;
                                  });
                                  unawaited(_service.savePaymentSettings(
                                    upiId: entered,
                                    upiPayeeName: currentPayeeName,
                                    defaultAmount: defaultAmt,
                                  ));
                                  _showSnackBar('UPI ID સેવ થઈ ગયો!', Colors.green);
                                }
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: const Text('સેવ & QR અપડેટ કરો', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('બંધ કરો'),
              ),
            ],
          );
        },
      ),
    );
    } catch (e, stack) {
      debugPrint('Error showing general QR dialog: $e\n$stack');
      _showSnackBar('QR કોડ ખૂલવામાં સમસ્યા આવી: $e', Colors.red);
    }
  }

  // --- ડાયલોગ ૪.૩: રોકડા, UPI QR કે ચેક થી પેમેન્ટ માર્ક કરવું ---
  Future<void> _showOfflinePaymentDialog(MaintenanceBill bill, {String? initialMode}) async {
    String paymentMode = initialMode ?? 'cash';
    final chequeController = TextEditingController();
    final utrController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('પેમેન્ટ નોંધો — ફ્લેટ ${bill.cleanFlatDisplay}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'સભ્ય: ${bill.memberName.isNotEmpty ? bill.memberName : "માલિક"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('રકમ: ${_currencyFormat.format(bill.totalPayable)}'),
                const Divider(height: 24),
                const Text('ચુકવણીનો પ્રકાર (Payment Mode):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('રોકડ (Cash)'),
                      selected: paymentMode == 'cash',
                      onSelected: (val) =>
                          setDlgState(() => paymentMode = 'cash'),
                    ),
                    ChoiceChip(
                      label: const Text('UPI (QR સ્કેન)'),
                      selected: paymentMode == 'upi',
                      onSelected: (val) =>
                          setDlgState(() => paymentMode = 'upi'),
                    ),
                    ChoiceChip(
                      label: const Text('ચેક (Cheque)'),
                      selected: paymentMode == 'cheque',
                      onSelected: (val) =>
                          setDlgState(() => paymentMode = 'cheque'),
                    ),
                  ],
                ),
                if (paymentMode == 'upi') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'મેમ્બરને સ્કેન કરાવવા માટે QR કોડ:',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showBillQrDialog(bill);
                          },
                          icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                          label: const Text('પેમેન્ટ QR કોડ બતાવો (Show QR)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: utrController,
                    decoration: const InputDecoration(
                      labelText: 'UTR / ટ્રાન્ઝેક્શન આઈડી (વૈકલ્પિક)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (paymentMode == 'cheque') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: chequeController,
                    decoration: const InputDecoration(
                      labelText: 'ચેક નંબર (Cheque No.) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'નોંધ (વૈકલ્પિક)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ'),
            ),
            FilledButton(
              onPressed: () async {
                if (paymentMode == 'cheque' &&
                    chequeController.text.trim().isEmpty) {
                  _showSnackBar('ચેક નંબર દાખલ કરવો જરૂરી છે', Colors.orange);
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  await _service.recordOfflinePayment(
                    billId: bill.id,
                    bill: bill,
                    paymentMode: paymentMode,
                    chequeNumber: chequeController.text.trim(),
                    utrNumber: utrController.text.trim(),
                    note: noteController.text.trim(),
                  );
                  _showSnackBar('પેમેન્ટ સ્વીકારાઈ ગયું અને રસીદ બની ગઈ!', Colors.green);
                } catch (e) {
                  _showSnackBar('ભૂલ: $e', Colors.red);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('પેઇડ માર્ક કરો'),
            ),
          ],
        ),
      ),
    );
  }

  // --- ડાયલોગ ૫: સભ્ય દ્વારા સબમિટ થયેલ UPI વેરિફિકેશન ---
  Future<void> _showVerifyUpiDialog(MaintenanceBill bill) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('UPI પેમેન્ટ વેરિફાય કરો'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ફ્લેટ: ${bill.cleanFlatDisplay}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('સભ્ય: ${bill.memberName} (${bill.memberPhone})'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('સભ્ય દ્વારા દાખલ કરેલ UTR / ટ્રાન્ઝેક્શન નં:',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  SelectableText(
                    bill.utrNumber.isNotEmpty ? bill.utrNumber : 'UTR દાખલ નથી થયો',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('રકમ: ${_currencyFormat.format(bill.totalPayable)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('બંધ કરો'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _service.approvePayment(billId: bill.id, bill: bill);
                _showSnackBar('UPI પેમેન્ટ સફળતાપૂર્વક મંજૂર કરવામાં આવ્યું!', Colors.green);
              } catch (e) {
                _showSnackBar('ભૂલ: $e', Colors.red);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('એપ્રૂવ કરો (Approve)'),
          ),
        ],
      ),
    );
  }

  // --- ડાયલોગ ૬: ડિજિટલ રસીદ પ્રિવ્યુ & શેર ---
  void _showReceiptDialog(MaintenanceBill bill) {
    final paidDate = bill.paidAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(bill.paidAt!)
        : '-';

    final receiptText = '''
================================
🏛️ ${_formatMonthDisplay(bill.billingMonth)} મેન્ટેનન્સ રસીદ
================================
રસીદ નં: ${bill.receiptNumber}
તારીખ: $paidDate
ફ્લેટ / યુનિટ: ${bill.cleanFlatDisplay}
સભ્ય નામ: ${bill.memberName}
સંપર્ક: ${bill.memberPhone}
રકમ: ${_currencyFormat.format(bill.totalPayable)}
ચુકવણી પદ્ધતિ: ${bill.paymentMode.toUpperCase()}
${bill.utrNumber.isNotEmpty ? "UTR / Ref: ${bill.utrNumber}" : ""}
${bill.chequeNumber.isNotEmpty ? "ચેક નં: ${bill.chequeNumber}" : ""}
સ્ટેટસ: પેઇડ (Paid & Verified)
================================
આ ડિજિટલ રસીદ માન્ય ગણાશે.
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_rounded, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('ડિજિટલ રસીદ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
                      const SizedBox(height: 6),
                      Text(
                        _currencyFormat.format(bill.totalPayable),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        'રસીદ નં: ${bill.receiptNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                _receiptRow('બિલ', bill.billTitle),
                _receiptRow('ફ્લેટ નં', bill.cleanFlatDisplay),
                _receiptRow('સભ્ય', bill.memberName),
                _receiptRow('ચુકવણી રીત', bill.paymentMode.toUpperCase()),
                if (bill.utrNumber.isNotEmpty) _receiptRow('UTR નં', bill.utrNumber),
                if (bill.chequeNumber.isNotEmpty)
                  _receiptRow('ચેક નં', bill.chequeNumber),
                _receiptRow('તારીખ', paidDate),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: receiptText,
                  subject: 'મેન્ટેનન્સ રસીદ - ${bill.cleanFlatDisplay}',
                ),
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('શેર કરો (Share)'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('બંધ કરો'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final societyId = SocietyService.instance.societyId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'મેન્ટેનન્સ & હિસાબ',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: Colors.teal.shade800, size: 20),
            ),
            tooltip: 'સોસાયટી પેમેન્ટ QR',
            onPressed: _showGeneralSocietyQrDialog,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.indigo.shade800, size: 20),
            ),
            tooltip: 'UPI સેટિંગ્સ',
            onPressed: _showPaymentSettingsDialog,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign_rounded, color: Colors.amber.shade900, size: 20),
            ),
            tooltip: 'ડ્યુ રીમાઇન્ડર મોકલો',
            onPressed: _sendReminders,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBulkGenerateDialog,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('બલ્ક બિલ જનરેટ', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.instance
                  .collection('maintenance_bills')
                  .where('societyId', isEqualTo: societyId)
                  .where('billingMonth', isEqualTo: _selectedMonth)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 54, color: Colors.red.shade700),
                          const SizedBox(height: 12),
                          const Text(
                            'ફાયરબેઝ સિક્યોરિટી પરમિશન એરર',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'આ એરર ઉકેલવા Firebase Console -> Firestore Database -> Rules માં પરમિશન Publish કરો.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final bills =
                    docs.map((d) => MaintenanceBill.fromFirestore(d)).toList();

                // સ્ટેટિસ્ટિક્સ કેલ્ક્યુલેશન
                final totalBills = bills.length;
                final paidBills =
                    bills.where((b) => b.status == MaintenanceStatus.paid).toList();
                final pendingBills = bills
                    .where((b) =>
                        b.status == MaintenanceStatus.pending ||
                        b.status == MaintenanceStatus.overdue)
                    .toList();
                final reviewBills = bills
                    .where((b) => b.status == MaintenanceStatus.underReview)
                    .toList();

                final totalCollected = paidBills.fold<double>(
                  0.0,
                  (acc, b) => acc + b.totalPayable,
                );
                final totalPending = pendingBills.fold<double>(
                  0.0,
                  (acc, b) => acc + b.totalPayable,
                );

                // ફિલ્ટર કરેલ લિસ્ટ
                List<MaintenanceBill> filteredBills = bills;
                if (_statusFilter == 'paid') {
                  filteredBills = paidBills;
                } else if (_statusFilter == 'pending') {
                  filteredBills = pendingBills;
                } else if (_statusFilter == 'under_review') {
                  filteredBills = reviewBills;
                }

                // ફ્લેટ નંબર મુજબ સૉર્ટિંગ
                filteredBills.sort((a, b) => a.cleanFlatDisplay.compareTo(b.cleanFlatDisplay));

                return Column(
                  children: [
                    // --- ૧. મહિનો પસંદગી બાર ---
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'મહિનો:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF475569)),
                          ),
                          const SizedBox(width: 8),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA)),
                              borderRadius: BorderRadius.circular(14),
                              items: _getAvailableMonths().map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    _formatMonthDisplay(m),
                                    style: TextStyle(
                                      fontWeight: m == _selectedMonth ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMonth = val);
                                }
                              },
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.domain_rounded, size: 12, color: Color(0xFF475569)),
                                const SizedBox(width: 4),
                                Text(
                                  'કુલ ફ્લેટ્સ: $totalBills',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- ૨. કલેક્શન સમરી કાર્ડ્સ (KPI) ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'કુલ જમા',
                              amount: _currencyFormat.format(totalCollected),
                              countText: '${paidBills.length} ફ્લેટ્સ ચૂકવેલ',
                              color: const Color(0xFF047857),
                              bgColor: const Color(0xFFECFDF5),
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'કુલ બાકી',
                              amount: _currencyFormat.format(totalPending),
                              countText: '${pendingBills.length} ફ્લેટ્સ બાકી',
                              color: const Color(0xFFBE123C),
                              bgColor: const Color(0xFFFFF1F2),
                              icon: Icons.pending_actions_rounded,
                            ),
                          ),
                          if (reviewBills.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'UPI વેરિફાય',
                                amount: '${reviewBills.length}',
                                countText: 'ચકાસણી પેન્ડિંગ',
                                color: const Color(0xFF1D4ED8),
                                bgColor: const Color(0xFFEFF6FF),
                                icon: Icons.verified_user_rounded,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // --- ૩. ફિલ્ટર ચિપ્સ ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _filterChip('all', 'બધા ($totalBills)'),
                          const SizedBox(width: 8),
                          _filterChip('pending', 'બાકી (${pendingBills.length})'),
                          const SizedBox(width: 8),
                          _filterChip(
                            'under_review',
                            'ચકાસણી હેઠળ (${reviewBills.length})',
                          ),
                          const SizedBox(width: 8),
                          _filterChip('paid', 'ચૂકવેલ (${paidBills.length})'),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // --- ૪. બિલ્સ લિસ્ટ ---
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting && bills.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : filteredBills.isEmpty
                          ? Center(
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
                                    totalBills == 0
                                        ? '${_formatMonthDisplay(_selectedMonth)} માટે કોઈ બિલ બન્યા નથી.\nનીચેના બટનથી બલ્ક બિલ બનાવો.'
                                        : 'આ ફિલ્ટરમાં કોઈ બિલ નથી.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  if (totalBills == 0) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showBulkGenerateDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('બિલ જનરેટ કરો'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filteredBills.length,
                              itemBuilder: (context, index) {
                                final bill = filteredBills[index];
                                return _buildBillCard(bill);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String countText,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.16), bgColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              countText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(MaintenanceBill bill) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    Color statusBg;

    switch (bill.status) {
      case MaintenanceStatus.paid:
        statusColor = const Color(0xFF047857);
        statusBg = const Color(0xFFECFDF5);
        statusText = 'ચૂકવેલ (Paid)';
        statusIcon = Icons.check_circle_rounded;
        break;
      case MaintenanceStatus.underReview:
        statusColor = const Color(0xFF1D4ED8);
        statusBg = const Color(0xFFEFF6FF);
        statusText = 'UPI ચકાસણી';
        statusIcon = Icons.pending_rounded;
        break;
      case MaintenanceStatus.overdue:
        statusColor = const Color(0xFFBE123C);
        statusBg = const Color(0xFFFFF1F2);
        statusText = 'મુદત વીતી ગઈ';
        statusIcon = Icons.warning_rounded;
        break;
      case MaintenanceStatus.pending:
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFFFFBEB);
        statusText = 'બાકી (Pending)';
        statusIcon = Icons.schedule_rounded;
        break;
    }

    final displayName = bill.memberName.trim().isNotEmpty
        ? bill.memberName
        : 'ફ્લેટ ${bill.cleanFlatDisplay}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bill.status == MaintenanceStatus.underReview
              ? const Color(0xFF93C5FD)
              : const Color(0xFFE2E8F0),
          width: bill.status == MaintenanceStatus.underReview ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.domain_rounded, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  bill.cleanFlatDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (bill.memberPhone.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 11, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 3),
                                      Text(
                                        bill.memberPhone,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(bill.totalPayable),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.5,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 11, color: statusColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_outlined, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  'ડ્યુ: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (bill.memberPhone.isNotEmpty &&
                                  bill.status != MaintenanceStatus.paid) ...[
                                InkWell(
                                  onTap: () => _makePhoneCall(bill.memberPhone),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Icon(Icons.call_rounded, size: 15, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                              if (bill.status != MaintenanceStatus.paid) ...[
                                InkWell(
                                  onTap: () => _showBillQrDialog(bill),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF99F6E4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF0D9488)),
                                        SizedBox(width: 4),
                                        Text(
                                          'QR પે',
                                          style: TextStyle(
                                            color: Color(0xFF0F766E),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (bill.status == MaintenanceStatus.underReview)
                                ElevatedButton.icon(
                                  onPressed: () => _showVerifyUpiDialog(bill),
                                  icon: const Icon(Icons.verified_rounded, size: 13),
                                  label: const Text('વેરિફાય', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              if (bill.status == MaintenanceStatus.pending ||
                                  bill.status == MaintenanceStatus.overdue)
                                ElevatedButton(
                                  onPressed: () => _showOfflinePaymentDialog(bill),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4338CA),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: const Color(0xFF4338CA).withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              if (bill.status == MaintenanceStatus.paid)
                                OutlinedButton.icon(
                                  onPressed: () => _showReceiptDialog(bill),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 13, color: Color(0xFF047857)),
                                  label: const Text('રસીદ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                                    backgroundColor: const Color(0xFFF0FDF4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
