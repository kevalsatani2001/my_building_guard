import 'package:cloud_firestore/cloud_firestore.dart';

/// એક Firebase પ્રોજેક્ટમાં ઘણી સોસાયટી — દરે ડૉક્યુમેન્ટ પર `societyId`.
/// લૉગિન પછી [bindFromUserMap] ચોક્કસ કરો (જુઓ [AuthWrapper] / લોગિન).
class SocietyService {
  SocietyService._();
  static final SocietyService instance = SocietyService._();

  /// જૂના ડેટા / સિંગલ-સોસાયટી — માઇગ્રેશન સ્ક્રિપ્ટ આ જ ID ઉમેરે.
  static const String kDefaultSocietyId = 'default';

  String _societyId = kDefaultSocietyId;
  String get societyId => _societyId;

  void bindFromUserMap(Map<String, dynamic>? data) {
    final raw = data?['societyId'];
    if (raw is String && raw.trim().isNotEmpty) {
      _societyId = raw.trim();
    } else {
      _societyId = kDefaultSocietyId;
    }
  }

  void clear() {
    _societyId = kDefaultSocietyId;
  }

  /// `societyId` ન હોય / ખાલી → માત્ર [kDefaultSocietyId] સોસાયટી (જૂનો ડેટા / માઇગ્રેશન પહેલાં).
  bool documentBelongsToCurrentTenant(Map<String, dynamic>? data) {
    if (data == null) return false;
    final raw = data['societyId'];
    if (raw == null) return _societyId == kDefaultSocietyId;
    final s = raw.toString().trim();
    if (s.isEmpty) return _societyId == kDefaultSocietyId;
    return s == _societyId;
  }

  /// બીજી સોસાયટીમાં બ્લોક ID કૉલિઝન ન થાય તેમ પ્રિફિક્સ.
  String blockFirestoreId(String logicalBlockId) {
    if (_societyId == kDefaultSocietyId) return logicalBlockId;
    return '${_societyId}_$logicalBlockId';
  }

  String unitFirestoreDocId(String logicalBlockId, String unitNumber) {
    final bid = blockFirestoreId(logicalBlockId);
    return '$bid-$unitNumber';
  }

  Map<String, dynamic> tenantFields() => {'societyId': _societyId};

  /// FCM ટોપિક માટે સેફ સેગમેન્ટ.
  static String fcmTopicSegment(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// ડિફૉલ્ટ સોસાયટી = જૂના ટોપિક નામ (એપ અપડેટ વગરના ક્લાયન્ટ સાથે સુસંગત).
  String get topicMembers {
    if (_societyId == kDefaultSocietyId) return 'society_members';
    return 'soc_${fcmTopicSegment(_societyId)}_members';
  }

  String get topicAdmins {
    if (_societyId == kDefaultSocietyId) return 'society_admins';
    return 'soc_${fcmTopicSegment(_societyId)}_admins';
  }

  String get topicWatchmen {
    if (_societyId == kDefaultSocietyId) return 'society_watchmen';
    return 'soc_${fcmTopicSegment(_societyId)}_watchmen';
  }

  DocumentReference<Map<String, dynamic>> societySettingsDoc(
      FirebaseFirestore db) {
    return db.collection('society_settings').doc(_societyId);
  }

  /// સેટઅપ / એડમિન: ડિફૉલ્ટ સોસાયટી માટે લેગસી `settings/society_config` પણ મર્જ.
  Future<void> mirrorLegacySocietyConfig(
      Map<String, dynamic> fields) async {
    if (_societyId != kDefaultSocietyId) return;
    final merged = {...fields, 'societyId': kDefaultSocietyId};
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('society_config')
        .set(merged, SetOptions(merge: true));
  }
}
