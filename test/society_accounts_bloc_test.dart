import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/society_expense_model.dart';
import 'package:building_guard/services/society_accounts_service.dart';
import 'package:building_guard/blocs/accounts/society_accounts_bloc.dart';

void main() {
  group('SocietyAccountsBloc State and Accounting Aggregate Tests', () {
    final now = DateTime.now();

    final testExpense1 = SocietyExpense(
      id: 'e1',
      societyId: 'soc123',
      title: 'Watchman Monthly Salary',
      categoryKey: 'watchman_salary',
      amount: 12000.0,
      expenseDate: now.subtract(const Duration(days: 2)),
      paidTo: 'Ramu Watchman',
      paymentMode: 'cash',
      recordedBy: 'admin1',
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final testExpense2 = SocietyExpense(
      id: 'e2',
      societyId: 'soc123',
      title: 'Common Electricity Bill',
      categoryKey: 'electricity_common',
      amount: 4500.0,
      expenseDate: now.subtract(const Duration(days: 5)),
      paidTo: 'MGVCL Board',
      paymentMode: 'upi',
      recordedBy: 'admin1',
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final testExpense3 = SocietyExpense(
      id: 'e3',
      societyId: 'soc123',
      title: 'Lift AMC Quarterly',
      categoryKey: 'lift_amc',
      amount: 8000.0,
      expenseDate: now.subtract(const Duration(days: 10)),
      paidTo: 'Otis Elevator',
      paymentMode: 'bank_transfer',
      recordedBy: 'admin1',
      createdAt: now.subtract(const Duration(days: 10)),
    );

    test('SocietyAccountsLoaded computes correct cash and digital totals', () {
      final state = SocietyAccountsLoaded(
        expenses: [testExpense1, testExpense2, testExpense3],
        financialSummary: SocietyFinancialSummary.empty(),
      );

      expect(state.totalExpensesAmount, 24500.0);
      expect(state.cashExpensesTotal, 12000.0);
      expect(state.digitalExpensesTotal, 12500.0); // 4500 (upi) + 8000 (bank)
    });

    test('SocietyAccountsLoaded filters by category properly', () {
      final state = SocietyAccountsLoaded(
        expenses: [testExpense1, testExpense2, testExpense3],
        financialSummary: SocietyFinancialSummary.empty(),
        categoryFilter: 'watchman_salary',
      );

      final filtered = state.filteredExpenses;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'e1');
      expect(state.totalFilteredExpensesAmount, 12000.0);
    });

    test('SocietyAccountsLoaded search query filters across title and paidTo', () {
      final stateSearchVendor = SocietyAccountsLoaded(
        expenses: [testExpense1, testExpense2, testExpense3],
        financialSummary: SocietyFinancialSummary.empty(),
        searchQuery: 'otis',
      );
      expect(stateSearchVendor.filteredExpenses.length, 1);
      expect(stateSearchVendor.filteredExpenses.first.id, 'e3');

      final stateSearchTitle = SocietyAccountsLoaded(
        expenses: [testExpense1, testExpense2, testExpense3],
        financialSummary: SocietyFinancialSummary.empty(),
        searchQuery: 'electricity',
      );
      expect(stateSearchTitle.filteredExpenses.length, 1);
      expect(stateSearchTitle.filteredExpenses.first.id, 'e2');
    });

    test('SocietyAccountsLoaded copyWith handles updates without mutating state', () {
      final state1 = SocietyAccountsLoaded(
        expenses: [testExpense1],
        financialSummary: SocietyFinancialSummary.empty(),
      );

      final state2 = state1.copyWith(
        categoryFilter: 'watchman_salary',
        searchQuery: 'ramu',
        isActionInProgress: true,
      );

      expect(state1.categoryFilter, 'all');
      expect(state2.categoryFilter, 'watchman_salary');
      expect(state2.searchQuery, 'ramu');
      expect(state2.isActionInProgress, true);
    });
  });
}
