import 'package:building_guard/core/app_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import 'admin_add_block_screen.dart';
import 'admin_add_user_screen.dart';
import 'admin_broadcast_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_emergency_contacts_screen.dart';
import 'admin_maintenance_screen.dart';
import 'admin_publish_notice_screen.dart';
import 'admin_setup_wizard_screen.dart';
import 'admin_society_bank_settings_screen.dart';
import 'admin_users_directory_screen.dart';
import 'admin_visitor_report_screen.dart';
import 'admin_watchmen_manage_screen.dart';
import 'architecture_preview.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  bool _isSetupComplete = false;
  String _societyName = "";
  String _architectureType = "Wing";
  DateTime _analyticsMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  String _analyticsBlockType = 'All';
  String _selectedActionCategory = 'all'; // 'all', 'security', 'comm', 'admin'
  late Future<List<QueryDocumentSnapshot>> _visitorInsightsFuture;

  @override
  void initState() {
    super.initState();
    _visitorInsightsFuture = _loadFilteredVisitors(
      month: _analyticsMonth,
      blockType: _analyticsBlockType,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
    });
    _checkSetupStatus();
  }

  void _checkSetupStatus() async {
    final sid = SocietyService.instance.societyId;
    var doc = await SocietyService.instance
        .societySettingsDoc(AppFirestore.instance)
        .get();
    if (!doc.exists && sid == SocietyService.kDefaultSocietyId) {
      doc = await AppFirestore.instance
          .collection('settings')
          .doc('society_config')
          .get();
    }
    if (mounted) {
      setState(() {
        if (doc.exists) {
          _isSetupComplete = doc.data()?['isSetupComplete'] ?? false;
          _societyName = doc.data()?['societyName'] ?? "";
          _architectureType = doc.data()?['architectureType'] ?? "Wing";
        }
        _isLoading = false;
      });
    }
  }



  List<DateTime> _analyticsMonthOptions() {
    final now = DateTime.now();
    return List.generate(12, (i) => DateTime(now.year, now.month - i));
  }

  String _monthLabel(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[d.month - 1]} ${d.year}';
  }

  Future<List<QueryDocumentSnapshot>> _loadFilteredVisitors({
    required DateTime month,
    required String blockType,
  }) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonthStart = DateTime(month.year, month.month + 1, 1);

    final visitorsSnap = await AppFirestore.instance
        .collection('visitors')
        .where(
          'entryTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('entryTime', isLessThan: Timestamp.fromDate(nextMonthStart))
        .limit(3000)
        .get();

    var docs = visitorsSnap.docs
        .where(
          (d) =>
              SocietyService.instance.documentBelongsToCurrentTenant(d.data()),
        )
        .toList();

    if (blockType == 'All') return docs;

    final blocksSnap = await AppFirestore.instance
        .collection('blocks')
        .where('societyId', isEqualTo: SocietyService.instance.societyId)
        .get();

    final typeByBlockId = <String, String>{};
    for (final b in blocksSnap.docs) {
      final data = b.data();
      final t = (data['type'] ?? '').toString();
      typeByBlockId[b.id] = t;
    }

    final normalized = blockType.toLowerCase();
    docs = docs.where((d) {
      final m = d.data();
      final blockId = (m['blockName'] ?? '').toString();
      final type = (typeByBlockId[blockId] ?? '').toLowerCase();
      return type == normalized;
    }).toList();

    return docs;
  }

  void _showRoleUsersDialog(String roleTitle, String roleKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUsersDirectoryScreen(initialRole: roleKey),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            _societyName.isEmpty ? 'My Building' : _societyName,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _isSetupComplete
        ? _buildMainDashboard()
        : AdminSetupWizardScreen(onSetupComplete: _checkSetupStatus);
  }

  // ==========================================
  // ૨. MAIN DASHBOARD (EXECUTIVE COMMAND CENTER)
  // ==========================================
  Widget _buildMainDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleSpacing: 16,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _societyName.isEmpty ? 'My Building' : _societyName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2563EB)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          "એડમિન કંટ્રોલ સેન્ટર • ૨૪×૭ લાઈવ",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Complaints Notification Bell with badge
                StreamBuilder<QuerySnapshot>(
                  stream: AppFirestore.instance
                      .collection('complaints')
                      .where('societyId', isEqualTo: SocietyService.instance.societyId)
                      .where('status', isNotEqualTo: 'resolved')
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    final pendingCount = snap.hasData ? snap.data!.docs.length : 0;
                    return Tooltip(
                      message: 'ફરિયાદો & એલર્ટ્સ',
                      child: InkWell(
                        onTap: () => _openComplaints(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: pendingCount > 0
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: pendingCount > 0
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                pendingCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                color: pendingCount > 0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF334155),
                                size: 19,
                              ),
                            ),
                            if (pendingCount > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '$pendingCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 7),
                // 2. Bank & UPI Settings button
                Tooltip(
                  message: 'સોસાયટી બેંક & UPI સેટિંગ્સ',
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: Color(0xFF334155),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // 3. Logout button
                Tooltip(
                  message: 'લોગઆઉટ',
                  child: InkWell(
                    onTap: () => _showLogoutConfirmation(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSummaryCard(),
            const SizedBox(height: 14),
            _buildPendingComplaintsAlert(),
            const SizedBox(height: 14),
            _buildLiveMetricsSection(),
            const SizedBox(height: 16),
            _buildFeaturedMaintenanceBanner(),
            const SizedBox(height: 18),
            _buildLiveGateFeed(),
            const SizedBox(height: 20),
            _buildCategorizedActionSection(),
            const SizedBox(height: 20),
            _buildVisitorInsightsCard(),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: PremiumSectionHeader(
                    title: "તાજેતરના સભ્યો",
                    icon: Icons.groups_rounded,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRoleUsersDialog('મેમ્બર', 'member'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('બધા જુઓ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMemberList(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('લોગઆઉટ'),
          ],
        ),
        content: const Text('શું તમે ખરેખર એડમિન પેનલમાંથી લોગઆઉટ કરવા માંગો છો?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseAuth.instance.signOut();
            },
            child: const Text('હા, લોગઆઉટ'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/society_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.94),
                      const Color(0xFF1E1B4B).withValues(alpha: 0.88),
                      const Color(0xFF312E81).withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 13, color: Color(0xFF34D399)),
                            SizedBox(width: 5),
                            Text(
                              "સ્માર્ટ સિક્યોરિટી • સક્રિય",
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          _architectureType == 'Wing' ? '🏢 વિંગ / એપાર્ટમેન્ટ' : '🏡 શેરી / બંગલો',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _societyName.isEmpty ? "સ્માર્ટ સોસાયટી કમાન્ડ હબ" : _societyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ગેટ વિઝિટર્સ, સિક્યોરિટી કવચ, મેન્ટેનન્સ અને ડિજિટલ પરિપત્ર",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Executive Action Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeroActionButton(
                          icon: Icons.campaign_rounded,
                          label: "લાઈવ બ્રોડકાસ્ટ",
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showNotificationDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.post_add_rounded,
                          label: "નવી નોટિસ",
                          color: const Color(0xFFEA580C),
                          onTap: () => _showPublishNoticeDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.account_balance_wallet_rounded,
                          label: "મેન્ટેનન્સ પોર્ટલ",
                          color: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.phone_in_talk_rounded,
                          label: "ઈમરજન્સી હેલ્પ",
                          color: const Color(0xFFEF4444),
                          onTap: () => _showEmergencyContactsDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Real-time alert banner for pending complaints
  Widget _buildPendingComplaintsAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('complaints')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .where('status', isNotEqualTo: 'resolved')
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        final pendingCount = snap.hasData ? snap.data!.docs.length : 0;
        if (pendingCount == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "સોસાયટી સુરક્ષા વ્યવસ્થા સામાન્ય છે • કોઈ પેન્ડિંગ ફરિયાદ નથી",
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openComplaints(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⚠️ $pendingCount સભ્યોની ફરિયાદો ઉકેલવા માટે બાકી છે",
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            "તુરંત તપાસ અને નિરાકરણ માટે અહીં ટેપ કરો",
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveMetricsSection() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.34,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildLiveMetricCard(
          title: "સભ્યો",
          subtitle: "પરિવાર ડિરેક્ટરી",
          icon: Icons.groups_rounded,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          collection: 'users',
          field: 'role',
          value: 'member',
          onTap: () => _showRoleUsersDialog('મેમ્બર', 'member'),
        ),
        _buildLiveMetricCard(
          title: "ગેટ સિક્યોરિટી",
          subtitle: "વોચમેન સ્ટાફ & PIN",
          icon: Icons.security_rounded,
          gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
          collection: 'users',
          field: 'role',
          value: 'watchman',
          onTap: () => _showWatchmanManageDialog(context),
        ),
        _buildTodayVisitorsMetricCard(),
        _buildLiveMetricCard(
          title: _architectureType == 'Wing' ? "વિંગ્સ / બ્લોક્સ" : "શેરીઓ",
          subtitle: "સ્ટ્રક્ચર નકશો",
          icon: Icons.apartment_rounded,
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          collection: 'blocks',
          onTap: _navigateToPreview,
        ),
      ],
    );
  }

  Widget _buildTodayVisitorsMetricCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('visitors')
          .orderBy('entryTime', descending: true)
          .limit(40)
          .snapshots(),
      builder: (context, snap) {
        int todayCount = 0;
        if (snap.hasData) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          todayCount = snap.data!.docs.where((d) {
            final m = d.data() as Map<String, dynamic>;
            if (!SocietyService.instance.documentBelongsToCurrentTenant(m)) return false;
            final ts = m['entryTime'] as Timestamp?;
            if (ts == null) return false;
            return ts.toDate().isAfter(startOfDay);
          }).length;
        }

        return _buildExecutiveMetricCard(
          title: "આજના મુલાકાતી",
          subtitle: "ગેટ લાઈવ ટ્રાફિક",
          icon: Icons.badge_rounded,
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          count: todayCount,
          onTap: () => _showVisitorReportDialog(context),
        );
      },
    );
  }

  Widget _buildLiveMetricCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String collection,
    String? field,
    String? value,
    VoidCallback? onTap,
  }) {
    Query query = AppFirestore.instance
        .collection(collection)
        .where('societyId', isEqualTo: SocietyService.instance.societyId);
    if (field != null) {
      query = query.where(field, isEqualTo: value);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return _buildExecutiveMetricCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          gradientColors: gradientColors,
          count: count,
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildExecutiveMetricCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required int count,
    VoidCallback? onTap,
  }) {
    final primaryColor = gradientColors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: LinearGradient(
              colors: [
                Colors.white,
                primaryColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background watermark icon
              Positioned(
                right: -6,
                top: -6,
                child: Icon(
                  icon,
                  size: 56,
                  color: primaryColor.withValues(alpha: 0.045),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 21, color: Colors.white),
                        ),
                        Text(
                          "$count",
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onTap != null)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// High impact Fintech & Payment hub card
  Widget _buildFeaturedMaintenanceBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative background glowing orb
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.24),
                              Colors.white.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    "મેન્ટેનન્સ પોર્ટલ & QR પેમેન્ટ",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "UPI ૧-ટેપ",
                                    style: TextStyle(
                                      color: Color(0xFF78350F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "માસિક બિલિંગ, સોસાયટી UPI QR સ્કેન અને ઑનલાઇન કલેક્શન",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF064E3B),
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text(
                            "બિલિંગ ડેસ્ક",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text(
                            "બેંક/UPI સેટિંગ",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real-time live gate visitor feed for immediate operational awareness
  Widget _buildLiveGateFeed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.radar_rounded, size: 20, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🚨 લાઈવ ગેટ એક્ટિવિટી",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      "ગેટ પર તાજેતરના મુલાકાતીઓ (Realtime Feed)",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () => _showVisitorReportDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      "રિપોર્ટ જુઓ",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
                .collection('visitors')
                .orderBy('entryTime', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final docs = snap.hasData
                  ? snap.data!.docs
                      .where((d) => SocietyService.instance
                          .documentBelongsToCurrentTenant(d.data() as Map<String, dynamic>?))
                      .take(3)
                      .toList()
                  : <QueryDocumentSnapshot>[];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, size: 28, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "ગેટ સુરક્ષા સામાન્ય છે",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "આજે હજુ સુધી કોઈ મુલાકાતીની નોંધણી નથી થઈ.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final m = doc.data() as Map<String, dynamic>;
                  final name = m['name'] ?? 'મુલાકાતી';
                  final rawBlock = (m['blockName'] ?? '').toString();
                  final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
                  final unit = m['unitNumber'] ?? '';
                  final purpose = m['purpose'] ?? 'મુલાકાત';
                  final status = m['status'] ?? 'pending';
                  final ts = m['entryTime'] as Timestamp?;
                  final timeStr = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : 'હમણાં';

                  final (statusLabel, statusColor, statusBg) = switch (status) {
                    'approved' => ('મંજૂર', const Color(0xFF047857), const Color(0xFFECFDF5)),
                    'rejected' => ('નકારેલ', const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
                    'checked_out' => ('બહાર ગયા', const Color(0xFF0F766E), const Color(0xFFF0FDFA)),
                    _ => ('ગેટ પર', const Color(0xFFB45309), const Color(0xFFFFFBEB)),
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'V',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "લક્ષ્ય: $cleanBlock-$unit • હેતુ: $purpose",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Categorized action management hub with segmented chips
  Widget _buildCategorizedActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumSectionHeader(
          title: "કંટ્રોલ પેનલ & મેનેજમેન્ટ",
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', 'બધા (All)', Icons.apps_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('security', '🛡️ સુરક્ષા & ગેટ', Icons.security_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('comm', '📢 સંચાર & સૂચના', Icons.campaign_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('admin', '🏢 વહીવટ & સેટઅપ', Icons.apartment_rounded),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildFilteredActionGrid(),
      ],
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon) {
    final isSelected = _selectedActionCategory == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedActionCategory = key),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredActionGrid() {
    final allActions = [
      (
        category: 'admin',
        title: "નવી $_architectureType ઉમેરો",
        subtitle: "નવા બ્લોક/ઘર એડ કરો",
        icon: Icons.add_business_rounded,
        gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
        onTap: _showAddBlockDialog,
      ),
      (
        category: 'admin',
        title: "યુઝર રજીસ્ટ્રેશન",
        subtitle: "મેમ્બર & સ્ટાફ નોંધણી",
        icon: Icons.person_add_alt_1_rounded,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () => _showAddUserDialog(context),
      ),
      (
        category: 'comm',
        title: "લાઈવ બ્રોડકાસ્ટ",
        subtitle: "તમામને તુરંત સૂચના",
        icon: Icons.campaign_rounded,
        gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => _showNotificationDialog(context),
      ),
      (
        category: 'comm',
        title: "નોટિસ બોર્ડ પોસ્ટ",
        subtitle: "ડિજિટલ પરિપત્ર પબ્લિશ",
        icon: Icons.article_rounded,
        gradient: [const Color(0xFFEA580C), const Color(0xFFC2410C)],
        onTap: () => _showPublishNoticeDialog(context),
      ),
      (
        category: 'comm',
        title: "ફરિયાદ નિવારણ",
        subtitle: "મેમ્બર સમસ્યા & સમાધાન",
        icon: Icons.report_problem_rounded,
        gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => _openComplaints(context),
      ),
      (
        category: 'security',
        title: "વિઝિટર રિપોર્ટ",
        subtitle: "મુલાકાતી એન્ટ્રી વિગત",
        icon: Icons.analytics_rounded,
        gradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        onTap: () => _showVisitorReportDialog(context),
      ),
      (
        category: 'security',
        title: "વોચમેન મેનેજ",
        subtitle: "ડ્યુટી સ્ટેટસ & પિન",
        icon: Icons.security_rounded,
        gradient: [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
        onTap: () => _showWatchmanManageDialog(context),
      ),
      (
        category: 'security',
        title: "ઈમરજન્સી હેલ્પલાઇન",
        subtitle: "પોલીસ, ૧૦૮, ફાયર, પ્લમ્બર",
        icon: Icons.phone_in_talk_rounded,
        gradient: [const Color(0xFFE11D48), const Color(0xFFBE123C)],
        onTap: () => _showEmergencyContactsDialog(context),
      ),
      (
        category: 'admin',
        title: "બેંક/UPI સેટિંગ્સ",
        subtitle: "સોસાયટી કલેક્શન QR",
        icon: Icons.account_balance_rounded,
        gradient: [const Color(0xFF059669), const Color(0xFF047857)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
        ),
      ),
      (
        category: 'admin',
        title: "સોસાયટી નકશો",
        subtitle: "ફ્લેટ્સ વિઝ્યુઅલ પ્રિવ્યુ",
        icon: Icons.map_rounded,
        gradient: [const Color(0xFF6366F1), const Color(0xFF4338CA)],
        onTap: _navigateToPreview,
      ),
    ];

    final filtered = _selectedActionCategory == 'all'
        ? allActions
        : allActions.where((a) => a.category == _selectedActionCategory).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 86,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final a = filtered[index];
        final primaryColor = a.gradient.first;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    primaryColor.withValues(alpha: 0.035),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: a.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(a.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: primaryColor.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitorInsightsCard() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _visitorInsightsFuture,
      builder: (context, snapshot) {
        final docs = snapshot.data ?? <QueryDocumentSnapshot>[];
        final total = docs.length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final rejected = docs.where((d) => d['status'] == 'rejected').length;
        final checkedOut = docs
            .where((d) => d['status'] == 'checked_out')
            .length;
        final byBlock = <String, int>{};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final block = (data['blockName'] ?? '-').toString();
          final cleanB = block.contains('_') ? block.split('_').last : block;
          byBlock[cleanB] = (byBlock[cleanB] ?? 0) + 1;
        }
        final topBlocks = byBlock.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topBlockBars = topBlocks.take(5).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, size: 20, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "મુલાકાતી વિશ્લેષણ",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "ગેટ ટ્રાફિક & એન્ટ્રી આંકડા",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      "કુલ: $total",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 155,
                    child: DropdownButtonFormField<DateTime>(
                      initialValue: _analyticsMonth,
                      decoration: InputDecoration(
                        labelText: 'મહિનો',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: _analyticsMonthOptions()
                          .map(
                            (m) => DropdownMenuItem<DateTime>(
                              value: m,
                              child: Text(_monthLabel(m), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _analyticsMonth = v;
                          _visitorInsightsFuture = _loadFilteredVisitors(
                            month: _analyticsMonth,
                            blockType: _analyticsBlockType,
                          );
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 155,
                    child: DropdownButtonFormField<String>(
                      initialValue: _analyticsBlockType,
                      decoration: InputDecoration(
                        labelText: 'પ્રકાર',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('બધા (All)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        DropdownMenuItem(value: 'Wing', child: Text('વિંગ (Wing)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        DropdownMenuItem(
                          value: 'Street',
                          child: Text('શેરી (Street)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _analyticsBlockType = v;
                          _visitorInsightsFuture = _loadFilteredVisitors(
                            month: _analyticsMonth,
                            blockType: _analyticsBlockType,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Modern 4 Analytics Status Cards (Replaces bare floating stubs)
              Row(
                children: [
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "મંજૂર",
                      count: approved,
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "બાકી",
                      count: pending,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "નકારેલ",
                      count: rejected,
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "બહાર ગયા",
                      count: checkedOut,
                      color: const Color(0xFF0D9488),
                      icon: Icons.logout_rounded,
                    ),
                  ),
                ],
              ),
              if (topBlockBars.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  "સૌથી વધુ વિઝિટર્સ ધરાવતા બ્લોક્સ",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ...topBlockBars.map((e) {
                  final topMax = topBlockBars.first.value;
                  final ratio = topMax == 0 ? 0.0 : (e.value / topMax);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (snapshot.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _navigateToPreview() async {
    setState(() => _isLoading = true); // પ્રોસેસિંગ બતાવવા માટે

    try {
      // Firestore માંથી બધા બ્લોક્સ (Wings/Streets) મેળવો
      var snapshot = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .get();

      List<Map<String, dynamic>> blocksData = [];

      for (var doc in snapshot.docs) {
        String bID = doc.id;

        // દરેક બ્લોકના યુનિટ્સની સંખ્યા મેળવો (ગણતરી માટે)
        var unitsSnapshot = await AppFirestore.instance
            .collection('units')
            .where('societyId', isEqualTo: SocietyService.instance.societyId)
            .where('blockName', isEqualTo: bID)
            .get();

        // આપણે પ્રિવ્યુ માટે v1 અને v2 ની જરૂર પડશે
        // અંદાજે ગણતરી: જો વિંગ હોય તો માળ અને ઘરની સંખ્યા
        // નોંધ: સેટઅપ વખતે આપણે આ ડેટા બ્લોક ડોક્યુમેન્ટમાં પણ સેવ કરી શકીએ છીએ

        int maxFloor = 0;
        int unitsPerFloor = 0;
        int minUnit = 9999;
        int maxUnit = 0;

        for (var uDoc in unitsSnapshot.docs) {
          int floor = uDoc.data()['floorNo'] ?? 0;
          int uNum = int.parse(uDoc.data()['unitNumber']);
          if (floor > maxFloor) maxFloor = floor;
          if (uNum > maxUnit) maxUnit = uNum;
          if (uNum < minUnit) minUnit = uNum;
        }

        // અંદાજિત units per floor
        if (maxFloor > 0) unitsPerFloor = unitsSnapshot.docs.length ~/ maxFloor;

        blocksData.add({
          'name': bID.split('-').last, // 'W-A' માંથી 'A' લેવા માટે
          'id': bID,
          'v1': _architectureType == 'Wing' ? maxFloor : minUnit,
          'v2': _architectureType == 'Wing' ? unitsPerFloor : maxUnit,
        });
      }

      if (!mounted) return;

      // નવી સ્ક્રીન પર જાવ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArchitecturePreviewScreen(
            tempBlocks: blocksData,
            architectureType: _architectureType,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // LOGIC & VALIDATED FUNCTIONS
  // ==========================================





  // ==========================================
  // ૩. USER REGISTRATION & BLOCK LOGIC (Dedicated Screens)
  // ==========================================
  Future<void> _showAddUserDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddUserScreen()),
    );
  }

  void _showAddBlockDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddBlockScreen(architectureType: _architectureType),
      ),
    );
  }

  Widget _buildMemberList() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('users')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .where('role', isEqualTo: 'member')
          .limit(8)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 36,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "હજુ સુધી કોઈ મેમ્બર્સ ઉમેરાયા નથી",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "સોસાયટીના ફ્લેટ માલિકો અને ભાડૂતોની નોંધણી કરો.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text(
                    "નવા મેમ્બર ઉમેરો",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }

        var docs = snap.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            String mId = d['uid'] ?? "";
            String mName = d['name'] ?? "No Name";
            String rawBlock = (d['blockName'] ?? "").toString();
            String mBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
            String mUnit = d['unitNumber'] ?? "";
            String mPhone = d['phone'] ?? "";
            String mEmail = d['email'] ?? "";

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mName.isNotEmpty ? mName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                mName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mBlock.isNotEmpty || mUnit.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  mUnit.isNotEmpty ? "$mBlock • $mUnit" : mBlock,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mPhone.isNotEmpty
                              ? mPhone
                              : (mEmail.isNotEmpty ? mEmail : 'કોઈ સંપર્ક નથી'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mPhone.isNotEmpty)
                    InkWell(
                      onTap: () => _makePhoneCall(mPhone),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Color(0xFF0D9488), size: 17),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'transfer') {
                        _confirmTransfer(mId, mName);
                      }
                      if (value == 'notify') {
                        _showNotificationDialog(
                          context,
                          targetUID: mId,
                          targetName: mName,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'transfer',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('પ્રમુખ પદ સોંપો', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notify',
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('સૂચના મોકલો', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationDialog(
    BuildContext context, {
    String? targetUID,
    String? targetName,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBroadcastScreen(
          targetUID: targetUID,
          targetName: targetName,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (_) {}
  }

  void _openComplaints(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()),
    );
  }

  Future<void> _showPublishNoticeDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPublishNoticeScreen()),
    );
  }

  Future<void> _showVisitorReportDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminVisitorReportScreen()),
    );
  }

  Future<void> _showWatchmanManageDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminWatchmenManageScreen()),
    );
  }

  Future<void> _showEmergencyContactsDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEmergencyContactsScreen()),
    );
  }

  void _confirmTransfer(String newAdminId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ચેતવણી!"),
        content: Text(
          "શું તમે ખરેખર $name ને સોસાયટીના નવા પ્રમુખ બનાવવા માંગો છો? આ કર્યા પછી તમારી એડમિન સત્તા જતી રહેશે.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ના"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _transferOwnership(newAdminId);
            },
            child: const Text("હા, સોંપો"),
          ),
        ],
      ),
    );
  }

  Future<void> _transferOwnership(String newAdminId) async {
    // હાલના લોગ-ઈન થયેલ એડમિનની UID
    String currentAdminId = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _isLoading = true);

    try {
      WriteBatch batch = AppFirestore.instance.batch();

      // ૧. નવા વ્યક્તિને એડમિન બનાવો
      DocumentReference newAdminRef = AppFirestore.instance
          .collection('users')
          .doc(newAdminId);
      batch.update(newAdminRef, {'role': 'admin'});

      // ૨. જૂના (પોતાના) રોલને મેમ્બર બનાવી દો
      DocumentReference oldAdminRef = AppFirestore.instance
          .collection('users')
          .doc(currentAdminId);
      batch.update(oldAdminRef, {'role': 'member'});

      await batch.commit();

      if (!mounted) return;

      // સફળતાનો મેસેજ અને લોગઆઉટ (કારણ કે હવે તમે એડમિન નથી)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("માલિકી સફળતાપૂર્વક બદલાઈ ગઈ છે!"),
          backgroundColor: Colors.green,
        ),
      );

      // એડમિન પેનલમાંથી બહાર કાઢીને લોગિન પર મોકલી દેવા
      FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ આવી: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
