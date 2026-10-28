import 'package:equatable/equatable.dart';
import '../../models/complaint_model.dart';

abstract class ComplaintsState extends Equatable {
  const ComplaintsState();

  @override
  List<Object?> get props => [];
}

class ComplaintsInitial extends ComplaintsState {}

class ComplaintsLoading extends ComplaintsState {}

class ComplaintsLoaded extends ComplaintsState {
  final List<ComplaintModel> complaints;
  final String statusFilter; // 'all', 'pending', 'resolved', 'urgent'
  final String categoryFilter;
  final String searchQuery;
  final String scope;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const ComplaintsLoaded({
    this.complaints = const [],
    this.statusFilter = 'all',
    this.categoryFilter = 'all',
    this.searchQuery = '',
    this.scope = 'society',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered complaints based on status, category, and search keyword
  List<ComplaintModel> get filteredComplaints {
    final query = searchQuery.trim().toLowerCase();

    return complaints.where((c) {
      // 1. Status Filter
      if (statusFilter == 'pending' && c.isResolved) return false;
      if (statusFilter == 'resolved' && !c.isResolved) return false;
      if (statusFilter == 'urgent' && (!c.isUrgent || c.isResolved)) return false;

      // 2. Category Filter
      if (categoryFilter != 'all') {
        if (!c.category.toLowerCase().contains(categoryFilter.toLowerCase())) {
          return false;
        }
      }

      // 3. Search Query Filter
      if (query.isNotEmpty) {
        final matchesTitle = c.title.toLowerCase().contains(query);
        final matchesDesc = c.description.toLowerCase().contains(query);
        final matchesMember = c.memberName.toLowerCase().contains(query);
        final matchesFlat = c.memberFlat.toLowerCase().contains(query);
        final matchesCat = c.category.toLowerCase().contains(query);

        if (!matchesTitle && !matchesDesc && !matchesMember && !matchesFlat && !matchesCat) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Number of pending unresolved complaints
  int get pendingCount => complaints.where((c) => c.isPending).length;

  /// Number of resolved complaints
  int get resolvedCount => complaints.where((c) => c.isResolved).length;

  /// Number of urgent complaints pending resolution
  int get urgentCount => complaints.where((c) => c.isUrgent && c.isPending).length;

  ComplaintsLoaded copyWith({
    List<ComplaintModel>? complaints,
    String? statusFilter,
    String? categoryFilter,
    String? searchQuery,
    String? scope,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return ComplaintsLoaded(
      complaints: complaints ?? this.complaints,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      scope: scope ?? this.scope,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        complaints,
        statusFilter,
        categoryFilter,
        searchQuery,
        scope,
        isActionInProgress,
        feedbackMessage,
      ];
}

class ComplaintsFailure extends ComplaintsState {
  final String errorMessage;

  const ComplaintsFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
