import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:building_guard/core/app_firestore.dart';
import '../models/patrol_model.dart';
import 'package:intl/intl.dart';

class GuardPatrolService {
  static final GuardPatrolService _instance = GuardPatrolService._internal();
  factory GuardPatrolService() => _instance;
  GuardPatrolService._internal();

  CollectionReference _checkpointsRef(String societyId) {
    return AppFirestore.instance
        .collection('societies')
        .doc(societyId)
        .collection('patrol_checkpoints');
  }

  CollectionReference _sessionsRef(String societyId) {
    return AppFirestore.instance
        .collection('societies')
        .doc(societyId)
        .collection('patrol_sessions');
  }

  /// Generate QR code string format
  static String generateQrPayload(String societyId, String code) {
    return 'MBG_PATROL|$societyId|$code';
  }

  // ================= CHECKPOINTS MANAGEMENT =================

  /// Stream all active checkpoints ordered by sequence
  Stream<List<PatrolCheckpoint>> streamCheckpoints(String societyId) {
    if (societyId.isEmpty) return Stream.value([]);
    return _checkpointsRef(societyId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return PatrolCheckpoint.fromMap(
                doc.data() as Map<String, dynamic>,
                docId: doc.id,
              );
            }).toList());
  }

  /// Fetch checkpoints as a list
  Future<List<PatrolCheckpoint>> getCheckpoints(String societyId) async {
    if (societyId.isEmpty) return [];
    final snap = await _checkpointsRef(societyId).orderBy('order').get();
    return snap.docs
        .map((doc) => PatrolCheckpoint.fromMap(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ))
        .toList();
  }

  /// Add a new security checkpoint
  Future<String> addCheckpoint({
    required String societyId,
    required String code,
    required String name,
    required String location,
    int order = 1,
    String? notes,
  }) async {
    final docRef = _checkpointsRef(societyId).doc();
    final qr = generateQrPayload(societyId, code);

    final cp = PatrolCheckpoint(
      id: docRef.id,
      societyId: societyId,
      code: code,
      name: name,
      location: location,
      qrPayload: qr,
      order: order,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await docRef.set(cp.toMap());
    return docRef.id;
  }

  /// Update checkpoint
  Future<void> updateCheckpoint(PatrolCheckpoint cp) async {
    await _checkpointsRef(cp.societyId).doc(cp.id).update(cp.toMap());
  }

  /// Delete checkpoint
  Future<void> deleteCheckpoint(String societyId, String checkpointId) async {
    await _checkpointsRef(societyId).doc(checkpointId).delete();
  }

  /// Pre-seed default checkpoints if admin opens screen and no checkpoints exist
  Future<void> seedDefaultCheckpointsIfEmpty(String societyId) async {
    if (societyId.isEmpty) return;
    final snap = await _checkpointsRef(societyId).limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final defaults = [
      {
        'code': 'CP01',
        'name': 'મુખ્ય પ્રવેશ દ્વાર (Main Entrance Gate)',
        'location': 'ગ્રાઉન્ડ ફ્લોર - સિક્યોરિટી કેબિન સામે',
        'order': 1,
      },
      {
        'code': 'CP02',
        'name': 'વિંગ A & B ટેરેસ પ્રવેશ દ્વાર (Terrace Door)',
        'location': 'ટોપ ફ્લોર - ટેરેસ સીડી પાસે',
        'order': 2,
      },
      {
        'code': 'CP03',
        'name': 'બેઝમેન્ટ પાર્કિંગ B1 (Basement Parking)',
        'location': 'બેઝમેન્ટ - પિલર નં. ૦૫ પાસે',
        'order': 3,
      },
      {
        'code': 'CP04',
        'name': 'જનરેટર અને પાવર પેનલ રૂમ (Electric Room)',
        'location': 'ગ્રાઉન્ડ લેવલ - યુટિલિટી બ્લોક',
        'order': 4,
      },
      {
        'code': 'CP05',
        'name': 'ગાર્ડન અને પાછળનો પેરીમીટર (Garden & Perimeter)',
        'location': 'પાછળની બાઉન્ડ્રી વોલ - કોર્નર ૨',
        'order': 5,
      },
    ];

    final batch = AppFirestore.instance.batch();
    for (final d in defaults) {
      final docRef = _checkpointsRef(societyId).doc();
      final qr = generateQrPayload(societyId, d['code'] as String);
      final cp = PatrolCheckpoint(
        id: docRef.id,
        societyId: societyId,
        code: d['code'] as String,
        name: d['name'] as String,
        location: d['location'] as String,
        qrPayload: qr,
        order: d['order'] as int,
        createdAt: DateTime.now(),
      );
      batch.set(docRef, cp.toMap());
    }
    await batch.commit();
  }

  // ================= PATROL ROUND SESSIONS =================

  /// Stream current active patrol session for a guard
  Stream<PatrolShiftSession?> streamActiveSession(String societyId, String guardUid) {
    if (societyId.isEmpty || guardUid.isEmpty) return Stream.value(null);

    return _sessionsRef(societyId)
        .where('guardUid', isEqualTo: guardUid)
        .where('status', isEqualTo: 'in_progress')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return PatrolShiftSession.fromMap(
        snap.docs.first.data() as Map<String, dynamic>,
        docId: snap.docs.first.id,
      );
    });
  }

  /// Start a new patrol session
  Future<PatrolShiftSession> startPatrolRound({
    required String societyId,
    required String guardUid,
    required String guardName,
    required String guardPhone,
    required int roundNumber,
    required String roundLabel,
    required int totalCheckpoints,
  }) async {
    final docRef = _sessionsRef(societyId).doc();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final session = PatrolShiftSession(
      id: docRef.id,
      societyId: societyId,
      guardUid: guardUid,
      guardName: guardName,
      guardPhone: guardPhone,
      shiftDate: today,
      roundNumber: roundNumber,
      roundLabel: roundLabel,
      startTime: DateTime.now(),
      status: 'in_progress',
      totalCheckpoints: totalCheckpoints,
      scannedCount: 0,
      scanLogs: const [],
      hasIncident: false,
    );

    await docRef.set(session.toMap());
    return session;
  }

  /// Process QR scan during an ongoing session
  Future<Map<String, dynamic>> scanCheckpoint({
    required String societyId,
    required String sessionId,
    required String qrPayload,
    String? incidentNote,
    required String guardUid,
    required String guardName,
  }) async {
    // 1. Validate payload format
    // Format: MBG_PATROL|<societyId>|<code>
    final parts = qrPayload.trim().split('|');
    if (parts.length < 3 || parts[0] != 'MBG_PATROL') {
      return {
        'success': false,
        'message': 'આ QR કોડ પેટ્રોલિંગ ચેકપોઇન્ટનો નથી!',
      };
    }

    final targetSocietyId = parts[1];
    final checkpointCode = parts[2];

    if (targetSocietyId != societyId) {
      return {
        'success': false,
        'message': 'આ QR કોડ અન્ય સોસાયટીનો છે!',
      };
    }

    // 2. Fetch Checkpoint Details
    final cpSnap = await _checkpointsRef(societyId)
        .where('code', isEqualTo: checkpointCode)
        .limit(1)
        .get();

    if (cpSnap.docs.isEmpty) {
      return {
        'success': false,
        'message': 'ચેકપોઇન્ટ [$checkpointCode] મળ્યો નથી!',
      };
    }

    final cp = PatrolCheckpoint.fromMap(
      cpSnap.docs.first.data() as Map<String, dynamic>,
      docId: cpSnap.docs.first.id,
    );

    // 3. Update Session Document
    final sessionRef = _sessionsRef(societyId).doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      return {
        'success': false,
        'message': 'પેટ્રોલિંગ સેશન મળી શક્યું નથી!',
      };
    }

    final session = PatrolShiftSession.fromMap(
      sessionSnap.data() as Map<String, dynamic>,
      docId: sessionSnap.id,
    );

    // Check if already scanned in this session
    final alreadyScanned = session.scanLogs.any((l) => l.checkpointCode == cp.code);
    if (alreadyScanned) {
      return {
        'success': false,
        'message': 'આ ચેકપોઇન્ટ (${cp.name}) આ રાઉન્ડમાં પહેલેથી જ સ્કેન થઈ ચૂક્યો છે!',
        'checkpoint': cp,
      };
    }

    final hasIncident = incidentNote != null && incidentNote.trim().isNotEmpty;
    final newLog = CheckpointScanLog(
      checkpointId: cp.id,
      checkpointCode: cp.code,
      checkpointName: cp.name,
      scannedAt: DateTime.now(),
      isIncidentReported: hasIncident,
      incidentNote: hasIncident ? incidentNote.trim() : null,
      scannedByGuardUid: guardUid,
      scannedByGuardName: guardName,
    );

    final updatedLogs = List<CheckpointScanLog>.from(session.scanLogs)..add(newLog);
    final newScannedCount = updatedLogs.length;
    final isAllDone = newScannedCount >= session.totalCheckpoints;

    await sessionRef.update({
      'scanLogs': updatedLogs.map((e) => e.toMap()).toList(),
      'scannedCount': newScannedCount,
      'hasIncident': session.hasIncident || hasIncident,
      if (isAllDone) 'status': 'completed',
      if (isAllDone) 'endTime': Timestamp.fromDate(DateTime.now()),
    });

    return {
      'success': true,
      'checkpoint': cp,
      'isCompleted': isAllDone,
      'remaining': (session.totalCheckpoints - newScannedCount).clamp(0, 99),
      'message': '${cp.name} સફળતાપૂર્વક સ્કેન થયું! ✅',
    };
  }

  /// Manually complete or end an in-progress round
  Future<void> completePatrolRound({
    required String societyId,
    required String sessionId,
  }) async {
    await _sessionsRef(societyId).doc(sessionId).update({
      'status': 'completed',
      'endTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Stream sessions for audit logs
  Stream<List<PatrolShiftSession>> streamSessions(String societyId, {String? dateFilter}) {
    if (societyId.isEmpty) return Stream.value([]);
    Query q = _sessionsRef(societyId).orderBy('startTime', descending: true);
    if (dateFilter != null && dateFilter.isNotEmpty) {
      q = q.where('shiftDate', isEqualTo: dateFilter);
    }
    return q.limit(40).snapshots().map((snap) => snap.docs.map((doc) {
          return PatrolShiftSession.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          );
        }).toList());
  }

  /// Security Audit Compliance calculation for Member & Admin dashboards
  Future<Map<String, dynamic>> getPatrolComplianceStats(String societyId) async {
    if (societyId.isEmpty) {
      return {
        'completedRounds': 0,
        'targetRounds': 4,
        'compliancePercent': 0,
        'totalIncidents': 0,
        'statusMessage': 'સુરક્ષા પેટ્રોલિંગ સેટ કરેલ નથી',
      };
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    // Fetch sessions from yesterday & today
    final snap = await _sessionsRef(societyId)
        .where('shiftDate', whereIn: [today, yesterday])
        .orderBy('startTime', descending: true)
        .get();

    final sessions = snap.docs
        .map((d) => PatrolShiftSession.fromMap(
              d.data() as Map<String, dynamic>,
              docId: d.id,
            ))
        .toList();

    final completedRounds = sessions.where((s) => s.isCompleted).length;
    final totalIncidents = sessions.where((s) => s.hasIncident).length;
    const targetRounds = 4; // Standard night target (11 PM, 1 AM, 3 AM, 5 AM)
    final ratio = (completedRounds / targetRounds).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    String msg;
    if (completedRounds >= targetRounds) {
      msg = 'ગઈકાલે રાત્રે સુરક્ષા પેટ્રોલિંગ: $completedRounds રાઉન્ડ ૧૦૦% પૂર્ણ ✅';
    } else if (completedRounds > 0) {
      msg = 'રાત્રિ પેટ્રોલિંગ: $completedRounds/$targetRounds રાઉન્ડ પૂર્ણ ($percent%)';
    } else {
      msg = 'આજનું રાત્રિ પેટ્રોલિંગ ૧૧:૦૦ PM થી શરૂ થશે 🛡️';
    }

    return {
      'completedRounds': completedRounds,
      'targetRounds': targetRounds,
      'compliancePercent': percent,
      'totalIncidents': totalIncidents,
      'statusMessage': msg,
      'lastPatrol': sessions.isNotEmpty ? sessions.first : null,
    };
  }
}
