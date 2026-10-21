import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SocietyExpenseCategory {
  final String key;
  final String titleGujarati;
  final String titleEnglish;
  final IconData icon;
  final Color color;

  const SocietyExpenseCategory({
    required this.key,
    required this.titleGujarati,
    required this.titleEnglish,
    required this.icon,
    required this.color,
  });

  static const List<SocietyExpenseCategory> all = [
    SocietyExpenseCategory(
      key: 'watchman_salary',
      titleGujarati: 'સિક્યોરિટી / વોચમેન પગાર',
      titleEnglish: 'Watchman / Security Salary',
      icon: Icons.security_rounded,
      color: Color(0xFF0F766E), // Teal
    ),
    SocietyExpenseCategory(
      key: 'cleaning_staff',
      titleGujarati: 'સફાઈ કર્મચારી ખર્ચ',
      titleEnglish: 'Cleaning & Housekeeping',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF0284C7), // Sky Blue
    ),
    SocietyExpenseCategory(
      key: 'electricity_common',
      titleGujarati: 'સામાન્ય લાઈટ બિલ (કોમન)',
      titleEnglish: 'Common Electricity Bill',
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFFD97706), // Amber
    ),
    SocietyExpenseCategory(
      key: 'lift_amc',
      titleGujarati: 'લિફ્ટ AMC & સર્વિસ',
      titleEnglish: 'Lift Maintenance / AMC',
      icon: Icons.elevator_rounded,
      color: Color(0xFF4F46E5), // Indigo
    ),
    SocietyExpenseCategory(
      key: 'water_borewell',
      titleGujarati: 'પાણી & બોરવેલ ખર્ચ',
      titleEnglish: 'Water Supply & Borewell',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0D9488), // Cyan Teal
    ),
    SocietyExpenseCategory(
      key: 'festival_celebration',
      titleGujarati: 'તહેવાર ઉજવણી ખર્ચ',
      titleEnglish: 'Festival & Celebrations',
      icon: Icons.celebration_rounded,
      color: Color(0xFFE11D48), // Rose
    ),
    SocietyExpenseCategory(
      key: 'repairs_maintenance',
      titleGujarati: 'રિપેરિંગ, કલર & પ્લમ્બિંગ',
      titleEnglish: 'Repairs & Renovation',
      icon: Icons.build_circle_rounded,
      color: Color(0xFF7C3AED), // Violet
    ),
    SocietyExpenseCategory(
      key: 'gardening',
      titleGujarati: 'બગીચો / માળી ખર્ચ',
      titleEnglish: 'Gardening & Landscape',
      icon: Icons.park_rounded,
      color: Color(0xFF059669), // Emerald
    ),
    SocietyExpenseCategory(
      key: 'cctv_security',
      titleGujarati: 'CCTV & ગેટ સિક્યોરિટી',
      titleEnglish: 'CCTV & Security Hardware',
      icon: Icons.videocam_rounded,
      color: Color(0xFF334155), // Slate
    ),
    SocietyExpenseCategory(
      key: 'other',
      titleGujarati: 'અન્ય પરચુરણ ખર્ચ',
      titleEnglish: 'Miscellaneous / Other',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF64748B), // Slate Grey
    ),
  ];

  static SocietyExpenseCategory fromKey(String? key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.last,
    );
  }
}

class SocietyExpense {
  final String id;
  final String societyId;
  final String title;
  final String categoryKey;
  final double amount;
  final DateTime expenseDate;
  final String paidTo; // Payee Name (e.g. Ramesh Watchman)
  final String paymentMode; // 'cash', 'online', 'upi', 'bank_transfer', 'cheque'
  final String notes;
  final String billReceiptUrl;
  final String recordedBy;
  final DateTime createdAt;

  SocietyExpense({
    required this.id,
    required this.societyId,
    required this.title,
    required this.categoryKey,
    required this.amount,
    required this.expenseDate,
    required this.paidTo,
    this.paymentMode = 'cash',
    this.notes = '',
    this.billReceiptUrl = '',
    this.recordedBy = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SocietyExpenseCategory get category => SocietyExpenseCategory.fromKey(categoryKey);

  String get paymentModeLabel {
    switch (paymentMode.toLowerCase()) {
      case 'upi':
        return 'UPI / QR ઓનલાઇન';
      case 'bank_transfer':
      case 'online':
        return 'બેંક ટ્રાન્સફર (NEFT/IMPS)';
      case 'cheque':
        return 'ચેક (Cheque)';
      case 'cash':
      default:
        return 'રોકડ (Cash)';
    }
  }

  factory SocietyExpense.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return SocietyExpense(
      id: doc.id,
      societyId: (data['societyId'] ?? 'default').toString(),
      title: (data['title'] ?? 'ખર્ચ').toString(),
      categoryKey: (data['categoryKey'] ?? 'other').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: parseDate(data['expenseDate']),
      paidTo: (data['paidTo'] ?? '').toString(),
      paymentMode: (data['paymentMode'] ?? 'cash').toString(),
      notes: (data['notes'] ?? '').toString(),
      billReceiptUrl: (data['billReceiptUrl'] ?? '').toString(),
      recordedBy: (data['recordedBy'] ?? '').toString(),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'categoryKey': categoryKey,
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'paidTo': paidTo,
      'paymentMode': paymentMode,
      'notes': notes,
      'billReceiptUrl': billReceiptUrl,
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// A unified chronological ledger entry for society income or expense with running balance.
class SocietyLedgerEntry {
  final String id;
  final DateTime date;
  final String title;
  final String subtitle;
  final String categoryKey;
  final String categoryLabel;
  final bool isCredit; // true = Income (+), false = Expense (-)
  final double amount;
  final String paymentMode;
  final String reference;
  double runningBalance; // Net treasury fund balance on that date after this transaction

  SocietyLedgerEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.categoryKey,
    required this.categoryLabel,
    required this.isCredit,
    required this.amount,
    required this.paymentMode,
    required this.reference,
    this.runningBalance = 0.0,
  });
}

