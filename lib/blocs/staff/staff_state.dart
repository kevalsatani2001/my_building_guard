import 'package:equatable/equatable.dart';
import '../../models/staff_model.dart';

abstract class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<DailyStaffModel> staffList;
  final String roleFilter; // 'all' or specific role
  final String searchQuery;
  final String scope;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const StaffLoaded({
    this.staffList = const [],
    this.roleFilter = 'all',
    this.searchQuery = '',
    this.scope = 'society',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered list of staff based on role and search query
  List<DailyStaffModel> get filteredStaff {
    final query = searchQuery.trim().toLowerCase();

    return staffList.where((s) {
      // 1. Role Filter
      if (roleFilter != 'all') {
        if (!s.staffRole.toLowerCase().contains(roleFilter.toLowerCase())) {
          return false;
        }
      }

      // 2. Search Query Filter (name or phone)
      if (query.isNotEmpty) {
        final matchesName = s.staffName.toLowerCase().contains(query);
        final matchesPhone = s.staffPhone.contains(query);
        final matchesRole = s.staffRole.toLowerCase().contains(query);

        if (!matchesName && !matchesPhone && !matchesRole) return false;
      }

      return true;
    }).toList();
  }

  /// Total count of staff
  int get totalStaffCount => staffList.length;

  /// Active staff count
  int get activeStaffCount => staffList.where((s) => s.isActive).length;

  StaffLoaded copyWith({
    List<DailyStaffModel>? staffList,
    String? roleFilter,
    String? searchQuery,
    String? scope,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return StaffLoaded(
      staffList: staffList ?? this.staffList,
      roleFilter: roleFilter ?? this.roleFilter,
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
        staffList,
        roleFilter,
        searchQuery,
        scope,
        isActionInProgress,
        feedbackMessage,
      ];
}

class StaffFailure extends StaffState {
  final String errorMessage;

  const StaffFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
