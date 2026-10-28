import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/society_expense_model.dart';
import '../../services/society_accounts_service.dart';
import 'society_accounts_event.dart';
import 'society_accounts_state.dart';

export 'society_accounts_event.dart';
export 'society_accounts_state.dart';

class SocietyAccountsBloc extends Bloc<SocietyAccountsEvent, SocietyAccountsState> {
  final SocietyAccountsService _accountsService;
  StreamSubscription<List<SocietyExpense>>? _expensesSubscription;
  String _currentSocietyId = '';

  SocietyAccountsBloc({SocietyAccountsService? accountsService})
      : _accountsService = accountsService ?? SocietyAccountsService.instance,
        super(SocietyAccountsInitial()) {
    on<AccountsSubscriptionRequested>(_onSubscriptionRequested);
    on<AccountsErrorOccurred>((event, emit) => emit(SocietyAccountsFailure(event.error)));
    on<AccountsExpensesUpdated>(_onExpensesUpdated);
    on<AccountsSummaryUpdated>(_onSummaryUpdated);
    on<AccountsCategoryFilterChanged>(_onCategoryFilterChanged);
    on<AccountsSearchQueryChanged>(_onSearchQueryChanged);
    on<AccountsRecordExpenseRequested>(_onRecordExpenseRequested);
    on<AccountsDeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<AccountsRefreshSummaryRequested>(_onRefreshSummaryRequested);
  }

  void _onSubscriptionRequested(
    AccountsSubscriptionRequested event,
    Emitter<SocietyAccountsState> emit,
  ) {
    emit(SocietyAccountsLoading());
    _currentSocietyId = event.societyId;
    _expensesSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(SocietyAccountsLoaded(financialSummary: SocietyFinancialSummary.empty()));
      return;
    }

    _expensesSubscription = _accountsService
        .streamExpenses(societyId: event.societyId, blockFilter: event.blockFilter)
        .listen(
          (expenses) => add(AccountsExpensesUpdated(expenses)),
          onError: (error) => add(AccountsErrorOccurred(error.toString())),
        );

    // Initial summary fetch
    add(AccountsRefreshSummaryRequested(event.societyId));
  }

  void _onExpensesUpdated(
    AccountsExpensesUpdated event,
    Emitter<SocietyAccountsState> emit,
  ) {
    if (state is SocietyAccountsLoaded) {
      final current = state as SocietyAccountsLoaded;
      emit(current.copyWith(expenses: event.expenses));
    } else {
      emit(SocietyAccountsLoaded(
        expenses: event.expenses,
        financialSummary: SocietyFinancialSummary.empty(),
      ));
    }
  }

  void _onSummaryUpdated(
    AccountsSummaryUpdated event,
    Emitter<SocietyAccountsState> emit,
  ) {
    if (state is SocietyAccountsLoaded) {
      final current = state as SocietyAccountsLoaded;
      emit(current.copyWith(financialSummary: event.summary));
    } else {
      emit(SocietyAccountsLoaded(financialSummary: event.summary));
    }
  }

  void _onCategoryFilterChanged(
    AccountsCategoryFilterChanged event,
    Emitter<SocietyAccountsState> emit,
  ) {
    if (state is SocietyAccountsLoaded) {
      emit((state as SocietyAccountsLoaded).copyWith(categoryFilter: event.categoryKey));
    }
  }

  void _onSearchQueryChanged(
    AccountsSearchQueryChanged event,
    Emitter<SocietyAccountsState> emit,
  ) {
    if (state is SocietyAccountsLoaded) {
      emit((state as SocietyAccountsLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onRecordExpenseRequested(
    AccountsRecordExpenseRequested event,
    Emitter<SocietyAccountsState> emit,
  ) async {
    try {
      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(isActionInProgress: true));
      }

      await _accountsService.recordExpense(
        title: event.title,
        categoryKey: event.categoryKey,
        amount: event.amount,
        expenseDate: event.expenseDate,
        paidTo: event.paidTo,
        paymentMode: event.paymentMode,
        notes: event.notes,
        billReceiptUrl: event.billReceiptUrl,
        scope: event.scope,
        targetBlock: event.targetBlock,
      );

      if (_currentSocietyId.isNotEmpty) {
        final summary = await _accountsService.calculateFinancialSummary(societyId: _currentSocietyId);
        add(AccountsSummaryUpdated(summary));
      }

      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ખર્ચ સફળતાપૂર્વક નોંધાયો.',
        ));
      }
    } catch (e) {
      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ખર્ચ નોંધણી ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteExpenseRequested(
    AccountsDeleteExpenseRequested event,
    Emitter<SocietyAccountsState> emit,
  ) async {
    try {
      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(isActionInProgress: true));
      }

      await _accountsService.deleteExpense(event.expenseId);

      if (_currentSocietyId.isNotEmpty) {
        final summary = await _accountsService.calculateFinancialSummary(societyId: _currentSocietyId);
        add(AccountsSummaryUpdated(summary));
      }

      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ખર્ચ રદ કરવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is SocietyAccountsLoaded) {
        emit((state as SocietyAccountsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onRefreshSummaryRequested(
    AccountsRefreshSummaryRequested event,
    Emitter<SocietyAccountsState> emit,
  ) async {
    try {
      final summary = await _accountsService.calculateFinancialSummary(societyId: event.societyId);
      add(AccountsSummaryUpdated(summary));
    } catch (_) {
      // Ignored: keep existing summary or empty
    }
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    return super.close();
  }
}
