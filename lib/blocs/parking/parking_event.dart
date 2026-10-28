import 'package:equatable/equatable.dart';
import '../../services/parking_slot_service.dart';

abstract class ParkingEvent extends Equatable {
  const ParkingEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to parking slots
class ParkingSubscriptionRequested extends ParkingEvent {
  final String societyId;
  final String? blockFilter;

  const ParkingSubscriptionRequested({
    required this.societyId,
    this.blockFilter,
  });

  @override
  List<Object?> get props => [societyId, blockFilter];
}

/// Internal event fired when slots stream updates
class ParkingSlotsUpdated extends ParkingEvent {
  final List<ParkingSlotModel> slots;

  const ParkingSlotsUpdated(this.slots);

  @override
  List<Object?> get props => [slots];
}

/// Internal event fired when slots stream fails
class ParkingErrorOccurred extends ParkingEvent {
  final String error;

  const ParkingErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter by assignment status ('all', 'available', 'assigned')
class ParkingStatusFilterChanged extends ParkingEvent {
  final String statusFilter;

  const ParkingStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Filter by slot type ('all', 'car', 'bike', 'ev', 'general')
class ParkingTypeFilterChanged extends ParkingEvent {
  final String slotType;

  const ParkingTypeFilterChanged(this.slotType);

  @override
  List<Object?> get props => [slotType];
}

/// Filter by level ('all', 'Ground', 'B1', 'B2', 'B3', 'Open')
class ParkingLevelFilterChanged extends ParkingEvent {
  final String level;

  const ParkingLevelFilterChanged(this.level);

  @override
  List<Object?> get props => [level];
}

/// Search slots by slot number, vehicle plate, flat, or member name
class ParkingSearchQueryChanged extends ParkingEvent {
  final String query;

  const ParkingSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Assign parking slot to a vehicle/member
class ParkingAssignSlotRequested extends ParkingEvent {
  final String slotId;
  final String memberId;
  final String memberName;
  final String flat;
  final String vehiclePlate;
  final String vehicleModel;

  const ParkingAssignSlotRequested({
    required this.slotId,
    required this.memberId,
    required this.memberName,
    required this.flat,
    required this.vehiclePlate,
    required this.vehicleModel,
  });

  @override
  List<Object?> get props => [
        slotId,
        memberId,
        memberName,
        flat,
        vehiclePlate,
        vehicleModel,
      ];
}

/// Release / Unassign a parking slot
class ParkingReleaseSlotRequested extends ParkingEvent {
  final String slotId;

  const ParkingReleaseSlotRequested(this.slotId);

  @override
  List<Object?> get props => [slotId];
}

/// Add new parking slot
class ParkingAddSlotRequested extends ParkingEvent {
  final String slotNumber;
  final String blockName;
  final String category;
  final String slotType;
  final String level;

  const ParkingAddSlotRequested({
    required this.slotNumber,
    required this.blockName,
    this.category = 'Wing',
    this.slotType = 'car',
    this.level = 'Ground',
  });

  @override
  List<Object?> get props => [slotNumber, blockName, category, slotType, level];
}

/// Delete a parking slot
class ParkingDeleteSlotRequested extends ParkingEvent {
  final String slotId;

  const ParkingDeleteSlotRequested(this.slotId);

  @override
  List<Object?> get props => [slotId];
}
