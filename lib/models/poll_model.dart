import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final String id;
  final String text;
  final int votesCount;

  const PollOption({
    required this.id,
    required this.text,
    this.votesCount = 0,
  });

  factory PollOption.fromMap(Map<String, dynamic> data) {
    return PollOption(
      id: (data['id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      votesCount: (data['votesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'votesCount': votesCount,
    };
  }

  PollOption copyWith({int? votesCount, String? text}) {
    return PollOption(
      id: id,
      text: text ?? this.text,
      votesCount: votesCount ?? this.votesCount,
    );
  }
}

class PollModel {
  final String id;
  final String societyId;
  final String title;
  final String description;
  final List<PollOption> options;
  final String targetScope; // 'all' or specific blockName e.g. 'A'
  final String voterEligibility; // 'all_members' or 'owners_only'
  final bool isAnonymous;
  final bool statusActive; // true if active, false if closed
  final DateTime startDate;
  final DateTime endDate;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final int totalVotes;
  final List<String> votedMemberUids;
  final List<String> votedFlats;
  final String? resolutionSummary;

  const PollModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.description,
    required this.options,
    this.targetScope = 'all',
    this.voterEligibility = 'all_members',
    this.isAnonymous = false,
    this.statusActive = true,
    required this.startDate,
    required this.endDate,
    required this.createdByUid,
    this.createdByName = '',
    required this.createdAt,
    this.totalVotes = 0,
    this.votedMemberUids = const [],
    this.votedFlats = const [],
    this.resolutionSummary,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isLive => statusActive && !isExpired;

  bool hasUserVoted(String uid) => votedMemberUids.contains(uid);
  bool hasFlatVoted(String flatDisplay) => votedFlats.contains(flatDisplay);

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final d = DateTime.tryParse(val);
        if (d != null) return d;
      }
      return DateTime.now();
    }

    final rawOptions = data['options'] as List? ?? [];
    final options = rawOptions
        .whereType<Map>()
        .map((m) => PollOption.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final rawVotedUids = (data['votedMemberUids'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    final rawVotedFlats = (data['votedFlats'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return PollModel(
      id: doc.id,
      societyId: (data['societyId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      options: options,
      targetScope: (data['targetScope'] ?? 'all').toString(),
      voterEligibility: (data['voterEligibility'] ?? 'all_members').toString(),
      isAnonymous: data['isAnonymous'] == true,
      statusActive: data['statusActive'] ?? true,
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
      createdByUid: (data['createdByUid'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt: parseDate(data['createdAt']),
      totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
      votedMemberUids: rawVotedUids,
      votedFlats: rawVotedFlats,
      resolutionSummary: data['resolutionSummary']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'description': description,
      'options': options.map((o) => o.toMap()).toList(),
      'targetScope': targetScope,
      'voterEligibility': voterEligibility,
      'isAnonymous': isAnonymous,
      'statusActive': statusActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalVotes': totalVotes,
      'votedMemberUids': votedMemberUids,
      'votedFlats': votedFlats,
      if (resolutionSummary != null) 'resolutionSummary': resolutionSummary,
    };
  }
}
