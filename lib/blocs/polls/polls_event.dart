import 'package:equatable/equatable.dart';
import '../../models/poll_model.dart';

abstract class PollsEvent extends Equatable {
  const PollsEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to society polls
class PollsSubscriptionRequested extends PollsEvent {
  final String societyId;
  final String? blockScope;

  const PollsSubscriptionRequested({
    required this.societyId,
    this.blockScope,
  });

  @override
  List<Object?> get props => [societyId, blockScope];
}

/// Internal event fired when polls stream updates
class PollsUpdated extends PollsEvent {
  final List<PollModel> polls;

  const PollsUpdated(this.polls);

  @override
  List<Object?> get props => [polls];
}

/// Internal event fired when polls stream fails
class PollsErrorOccurred extends PollsEvent {
  final String error;

  const PollsErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter polls ('all', 'active', 'closed')
class PollsFilterChanged extends PollsEvent {
  final String statusFilter;

  const PollsFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Filter polls by search query in title or description
class PollsSearchQueryChanged extends PollsEvent {
  final String query;

  const PollsSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Create a new society poll
class PollCreateRequested extends PollsEvent {
  final String title;
  final String description;
  final List<String> optionTexts;
  final DateTime endDate;
  final DateTime? startDate;
  final String targetScope;
  final String voterEligibility;
  final bool isAnonymous;
  final String createdByName;

  const PollCreateRequested({
    required this.title,
    required this.description,
    required this.optionTexts,
    required this.endDate,
    this.startDate,
    this.targetScope = 'all',
    this.voterEligibility = 'all_members',
    this.isAnonymous = false,
    this.createdByName = '',
  });

  @override
  List<Object?> get props => [
        title,
        description,
        optionTexts,
        endDate,
        startDate,
        targetScope,
        voterEligibility,
        isAnonymous,
        createdByName,
      ];
}

/// Member casts a vote on a poll
class PollCastVoteRequested extends PollsEvent {
  final String pollId;
  final String optionId;
  final String flatDisplay;

  const PollCastVoteRequested({
    required this.pollId,
    required this.optionId,
    required this.flatDisplay,
  });

  @override
  List<Object?> get props => [pollId, optionId, flatDisplay];
}

/// Society Admin closes a poll and optionally writes a final resolution summary
class PollCloseRequested extends PollsEvent {
  final String pollId;
  final String? resolutionSummary;

  const PollCloseRequested({
    required this.pollId,
    this.resolutionSummary,
  });

  @override
  List<Object?> get props => [pollId, resolutionSummary];
}

/// Society Admin deletes a poll
class PollDeleteRequested extends PollsEvent {
  final String pollId;

  const PollDeleteRequested(this.pollId);

  @override
  List<Object?> get props => [pollId];
}
