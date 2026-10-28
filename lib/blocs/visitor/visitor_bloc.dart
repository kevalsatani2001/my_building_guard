import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/visitor_model.dart';
import 'visitor_event.dart';
import 'visitor_state.dart';

export 'visitor_event.dart';
export 'visitor_state.dart';

class VisitorBloc extends Bloc<VisitorEvent, VisitorState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _visitorSubscription;

  VisitorBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance,
        super(VisitorInitial()) {
    on<VisitorSubscriptionRequested>(_onSubscriptionRequested);
    on<VisitorErrorOccurred>((event, emit) => emit(VisitorFailure(event.error)));
    on<VisitorsUpdated>(_onVisitorsUpdated);
    on<VisitorStatusFilterChanged>(_onStatusFilterChanged);
    on<VisitorTimeFilterChanged>(_onTimeFilterChanged);
    on<VisitorSearchQueryChanged>(_onSearchQueryChanged);
    on<VisitorApproveRequested>(_onApproveRequested);
    on<VisitorRejectRequested>(_onRejectRequested);
    on<VisitorCheckOutRequested>(_onCheckOutRequested);
    on<VisitorAddRequested>(_onAddRequested);
  }

  void _onSubscriptionRequested(
    VisitorSubscriptionRequested event,
    Emitter<VisitorState> emit,
  ) {
    emit(VisitorLoading());
    _visitorSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(VisitorLoaded(
        allVisitors: const [],
        scope: event.scope,
      ));
      return;
    }

    Query query = _firestore
        .collection('visitors')
        .where('societyId', isEqualTo: event.societyId.trim());

    _visitorSubscription = query.snapshots().listen(
      (snapshot) {
        final all = snapshot.docs.map((doc) => VisitorModel.fromFirestore(doc)).toList();
        all.sort((a, b) => b.entryTime.compareTo(a.entryTime));

        if (event.scope == 'my_flat') {
          final flatFiltered = all.where((v) {
            if (v.memberId == 'all_society') return true;
            if (event.memberId != null &&
                event.memberId!.isNotEmpty &&
                v.memberId == event.memberId) {
              return true;
            }
            if (event.unitNumber != null &&
                event.unitNumber!.isNotEmpty &&
                v.unitNumber.toLowerCase() == event.unitNumber!.toLowerCase()) {
              if (event.blockName != null &&
                  event.blockName!.isNotEmpty &&
                  v.blockName.isNotEmpty) {
                return v.blockName.toLowerCase() == event.blockName!.toLowerCase();
              }
              return true;
            }
            return false;
          }).toList();
          add(VisitorsUpdated(flatFiltered));
        } else {
          add(VisitorsUpdated(all));
        }
      },
      onError: (error) {
        add(VisitorErrorOccurred(error.toString()));
      },
    );
  }

  void _onVisitorsUpdated(
    VisitorsUpdated event,
    Emitter<VisitorState> emit,
  ) {
    if (state is VisitorLoaded) {
      final current = state as VisitorLoaded;
      emit(current.copyWith(allVisitors: event.visitors));
    } else {
      emit(VisitorLoaded(allVisitors: event.visitors));
    }
  }

  void _onStatusFilterChanged(
    VisitorStatusFilterChanged event,
    Emitter<VisitorState> emit,
  ) {
    if (state is VisitorLoaded) {
      emit((state as VisitorLoaded).copyWith(statusFilter: event.statusFilter));
    }
  }

  void _onTimeFilterChanged(
    VisitorTimeFilterChanged event,
    Emitter<VisitorState> emit,
  ) {
    if (state is VisitorLoaded) {
      emit((state as VisitorLoaded).copyWith(timeFilter: event.timeFilter));
    }
  }

  void _onSearchQueryChanged(
    VisitorSearchQueryChanged event,
    Emitter<VisitorState> emit,
  ) {
    if (state is VisitorLoaded) {
      emit((state as VisitorLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onApproveRequested(
    VisitorApproveRequested event,
    Emitter<VisitorState> emit,
  ) async {
    try {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(isActionInProgress: true));
      }
      await _firestore.collection('visitors').doc(event.visitorId).update({
        'status': 'approved',
        'actionTime': FieldValue.serverTimestamp(),
      });
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.',
        ));
      }
    } catch (e) {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'સ્ટેટસ અપડેટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onRejectRequested(
    VisitorRejectRequested event,
    Emitter<VisitorState> emit,
  ) async {
    try {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(isActionInProgress: true));
      }
      await _firestore.collection('visitors').doc(event.visitorId).update({
        'status': 'rejected',
        'actionTime': FieldValue.serverTimestamp(),
      });
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'સ્ટેટસ અપડેટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onCheckOutRequested(
    VisitorCheckOutRequested event,
    Emitter<VisitorState> emit,
  ) async {
    try {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(isActionInProgress: true));
      }
      await _firestore.collection('visitors').doc(event.visitorId).update({
        'status': 'checked_out',
        'exitTime': FieldValue.serverTimestamp(),
      });
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'મુલાકાતી ચેક-આઉટ થઈ ગયા.',
        ));
      }
    } catch (e) {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'ચેક-આઉટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onAddRequested(
    VisitorAddRequested event,
    Emitter<VisitorState> emit,
  ) async {
    try {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(isActionInProgress: true));
      }
      await _firestore.collection('visitors').add(event.visitor.toMap());
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'મુલાકાતીની નોંધણી સફળતાપૂર્વક થઈ.',
        ));
      }
    } catch (e) {
      if (state is VisitorLoaded) {
        emit((state as VisitorLoaded).copyWith(
          isActionInProgress: false,
          lastActionMessage: 'નોંધણી નિષ્ફળ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _visitorSubscription?.cancel();
    return super.close();
  }
}
