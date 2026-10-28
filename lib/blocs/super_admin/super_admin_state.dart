import 'package:equatable/equatable.dart';
import '../../models/super_admin_models.dart';

abstract class SuperAdminState extends Equatable {
  const SuperAdminState();

  @override
  List<Object?> get props => [];
}

class SuperAdminInitial extends SuperAdminState {}

class SuperAdminLoading extends SuperAdminState {}

class SuperAdminLoaded extends SuperAdminState {
  final GlobalPlatformStats stats;
  final List<SocietyOverview> societies;
  final String architectureFilter; // 'all', 'Commercial', 'Mixed', 'Wing', 'Street'
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const SuperAdminLoaded({
    required this.stats,
    this.societies = const [],
    this.architectureFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered list of societies based on architecture type and search keyword
  List<SocietyOverview> get filteredSocieties {
    final query = searchQuery.trim().toLowerCase();

    return societies.where((soc) {
      // 1. Architecture Filter
      if (architectureFilter != 'all') {
        if (!soc.architectureType.toLowerCase().contains(architectureFilter.toLowerCase())) {
          return false;
        }
      }

      // 2. Search Query Filter (name, city, admin name, phone)
      if (query.isNotEmpty) {
        final matchesName = soc.name.toLowerCase().contains(query);
        final matchesCity = soc.city.toLowerCase().contains(query);
        final matchesAdmin = soc.adminName.toLowerCase().contains(query);
        final matchesPhone = soc.adminPhone.contains(query);

        if (!matchesName && !matchesCity && !matchesAdmin && !matchesPhone) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total count of active societies on the platform
  int get activeSocietiesCount => societies.where((s) => s.isActive).length;

  /// Total count of suspended societies on the platform
  int get suspendedSocietiesCount => societies.where((s) => !s.isActive).length;

  SuperAdminLoaded copyWith({
    GlobalPlatformStats? stats,
    List<SocietyOverview>? societies,
    String? architectureFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return SuperAdminLoaded(
      stats: stats ?? this.stats,
      societies: societies ?? this.societies,
      architectureFilter: architectureFilter ?? this.architectureFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        stats,
        societies,
        architectureFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class SuperAdminFailure extends SuperAdminState {
  final String errorMessage;

  const SuperAdminFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
