import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/notice_model.dart';
import 'notice_event.dart';
import 'notice_state.dart';

export 'notice_event.dart';
export 'notice_state.dart';

class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _noticesSubscription;
  String _currentSocietyId = '';

  NoticeBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance,
        super(NoticeInitial()) {
    on<NoticeSubscriptionRequested>(_onSubscriptionRequested);
    on<NoticeErrorOccurred>((event, emit) => emit(NoticeFailure(event.error)));
    on<NoticesUpdated>(_onNoticesUpdated);
    on<NoticeCategoryFilterChanged>(_onCategoryFilterChanged);
    on<NoticeUrgencyFilterChanged>(_onUrgencyFilterChanged);
    on<NoticeSearchQueryChanged>(_onSearchQueryChanged);
    on<NoticePublishRequested>(_onPublishRequested);
    on<NoticeDeleteRequested>(_onDeleteRequested);
  }

  void _onSubscriptionRequested(
    NoticeSubscriptionRequested event,
    Emitter<NoticeState> emit,
  ) {
    emit(NoticeLoading());
    _currentSocietyId = event.societyId;
    _noticesSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const NoticeLoaded());
      return;
    }

    Query query = _firestore
        .collection('notices')
        .where('societyId', isEqualTo: event.societyId.trim());

    _noticesSubscription = query.snapshots().listen(
      (snapshot) {
        final all = snapshot.docs.map((d) => NoticeModel.fromFirestore(d)).toList();
        // Sort newest first
        all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (event.blockFilter != null &&
            event.blockFilter!.isNotEmpty &&
            event.blockFilter != 'ALL') {
          final blockFiltered = all.where((n) {
            return n.isCommon || n.targetBlock == event.blockFilter;
          }).toList();
          add(NoticesUpdated(blockFiltered));
        } else {
          add(NoticesUpdated(all));
        }
      },
      onError: (error) => add(NoticeErrorOccurred(error.toString())),
    );
  }

  void _onNoticesUpdated(
    NoticesUpdated event,
    Emitter<NoticeState> emit,
  ) {
    if (state is NoticeLoaded) {
      final current = state as NoticeLoaded;
      emit(current.copyWith(notices: event.notices));
    } else {
      emit(NoticeLoaded(notices: event.notices));
    }
  }

  void _onCategoryFilterChanged(
    NoticeCategoryFilterChanged event,
    Emitter<NoticeState> emit,
  ) {
    if (state is NoticeLoaded) {
      emit((state as NoticeLoaded).copyWith(categoryFilter: event.category));
    }
  }

  void _onUrgencyFilterChanged(
    NoticeUrgencyFilterChanged event,
    Emitter<NoticeState> emit,
  ) {
    if (state is NoticeLoaded) {
      emit((state as NoticeLoaded).copyWith(urgentOnly: event.urgentOnly));
    }
  }

  void _onSearchQueryChanged(
    NoticeSearchQueryChanged event,
    Emitter<NoticeState> emit,
  ) {
    if (state is NoticeLoaded) {
      emit((state as NoticeLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onPublishRequested(
    NoticePublishRequested event,
    Emitter<NoticeState> emit,
  ) async {
    try {
      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('notices').add({
        'title': event.title.trim(),
        'body': event.body.trim(),
        'category': event.category,
        'targetBlock': event.targetBlock == 'ALL' ? null : event.targetBlock,
        'isUrgent': event.isUrgent,
        'isPinned': event.isPinned,
        'societyId': _currentSocietyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નોટિસ સફળતાપૂર્વક પબ્લિશ થઈ ગઈ.',
        ));
      }
    } catch (e) {
      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નોટિસ પબ્લિશ કરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteRequested(
    NoticeDeleteRequested event,
    Emitter<NoticeState> emit,
  ) async {
    try {
      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('notices').doc(event.noticeId).delete();

      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નોટિસ કાઢી નાખવામાં આવી.',
        ));
      }
    } catch (e) {
      if (state is NoticeLoaded) {
        emit((state as NoticeLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _noticesSubscription?.cancel();
    return super.close();
  }
}
