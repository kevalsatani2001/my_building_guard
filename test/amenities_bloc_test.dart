import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/amenity_model.dart';
import 'package:building_guard/blocs/amenities/amenities_bloc.dart';

void main() {
  group('AmenitiesBloc State and Filter Calculation Tests', () {
    final now = DateTime.now();

    final testAmenity1 = AmenityModel(
      id: 'a1',
      societyId: 'soc123',
      name: 'Community Hall',
      category: 'hall',
      capacity: 250,
      isPaid: true,
      rentAmount: 5000.0,
      securityDeposit: 2000.0,
      isActive: true,
    );

    final testAmenity2 = AmenityModel(
      id: 'a2',
      societyId: 'soc123',
      name: 'Old Badminton Court',
      category: 'sports',
      capacity: 20,
      isPaid: false,
      isActive: false, // Inactive
    );

    final testBooking1 = AmenityBookingModel(
      id: 'b1',
      societyId: 'soc123',
      amenityId: 'a1',
      amenityName: 'Community Hall',
      memberUid: 'm1',
      memberName: 'Keval Satani',
      memberPhone: '9876543210',
      unitDisplay: 'A-101',
      bookingDate: now.add(const Duration(days: 3)),
      slotName: 'Morning Slot (8 AM - 1 PM)',
      purpose: 'Birthday Party',
      expectedGuests: 50,
      status: 'pending',
      rentAmount: 5000.0,
      securityDeposit: 2000.0,
      depositStatus: 'pending',
      eventPassCode: '458921',
      createdAt: now.subtract(const Duration(hours: 4)),
    );

    final testBooking2 = AmenityBookingModel(
      id: 'b2',
      societyId: 'soc123',
      amenityId: 'a1',
      amenityName: 'Community Hall',
      memberUid: 'm2',
      memberName: 'Hardik',
      memberPhone: '9123456780',
      unitDisplay: 'B-202',
      bookingDate: now.add(const Duration(days: 7)),
      slotName: 'Evening Slot (5 PM - 11 PM)',
      purpose: 'Engagement Celebration',
      expectedGuests: 120,
      status: 'approved',
      rentAmount: 5000.0,
      securityDeposit: 2000.0,
      depositStatus: 'held',
      eventPassCode: '892104',
      createdAt: now.subtract(const Duration(days: 1)),
    );

    test('AmenitiesLoaded counts pending, approved, and active amenities properly', () {
      final state = AmenitiesLoaded(
        amenities: [testAmenity1, testAmenity2],
        bookings: [testBooking1, testBooking2],
      );

      expect(state.activeAmenitiesCount, 1);    // testAmenity1 is active
      expect(state.pendingBookingsCount, 1);   // testBooking1 is pending
      expect(state.approvedBookingsCount, 1);  // testBooking2 is approved
    });

    test('AmenitiesLoaded filters bookings by status properly', () {
      final statePending = AmenitiesLoaded(
        amenities: [testAmenity1],
        bookings: [testBooking1, testBooking2],
        statusFilter: 'pending',
      );

      expect(statePending.filteredBookings.length, 1);
      expect(statePending.filteredBookings.first.id, 'b1');

      final stateApproved = AmenitiesLoaded(
        amenities: [testAmenity1],
        bookings: [testBooking1, testBooking2],
        statusFilter: 'approved',
      );

      expect(stateApproved.filteredBookings.length, 1);
      expect(stateApproved.filteredBookings.first.id, 'b2');
    });

    test('AmenitiesLoaded search filters across pass code and member name', () {
      final stateCodeSearch = AmenitiesLoaded(
        amenities: [testAmenity1],
        bookings: [testBooking1, testBooking2],
        searchQuery: '458921',
      );
      expect(stateCodeSearch.filteredBookings.length, 1);
      expect(stateCodeSearch.filteredBookings.first.id, 'b1');

      final stateMemberSearch = AmenitiesLoaded(
        amenities: [testAmenity1],
        bookings: [testBooking1, testBooking2],
        searchQuery: 'hardik',
      );
      expect(stateMemberSearch.filteredBookings.length, 1);
      expect(stateMemberSearch.filteredBookings.first.id, 'b2');
    });

    test('AmenitiesLoaded copyWith preserves immutability', () {
      final state1 = AmenitiesLoaded(
        amenities: [testAmenity1],
        bookings: [testBooking1],
      );

      final state2 = state1.copyWith(
        statusFilter: 'approved',
        searchQuery: 'hall',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'approved');
      expect(state2.searchQuery, 'hall');
      expect(state2.isActionInProgress, true);
    });

    test('AmenitiesErrorOccurred emits AmenitiesFailure cleanly', () async {
      final bloc = AmenitiesBloc();
      bloc.add(const AmenitiesErrorOccurred('Test error occurred'));
      await expectLater(
        bloc.stream,
        emits(const AmenitiesFailure('Test error occurred')),
      );
      await bloc.close();
    });
  });
}
