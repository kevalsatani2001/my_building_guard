import 'package:equatable/equatable.dart';
import '../../services/parking_slot_service.dart';

abstract class ParkingState extends Equatable {
  const ParkingState();

  @override
  List<Object?> get props => [];
}

class ParkingInitial extends ParkingState {}

class ParkingLoading extends ParkingState {}

class ParkingLoaded extends ParkingState {
  final List<ParkingSlotModel> slots;
  final String statusFilter; // 'all', 'available', 'assigned'
  final String typeFilter; // 'all', 'car', 'bike', 'ev', 'general'
  final String levelFilter; // 'all' or level name
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const ParkingLoaded({
    this.slots = const [],
    this.statusFilter = 'all',
    this.typeFilter = 'all',
    this.levelFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered list of parking slots based on status, vehicle type, floor level, and search keyword
  List<ParkingSlotModel> get filteredSlots {
    final query = searchQuery.trim().toLowerCase();

    return slots.where((slot) {
      // 1. Status Filter
      if (statusFilter == 'available' && slot.isAssigned) return false;
      if (statusFilter == 'assigned' && !slot.isAssigned) return false;

      // 2. Type Filter
      if (typeFilter != 'all') {
        if (slot.slotType.toLowerCase() != typeFilter.toLowerCase()) return false;
      }

      // 3. Level Filter
      if (levelFilter != 'all') {
        if (slot.level.toLowerCase() != levelFilter.toLowerCase()) return false;
      }

      // 4. Search Query Filter
      if (query.isNotEmpty) {
        final matchesSlot = slot.slotNumber.toLowerCase().contains(query);
        final matchesBlock = slot.blockName.toLowerCase().contains(query);
        final matchesPlate = (slot.assignedVehiclePlate ?? '').toLowerCase().contains(query);
        final matchesFlat = (slot.assignedFlat ?? '').toLowerCase().contains(query);
        final matchesMember = (slot.assignedMemberName ?? '').toLowerCase().contains(query);
        final matchesModel = (slot.assignedVehicleModel ?? '').toLowerCase().contains(query);

        if (!matchesSlot &&
            !matchesBlock &&
            !matchesPlate &&
            !matchesFlat &&
            !matchesMember &&
            !matchesModel) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total number of slots configured
  int get totalSlotsCount => slots.length;

  /// Number of free / available parking slots
  int get availableSlotsCount => slots.where((s) => !s.isAssigned).length;

  /// Number of occupied / assigned slots
  int get assignedSlotsCount => slots.where((s) => s.isAssigned).length;

  /// Percentage of slots currently occupied (0.0 to 100.0)
  double get occupancyPercentage {
    if (totalSlotsCount == 0) return 0.0;
    return ((assignedSlotsCount / totalSlotsCount) * 100.0).clamp(0.0, 100.0);
  }

  ParkingLoaded copyWith({
    List<ParkingSlotModel>? slots,
    String? statusFilter,
    String? typeFilter,
    String? levelFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return ParkingLoaded(
      slots: slots ?? this.slots,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      levelFilter: levelFilter ?? this.levelFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        slots,
        statusFilter,
        typeFilter,
        levelFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class ParkingFailure extends ParkingState {
  final String errorMessage;

  const ParkingFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
