import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a physical security checkpoint in the society
class PatrolCheckpoint {
  final String id;
  final String societyId;
  final String code;
  final String name;
  final String location;
  final String qrPayload;
  final int order;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const PatrolCheckpoint({
    required this.id,
    required this.societyId,
    required this.code,
    required this.name,
    required this.location,
    required this.qrPayload,
    this.order = 1,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'societyId': societyId,
      'code': code,
      'name': name,
      'location': location,
      'qrPayload': qrPayload,
      'order': order,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PatrolCheckpoint.fromMap(Map<String, dynamic> map, {String? docId}) {
    return PatrolCheckpoint(
      id: docId ?? map['id'] ?? '',
      societyId: map['societyId'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      qrPayload: map['qrPayload'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 1,
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Represents a single checkpoint scan event in a patrol round
class CheckpointScanLog {
  final String checkpointId;
  final String checkpointCode;
  final String checkpointName;
  final DateTime scannedAt;
  final bool isIncidentReported;
  final String? incidentNote;
  final String scannedByGuardUid;
  final String scannedByGuardName;

  const CheckpointScanLog({
    required this.checkpointId,
    required this.checkpointCode,
    required this.checkpointName,
    required this.scannedAt,
    this.isIncidentReported = false,
    this.incidentNote,
    required this.scannedByGuardUid,
    required this.scannedByGuardName,
  });

  Map<String, dynamic> toMap() {
    return {
      'checkpointId': checkpointId,
      'checkpointCode': checkpointCode,
      'checkpointName': checkpointName,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'isIncidentReported': isIncidentReported,
      'incidentNote': incidentNote,
      'scannedByGuardUid': scannedByGuardUid,
      'scannedByGuardName': scannedByGuardName,
    };
  }

  factory CheckpointScanLog.fromMap(Map<String, dynamic> map) {
    return CheckpointScanLog(
      checkpointId: map['checkpointId'] ?? '',
      checkpointCode: map['checkpointCode'] ?? '',
      checkpointName: map['checkpointName'] ?? '',
      scannedAt: map['scannedAt'] is Timestamp
          ? (map['scannedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isIncidentReported: map['isIncidentReported'] ?? false,
      incidentNote: map['incidentNote'],
      scannedByGuardUid: map['scannedByGuardUid'] ?? '',
      scannedByGuardName: map['scannedByGuardName'] ?? '',
    );
  }
}

/// Represents an entire patrol round executed by a night guard
class PatrolShiftSession {
  final String id;
  final String societyId;
  final String guardUid;
  final String guardName;
  final String guardPhone;
  final String shiftDate; // e.g. '2026-10-22'
  final int roundNumber; // 1, 2, 3, 4
  final String roundLabel; // e.g. 'રાઉન્ડ ૧ (૧૧:૦૦ PM - ૧૨:૩૦ AM)'
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'in_progress', 'completed', 'missed'
  final int totalCheckpoints;
  final int scannedCount;
  final List<CheckpointScanLog> scanLogs;
  final bool hasIncident;

  const PatrolShiftSession({
    required this.id,
    required this.societyId,
    required this.guardUid,
    required this.guardName,
    required this.guardPhone,
    required this.shiftDate,
    required this.roundNumber,
    required this.roundLabel,
    required this.startTime,
    this.endTime,
    this.status = 'in_progress',
    required this.totalCheckpoints,
    this.scannedCount = 0,
    this.scanLogs = const [],
    this.hasIncident = false,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  double get progressRatio =>
      totalCheckpoints > 0 ? (scannedCount / totalCheckpoints).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progressRatio * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'societyId': societyId,
      'guardUid': guardUid,
      'guardName': guardName,
      'guardPhone': guardPhone,
      'shiftDate': shiftDate,
      'roundNumber': roundNumber,
      'roundLabel': roundLabel,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'totalCheckpoints': totalCheckpoints,
      'scannedCount': scannedCount,
      'scanLogs': scanLogs.map((e) => e.toMap()).toList(),
      'hasIncident': hasIncident,
    };
  }

  factory PatrolShiftSession.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawLogs = map['scanLogs'] as List<dynamic>? ?? [];
    final logs = rawLogs
        .map((e) => CheckpointScanLog.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PatrolShiftSession(
      id: docId ?? map['id'] ?? '',
      societyId: map['societyId'] ?? '',
      guardUid: map['guardUid'] ?? '',
      guardName: map['guardName'] ?? '',
      guardPhone: map['guardPhone'] ?? '',
      shiftDate: map['shiftDate'] ?? '',
      roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      roundLabel: map['roundLabel'] ?? '',
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      status: map['status'] ?? 'in_progress',
      totalCheckpoints: (map['totalCheckpoints'] as num?)?.toInt() ?? 0,
      scannedCount: (map['scannedCount'] as num?)?.toInt() ?? logs.length,
      scanLogs: logs,
      hasIncident: map['hasIncident'] ?? false,
    );
  }
}
