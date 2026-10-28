import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/notice_model.dart';
import 'package:building_guard/blocs/notice/notice_bloc.dart';

void main() {
  group('NoticeBloc State and Filter Calculation Tests', () {
    final now = DateTime.now();

    final testNotice1 = NoticeModel(
      id: 'n1',
      societyId: 'soc123',
      title: 'Water Supply Timings Tomorrow',
      body: 'Morning 6 AM to 8 AM due to pipeline maintenance',
      category: 'પાણી',
      isUrgent: true,
      isPinned: true,
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    final testNotice2 = NoticeModel(
      id: 'n2',
      societyId: 'soc123',
      title: 'Annual General Meeting',
      body: 'All residents are requested to attend the meeting in Clubhouse',
      category: 'મીટિંગ',
      isUrgent: false,
      isPinned: true,
      createdAt: now.subtract(const Duration(days: 1)),
    );

    final testNotice3 = NoticeModel(
      id: 'n3',
      societyId: 'soc123',
      title: 'Diwali Cleanliness Drive',
      body: 'Keep common passages clear of heavy items',
      category: 'સફાઈ',
      isUrgent: false,
      isPinned: false,
      createdAt: now.subtract(const Duration(days: 3)),
    );

    test('NoticeLoaded computes counts and pinned notices accurately', () {
      final state = NoticeLoaded(
        notices: [testNotice1, testNotice2, testNotice3],
      );

      expect(state.totalCount, 3);
      expect(state.urgentCount, 1);       // n1
      expect(state.pinnedNotices.length, 2); // n1, n2
    });

    test('NoticeLoaded filters by category properly', () {
      final stateWater = NoticeLoaded(
        notices: [testNotice1, testNotice2, testNotice3],
        categoryFilter: 'પાણી',
      );
      expect(stateWater.filteredNotices.length, 1);
      expect(stateWater.filteredNotices.first.id, 'n1');
    });

    test('NoticeLoaded filters by urgency properly', () {
      final stateUrgent = NoticeLoaded(
        notices: [testNotice1, testNotice2, testNotice3],
        urgentOnly: true,
      );
      expect(stateUrgent.filteredNotices.length, 1);
      expect(stateUrgent.filteredNotices.first.id, 'n1');
    });

    test('NoticeLoaded search query matches title or body', () {
      final statePipeline = NoticeLoaded(
        notices: [testNotice1, testNotice2, testNotice3],
        searchQuery: 'pipeline',
      );
      expect(statePipeline.filteredNotices.length, 1);
      expect(statePipeline.filteredNotices.first.id, 'n1');

      final stateAGM = NoticeLoaded(
        notices: [testNotice1, testNotice2, testNotice3],
        searchQuery: 'General Meeting',
      );
      expect(stateAGM.filteredNotices.length, 1);
      expect(stateAGM.filteredNotices.first.id, 'n2');
    });

    test('NoticeLoaded copyWith preserves state immutability', () {
      final state1 = NoticeLoaded(
        notices: [testNotice1],
        categoryFilter: 'all',
      );

      final state2 = state1.copyWith(
        categoryFilter: 'મીટિંગ',
        urgentOnly: true,
        searchQuery: 'AGM',
        isActionInProgress: true,
      );

      expect(state1.categoryFilter, 'all');
      expect(state2.categoryFilter, 'મીટિંગ');
      expect(state2.urgentOnly, true);
      expect(state2.searchQuery, 'AGM');
      expect(state2.isActionInProgress, true);
    });
  });
}
