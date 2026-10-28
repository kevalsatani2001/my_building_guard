import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/visitor_model.dart';
import 'package:building_guard/blocs/visitor/visitor_bloc.dart';

void main() {
  group('VisitorBloc Models and State Filtering Tests', () {
    final now = DateTime.now();

    final testVisitor1 = VisitorModel(
      id: 'v1',
      name: 'Ramesh Patel',
      phone: '9876543210',
      purpose: 'Meeting',
      photoUrl: '',
      memberId: 'm1',
      memberName: 'Keval Satani',
      blockName: 'A',
      unitNumber: '101',
      societyId: 'soc123',
      status: 'pending',
      visitorType: 'guest',
      vehicleNumber: 'GJ-01-AB-1234',
      entryTime: now.subtract(const Duration(hours: 1)),
    );

    final testVisitor2 = VisitorModel(
      id: 'v2',
      name: 'Amazon Delivery',
      phone: '9123456780',
      purpose: 'Parcel',
      photoUrl: '',
      memberId: 'm2',
      memberName: 'Hardik',
      blockName: 'B',
      unitNumber: '202',
      societyId: 'soc123',
      status: 'approved',
      visitorType: 'delivery',
      vehicleNumber: 'GJ-05-XY-9999',
      entryTime: now.subtract(const Duration(hours: 3)),
    );

    final testVisitor3 = VisitorModel(
      id: 'v3',
      name: 'Old Visitor',
      phone: '9000000000',
      purpose: 'Old repair',
      photoUrl: '',
      memberId: 'm1',
      memberName: 'Keval Satani',
      blockName: 'A',
      unitNumber: '101',
      societyId: 'soc123',
      status: 'checked_out',
      visitorType: 'service',
      vehicleNumber: '',
      entryTime: now.subtract(const Duration(days: 10)),
      exitTime: now.subtract(const Duration(days: 10, hours: -1)),
    );

    test('VisitorLoaded correctly calculates pending, inside, and today counts', () {
      final state = VisitorLoaded(
        allVisitors: [testVisitor1, testVisitor2, testVisitor3],
      );

      expect(state.pendingCount, 1); // testVisitor1
      expect(state.insideCount, 1);  // testVisitor2 (approved & no exitTime)
      expect(state.todayCount, 2);   // v1 and v2 are within today
    });

    test('VisitorLoaded filters visitors by status properly', () {
      final state = VisitorLoaded(
        allVisitors: [testVisitor1, testVisitor2, testVisitor3],
        statusFilter: 'pending',
      );

      final filtered = state.filteredVisitors;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'v1');
    });

    test('VisitorLoaded filters visitors by time window properly', () {
      final state = VisitorLoaded(
        allVisitors: [testVisitor1, testVisitor2, testVisitor3],
        timeFilter: '7d',
      );

      final filtered = state.filteredVisitors;
      expect(filtered.length, 2);
      expect(filtered.any((v) => v.id == 'v3'), false); // 10 days old should be excluded
    });

    test('VisitorLoaded filters visitors by search query properly', () {
      final state = VisitorLoaded(
        allVisitors: [testVisitor1, testVisitor2, testVisitor3],
        searchQuery: 'amazon',
      );

      final filtered = state.filteredVisitors;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Amazon Delivery');
    });

    test('VisitorLoaded filters by vehicle number in search query', () {
      final state = VisitorLoaded(
        allVisitors: [testVisitor1, testVisitor2, testVisitor3],
        searchQuery: 'GJ-01',
      );

      final filtered = state.filteredVisitors;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'v1');
    });

    test('VisitorLoaded copyWith immutability works correctly', () {
      final state1 = VisitorLoaded(
        allVisitors: [testVisitor1],
        statusFilter: 'all',
      );

      final state2 = state1.copyWith(
        statusFilter: 'approved',
        searchQuery: 'test',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'approved');
      expect(state2.searchQuery, 'test');
      expect(state2.isActionInProgress, true);
      expect(state1.allVisitors, state2.allVisitors);
    });

    test('VisitorModel flatDisplay formats correctly', () {
      expect(testVisitor1.flatDisplay, 'A - 101');
      expect(testVisitor2.flatDisplay, 'B - 202');
    });
  });
}
