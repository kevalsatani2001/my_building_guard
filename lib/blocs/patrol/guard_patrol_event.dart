import 'package:equatable/equatable.dart';
import '../../models/patrol_model.dart';

abstract class GuardPatrolEvent extends Equatable {
  const GuardPatrolEvent();

  @override
  List<Object?> get props => [];
}

/// Start subscription to checkpoints and optionally the guard's active patrol session
class PatrolSubscriptionRequested extends GuardPatrolEvent {
  final String societyId;
  final String? guardUid;

  const PatrolSubscriptionRequested({
    required this.societyId,
    this.guardUid,
  });

  @override
  List<Object?> get props => [societyId, guardUid];
}

/// Internal event fired when checkpoints stream updates
class PatrolCheckpointsUpdated extends GuardPatrolEvent {
  final List<PatrolCheckpoint> checkpoints;

  const PatrolCheckpointsUpdated(this.checkpoints);

  @override
  List<Object?> get props => [checkpoints];
}

/// Internal event fired when patrol stream fails
class PatrolErrorOccurred extends GuardPatrolEvent {
  final String error;

  const PatrolErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Internal event fired when guard's active session stream updates
class PatrolActiveSessionUpdated extends GuardPatrolEvent {
  final PatrolShiftSession? activeSession;

  const PatrolActiveSessionUpdated(this.activeSession);

  @override
  List<Object?> get props => [activeSession];
}

/// Internal event fired when past patrol sessions update
class PatrolSessionsHistoryUpdated extends GuardPatrolEvent {
  final List<PatrolShiftSession> sessions;

  const PatrolSessionsHistoryUpdated(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// Add a new security checkpoint
class PatrolAddCheckpointRequested extends GuardPatrolEvent {
  final String code;
  final String name;
  final String location;
  final int order;
  final String? notes;

  const PatrolAddCheckpointRequested({
    required this.code,
    required this.name,
    required this.location,
    this.order = 1,
    this.notes,
  });

  @override
  List<Object?> get props => [code, name, location, order, notes];
}

/// Delete a security checkpoint
class PatrolDeleteCheckpointRequested extends GuardPatrolEvent {
  final String checkpointId;

  const PatrolDeleteCheckpointRequested(this.checkpointId);

  @override
  List<Object?> get props => [checkpointId];
}

/// Guard starts a new patrol round
class PatrolStartRoundRequested extends GuardPatrolEvent {
  final String guardUid;
  final String guardName;
  final String guardPhone;
  final int roundNumber;
  final String roundLabel;

  const PatrolStartRoundRequested({
    required this.guardUid,
    required this.guardName,
    required this.guardPhone,
    required this.roundNumber,
    required this.roundLabel,
  });

  @override
  List<Object?> get props => [guardUid, guardName, guardPhone, roundNumber, roundLabel];
}

/// Guard scans a checkpoint QR code
class PatrolScanQrRequested extends GuardPatrolEvent {
  final String qrPayload;
  final String guardUid;
  final String guardName;
  final bool isIncident;
  final String? incidentNote;

  const PatrolScanQrRequested({
    required this.qrPayload,
    required this.guardUid,
    required this.guardName,
    this.isIncident = false,
    this.incidentNote,
  });

  @override
  List<Object?> get props => [qrPayload, guardUid, guardName, isIncident, incidentNote];
}

/// Guard finishes the active patrol round
class PatrolFinishRoundRequested extends GuardPatrolEvent {
  final String sessionId;
  final String? notes;

  const PatrolFinishRoundRequested({
    required this.sessionId,
    this.notes,
  });

  @override
  List<Object?> get props => [sessionId, notes];
}
