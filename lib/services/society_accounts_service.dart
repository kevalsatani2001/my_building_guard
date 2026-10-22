import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_firestore.dart';
import '../models/society_expense_model.dart';
import '../models/maintenance_model.dart';
import 'society_service.dart';

class SocietyFinancialSummary {
  final double totalIncome;
  final double totalMaintenanceCollected;
  final double totalFestivalCollected;
  final double totalPenaltyCollected;
  final double totalExpenses;
  final double currentSavings; // totalIncome - totalExpenses
  final double thisMonthIncome;
  final double thisMonthExpense;
  final double pendingMaintenanceAmount;
  final int paidBillsCount;
  final int pendingBillsCount;
  final Map<String, double> categoryTotals;
  final List<SocietyExpense> recentExpenses;
  final List<SocietyLedgerEntry> ledgerEntries;

  SocietyFinancialSummary({
    required this.totalIncome,
    required this.totalMaintenanceCollected,
    required this.totalFestivalCollected,
    required this.totalPenaltyCollected,
    required this.totalExpenses,
    required this.currentSavings,
    required this.thisMonthIncome,
    required this.thisMonthExpense,
    required this.pendingMaintenanceAmount,
    required this.paidBillsCount,
    required this.pendingBillsCount,
    required this.categoryTotals,
    required this.recentExpenses,
    required this.ledgerEntries,
  });

  factory SocietyFinancialSummary.empty() {
    return SocietyFinancialSummary(
      totalIncome: 0,
      totalMaintenanceCollected: 0,
      totalFestivalCollected: 0,
      totalPenaltyCollected: 0,
      totalExpenses: 0,
      currentSavings: 0,
      thisMonthIncome: 0,
      thisMonthExpense: 0,
      pendingMaintenanceAmount: 0,
      paidBillsCount: 0,
      pendingBillsCount: 0,
      categoryTotals: {},
      recentExpenses: [],
      ledgerEntries: [],
    );
  }
}

class SocietyAccountsService {
  static final SocietyAccountsService instance = SocietyAccountsService._internal();
  SocietyAccountsService._internal();

  final FirebaseFirestore _firestore = AppFirestore.instance;

  String get _currentSocietyId => SocietyService.instance.currentSocietyId;

  /// Stream of all expenses for a society (optional blockFilter)
  Stream<List<SocietyExpense>> streamExpenses({String? societyId, String? blockFilter}) {
    final sId = societyId ?? _currentSocietyId;
    return _firestore
        .collection('society_expenses')
        .where('societyId', isEqualTo: sId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => SocietyExpense.fromFirestore(d)).toList();
          list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          if (blockFilter != null && blockFilter.isNotEmpty && blockFilter != 'ALL') {
            return list.where((e) => e.targetBlock == blockFilter || e.isCommon).toList();
          }
          return list;
        });
  }

  /// Record a new expense by Admin (common or block-specific)
  Future<void> recordExpense({
    required String title,
    required String categoryKey,
    required double amount,
    required DateTime expenseDate,
    required String paidTo,
    String paymentMode = 'cash',
    String notes = '',
    String billReceiptUrl = '',
    String scope = 'common',
    String targetBlock = 'ALL',
  }) async {
    final societyId = _currentSocietyId;
    final currentUser = FirebaseAuth.instance.currentUser;
    final recordedBy = currentUser?.displayName ?? currentUser?.email ?? 'Admin';

    final docRef = _firestore.collection('society_expenses').doc();
    final expense = SocietyExpense(
      id: docRef.id,
      societyId: societyId,
      title: title.trim(),
      categoryKey: categoryKey,
      amount: amount,
      expenseDate: expenseDate,
      paidTo: paidTo.trim(),
      paymentMode: paymentMode,
      notes: notes.trim(),
      billReceiptUrl: billReceiptUrl,
      recordedBy: recordedBy,
      scope: scope,
      targetBlock: targetBlock,
      createdAt: DateTime.now(),
    );

    await docRef.set(expense.toMap());
  }

  /// Update an existing expense
  Future<void> updateExpense(SocietyExpense expense) async {
    await _firestore
        .collection('society_expenses')
        .doc(expense.id)
        .update(expense.toMap());
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('society_expenses').doc(expenseId).delete();
  }

  /// Helper to normalize payment mode to clean Latin ASCII string
  static String normalizePaymentMode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'ONLINE';
    final m = raw.toLowerCase().trim();
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
    return raw.trim().toUpperCase();
  }

  /// Comprehensive calculation of society income, expenses, and current treasury balance
  Future<SocietyFinancialSummary> calculateFinancialSummary({
    String? societyId,
    String? blockFilter,
  }) async {
    final sId = societyId ?? _currentSocietyId;
    final isFiltered = blockFilter != null && blockFilter.isNotEmpty && blockFilter != 'ALL';

    // 1. Fetch all maintenance bills
    final billsSnap = await _firestore
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: sId)
        .get();

    double totalMaint = 0.0;
    double totalFest = 0.0;
    double totalPen = 0.0;
    double pendingMaint = 0.0;
    int paidCount = 0;
    int pendingCount = 0;
    double thisMonthInc = 0.0;

    final now = DateTime.now();
    final currentMonthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final List<SocietyLedgerEntry> ledgerEntries = [];

    for (final doc in billsSnap.docs) {
      final bill = MaintenanceBill.fromFirestore(doc);
      if (isFiltered) {
        final matchesBlock = bill.blockName == blockFilter ||
            bill.cleanBlockName == blockFilter ||
            bill.flatDisplay.startsWith(blockFilter);
        if (!matchesBlock) continue;
      }

      if (bill.isPaid) {
        paidCount++;
        totalMaint += bill.amount;
        totalFest += bill.festivalCharge;
        totalPen += bill.penaltyAmount;

        final txDate = bill.paidAt ?? bill.createdAt;
        final memPart = bill.memberName.isNotEmpty ? ' (${bill.memberName})' : '';
        ledgerEntries.add(
          SocietyLedgerEntry(
            id: bill.id,
            date: txDate,
            title: '${bill.billTitle} [ફ્લેટ ${bill.flatDisplay}$memPart]',
            subtitle: 'રસીદ: ${bill.receiptNumber.isNotEmpty ? bill.receiptNumber : (bill.id.length > 8 ? bill.id.substring(0, 8).toUpperCase() : bill.id)}',
            categoryKey: 'maintenance_income',
            categoryLabel: bill.festivalCharge > 0 ? 'મેન્ટેનન્સ + તહેવાર ફાળો' : 'મેન્ટેનન્સ આવક',
            isCredit: true,
            amount: bill.totalPayable,
            paymentMode: normalizePaymentMode(bill.paymentMode),
            reference: bill.receiptNumber.isNotEmpty ? bill.receiptNumber : (bill.id.length > 8 ? bill.id.substring(0, 8).toUpperCase() : bill.id),
          ),
        );

        if (bill.billingMonth == currentMonthPrefix ||
            (bill.paidAt != null &&
                bill.paidAt!.year == now.year &&
                bill.paidAt!.month == now.month)) {
          thisMonthInc += bill.totalPayable;
        }
      } else {
        pendingCount++;
        pendingMaint += bill.totalPayable;
      }
    }

    final totalIncome = totalMaint + totalFest + totalPen;

    // 2. Fetch all expenses
    final expensesSnap = await _firestore
        .collection('society_expenses')
        .where('societyId', isEqualTo: sId)
        .get();

    double totalExp = 0.0;
    double thisMonthExp = 0.0;
    final Map<String, double> categoryTotals = {};
    final List<SocietyExpense> allExpenses = [];

    for (final doc in expensesSnap.docs) {
      final exp = SocietyExpense.fromFirestore(doc);
      if (isFiltered) {
        final matchesExpense = exp.targetBlock == blockFilter || exp.isCommon;
        if (!matchesExpense) continue;
      }

      allExpenses.add(exp);
      totalExp += exp.amount;

      categoryTotals[exp.categoryKey] = (categoryTotals[exp.categoryKey] ?? 0.0) + exp.amount;

      ledgerEntries.add(
        SocietyLedgerEntry(
          id: exp.id,
          date: exp.expenseDate,
          title: exp.title,
          subtitle: exp.paidTo.isNotEmpty ? 'ચૂકવ્યા: ${exp.paidTo}' : (exp.notes.isNotEmpty ? exp.notes : '-'),
          categoryKey: exp.categoryKey,
          categoryLabel: exp.category.titleGujarati,
          isCredit: false,
          amount: exp.amount,
          paymentMode: normalizePaymentMode(exp.paymentMode),
          reference: exp.id.length > 8 ? exp.id.substring(0, 8).toUpperCase() : exp.id.toUpperCase(),
        ),
      );

      if (exp.expenseDate.year == now.year && exp.expenseDate.month == now.month) {
        thisMonthExp += exp.amount;
      }
    }

    allExpenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    // Calculate chronological running balance (earliest date to latest date)
    ledgerEntries.sort((a, b) => a.date.compareTo(b.date));
    double running = 0.0;
    for (final entry in ledgerEntries) {
      if (entry.isCredit) {
        running += entry.amount;
      } else {
        running -= entry.amount;
      }
      entry.runningBalance = running;
    }

    final currentSavings = totalIncome - totalExp;

    return SocietyFinancialSummary(
      totalIncome: totalIncome,
      totalMaintenanceCollected: totalMaint,
      totalFestivalCollected: totalFest,
      totalPenaltyCollected: totalPen,
      totalExpenses: totalExp,
      currentSavings: currentSavings,
      thisMonthIncome: thisMonthInc,
      thisMonthExpense: thisMonthExp,
      pendingMaintenanceAmount: pendingMaint,
      paidBillsCount: paidCount,
      pendingBillsCount: pendingCount,
      categoryTotals: categoryTotals,
      recentExpenses: allExpenses.take(15).toList(),
      ledgerEntries: ledgerEntries,
    );
  }
}
