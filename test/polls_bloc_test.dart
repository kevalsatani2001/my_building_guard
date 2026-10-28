import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/poll_model.dart';
import 'package:building_guard/blocs/polls/polls_bloc.dart';

void main() {
  group('PollsBloc State and Option Calculation Tests', () {
    final now = DateTime.now();

    final testPoll1 = PollModel(
      id: 'p1',
      societyId: 'soc123',
      title: 'Solar Panel Installation on Terrace',
      description: 'Should we install 20kW solar rooftop panels?',
      options: const [
        PollOption(id: 'opt_1', text: 'હા (Yes)', votesCount: 15),
        PollOption(id: 'opt_2', text: 'ના (No)', votesCount: 3),
      ],
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
      createdByUid: 'admin1',
      createdAt: now.subtract(const Duration(days: 2)),
      statusActive: true,
      totalVotes: 18,
      votedMemberUids: const ['u1', 'u2', 'u3'],
      votedFlats: const ['A-101', 'A-102', 'B-201'],
    );

    final testPoll2 = PollModel(
      id: 'p2',
      societyId: 'soc123',
      title: 'Diwali Lighting Colors',
      description: 'Choose lighting color theme for campus',
      options: const [
        PollOption(id: 'opt_1', text: 'ગોલ્ડન (Warm White)', votesCount: 22),
        PollOption(id: 'opt_2', text: 'મલ્ટીકલર (RGB)', votesCount: 10),
      ],
      startDate: now.subtract(const Duration(days: 15)),
      endDate: now.subtract(const Duration(days: 2)), // Expired
      createdByUid: 'admin1',
      createdAt: now.subtract(const Duration(days: 15)),
      statusActive: true, // Expired by date
      totalVotes: 32,
    );

    test('PollsLoaded computes active, closed, and total votes correctly', () {
      final state = PollsLoaded(
        polls: [testPoll1, testPoll2],
      );

      expect(state.activePollsCount, 1); // p1 is live
      expect(state.closedPollsCount, 1); // p2 is expired
      expect(state.totalVotesSum, 50);    // 18 + 32
    });

    test('PollsLoaded filters by active and closed status', () {
      final stateActive = PollsLoaded(
        polls: [testPoll1, testPoll2],
        statusFilter: 'active',
      );
      expect(stateActive.filteredPolls.length, 1);
      expect(stateActive.filteredPolls.first.id, 'p1');

      final stateClosed = PollsLoaded(
        polls: [testPoll1, testPoll2],
        statusFilter: 'closed',
      );
      expect(stateClosed.filteredPolls.length, 1);
      expect(stateClosed.filteredPolls.first.id, 'p2');
    });

    test('PollsLoaded search query matches title or description', () {
      final stateSearch = PollsLoaded(
        polls: [testPoll1, testPoll2],
        searchQuery: 'solar',
      );
      expect(stateSearch.filteredPolls.length, 1);
      expect(stateSearch.filteredPolls.first.id, 'p1');
    });

    test('PollModel hasUserVoted and hasFlatVoted work accurately', () {
      expect(testPoll1.hasUserVoted('u1'), true);
      expect(testPoll1.hasUserVoted('unknown_user'), false);
      expect(testPoll1.hasFlatVoted('A-101'), true);
      expect(testPoll1.hasFlatVoted('C-303'), false);
    });

    test('PollsLoaded copyWith handles immutability', () {
      final state1 = PollsLoaded(
        polls: [testPoll1],
        statusFilter: 'all',
      );

      final state2 = state1.copyWith(
        statusFilter: 'active',
        searchQuery: 'lighting',
        isActionInProgress: true,
      );

      expect(state1.statusFilter, 'all');
      expect(state2.statusFilter, 'active');
      expect(state2.searchQuery, 'lighting');
      expect(state2.isActionInProgress, true);
    });
  });
}
