import 'package:equatable/equatable.dart';
import '../../models/maintenance_model.dart';

abstract class MaintenanceState extends Equatable {
  const MaintenanceState();

  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceLoaded extends MaintenanceState {
  final List<MaintenanceBill> allBills;
  final String statusFilter; // 'all', 'pending', 'under_review', 'paid', 'overdue'
  final String monthFilter; // 'all' or 'YYYY-MM'
  final String searchQuery;
  final String scope; // 'society' or 'member'
  final bool isActionInProgress;
  final String? actionFeedbackMessage;

  const MaintenanceLoaded({
    required this.allBills,
    this.statusFilter = 'all',
    this.monthFilter = 'all',
    this.searchQuery = '',
    this.scope = 'society',
    this.isActionInProgress = false,
    this.actionFeedbackMessage,
  });

  /// Computed list of bills after applying status, month, and search query filters
  List<MaintenanceBill> get filteredBills {
    final query = searchQuery.trim().toLowerCase();

    return allBills.where((bill) {
      // 1. Status Filter
      if (statusFilter != 'all') {
        if (bill.status.toDbString().toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Billing Month Filter
      if (monthFilter != 'all') {
        if (bill.billingMonth != monthFilter) {
          return false;
        }
      }

      // 3. Search Query Filter (member name, flat unit, phone, receipt or title)
      if (query.isNotEmpty) {
        final matchesName = bill.memberName.toLowerCase().contains(query);
        final matchesUnit = bill.unitNumber.toLowerCase().contains(query);
        final matchesBlock = bill.blockName.toLowerCase().contains(query);
        final matchesPhone = bill.memberPhone.contains(query);
        final matchesReceipt = bill.receiptNumber.toLowerCase().contains(query);
        final matchesTitle = bill.billTitle.toLowerCase().contains(query);
        final matchesFlat = bill.flatDisplay.toLowerCase().contains(query);

        if (!matchesName &&
            !matchesUnit &&
            !matchesBlock &&
            !matchesPhone &&
            !matchesReceipt &&
            !matchesTitle &&
            !matchesFlat) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// All unique billing months present in the current bill set (sorted newest first)
  List<String> get availableMonths {
    final months = allBills.map((b) => b.billingMonth).toSet().toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Total sum of payable amounts across all loaded bills
  double get totalBilledAmount =>
      allBills.fold(0.0, (sum, bill) => sum + bill.totalPayable);

  /// Total money received (Paid status)
  double get totalCollectedAmount => allBills
      .where((b) => b.status == MaintenanceStatus.paid)
      .fold(0.0, (sum, bill) => sum + bill.totalPayable);

  /// Total outstanding dues (Pending, Overdue, UnderReview)
  double get pendingCollectionAmount => allBills
      .where((b) => b.status != MaintenanceStatus.paid)
      .fold(0.0, (sum, bill) => sum + bill.totalPayable);

  /// Number of bills currently paid
  int get paidCount =>
      allBills.where((b) => b.status == MaintenanceStatus.paid).length;

  /// Number of bills currently pending
  int get pendingCount =>
      allBills.where((b) => b.status == MaintenanceStatus.pending).length;

  /// Number of bills under review (waiting for Admin to approve UTR)
  int get underReviewCount =>
      allBills.where((b) => b.status == MaintenanceStatus.underReview).length;

  /// Number of overdue bills
  int get overdueCount =>
      allBills.where((b) => b.status == MaintenanceStatus.overdue).length;

  /// Percentage of total bills collected (0.0 to 100.0)
  double get collectionPercentage {
    if (totalBilledAmount <= 0) return 0.0;
    return ((totalCollectedAmount / totalBilledAmount) * 100).clamp(0.0, 100.0);
  }

  MaintenanceLoaded copyWith({
    List<MaintenanceBill>? allBills,
    String? statusFilter,
    String? monthFilter,
    String? searchQuery,
    String? scope,
    bool? isActionInProgress,
    String? actionFeedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return MaintenanceLoaded(
      allBills: allBills ?? this.allBills,
      statusFilter: statusFilter ?? this.statusFilter,
      monthFilter: monthFilter ?? this.monthFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      scope: scope ?? this.scope,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      actionFeedbackMessage: clearFeedbackMessage
          ? null
          : (actionFeedbackMessage ?? this.actionFeedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        allBills,
        statusFilter,
        monthFilter,
        searchQuery,
        scope,
        isActionInProgress,
        actionFeedbackMessage,
      ];
}

class MaintenanceFailure extends MaintenanceState {
  final String errorMessage;

  const MaintenanceFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
