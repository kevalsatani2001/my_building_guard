import 'package:equatable/equatable.dart';
import '../../models/visitor_model.dart';

abstract class VisitorEvent extends Equatable {
  const VisitorEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to visitors stream for a society with optional member flat filters
class VisitorSubscriptionRequested extends VisitorEvent {
  final String societyId;
  final String? memberId;
  final String? blockName;
  final String? unitNumber;
  final String scope; // 'all_society' or 'my_flat'

  const VisitorSubscriptionRequested({
    required this.societyId,
    this.memberId,
    this.blockName,
    this.unitNumber,
    this.scope = 'all_society',
  });

  @override
  List<Object?> get props => [societyId, memberId, blockName, unitNumber, scope];
}

/// Internal event fired when visitors stream updates from Firestore
class VisitorsUpdated extends VisitorEvent {
  final List<VisitorModel> visitors;
  const VisitorsUpdated(this.visitors);

  @override
  List<Object?> get props => [visitors];
}

/// Internal event fired when visitors stream fails
class VisitorErrorOccurred extends VisitorEvent {
  final String error;
  const VisitorErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter visitors by status ('all', 'pending', 'approved', 'rejected', 'checked_out')
class VisitorStatusFilterChanged extends VisitorEvent {
  final String statusFilter;
  const VisitorStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Filter visitors by time window ('today', '7d', '30d', 'all')
class VisitorTimeFilterChanged extends VisitorEvent {
  final String timeFilter;
  const VisitorTimeFilterChanged(this.timeFilter);

  @override
  List<Object?> get props => [timeFilter];
}

/// Search visitors by name, phone or unit number
class VisitorSearchQueryChanged extends VisitorEvent {
  final String query;
  const VisitorSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Resident approves visitor entry
class VisitorApproveRequested extends VisitorEvent {
  final String visitorId;
  final String? visitorName;
  const VisitorApproveRequested({
    required this.visitorId,
    this.visitorName,
  });

  @override
  List<Object?> get props => [visitorId, visitorName];
}

/// Resident rejects visitor entry
class VisitorRejectRequested extends VisitorEvent {
  final String visitorId;
  final String? visitorName;
  const VisitorRejectRequested({
    required this.visitorId,
    this.visitorName,
  });

  @override
  List<Object?> get props => [visitorId, visitorName];
}

/// Watchman checks out a visitor
class VisitorCheckOutRequested extends VisitorEvent {
  final String visitorId;
  const VisitorCheckOutRequested(this.visitorId);

  @override
  List<Object?> get props => [visitorId];
}

/// Watchman logs new visitor entry
class VisitorAddRequested extends VisitorEvent {
  final VisitorModel visitor;
  const VisitorAddRequested(this.visitor);

  @override
  List<Object?> get props => [visitor.id, visitor.name, visitor.phone];
}
