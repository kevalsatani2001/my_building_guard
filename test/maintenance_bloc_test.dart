import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/maintenance_model.dart';
import 'package:building_guard/blocs/maintenance/maintenance_bloc.dart';

void main() {
  group('MaintenanceBloc State and Financial Analytics Tests', () {
    final now = DateTime.now();

    final testBill1 = MaintenanceBill(
      id: 'b1',
      societyId: 'soc123',
      billTitle: 'October Maintenance',
      billingMonth: '2026-10',
      dueDate: now.add(const Duration(days: 5)),
      amount: 2000.0,
      penaltyAmount: 100.0,
      festivalCharge: 500.0,
      blockName: 'A',
      unitNumber: '101',
      memberName: 'Keval Satani',
      memberPhone: '9876543210',
      status: MaintenanceStatus.paid,
      paymentMode: 'upi',
      receiptNumber: 'REC-202610-A101',
    );

    final testBill2 = MaintenanceBill(
      id: 'b2',
      societyId: 'soc123',
      billTitle: 'October Maintenance',
      billingMonth: '2026-10',
      dueDate: now.subtract(const Duration(days: 2)),
      amount: 1500.0,
      penaltyAmount: 50.0,
      blockName: 'B',
      unitNumber: '505',
      memberName: 'Hardik Patel',
      memberPhone: '9123456780',
      status: MaintenanceStatus.pending,
    );

    final testBill3 = MaintenanceBill(
      id: 'b3',
      societyId: 'soc123',
      billTitle: 'September Maintenance',
      billingMonth: '2026-09',
      dueDate: now.subtract(const Duration(days: 35)),
      amount: 1500.0,
      blockName: 'B',
      unitNumber: '505',
      memberName: 'Hardik Patel',
      memberPhone: '9123456780',
      status: MaintenanceStatus.overdue,
    );

    test('MaintenanceLoaded computes correct financial metrics', () {
      final state = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
      );

      // Bill 1: 2000 + 100 + 500 = 2600 (Paid)
      // Bill 2: 1500 + 50 = 1550 (Pending)
      // Bill 3: 1500 (Overdue)
      // Total: 2600 + 1550 + 1500 = 5650.0
      expect(state.totalBilledAmount, 5650.0);
      expect(state.totalCollectedAmount, 2600.0);
      expect(state.pendingCollectionAmount, 3050.0);
      expect(state.paidCount, 1);
      expect(state.pendingCount, 1);
      expect(state.overdueCount, 1);
      expect(state.underReviewCount, 0);

      // Collection percentage: 2600 / 5650 * 100 ~ 46.01%
      expect(state.collectionPercentage, closeTo(46.01, 0.1));
    });

    test('MaintenanceLoaded extracts unique billing months sorted descending', () {
      final state = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
      );

      expect(state.availableMonths, ['2026-10', '2026-09']);
    });

    test('MaintenanceLoaded filters by billing month properly', () {
      final state = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
        monthFilter: '2026-09',
      );

      final filtered = state.filteredBills;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'b3');
    });

    test('MaintenanceLoaded filters by status properly', () {
      final state = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
        statusFilter: 'paid',
      );

      final filtered = state.filteredBills;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'b1');
    });

    test('MaintenanceLoaded search filters by flat number and member name', () {
      final stateNameSearch = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
        searchQuery: 'keval',
      );
      expect(stateNameSearch.filteredBills.length, 1);
      expect(stateNameSearch.filteredBills.first.id, 'b1');

      final stateUnitSearch = MaintenanceLoaded(
        allBills: [testBill1, testBill2, testBill3],
        searchQuery: '505',
      );
      expect(stateUnitSearch.filteredBills.length, 2);
    });

    test('MaintenanceLoaded copyWith preserves immutability', () {
      final state1 = MaintenanceLoaded(
        allBills: [testBill1],
        statusFilter: 'all',
      );

      final state2 = state1.copyWith(
        statusFilter: 'paid',
        monthFilter: '2026-10',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'paid');
      expect(state2.monthFilter, '2026-10');
      expect(state2.isActionInProgress, true);
    });
  });
}
