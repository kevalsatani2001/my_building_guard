import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/staff_model.dart';
import 'package:building_guard/blocs/staff/staff_bloc.dart';

void main() {
  group('StaffBloc State and Role Filter Tests', () {
    final now = DateTime.now();

    final testStaff1 = DailyStaffModel(
      id: 's1',
      societyId: 'soc123',
      memberId: 'm1',
      staffName: 'Shantaben Maid',
      staffPhone: '9876543210',
      staffRole: 'કામવાળા (Maid)',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 20)),
    );

    final testStaff2 = DailyStaffModel(
      id: 's2',
      societyId: 'soc123',
      memberId: 'm1',
      staffName: 'Mukesh Driver',
      staffPhone: '9123456780',
      staffRole: 'ડ્રાઈવર (Driver)',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 10)),
    );

    final testStaff3 = DailyStaffModel(
      id: 's3',
      societyId: 'soc123',
      memberId: 'm2',
      staffName: 'Raju Cook',
      staffPhone: '9000000000',
      staffRole: 'રસોઈયા (Cook)',
      isActive: false, // Inactive
      createdAt: now.subtract(const Duration(days: 40)),
    );

    test('StaffLoaded computes total and active staff counts accurately', () {
      final state = StaffLoaded(
        staffList: [testStaff1, testStaff2, testStaff3],
      );

      expect(state.totalStaffCount, 3);
      expect(state.activeStaffCount, 2); // s1, s2
    });

    test('StaffLoaded filters staff by role properly', () {
      final stateMaid = StaffLoaded(
        staffList: [testStaff1, testStaff2, testStaff3],
        roleFilter: 'Maid',
      );
      expect(stateMaid.filteredStaff.length, 1);
      expect(stateMaid.filteredStaff.first.id, 's1');

      final stateDriver = StaffLoaded(
        staffList: [testStaff1, testStaff2, testStaff3],
        roleFilter: 'Driver',
      );
      expect(stateDriver.filteredStaff.length, 1);
      expect(stateDriver.filteredStaff.first.id, 's2');
    });

    test('StaffLoaded search query matches staff name or phone', () {
      final stateMukesh = StaffLoaded(
        staffList: [testStaff1, testStaff2, testStaff3],
        searchQuery: 'mukesh',
      );
      expect(stateMukesh.filteredStaff.length, 1);
      expect(stateMukesh.filteredStaff.first.id, 's2');

      final statePhone = StaffLoaded(
        staffList: [testStaff1, testStaff2, testStaff3],
        searchQuery: '987654',
      );
      expect(statePhone.filteredStaff.length, 1);
      expect(statePhone.filteredStaff.first.id, 's1');
    });

    test('StaffLoaded copyWith preserves state immutability', () {
      final state1 = StaffLoaded(
        staffList: [testStaff1],
        roleFilter: 'all',
      );

      final state2 = state1.copyWith(
        roleFilter: 'Cook',
        searchQuery: 'Raju',
        isActionInProgress: true,
      );

      expect(state1.roleFilter, 'all');
      expect(state2.roleFilter, 'Cook');
      expect(state2.searchQuery, 'Raju');
      expect(state2.isActionInProgress, true);
    });
  });
}
