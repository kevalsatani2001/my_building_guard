import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/user_model.dart';
import '../../services/society_service.dart';
import 'society_setup_event.dart';
import 'society_setup_state.dart';

export 'society_setup_event.dart';
export 'society_setup_state.dart';

class SocietySetupBloc extends Bloc<SocietySetupEvent, SocietySetupState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _blocksSubscription;
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  String _currentSocietyId = '';

  SocietySetupBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppFirestore.instance,
        super(SocietySetupInitial()) {
    on<SocietySetupSubscriptionRequested>(_onSubscriptionRequested);
    on<SocietySetupErrorOccurred>((event, emit) => emit(SocietySetupFailure(event.error)));
    on<SocietyBlocksUpdated>(_onBlocksUpdated);
    on<SocietyUsersUpdated>(_onUsersUpdated);
    on<SocietySetupRoleFilterChanged>(_onRoleFilterChanged);
    on<SocietySetupBlockFilterChanged>(_onBlockFilterChanged);
    on<SocietySetupSearchQueryChanged>(_onSearchQueryChanged);
    on<SocietyAddBlockRequested>(_onAddBlockRequested);
    on<SocietyAddUserRequested>(_onAddUserRequested);
    on<SocietyDeleteUserRequested>(_onDeleteUserRequested);
  }

  void _onSubscriptionRequested(
    SocietySetupSubscriptionRequested event,
    Emitter<SocietySetupState> emit,
  ) {
    emit(SocietySetupLoading());
    _currentSocietyId = event.societyId;
    _blocksSubscription?.cancel();
    _usersSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(const SocietySetupLoaded());
      return;
    }

    _blocksSubscription = _firestore
        .collection('blocks')
        .where('societyId', isEqualTo: event.societyId.trim())
        .snapshots()
        .listen(
      (snapshot) {
        final blocks = <String>{};
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final raw = (data['name'] ?? '').toString();
          final clean = SocietyService.instance.logicalBlockName(raw);
          if (clean.isNotEmpty) blocks.add(clean);
        }
        final sorted = blocks.toList()..sort();
        add(SocietyBlocksUpdated(sorted));
      },
      onError: (error) => add(SocietySetupErrorOccurred(error.toString())),
    );

    _usersSubscription = _firestore
        .collection('users')
        .where('societyId', isEqualTo: event.societyId.trim())
        .snapshots()
        .listen(
      (snapshot) {
        final users = snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>? ?? {};
          return UserModel.fromMap(data, d.id);
        }).toList();
        users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        add(SocietyUsersUpdated(users));
      },
      onError: (error) => add(SocietySetupErrorOccurred(error.toString())),
    );
  }

  void _onBlocksUpdated(
    SocietyBlocksUpdated event,
    Emitter<SocietySetupState> emit,
  ) {
    if (state is SocietySetupLoaded) {
      final current = state as SocietySetupLoaded;
      emit(current.copyWith(blocks: event.blocks));
    } else {
      emit(SocietySetupLoaded(blocks: event.blocks));
    }
  }

  void _onUsersUpdated(
    SocietyUsersUpdated event,
    Emitter<SocietySetupState> emit,
  ) {
    if (state is SocietySetupLoaded) {
      final current = state as SocietySetupLoaded;
      emit(current.copyWith(users: event.users));
    } else {
      emit(SocietySetupLoaded(users: event.users));
    }
  }

  void _onRoleFilterChanged(
    SocietySetupRoleFilterChanged event,
    Emitter<SocietySetupState> emit,
  ) {
    if (state is SocietySetupLoaded) {
      emit((state as SocietySetupLoaded).copyWith(roleFilter: event.role));
    }
  }

  void _onBlockFilterChanged(
    SocietySetupBlockFilterChanged event,
    Emitter<SocietySetupState> emit,
  ) {
    if (state is SocietySetupLoaded) {
      emit((state as SocietySetupLoaded).copyWith(blockFilter: event.block));
    }
  }

  void _onSearchQueryChanged(
    SocietySetupSearchQueryChanged event,
    Emitter<SocietySetupState> emit,
  ) {
    if (state is SocietySetupLoaded) {
      emit((state as SocietySetupLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onAddBlockRequested(
    SocietyAddBlockRequested event,
    Emitter<SocietySetupState> emit,
  ) async {
    try {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('blocks').add({
        'societyId': _currentSocietyId,
        'name': event.blockName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'નવો બ્લોક/વિંગ સફળતાપૂર્વક ઉમેરાયો.',
        ));
      }
    } catch (e) {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'બ્લોક ઉમેરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onAddUserRequested(
    SocietyAddUserRequested event,
    Emitter<SocietySetupState> emit,
  ) async {
    try {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('users').add({
        'name': event.name.trim(),
        'phone': event.phone.trim(),
        'role': event.role.trim().toLowerCase(),
        'blockName': event.blockName.trim(),
        'unitNumber': event.unitNumber.trim(),
        'societyId': _currentSocietyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'યુઝર સફળતાપૂર્વક ઉમેરાઈ ગયો.',
        ));
      }
    } catch (e) {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'યુઝર ઉમેરવામાં ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteUserRequested(
    SocietyDeleteUserRequested event,
    Emitter<SocietySetupState> emit,
  ) async {
    try {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('users').doc(event.userId).delete();

      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'યુઝર કાઢી નાખવામાં આવ્યો.',
        ));
      }
    } catch (e) {
      if (state is SocietySetupLoaded) {
        emit((state as SocietySetupLoaded).copyWith(
          isActionInProgress: false,
          feedbackMessage: 'ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _blocksSubscription?.cancel();
    _usersSubscription?.cancel();
    return super.close();
  }
}
