import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/premise_type.dart';
import 'localization_service.dart';

/// એક Firebase પ્રોજેક્ટમાં ઘણી સોસાયટી — દરે ડૉક્યુમેન્ટ પર `societyId`.
/// લૉગિન પછી [bindFromUserMap] ચોક્કસ કરો (જુઓ [AuthWrapper] / લોગિન).
class SocietyService {
  SocietyService._();
  static final SocietyService instance = SocietyService._();

  /// જૂના ડેટા / સિંગલ-સોસાયટી — માઇગ્રેશન સ્ક્રિપ્ટ આ જ ID ઉમેરે.
  static const String kDefaultSocietyId = 'default';

  String _societyId = kDefaultSocietyId;
  String get societyId => _societyId;
  String get currentSocietyId => _societyId;

  String _societyName = 'માય સોસાયટી (My Society)';
  String get currentSocietyName => _societyName;
  String get societyName => _societyName;

  String _architectureType = 'Wing';
  String get architectureType => _architectureType;
  PremiseVocabulary get vocabulary => PremiseVocabulary.fromString(_architectureType);

  String _currentUserRole = 'member';
  String get currentUserRole => _currentUserRole;

  bool _isCommitteeMember = false;
  bool get isCommitteeMember => _isCommitteeMember;

  String _currentUserName = '';
  String get currentUserName => _currentUserName;

  String _currentUserBlock = '';
  String get currentUserBlock => _currentUserBlock;

  String _currentUserUnit = '';
  String get currentUserUnit => _currentUserUnit;

  bool get isAdmin =>
      _currentUserRole == 'admin' ||
      _currentUserRole == 'chairman' ||
      _currentUserRole == 'president' ||
      isPlatformSuperAdmin;
  bool get isSubAdminOrCommittee =>
      _isCommitteeMember ||
      _currentUserRole == 'sub_admin' ||
      _currentUserRole == 'subadmin' ||
      _currentUserRole == 'wing_admin' ||
      _currentUserRole == 'committee' ||
      _currentUserRole == 'committee_member' ||
      _currentUserRole == 'kamiti' ||
      _currentUserRole == 'kamiti_member';
  bool get isGuard =>
      _currentUserRole == 'watchman' ||
      _currentUserRole == 'guard' ||
      _currentUserRole == 'security' ||
      _currentUserRole == 'gate_staff';
  bool get isPlatformSuperAdmin =>
      _currentUserRole == 'super_admin' || _currentUserRole == 'superadmin';
  bool get hasAdminAccess => isAdmin || isSubAdminOrCommittee;

  void setSocietyName(String name) {
    if (name.trim().isNotEmpty) _societyName = name.trim();
  }

  void setArchitectureType(String type) {
    if (type.trim().isNotEmpty) _architectureType = type.trim();
  }

  void bindFromUserMap(Map<String, dynamic>? data) {
    final raw = data?['societyId'];
    if (raw is String && raw.trim().isNotEmpty) {
      _societyId = raw.trim();
    } else {
      _societyId = kDefaultSocietyId;
    }

    final rawName = data?['societyName'];
    if (rawName is String && rawName.trim().isNotEmpty) {
      _societyName = rawName.trim();
    }

    final rawArch = data?['architectureType'];
    if (rawArch is String && rawArch.trim().isNotEmpty) {
      _architectureType = rawArch.trim();
    }

    final rawRole = (data?['role'] ?? 'member').toString().toLowerCase().trim();
    _currentUserRole = rawRole.isEmpty ? 'member' : rawRole;
    _isCommitteeMember = _currentUserRole == 'sub_admin' ||
        _currentUserRole == 'subadmin' ||
        _currentUserRole == 'wing_admin' ||
        _currentUserRole == 'committee' ||
        _currentUserRole == 'committee_member' ||
        _currentUserRole == 'kamiti' ||
        _currentUserRole == 'kamiti_member' ||
        data?['isCommitteeMember'] == true ||
        data?['subAdmin'] == true ||
        data?['isSubAdmin'] == true;
    _currentUserName = (data?['name'] ?? '').toString().trim();
    _currentUserBlock = (data?['blockName'] ?? '').toString().trim();
    _currentUserUnit = (data?['unitNumber'] ?? '').toString().trim();
  }

  void clear() {
    _societyId = kDefaultSocietyId;
    _societyName = 'માય સોસાયટી (My Society)';
    _architectureType = 'Wing';
    _currentUserRole = 'member';
    _isCommitteeMember = false;
    _currentUserName = '';
    _currentUserBlock = '';
    _currentUserUnit = '';
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
    if (logicalBlockId.startsWith('${_societyId}_')) return logicalBlockId;
    return '${_societyId}_$logicalBlockId';
  }

  /// UI પ્રદર્શન માટે ક્લીન લૉજિકલ બ્લોક નામ મેળવો.
  String logicalBlockName(String blockId) {
    if (_societyId != kDefaultSocietyId && blockId.startsWith('${_societyId}_')) {
      return blockId.substring('${_societyId}_'.length);
    }
    return blockId;
  }

  /// ગ્રાઉન્ડ ફ્લોર અથવા વિવિધ ફોર્મેટના બ્લોક નામને કેનોનિકલ/સિંગલ ફોર્મેટમાં કન્વર્ટ કરો.
  /// દા.ત. 'W-G', 'COMM-G', 'FLOOR-G', 'Ground', 'Ground Floor', 'G' -> 'G'.
  /// 'W-A' -> 'A', 'S-1' -> '1', 'F1-F5' -> 'F1-F5'.
  String normalizeBlockName(String raw) {
    var s = logicalBlockName(raw).trim();
    if (s.isEmpty) return '';

    // Strip common legacy prefixes
    s = s.replaceAll(
      RegExp(r'^(W|S|C|M|COMM|FLOOR|FLOORS|RES-WING|WING|BLOCK|STREET)-', caseSensitive: false),
      '',
    );
    s = s.replaceAll(RegExp(r'^(વિંગ|બ્લોક|શેરી|ફ્લોર)\s*', caseSensitive: false), '');
    s = s.trim().toUpperCase();

    // Ground Floor normalization
    if (s == 'G' ||
        s == 'GROUND' ||
        s == 'GROUND FLOOR' ||
        s == 'GROUNDFLOOR' ||
        s == 'G FLOOR' ||
        s == 'G-FLOOR' ||
        s == '0' ||
        s == 'ગ્રાઉન્ડ' ||
        s == 'ગ્રાઉન્ડ ફ્લોર') {
      return 'G';
    }

    return s;
  }

  /// ચેક કરે છે કે આપેલ બ્લોક ગ્રાઉન્ડ ફ્લોર છે કે નહીં.
  bool isGroundBlock(String raw) {
    final n = normalizeBlockName(raw);
    return n == 'G' || n == '0';
  }

  /// યુઝર ઇન્ટરફેસ (UI) માટે સચોટ, સુંદર લોકલાઇઝ્ડ લેબલ.
  /// દા.ત. Street 1 -> 'શેરી નં. 1' (GU), 'Street No. 1' (EN), 'गली नं. 1' (HI)
  String formatBlockDisplayName(
    String raw, {
    String? architectureType,
    String? category,
  }) {
    final clean = normalizeBlockName(raw);
    if (clean.isEmpty) return '';

    final arch = (architectureType ?? _architectureType).toLowerCase();
    final cat = (category ?? '').toLowerCase();
    final lang = LocalizationService.instance.currentCode;

    if (isGroundBlock(clean)) {
      if (lang == 'en') {
        if (arch == 'commercial' || cat == 'commercial') return 'Ground Floor (G)';
        if (arch == 'mixed') return 'Ground Floor / Shops (G)';
        return 'Ground Floor (G)';
      } else if (lang == 'hi') {
        if (arch == 'commercial' || cat == 'commercial') return 'ग्राउंड फ्लोर (G)';
        if (arch == 'mixed') return 'ग्राउंड फ्लोर / दुकानें (G)';
        return 'ग्राउंड फ्लोर (G)';
      }
      if (arch == 'commercial' || cat == 'commercial') {
        return 'ગ્રાઉન્ડ ફ્લોર (G)';
      } else if (arch == 'mixed') {
        return 'ગ્રાઉન્ડ ફ્લોર / શોપ્સ (G)';
      }
      return 'ગ્રાઉન્ડ ફ્લોર (G)';
    }

    if (arch == 'commercial') {
      if (clean.startsWith('B') || clean.contains('BASEMENT')) {
        if (lang == 'en') return 'Basement $clean';
        if (lang == 'hi') return 'बेसमेंट $clean';
        return 'બેઝમેન્ટ $clean';
      }
      if (lang == 'en') return 'Floor $clean';
      if (lang == 'hi') return 'फ्लोर $clean';
      return 'ફ્લોર $clean';
    } else if (arch == 'street') {
      if (lang == 'en') return 'Street No. $clean';
      if (lang == 'hi') return 'गली नं. $clean';
      return 'શેરી નં. $clean';
    } else if (arch == 'mixed') {
      if (cat == 'commercial') {
        if (lang == 'en') return 'Shops: Floor $clean';
        if (lang == 'hi') return 'दुकानें: फ्लोर $clean';
        return 'શોપ્સ: ફ્લોર $clean';
      }
      if (lang == 'en') return 'Wing $clean';
      if (lang == 'hi') return 'विंग $clean';
      return 'વિંગ $clean';
    } else {
      if (lang == 'en') return 'Wing $clean';
      if (lang == 'hi') return 'विंग $clean';
      return 'વિંગ $clean';
    }
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
    await AppFirestore.instance
        .collection('settings')
        .doc('society_config')
        .set(merged, SetOptions(merge: true));
  }
}
