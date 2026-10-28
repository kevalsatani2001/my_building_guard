import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../models/maintenance_model.dart';
import '../../services/maintenance_service.dart';
import 'maintenance_event.dart';
import 'maintenance_state.dart';

export 'maintenance_event.dart';
export 'maintenance_state.dart';

class MaintenanceBloc extends Bloc<MaintenanceEvent, MaintenanceState> {
  final FirebaseFirestore _firestore;
  final MaintenanceService _maintenanceService;
  StreamSubscription<QuerySnapshot>? _billsSubscription;

  MaintenanceBloc({
    FirebaseFirestore? firestore,
    MaintenanceService? maintenanceService,
  })  : _firestore = firestore ?? AppFirestore.instance,
        _maintenanceService = maintenanceService ?? MaintenanceService.instance,
        super(MaintenanceInitial()) {
    on<MaintenanceSubscriptionRequested>(_onSubscriptionRequested);
    on<MaintenanceErrorOccurred>((event, emit) => emit(MaintenanceFailure(event.error)));
    on<MaintenanceBillsUpdated>(_onBillsUpdated);
    on<MaintenanceStatusFilterChanged>(_onStatusFilterChanged);
    on<MaintenanceMonthFilterChanged>(_onMonthFilterChanged);
    on<MaintenanceSearchQueryChanged>(_onSearchQueryChanged);
    on<MaintenanceGenerateBulkBillsRequested>(_onGenerateBulkBillsRequested);
    on<MaintenanceRecordOfflinePaymentRequested>(_onRecordOfflinePaymentRequested);
    on<MaintenanceSubmitUtrRequested>(_onSubmitUtrRequested);
    on<MaintenanceVerifyUtrRequested>(_onVerifyUtrRequested);
    on<MaintenanceDeleteBillRequested>(_onDeleteBillRequested);
  }

  void _onSubscriptionRequested(
    MaintenanceSubscriptionRequested event,
    Emitter<MaintenanceState> emit,
  ) {
    emit(MaintenanceLoading());
    _billsSubscription?.cancel();

    if (event.societyId.trim().isEmpty) {
      emit(MaintenanceLoaded(
        allBills: const [],
        scope: event.scope,
      ));
      return;
    }

    Query query = _firestore
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: event.societyId.trim());

    _billsSubscription = query.snapshots().listen(
      (snapshot) {
        final all = snapshot.docs.map((d) => MaintenanceBill.fromFirestore(d)).toList();
        all.sort((a, b) => b.dueDate.compareTo(a.dueDate));

        if (event.scope == 'member') {
          final memberBills = all.where((b) {
            if (event.memberId != null &&
                event.memberId!.isNotEmpty &&
                b.memberId == event.memberId) {
              return true;
            }
            if (event.unitNumber != null &&
                event.unitNumber!.isNotEmpty &&
                b.unitNumber.toLowerCase() == event.unitNumber!.toLowerCase()) {
              if (event.blockName != null &&
                  event.blockName!.isNotEmpty &&
                  b.blockName.isNotEmpty) {
                return b.blockName.toLowerCase() == event.blockName!.toLowerCase();
              }
              return true;
            }
            return false;
          }).toList();
          add(MaintenanceBillsUpdated(memberBills));
        } else {
          add(MaintenanceBillsUpdated(all));
        }
      },
      onError: (error) {
        add(MaintenanceErrorOccurred(error.toString()));
      },
    );
  }

  void _onBillsUpdated(
    MaintenanceBillsUpdated event,
    Emitter<MaintenanceState> emit,
  ) {
    if (state is MaintenanceLoaded) {
      final current = state as MaintenanceLoaded;
      emit(current.copyWith(allBills: event.bills));
    } else {
      emit(MaintenanceLoaded(allBills: event.bills));
    }
  }

  void _onStatusFilterChanged(
    MaintenanceStatusFilterChanged event,
    Emitter<MaintenanceState> emit,
  ) {
    if (state is MaintenanceLoaded) {
      emit((state as MaintenanceLoaded).copyWith(statusFilter: event.statusFilter));
    }
  }

  void _onMonthFilterChanged(
    MaintenanceMonthFilterChanged event,
    Emitter<MaintenanceState> emit,
  ) {
    if (state is MaintenanceLoaded) {
      emit((state as MaintenanceLoaded).copyWith(monthFilter: event.monthFilter));
    }
  }

  void _onSearchQueryChanged(
    MaintenanceSearchQueryChanged event,
    Emitter<MaintenanceState> emit,
  ) {
    if (state is MaintenanceLoaded) {
      emit((state as MaintenanceLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onGenerateBulkBillsRequested(
    MaintenanceGenerateBulkBillsRequested event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(isActionInProgress: true));
      }

      final res = await _maintenanceService.generateBulkBills(
        billingMonth: event.billingMonth,
        billTitle: event.billTitle,
        amount: event.amount,
        dueDate: event.dueDate,
        penaltyAmount: event.penaltyAmount,
        festivalCharge: event.festivalCharge,
        festivalName: event.festivalName,
        billingMode: event.billingMode,
        ratePerSqFt: event.ratePerSqFt,
        targetCategory: event.targetCategory,
        targetBlock: event.targetBlock,
        gstRate: event.gstRate,
        gstin: event.gstin,
        commercialRate: event.commercialRate,
        residentialRate: event.residentialRate,
      );

      if (state is MaintenanceLoaded) {
        final created = res['created'] ?? 0;
        final updated = res['updated'] ?? 0;
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'બલ્ક બિલ જનરેટ થયા (બનેલ: $created, અપડેટ: $updated).',
        ));
      }
    } catch (e) {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'બલ્ક બિલ જનરેશન ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onRecordOfflinePaymentRequested(
    MaintenanceRecordOfflinePaymentRequested event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(isActionInProgress: true));
        final current = state as MaintenanceLoaded;
        final bill = current.allBills.firstWhere((b) => b.id == event.billId);

        await _maintenanceService.recordOfflinePayment(
          billId: event.billId,
          bill: bill,
          paymentMode: event.paymentMode,
          chequeNumber: event.chequeNumber,
          note: event.note,
        );

        emit(current.copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'ઓફલાઇન પેમેન્ટ સફળતાપૂર્વક નોંધાયું.',
        ));
      }
    } catch (e) {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'પેમેન્ટ નોંધણી ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onSubmitUtrRequested(
    MaintenanceSubmitUtrRequested event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(isActionInProgress: true));
      }

      await _maintenanceService.submitUpiPayment(
        billId: event.billId,
        utrNumber: event.utrNumber,
        note: event.note,
      );

      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'UTR ચકાસણી માટે સફળતાપૂર્વક સબમિટ કરાયું.',
        ));
      }
    } catch (e) {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'UTR સબમિશન ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onVerifyUtrRequested(
    MaintenanceVerifyUtrRequested event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(isActionInProgress: true));
        final current = state as MaintenanceLoaded;
        final bill = current.allBills.firstWhere((b) => b.id == event.billId);

        if (event.isApproved) {
          await _maintenanceService.approvePayment(
            billId: event.billId,
            bill: bill,
          );
          emit(current.copyWith(
            isActionInProgress: false,
            actionFeedbackMessage: 'પેમેન્ટ મંજૂર કરવામાં આવ્યું.',
          ));
        } else {
          await _firestore.collection('maintenance_bills').doc(event.billId).update({
            'status': MaintenanceStatus.pending.toDbString(),
            'utrNumber': '',
            'rejectReason': event.rejectReason ?? 'અમાન્ય UTR નંબર',
            'actionTime': FieldValue.serverTimestamp(),
          });
          emit(current.copyWith(
            isActionInProgress: false,
            actionFeedbackMessage: 'પેમેન્ટ અસ્વીકાર કરવામાં આવ્યું.',
          ));
        }
      }
    } catch (e) {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'વેરિફિકેશન ભૂલ: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteBillRequested(
    MaintenanceDeleteBillRequested event,
    Emitter<MaintenanceState> emit,
  ) async {
    try {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(isActionInProgress: true));
      }

      await _firestore.collection('maintenance_bills').doc(event.billId).delete();

      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'બિલ કાઢી નાખવામાં આવ્યું.',
        ));
      }
    } catch (e) {
      if (state is MaintenanceLoaded) {
        emit((state as MaintenanceLoaded).copyWith(
          isActionInProgress: false,
          actionFeedbackMessage: 'બિલ ડિલીટ ભૂલ: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _billsSubscription?.cancel();
    return super.close();
  }
}
