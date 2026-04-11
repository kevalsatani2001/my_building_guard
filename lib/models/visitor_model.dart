import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorModel {
  final String id;
  final String name;
  final String phone;
  final String purpose;
  final String photoUrl;
  final String memberId;
  final String watchmanId;
  final String unitNumber;
  final String status; // pending, approved, rejected, checked_out
  final DateTime entryTime;
  final DateTime? exitTime;

  VisitorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.photoUrl,
    required this.memberId,
    required this.watchmanId,
    required this.unitNumber,
    required this.status,
    required this.entryTime,
    this.exitTime,
  });

  factory VisitorModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return VisitorModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      purpose: data['purpose'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      memberId: data['memberId'] ?? '',
      watchmanId: data['watchmanId'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      status: data['status'] ?? 'pending',
      entryTime: data['entryTime'] is Timestamp
          ? (data['entryTime'] as Timestamp).toDate()
          : DateTime.now(),
      exitTime: data['exitTime'] != null ? (data['exitTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'purpose': purpose,
      'photoUrl': photoUrl,
      'memberId': memberId,
      'watchmanId': watchmanId,
      'unitNumber': unitNumber,
      'status': status,
      'entryTime': Timestamp.fromDate(entryTime),
      'exitTime': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
    };
  }
}
