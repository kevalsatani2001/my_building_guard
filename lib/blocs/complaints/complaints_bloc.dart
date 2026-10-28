import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/complaint_model.dart';
import 'complaints_event.dart';
import 'complaints_state.dart';

export 'complaints_event.dart';
export 'complaints_state.dart';

class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _complaintsSubscription;

  ComplaintsBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance,
        super(ComplaintsInitial()) {
    on<ComplaintsSubscriptionRequested>(_onSubscriptionRequested);
    on<ComplaintsErrorOccurred>((event, emit) => emit(ComplaintsFailure(event.error)));
    on<ComplaintsUpdated>(_onComplaintsUpdated);
    on<ComplaintFilterChanged>(_onFilterChanged);
    on<ComplaintCategoryFilterChanged>(_onCategoryFilterChanged);
    on<ComplaintSearchQueryChanged>(_onSearchQueryChanged);
    on<ComplaintCreateRequested>(_onCreateRequested);
    on<ComplaintResolveRequested>(_onResolveRequested);
    on<ComplaintDeleteRequested>(_onDeleteRequested);
  }

  void _onSubscriptionRequested(
    ComplaintsSubscriptionRequested event,
    Emitter<ComplaintsState> emit,
  ) {
    emit(ComplaintsLoading());
    _complaintsSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(ComplaintsLoaded(scope: event.scope));
      return;
    }

    Query query = _firestore
        .collection('complaints')
        .where('societyId', isEqualTo: event.societyId.trim());

    _complaintsSubscription = query.snapshots().listen(
      (snapshot) {
        final all = snapshot.docs.map((d) => ComplaintModel.fromFirestore(d)).toList();
        all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (event.scope == 'member' && event.memberId != null && event.memberId!.isNotEmpty) {
          final memberComplaints = all.where((c) => c.memberId == event.memberId).toList();
          add(ComplaintsUpdated(memberComplaints));
        } else {
          add(ComplaintsUpdated(all));
        }
      },
      onError: (error) => add(ComplaintsErrorOccurred(error.toString())),
    );
  }

  void _onComplaintsUpdated(
    ComplaintsUpdated event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is ComplaintsLoaded) {
      final current = state as ComplaintsLoaded;
      emit(current.copyWith(complaints: event.complaints));
    } else {
      emit(ComplaintsLoaded(complaints: event.complaints));
    }
  }

  void _onFilterChanged(
    ComplaintFilterChanged event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is ComplaintsLoaded) {
      emit((state as ComplaintsLoaded).copyWith(statusFilter: event.filter));
    }
  }

  void _onCategoryFilterChanged(
    ComplaintCategoryFilterChanged event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is ComplaintsLoaded) {
      emit((state as ComplaintsLoaded).copyWith(categoryFilter: event.category));
    }
  }

  void _onSearchQueryChanged(
    ComplaintSearchQueryChanged event,
    Emitter<ComplaintsState> emit,
  ) {
    if (state is ComplaintsLoaded) {
      emit((state as ComplaintsLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onCreateRequested(
    ComplaintCreateRequested event,
    Emitter<ComplaintsState> emit,
  ) async {
    try {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('complaints').add(event.complaint.toMap());

      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ફરિયાદ સફળતાપૂર્વક નોંધાઈ ગઈ છે.',
        ));
      }
    } catch (e) {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ફરિયાદ નોંધણી ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onResolveRequested(
    ComplaintResolveRequested event,
    Emitter<ComplaintsState> emit,
  ) async {
    try {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('complaints').doc(event.complaintId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        if (event.resolutionNotes != null && event.resolutionNotes!.trim().isNotEmpty)
          'resolutionNotes': event.resolutionNotes!.trim(),
      });

      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ફરિયાદ સફળતાપૂર્વક ઉકેલાઈ ગઈ છે. ✅',
        ));
      }
    } catch (e) {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'સ્ટેટસ અપડેટ ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteRequested(
    ComplaintDeleteRequested event,
    Emitter<ComplaintsState> emit,
  ) async {
    try {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('complaints').doc(event.complaintId).delete();

      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ફરિયાદ કાઢી નાખવામાં આવી.',
        ));
      }
    } catch (e) {
      if (state is ComplaintsLoaded) {
        emit((state as ComplaintsLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _complaintsSubscription?.cancel();
    return super.close();
  }
}
