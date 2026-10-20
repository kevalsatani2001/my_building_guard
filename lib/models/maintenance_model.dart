import 'package:cloud_firestore/cloud_firestore.dart';

enum MaintenanceStatus {
  pending,
  underReview,
  paid,
  overdue;

  static MaintenanceStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'paid':
        return MaintenanceStatus.paid;
      case 'under_review':
      case 'underreview':
        return MaintenanceStatus.underReview;
      case 'overdue':
        return MaintenanceStatus.overdue;
      case 'pending':
      default:
        return MaintenanceStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case MaintenanceStatus.paid:
        return 'paid';
      case MaintenanceStatus.underReview:
        return 'under_review';
      case MaintenanceStatus.overdue:
        return 'overdue';
      case MaintenanceStatus.pending:
        return 'pending';
    }
  }

  String get labelGujarati {
    switch (this) {
      case MaintenanceStatus.paid:
        return 'ચૂકવેલ (Paid)';
      case MaintenanceStatus.underReview:
        return 'ચકાસણી હેઠળ (Review)';
      case MaintenanceStatus.overdue:
        return 'મુદત વીતી ગઈ (Overdue)';
      case MaintenanceStatus.pending:
        return 'બાકી (Pending)';
    }
  }
}

class MaintenanceBill {
  final String id;
  final String societyId;
  final String billTitle;
  final String billingMonth; // Format: YYYY-MM
  final DateTime dueDate;
  final double amount;
  final double penaltyAmount;
  final double festivalCharge;
  final String festivalName;
  final String blockName;
  final String unitNumber;
  final String? memberId;
  final String memberName;
  final String memberPhone;
  final MaintenanceStatus status;
  final String paymentMode; // 'upi', 'cash', 'cheque', 'online'
  final String utrNumber;
  final String chequeNumber;
  final String receiptNumber;
  final DateTime? paidAt;
  final String verifiedBy;
  final DateTime createdAt;
  final String note;

  MaintenanceBill({
    required this.id,
    required this.societyId,
    required this.billTitle,
    required this.billingMonth,
    required this.dueDate,
    required this.amount,
    this.penaltyAmount = 0.0,
    this.festivalCharge = 0.0,
    this.festivalName = '',
    required this.blockName,
    required this.unitNumber,
    this.memberId,
    this.memberName = '',
    this.memberPhone = '',
    this.status = MaintenanceStatus.pending,
    this.paymentMode = '',
    this.utrNumber = '',
    this.chequeNumber = '',
    this.receiptNumber = '',
    this.paidAt,
    this.verifiedBy = '',
    DateTime? createdAt,
    this.note = '',
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalPayable => amount + penaltyAmount + festivalCharge;

  String get cleanBlockName {
    if (blockName.contains('_')) {
      final parts = blockName.split('_');
      return parts.sublist(1).join('_');
    }
    return blockName;
  }

  String get cleanFlatDisplay => cleanBlockName.isNotEmpty && unitNumber.isNotEmpty
      ? '$cleanBlockName-$unitNumber'
      : (unitNumber.isNotEmpty ? unitNumber : cleanBlockName);

  String get flatDisplay => cleanFlatDisplay;

  bool get isPaid => status == MaintenanceStatus.paid;
  bool get isPending => status == MaintenanceStatus.pending;
  bool get isUnderReview => status == MaintenanceStatus.underReview;

  factory MaintenanceBill.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MaintenanceBill(
      id: doc.id,
      societyId: (data['societyId'] ?? 'default').toString(),
      billTitle: (data['billTitle'] ?? 'માસિક મેન્ટેનન્સ').toString(),
      billingMonth: (data['billingMonth'] ?? '').toString(),
      dueDate: parseDate(data['dueDate']),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      penaltyAmount: (data['penaltyAmount'] as num?)?.toDouble() ?? 0.0,
      festivalCharge: (data['festivalCharge'] as num?)?.toDouble() ?? 0.0,
      festivalName: (data['festivalName'] ?? '').toString(),
      blockName: (data['blockName'] ?? '').toString(),
      unitNumber: (data['unitNumber'] ?? '').toString(),
      memberId: data['memberId']?.toString(),
      memberName: (data['memberName'] ?? '').toString(),
      memberPhone: (data['memberPhone'] ?? '').toString(),
      status: MaintenanceStatus.fromString(data['status']?.toString()),
      paymentMode: (data['paymentMode'] ?? '').toString(),
      utrNumber: (data['utrNumber'] ?? '').toString(),
      chequeNumber: (data['chequeNumber'] ?? '').toString(),
      receiptNumber: (data['receiptNumber'] ?? '').toString(),
      paidAt: parseNullableDate(data['paidAt']),
      verifiedBy: (data['verifiedBy'] ?? '').toString(),
      createdAt: parseDate(data['createdAt']),
      note: (data['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'billTitle': billTitle,
      'billingMonth': billingMonth,
      'dueDate': Timestamp.fromDate(dueDate),
      'amount': amount,
      'penaltyAmount': penaltyAmount,
      'festivalCharge': festivalCharge,
      'festivalName': festivalName,
      'blockName': blockName,
      'unitNumber': unitNumber,
      'memberId': memberId,
      'memberName': memberName,
      'memberPhone': memberPhone,
      'status': status.toDbString(),
      'paymentMode': paymentMode,
      'utrNumber': utrNumber,
      'chequeNumber': chequeNumber,
      'receiptNumber': receiptNumber,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'verifiedBy': verifiedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }
}
