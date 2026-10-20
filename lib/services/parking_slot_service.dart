import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'society_service.dart';

enum ParkingSlotStatus {
  available, // ખાલી - કોઈપણ પસંદ કરી શકે
  occupied,  // બુક થયેલ - અન્ય સભ્યને ફાળવેલ છે (LOCKED)
  mySlot,    // તમારો સ્લોટ - વર્તમાન યુઝરના વાહનને ફાળવેલ છે
}

class ParkingSlotModel {
  final String id;
  final String societyId;
  final String slotNumber;
  final String blockName;
  final String category; // 'Wing' or 'Street'
  final String slotType; // 'car', 'bike', 'ev', 'common_plot', 'general'
  final bool isAssigned;
  final String? assignedMemberId;
  final String? assignedMemberName;
  final String? assignedFlat;
  final String? assignedVehiclePlate;
  final String? assignedVehicleModel;
  final DateTime? createdAt;

  const ParkingSlotModel({
    required this.id,
    required this.societyId,
    required this.slotNumber,
    required this.blockName,
    required this.category,
    required this.slotType,
    required this.isAssigned,
    this.assignedMemberId,
    this.assignedMemberName,
    this.assignedFlat,
    this.assignedVehiclePlate,
    this.assignedVehicleModel,
    this.createdAt,
  });

  factory ParkingSlotModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    final ts = m['createdAt'];
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    }
    return ParkingSlotModel(
      id: doc.id,
      societyId: (m['societyId'] ?? '').toString(),
      slotNumber: (m['slotNumber'] ?? doc.id).toString(),
      blockName: (m['blockName'] ?? '').toString(),
      category: (m['category'] ?? 'Wing').toString(),
      slotType: (m['slotType'] ?? 'general').toString(),
      isAssigned: m['isAssigned'] == true,
      assignedMemberId: m['assignedMemberId']?.toString(),
      assignedMemberName: m['assignedMemberName']?.toString(),
      assignedFlat: m['assignedFlat']?.toString(),
      assignedVehiclePlate: m['assignedVehiclePlate']?.toString(),
      assignedVehicleModel: m['assignedVehicleModel']?.toString(),
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'slotNumber': slotNumber,
      'blockName': blockName,
      'category': category,
      'slotType': slotType,
      'isAssigned': isAssigned,
      'assignedMemberId': assignedMemberId,
      'assignedMemberName': assignedMemberName,
      'assignedFlat': assignedFlat,
      'assignedVehiclePlate': assignedVehiclePlate,
      'assignedVehicleModel': assignedVehicleModel,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class OccupiedSlotInfo {
  final String slotName;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleType;
  final String ownerName;
  final String ownerPhone;
  final String flatDisplay;
  final String ownerUid;
  final bool isCurrentMember;

  const OccupiedSlotInfo({
    required this.slotName,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleType,
    required this.ownerName,
    required this.ownerPhone,
    required this.flatDisplay,
    required this.ownerUid,
    required this.isCurrentMember,
  });
}

class SocietyBlockInfo {
  final String name;
  final String type; // 'Wing' or 'Street'

  const SocietyBlockInfo({
    required this.name,
    required this.type,
  });

  bool get isStreet =>
      type == 'Street' ||
      name.contains('શેરી') ||
      RegExp(r'\bstreet\b', caseSensitive: false).hasMatch(name);
}

class ParkingSlotService {
  ParkingSlotService._();
  static final ParkingSlotService instance = ParkingSlotService._();

  /// સોસાયટીનો આર્કિટેક્ચર પ્રકાર ('Wing' અથવા 'Street') મેળવવો
  Stream<String> streamArchitectureType(String societyId) {
    return SocietyService.instance
        .societySettingsDoc(AppFirestore.instance)
        .snapshots()
        .map((snap) {
      if (snap.exists && snap.data() != null) {
        final t = snap.data()?['architectureType']?.toString();
        if (t != null && t.isNotEmpty) return t;
      }
      return 'Wing';
    });
  }

  /// સોસાયટીના તમામ બ્લોક્સ (વિંગ/શેરી) લાવો
  Stream<List<SocietyBlockInfo>> streamSocietyBlocks(String societyId) {
    return AppFirestore.instance
        .collection('blocks')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = <SocietyBlockInfo>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawName = (data['name'] ?? '').toString();
        final clean = SocietyService.instance.logicalBlockName(rawName);
        final type = (data['type'] ?? 'Wing').toString();
        if (clean.isNotEmpty && !list.any((b) => b.name == clean)) {
          list.add(SocietyBlockInfo(name: clean, type: type));
        }
      }
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// એડમિન દ્વારા બનાવેલા રીઅલ સ્લોટ્સ (જે-તે વિંગ માટે)
  Stream<List<ParkingSlotModel>> streamRealSlotsForBlock({
    required String societyId,
    required String blockName,
  }) {
    return AppFirestore.instance
        .collection('parking_slots')
        .where('societyId', isEqualTo: societyId)
        .where('blockName', isEqualTo: blockName)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ParkingSlotModel.fromFirestore).toList();
      list.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      return list;
    });
  }

  /// શેરી સોસાયટી માટે એડમિન દ્વારા બનાવેલા કોમન પ્લોટ / વાડી સ્લોટ્સ
  Stream<List<ParkingSlotModel>> streamRealCommonPlotSlots(String societyId) {
    return AppFirestore.instance
        .collection('parking_slots')
        .where('societyId', isEqualTo: societyId)
        .where('category', isEqualTo: 'Street')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ParkingSlotModel.fromFirestore).toList();
      list.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      return list;
    });
  }

  /// સોસાયટીના તમામ રીઅલ પાર્કિંગ સ્લોટ્સ (એડમિન મેનેજમેન્ટ માટે)
  Stream<List<ParkingSlotModel>> streamAllRealSlots(String societyId) {
    return AppFirestore.instance
        .collection('parking_slots')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ParkingSlotModel.fromFirestore).toList();
      list.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      return list;
    });
  }

  /// ૧. એડમિન દ્વારા વિંગ મુજબ જથ્થાબંધ સ્લોટ્સ Firestore માં સેવ કરવા
  Future<int> generateAndSaveWingSlotsInFirestore({
    required String societyId,
    required String blockName,
    required int carCount,
    required int bikeCount,
    required int evCount,
  }) async {
    final batch = AppFirestore.instance.batch();
    final cleanBlock = blockName.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '').toUpperCase();
    final prefix = cleanBlock.isNotEmpty ? cleanBlock : 'P';
    int count = 0;

    // ૪-વ્હીલર કાર સ્લોટ્સ
    for (int i = 1; i <= carCount; i++) {
      final slotNum = '$prefix-P${i.toString().padLeft(2, '0')}';
      final docId = '${societyId}_$slotNum';
      final docRef = AppFirestore.instance.collection('parking_slots').doc(docId);
      batch.set(docRef, {
        'societyId': societyId,
        'slotNumber': slotNum,
        'blockName': blockName,
        'category': 'Wing',
        'slotType': 'car',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;
    }

    // ૨-વ્હીલર બાઇક સ્લોટ્સ
    for (int i = 1; i <= bikeCount; i++) {
      final slotNum = '$prefix-B${i.toString().padLeft(2, '0')}';
      final docId = '${societyId}_$slotNum';
      final docRef = AppFirestore.instance.collection('parking_slots').doc(docId);
      batch.set(docRef, {
        'societyId': societyId,
        'slotNumber': slotNum,
        'blockName': blockName,
        'category': 'Wing',
        'slotType': 'bike',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;
    }

    // EV સ્લોટ્સ
    for (int i = 1; i <= evCount; i++) {
      final slotNum = '$prefix-EV${i.toString().padLeft(2, '0')}';
      final docId = '${societyId}_$slotNum';
      final docRef = AppFirestore.instance.collection('parking_slots').doc(docId);
      batch.set(docRef, {
        'societyId': societyId,
        'slotNumber': slotNum,
        'blockName': blockName,
        'category': 'Wing',
        'slotType': 'ev',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;
    }

    await batch.commit();
    return count;
  }

  /// ૨. એડમિન દ્વારા શેરી સોસાયટી માટે કોમન પ્લોટ / વાડી સ્લોટ્સ Firestore માં સેવ કરવા
  Future<int> generateAndSaveStreetCommonSlotsInFirestore({
    required String societyId,
    required int cpCount,
    required int vadiCount,
  }) async {
    final batch = AppFirestore.instance.batch();
    int count = 0;

    // કોમન પ્લોટ સ્લોટ્સ
    for (int i = 1; i <= cpCount; i++) {
      final slotNum = 'CP-${i.toString().padLeft(2, '0')}';
      final docId = '${societyId}_$slotNum';
      final docRef = AppFirestore.instance.collection('parking_slots').doc(docId);
      batch.set(docRef, {
        'societyId': societyId,
        'slotNumber': slotNum,
        'blockName': 'કોમન પ્લોટ',
        'category': 'Street',
        'slotType': 'common_plot',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;
    }

    // વાડી સ્લોટ્સ
    for (int i = 1; i <= vadiCount; i++) {
      final slotNum = 'વાડી-${i.toString().padLeft(2, '0')}';
      final docId = '${societyId}_$slotNum';
      final docRef = AppFirestore.instance.collection('parking_slots').doc(docId);
      batch.set(docRef, {
        'societyId': societyId,
        'slotNumber': slotNum,
        'blockName': 'વાડી પાર્કિંગ',
        'category': 'Street',
        'slotType': 'common_plot',
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      count++;
    }

    await batch.commit();
    return count;
  }

  /// ૩. એડમિન દ્વારા કોઈ ૧ સિંગલ કસ્ટમ સ્લોટ ઉમેરવો
  Future<void> addSingleCustomSlotInFirestore({
    required String societyId,
    required String slotNumber,
    required String blockName,
    required String category,
    required String slotType,
  }) async {
    final clean = slotNumber.trim().toUpperCase();
    final docId = '${societyId}_$clean';
    await AppFirestore.instance.collection('parking_slots').doc(docId).set({
      'societyId': societyId,
      'slotNumber': clean,
      'blockName': blockName,
      'category': category,
      'slotType': slotType,
      'isAssigned': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ૪. એડમિન દ્વારા સ્લોટ ડિલીટ કરવો
  Future<void> deleteSlotFromFirestore(String societyId, String slotNumber) async {
    final clean = slotNumber.trim().toUpperCase();
    final docId = '${societyId}_$clean';
    await AppFirestore.instance.collection('parking_slots').doc(docId).delete();
  }

  /// ૫. વાહન સેવ થાય ત્યારે Firestore સ્લોટને એસાઇન કરવો
  Future<void> markSlotAssignedInFirestore({
    required String societyId,
    required String slotNumber,
    required String memberUid,
    required String memberName,
    required String flatDisplay,
    required String vehiclePlate,
    required String vehicleModel,
    required String vehicleType,
  }) async {
    if (isFlexibleStreetParking(slotNumber)) return;
    final clean = slotNumber.trim().toUpperCase();
    final docId = '${societyId}_$clean';
    await AppFirestore.instance.collection('parking_slots').doc(docId).set({
      'isAssigned': true,
      'assignedMemberId': memberUid,
      'assignedMemberName': memberName,
      'assignedFlat': flatDisplay,
      'assignedVehiclePlate': vehiclePlate,
      'assignedVehicleModel': vehicleModel,
      'assignedVehicleType': vehicleType,
    }, SetOptions(merge: true));
  }

  /// ૬. વાહન ડિલીટ થાય ત્યારે Firestore સ્લોટ ખાલી કરવો
  Future<void> releaseSlotInFirestore({
    required String societyId,
    required String slotNumber,
  }) async {
    if (isFlexibleStreetParking(slotNumber)) return;
    final clean = slotNumber.trim().toUpperCase();
    final docId = '${societyId}_$clean';
    await AppFirestore.instance.collection('parking_slots').doc(docId).set({
      'isAssigned': false,
      'assignedMemberId': null,
      'assignedMemberName': null,
      'assignedFlat': null,
      'assignedVehiclePlate': null,
      'assignedVehicleModel': null,
      'assignedVehicleType': null,
    }, SetOptions(merge: true));
  }

  /// સોસાયટીમાં તમામ વપરાશકર્તાઓના વાહનો પરથી હાલ રોકાયેલા (Occupied) સ્લોટ્સનો રીઅલ-ટાઇમ મેપ
  Stream<Map<String, OccupiedSlotInfo>> streamOccupiedSlots(String societyId) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return AppFirestore.instance
        .collection('users')
        .where('societyId', isEqualTo: societyId)
        .where('role', isEqualTo: 'member')
        .snapshots()
        .map((snap) {
      final occupiedMap = <String, OccupiedSlotInfo>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final vehicles = data['vehicles'] as List<dynamic>? ?? [];
        final ownerName = (data['name'] ?? '').toString();
        final ownerPhone = (data['phone'] ?? '').toString();
        final rawBlock = (data['blockName'] ?? '').toString();
        final block = SocietyService.instance.logicalBlockName(rawBlock);
        final unit = (data['unitNumber'] ?? '').toString();
        final flat = [block, unit].where((e) => e.isNotEmpty).join('-');
        final isMe = doc.id == currentUid;

        for (final v in vehicles) {
          if (v is Map) {
            final slotRaw = (v['slot'] ?? '').toString().trim().toUpperCase();
            if (slotRaw.isNotEmpty) {
              occupiedMap[slotRaw] = OccupiedSlotInfo(
                slotName: slotRaw,
                vehicleNumber: (v['number'] ?? '').toString().toUpperCase(),
                vehicleModel: (v['model'] ?? '').toString(),
                vehicleType: (v['type'] ?? '').toString(),
                ownerName: ownerName,
                ownerPhone: ownerPhone,
                flatDisplay: flat.isNotEmpty ? flat : 'ફ્લેટ/મકાન',
                ownerUid: doc.id,
                isCurrentMember: isMe,
              );
            }
          }
        }
      }

      return occupiedMap;
    });
  }

  /// સ્લોટ સ્ટેટસ ચકાસો: ખાલી, અન્ય સભ્ય દ્વારા બુક, કે પોતાનો સ્લોટ
  ParkingSlotStatus checkSlotStatus({
    required String slotName,
    required Map<String, OccupiedSlotInfo> occupiedSlots,
    String? currentVehiclePlate,
  }) {
    final clean = slotName.trim().toUpperCase();
    if (clean.isEmpty) return ParkingSlotStatus.available;

    // 'ઘર આંગણે' માટે કોઈ યુનિક બ્લૉકિંગ નથી હોતું
    if (isFlexibleStreetParking(clean)) {
      return ParkingSlotStatus.available;
    }

    final info = occupiedSlots[clean];
    if (info == null) return ParkingSlotStatus.available;

    if (info.isCurrentMember) {
      if (currentVehiclePlate != null &&
          VehiclePlateValidator.clean(currentVehiclePlate) ==
              VehiclePlateValidator.clean(info.vehicleNumber)) {
        return ParkingSlotStatus.mySlot;
      }
      return ParkingSlotStatus.mySlot;
    }

    return ParkingSlotStatus.occupied;
  }

  /// શું આ સ્લોટ ફ્લેક્સિબલ શેરી પાર્કિંગ છે? (જેમ કે ઘર આંગણે / શેરી પાર્કિંગ)
  bool isFlexibleStreetParking(String slotName) {
    final upper = slotName.toUpperCase();
    return upper.contains('ઘર આંગણે') ||
        upper.contains('ઘર પાસે') ||
        upper.contains('HOME FRONT') ||
        upper.contains('પ્લોટ સામે') ||
        upper.contains('રોડ સાઇડ') ||
        upper.contains('STREET SIDE');
  }

  /// શું આ સ્લોટ બીજા કોઈ દ્વારા લેવાઈ ગયેલ છે?
  bool isSlotAlreadyTakenByOther({
    required String slotName,
    required Map<String, OccupiedSlotInfo> occupiedSlots,
  }) {
    final clean = slotName.trim().toUpperCase();
    if (clean.isEmpty) return false;

    // ઘર આંગણે કોઈનું બ્લૉક ન થાય
    if (isFlexibleStreetParking(clean)) return false;

    final info = occupiedSlots[clean];
    if (info == null) return false;

    return !info.isCurrentMember;
  }
}

class VehiclePlateValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? formattedPlate;
  final String? cleanPlate;

  const VehiclePlateValidationResult({
    required this.isValid,
    this.errorMessage,
    this.formattedPlate,
    this.cleanPlate,
  });
}

class VehiclePlateValidator {
  static const Set<String> _indianStateCodes = {
    'AN', 'AP', 'AR', 'AS', 'BR', 'CG', 'CH', 'DD', 'DL', 'DN',
    'GA', 'GJ', 'HP', 'HR', 'JH', 'JK', 'KA', 'KL', 'LA', 'LD',
    'MH', 'ML', 'MN', 'MP', 'MZ', 'NL', 'OD', 'OR', 'PB', 'PY',
    'RJ', 'SK', 'TN', 'TR', 'TS', 'UA', 'UK', 'UP', 'WB',
  };

  /// સફાઈ: બધી વધારાની સ્પેસ અને હાઇફન દૂર કરીને અપરકેસ બનાવે છે
  static String clean(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// વાહન નંબર પ્લેટની ચકાસણી કરે છે
  static VehiclePlateValidationResult validate(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const VehiclePlateValidationResult(
        isValid: false,
        errorMessage: 'કૃપા કરીને વાહન નંબર પ્લેટ દાખલ કરો',
      );
    }

    final cleaned = clean(input);

    if (cleaned.length < 5) {
      return const VehiclePlateValidationResult(
        isValid: false,
        errorMessage: 'નંબર પ્લેટ ખૂબ ટૂંકી છે (દા.ત. GJ 01 AB 1234)',
      );
    }

    if (cleaned.length > 12) {
      return const VehiclePlateValidationResult(
        isValid: false,
        errorMessage: 'અમાન્ય વાહન નંબર (વધુ પડતા અક્ષરો છે)',
      );
    }

    // ૧. ભારત (BH) સીરીઝ ચેક: દા.ત. 22 BH 1234 AA અથવા 22BH1234AA
    final bhRegex = RegExp(r'^([0-9]{2})BH([0-9]{4})([A-Z]{1,2})$');
    final bhMatch = bhRegex.firstMatch(cleaned);
    if (bhMatch != null) {
      final year = bhMatch.group(1)!;
      final num = bhMatch.group(2)!;
      final letters = bhMatch.group(3)!;
      final formatted = '$year BH $num $letters';
      return VehiclePlateValidationResult(
        isValid: true,
        formattedPlate: formatted,
        cleanPlate: cleaned,
      );
    }

    // ૨. જો યુઝરે સ્પેસ/હાઇફન સાથે દાખલ કર્યું હોય, તો એના ટોકન્સ ચકાસો (દા.ત. DL 1C AA 1111, GJ 5 1234)
    final tokens = input.trim().toUpperCase().split(RegExp(r'[\s\-]+'));
    if (tokens.length >= 3 && _indianStateCodes.contains(tokens.first)) {
      final state = tokens[0];
      final rto = tokens[1];
      final last = tokens.last;
      if (RegExp(r'^[0-9]{1,4}$').hasMatch(last)) {
        final middle = tokens.sublist(2, tokens.length - 1).join(' ');
        final parts = [state, rto, if (middle.isNotEmpty) middle, last];
        return VehiclePlateValidationResult(
          isValid: true,
          formattedPlate: parts.join(' '),
          cleanPlate: cleaned,
        );
      }
    }

    // ૩. સ્ટાન્ડર્ડ RTO ફોર્મેટ:
    // A: 2-digit RTO: GJ 01 AB 1234 અથવા GJ 01 1234
    final reg2Digit = RegExp(r'^([A-Z]{2})([0-9]{2})([A-Z]{0,3})([0-9]{1,4})$');
    final match2 = reg2Digit.firstMatch(cleaned);
    if (match2 != null) {
      final state = match2.group(1)!;
      final rto = match2.group(2)!;
      final series = match2.group(3)!;
      final number = match2.group(4)!;

      if (!_indianStateCodes.contains(state)) {
        return VehiclePlateValidationResult(
          isValid: false,
          errorMessage: 'અમાન્ય રાજ્ય કોડ "$state"! (દા.ત. GJ, MH, DL, RJ...)',
        );
      }

      final parts = [state, rto, if (series.isNotEmpty) series, number];
      return VehiclePlateValidationResult(
        isValid: true,
        formattedPlate: parts.join(' '),
        cleanPlate: cleaned,
      );
    }

    // B: 1-digit RTO (દા.ત. GJ 5 1234 અથવા DL 1 C 1234)
    final reg1Digit = RegExp(r'^([A-Z]{2})([0-9]{1})([A-Z]{0,3})([0-9]{1,4})$');
    final match1 = reg1Digit.firstMatch(cleaned);
    if (match1 != null) {
      final state = match1.group(1)!;
      final rto = match1.group(2)!;
      final series = match1.group(3)!;
      final number = match1.group(4)!;

      if (!_indianStateCodes.contains(state)) {
        return VehiclePlateValidationResult(
          isValid: false,
          errorMessage: 'અમાન્ય રાજ્ય કોડ "$state"! (દા.ત. GJ, MH, DL, RJ...)',
        );
      }

      final parts = [state, rto, if (series.isNotEmpty) series, number];
      return VehiclePlateValidationResult(
        isValid: true,
        formattedPlate: parts.join(' '),
        cleanPlate: cleaned,
      );
    }

    return const VehiclePlateValidationResult(
      isValid: false,
      errorMessage: 'અમાન્ય નંબર પ્લેટ ફોર્મેટ! (દા.ત. GJ 01 AB 1234)',
    );
  }
}
