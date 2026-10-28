import 'package:equatable/equatable.dart';
import '../../models/maintenance_model.dart';

abstract class MaintenanceEvent extends Equatable {
  const MaintenanceEvent();

  @override
  List<Object?> get props => [];
}

/// Request real-time stream subscription for bills
class MaintenanceSubscriptionRequested extends MaintenanceEvent {
  final String societyId;
  final String? memberId;
  final String? blockName;
  final String? unitNumber;
  final String scope; // 'society' or 'member'

  const MaintenanceSubscriptionRequested({
    required this.societyId,
    this.memberId,
    this.blockName,
    this.unitNumber,
    this.scope = 'society',
  });

  @override
  List<Object?> get props => [societyId, memberId, blockName, unitNumber, scope];
}

/// Internal event when Firestore streams update
class MaintenanceBillsUpdated extends MaintenanceEvent {
  final List<MaintenanceBill> bills;

  const MaintenanceBillsUpdated(this.bills);

  @override
  List<Object?> get props => [bills];
}

/// Internal event when Firestore streams fail
class MaintenanceErrorOccurred extends MaintenanceEvent {
  final String error;

  const MaintenanceErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Change status filter ('all', 'pending', 'under_review', 'paid', 'overdue')
class MaintenanceStatusFilterChanged extends MaintenanceEvent {
  final String statusFilter;

  const MaintenanceStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Change billing month filter ('all' or 'YYYY-MM')
class MaintenanceMonthFilterChanged extends MaintenanceEvent {
  final String monthFilter;

  const MaintenanceMonthFilterChanged(this.monthFilter);

  @override
  List<Object?> get props => [monthFilter];
}

/// Change search query (member name, flat/unit number, phone, bill title)
class MaintenanceSearchQueryChanged extends MaintenanceEvent {
  final String query;

  const MaintenanceSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Generate bulk bills for all society units/members
class MaintenanceGenerateBulkBillsRequested extends MaintenanceEvent {
  final String billingMonth;
  final String billTitle;
  final double amount;
  final DateTime dueDate;
  final double penaltyAmount;
  final double festivalCharge;
  final String festivalName;
  final String billingMode; // 'fixed' or 'sqft'
  final double ratePerSqFt;
  final String targetCategory; // 'all', 'commercial', 'residential'
  final String targetBlock; // 'all' or specific block name
  final double gstRate;
  final String gstin;
  final double commercialRate;
  final double residentialRate;

  const MaintenanceGenerateBulkBillsRequested({
    required this.billingMonth,
    required this.billTitle,
    required this.amount,
    required this.dueDate,
    this.penaltyAmount = 0.0,
    this.festivalCharge = 0.0,
    this.festivalName = '',
    this.billingMode = 'fixed',
    this.ratePerSqFt = 0.0,
    this.targetCategory = 'all',
    this.targetBlock = 'all',
    this.gstRate = 0.0,
    this.gstin = '',
    this.commercialRate = 0.0,
    this.residentialRate = 0.0,
  });

  @override
  List<Object?> get props => [
        billingMonth,
        billTitle,
        amount,
        dueDate,
        penaltyAmount,
        festivalCharge,
        festivalName,
        billingMode,
        ratePerSqFt,
        targetCategory,
        targetBlock,
        gstRate,
        gstin,
      ];
}

/// Record manual offline payment (Cash or Cheque)
class MaintenanceRecordOfflinePaymentRequested extends MaintenanceEvent {
  final String billId;
  final String paymentMode; // 'cash' or 'cheque'
  final String chequeNumber;
  final String note;

  const MaintenanceRecordOfflinePaymentRequested({
    required this.billId,
    required this.paymentMode,
    this.chequeNumber = '',
    this.note = '',
  });

  @override
  List<Object?> get props => [billId, paymentMode, chequeNumber, note];
}

/// Resident submits UPI UTR number for review
class MaintenanceSubmitUtrRequested extends MaintenanceEvent {
  final String billId;
  final String utrNumber;
  final String note;

  const MaintenanceSubmitUtrRequested({
    required this.billId,
    required this.utrNumber,
    this.note = '',
  });

  @override
  List<Object?> get props => [billId, utrNumber, note];
}

/// Society Admin verifies or rejects submitted UTR
class MaintenanceVerifyUtrRequested extends MaintenanceEvent {
  final String billId;
  final bool isApproved;
  final String? rejectReason;

  const MaintenanceVerifyUtrRequested({
    required this.billId,
    required this.isApproved,
    this.rejectReason,
  });

  @override
  List<Object?> get props => [billId, isApproved, rejectReason];
}

/// Society Admin deletes an erroneous bill
class MaintenanceDeleteBillRequested extends MaintenanceEvent {
  final String billId;

  const MaintenanceDeleteBillRequested(this.billId);

  @override
  List<Object?> get props => [billId];
}
