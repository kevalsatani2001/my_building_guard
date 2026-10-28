import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/services/parking_slot_service.dart';
import 'package:building_guard/blocs/parking/parking_bloc.dart';

void main() {
  group('ParkingBloc State and Allocation Tests', () {
    final now = DateTime.now();

    final testSlot1 = ParkingSlotModel(
      id: 'slot_1',
      societyId: 'soc123',
      slotNumber: 'P-101',
      blockName: 'A',
      category: 'Wing',
      slotType: 'car',
      level: 'B1',
      isAssigned: true,
      assignedMemberId: 'm1',
      assignedMemberName: 'Keval Satani',
      assignedFlat: 'A-101',
      assignedVehiclePlate: 'GJ-01-AB-1234',
      assignedVehicleModel: 'Hyundai Creta',
      createdAt: now,
    );

    final testSlot2 = ParkingSlotModel(
      id: 'slot_2',
      societyId: 'soc123',
      slotNumber: 'P-102',
      blockName: 'A',
      category: 'Wing',
      slotType: 'bike',
      level: 'Ground',
      isAssigned: false,
      createdAt: now,
    );

    final testSlot3 = ParkingSlotModel(
      id: 'slot_3',
      societyId: 'soc123',
      slotNumber: 'P-201',
      blockName: 'B',
      category: 'Wing',
      slotType: 'ev',
      level: 'B2',
      isAssigned: false,
      createdAt: now,
    );

    test('ParkingLoaded computes occupancy metrics accurately', () {
      final state = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
      );

      expect(state.totalSlotsCount, 3);
      expect(state.assignedSlotsCount, 1);
      expect(state.availableSlotsCount, 2);
      expect(state.occupancyPercentage, closeTo(33.33, 0.1));
    });

    test('ParkingLoaded filters by assignment status', () {
      final stateAvailable = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        statusFilter: 'available',
      );
      expect(stateAvailable.filteredSlots.length, 2);

      final stateAssigned = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        statusFilter: 'assigned',
      );
      expect(stateAssigned.filteredSlots.length, 1);
      expect(stateAssigned.filteredSlots.first.id, 'slot_1');
    });

    test('ParkingLoaded filters by vehicle slot type', () {
      final stateCar = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        typeFilter: 'car',
      );
      expect(stateCar.filteredSlots.length, 1);
      expect(stateCar.filteredSlots.first.id, 'slot_1');

      final stateBike = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        typeFilter: 'bike',
      );
      expect(stateBike.filteredSlots.length, 1);
      expect(stateBike.filteredSlots.first.id, 'slot_2');
    });

    test('ParkingLoaded filters by parking level', () {
      final stateB1 = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        levelFilter: 'B1',
      );
      expect(stateB1.filteredSlots.length, 1);
      expect(stateB1.filteredSlots.first.id, 'slot_1');
    });

    test('ParkingLoaded search matches vehicle plate or member name', () {
      final statePlate = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        searchQuery: 'GJ-01',
      );
      expect(statePlate.filteredSlots.length, 1);
      expect(statePlate.filteredSlots.first.id, 'slot_1');

      final stateMember = ParkingLoaded(
        slots: [testSlot1, testSlot2, testSlot3],
        searchQuery: 'keval',
      );
      expect(stateMember.filteredSlots.length, 1);
      expect(stateMember.filteredSlots.first.id, 'slot_1');
    });

    test('ParkingLoaded copyWith preserves state immutability', () {
      final state1 = ParkingLoaded(
        slots: [testSlot1],
        statusFilter: 'all',
      );

      final state2 = state1.copyWith(
        statusFilter: 'available',
        searchQuery: 'P-101',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'available');
      expect(state2.searchQuery, 'P-101');
      expect(state2.isActionInProgress, true);
    });
  });
}
