import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/amenity_model.dart';
import '../../services/amenity_booking_service.dart';
import 'amenities_event.dart';
import 'amenities_state.dart';

export 'amenities_event.dart';
export 'amenities_state.dart';

class AmenitiesBloc extends Bloc<AmenitiesEvent, AmenitiesState> {
  final AmenityBookingService _service;
  StreamSubscription<List<AmenityModel>>? _amenitiesSub;
  StreamSubscription<List<AmenityBookingModel>>? _bookingsSub;
  StreamSubscription<bool>? _enabledSub;

  AmenitiesBloc({AmenityBookingService? service})
      : _service = service ?? AmenityBookingService.instance,
        super(AmenitiesInitial()) {
    on<AmenitiesSubscriptionRequested>(_onSubscriptionRequested);
    on<AmenitiesErrorOccurred>(_onErrorOccurred);
    on<AmenitiesListUpdated>(_onAmenitiesListUpdated);
    on<AmenityBookingsUpdated>(_onBookingsUpdated);
    on<AmenitiesEnabledStatusUpdated>(_onEnabledStatusUpdated);
    on<AmenityStatusFilterChanged>(_onStatusFilterChanged);
    on<AmenitySearchQueryChanged>(_onSearchQueryChanged);
    on<AmenitySaveRequested>(_onSaveRequested);
    on<AmenityDeleteRequested>(_onDeleteRequested);
    on<AmenityBookRequested>(_onBookRequested);
    on<AmenityUpdateBookingStatusRequested>(_onUpdateBookingStatusRequested);
  }

  void _onErrorOccurred(
    AmenitiesErrorOccurred event,
    Emitter<AmenitiesState> emit,
  ) {
    emit(AmenitiesFailure(event.error));
  }

  void _onSubscriptionRequested(
    AmenitiesSubscriptionRequested event,
    Emitter<AmenitiesState> emit,
  ) {
    emit(AmenitiesLoading());
    _amenitiesSub?.cancel();
    _bookingsSub?.cancel();
    _enabledSub?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const AmenitiesLoaded());
      return;
    }

    _enabledSub = _service.hasAmenitiesStream().listen(
          (enabled) => add(AmenitiesEnabledStatusUpdated(enabled)),
          onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
        );

    if (event.role == 'admin') {
      _amenitiesSub = _service.getAllAmenitiesAdminStream().listen(
            (list) => add(AmenitiesListUpdated(list)),
            onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
          );
      _bookingsSub = _service.getAllBookingsAdminStream().listen(
            (list) => add(AmenityBookingsUpdated(list)),
            onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
          );
    } else if (event.role == 'watchman') {
      _amenitiesSub = _service.getActiveAmenitiesStream().listen(
            (list) => add(AmenitiesListUpdated(list)),
            onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
          );
      _bookingsSub = _service.getTodayEventsStream().listen(
            (list) => add(AmenityBookingsUpdated(list)),
            onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
          );
    } else {
      // member
      _amenitiesSub = _service.getActiveAmenitiesStream().listen(
            (list) => add(AmenitiesListUpdated(list)),
            onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
          );
      if (event.memberUid != null && event.memberUid!.isNotEmpty) {
        _bookingsSub = _service.getMemberBookingsStream(event.memberUid!).listen(
              (list) => add(AmenityBookingsUpdated(list)),
              onError: (error) => add(AmenitiesErrorOccurred(error.toString())),
            );
      }
    }
  }

  void _onAmenitiesListUpdated(
    AmenitiesListUpdated event,
    Emitter<AmenitiesState> emit,
  ) {
    if (state is AmenitiesLoaded) {
      final current = state as AmenitiesLoaded;
      emit(current.copyWith(amenities: event.amenities));
    } else {
      emit(AmenitiesLoaded(amenities: event.amenities));
    }
  }

  void _onBookingsUpdated(
    AmenityBookingsUpdated event,
    Emitter<AmenitiesState> emit,
  ) {
    if (state is AmenitiesLoaded) {
      final current = state as AmenitiesLoaded;
      emit(current.copyWith(bookings: event.bookings));
    } else {
      emit(AmenitiesLoaded(bookings: event.bookings));
    }
  }

  void _onEnabledStatusUpdated(
    AmenitiesEnabledStatusUpdated event,
    Emitter<AmenitiesState> emit,
  ) {
    if (state is AmenitiesLoaded) {
      final current = state as AmenitiesLoaded;
      emit(current.copyWith(isAmenitiesEnabled: event.isEnabled));
    } else {
      emit(AmenitiesLoaded(isAmenitiesEnabled: event.isEnabled));
    }
  }

  void _onStatusFilterChanged(
    AmenityStatusFilterChanged event,
    Emitter<AmenitiesState> emit,
  ) {
    if (state is AmenitiesLoaded) {
      emit((state as AmenitiesLoaded).copyWith(statusFilter: event.statusFilter));
    }
  }

  void _onSearchQueryChanged(
    AmenitySearchQueryChanged event,
    Emitter<AmenitiesState> emit,
  ) {
    if (state is AmenitiesLoaded) {
      emit((state as AmenitiesLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onSaveRequested(
    AmenitySaveRequested event,
    Emitter<AmenitiesState> emit,
  ) async {
    try {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(isActionInProgress: true));
      }

      await _service.saveAmenity(
        id: event.id,
        name: event.name,
        category: event.category,
        capacity: event.capacity,
        description: event.description,
        isPaid: event.isPaid,
        rentAmount: event.rentAmount,
        securityDeposit: event.securityDeposit,
        slotType: event.slotType,
        availableSlots: event.availableSlots,
        rulesAndTerms: event.rulesAndTerms,
        isActive: event.isActive,
      );

      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'એમેનિટી સફળતાપૂર્વક સાચવવામાં આવી.',
        ));
      }
    } catch (e) {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સાચવવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteRequested(
    AmenityDeleteRequested event,
    Emitter<AmenitiesState> emit,
  ) async {
    try {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(isActionInProgress: true));
      }

      await _service.deleteAmenity(event.amenityId);

      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'એમેનિટી કાઢી નાખવામાં આવી.',
        ));
      }
    } catch (e) {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onBookRequested(
    AmenityBookRequested event,
    Emitter<AmenitiesState> emit,
  ) async {
    try {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(isActionInProgress: true));
      }

      await _service.submitBookingRequest(
        amenity: event.amenity,
        bookingDate: event.bookingDate,
        slotName: event.slotName,
        purpose: event.purpose,
        expectedGuests: event.expectedGuests,
        memberName: event.memberName,
        memberPhone: event.memberPhone,
        unitDisplay: event.unitDisplay,
      );

      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'બુકિંગ રિક્વેસ્ટ સફળતાપૂર્વક સબમિટ થઈ.',
        ));
      }
    } catch (e) {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: '$e',
        ));
      }
    }
  }

  Future<void> _onUpdateBookingStatusRequested(
    AmenityUpdateBookingStatusRequested event,
    Emitter<AmenitiesState> emit,
  ) async {
    try {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(isActionInProgress: true));
      }

      await _service.updateBookingStatus(
        bookingId: event.bookingId,
        status: event.status,
        adminRemarks: event.adminRemarks,
      );

      final msg = event.status == 'approved'
          ? 'બુકિંગ મંજૂર કરવામાં આવ્યું.'
          : 'બુકિંગ અસ્વીકાર / રદ કરવામાં આવ્યું.';

      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: msg,
        ));
      }
    } catch (e) {
      if (state is AmenitiesLoaded) {
        emit((state as AmenitiesLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટેટસ અપડેટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _amenitiesSub?.cancel();
    _bookingsSub?.cancel();
    _enabledSub?.cancel();
    return super.close();
  }
}
