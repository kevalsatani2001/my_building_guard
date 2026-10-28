import 'package:equatable/equatable.dart';
import '../../models/visitor_model.dart';

abstract class VisitorState extends Equatable {
  const VisitorState();

  @override
  List<Object?> get props => [];
}

class VisitorInitial extends VisitorState {}

class VisitorLoading extends VisitorState {}

class VisitorLoaded extends VisitorState {
  final List<VisitorModel> allVisitors;
  final String statusFilter; // 'all', 'pending', 'approved', 'rejected', 'checked_out'
  final String timeFilter; // 'all', 'today', '7d', '30d'
  final String searchQuery;
  final String scope; // 'all_society' or 'my_flat'
  final bool isActionInProgress;
  final String? lastActionMessage;

  const VisitorLoaded({
    required this.allVisitors,
    this.statusFilter = 'all',
    this.timeFilter = 'all',
    this.searchQuery = '',
    this.scope = 'all_society',
    this.isActionInProgress = false,
    this.lastActionMessage,
  });

  /// Filtered list of visitors based on status, time cutoff, and search query
  List<VisitorModel> get filteredVisitors {
    final now = DateTime.now();
    DateTime? cutoff;
    if (timeFilter == 'today') {
      cutoff = DateTime(now.year, now.month, now.day);
    } else if (timeFilter == '7d') {
      cutoff = now.subtract(const Duration(days: 7));
    } else if (timeFilter == '30d') {
      cutoff = now.subtract(const Duration(days: 30));
    }

    final query = searchQuery.trim().toLowerCase();

    return allVisitors.where((visitor) {
      // 1. Time filter
      if (cutoff != null && visitor.entryTime.isBefore(cutoff)) {
        return false;
      }

      // 2. Status filter
      if (statusFilter != 'all') {
        if (statusFilter == 'checked_out') {
          if (visitor.status != 'checked_out' && visitor.exitTime == null) {
            return false;
          }
        } else if (visitor.status.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // 3. Search query filter
      if (query.isNotEmpty) {
        final matchesName = visitor.name.toLowerCase().contains(query);
        final matchesPhone = visitor.phone.toLowerCase().contains(query);
        final matchesUnit = visitor.unitNumber.toLowerCase().contains(query);
        final matchesPurpose = visitor.purpose.toLowerCase().contains(query);
        final matchesVehicle = visitor.vehicleNumber.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone && !matchesUnit && !matchesPurpose && !matchesVehicle) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Visitors waiting for resident approval
  int get pendingCount =>
      allVisitors.where((v) => v.status.toLowerCase() == 'pending').length;

  /// Visitors currently inside the campus (approved and not checked out)
  int get insideCount => allVisitors
      .where((v) => v.status.toLowerCase() == 'approved' && v.exitTime == null)
      .length;

  /// Visitors who arrived today
  int get todayCount {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return allVisitors.where((v) => !v.entryTime.isBefore(today)).length;
  }

  VisitorLoaded copyWith({
    List<VisitorModel>? allVisitors,
    String? statusFilter,
    String? timeFilter,
    String? searchQuery,
    String? scope,
    bool? isActionInProgress,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return VisitorLoaded(
      allVisitors: allVisitors ?? this.allVisitors,
      statusFilter: statusFilter ?? this.statusFilter,
      timeFilter: timeFilter ?? this.timeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      scope: scope ?? this.scope,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      lastActionMessage: clearActionMessage ? null : (lastActionMessage ?? this.lastActionMessage),
    );
  }

  @override
  List<Object?> get props => [
        allVisitors,
        statusFilter,
        timeFilter,
        searchQuery,
        scope,
        isActionInProgress,
        lastActionMessage,
      ];
}

class VisitorFailure extends VisitorState {
  final String errorMessage;

  const VisitorFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
