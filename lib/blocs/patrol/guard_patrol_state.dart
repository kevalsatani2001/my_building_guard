import 'package:equatable/equatable.dart';
import '../../models/patrol_model.dart';

abstract class GuardPatrolState extends Equatable {
  const GuardPatrolState();

  @override
  List<Object?> get props => [];
}

class GuardPatrolInitial extends GuardPatrolState {}

class GuardPatrolLoading extends GuardPatrolState {}

class GuardPatrolLoaded extends GuardPatrolState {
  final List<PatrolCheckpoint> checkpoints;
  final PatrolShiftSession? activeSession;
  final List<PatrolShiftSession> pastSessions;
  final bool isActionInProgress;
  final String? actionFeedbackMessage;

  const GuardPatrolLoaded({
    this.checkpoints = const [],
    this.activeSession,
    this.pastSessions = const [],
    this.isActionInProgress = false,
    this.actionFeedbackMessage,
  });

  /// Whether a patrol shift is currently being conducted
  bool get isRoundInProgress => activeSession != null;

  /// Number of checkpoints scanned in active round
  int get scannedCheckpointsCount => activeSession?.scannedCount ?? 0;

  /// Total number of active security checkpoints configured for this society
  int get totalCheckpointsCount => checkpoints.where((c) => c.isActive).length;

  /// Patrol completion ratio (0.0 to 1.0)
  double get progressRatio {
    if (totalCheckpointsCount == 0) return 0.0;
    return (scannedCheckpointsCount / totalCheckpointsCount).clamp(0.0, 1.0);
  }

  /// Patrol completion percentage (0.0 to 100.0)
  double get progressPercentage => progressRatio * 100.0;

  /// Whether all checkpoints for the active round have been scanned
  bool get isRoundFullyCompleted =>
      totalCheckpointsCount > 0 && scannedCheckpointsCount >= totalCheckpointsCount;

  GuardPatrolLoaded copyWith({
    List<PatrolCheckpoint>? checkpoints,
    PatrolShiftSession? activeSession,
    bool clearActiveSession = false,
    List<PatrolShiftSession>? pastSessions,
    bool? isActionInProgress,
    String? actionFeedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return GuardPatrolLoaded(
      checkpoints: checkpoints ?? this.checkpoints,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      pastSessions: pastSessions ?? this.pastSessions,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      actionFeedbackMessage: clearFeedbackMessage
          ? null
          : (actionFeedbackMessage ?? this.actionFeedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        checkpoints,
        activeSession,
        pastSessions,
        isActionInProgress,
        actionFeedbackMessage,
      ];
}

class GuardPatrolFailure extends GuardPatrolState {
  final String errorMessage;

  const GuardPatrolFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
