import 'package:equatable/equatable.dart';
import '../../models/complaint_model.dart';

abstract class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to complaints stream
class ComplaintsSubscriptionRequested extends ComplaintsEvent {
  final String societyId;
  final String? memberId;
  final String scope; // 'society' or 'member'

  const ComplaintsSubscriptionRequested({
    required this.societyId,
    this.memberId,
    this.scope = 'society',
  });

  @override
  List<Object?> get props => [societyId, memberId, scope];
}

/// Internal event fired when complaints stream updates
class ComplaintsUpdated extends ComplaintsEvent {
  final List<ComplaintModel> complaints;

  const ComplaintsUpdated(this.complaints);

  @override
  List<Object?> get props => [complaints];
}

/// Internal event fired when complaints stream fails
class ComplaintsErrorOccurred extends ComplaintsEvent {
  final String error;

  const ComplaintsErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter by status ('all', 'pending', 'resolved', 'urgent')
class ComplaintFilterChanged extends ComplaintsEvent {
  final String filter;

  const ComplaintFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Filter by complaint category
class ComplaintCategoryFilterChanged extends ComplaintsEvent {
  final String category;

  const ComplaintCategoryFilterChanged(this.category);

  @override
  List<Object?> get props => [category];
}

/// Search complaints by title, description, flat, or member name
class ComplaintSearchQueryChanged extends ComplaintsEvent {
  final String query;

  const ComplaintSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Member files a new complaint
class ComplaintCreateRequested extends ComplaintsEvent {
  final ComplaintModel complaint;

  const ComplaintCreateRequested(this.complaint);

  @override
  List<Object?> get props => [complaint.title, complaint.memberId];
}

/// Admin resolves a complaint
class ComplaintResolveRequested extends ComplaintsEvent {
  final String complaintId;
  final String? resolutionNotes;

  const ComplaintResolveRequested({
    required this.complaintId,
    this.resolutionNotes,
  });

  @override
  List<Object?> get props => [complaintId, resolutionNotes];
}

/// Delete a complaint
class ComplaintDeleteRequested extends ComplaintsEvent {
  final String complaintId;

  const ComplaintDeleteRequested(this.complaintId);

  @override
  List<Object?> get props => [complaintId];
}
