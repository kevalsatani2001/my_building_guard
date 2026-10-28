import 'package:equatable/equatable.dart';
import '../../models/notice_model.dart';

abstract class NoticeState extends Equatable {
  const NoticeState();

  @override
  List<Object?> get props => [];
}

class NoticeInitial extends NoticeState {}

class NoticeLoading extends NoticeState {}

class NoticeLoaded extends NoticeState {
  final List<NoticeModel> notices;
  final String categoryFilter; // 'all' or category name
  final bool urgentOnly;
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const NoticeLoaded({
    this.notices = const [],
    this.categoryFilter = 'all',
    this.urgentOnly = false,
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered notices based on category, urgency flag, and search query
  List<NoticeModel> get filteredNotices {
    final query = searchQuery.trim().toLowerCase();

    return notices.where((n) {
      // 1. Urgency Filter
      if (urgentOnly && !n.isUrgent) return false;

      // 2. Category Filter
      if (categoryFilter != 'all') {
        if (!n.category.toLowerCase().contains(categoryFilter.toLowerCase())) {
          return false;
        }
      }

      // 3. Search Query Filter
      if (query.isNotEmpty) {
        final matchesTitle = n.title.toLowerCase().contains(query);
        final matchesBody = n.body.toLowerCase().contains(query);
        final matchesCat = n.category.toLowerCase().contains(query);

        if (!matchesTitle && !matchesBody && !matchesCat) return false;
      }

      return true;
    }).toList();
  }

  /// Pinned notices for the hero carousel
  List<NoticeModel> get pinnedNotices => notices.where((n) => n.isPinned).toList();

  /// Total notices count
  int get totalCount => notices.length;

  /// Urgent notices count
  int get urgentCount => notices.where((n) => n.isUrgent).length;

  NoticeLoaded copyWith({
    List<NoticeModel>? notices,
    String? categoryFilter,
    bool? urgentOnly,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return NoticeLoaded(
      notices: notices ?? this.notices,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        notices,
        categoryFilter,
        urgentOnly,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class NoticeFailure extends NoticeState {
  final String errorMessage;

  const NoticeFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
