import 'package:equatable/equatable.dart';
import '../../models/super_admin_models.dart';

abstract class SuperAdminEvent extends Equatable {
  const SuperAdminEvent();

  @override
  List<Object?> get props => [];
}

/// Request refresh of platform global stats and all societies list
class SuperAdminRefreshRequested extends SuperAdminEvent {
  const SuperAdminRefreshRequested();
}

/// Internal event fired when societies and stats are loaded
class SuperAdminDataLoaded extends SuperAdminEvent {
  final GlobalPlatformStats stats;
  final List<SocietyOverview> societies;

  const SuperAdminDataLoaded({
    required this.stats,
    required this.societies,
  });

  @override
  List<Object?> get props => [stats, societies];
}

/// Filter societies by architecture type ('all', 'Commercial', 'Mixed', 'Wing', 'Street')
class SuperAdminArchitectureFilterChanged extends SuperAdminEvent {
  final String architectureFilter;

  const SuperAdminArchitectureFilterChanged(this.architectureFilter);

  @override
  List<Object?> get props => [architectureFilter];
}

/// Search societies by name, city, admin name, or phone
class SuperAdminSearchQueryChanged extends SuperAdminEvent {
  final String query;

  const SuperAdminSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Suspend or Activate a society
class SuperAdminToggleSocietyStatusRequested extends SuperAdminEvent {
  final String societyId;
  final bool suspend;
  final String reason;

  const SuperAdminToggleSocietyStatusRequested({
    required this.societyId,
    required this.suspend,
    this.reason = '',
  });

  @override
  List<Object?> get props => [societyId, suspend, reason];
}
