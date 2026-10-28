import 'package:equatable/equatable.dart';
import '../../models/society_expense_model.dart';
import '../../services/society_accounts_service.dart';

abstract class SocietyAccountsEvent extends Equatable {
  const SocietyAccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to expenses and financial summary for society
class AccountsSubscriptionRequested extends SocietyAccountsEvent {
  final String societyId;
  final String? blockFilter;

  const AccountsSubscriptionRequested({
    required this.societyId,
    this.blockFilter,
  });

  @override
  List<Object?> get props => [societyId, blockFilter];
}

/// Internal event fired when expenses stream updates
class AccountsExpensesUpdated extends SocietyAccountsEvent {
  final List<SocietyExpense> expenses;

  const AccountsExpensesUpdated(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

/// Internal event fired when expenses stream fails
class AccountsErrorOccurred extends SocietyAccountsEvent {
  final String error;

  const AccountsErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Internal event fired when financial summary recalculates
class AccountsSummaryUpdated extends SocietyAccountsEvent {
  final SocietyFinancialSummary summary;

  const AccountsSummaryUpdated(this.summary);

  @override
  List<Object?> get props => [
        summary.totalIncome,
        summary.totalExpenses,
        summary.currentSavings,
        summary.paidBillsCount,
      ];
}

/// Change category filter ('all' or specific category key like 'watchman_salary', 'repairs_maintenance')
class AccountsCategoryFilterChanged extends SocietyAccountsEvent {
  final String categoryKey;

  const AccountsCategoryFilterChanged(this.categoryKey);

  @override
  List<Object?> get props => [categoryKey];
}

/// Change search query (title, paidTo, notes)
class AccountsSearchQueryChanged extends SocietyAccountsEvent {
  final String query;

  const AccountsSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Record a new expense
class AccountsRecordExpenseRequested extends SocietyAccountsEvent {
  final String title;
  final String categoryKey;
  final double amount;
  final DateTime expenseDate;
  final String paidTo;
  final String paymentMode; // 'cash', 'upi', 'bank_transfer', 'cheque'
  final String notes;
  final String billReceiptUrl;
  final String scope; // 'common' or 'block'
  final String targetBlock;

  const AccountsRecordExpenseRequested({
    required this.title,
    required this.categoryKey,
    required this.amount,
    required this.expenseDate,
    required this.paidTo,
    this.paymentMode = 'cash',
    this.notes = '',
    this.billReceiptUrl = '',
    this.scope = 'common',
    this.targetBlock = 'ALL',
  });

  @override
  List<Object?> get props => [
        title,
        categoryKey,
        amount,
        expenseDate,
        paidTo,
        paymentMode,
        notes,
        billReceiptUrl,
        scope,
        targetBlock,
      ];
}

/// Delete an expense record
class AccountsDeleteExpenseRequested extends SocietyAccountsEvent {
  final String expenseId;

  const AccountsDeleteExpenseRequested(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

/// Trigger on-demand financial summary refresh
class AccountsRefreshSummaryRequested extends SocietyAccountsEvent {
  final String societyId;

  const AccountsRefreshSummaryRequested(this.societyId);

  @override
  List<Object?> get props => [societyId];
}
