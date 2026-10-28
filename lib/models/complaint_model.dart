import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String societyId;
  final String title;
  final String category;
  final String description;
  final String photoUrl;
  final String memberId;
  final String memberName;
  final String memberFlat;
  final bool isUrgent;
  final String status; // 'pending', 'in_progress', 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const ComplaintModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.category,
    required this.description,
    this.photoUrl = '',
    required this.memberId,
    this.memberName = '',
    this.memberFlat = '',
    this.isUrgent = false,
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isPending => !isResolved;

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
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

    return ComplaintModel(
      id: doc.id,
      societyId: (d['societyId'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      category: (d['category'] ?? 'અન્ય સામાન્ય').toString(),
      description: (d['description'] ?? '').toString(),
      photoUrl: (d['photoUrl'] ?? '').toString(),
      memberId: (d['memberId'] ?? '').toString(),
      memberName: (d['memberName'] ?? '').toString(),
      memberFlat: (d['memberFlat'] ?? '').toString(),
      isUrgent: d['isUrgent'] == true,
      status: (d['status'] ?? 'pending').toString(),
      createdAt: parseDate(d['createdAt']),
      resolvedAt: parseNullableDate(d['resolvedAt']),
      resolutionNotes: d['resolutionNotes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'category': category,
      'description': description,
      'photoUrl': photoUrl,
      'memberId': memberId,
      'memberName': memberName,
      'memberFlat': memberFlat,
      'isUrgent': isUrgent,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionNotes': resolutionNotes,
    };
  }
}
