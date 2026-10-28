import 'package:equatable/equatable.dart';
import '../../models/amenity_model.dart';

abstract class AmenitiesState extends Equatable {
  const AmenitiesState();

  @override
  List<Object?> get props => [];
}

class AmenitiesInitial extends AmenitiesState {}

class AmenitiesLoading extends AmenitiesState {}

class AmenitiesLoaded extends AmenitiesState {
  final List<AmenityModel> amenities;
  final List<AmenityBookingModel> bookings;
  final bool isAmenitiesEnabled;
  final String statusFilter; // 'all', 'pending', 'approved', 'rejected'
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const AmenitiesLoaded({
    this.amenities = const [],
    this.bookings = const [],
    this.isAmenitiesEnabled = true,
    this.statusFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered list of bookings based on status and search query
  List<AmenityBookingModel> get filteredBookings {
    final query = searchQuery.trim().toLowerCase();

    return bookings.where((b) {
      // 1. Status Filter
      if (statusFilter != 'all') {
        if (b.status.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final matchesAmenity = b.amenityName.toLowerCase().contains(query);
        final matchesMember = b.memberName.toLowerCase().contains(query);
        final matchesUnit = b.unitDisplay.toLowerCase().contains(query);
        final matchesPurpose = b.purpose.toLowerCase().contains(query);
        final matchesPassCode = b.eventPassCode.toLowerCase().contains(query);

        if (!matchesAmenity &&
            !matchesMember &&
            !matchesUnit &&
            !matchesPurpose &&
            !matchesPassCode) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Number of pending booking requests waiting for Admin approval
  int get pendingBookingsCount =>
      bookings.where((b) => b.status.toLowerCase() == 'pending').length;

  /// Number of approved bookings
  int get approvedBookingsCount =>
      bookings.where((b) => b.status.toLowerCase() == 'approved').length;

  /// Number of active amenities configured
  int get activeAmenitiesCount =>
      amenities.where((a) => a.isActive).length;

  AmenitiesLoaded copyWith({
    List<AmenityModel>? amenities,
    List<AmenityBookingModel>? bookings,
    bool? isAmenitiesEnabled,
    String? statusFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return AmenitiesLoaded(
      amenities: amenities ?? this.amenities,
      bookings: bookings ?? this.bookings,
      isAmenitiesEnabled: isAmenitiesEnabled ?? this.isAmenitiesEnabled,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        amenities,
        bookings,
        isAmenitiesEnabled,
        statusFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class AmenitiesFailure extends AmenitiesState {
  final String errorMessage;

  const AmenitiesFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
