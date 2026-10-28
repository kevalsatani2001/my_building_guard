import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/user_model.dart';
import 'package:building_guard/blocs/setup/society_setup_bloc.dart';

void main() {
  group('SocietySetupBloc State and Filter Tests', () {
    const user1 = UserModel(
      uid: 'u1',
      name: 'Rameshbhai Patel',
      email: 'ramesh@example.com',
      role: 'member',
      blockName: 'A',
      unitNumber: '101',
      phone: '9876543210',
      societyId: 'soc123',
    );

    const user2 = UserModel(
      uid: 'u2',
      name: 'Sureshbhai Shah',
      email: 'suresh@example.com',
      role: 'member',
      blockName: 'B',
      unitNumber: '202',
      phone: '9123456789',
      societyId: 'soc123',
    );

    const user3 = UserModel(
      uid: 'u3',
      name: 'Bahadur Singh',
      email: 'bahadur@guard.com',
      role: 'watchman',
      blockName: 'Main Gate',
      unitNumber: 'Gate 1',
      phone: '9998887776',
      societyId: 'soc123',
    );

    const user4 = UserModel(
      uid: 'u4',
      name: 'Keval Admin',
      email: 'admin@society.com',
      role: 'admin',
      blockName: 'A',
      unitNumber: '404',
      phone: '9888877777',
      societyId: 'soc123',
    );

    final allUsers = [user1, user2, user3, user4];

    test('SocietySetupLoaded counts members, watchmen, admins, and total correctly', () {
      final state = SocietySetupLoaded(
        blocks: const ['A', 'B'],
        users: allUsers,
      );

      expect(state.totalUsersCount, 4);
      expect(state.membersCount, 2);
      expect(state.watchmenCount, 1);
      expect(state.adminsCount, 1);
    });

    test('SocietySetupLoaded filters users by role accurately', () {
      final memberState = SocietySetupLoaded(
        users: allUsers,
        roleFilter: 'member',
      );
      expect(memberState.filteredUsers.length, 2);
      expect(memberState.filteredUsers.every((u) => u.role == 'member'), isTrue);

      final watchmanState = SocietySetupLoaded(
        users: allUsers,
        roleFilter: 'watchman',
      );
      expect(watchmanState.filteredUsers.length, 1);
      expect(watchmanState.filteredUsers.first.name, 'Bahadur Singh');

      final adminState = SocietySetupLoaded(
        users: allUsers,
        roleFilter: 'admin',
      );
      expect(adminState.filteredUsers.length, 1);
      expect(adminState.filteredUsers.first.name, 'Keval Admin');
    });

    test('SocietySetupLoaded filters users by block name', () {
      final blockAState = SocietySetupLoaded(
        users: allUsers,
        blockFilter: 'A',
      );
      expect(blockAState.filteredUsers.length, 2); // user1 and user4

      final blockBState = SocietySetupLoaded(
        users: allUsers,
        blockFilter: 'B',
      );
      expect(blockBState.filteredUsers.length, 1);
      expect(blockBState.filteredUsers.first.name, 'Sureshbhai Shah');
    });

    test('SocietySetupLoaded search query matches name, phone, or unit number', () {
      final searchByName = SocietySetupLoaded(
        users: allUsers,
        searchQuery: 'ramesh',
      );
      expect(searchByName.filteredUsers.length, 1);
      expect(searchByName.filteredUsers.first.uid, 'u1');

      final searchByPhone = SocietySetupLoaded(
        users: allUsers,
        searchQuery: '999888',
      );
      expect(searchByPhone.filteredUsers.length, 1);
      expect(searchByPhone.filteredUsers.first.name, 'Bahadur Singh');

      final searchByUnit = SocietySetupLoaded(
        users: allUsers,
        searchQuery: '202',
      );
      expect(searchByUnit.filteredUsers.length, 1);
      expect(searchByUnit.filteredUsers.first.name, 'Sureshbhai Shah');
    });

    test('SocietySetupLoaded handles multiple filters simultaneously', () {
      final filtered = SocietySetupLoaded(
        users: allUsers,
        roleFilter: 'member',
        blockFilter: 'A',
        searchQuery: '101',
      );

      expect(filtered.filteredUsers.length, 1);
      expect(filtered.filteredUsers.first.name, 'Rameshbhai Patel');
    });
  });
}
