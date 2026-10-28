import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String societyId;
  final String title;
  final String body;
  final String category;
  final String? targetBlock;
  final bool isUrgent;
  final bool isPinned;
  final DateTime createdAt;

  const NoticeModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.body,
    this.category = 'સામાન્ય',
    this.targetBlock,
    this.isUrgent = false,
    this.isPinned = false,
    required this.createdAt,
  });

  bool get isCommon => targetBlock == null || targetBlock == 'ALL' || targetBlock!.isEmpty;

  factory NoticeModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return NoticeModel(
      id: doc.id,
      societyId: (d['societyId'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      category: (d['category'] ?? 'સામાન્ય').toString(),
      targetBlock: d['targetBlock']?.toString(),
      isUrgent: d['isUrgent'] == true,
      isPinned: d['isPinned'] == true,
      createdAt: parseDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'body': body,
      'category': category,
      'targetBlock': targetBlock,
      'isUrgent': isUrgent,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
