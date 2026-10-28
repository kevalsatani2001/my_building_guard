import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStaffModel {
  final String id;
  final String societyId;
  final String memberId;
  final String staffName;
  final String staffPhone;
  final String staffRole;
  final String photoUrl;
  final bool isActive;
  final DateTime createdAt;

  const DailyStaffModel({
    required this.id,
    required this.societyId,
    required this.memberId,
    required this.staffName,
    required this.staffPhone,
    required this.staffRole,
    this.photoUrl = '',
    this.isActive = true,
    required this.createdAt,
  });

  factory DailyStaffModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return DailyStaffModel(
      id: doc.id,
      societyId: (d['societyId'] ?? '').toString(),
      memberId: (d['memberId'] ?? '').toString(),
      staffName: (d['staffName'] ?? '').toString(),
      staffPhone: (d['staffPhone'] ?? '').toString(),
      staffRole: (d['staffRole'] ?? 'અન્ય હેલ્પર').toString(),
      photoUrl: (d['photoUrl'] ?? '').toString(),
      isActive: d['isActive'] ?? true,
      createdAt: parseDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'memberId': memberId,
      'staffName': staffName,
      'staffPhone': staffPhone,
      'staffRole': staffRole,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
