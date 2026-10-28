import 'package:equatable/equatable.dart';
import '../../models/staff_model.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to daily staff (optionally scoped to a member or entire society)
class StaffSubscriptionRequested extends StaffEvent {
  final String societyId;
  final String? memberId;
  final String scope; // 'society' or 'my_staff'

  const StaffSubscriptionRequested({
    required this.societyId,
    this.memberId,
    this.scope = 'society',
  });

  @override
  List<Object?> get props => [societyId, memberId, scope];
}

/// Internal event fired when staff stream updates
class StaffListUpdated extends StaffEvent {
  final List<DailyStaffModel> staffList;

  const StaffListUpdated(this.staffList);

  @override
  List<Object?> get props => [staffList];
}

/// Internal event fired when staff stream fails
class StaffErrorOccurred extends StaffEvent {
  final String error;

  const StaffErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter by role ('all', 'Maid', 'Driver', 'Cook', 'Gardener', 'Tutor')
class StaffRoleFilterChanged extends StaffEvent {
  final String role;

  const StaffRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

/// Search staff by name or phone number
class StaffSearchQueryChanged extends StaffEvent {
  final String query;

  const StaffSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Add new staff member
class StaffAddRequested extends StaffEvent {
  final String staffName;
  final String staffPhone;
  final String staffRole;
  final String memberId;

  const StaffAddRequested({
    required this.staffName,
    required this.staffPhone,
    required this.staffRole,
    required this.memberId,
  });

  @override
  List<Object?> get props => [staffName, staffPhone, staffRole, memberId];
}

/// Delete a staff member
class StaffDeleteRequested extends StaffEvent {
  final String staffId;

  const StaffDeleteRequested(this.staffId);

  @override
  List<Object?> get props => [staffId];
}
