import 'package:flutter_test/flutter_test.dart';
import 'package:building_guard/models/patrol_model.dart';
import 'package:building_guard/blocs/patrol/guard_patrol_bloc.dart';

void main() {
  group('GuardPatrolBloc State and Calculation Tests', () {
    final now = DateTime.now();

    final cp1 = PatrolCheckpoint(
      id: 'cp1',
      societyId: 'soc123',
      code: 'CP01',
      name: 'Main Gate',
      location: 'Ground Floor',
      qrPayload: 'MBG_PATROL|soc123|CP01',
      order: 1,
      isActive: true,
      createdAt: now,
    );

    final cp2 = PatrolCheckpoint(
      id: 'cp2',
      societyId: 'soc123',
      code: 'CP02',
      name: 'Terrace A',
      location: 'Top Floor',
      qrPayload: 'MBG_PATROL|soc123|CP02',
      order: 2,
      isActive: true,
      createdAt: now,
    );

    final cp3 = PatrolCheckpoint(
      id: 'cp3',
      societyId: 'soc123',
      code: 'CP03',
      name: 'Old Shed',
      location: 'Backyard',
      qrPayload: 'MBG_PATROL|soc123|CP03',
      order: 3,
      isActive: false, // inactive checkpoint
      createdAt: now,
    );

    test('GuardPatrolLoaded correctly counts active checkpoints and progress', () {
      final session = PatrolShiftSession(
        id: 's1',
        societyId: 'soc123',
        guardUid: 'g1',
        guardName: 'Ramu Watchman',
        guardPhone: '9876543210',
        shiftDate: '2026-10-24',
        roundNumber: 1,
        roundLabel: 'Morning Round',
        startTime: now,
        status: 'in_progress',
        totalCheckpoints: 2,
        scannedCount: 1,
        scanLogs: [
          CheckpointScanLog(
            checkpointId: 'cp1',
            checkpointCode: 'CP01',
            checkpointName: 'Main Gate',
            scannedAt: now,
            scannedByGuardUid: 'g1',
            scannedByGuardName: 'Ramu',
          ),
        ],
      );

      final state = GuardPatrolLoaded(
        checkpoints: [cp1, cp2, cp3],
        activeSession: session,
      );

      expect(state.totalCheckpointsCount, 2); // cp3 is inactive
      expect(state.scannedCheckpointsCount, 1);
      expect(state.isRoundInProgress, true);
      expect(state.progressRatio, 0.5);
      expect(state.progressPercentage, 50.0);
      expect(state.isRoundFullyCompleted, false);
    });

    test('GuardPatrolLoaded marks round as completed when all are scanned', () {
      final completedSession = PatrolShiftSession(
        id: 's2',
        societyId: 'soc123',
        guardUid: 'g1',
        guardName: 'Ramu Watchman',
        guardPhone: '9876543210',
        shiftDate: '2026-10-24',
        roundNumber: 2,
        roundLabel: 'Evening Round',
        startTime: now,
        status: 'completed',
        totalCheckpoints: 2,
        scannedCount: 2,
        scanLogs: const [],
      );

      final state = GuardPatrolLoaded(
        checkpoints: [cp1, cp2],
        activeSession: completedSession,
      );

      expect(state.progressPercentage, 100.0);
      expect(state.isRoundFullyCompleted, true);
    });

    test('GuardPatrolLoaded copyWith handles clearing active session', () {
      final session = PatrolShiftSession(
        id: 's1',
        societyId: 'soc123',
        guardUid: 'g1',
        guardName: 'Ramu',
        guardPhone: '',
        shiftDate: '2026-10-24',
        roundNumber: 1,
        roundLabel: 'Round 1',
        startTime: now,
        status: 'in_progress',
        totalCheckpoints: 2,
        scannedCount: 1,
        scanLogs: const [],
      );

      final stateWithSession = GuardPatrolLoaded(
        checkpoints: [cp1, cp2],
        activeSession: session,
      );
      expect(stateWithSession.isRoundInProgress, true);

      final clearedState = stateWithSession.copyWith(clearActiveSession: true);
      expect(clearedState.isRoundInProgress, false);
      expect(clearedState.activeSession, null);
      expect(clearedState.checkpoints.length, 2);
    });
  });
}
