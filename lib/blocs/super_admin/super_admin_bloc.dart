import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/super_admin_service.dart';
import 'super_admin_event.dart';
import 'super_admin_state.dart';

export 'super_admin_event.dart';
export 'super_admin_state.dart';

class SuperAdminBloc extends Bloc<SuperAdminEvent, SuperAdminState> {
  final SuperAdminService _superAdminService;

  SuperAdminBloc({SuperAdminService? superAdminService})
      : _superAdminService = superAdminService ?? SuperAdminService.instance,
        super(SuperAdminInitial()) {
    on<SuperAdminRefreshRequested>(_onRefreshRequested);
    on<SuperAdminDataLoaded>(_onDataLoaded);
    on<SuperAdminArchitectureFilterChanged>(_onArchitectureFilterChanged);
    on<SuperAdminSearchQueryChanged>(_onSearchQueryChanged);
    on<SuperAdminToggleSocietyStatusRequested>(_onToggleSocietyStatusRequested);
  }

  Future<void> _onRefreshRequested(
    SuperAdminRefreshRequested event,
    Emitter<SuperAdminState> emit,
  ) async {
    emit(SuperAdminLoading());
    try {
      final stats = await _superAdminService.fetchGlobalStats();
      final societies = await _superAdminService.fetchSocietiesList();
      emit(SuperAdminLoaded(
        stats: stats,
        societies: societies,
      ));
    } catch (e) {
      emit(SuperAdminFailure(e.toString()));
    }
  }

  void _onDataLoaded(
    SuperAdminDataLoaded event,
    Emitter<SuperAdminState> emit,
  ) {
    if (state is SuperAdminLoaded) {
      final current = state as SuperAdminLoaded;
      emit(current.copyWith(
        stats: event.stats,
        societies: event.societies,
      ));
    } else {
      emit(SuperAdminLoaded(
        stats: event.stats,
        societies: event.societies,
      ));
    }
  }

  void _onArchitectureFilterChanged(
    SuperAdminArchitectureFilterChanged event,
    Emitter<SuperAdminState> emit,
  ) {
    if (state is SuperAdminLoaded) {
      emit((state as SuperAdminLoaded).copyWith(architectureFilter: event.architectureFilter));
    }
  }

  void _onSearchQueryChanged(
    SuperAdminSearchQueryChanged event,
    Emitter<SuperAdminState> emit,
  ) {
    if (state is SuperAdminLoaded) {
      emit((state as SuperAdminLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onToggleSocietyStatusRequested(
    SuperAdminToggleSocietyStatusRequested event,
    Emitter<SuperAdminState> emit,
  ) async {
    try {
      if (state is SuperAdminLoaded) {
        emit((state as SuperAdminLoaded).copyWith(isActionInProgress: true));
      }

      await _superAdminService.toggleSocietyStatus(event.societyId, !event.suspend);

      final stats = await _superAdminService.fetchGlobalStats();
      final societies = await _superAdminService.fetchSocietiesList();

      final msg = event.suspend
          ? 'સોસાયટી સફળતાપૂર્વક સસ્પેન્ડ કરવામાં આવી.'
          : 'સોસાયટી સફળતાપૂર્વક પુનઃસક્રિય કરવામાં આવી.';

      emit(SuperAdminLoaded(
        stats: stats,
        societies: societies,
        feedbackMessage: msg,
      ));
    } catch (e) {
      if (state is SuperAdminLoaded) {
        emit((state as SuperAdminLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટેટસ અપડેટ ભૂલ: $e',
        ));
      }
    }
  }
}
