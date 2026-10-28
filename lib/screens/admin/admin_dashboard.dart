import 'package:building_guard/core/app_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import '../../services/session_guard_service.dart';
import '../../services/society_service.dart';
import '../../models/premise_type.dart';
import '../../widgets/premium_ui.dart';
import 'admin_add_block_screen.dart';
import 'admin_add_user_screen.dart';
import 'admin_broadcast_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_emergency_contacts_screen.dart';
import 'admin_maintenance_screen.dart';
import 'admin_bulk_bill_screen.dart';
import 'admin_publish_notice_screen.dart';
import 'admin_setup_wizard_screen.dart';
import 'admin_member_signature_sheet_screen.dart';
import 'admin_society_bank_settings_screen.dart';
import 'admin_users_directory_screen.dart';
import 'admin_visitor_report_screen.dart';
import 'admin_watchmen_manage_screen.dart';
import 'admin_parking_management_screen.dart';
import 'admin_accounts_screen.dart';
import 'admin_polls_screen.dart';
import 'admin_amenities_screen.dart';
import 'admin_patrol_screen.dart';
import '../auth/architecture_preview.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/animated_bottom_nav_bar.dart';

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
  String _gateFeedFilter = 'all'; // 'all', 'pending', 'approved', 'checked_out', 'rejected'
  late Future<List<QueryDocumentSnapshot>> _visitorInsightsFuture;
  int _selectedNavIndex = 0;

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
    bool isSetup = false;
    String socName = "";
    String archType = "Wing";
    if (doc.exists) {
      final data = doc.data() ?? {};
      isSetup = data['isSetupComplete'] == true;
      socName = (data['societyName'] ?? "").toString();
      archType = (data['architectureType'] ?? "Wing").toString();
      SocietyService.instance.setArchitectureType(archType);
      if (socName.isNotEmpty) {
        SocietyService.instance.setSocietyName(socName);
      }

      // જો isSetupComplete: true હોય છતાં પણ જો સોસાયટીમાં કોઈ જ એકમો (units) ન હોય,
      // તો એડમિનને પ્રથમવારનું આર્કિટેક્ચર સેટઅપ વિઝાર્ડ બતાવવું જરૂરી છે.
      if (isSetup) {
        try {
          final unitsSnap = await AppFirestore.instance
              .collection('units')
              .where('societyId', isEqualTo: sid)
              .limit(1)
              .get();
          if (unitsSnap.docs.isEmpty) {
            isSetup = false;
          }
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() {
        _isSetupComplete = isSetup;
        _societyName = socName;
        _architectureType = archType;
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
        : AdminSetupWizardScreen(
            onSetupComplete: _checkSetupStatus,
            initialSocietyName: _societyName,
            initialArchitectureType: _architectureType,
          );
  }

  // ==========================================
  // ૨. MAIN DASHBOARD (EXECUTIVE COMMAND CENTER)
  // ==========================================
  Widget _buildMainDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppNavigationDrawer(role: 'admin'),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: Builder(
          builder: (ctx) => Center(
            child: InkWell(
              onTap: () => Scaffold.of(ctx).openDrawer(),
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
                  Icons.menu_rounded,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        leadingWidth: 52,
        titleSpacing: 0,
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
                      Flexible(
                        child: Text(
                          AppStrings.get('admin_control_center'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
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
                      message: 'ફરિયાદો & એલર્ટ્સ'.tr,
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
                  message: 'સોસાયટી બેંક & UPI સેટિંગ્સ'.tr,
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
                // Multi-language switch button (GU / HI / EN)
                const LanguageSwitchButton(),
                const SizedBox(width: 7),
                // 3. Logout button
                Tooltip(
                  message: AppStrings.get('logout'),
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
      extendBody: true,
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildAdminHomeTab(),
          _buildAdminSecurityTab(),
          _buildAdminFinanceTab(),
          _buildAdminSocietyTab(),
        ],
      ),
      bottomNavigationBar: FloatingGlassmorphicNavBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        primaryColor: const Color(0xFF0F766E),
        items: [
          FloatingNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'nav_home'.tr,
          ),
          FloatingNavItem(
            icon: Icons.shield_outlined,
            activeIcon: Icons.shield_rounded,
            label: 'nav_security'.tr,
          ),
          FloatingNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'nav_finance'.tr,
          ),
          FloatingNavItem(
            icon: Icons.apartment_outlined,
            activeIcon: Icons.apartment_rounded,
            label: 'nav_society'.tr,
          ),
        ],
      ),
    );
  }

  EdgeInsets _tabScrollPadding(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(16, 16, 16, 120 + bottomInset);
  }

  Widget _buildAdminHomeTab() {
    return SingleChildScrollView(
      padding: _tabScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSummaryCard(),
          const SizedBox(height: 14),
          _buildPendingComplaintsAlert(),
          const SizedBox(height: 14),
          _buildLiveMetricsSection(),
          const SizedBox(height: 14),
          _buildVisitorInsightsCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PremiumSectionHeader(
                  title: "તાજેતરના સભ્યો".tr,
                  icon: Icons.groups_rounded,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showRoleUsersDialog('મેમ્બર'.tr, 'member'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text('બધા જુઓ'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMemberList(),
        ],
      ),
    );
  }

  Widget _buildAdminSecurityTab() {
    return SingleChildScrollView(
      padding: _tabScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSectionHeader(
            title: "sec_gate_control_title".tr,
            icon: Icons.shield_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildNavHubCard(
                  title: 'sec_night_patrol'.tr,
                  subtitle: 'sec_qr_checkpoints'.tr,
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF4F46E5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPatrolScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNavHubCard(
                  title: 'sec_watchmen_staff'.tr,
                  subtitle: 'sec_on_duty_pin'.tr,
                  icon: Icons.security_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => _showWatchmanManageDialog(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildNavHubCard(
                  title: 'sec_visitor_report'.tr,
                  subtitle: 'sec_history_excel'.tr,
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminVisitorReportScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNavHubCard(
                  title: 'sec_emergency_help'.tr,
                  subtitle: 'sec_contact_numbers'.tr,
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () => _showEmergencyContactsDialog(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLiveGateFeed(),
        ],
      ),
    );
  }

  Widget _buildAdminFinanceTab() {
    return SingleChildScrollView(
      padding: _tabScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedMaintenanceBanner(),
          const SizedBox(height: 20),
          PremiumSectionHeader(
            title: "fin_accounts_title".tr,
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildNavHubCard(
                  title: 'fin_society_ledger'.tr,
                  subtitle: 'fin_expense_passbook'.tr,
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0F766E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAccountsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNavHubCard(
                  title: 'fin_maintenance_desk'.tr,
                  subtitle: 'fin_bills_payments'.tr,
                  icon: Icons.request_quote_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildNavHubCard(
                  title: 'fin_bulk_billing'.tr,
                  subtitle: 'fin_all_flats_together'.tr,
                  icon: Icons.playlist_add_check_circle_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminBulkBillScreen(
                        initialMonth: DateFormat('yyyy-MM').format(DateTime.now()),
                        architectureType: _architectureType,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNavHubCard(
                  title: 'fin_bank_upi'.tr,
                  subtitle: 'fin_qr_account_info'.tr,
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildNavHubCard(
            title: 'fin_member_signature_sheet'.tr,
            subtitle: 'fin_annual_sign_verification'.tr,
            icon: Icons.draw_rounded,
            color: const Color(0xFF475569),
            isFullWidth: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminMemberSignatureSheetScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSocietyTab() {
    return SingleChildScrollView(
      padding: _tabScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorizedActionSection(),
        ],
      ),
    );
  }

  Widget _buildNavHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InteractiveBounce(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isFullWidth ? 13 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.07),
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
            child: isFullWidth
                ? Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: color,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.82)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 21),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                              height: 1.22,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() async {
    final confirmed = await PremiumLogoutDialog.show(
      context,
      roleName: 'એડમિન પેનલ'.tr,
    );
    if (confirmed && mounted) {
      await SessionGuardService.performAppLogout(context);
    }
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 13, color: Color(0xFF34D399)),
                            SizedBox(width: 5),
                            Text(
                              "સ્માર્ટ સિક્યોરિટી • સક્રિય".tr,
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
                          PremiseVocabulary.fromString(_architectureType).premiseBadge,
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
                    _societyName.isEmpty ? "સ્માર્ટ સોસાયટી કમાન્ડ હબ".tr : _societyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ગેટ વિઝિટર્સ, સિક્યોરિટી કવચ, મેન્ટેનન્સ અને ડિજિટલ પરિપત્ર".tr,
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
                          label: "લાઈવ બ્રોડકાસ્ટ".tr,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showNotificationDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.post_add_rounded,
                          label: "નવી નોટિસ".tr,
                          color: const Color(0xFFEA580C),
                          onTap: () => _showPublishNoticeDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.account_balance_wallet_rounded,
                          label: "મેન્ટેનન્સ પોર્ટલ".tr,
                          color: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.account_balance_rounded,
                          label: "સોસાયટી હિસાબ".tr,
                          color: const Color(0xFF0F766E),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminAccountsScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildHeroActionButton(
                          icon: Icons.phone_in_talk_rounded,
                          label: "ઈમરજન્સી હેલ્પ".tr,
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
                Expanded(
                  child: Text(
                    "સોસાયટી સુરક્ષા વ્યવસ્થા સામાન્ય છે • કોઈ પેન્ડિંગ ફરિયાદ નથી".tr,
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
                            "⚠️ $pendingCount સભ્યોની ફરિયાદો ઉકેલવા માટે બાકી છે".tr,
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "તુરંત તપાસ અને નિરાકરણ માટે અહીં ટેપ કરો".tr,
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
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildLiveMetricCard(
                  title: AppStrings.get('role_member'),
                  subtitle: "પરિવાર ડિરેક્ટરી".tr,
                  icon: Icons.groups_rounded,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  collection: 'users',
                  field: 'role',
                  value: 'member',
                  onTap: () => _showRoleUsersDialog('મેમ્બર'.tr, 'member'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLiveMetricCard(
                  title: AppStrings.get('role_guard'),
                  subtitle: "વોચમેન સ્ટાફ & PIN".tr,
                  icon: Icons.security_rounded,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
                  collection: 'users',
                  field: 'role',
                  value: 'watchman',
                  onTap: () => _showWatchmanManageDialog(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildTodayVisitorsMetricCard(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLiveMetricCard(
                  title: PremiseVocabulary.fromString(_architectureType).blockLabel,
                  subtitle: "સ્ટ્રક્ચર નકશો".tr,
                  icon: Icons.apartment_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  collection: 'blocks',
                  onTap: _navigateToPreview,
                ),
              ),
            ],
          ),
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
          title: AppStrings.get('admin_today_visitors'),
          subtitle: "ગેટ લાઈવ ટ્રાફિક".tr,
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

    return InteractiveBounce(
      onTap: onTap,
      child: Material(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
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
                            child: Icon(icon, size: 20, color: Colors.white),
                          ),
                          AnimatedCountUpText(
                            value: count,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  "મેન્ટેનન્સ પોર્ટલ & QR પેમેન્ટ".tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
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
                                  child: Text(
                                    "UPI ૧-ટેપ".tr,
                                    style: const TextStyle(
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
                              "માસિક બિલિંગ, સોસાયટી UPI QR સ્કેન અને ઑનલાઇન કલેક્શન".tr,
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
                          label: Text(
                            "બિલિંગ ડેસ્ક".tr,
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
                          label: Text(
                            "બેંક/UPI સેટિંગ".tr,
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.account_balance_rounded, size: 16),
                      label: Text(
                        "સોસાયટી હિસાબ & ખર્ચ (Ledger & Fund)".tr,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAccountsScreen()),
                      ),
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

  /// Real-time live gate visitor feed with luxury cards, status chips, and admin control
  Widget _buildLiveGateFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('visitors')
          .orderBy('entryTime', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        final allDocs = snap.hasData
            ? snap.data!.docs
                .where((d) => SocietyService.instance
                    .documentBelongsToCurrentTenant(d.data() as Map<String, dynamic>?))
                .toList()
            : <QueryDocumentSnapshot>[];

        final pendingCount =
            allDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final approvedCount =
            allDocs.where((d) => (d.data() as Map)['status'] == 'approved').length;
        final checkedOutCount =
            allDocs.where((d) => (d.data() as Map)['status'] == 'checked_out').length;
        final rejectedCount =
            allDocs.where((d) => (d.data() as Map)['status'] == 'rejected').length;

        final filteredDocs = allDocs.where((d) {
          final s = ((d.data() as Map)['status'] ?? 'pending').toString();
          if (_gateFeedFilter == 'all') return true;
          if (_gateFeedFilter == 'pending') return s == 'pending';
          if (_gateFeedFilter == 'approved') return s == 'approved';
          if (_gateFeedFilter == 'checked_out') return s == 'checked_out';
          if (_gateFeedFilter == 'rejected') return s == 'rejected';
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Integrated Header matching sequence
            Row(
              children: [
                Expanded(
                  child: PremiumSectionHeader(
                    title: "sec_live_gate_feed".tr,
                    icon: Icons.radar_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                // Pulsing Live Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsingStatusDot(
                        color: Color(0xFF059669),
                        size: 6.5,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "૨૪x૭ લાઈવ".tr,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Full Report Action Button
                InkWell(
                  onTap: () => _showVisitorReportDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "રિપોર્ટ જુઓ".tr,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8.5,
                          color: Color(0xFF4338CA),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Filter Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGateFilterChip(
                      'all', '${'sec_filter_all'.tr} (${allDocs.length})', Icons.apps_rounded),
                  const SizedBox(width: 8),
                  _buildGateFilterChip('pending', '⏳ ${'sec_filter_at_gate'.tr} ($pendingCount)',
                      Icons.hourglass_top_rounded),
                  const SizedBox(width: 8),
                  _buildGateFilterChip('approved', '🟢 ${'sec_filter_inside'.tr} ($approvedCount)',
                      Icons.door_front_door_rounded),
                  const SizedBox(width: 8),
                  _buildGateFilterChip('checked_out', '🚪 ${'sec_filter_out'.tr} ($checkedOutCount)',
                      Icons.exit_to_app_rounded),
                  const SizedBox(width: 8),
                  _buildGateFilterChip(
                      'rejected', '🔴 ${'analytics_rejected'.tr} ($rejectedCount)', Icons.cancel_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Visitor Feed Content (Loading / Empty / List)
            if (snap.connectionState == ConnectionState.waiting && allDocs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              )
            else if (filteredDocs.isEmpty)
              _buildUltraPremiumGateEmptyState(allDocs.length)
            else ...[
              ...List.generate(
                filteredDocs.take(4).length,
                (i) => StaggeredEntrance(
                  index: i,
                  child: _buildAdminVisitorCard(filteredDocs[i]),
                ),
              ),
              if (filteredDocs.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => _showVisitorReportDialog(context),
                      icon: const Icon(Icons.history_rounded,
                          size: 16, color: Color(0xFF4F46E5)),
                      label: Text(
                        "તમામ ${allDocs.length} મુલાકાતીઓ જુઓ (View All)".tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// Segmented Gate Filter Chip with vibrant selection styling
  Widget _buildGateFilterChip(String key, String label, IconData icon) {
    final isSelected = _gateFeedFilter == key;
    return InkWell(
      onTap: () => setState(() => _gateFeedFilter = key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ultra-luxury Empty State for Gate Security matching the app theme
  Widget _buildUltraPremiumGateEmptyState(int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Concentric glowing radar rings
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 26,
                  color: Color(0xFF4338CA),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "ગેટ સુરક્ષા સક્રિય & સામાન્ય છે".tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _gateFeedFilter == 'all'
                ? "આજના દિવસમાં સોસાયટી ગેટ પર તમામ સુરક્ષા સામાન્ય છે. કોઈ પેન્ડિંગ કે શંકાસ્પદ મુલાકાતી નથી.".tr
                : "પસંદ કરેલ ફિલ્ટર મુજબ કોઈ મુલાકાતીની એન્ટ્રી મળી નથી.".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Action shortcuts
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showVisitorReportDialog(context),
                icon: const Icon(Icons.receipt_long_rounded, size: 14),
                label: Text(
                  "મુલાકાતી રજીસ્ટર".tr,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4338CA),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showWatchmanManageDialog(context),
                icon: const Icon(Icons.security_rounded, size: 14),
                label: Text(
                  "વોચમેન મેનેજ".tr,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Localized visitor purpose resolver
  String _getLocalizedVisitorPurpose(String rawPurpose) {
    final p = rawPurpose.trim().toLowerCase();
    if (p.contains('pre-approved') || p.contains('preapproved') || p.contains('પ્રી-એપ્રૂવ્ડ')) {
      return 'pre_approved_guest'.tr;
    }
    if (p.contains('merchant') || p.contains('shop staff') || p.contains('વેપારી')) {
      return 'merchant_shop_staff'.tr;
    }
    if (p.contains('delivery') || p.contains('courier') || p.contains('parcel') || p.contains('ડિલિવરી')) {
      return 'ડિલિવરી'.tr;
    }
    if (p.contains('cab') || p.contains('taxi') || p.contains('uber') || p.contains('ola') || p.contains('ટેક્સી')) {
      return 'કેબ / ટેક્સી'.tr;
    }
    if (p.contains('service') || p.contains('repair') || p.contains('સર્વિસ') || p.contains('કારીગર')) {
      return 'સર્વિસ / કારીગર'.tr;
    }
    if (p.contains('guest') || p.contains('visitor') || p.contains('મહેમાન')) {
      return 'મહેમાન (Guest)'.tr;
    }
    return rawPurpose.tr;
  }

  /// Initial letter squircle avatar when photo is unavailable
  Widget _buildStyledVisitorFallbackAvatar(String name, Color typeColor, Color typeBg, IconData typeIcon) {
    final cleanName = name.trim();
    return Container(
      decoration: BoxDecoration(
        color: typeBg,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: cleanName.isNotEmpty && cleanName != 'મુલાકાતી' && cleanName != 'Visitor'
          ? Text(
              cleanName[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: typeColor,
                fontSize: 18,
              ),
            )
          : Icon(typeIcon, color: typeColor, size: 20),
    );
  }

  /// Default fallback avatar for admin visitor sheets
  Widget _fallbackAdminAvatar(String name) {
    return _buildStyledVisitorFallbackAvatar(
      name,
      const Color(0xFF4F46E5),
      const Color(0xFFEEF2FF),
      Icons.person_rounded,
    );
  }

  /// Ultra-luxury visitor card matching MemberScreen design language
  Widget _buildAdminVisitorCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = (d['name'] ?? 'મુલાકાતી'.tr).toString();
    final phone = (d['phone'] ?? '').toString().trim();
    final rawPurpose = (d['purpose'] ?? 'મુલાકાત'.tr).toString();
    final localizedPurpose = _getLocalizedVisitorPurpose(rawPurpose);
    final photoUrl = (d['photoUrl'] ?? '').toString().trim();
    final memberName = (d['memberName'] ?? d['hostName'] ?? '').toString().trim();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString().trim();
    final vehicle = (d['vehicleNumber'] ?? d['vehicle'] ?? '').toString().trim();

    final formattedBlock = cleanBlock.isNotEmpty
        ? SocietyService.instance.formatBlockDisplayName(cleanBlock)
        : '';
    final destFlatStr = formattedBlock.isNotEmpty && unit.isNotEmpty
        ? '$formattedBlock • ${'unit'.tr} $unit'
        : (formattedBlock.isNotEmpty
            ? formattedBlock
            : (unit.isNotEmpty ? '${'unit'.tr} $unit' : 'સોસાયટી'.tr));

    final status = (d['status'] ?? 'pending').toString();
    final entryTs = d['entryTime'] as Timestamp?;
    final exitTs = d['exitTime'] as Timestamp?;
    final timeStr = entryTs != null
        ? DateFormat('hh:mm a').format(entryTs.toDate())
        : 'હમણાં'.tr;

    final (typeIcon, typeColor, typeBg) = _getVisitorTypeMeta(rawPurpose);

    final (statusLabel, statusColor, statusBg, statusDotColor) = switch (status) {
      'approved' => (
        'sec_filter_inside'.tr,
        const Color(0xFF047857),
        const Color(0xFFECFDF5),
        const Color(0xFF10B981)
      ),
      'rejected' => (
        'analytics_rejected'.tr,
        const Color(0xFFB91C1C),
        const Color(0xFFFEF2F2),
        const Color(0xFFEF4444)
      ),
      'checked_out' => (
        'sec_filter_out'.tr,
        const Color(0xFF0F766E),
        const Color(0xFFF0FDFA),
        const Color(0xFF14B8A6)
      ),
      _ => (
        'sec_filter_at_gate'.tr,
        const Color(0xFFB45309),
        const Color(0xFFFFFBEB),
        const Color(0xFFF59E0B)
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'pending'
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
          width: status == 'pending' ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: status == 'pending'
                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                : const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAdminVisitorDetailSheet(context, d, doc.id),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Avatar + Visitor Details + Call & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle Avatar with clean border
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => _buildStyledVisitorFallbackAvatar(name, typeColor, typeBg, typeIcon),
                              )
                            : _buildStyledVisitorFallbackAvatar(name, typeColor, typeBg, typeIcon),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name, Purpose Pill & Entry Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: typeColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, size: 11, color: typeColor),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      localizedPurpose,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: typeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 11, color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Text(
                                    status == 'checked_out' && exitTs != null
                                        ? '${DateFormat('hh:mm a').format(exitTs.toDate())} (${'sec_filter_out'.tr})'
                                        : timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions: Call button & Status Pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (phone.isNotEmpty) ...[
                          InkWell(
                            onTap: () => _makePhoneCall(phone),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF059669)),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusDotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Host Member & Destination Unit Strip (Clear, Structured Data)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          size: 14,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                            ),
                            children: [
                              TextSpan(
                                text: '${'visiting_member_host'.tr}: ',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (memberName.isNotEmpty) ...[
                                TextSpan(
                                  text: memberName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' • ',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              TextSpan(
                                text: destFlatStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (vehicle.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_car_filled_rounded, size: 10.5, color: Color(0xFF475569)),
                              const SizedBox(width: 3),
                              Text(
                                vehicle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Purpose metadata resolver (Icon, Color, Light Background)
  (IconData, Color, Color) _getVisitorTypeMeta(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('delivery') ||
        p.contains('courier') ||
        p.contains('amazon') ||
        p.contains('flipkart') ||
        p.contains('zomato') ||
        p.contains('swiggy') ||
        p.contains('parcel') ||
        p.contains('પાર્સલ'.tr) ||
        p.contains('ડિલિવરી'.tr)) {
      return (
        Icons.local_shipping_rounded,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7)
      );
    }
    if (p.contains('cab') ||
        p.contains('taxi') ||
        p.contains('uber') ||
        p.contains('ola') ||
        p.contains('auto') ||
        p.contains('ટેક્સી'.tr) ||
        p.contains('રીક્ષા'.tr)) {
      return (
        Icons.local_taxi_rounded,
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF)
      );
    }
    if (p.contains('service') ||
        p.contains('repair') ||
        p.contains('plumber') ||
        p.contains('electric') ||
        p.contains('maid') ||
        p.contains('કામવાળા'.tr) ||
        p.contains('રીપેરિંગ'.tr)) {
      return (
        Icons.handyman_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFF5F3FF)
      );
    }
    return (
      Icons.people_alt_rounded,
      const Color(0xFF0D9488),
      const Color(0xFFCCFBF1)
    );
  }

  /// Full visitor detail bottom sheet with admin quick controls
  void _showAdminVisitorDetailSheet(
      BuildContext context, Map<String, dynamic> d, String docId) {
    final name = (d['name'] ?? 'મુલાકાતી'.tr).toString();
    final phone = (d['phone'] ?? '').toString().trim();
    final rawPurpose = (d['purpose'] ?? 'મુલાકાત'.tr).toString();
    final localizedPurpose = _getLocalizedVisitorPurpose(rawPurpose);
    final photoUrl = (d['photoUrl'] ?? '').toString().trim();
    final vehicle = (d['vehicleNumber'] ?? d['vehicle'] ?? '').toString().trim();
    final memberName = (d['memberName'] ?? d['hostName'] ?? '').toString().trim();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock =
        rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString().trim();
    final formattedBlock = cleanBlock.isNotEmpty
        ? SocietyService.instance.formatBlockDisplayName(cleanBlock)
        : '';
    final destFlatStr = formattedBlock.isNotEmpty && unit.isNotEmpty
        ? '$formattedBlock • ${'unit'.tr} $unit'
        : (formattedBlock.isNotEmpty
            ? formattedBlock
            : (unit.isNotEmpty ? '${'unit'.tr} $unit' : 'સોસાયટી'.tr));
    final status = (d['status'] ?? 'pending').toString();
    final entryTs = d['entryTime'] as Timestamp?;
    final exitTs = d['exitTime'] as Timestamp?;

    final (statusLabel, statusColor, statusBg) = switch (status) {
      'approved' => ('અંદર છે (Approved)'.tr, const Color(0xFF047857), const Color(0xFFECFDF5)),
      'rejected' => ('નકારેલ (Rejected)'.tr, const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
      'checked_out' =>
        ('બહાર ગયા (Checked Out)'.tr, const Color(0xFF0F766E), const Color(0xFFF0FDFA)),
      _ => ('ગેટ પર (Pending)'.tr, const Color(0xFFB45309), const Color(0xFFFFFBEB)),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _fallbackAdminAvatar(name),
                        )
                      : _fallbackAdminAvatar(name),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        memberName.isNotEmpty
                            ? '${'visiting_member_host'.tr}: $memberName'
                            : destFlatStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.25)),
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
            const SizedBox(height: 18),

            // Key info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _adminVisitorDetailRow('મુલાકાત હેતુ:'.tr, localizedPurpose),
                  if (memberName.isNotEmpty) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _adminVisitorDetailRow('visiting_member_host'.tr, memberName),
                  ],
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _adminVisitorDetailRow('ગંતવ્ય:'.tr, destFlatStr),
                  if (phone.isNotEmpty) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'મોબાઇલ નંબર:'.tr,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600),
                        ),
                        InkWell(
                          onTap: () => _makePhoneCall(phone),
                          child: Row(
                            children: [
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.phone_rounded,
                                  size: 14, color: Color(0xFF059669)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (vehicle.isNotEmpty) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _adminVisitorDetailRow('વાહન નંબર:'.tr, vehicle),
                  ],
                  if (entryTs != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _adminVisitorDetailRow(
                      'પ્રવેશ સમય:'.tr,
                      DateFormat('dd MMM yyyy, hh:mm a').format(entryTs.toDate()),
                    ),
                  ],
                  if (exitTs != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _adminVisitorDetailRow(
                      'બહાર નીકળ્યા:'.tr,
                      DateFormat('dd MMM yyyy, hh:mm a').format(exitTs.toDate()),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Admin Action Buttons
            Row(
              children: [
                if (status != 'checked_out') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _checkOutVisitor(docId, name);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: Text(
                        'બહાર ગયા માર્ક કરો'.tr,
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteVisitor(docId, name);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(
                      'એન્ટ્રી ડિલીટ'.tr,
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminVisitorDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// Admin manual visitor check-out
  Future<void> _checkOutVisitor(String docId, String name) async {
    try {
      await AppFirestore.instance.collection('visitors').doc(docId).update({
        'status': 'checked_out',
        'exitTime': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            content: Text('$name સોસાયટી બહાર ગયા તરીકે માર્ક થયા.'.tr),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ આવી: $e'.tr)),
        );
      }
    }
  }

  /// Admin visitor record deletion with confirmation
  Future<void> _deleteVisitor(String docId, String name) async {
    final confirmed = await PremiumConfirmationDialog.show(
      context,
      title: "મુલાકાતી એન્ટ્રી ડિલીટ".tr,
      message: "શું તમે ખરેખર $name ની એન્ટ્રી ડિલીટ કરવા માંગો છો?".tr,
      icon: Icons.delete_outline_rounded,
      confirmText: "હા, ડિલીટ કરો".tr,
      confirmColor: const Color(0xFFDC2626),
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await AppFirestore.instance.collection('visitors').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color(0xFFDC2626),
              content: Text('એન્ટ્રી સફળતાપૂર્વક ડિલીટ થઈ.'.tr),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ડિલીટ કરવામાં ભૂલ આવી: $e'.tr)),
          );
        }
      }
    }
  }

  /// Categorized action management hub with segmented chips
  Widget _buildCategorizedActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSectionHeader(
          title: "કંટ્રોલ પેનલ & મેનેજમેન્ટ".tr,
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', 'બધા (All)'.tr, Icons.apps_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('security', '🛡️ સુરક્ષા & ગેટ'.tr, Icons.security_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('comm', '📢 સંચાર & સૂચના'.tr, Icons.campaign_rounded),
              const SizedBox(width: 8),
              _buildCategoryChip('admin', '🏢 વહીવટ & સેટઅપ'.tr, Icons.apartment_rounded),
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
        title: AppStrings.get('admin_btn_setup_wizard'),
        subtitle: "આર્કિટેક્ચર & બ્લોક ગોઠવણી".tr,
        icon: Icons.architecture_rounded,
        gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminSetupWizardScreen(
                onSetupComplete: () {
                  Navigator.pop(context);
                  _checkSetupStatus();
                },
                initialSocietyName: _societyName,
                initialArchitectureType: _architectureType,
              ),
            ),
          );
        },
      ),
      (
        category: 'admin',
        title: "સભ્ય સહી પત્રક (PDF)".tr,
        subtitle: "ઠરાવ/કારણ & સહી લિસ્ટ".tr,
        icon: Icons.draw_rounded,
        gradient: [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminMemberSignatureSheetScreen(),
            ),
          );
        },
      ),
      (
        category: 'admin',
        title: "નવી $_architectureType ઉમેરો".tr,
        subtitle: "નવા બ્લોક/ઘર એડ કરો".tr,
        icon: Icons.add_business_rounded,
        gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
        onTap: _showAddBlockDialog,
      ),
      (
        category: 'admin',
        title: AppStrings.get('admin_btn_add_member'),
        subtitle: "મેમ્બર & સ્ટાફ નોંધણી".tr,
        icon: Icons.person_add_alt_1_rounded,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () => _showAddUserDialog(context),
      ),
      (
        category: 'comm',
        title: AppStrings.get('admin_btn_broadcast'),
        subtitle: "તમામને તુરંત સૂચના".tr,
        icon: Icons.campaign_rounded,
        gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => _showNotificationDialog(context),
      ),
      (
        category: 'comm',
        title: "નોટિસ બોર્ડ પોસ્ટ".tr,
        subtitle: "ડિજિટલ પરિપત્ર પબ્લિશ".tr,
        icon: Icons.article_rounded,
        gradient: [const Color(0xFFEA580C), const Color(0xFFC2410C)],
        onTap: () => _showPublishNoticeDialog(context),
      ),
      (
        category: 'comm',
        title: AppStrings.get('admin_btn_complaints'),
        subtitle: "મેમ્બર સમસ્યા & સમાધાન".tr,
        icon: Icons.report_problem_rounded,
        gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => _openComplaints(context),
      ),
      (
        category: 'comm',
        title: AppStrings.get('polls'),
        subtitle: "ડિજિટલ વોટિંગ & પોલ".tr,
        icon: Icons.how_to_vote_rounded,
        gradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPollsScreen()),
        ),
      ),
      (
        category: 'security',
        title: AppStrings.get('admin_btn_visitors'),
        subtitle: "મુલાકાતી એન્ટ્રી વિગત".tr,
        icon: Icons.analytics_rounded,
        gradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        onTap: () => _showVisitorReportDialog(context),
      ),
      (
        category: 'security',
        title: "વોચમેન મેનેજ".tr,
        subtitle: "ડ્યુટી સ્ટેટસ & પિન".tr,
        icon: Icons.security_rounded,
        gradient: [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
        onTap: () => _showWatchmanManageDialog(context),
      ),
      (
        category: 'security',
        title: "ઈમરજન્સી હેલ્પલાઇન".tr,
        subtitle: "પોલીસ, ૧૦૮, ફાયર, પ્લમ્બર".tr,
        icon: Icons.phone_in_talk_rounded,
        gradient: [const Color(0xFFE11D48), const Color(0xFFBE123C)],
        onTap: () => _showEmergencyContactsDialog(context),
      ),
      (
        category: 'security',
        title: AppStrings.get('guard_patrol'),
        subtitle: "વોચમેન QR સ્કેન રિપોર્ટ".tr,
        icon: Icons.shield_moon_rounded,
        gradient: [const Color(0xFF0F172A), const Color(0xFF334155)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPatrolScreen()),
        ),
      ),
      (
        category: 'admin',
        title: "બેંક/UPI સેટિંગ્સ".tr,
        subtitle: "સોસાયટી કલેક્શન QR".tr,
        icon: Icons.account_balance_rounded,
        gradient: [const Color(0xFF059669), const Color(0xFF047857)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
        ),
      ),
      (
        category: 'admin',
        title: "સોસાયટી નકશો".tr,
        subtitle: "ફ્લેટ્સ વિઝ્યુઅલ પ્રિવ્યુ".tr,
        icon: Icons.map_rounded,
        gradient: [const Color(0xFF6366F1), const Color(0xFF4338CA)],
        onTap: _navigateToPreview,
      ),
      (
        category: 'admin',
        title: AppStrings.get('admin_btn_parking'),
        subtitle: "સ્લોટ્સ જનરેટ & કંટ્રોલ".tr,
        icon: Icons.local_parking_rounded,
        gradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminParkingManagementScreen()),
        ),
      ),
      (
        category: 'admin',
        title: AppStrings.get('admin_btn_amenities'),
        subtitle: "વાડી, ક્લબહાઉસ સેટઅપ".tr,
        icon: Icons.domain_rounded,
        gradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAmenitiesScreen()),
        ),
      ),
    ];

    final filtered = _selectedActionCategory == 'all'
        ? allActions
        : allActions.where((a) => a.category == _selectedActionCategory).toList();

    return GridView.builder(
      padding: EdgeInsets.zero,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "analytics_visitor_title".tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "analytics_visitor_subtitle".tr,
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
                      "${'analytics_total_prefix'.tr}: $total",
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
              Row(
                children: [
                  // 📅 Month Dropdown
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime>(
                          value: _analyticsMonth,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 8,
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                          ),
                          items: _analyticsMonthOptions()
                              .map(
                                (m) => DropdownMenuItem<DateTime>(
                                  value: m,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _monthLabel(m),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🏢 Type Dropdown
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _analyticsBlockType,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 8,
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF0D9488),
                              size: 18,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(
                                      Icons.apps_rounded,
                                      size: 13,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'all_the_wings'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Wing',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      size: 13,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'wing'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Street',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(
                                      Icons.signpost_rounded,
                                      size: 13,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'street'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                      label: "analytics_approved".tr,
                      count: approved,
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "analytics_pending".tr,
                      count: pending,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "analytics_rejected".tr,
                      count: rejected,
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInsightStatCard(
                      label: "analytics_checked_out".tr,
                      count: checkedOut,
                      color: const Color(0xFF0D9488),
                      icon: Icons.logout_rounded,
                    ),
                  ),
                ],
              ),
              if (topBlockBars.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  "analytics_top_blocks".tr,
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
        color: Colors.white,
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          AnimatedCountUpText(
            value: count,
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
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _navigateToPreview() async {
    setState(() => _isLoading = true);

    try {
      final sid = SocietyService.instance.societyId;
      // Firestore માંથી બધા બ્લોક્સ (Wings/Streets/Commercial Blocks) મેળવો
      var snapshot = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: sid)
          .get();

      List<Map<String, dynamic>> blocksData = [];
      final seenLogicalNames = <String, int>{};

      for (var doc in snapshot.docs) {
        String bID = doc.id;
        final bData = doc.data();
        final rawName = (bData['name'] ?? (bID.contains('-') ? bID.split('-').last : bID)).toString();
        final normName = SocietyService.instance.normalizeBlockName(rawName);
        if (normName.isEmpty) continue;

        // દરેક બ્લોકના યુનિટ્સની સંખ્યા મેળવો
        var unitsSnapshot = await AppFirestore.instance
            .collection('units')
            .where('societyId', isEqualTo: sid)
            .where('blockName', isEqualTo: bID)
            .get();

        // જો phyBlock થી ના મળે, તો rawName / normName થી પ્રયાસ કરો (backward compatibility)
        if (unitsSnapshot.docs.isEmpty && rawName != bID) {
          unitsSnapshot = await AppFirestore.instance
              .collection('units')
              .where('societyId', isEqualTo: sid)
              .where('blockName', isEqualTo: rawName)
              .get();
        }
        if (unitsSnapshot.docs.isEmpty && normName != rawName) {
          unitsSnapshot = await AppFirestore.instance
              .collection('units')
              .where('societyId', isEqualTo: sid)
              .where('blockName', isEqualTo: normName)
              .get();
        }

        final rawCategory = bData['category']?.toString();
        final bCategory = (rawCategory != null && rawCategory.isNotEmpty)
            ? rawCategory
            : (_architectureType == 'Commercial'
                ? 'commercial'
                : (bID.startsWith('S-') ? 'street' : 'residential'));

        final List<Map<String, dynamic>> unitList = [];
        int maxFloor = 0;
        int minUnit = 9999;
        int maxUnit = 0;

        for (var uDoc in unitsSnapshot.docs) {
          final uData = uDoc.data();
          final floor = (uData['floorNo'] as num?)?.toInt() ?? 0;
          final uNumStr = (uData['unitNumber'] ?? '').toString();
          // સુરક્ષિત રીતે આંકડાકીય ભાગ કાઢવો (દા.ત. 'G-01' -> 1)
          final parsedNum = int.tryParse(uNumStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          if (floor > maxFloor) maxFloor = floor;
          if (parsedNum > maxUnit) maxUnit = parsedNum;
          if (parsedNum < minUnit && parsedNum > 0) minUnit = parsedNum;

          unitList.add({
            'docId': uDoc.id,
            'unitNumber': uNumStr,
            'floorNo': floor,
            'unitType': uData['unitType'] ?? (bCategory == 'commercial' ? 'shop' : 'flat'),
            'areaSqFt': uData['areaSqFt'],
            'isOccupied': uData['isOccupied'] == true,
            'memberId': uData['memberId'],
            'memberIds': uData['memberIds'],
            'blockName': normName,
            'societyId': sid,
            'ownerName': uData['ownerName'],
            'tenantName': uData['tenantName'],
          });
        }

        // અંદાજિત units per floor
        int unitsPerFloor = 0;
        if (maxFloor > 0 && unitsSnapshot.docs.isNotEmpty) {
          unitsPerFloor = unitsSnapshot.docs.length ~/ maxFloor;
        }

        final formattedDisplayName = SocietyService.instance.formatBlockDisplayName(
          normName,
          architectureType: _architectureType,
          category: bCategory,
        );

        if (seenLogicalNames.containsKey(normName)) {
          final existingIndex = seenLogicalNames[normName]!;
          final existingBlock = blocksData[existingIndex];
          final existingUnits = existingBlock['units'] as List<Map<String, dynamic>>;
          for (final u in unitList) {
            if (!existingUnits.any((eu) => eu['unitNumber'] == u['unitNumber'])) {
              existingUnits.add(u);
            }
          }
          continue;
        }

        seenLogicalNames[normName] = blocksData.length;
        blocksData.add({
          'name': normName,
          'id': bID,
          'displayName': (bData['displayName'] != null && (bData['displayName'] as String).isNotEmpty)
              ? bData['displayName']
              : formattedDisplayName,
          'category': bCategory,
          'units': unitList, // ડાયનેમિક યુનિટ્સ લિસ્ટ
          'v1': _architectureType == 'Wing' ? maxFloor : (minUnit == 9999 ? 1 : minUnit),
          'v2': _architectureType == 'Wing' ? unitsPerFloor : maxUnit,
        });
      }

      // Ground floor ('G') always comes first in preview
      blocksData.sort((a, b) {
        final nameA = (a['name'] ?? '').toString();
        final nameB = (b['name'] ?? '').toString();
        if (SocietyService.instance.isGroundBlock(nameA)) return -1;
        if (SocietyService.instance.isGroundBlock(nameB)) return 1;
        return nameA.compareTo(nameB);
      });

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text("Error: $e"),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                Text(
                  "હજુ સુધી કોઈ મેમ્બર્સ ઉમેરાયા નથી".tr,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "સોસાયટીના ફ્લેટ માલિકો અને ભાડૂતોની નોંધણી કરો.".tr,
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
                  label: Text(
                    "નવા મેમ્બર ઉમેરો".tr,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }

        var docs = snap.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            final rawUid = d['uid']?.toString().trim();
            String mId = (rawUid != null && rawUid.isNotEmpty) ? rawUid : docs[i].id;
            String mName = d['name'] ?? "No Name";
            String rawBlock = (d['blockName'] ?? "").toString();
            String cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
            String mBlock = cleanBlock.isNotEmpty
                ? SocietyService.instance.formatBlockDisplayName(cleanBlock)
                : '';
            String mUnit = (d['unitNumber'] ?? "").toString().trim();
            final flatStr = mBlock.isNotEmpty && mUnit.isNotEmpty
                ? "$mBlock • ${'unit'.tr} $mUnit"
                : (mBlock.isNotEmpty ? mBlock : (mUnit.isNotEmpty ? "${'unit'.tr} $mUnit" : ''));
            String mPhone = (d['phone'] ?? "").toString().trim();
            String mEmail = (d['email'] ?? "").toString().trim();

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
                            if (flatStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  flatStr,
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
                              : (mEmail.isNotEmpty ? mEmail : 'કોઈ સંપર્ક નથી'.tr),
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
                    tooltip: '',
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 10,
                    shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                    ),
                    offset: const Offset(0, 42),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF475569),
                        size: 18,
                      ),
                    ),
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
                      PopupMenuItem<String>(
                        value: 'transfer',
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'assign_the_post_of_president'.tr,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'transfer_admin_leadership'.tr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'notify',
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'send_a_notification'.tr,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'send_personal_alert_to_member'.tr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  void _confirmTransfer(String newAdminId, String name) async {
    final confirmed = await PremiumConfirmationDialog.show(
      context,
      title: "એડમિન સત્તા સોંપણી".tr,
      message:
          "શું તમે ખરેખર $name ને સોસાયટીના નવા પ્રમુખ બનાવવા માંગો છો? આ કર્યા પછી તમારી એડમિન સત્તા જતી રહેશે અને તમારો રોલ મેમ્બર થઈ જશે.".tr,
      icon: Icons.admin_panel_settings_rounded,
      gradientColors: const [Color(0xFFD97706), Color(0xFFB45309)],
      cancelText: "ના, રદ કરો".tr,
      confirmText: "હા, સત્તા સોંપો".tr,
      confirmGradient: const [Color(0xFFDC2626), Color(0xFFB91C1C)],
      confirmColor: const Color(0xFFDC2626),
      isDestructive: true,
    );
    if (confirmed == true) {
      _transferOwnership(newAdminId);
    }
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
        SnackBar(
          content: Text("માલિકી સફળતાપૂર્વક બદલાઈ ગઈ છે!".tr),
          backgroundColor: Colors.green,
        ),
      );

      // એડમિન પેનલમાંથી બહાર કાઢીને લોગિન પર મોકલી દેવા
      if (mounted) {
        await SessionGuardService.performAppLogout(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ આવી: $e".tr), backgroundColor: Colors.red),
      );
    }
  }
}
