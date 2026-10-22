import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/poll_model.dart';
import 'firebase_app_guard.dart';
import 'society_service.dart';

class SocietyPollService {
  SocietyPollService._();
  static final SocietyPollService instance = SocietyPollService._();

  FirebaseFirestore get _firestore => AppFirestore.instance;
  String get _currentSocietyId => SocietyService.instance.societyId;
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _pollsRef =>
      _firestore.collection('societies').doc(_currentSocietyId).collection('polls');

  /// ૧. નવો પોલ / નિર્ણય મતદાન બનાવવું
  Future<String> createPoll({
    required String title,
    required String description,
    required List<String> optionTexts,
    required DateTime endDate,
    DateTime? startDate,
    String targetScope = 'all', // 'all' અથવા ચોક્કસ બ્લોક/વિંગ
    String voterEligibility = 'all_members', // 'all_members', 'owners_only'
    bool isAnonymous = false,
    String createdByName = '',
  }) async {
    final societyId = _currentSocietyId;
    if (societyId.isEmpty) throw Exception('સોસાયટી ID ઉપલબ્ધ નથી.');

    final effectiveStartDate = startDate ?? DateTime.now();

    final options = <Map<String, dynamic>>[];
    for (int i = 0; i < optionTexts.length; i++) {
      final t = optionTexts[i].trim();
      if (t.isNotEmpty) {
        options.add({
          'id': 'opt_${i + 1}',
          'text': t,
          'votesCount': 0,
        });
      }
    }

    if (options.length < 2) {
      throw Exception('ઓછામાં ઓછા ૨ વિકલ્પો હોવા જરૂરી છે.');
    }

    final docRef = await _pollsRef.add({
      'societyId': societyId,
      'title': title.trim(),
      'description': description.trim(),
      'options': options,
      'targetScope': targetScope,
      'voterEligibility': voterEligibility,
      'isAnonymous': isAnonymous,
      'statusActive': true,
      'startDate': Timestamp.fromDate(effectiveStartDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdByUid': _currentUserId ?? '',
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'totalVotes': 0,
      'votedMemberUids': [],
      'votedFlats': [],
    });

    // Send notification / push to members
    _notifyMembersNewPoll(
      pollId: docRef.id,
      title: title.trim(),
      targetScope: targetScope,
    );

    return docRef.id;
  }

  /// સભ્યોને નવા પોલ માટે સૂચના મોકલવી
  Future<void> _notifyMembersNewPoll({
    required String pollId,
    required String title,
    required String targetScope,
  }) async {
    try {
      final societyId = _currentSocietyId;
      final topicKind = targetScope == 'all' ? 'members' : 'members_$targetScope';

      // 1. In-App Notification
      await _firestore.collection('notifications').add({
        'title': '🗳️ સોસાયટી નિર્ણય મતદાન',
        'body': 'નવા નિર્ણય માટે તમારો કિંમતી મત આપો: "$title"',
        'societyId': societyId,
        'type': 'new_poll',
        'pollId': pollId,
        'targetScope': targetScope,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Cloud Functions Push
      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: 'us-central1',
      );
      final callable = functions.httpsCallable(
        'sendTopicAlertPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      await callable.call<Map<String, dynamic>>({
        'topicKind': topicKind,
        'title': '🗳️ સોસાયટી નિર્ણય મતદાન',
        'body': 'નવા નિર્ણય માટે તમારો કિંમતી મત આપો: "$title"',
        'type': 'new_poll',
      });
    } catch (e) {
      debugPrint('Error notifying members for new poll: $e');
    }
  }

  /// ૨. મત નોંધાવવો (Firestore Transaction વડે સંપૂર્ણ સુરક્ષિત - ૧ ફ્લેટ/સભ્ય = ૧ મત)
  Future<void> castVote({
    required String pollId,
    required String optionId,
    required String flatDisplay,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('કૃપા કરીને પહેલા લોગિન કરો.');

    final pollDocRef = _pollsRef.doc(pollId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(pollDocRef);
      if (!snap.exists) throw Exception('મતદાન/પોલ અસ્તિત્વમાં નથી.');

      final data = snap.data() as Map<String, dynamic>;
      final statusActive = data['statusActive'] == true;

      DateTime endDate = DateTime.now();
      final rawEnd = data['endDate'];
      if (rawEnd is Timestamp) endDate = rawEnd.toDate();

      if (!statusActive || DateTime.now().isAfter(endDate)) {
        throw Exception('આ મતદાનની મુદત સમાપ્ત થઈ ગઈ છે.');
      }

      final List votedUids = (data['votedMemberUids'] as List?) ?? [];
      final List votedFlats = (data['votedFlats'] as List?) ?? [];

      if (votedUids.contains(uid)) {
        throw Exception('આપ દ્વારા પહેલેથી જ મત આપવામાં આવેલ છે.');
      }

      if (flatDisplay.isNotEmpty && votedFlats.contains(flatDisplay)) {
        throw Exception('આપના ફ્લેટ ($flatDisplay) તરફથી પહેલેથી જ મત નોંધાઈ ચૂક્યો છે.');
      }

      final rawOptions = data['options'] as List? ?? [];
      final updatedOptions = <Map<String, dynamic>>[];
      bool foundOption = false;

      for (final o in rawOptions) {
        if (o is Map) {
          final oMap = Map<String, dynamic>.from(o);
          if (oMap['id'] == optionId) {
            oMap['votesCount'] = ((oMap['votesCount'] as num?)?.toInt() ?? 0) + 1;
            foundOption = true;
          }
          updatedOptions.add(oMap);
        }
      }

      if (!foundOption) {
        throw Exception('અમાન્ય વિકલ્પ પસંદ કર્યો છે.');
      }

      final currentTotal = (data['totalVotes'] as num?)?.toInt() ?? 0;

      transaction.update(pollDocRef, {
        'options': updatedOptions,
        'totalVotes': currentTotal + 1,
        'votedMemberUids': FieldValue.arrayUnion([uid]),
        if (flatDisplay.isNotEmpty) 'votedFlats': FieldValue.arrayUnion([flatDisplay]),
      });

      // Save individual vote record in sub-collection
      final voteRecordRef = pollDocRef.collection('votes').doc(uid);
      transaction.set(voteRecordRef, {
        'uid': uid,
        'flatDisplay': flatDisplay,
        'optionId': optionId,
        'isAnonymous': data['isAnonymous'] == true,
        'votedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// ૩. વપરાશકર્તાએ કયા વિકલ્પ પર મત આપ્યો તે જાણવું
  Future<String?> getUserVotedOptionId(String pollId) async {
    final uid = _currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _pollsRef.doc(pollId).collection('votes').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['optionId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// ૪. પોલ બંધ કરવો / આખરી ઠરાવ નોંધવો
  Future<void> closePoll({
    required String pollId,
    String? resolutionSummary,
  }) async {
    await _pollsRef.doc(pollId).update({
      'statusActive': false,
      if (resolutionSummary != null && resolutionSummary.trim().isNotEmpty)
        'resolutionSummary': resolutionSummary.trim(),
    });
  }

  /// ૫. પોલ ડીલીટ કરવો
  Future<void> deletePoll(String pollId) async {
    await _pollsRef.doc(pollId).delete();
  }

  /// ૬. સોસાયટીના તમામ પોલ્સનો લાઈવ સ્ટ્રીમ
  Stream<List<PollModel>> getPollsStream({String? blockScope}) {
    return _pollsRef.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final list = snap.docs.map((doc) => PollModel.fromFirestore(doc)).toList();
      if (blockScope != null && blockScope.isNotEmpty && blockScope != 'all') {
        return list.where((p) => p.targetScope == 'all' || p.targetScope == blockScope).toList();
      }
      return list;
    });
  }

  /// ૭. જો અનામી (anonymous) ન હોય તો કોણે શું મત આપ્યો તેનું લિસ્ટ
  Stream<QuerySnapshot> getPollVotersStream(String pollId) {
    return _pollsRef.doc(pollId).collection('votes').orderBy('votedAt', descending: true).snapshots();
  }
}
