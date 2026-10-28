import 'package:equatable/equatable.dart';
import '../../models/notice_model.dart';

abstract class NoticeEvent extends Equatable {
  const NoticeEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to society notice board
class NoticeSubscriptionRequested extends NoticeEvent {
  final String societyId;
  final String? blockFilter;

  const NoticeSubscriptionRequested({
    required this.societyId,
    this.blockFilter,
  });

  @override
  List<Object?> get props => [societyId, blockFilter];
}

/// Internal event fired when notices stream updates
class NoticesUpdated extends NoticeEvent {
  final List<NoticeModel> notices;

  const NoticesUpdated(this.notices);

  @override
  List<Object?> get props => [notices];
}

/// Internal event fired when notices stream fails
class NoticeErrorOccurred extends NoticeEvent {
  final String error;

  const NoticeErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter notices by category ('all', 'સામાન્ય', 'પાણી', 'લાઈટ', 'મીટિંગ', 'ઉત્સવ', 'સફાઈ')
class NoticeCategoryFilterChanged extends NoticeEvent {
  final String category;

  const NoticeCategoryFilterChanged(this.category);

  @override
  List<Object?> get props => [category];
}

/// Filter notices by urgency ('all', 'urgent_only')
class NoticeUrgencyFilterChanged extends NoticeEvent {
  final bool urgentOnly;

  const NoticeUrgencyFilterChanged(this.urgentOnly);

  @override
  List<Object?> get props => [urgentOnly];
}

/// Search notices by title or content body
class NoticeSearchQueryChanged extends NoticeEvent {
  final String query;

  const NoticeSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Admin publishes a new notice
class NoticePublishRequested extends NoticeEvent {
  final String title;
  final String body;
  final String category;
  final String? targetBlock;
  final bool isUrgent;
  final bool isPinned;

  const NoticePublishRequested({
    required this.title,
    required this.body,
    this.category = 'સામાન્ય',
    this.targetBlock,
    this.isUrgent = false,
    this.isPinned = false,
  });

  @override
  List<Object?> get props => [title, body, category, targetBlock, isUrgent, isPinned];
}

/// Admin deletes a notice
class NoticeDeleteRequested extends NoticeEvent {
  final String noticeId;

  const NoticeDeleteRequested(this.noticeId);

  @override
  List<Object?> get props => [noticeId];
}
