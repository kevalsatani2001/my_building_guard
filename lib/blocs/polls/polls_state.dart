import 'package:equatable/equatable.dart';
import '../../models/poll_model.dart';

abstract class PollsState extends Equatable {
  const PollsState();

  @override
  List<Object?> get props => [];
}

class PollsInitial extends PollsState {}

class PollsLoading extends PollsState {}

class PollsLoaded extends PollsState {
  final List<PollModel> polls;
  final String statusFilter; // 'all', 'active', 'closed'
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const PollsLoaded({
    this.polls = const [],
    this.statusFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered polls by live status and search keyword
  List<PollModel> get filteredPolls {
    final query = searchQuery.trim().toLowerCase();

    return polls.where((p) {
      // 1. Status Filter
      if (statusFilter == 'active' && !p.isLive) return false;
      if (statusFilter == 'closed' && p.isLive) return false;

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final matchesTitle = p.title.toLowerCase().contains(query);
        final matchesDesc = p.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      return true;
    }).toList();
  }

  /// List of currently active polls
  List<PollModel> get activePolls => polls.where((p) => p.isLive).toList();

  /// List of closed / concluded polls
  List<PollModel> get closedPolls => polls.where((p) => !p.isLive).toList();

  /// Number of currently live polls accepting votes
  int get activePollsCount => activePolls.length;

  /// Number of closed / concluded polls
  int get closedPollsCount => closedPolls.length;

  /// Total votes recorded across all society polls
  int get totalVotesSum => polls.fold(0, (sum, p) => sum + p.totalVotes);

  PollsLoaded copyWith({
    List<PollModel>? polls,
    String? statusFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return PollsLoaded(
      polls: polls ?? this.polls,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        polls,
        statusFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class PollsFailure extends PollsState {
  final String errorMessage;

  const PollsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
