import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class SocietySetupState extends Equatable {
  const SocietySetupState();

  @override
  List<Object?> get props => [];
}

class SocietySetupInitial extends SocietySetupState {}

class SocietySetupLoading extends SocietySetupState {}

class SocietySetupLoaded extends SocietySetupState {
  final List<String> blocks;
  final List<UserModel> users;
  final String roleFilter; // 'all', 'member', 'watchman', 'admin'
  final String blockFilter; // 'all' or specific block name
  final String searchQuery;
  final bool isActionInProgress;
  final String? feedbackMessage;

  const SocietySetupLoaded({
    this.blocks = const [],
    this.users = const [],
    this.roleFilter = 'all',
    this.blockFilter = 'all',
    this.searchQuery = '',
    this.isActionInProgress = false,
    this.feedbackMessage,
  });

  /// Filtered directory users based on role, block, and search query
  List<UserModel> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();

    return users.where((u) {
      // 1. Role Filter
      if (roleFilter != 'all') {
        if (u.role.toLowerCase() != roleFilter.toLowerCase()) return false;
      }

      // 2. Block Filter
      if (blockFilter != 'all') {
        final bName = (u.blockName ?? '').toLowerCase();
        if (bName != blockFilter.toLowerCase()) return false;
      }

      // 3. Search Query Filter (name, phone, unit)
      if (query.isNotEmpty) {
        final matchesName = u.name.toLowerCase().contains(query);
        final matchesPhone = (u.phone ?? '').contains(query);
        final matchesUnit = (u.unitNumber ?? '').toLowerCase().contains(query);
        final matchesBlock = (u.blockName ?? '').toLowerCase().contains(query);

        if (!matchesName && !matchesPhone && !matchesUnit && !matchesBlock) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total registered users
  int get totalUsersCount => users.length;

  /// Members count
  int get membersCount => users.where((u) => u.role.toLowerCase() == 'member').length;

  /// Watchmen count
  int get watchmenCount => users.where((u) => u.role.toLowerCase() == 'watchman').length;

  /// Admins count
  int get adminsCount => users.where((u) => u.role.toLowerCase() == 'admin').length;

  SocietySetupLoaded copyWith({
    List<String>? blocks,
    List<UserModel>? users,
    String? roleFilter,
    String? blockFilter,
    String? searchQuery,
    bool? isActionInProgress,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return SocietySetupLoaded(
      blocks: blocks ?? this.blocks,
      users: users ?? this.users,
      roleFilter: roleFilter ?? this.roleFilter,
      blockFilter: blockFilter ?? this.blockFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        blocks,
        users,
        roleFilter,
        blockFilter,
        searchQuery,
        isActionInProgress,
        feedbackMessage,
      ];
}

class SocietySetupFailure extends SocietySetupState {
  final String errorMessage;

  const SocietySetupFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
