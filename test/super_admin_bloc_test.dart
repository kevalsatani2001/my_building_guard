import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/super_admin_models.dart';
import 'package:building_guard/blocs/super_admin/super_admin_bloc.dart';

void main() {
  group('SuperAdminBloc State and Architecture Filter Tests', () {
    final now = DateTime.now();

    final testSoc1 = SocietyOverview(
      id: 'soc_1',
      name: 'Shivalik Heights',
      architectureType: 'Wing',
      city: 'Ahmedabad',
      adminName: 'Keval Satani',
      adminPhone: '9876543210',
      adminEmail: 'keval@shivalik.com',
      totalUnits: 120,
      totalMembers: 115,
      totalWatchmen: 4,
      totalAdmins: 2,
      totalBilledMonth: 240000.0,
      totalCollectedMonth: 210000.0,
      pendingComplaints: 2,
      todayVisitors: 28,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 100)),
    );

    final testSoc2 = SocietyOverview(
      id: 'soc_2',
      name: 'Titanium City Centre',
      architectureType: 'Commercial',
      city: 'Surat',
      adminName: 'Hardik Patel',
      adminPhone: '9123456780',
      adminEmail: 'hardik@titanium.com',
      totalUnits: 60,
      totalMembers: 55,
      totalWatchmen: 6,
      totalAdmins: 1,
      totalBilledMonth: 180000.0,
      totalCollectedMonth: 180000.0,
      pendingComplaints: 0,
      todayVisitors: 140,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 200)),
    );

    final testSoc3 = SocietyOverview(
      id: 'soc_3',
      name: 'Gokul Row House',
      architectureType: 'Street',
      city: 'Rajkot',
      adminName: 'Sanjay',
      adminPhone: '9000000000',
      adminEmail: 'sanjay@gokul.com',
      totalUnits: 40,
      totalMembers: 38,
      totalWatchmen: 2,
      totalAdmins: 1,
      totalBilledMonth: 40000.0,
      totalCollectedMonth: 20000.0,
      pendingComplaints: 1,
      todayVisitors: 10,
      isActive: false, // Suspended
      createdAt: now.subtract(const Duration(days: 300)),
    );

    test('SuperAdminLoaded computes active and suspended counts accurately', () {
      final state = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1, testSoc2, testSoc3],
      );

      expect(state.activeSocietiesCount, 2);
      expect(state.suspendedSocietiesCount, 1);
    });

    test('SuperAdminLoaded filters societies by architecture type', () {
      final stateCommercial = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1, testSoc2, testSoc3],
        architectureFilter: 'Commercial',
      );
      expect(stateCommercial.filteredSocieties.length, 1);
      expect(stateCommercial.filteredSocieties.first.id, 'soc_2');

      final stateStreet = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1, testSoc2, testSoc3],
        architectureFilter: 'Street',
      );
      expect(stateStreet.filteredSocieties.length, 1);
      expect(stateStreet.filteredSocieties.first.id, 'soc_3');
    });

    test('SuperAdminLoaded search matches city or admin phone', () {
      final stateCity = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1, testSoc2, testSoc3],
        searchQuery: 'ahmedabad',
      );
      expect(stateCity.filteredSocieties.length, 1);
      expect(stateCity.filteredSocieties.first.id, 'soc_1');

      final statePhone = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1, testSoc2, testSoc3],
        searchQuery: '912345',
      );
      expect(statePhone.filteredSocieties.length, 1);
      expect(statePhone.filteredSocieties.first.id, 'soc_2');
    });

    test('SuperAdminLoaded copyWith preserves state immutability', () {
      final state1 = SuperAdminLoaded(
        stats: GlobalPlatformStats.empty(),
        societies: [testSoc1],
      );

      final state2 = state1.copyWith(
        architectureFilter: 'Wing',
        searchQuery: 'Shivalik',
        isActionInProgress: true,
      );

      expect(state1.architectureFilter, 'all');
      expect(state2.architectureFilter, 'Wing');
      expect(state2.searchQuery, 'Shivalik');
      expect(state2.isActionInProgress, true);
    });
  });
}
