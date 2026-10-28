import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/complaint_model.dart';
import 'package:building_guard/blocs/complaints/complaints_bloc.dart';

void main() {
  group('ComplaintsBloc State and Urgency Tests', () {
    final now = DateTime.now();

    final testComplaint1 = ComplaintModel(
      id: 'c1',
      societyId: 'soc123',
      title: 'Water motor leakage in basement',
      category: 'પાણી પુરવઠો',
      description: 'Continuous leaking from overhead tank pipe',
      memberId: 'm1',
      memberName: 'Keval Satani',
      memberFlat: 'A-101',
      isUrgent: true,
      status: 'pending',
      createdAt: now.subtract(const Duration(hours: 2)),
    );

    final testComplaint2 = ComplaintModel(
      id: 'c2',
      societyId: 'soc123',
      title: 'Lift button stuck on 3rd floor',
      category: 'લિફ્ટ સમસ્યા',
      description: 'Up arrow button not responding',
      memberId: 'm2',
      memberName: 'Hardik',
      memberFlat: 'B-202',
      isUrgent: false,
      status: 'pending',
      createdAt: now.subtract(const Duration(hours: 5)),
    );

    final testComplaint3 = ComplaintModel(
      id: 'c3',
      societyId: 'soc123',
      title: 'Common passage light fused',
      category: 'લાઈટ / વીજળી',
      description: 'Replaced with new 20W LED',
      memberId: 'm1',
      memberName: 'Keval Satani',
      memberFlat: 'A-101',
      isUrgent: false,
      status: 'resolved',
      createdAt: now.subtract(const Duration(days: 2)),
      resolvedAt: now.subtract(const Duration(days: 1)),
      resolutionNotes: 'Bulb changed by electrician',
    );

    test('ComplaintsLoaded counts pending, resolved, and urgent complaints accurately', () {
      final state = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
      );

      expect(state.pendingCount, 2);   // c1, c2
      expect(state.resolvedCount, 1);  // c3
      expect(state.urgentCount, 1);    // c1 (urgent & pending)
    });

    test('ComplaintsLoaded filters by status properly', () {
      final statePending = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        statusFilter: 'pending',
      );
      expect(statePending.filteredComplaints.length, 2);

      final stateResolved = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        statusFilter: 'resolved',
      );
      expect(stateResolved.filteredComplaints.length, 1);
      expect(stateResolved.filteredComplaints.first.id, 'c3');

      final stateUrgent = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        statusFilter: 'urgent',
      );
      expect(stateUrgent.filteredComplaints.length, 1);
      expect(stateUrgent.filteredComplaints.first.id, 'c1');
    });

    test('ComplaintsLoaded filters by category properly', () {
      final stateCategory = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        categoryFilter: 'લિફ્ટ',
      );
      expect(stateCategory.filteredComplaints.length, 1);
      expect(stateCategory.filteredComplaints.first.id, 'c2');
    });

    test('ComplaintsLoaded search filters across title, description, and flat', () {
      final stateSearchDesc = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        searchQuery: 'leakage',
      );
      expect(stateSearchDesc.filteredComplaints.length, 1);
      expect(stateSearchDesc.filteredComplaints.first.id, 'c1');

      final stateSearchFlat = ComplaintsLoaded(
        complaints: [testComplaint1, testComplaint2, testComplaint3],
        searchQuery: 'B-202',
      );
      expect(stateSearchFlat.filteredComplaints.length, 1);
      expect(stateSearchFlat.filteredComplaints.first.id, 'c2');
    });

    test('ComplaintsLoaded copyWith preserves state immutability', () {
      final state1 = ComplaintsLoaded(
        complaints: [testComplaint1],
        statusFilter: 'all',
      );

      final state2 = state1.copyWith(
        statusFilter: 'urgent',
        searchQuery: 'leakage',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'urgent');
      expect(state2.searchQuery, 'leakage');
      expect(state2.isActionInProgress, true);
    });
  });
}
