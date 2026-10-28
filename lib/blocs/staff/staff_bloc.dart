import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/staff_model.dart';
import 'staff_event.dart';
import 'staff_state.dart';

export 'staff_event.dart';
export 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _staffSubscription;
  String _currentSocietyId = '';

  StaffBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance,
        super(StaffInitial()) {
    on<StaffSubscriptionRequested>(_onSubscriptionRequested);
    on<StaffErrorOccurred>((event, emit) => emit(StaffFailure(event.error)));
    on<StaffListUpdated>(_onStaffListUpdated);
    on<StaffRoleFilterChanged>(_onRoleFilterChanged);
    on<StaffSearchQueryChanged>(_onSearchQueryChanged);
    on<StaffAddRequested>(_onAddRequested);
    on<StaffDeleteRequested>(_onDeleteRequested);
  }

  void _onSubscriptionRequested(
    StaffSubscriptionRequested event,
    Emitter<StaffState> emit,
  ) {
    emit(StaffLoading());
    _currentSocietyId = event.societyId;
    _staffSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(StaffLoaded(scope: event.scope));
      return;
    }

    Query query = _firestore
        .collection('daily_staff')
        .where('societyId', isEqualTo: event.societyId.trim());

    if (event.scope == 'my_staff' && event.memberId != null && event.memberId!.isNotEmpty) {
      query = query.where('memberId', isEqualTo: event.memberId);
    }

    _staffSubscription = query.snapshots().listen(
      (snapshot) {
        final list = snapshot.docs.map((d) => DailyStaffModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        add(StaffListUpdated(list));
      },
      onError: (error) => add(StaffErrorOccurred(error.toString())),
    );
  }

  void _onStaffListUpdated(
    StaffListUpdated event,
    Emitter<StaffState> emit,
  ) {
    if (state is StaffLoaded) {
      final current = state as StaffLoaded;
      emit(current.copyWith(staffList: event.staffList));
    } else {
      emit(StaffLoaded(staffList: event.staffList));
    }
  }

  void _onRoleFilterChanged(
    StaffRoleFilterChanged event,
    Emitter<StaffState> emit,
  ) {
    if (state is StaffLoaded) {
      emit((state as StaffLoaded).copyWith(roleFilter: event.role));
    }
  }

  void _onSearchQueryChanged(
    StaffSearchQueryChanged event,
    Emitter<StaffState> emit,
  ) {
    if (state is StaffLoaded) {
      emit((state as StaffLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onAddRequested(
    StaffAddRequested event,
    Emitter<StaffState> emit,
  ) async {
    try {
      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('daily_staff').add({
        'societyId': _currentSocietyId,
        'memberId': event.memberId,
        'staffName': event.staffName.trim(),
        'staffPhone': event.staffPhone.trim(),
        'staffRole': event.staffRole.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટાફ સફળતાપૂર્વક ઉમેરાઈ ગયો.',
        ));
      }
    } catch (e) {
      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટાફ ઉમેરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteRequested(
    StaffDeleteRequested event,
    Emitter<StaffState> emit,
  ) async {
    try {
      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('daily_staff').doc(event.staffId).delete();

      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટાફ રેકોર્ડ કાઢી નાખવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _staffSubscription?.cancel();
    return super.close();
  }
}
