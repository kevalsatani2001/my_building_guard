import 'package:equatable/equatable.dart';
import '../../models/amenity_model.dart';

abstract class AmenitiesEvent extends Equatable {
  const AmenitiesEvent();

  @override
  List<Object?> get props => [];
}

/// Request real-time stream subscription for amenities and bookings
class AmenitiesSubscriptionRequested extends AmenitiesEvent {
  final String societyId;
  final String? memberUid;
  final String role; // 'admin', 'member', 'watchman'

  const AmenitiesSubscriptionRequested({
    required this.societyId,
    this.memberUid,
    this.role = 'member',
  });

  @override
  List<Object?> get props => [societyId, memberUid, role];
}

/// Internal event fired when amenities list updates
class AmenitiesListUpdated extends AmenitiesEvent {
  final List<AmenityModel> amenities;

  const AmenitiesListUpdated(this.amenities);

  @override
  List<Object?> get props => [amenities];
}

/// Internal event fired when bookings list updates
class AmenityBookingsUpdated extends AmenitiesEvent {
  final List<AmenityBookingModel> bookings;

  const AmenityBookingsUpdated(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

/// Internal event fired when society amenity module toggle updates
class AmenitiesEnabledStatusUpdated extends AmenitiesEvent {
  final bool isEnabled;

  const AmenitiesEnabledStatusUpdated(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

/// Internal event fired when any amenity stream encounters an error
class AmenitiesErrorOccurred extends AmenitiesEvent {
  final String error;

  const AmenitiesErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter bookings by status ('all', 'pending', 'approved', 'rejected')
class AmenityStatusFilterChanged extends AmenitiesEvent {
  final String statusFilter;

  const AmenityStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Search amenities or bookings
class AmenitySearchQueryChanged extends AmenitiesEvent {
  final String query;

  const AmenitySearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Admin adds or updates an amenity
class AmenitySaveRequested extends AmenitiesEvent {
  final String? id;
  final String name;
  final String category;
  final int capacity;
  final String description;
  final bool isPaid;
  final double rentAmount;
  final double securityDeposit;
  final String slotType;
  final List<String> availableSlots;
  final String rulesAndTerms;
  final bool isActive;

  const AmenitySaveRequested({
    this.id,
    required this.name,
    this.category = 'hall',
    this.capacity = 100,
    this.description = '',
    this.isPaid = false,
    this.rentAmount = 0.0,
    this.securityDeposit = 0.0,
    this.slotType = 'full_day',
    this.availableSlots = const ['આખો દિવસ (Full Day)'],
    this.rulesAndTerms = '',
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        capacity,
        description,
        isPaid,
        rentAmount,
        securityDeposit,
        slotType,
        availableSlots,
        rulesAndTerms,
        isActive,
      ];
}

/// Admin deletes an amenity
class AmenityDeleteRequested extends AmenitiesEvent {
  final String amenityId;

  const AmenityDeleteRequested(this.amenityId);

  @override
  List<Object?> get props => [amenityId];
}

/// Member submits a booking request
class AmenityBookRequested extends AmenitiesEvent {
  final AmenityModel amenity;
  final DateTime bookingDate;
  final String slotName;
  final String purpose;
  final int expectedGuests;
  final String memberName;
  final String memberPhone;
  final String unitDisplay;

  const AmenityBookRequested({
    required this.amenity,
    required this.bookingDate,
    required this.slotName,
    required this.purpose,
    required this.expectedGuests,
    required this.memberName,
    required this.memberPhone,
    required this.unitDisplay,
  });

  @override
  List<Object?> get props => [
        amenity.id,
        bookingDate,
        slotName,
        purpose,
        expectedGuests,
        memberName,
        memberPhone,
        unitDisplay,
      ];
}

/// Admin approves or rejects booking
class AmenityUpdateBookingStatusRequested extends AmenitiesEvent {
  final String bookingId;
  final String status; // 'approved', 'rejected', 'cancelled'
  final String? adminRemarks;

  const AmenityUpdateBookingStatusRequested({
    required this.bookingId,
    required this.status,
    this.adminRemarks,
  });

  @override
  List<Object?> get props => [bookingId, status, adminRemarks];
}
