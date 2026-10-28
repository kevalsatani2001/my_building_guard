import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/poll_model.dart';
import '../../services/society_poll_service.dart';
import 'polls_event.dart';
import 'polls_state.dart';

export 'polls_event.dart';
export 'polls_state.dart';

class PollsBloc extends Bloc<PollsEvent, PollsState> {
  final SocietyPollService _pollService;
  StreamSubscription<List<PollModel>>? _pollsSubscription;

  PollsBloc({SocietyPollService? pollService})
      : _pollService = pollService ?? SocietyPollService.instance,
        super(PollsInitial()) {
    on<PollsSubscriptionRequested>(_onSubscriptionRequested);
    on<PollsErrorOccurred>((event, emit) => emit(PollsFailure(event.error)));
    on<PollsUpdated>(_onPollsUpdated);
    on<PollsFilterChanged>(_onFilterChanged);
    on<PollsSearchQueryChanged>(_onSearchQueryChanged);
    on<PollCreateRequested>(_onCreateRequested);
    on<PollCastVoteRequested>(_onCastVoteRequested);
    on<PollCloseRequested>(_onCloseRequested);
    on<PollDeleteRequested>(_onDeleteRequested);
  }

  void _onSubscriptionRequested(
    PollsSubscriptionRequested event,
    Emitter<PollsState> emit,
  ) {
    emit(PollsLoading());
    _pollsSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const PollsLoaded());
      return;
    }

    _pollsSubscription = _pollService
        .getPollsStream(blockScope: event.blockScope)
        .listen(
          (polls) => add(PollsUpdated(polls)),
          onError: (error) => add(PollsErrorOccurred(error.toString())),
        );
  }

  void _onPollsUpdated(
    PollsUpdated event,
    Emitter<PollsState> emit,
  ) {
    if (state is PollsLoaded) {
      final current = state as PollsLoaded;
      emit(current.copyWith(polls: event.polls));
    } else {
      emit(PollsLoaded(polls: event.polls));
    }
  }

  void _onFilterChanged(
    PollsFilterChanged event,
    Emitter<PollsState> emit,
  ) {
    if (state is PollsLoaded) {
      emit((state as PollsLoaded).copyWith(statusFilter: event.statusFilter));
    }
  }

  void _onSearchQueryChanged(
    PollsSearchQueryChanged event,
    Emitter<PollsState> emit,
  ) {
    if (state is PollsLoaded) {
      emit((state as PollsLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onCreateRequested(
    PollCreateRequested event,
    Emitter<PollsState> emit,
  ) async {
    try {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(isActionInProgress: true));
      }

      await _pollService.createPoll(
        title: event.title,
        description: event.description,
        optionTexts: event.optionTexts,
        endDate: event.endDate,
        startDate: event.startDate,
        targetScope: event.targetScope,
        voterEligibility: event.voterEligibility,
        isAnonymous: event.isAnonymous,
        createdByName: event.createdByName,
      );

      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નવો નિર્ણય મતદાન સફળતાપૂર્વક શરૂ થયો.',
        ));
      }
    } catch (e) {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પોલ બનાવવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onCastVoteRequested(
    PollCastVoteRequested event,
    Emitter<PollsState> emit,
  ) async {
    try {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(isActionInProgress: true));
      }

      await _pollService.castVote(
        pollId: event.pollId,
        optionId: event.optionId,
        flatDisplay: event.flatDisplay,
      );

      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'તમારો કિંમતી મત સફળતાપૂર્વક નોંધાઈ ગયો છે. ✅',
        ));
      }
    } catch (e) {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: '$e',
        ));
      }
    }
  }

  Future<void> _onCloseRequested(
    PollCloseRequested event,
    Emitter<PollsState> emit,
  ) async {
    try {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(isActionInProgress: true));
      }

      await _pollService.closePoll(
        pollId: event.pollId,
        resolutionSummary: event.resolutionSummary,
      );

      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'મતદાન બંધ કરી પરિણામ જાહેર કરાયું.',
        ));
      }
    } catch (e) {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પોલ બંધ કરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteRequested(
    PollDeleteRequested event,
    Emitter<PollsState> emit,
  ) async {
    try {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(isActionInProgress: true));
      }

      await _pollService.deletePoll(event.pollId);

      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'મતદાન કાઢી નાખવામાં આવ્યું.',
        ));
      }
    } catch (e) {
      if (state is PollsLoaded) {
        emit((state as PollsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પોલ ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _pollsSubscription?.cancel();
    return super.close();
  }
}
