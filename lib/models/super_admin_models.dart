class SocietyOverview {
  final String id;
  final String name;
  final String architectureType; // 'Commercial', 'Mixed', 'Wing', 'Street'
  final String city;
  final String? address;
  final String? adminUid;
  final String adminName;
  final String adminPhone;
  final String adminEmail;
  final int totalUnits;
  final int totalMembers;
  final int totalWatchmen;
  final int totalAdmins;
  final double totalBilledMonth;
  final double totalCollectedMonth;
  final int pendingComplaints;
  final int todayVisitors;
  final bool isActive;
  final DateTime createdAt;

  const SocietyOverview({
    required this.id,
    required this.name,
    required this.architectureType,
    required this.city,
    this.address,
    this.adminUid,
    required this.adminName,
    required this.adminPhone,
    required this.adminEmail,
    required this.totalUnits,
    required this.totalMembers,
    required this.totalWatchmen,
    required this.totalAdmins,
    required this.totalBilledMonth,
    required this.totalCollectedMonth,
    required this.pendingComplaints,
    required this.todayVisitors,
    required this.isActive,
    required this.createdAt,
  });

  double get collectionPercentage =>
      totalBilledMonth > 0 ? (totalCollectedMonth / totalBilledMonth) * 100 : 0.0;
}

class GlobalPlatformStats {
  final int totalSocieties;
  final int commercialSocieties;
  final int mixedSocieties;
  final int residentialSocieties;
  final int streetSocieties;
  final int totalAdmins;
  final int totalSubAdmins;
  final int totalWatchmen;
  final int totalMembers;
  final int totalUnits;
  final double totalPlatformBilled;
  final double totalPlatformCollected;
  final double totalPlatformPending;
  final double totalPlatformGst;
  final int todayTotalVisitors;
  final int totalComplaints;
  final int resolvedComplaints;

  const GlobalPlatformStats({
    required this.totalSocieties,
    required this.commercialSocieties,
    required this.mixedSocieties,
    required this.residentialSocieties,
    required this.streetSocieties,
    required this.totalAdmins,
    required this.totalSubAdmins,
    required this.totalWatchmen,
    required this.totalMembers,
    required this.totalUnits,
    required this.totalPlatformBilled,
    required this.totalPlatformCollected,
    required this.totalPlatformPending,
    required this.totalPlatformGst,
    required this.todayTotalVisitors,
    required this.totalComplaints,
    required this.resolvedComplaints,
  });

  factory GlobalPlatformStats.empty() {
    return const GlobalPlatformStats(
      totalSocieties: 0,
      commercialSocieties: 0,
      mixedSocieties: 0,
      residentialSocieties: 0,
      streetSocieties: 0,
      totalAdmins: 0,
      totalSubAdmins: 0,
      totalWatchmen: 0,
      totalMembers: 0,
      totalUnits: 0,
      totalPlatformBilled: 0.0,
      totalPlatformCollected: 0.0,
      totalPlatformPending: 0.0,
      totalPlatformGst: 0.0,
      todayTotalVisitors: 0,
      totalComplaints: 0,
      resolvedComplaints: 0,
    );
  }
}

class SuperAdminUserItem {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin', 'wing_admin', 'watchman', 'member'
  final String societyId;
  final String societyName;
  final String? unitNumber;
  final String? blockName;
  final bool isActive;
  final DateTime createdAt;

  const SuperAdminUserItem({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.societyId,
    required this.societyName,
    this.unitNumber,
    this.blockName,
    required this.isActive,
    required this.createdAt,
  });
}

class OnboardSocietyResult {
  final String societyId;
  final String adminUid;
  final String societyName;
  final String architectureType;
  final String city;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final String adminPhone;
  final int? totalUnits;

  const OnboardSocietyResult({
    required this.societyId,
    required this.adminUid,
    required this.societyName,
    required this.architectureType,
    required this.city,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
    required this.adminPhone,
    this.totalUnits,
  });
}

