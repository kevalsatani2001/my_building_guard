import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/patrol_model.dart';
import '../../services/guard_patrol_service.dart';
import 'guard_patrol_event.dart';
import 'guard_patrol_state.dart';

export 'guard_patrol_event.dart';
export 'guard_patrol_state.dart';

class GuardPatrolBloc extends Bloc<GuardPatrolEvent, GuardPatrolState> {
  final GuardPatrolService _patrolService;
  StreamSubscription<List<PatrolCheckpoint>>? _checkpointsSubscription;
  StreamSubscription<PatrolShiftSession?>? _activeSessionSubscription;

  String _currentSocietyId = '';

  GuardPatrolBloc({GuardPatrolService? patrolService})
      : _patrolService = patrolService ?? GuardPatrolService(),
        super(GuardPatrolInitial()) {
    on<PatrolSubscriptionRequested>(_onSubscriptionRequested);
    on<PatrolErrorOccurred>((event, emit) => emit(GuardPatrolFailure(event.error)));
    on<PatrolCheckpointsUpdated>(_onCheckpointsUpdated);
    on<PatrolActiveSessionUpdated>(_onActiveSessionUpdated);
    on<PatrolSessionsHistoryUpdated>(_onSessionsHistoryUpdated);
    on<PatrolAddCheckpointRequested>(_onAddCheckpointRequested);
    on<PatrolDeleteCheckpointRequested>(_onDeleteCheckpointRequested);
    on<PatrolStartRoundRequested>(_onStartRoundRequested);
    on<PatrolScanQrRequested>(_onScanQrRequested);
    on<PatrolFinishRoundRequested>(_onFinishRoundRequested);
  }

  void _onSubscriptionRequested(
    PatrolSubscriptionRequested event,
    Emitter<GuardPatrolState> emit,
  ) {
    emit(GuardPatrolLoading());
    _currentSocietyId = event.societyId;

    _checkpointsSubscription?.cancel();
    _activeSessionSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const GuardPatrolLoaded());
      return;
    }

    _checkpointsSubscription = _patrolService
        .streamCheckpoints(event.societyId)
        .listen(
          (checkpoints) => add(PatrolCheckpointsUpdated(checkpoints)),
          onError: (error) => add(PatrolErrorOccurred(error.toString())),
        );

    if (event.guardUid != null && event.guardUid!.isNotEmpty) {
      _activeSessionSubscription = _patrolService
          .streamActiveSession(event.societyId, event.guardUid!)
          .listen(
            (session) => add(PatrolActiveSessionUpdated(session)),
            onError: (error) => add(PatrolErrorOccurred(error.toString())),
          );
    }
  }

  void _onCheckpointsUpdated(
    PatrolCheckpointsUpdated event,
    Emitter<GuardPatrolState> emit,
  ) {
    if (state is GuardPatrolLoaded) {
      final current = state as GuardPatrolLoaded;
      emit(current.copyWith(checkpoints: event.checkpoints));
    } else {
      emit(GuardPatrolLoaded(checkpoints: event.checkpoints));
    }
  }

  void _onActiveSessionUpdated(
    PatrolActiveSessionUpdated event,
    Emitter<GuardPatrolState> emit,
  ) {
    if (state is GuardPatrolLoaded) {
      final current = state as GuardPatrolLoaded;
      emit(current.copyWith(
        activeSession: event.activeSession,
        clearActiveSession: event.activeSession == null,
      ));
    } else {
      emit(GuardPatrolLoaded(activeSession: event.activeSession));
    }
  }

  void _onSessionsHistoryUpdated(
    PatrolSessionsHistoryUpdated event,
    Emitter<GuardPatrolState> emit,
  ) {
    if (state is GuardPatrolLoaded) {
      final current = state as GuardPatrolLoaded;
      emit(current.copyWith(pastSessions: event.sessions));
    } else {
      emit(GuardPatrolLoaded(pastSessions: event.sessions));
    }
  }

  Future<void> _onAddCheckpointRequested(
    PatrolAddCheckpointRequested event,
    Emitter<GuardPatrolState> emit,
  ) async {
    try {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(isActionInProgress: true));
      }

      await _patrolService.addCheckpoint(
        societyId: _currentSocietyId,
        code: event.code,
        name: event.name,
        location: event.location,
        order: event.order,
        notes: event.notes,
      );

      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'નવો સુરક્ષા ચેકપોઇન્ટ ઉમેરાયો.',
        ));
      }
    } catch (e) {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'ચેકપોઇન્ટ ઉમેરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteCheckpointRequested(
    PatrolDeleteCheckpointRequested event,
    Emitter<GuardPatrolState> emit,
  ) async {
    try {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(isActionInProgress: true));
      }

      await _patrolService.deleteCheckpoint(_currentSocietyId, event.checkpointId);

      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'ચેકપોઇન્ટ કાઢી નાખવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onStartRoundRequested(
    PatrolStartRoundRequested event,
    Emitter<GuardPatrolState> emit,
  ) async {
    try {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(isActionInProgress: true));
      }

      final activeCheckpoints = (state is GuardPatrolLoaded)
          ? (state as GuardPatrolLoaded).checkpoints.where((c) => c.isActive).length
          : 0;

      final session = await _patrolService.startPatrolRound(
        societyId: _currentSocietyId,
        guardUid: event.guardUid,
        guardName: event.guardName,
        guardPhone: event.guardPhone,
        roundNumber: event.roundNumber,
        roundLabel: event.roundLabel,
        totalCheckpoints: activeCheckpoints,
      );

      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          activeSession: session,
          actionFeedbackMessage: 'રાઉન્ડ #${event.roundNumber} શરૂ થયો.',
        ));
      }
    } catch (e) {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'રાઉન્ડ શરૂ કરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onScanQrRequested(
    PatrolScanQrRequested event,
    Emitter<GuardPatrolState> emit,
  ) async {
    try {
      if (state is GuardPatrolLoaded) {
        final current = state as GuardPatrolLoaded;
        if (current.activeSession == null) {
          emit(current.copyWith(actionFeedbackMessage: 'કોઈ પેટ્રોલિંગ રાઉન્ડ ચાલુ નથી!'));
          return;
        }

        emit(current.copyWith(isActionInProgress: true));

        final res = await _patrolService.scanCheckpoint(
          societyId: _currentSocietyId,
          sessionId: current.activeSession!.id,
          qrPayload: event.qrPayload,
          guardUid: event.guardUid,
          guardName: event.guardName,
          incidentNote: event.incidentNote,
        );

        emit(current.copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: res['message']?.toString() ?? 'સ્કેન પ્રક્રિયા પૂર્ણ થઈ.',
        ));
      }
    } catch (e) {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'સ્કેન ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onFinishRoundRequested(
    PatrolFinishRoundRequested event,
    Emitter<GuardPatrolState> emit,
  ) async {
    try {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(isActionInProgress: true));
      }

      await _patrolService.completePatrolRound(
        societyId: _currentSocietyId,
        sessionId: event.sessionId,
      );

      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          clearActiveSession: true,
          actionFeedbackMessage: 'પેટ્રોલિંગ રાઉન્ડ સફળતાપૂર્વક પૂર્ણ થયો.',
        ));
      }
    } catch (e) {
      if (state is GuardPatrolLoaded) {
        emit((state as GuardPatrolLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'રાઉન્ડ સમાપ્ત કરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _checkpointsSubscription?.cancel();
    _activeSessionSubscription?.cancel();
    return super.close();
  }
}
