import 'package:equatable/equatable.dart';
import '../../models/society_expense_model.dart';
import '../../services/society_accounts_service.dart';

abstract class SocietyAccountsState extends Equatable {
  const SocietyAccountsState();

  @override
  List<Object?> get props => [];
}

class SocietyAccountsInitial extends SocietyAccountsState {}

class SocietyAccountsLoading extends SocietyAccountsState {}

class SocietyAccountsLoaded extends SocietyAccountsState {
  final List<SocietyExpense> expenses;
  final SocietyFinancialSummary financialSummary;
  final String categoryFilter;
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const SocietyAccountsLoaded({
    this.expenses = const [],
    required this.financialSummary,
    this.categoryFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered expense entries based on category and search query
  List<SocietyExpense> get filteredExpenses {
    final query = searchQuery.trim().toLowerCase();

    return expenses.where((exp) {
      // 1. Category Filter
      if (categoryFilter != 'all') {
        if (exp.categoryKey != categoryFilter) {
          return false;
        }
      }

      // 2. Search Query Filter (Title, PaidTo, Notes)
      if (query.isNotEmpty) {
        final matchesTitle = exp.title.toLowerCase().contains(query);
        final matchesPaidTo = exp.paidTo.toLowerCase().contains(query);
        final matchesNotes = exp.notes.toLowerCase().contains(query);
        final matchesCategory = exp.categoryKey.toLowerCase().contains(query);

        if (!matchesTitle && !matchesPaidTo && !matchesNotes && !matchesCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total amount spent across all loaded expenses
  double get totalExpensesAmount =>
      expenses.fold(0.0, (sum, exp) => sum + exp.amount);

  /// Total amount spent across filtered expenses
  double get totalFilteredExpensesAmount =>
      filteredExpenses.fold(0.0, (sum, exp) => sum + exp.amount);

  /// Cash expense total
  double get cashExpensesTotal => expenses
      .where((e) => e.paymentMode.toLowerCase() == 'cash')
      .fold(0.0, (sum, exp) => sum + exp.amount);

  /// Digital (UPI, Bank Transfer, Cheque) expense total
  double get digitalExpensesTotal => expenses
      .where((e) => e.paymentMode.toLowerCase() != 'cash')
      .fold(0.0, (sum, exp) => sum + exp.amount);

  SocietyAccountsLoaded copyWith({
    List<SocietyExpense>? expenses,
    SocietyFinancialSummary? financialSummary,
    String? categoryFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return SocietyAccountsLoaded(
      expenses: expenses ?? this.expenses,
      financialSummary: financialSummary ?? this.financialSummary,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        financialSummary.totalIncome,
        financialSummary.totalExpenses,
        financialSummary.currentSavings,
        categoryFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class SocietyAccountsFailure extends SocietyAccountsState {
  final String errorMessage;

  const SocietyAccountsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
