import 'package:cloud_firestore/cloud_firestore.dart';

class AmenityModel {
  final String id;
  final String societyId;
  final String name;
  final String category; // 'hall', 'clubhouse', 'terrace', 'guest_room', 'sports', 'other'
  final int capacity;
  final String description;
  final bool isPaid;
  final double rentAmount;
  final double securityDeposit;
  final String slotType; // 'full_day', 'time_slots'
  final List<String> availableSlots;
  final String rulesAndTerms;
  final bool isActive;
  final bool requiresAdminApproval;

  const AmenityModel({
    required this.id,
    required this.societyId,
    required this.name,
    this.category = 'hall',
    this.capacity = 100,
    this.description = '',
    this.isPaid = false,
    this.rentAmount = 0.0,
    this.securityDeposit = 0.0,
    this.slotType = 'full_day',
    this.availableSlots = const ['આખો દિવસ (Full Day)'],
    this.rulesAndTerms = '',
    this.isActive = true,
    this.requiresAdminApproval = true,
  });

  factory AmenityModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};

    final rawSlots = d['availableSlots'] as List? ?? ['આખો દિવસ (Full Day)'];
    final slots = rawSlots.map((e) => e.toString()).toList();

    return AmenityModel(
      id: doc.id,
      societyId: (d['societyId'] ?? '').toString(),
      name: (d['name'] ?? '').toString(),
      category: (d['category'] ?? 'hall').toString(),
      capacity: (d['capacity'] as num?)?.toInt() ?? 100,
      description: (d['description'] ?? '').toString(),
      isPaid: d['isPaid'] == true,
      rentAmount: (d['rentAmount'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (d['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      slotType: (d['slotType'] ?? 'full_day').toString(),
      availableSlots: slots,
      rulesAndTerms: (d['rulesAndTerms'] ?? '').toString(),
      isActive: d['isActive'] ?? true,
      requiresAdminApproval: d['requiresAdminApproval'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'name': name,
      'category': category,
      'capacity': capacity,
      'description': description,
      'isPaid': isPaid,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'slotType': slotType,
      'availableSlots': availableSlots,
      'rulesAndTerms': rulesAndTerms,
      'isActive': isActive,
      'requiresAdminApproval': requiresAdminApproval,
    };
  }
}

class AmenityBookingModel {
  final String id;
  final String societyId;
  final String amenityId;
  final String amenityName;
  final String memberUid;
  final String memberName;
  final String memberPhone;
  final String unitDisplay;
  final DateTime bookingDate; // YYYY-MM-DD
  final String slotName;
  final String purpose;
  final int expectedGuests;
  final String status; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
  final double rentAmount;
  final double securityDeposit;
  final String depositStatus; // 'pending', 'held', 'refunded', 'deducted'
  final String? adminRemarks;
  final String? inspectionNotes;
  final String eventPassCode; // 6-digit gate code for guests
  final DateTime createdAt;
  final DateTime? approvedAt;

  const AmenityBookingModel({
    required this.id,
    required this.societyId,
    required this.amenityId,
    required this.amenityName,
    required this.memberUid,
    required this.memberName,
    required this.memberPhone,
    required this.unitDisplay,
    required this.bookingDate,
    required this.slotName,
    required this.purpose,
    this.expectedGuests = 50,
    this.status = 'pending',
    this.rentAmount = 0.0,
    this.securityDeposit = 0.0,
    this.depositStatus = 'pending',
    this.adminRemarks,
    this.inspectionNotes,
    required this.eventPassCode,
    required this.createdAt,
    this.approvedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory AmenityBookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AmenityBookingModel(
      id: doc.id,
      societyId: (d['societyId'] ?? '').toString(),
      amenityId: (d['amenityId'] ?? '').toString(),
      amenityName: (d['amenityName'] ?? '').toString(),
      memberUid: (d['memberUid'] ?? '').toString(),
      memberName: (d['memberName'] ?? '').toString(),
      memberPhone: (d['memberPhone'] ?? '').toString(),
      unitDisplay: (d['unitDisplay'] ?? '').toString(),
      bookingDate: parseDate(d['bookingDate']),
      slotName: (d['slotName'] ?? '').toString(),
      purpose: (d['purpose'] ?? '').toString(),
      expectedGuests: (d['expectedGuests'] as num?)?.toInt() ?? 50,
      status: (d['status'] ?? 'pending').toString(),
      rentAmount: (d['rentAmount'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (d['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      depositStatus: (d['depositStatus'] ?? 'pending').toString(),
      adminRemarks: d['adminRemarks']?.toString(),
      inspectionNotes: d['inspectionNotes']?.toString(),
      eventPassCode: (d['eventPassCode'] ?? '').toString(),
      createdAt: parseDate(d['createdAt']),
      approvedAt: parseNullableDate(d['approvedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'amenityId': amenityId,
      'amenityName': amenityName,
      'memberUid': memberUid,
      'memberName': memberName,
      'memberPhone': memberPhone,
      'unitDisplay': unitDisplay,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'slotName': slotName,
      'purpose': purpose,
      'expectedGuests': expectedGuests,
      'status': status,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'depositStatus': depositStatus,
      if (adminRemarks != null) 'adminRemarks': adminRemarks,
      if (inspectionNotes != null) 'inspectionNotes': inspectionNotes,
      'eventPassCode': eventPassCode,
      'createdAt': Timestamp.fromDate(createdAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
    };
  }
}
