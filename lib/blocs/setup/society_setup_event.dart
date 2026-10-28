import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class SocietySetupEvent extends Equatable {
  const SocietySetupEvent();

  @override
  List<Object?> get props => [];
}

/// Request subscription to society setup: blocks, units, and directory of users
class SocietySetupSubscriptionRequested extends SocietySetupEvent {
  final String societyId;

  const SocietySetupSubscriptionRequested(this.societyId);

  @override
  List<Object?> get props => [societyId];
}

/// Internal event fired when blocks stream updates
class SocietyBlocksUpdated extends SocietySetupEvent {
  final List<String> blocks;

  const SocietyBlocksUpdated(this.blocks);

  @override
  List<Object?> get props => [blocks];
}

/// Internal event fired when directory users stream updates
class SocietyUsersUpdated extends SocietySetupEvent {
  final List<UserModel> users;

  const SocietyUsersUpdated(this.users);

  @override
  List<Object?> get props => [users];
}

/// Internal event fired when setup streams fail
class SocietySetupErrorOccurred extends SocietySetupEvent {
  final String error;

  const SocietySetupErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Filter directory by role ('all', 'member', 'watchman', 'admin')
class SocietySetupRoleFilterChanged extends SocietySetupEvent {
  final String role;

  const SocietySetupRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

/// Filter directory by block/wing name
class SocietySetupBlockFilterChanged extends SocietySetupEvent {
  final String block;

  const SocietySetupBlockFilterChanged(this.block);

  @override
  List<Object?> get props => [block];
}

/// Search directory users by name, phone, or unit
class SocietySetupSearchQueryChanged extends SocietySetupEvent {
  final String query;

  const SocietySetupSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Add a new block / wing
class SocietyAddBlockRequested extends SocietySetupEvent {
  final String blockName;

  const SocietyAddBlockRequested(this.blockName);

  @override
  List<Object?> get props => [blockName];
}

/// Add a new user (Member or Watchman) to directory
class SocietyAddUserRequested extends SocietySetupEvent {
  final String name;
  final String phone;
  final String role;
  final String blockName;
  final String unitNumber;

  const SocietyAddUserRequested({
    required this.name,
    required this.phone,
    required this.role,
    this.blockName = '',
    this.unitNumber = '',
  });

  @override
  List<Object?> get props => [name, phone, role, blockName, unitNumber];
}

/// Delete or deactivate a user
class SocietyDeleteUserRequested extends SocietySetupEvent {
  final String userId;

  const SocietyDeleteUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
