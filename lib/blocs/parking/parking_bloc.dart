import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../services/parking_slot_service.dart';
import 'parking_event.dart';
import 'parking_state.dart';

export 'parking_event.dart';
export 'parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final ParkingSlotService _parkingService;
  final FirebaseFirestore _firestore;
  StreamSubscription<List<ParkingSlotModel>>? _slotsSubscription;
  String _currentSocietyId = '';

  ParkingBloc({
    ParkingSlotService? parkingService,
    FirebaseFirestore? firestore,
  })  : _parkingService = parkingService ?? ParkingSlotService.instance,
        _firestore = firestore ?? AppFirestore.instance,
        super(ParkingInitial()) {
    on<ParkingSubscriptionRequested>(_onSubscriptionRequested);
    on<ParkingErrorOccurred>((event, emit) => emit(ParkingFailure(event.error)));
    on<ParkingSlotsUpdated>(_onSlotsUpdated);
    on<ParkingStatusFilterChanged>(_onStatusFilterChanged);
    on<ParkingTypeFilterChanged>(_onTypeFilterChanged);
    on<ParkingLevelFilterChanged>(_onLevelFilterChanged);
    on<ParkingSearchQueryChanged>(_onSearchQueryChanged);
    on<ParkingAssignSlotRequested>(_onAssignSlotRequested);
    on<ParkingReleaseSlotRequested>(_onReleaseSlotRequested);
    on<ParkingAddSlotRequested>(_onAddSlotRequested);
    on<ParkingDeleteSlotRequested>(_onDeleteSlotRequested);
  }

  void _onSubscriptionRequested(
    ParkingSubscriptionRequested event,
    Emitter<ParkingState> emit,
  ) {
    emit(ParkingLoading());
    _currentSocietyId = event.societyId;
    _slotsSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const ParkingLoaded());
      return;
    }

    final stream = (event.blockFilter != null &&
            event.blockFilter!.isNotEmpty &&
            event.blockFilter != 'ALL')
        ? _parkingService.streamRealSlotsForBlock(
            societyId: event.societyId,
            blockName: event.blockFilter!,
          )
        : _parkingService.streamAllRealSlots(event.societyId);

    _slotsSubscription = stream.listen(
      (slots) => add(ParkingSlotsUpdated(slots)),
      onError: (error) => add(ParkingErrorOccurred(error.toString())),
    );
  }

  void _onSlotsUpdated(
    ParkingSlotsUpdated event,
    Emitter<ParkingState> emit,
  ) {
    if (state is ParkingLoaded) {
      final current = state as ParkingLoaded;
      emit(current.copyWith(slots: event.slots));
    } else {
      emit(ParkingLoaded(slots: event.slots));
    }
  }

  void _onStatusFilterChanged(
    ParkingStatusFilterChanged event,
    Emitter<ParkingState> emit,
  ) {
    if (state is ParkingLoaded) {
      emit((state as ParkingLoaded).copyWith(statusFilter: event.statusFilter));
    }
  }

  void _onTypeFilterChanged(
    ParkingTypeFilterChanged event,
    Emitter<ParkingState> emit,
  ) {
    if (state is ParkingLoaded) {
      emit((state as ParkingLoaded).copyWith(typeFilter: event.slotType));
    }
  }

  void _onLevelFilterChanged(
    ParkingLevelFilterChanged event,
    Emitter<ParkingState> emit,
  ) {
    if (state is ParkingLoaded) {
      emit((state as ParkingLoaded).copyWith(levelFilter: event.level));
    }
  }

  void _onSearchQueryChanged(
    ParkingSearchQueryChanged event,
    Emitter<ParkingState> emit,
  ) {
    if (state is ParkingLoaded) {
      emit((state as ParkingLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onAssignSlotRequested(
    ParkingAssignSlotRequested event,
    Emitter<ParkingState> emit,
  ) async {
    try {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore
          .collection('societies')
          .doc(_currentSocietyId)
          .collection('parking_slots')
          .doc(event.slotId)
          .update({
        'isAssigned': true,
        'assignedMemberId': event.memberId,
        'assignedMemberName': event.memberName,
        'assignedFlat': event.flat,
        'assignedVehiclePlate': event.vehiclePlate,
        'assignedVehicleModel': event.vehicleModel,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પાર્કિંગ સ્લોટ સફળતાપૂર્વક ફાળવવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્લોટ ફાળવણી ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onReleaseSlotRequested(
    ParkingReleaseSlotRequested event,
    Emitter<ParkingState> emit,
  ) async {
    try {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore
          .collection('societies')
          .doc(_currentSocietyId)
          .collection('parking_slots')
          .doc(event.slotId)
          .update({
        'isAssigned': false,
        'assignedMemberId': null,
        'assignedMemberName': null,
        'assignedFlat': null,
        'assignedVehiclePlate': null,
        'assignedVehicleModel': null,
        'releasedAt': FieldValue.serverTimestamp(),
      });

      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પાર્કિંગ સ્લોટ મુક્ત કરવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્લોટ અન-એલોકેટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onAddSlotRequested(
    ParkingAddSlotRequested event,
    Emitter<ParkingState> emit,
  ) async {
    try {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(isActionInProgress: true));
      }

      final docRef = _firestore
          .collection('societies')
          .doc(_currentSocietyId)
          .collection('parking_slots')
          .doc();

      await docRef.set({
        'id': docRef.id,
        'societyId': _currentSocietyId,
        'slotNumber': event.slotNumber.trim(),
        'blockName': event.blockName.trim(),
        'category': event.category,
        'slotType': event.slotType,
        'level': event.level,
        'parkingZone': 'resident',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નવો પાર્કિંગ સ્લોટ ઉમેરાયો.',
        ));
      }
    } catch (e) {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્લોટ ઉમેરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteSlotRequested(
    ParkingDeleteSlotRequested event,
    Emitter<ParkingState> emit,
  ) async {
    try {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore
          .collection('societies')
          .doc(_currentSocietyId)
          .collection('parking_slots')
          .doc(event.slotId)
          .delete();

      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'પાર્કિંગ સ્લોટ ડિલીટ કર્યો.',
        ));
      }
    } catch (e) {
      if (state is ParkingLoaded) {
        emit((state as ParkingLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _slotsSubscription?.cancel();
    return super.close();
  }
}
