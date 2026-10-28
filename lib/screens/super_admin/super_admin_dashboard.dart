import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/super_admin_models.dart';
import '../../services/super_admin_service.dart';
import '../../services/society_service.dart';
import '../../services/session_guard_service.dart';
import '../../services/notification_service.dart';
import '../admin/admin_dashboard.dart';
import 'super_admin_create_admin_screen.dart';
import 'super_admin_onboard_society_screen.dart';
import 'super_admin_broadcast_screen.dart';
import 'super_admin_appeal_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_firestore.dart';
import '../../services/society_appeal_service.dart';
import '../../widgets/admin_credentials_modal.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/animated_bottom_nav_bar.dart';
import '../../widgets/premium_ui.dart';


class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  final SuperAdminService _service = SuperAdminService.instance;
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  late TabController _tabController;
  int _currentTabIndex = 0;
  bool _isLoading = true;

  GlobalPlatformStats _stats = GlobalPlatformStats.empty();
  List<SocietyOverview> _allSocieties = [];
  List<SuperAdminUserItem> _allUsers = [];

  // ફિલ્ટર્સ
  String _socSearchQuery = '';
  String _selectedArchFilter = 'all';

  String _userSearchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadAllData();
    unawaited(NotificationService.instance.ensureTokenRegistered());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final statsFuture = _service.fetchGlobalStats();
      final socsFuture = _service.fetchSocietiesList();
      final usersFuture = _service.fetchUsersList();

      final results = await Future.wait([statsFuture, socsFuture, usersFuture]);

      if (mounted) {
        setState(() {
          _stats = results[0] as GlobalPlatformStats;
          _allSocieties = results[1] as List<SocietyOverview>;
          _allUsers = results[2] as List<SuperAdminUserItem>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SocietyOverview> get _filteredSocieties {
    return _allSocieties.where((soc) {
      if (_selectedArchFilter != 'all') {
        final arch = soc.architectureType.toLowerCase();
        if (_selectedArchFilter == 'commercial' &&
            arch != 'commercial' &&
            arch != 'shopping' &&
            arch != 'mall') {
          return false;
        }
        if (_selectedArchFilter == 'mixed' && arch != 'mixed') return false;
        if (_selectedArchFilter == 'street' &&
            arch != 'street' &&
            arch != 'rowhouse' &&
            arch != 'bungalow') {
          return false;
        }
        if (_selectedArchFilter == 'wing' &&
            arch != 'wing' &&
            arch != 'flat' &&
            arch != 'apartment') {
          return false;
        }
      }

      if (_socSearchQuery.isNotEmpty) {
        final q = _socSearchQuery.toLowerCase();
        final matches = soc.name.toLowerCase().contains(q) ||
            soc.city.toLowerCase().contains(q) ||
            soc.adminName.toLowerCase().contains(q) ||
            soc.adminPhone.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  List<SuperAdminUserItem> get _filteredUsers {
    return _allUsers.where((u) {
      if (_selectedRoleFilter != 'all') {
        if (u.role.toLowerCase() != _selectedRoleFilter.toLowerCase()) return false;
      }
      if (_userSearchQuery.isNotEmpty) {
        final q = _userSearchQuery.toLowerCase();
        final matches = u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q) ||
            u.societyName.toLowerCase().contains(q) ||
            (u.unitNumber ?? '').toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF14B8A6),
          surface: Color(0xFF111827),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14), // Deep Midnight Obsidian
        drawer: const AppNavigationDrawer(role: 'super_admin', isDark: true),
        extendBody: true,
        bottomNavigationBar: FloatingGlassmorphicNavBar(
          currentIndex: _currentTabIndex,
          isDark: true,
          primaryColor: const Color(0xFF14B8A6),
          onTap: (index) {
            _tabController.animateTo(index);
            setState(() => _currentTabIndex = index);
          },
          items: [
            FloatingNavItem(
              icon: Icons.domain_outlined,
              activeIcon: Icons.domain_rounded,
              label: 'સોસાયટી'.tr,
            ),
            FloatingNavItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'યુઝર્સ'.tr,
            ),
            FloatingNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: 'ઓડિટ'.tr,
            ),
            FloatingNavItem(
              icon: Icons.shield_outlined,
              activeIcon: Icons.shield_rounded,
              label: 'ઓપરેશન્સ'.tr,
            ),
          ],
        ),
        body: Stack(
        children: [
          // Ambient Glow Effect (Cyber Mint top left, Royal Gold top right)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildExecutiveAppBar(),
                  _buildPendingAppealsLiveBannerSliver(),
                  _buildKpiDeckSliver(),
                  _buildFloatingTabBarSliver(),
                ];
              },
              body: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSocietiesTab(),
                        _buildUsersTab(),
                        _buildFinanceAuditTab(),
                        _buildSuperActionsTab(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ==========================================
  // ૧. એક્ઝિક્યુટિવ ટોપ હેડર બાર (App Bar)
  // ==========================================
  Widget _buildExecutiveAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            // ગોલ્ડન ક્રાઉન લોગો વિથ ગ્લો
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),

            // ટાઈટલ અને પ્લેટફોર્મ પલ્સ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "SUPER ADMIN",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: const Text(
                          "PRO",
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          "LIVE ENGINE • કમાન્ડ સેન્ટર".tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // નોટિફિકેશન બેલ બટન (લાઇવ અપીલ & એડમિન સૂચનાઓ)
            // નોટિફિકેશન બેલ બટન (લાઇવ અપીલ & એડમિન સૂચનાઓ)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SocietyAppealService.instance.streamAllAppeals(),
              builder: (context, snap) {
                final allAppeals = snap.data ?? [];
                final count = allAppeals.where((a) => a['status'] == 'pending').length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'સૂચનાઓ & અપીલ્સ'.tr,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: count > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      icon: Icon(
                        count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        size: 19,
                        color: count > 0 ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                      ),
                      onPressed: _showAppealsListDialog,
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 5),

            // રીફ્રેશ બટન
            IconButton(
              tooltip: 'ડેટા રિફ્રેશ કરો'.tr,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 19, color: Color(0xFF38BDF8)),
              onPressed: _loadAllData,
            ),
            const SizedBox(width: 5),

            // Multi-language switch button (GU / HI / EN)
            const LanguageSwitchButton(isDark: true),
            const SizedBox(width: 5),

            // લૉગઆઉટ બટન
            IconButton(
              tooltip: 'લૉગઆઉટ'.tr,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19, color: Color(0xFFF87171)),
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ૧.૧ લાઇવ પેન્ડિંગ અપીલ બેનર (Pending Appeals Live Alert Banner)
  // ==========================================
  Widget _buildPendingAppealsLiveBannerSliver() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SocietyAppealService.instance.streamAllAppeals(),
        builder: (context, snap) {
          final allAppeals = snap.data ?? [];
          final pendingAppeals = allAppeals.where((a) => a['status'] == 'pending').toList();
          if (pendingAppeals.isEmpty) return const SizedBox.shrink();

          final count = pendingAppeals.length;
          final latest = pendingAppeals.first;
          final socName = (latest['societyName'] ?? 'સોસાયટી'.tr).toString();
          final admName = (latest['adminName'] ?? 'એડમિન'.tr).toString();
          final appealId = (latest['appealId'] ?? latest['docId'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: InkWell(
              onTap: () {
                if (count == 1 && appealId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuperAdminAppealDetailScreen(
                        appealId: appealId,
                        initialData: latest,
                      ),
                    ),
                  );
                } else {
                  _showAppealsListDialog();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF78350F), Color(0xFF451A03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFBBF24), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const PulsingStatusDot(color: Color(0xFFFBBF24), size: 7),
                              const SizedBox(width: 7),
                              Text(
                                "પેન્ડિંગ પુનઃસક્રિયતા અપીલ ($count)".tr,
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "$socName ($admName) ${'appeal_notif_suffix'.tr}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "રિવ્યુ કરો".tr,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // ૨. એક્ઝિક્યુટિવ કેપીઆઈ ડેક (Hero KPI Deck)
  // ==========================================
  Widget _buildKpiDeckSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              StaggeredEntrance(
                index: 0,
                child: _buildBentoKpiCard(
                  title: "કુલ કલેક્શન વોલ્યુમ".tr,
                  value: _currency.format(_stats.totalPlatformCollected.toInt()),
                  trend: "આ મહિને જમા".tr,
                  icon: Icons.currency_rupee_rounded,
                  gradient: const [Color(0xFF0F766E), Color(0xFF042F2E)],
                  accentColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 10),
              StaggeredEntrance(
                index: 1,
                child: _buildBentoKpiCard(
                  title: "રજિસ્ટર્ડ પરિસરો".tr,
                  value: "${_stats.totalSocieties} ${'complexes_label'.tr}",
                  trend: "${_allSocieties.where((s) => s.isActive).length} ${'active'.tr}",
                  icon: Icons.apartment_rounded,
                  gradient: const [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  accentColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              StaggeredEntrance(
                index: 2,
                child: _buildBentoKpiCard(
                  title: "કુલ યુઝર્સ & સભ્યો".tr,
                  value: "${_stats.totalMembers} ${'label_members'.tr}",
                  trend: "${_stats.totalAdmins} ${'admins_label'.tr}",
                  icon: Icons.groups_rounded,
                  gradient: const [Color(0xFF581C87), Color(0xFF1E1B4B)],
                  accentColor: const Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(width: 10),
              StaggeredEntrance(
                index: 3,
                child: _buildBentoKpiCard(
                  title: "ગેટ સિક્યોરિટી પલ્સ".tr,
                  value: "${_stats.todayTotalVisitors} ${'visitors_label'.tr}",
                  trend: "${_stats.totalWatchmen} ${'guards_on_duty_label'.tr}",
                  icon: Icons.shield_rounded,
                  gradient: const [Color(0xFF78350F), Color(0xFF1C1917)],
                  accentColor: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoKpiCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required List<Color> gradient,
    required Color accentColor,
  }) {
    return InteractiveBounce(
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 11, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ૩. ફ્લોટિંગ સેગમેન્ટેડ ટેબ બાર (Custom Capsule)
  // ==========================================
  Widget _buildFloatingTabBarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CustomHeaderDelegate(
        child: Container(
          color: const Color(0xFF070B14),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSegmentTabItem(0, "પરિસરો".tr, Icons.apartment_rounded, "${_allSocieties.length}"),
                _buildSegmentTabItem(1, "યુઝર્સ".tr, Icons.groups_rounded, "${_allUsers.length}"),
                _buildSegmentTabItem(2, "ફાઇનાન્સ".tr, Icons.insights_rounded, null),
                _buildSegmentTabItem(3, "પાવર્સ".tr, Icons.bolt_rounded, null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTabItem(int index, String label, IconData icon, String? badge) {
    final bool isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ટેબ ૧: પરિસર લિસ્ટ & મોનિટરિંગ (Societies Tab)
  // ==========================================
  Widget _buildSocietiesTab() {
    final list = _filteredSocieties;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // સર્ચ બાર
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _socSearchQuery = val),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
            cursorColor: const Color(0xFF38BDF8),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF111827),
              hintText: 'પરિસર, શહેર, એડમિન કે ફોન શોધો...'.tr,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // આર્કિટેક્ચર ફિલ્ટર ચિપ્સ
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildArchFilterPill('all', '${'all_premises_label'.tr} (${_allSocieties.length})'),
              _buildArchFilterPill('commercial', '🛍️ કોમર્શિયલ મોલ'.tr),
              _buildArchFilterPill('mixed', '🏙️ મિક્સ્ડ કોમ્પ્લેક્સ'.tr),
              _buildArchFilterPill('wing', '🏢 રેસિડેન્શિયલ'.tr),
              _buildArchFilterPill('street', '🏡 સોસાયટી / બંગલો'.tr),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (list.isEmpty)
          _buildEmptyState("કોઈ પરિસર મળ્યું નથી".tr, "સર્ચ ક્વેરી અથવા ફિલ્ટર બદલીને પ્રયાસ કરો.".tr)
        else
          ...List.generate(
            list.length,
            (i) => StaggeredEntrance(
              index: i,
              child: _buildLuxurySocietyCard(list[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildArchFilterPill(String key, String label) {
    final isSelected = _selectedArchFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedArchFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)])
              : null,
          color: isSelected ? null : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildLuxurySocietyCard(SocietyOverview soc) {
    final bool isCommercial = soc.architectureType.toLowerCase() == 'commercial';
    final bool isMixed = soc.architectureType.toLowerCase() == 'mixed';
    final bool isStreet = soc.architectureType.toLowerCase() == 'street';

    final Color badgeColor = isCommercial
        ? const Color(0xFFF59E0B)
        : (isMixed
            ? const Color(0xFFA855F7)
            : (isStreet ? const Color(0xFF10B981) : const Color(0xFF38BDF8)));

    final String badgeText = isCommercial
        ? "🛍️ કોમર્શિયલ મોલ".tr
        : (isMixed
            ? "🏙️ મિક્સ્ડ સંકુલ".tr
            : (isStreet ? "🏡 બંગલો સોસાયટી".tr : "🏢 ફ્લેટ ટાવર".tr));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: soc.isActive ? Colors.white.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // હેડર પટ્ટી
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              children: [
                // આર્કિટેક્ચર બેજ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
                const Spacer(),

                // સક્રિય / સ્થગિત સ્વિચ
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: soc.isActive ? const Color(0xFF10B981) : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (soc.isActive ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      soc.isActive ? "કાર્યરત".tr : "ફ્રીઝ્ડ".tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: soc.isActive ? const Color(0xFF34D399) : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: soc.isActive,
                        activeTrackColor: const Color(0xFF14B8A6),
                        inactiveThumbColor: Colors.redAccent,
                        onChanged: (val) => _confirmToggleSociety(soc, val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // સોસાયટી નામ & લોકેશન
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soc.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17.5, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      "${soc.city} • ${'registered_on'.tr}: ${DateFormat('dd MMM yyyy').format(soc.createdAt)}",
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ૪-સેલ હાઈ-ટેક મેટ્રિક્સ ગ્રીડ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF090E1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  _buildMicroGridItem("એકમો".tr, "${soc.totalUnits}", Icons.tag_rounded, const Color(0xFF38BDF8)),
                  _buildDividerLine(),
                  _buildMicroGridItem("સભ્યો".tr, "${soc.totalMembers}", Icons.person_rounded, const Color(0xFFA78BFA)),
                  _buildDividerLine(),
                  _buildMicroGridItem("ગાર્ડ્સ".tr, "${soc.totalWatchmen}", Icons.shield_rounded, const Color(0xFFFBBF24)),
                  _buildDividerLine(),
                  _buildMicroGridItem(
                    "કલેક્શન".tr,
                    _currency.format(soc.totalCollectedMonth.toInt()),
                    Icons.currency_rupee_rounded,
                    const Color(0xFF34D399),
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // એડમિન સંપર્ક પટ્ટી
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${'admins_label'.tr}: ${soc.adminName} (${soc.adminPhone})",
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _launchCall(soc.adminPhone),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: Color(0xFF34D399)),
                          SizedBox(width: 4),
                          Text("કોલ".tr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF34D399))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showSendNotificationModal(
                      societyId: soc.id,
                      societyName: soc.name,
                      adminUid: soc.adminUid,
                      recipientName: soc.adminName,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_rounded, size: 12, color: Color(0xFF38BDF8)),
                          SizedBox(width: 4),
                          Text("નોટિસ".tr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ડ્યુઅલ એક્શન બટન પટ્ટી (View As Admin & Audit)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSocietyInspectionSheet(soc),
                    icon: const Icon(Icons.analytics_rounded, size: 15),
                    label: Text("સંપૂર્ણ કુંડળી".tr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _shadowLogin(soc),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 15),
                    label: Text("View As Admin", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroGridItem(String label, String value, IconData icon, Color color, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: isHighlight ? const Color(0xFF34D399) : Colors.white,
              ),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildDividerLine() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ==========================================
  // ટેબ ૨: યુઝર્સ & રોલ્સ ડિરેક્ટરી (Users Tab)
  // ==========================================
  Widget _buildUsersTab() {
    final list = _filteredUsers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // સર્ચ બાર
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _userSearchQuery = val),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
            cursorColor: const Color(0xFF38BDF8),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF111827),
              hintText: 'નામ, ફોન, ઈમેલ કે એકમ નંબર શોધો...'.tr,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // રોલ ફિલ્ટર ચિપ્સ
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildUserRoleChip("બધા (${_allUsers.length})".tr, 'all'),
              _buildUserRoleChip("👑 સુપર એડમિન".tr, 'super_admin'),
              _buildUserRoleChip("💼 એડમિન (${_stats.totalAdmins})".tr, 'admin'),
              _buildUserRoleChip("🛡️ વોચમેન (${_stats.totalWatchmen})".tr, 'watchman'),
              _buildUserRoleChip("🏢 સબ-એડમિન (${_stats.totalSubAdmins})".tr, 'wing_admin'),
              _buildUserRoleChip("👥 સભ્યો (${_stats.totalMembers})".tr, 'member'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (list.isEmpty)
          _buildEmptyState("કોઈ યુઝર મળ્યા નથી".tr, "સર્ચ ક્વેરી અથવા રોલ ફિલ્ટર બદલીને પ્રયાસ કરો.".tr)
        else
          ...List.generate(
            list.length,
            (i) => StaggeredEntrance(
              index: i,
              child: _buildLuxuryUserCard(list[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildUserRoleChip(String label, String roleKey) {
    final isSelected = _selectedRoleFilter == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)])
              : null,
          color: isSelected ? null : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryUserCard(SuperAdminUserItem u) {
    Color roleColor;
    String roleName;
    IconData roleIcon;

    final isSuper = u.role.toLowerCase() == 'super_admin' || u.role.toLowerCase() == 'superadmin';

    switch (u.role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        roleColor = const Color(0xFFF59E0B);
        roleName = '👑 સુપર એડમિન'.tr;
        roleIcon = Icons.workspace_premium_rounded;
        break;
      case 'admin':
        roleColor = const Color(0xFFF59E0B);
        roleName = 'મુખ્ય એડમિન'.tr;
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case 'watchman':
        roleColor = const Color(0xFF10B981);
        roleName = 'સિક્યોરિટી ગાર્ડ'.tr;
        roleIcon = Icons.shield_rounded;
        break;
      case 'wing_admin':
      case 'sub_admin':
        roleColor = const Color(0xFF38BDF8);
        roleName = 'સબ-એડમિન'.tr;
        roleIcon = Icons.supervised_user_circle_rounded;
        break;
      default:
        roleColor = const Color(0xFF94A3B8);
        roleName = 'સભ્ય / માલિક'.tr;
        roleIcon = Icons.person_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSuper
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (u.isActive ? Colors.white.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.4)),
          width: isSuper ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // અવતાર વિથ રોલ રિંગ
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.15),
              border: Border.all(color: roleColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Center(
              child: Icon(roleIcon, size: 22, color: roleColor),
            ),
          ),
          const SizedBox(width: 12),

          // વિગતો
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleName,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "📱 ${u.phone} • ✉️ ${u.email}",
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "🏬 ${u.societyName}${u.unitNumber != null ? ' (એકમ: ${u.unitNumber})' : ''}".tr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF14B8A6), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // એક્ટિવ/બ્લોક બટન
          IconButton(
            tooltip: u.isActive ? 'યુઝર બ્લોક કરો'.tr : 'યુઝર એક્ટિવ કરો'.tr,
            icon: Icon(
              u.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
              color: u.isActive ? const Color(0xFF34D399) : Colors.redAccent,
              size: 22,
            ),
            onPressed: () => _toggleUserActive(u),
          ),

          // વિકલ્પો મેનુ (Promote / Revoke)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'promote') {
                _confirmPromoteSuperAdmin(u);
              } else if (val == 'revoke') {
                _confirmRevokeSuperAdmin(u);
              } else if (val == 'call') {
                _launchCall(u.phone);
              } else if (val == 'notify') {
                _showSendNotificationModal(
                  societyId: u.societyId,
                  societyName: u.societyName,
                  adminUid: u.uid,
                  recipientName: u.name,
                  canTargetWholeSociety: false,
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'notify',
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Text("નોટિફિકેશન / નોટિસ મોકલો".tr, style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: Color(0xFF34D399), size: 18),
                    const SizedBox(width: 8),
                    Text("કોલ કરો (${u.phone})".tr, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              if (!isSuper)
                PopupMenuItem(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 8),
                      Text("👑 સુપર એડમિન બનાવો".tr, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'revoke',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text("સુપર એડમિન સત્તા રદ્દ કરો".tr, style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ટેબ ૩: ગ્લોબલ ફાઇનાન્સ & ઓડિટ (Finance Tab)
  // ==========================================
  Widget _buildFinanceAuditTab() {
    final double billed = _stats.totalPlatformBilled;
    final double collected = _stats.totalPlatformCollected;
    final double pending = _stats.totalPlatformPending;
    final double pct = billed > 0 ? (collected / billed * 100).clamp(0.0, 100.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // ૧. પ્લેટફોર્મ રેવેન્યુ ડેશબોર્ડ (Hero Revenue Hub)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF042F2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "પ્લેટફોર્મ મેન્ટેનન્સ હિસાબ (કુલ વોલ્યુમ)".tr,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialStat("કુલ બિલિંગ".tr, _currency.format(billed.toInt()), Colors.white70),
                  _buildFinancialStat("કુલ જમા થયેલ".tr, _currency.format(collected.toInt()), const Color(0xFF34D399)),
                  _buildFinancialStat("કુલ બાકી રકમ".tr, _currency.format(pending.toInt()), const Color(0xFFF87171)),
                ],
              ),
              const SizedBox(height: 16),

              // પ્રોગ્રેસ બાર
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${'avg_recovery_rate'.tr}: ${pct.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w700)),
                  Text("૧૦૦% સિક્યોર્ડ ડેટાબેઝ".tr, style: const TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ૨. ૧૮% GST સમરી કાર્ડ
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Text("૧૮% GST ઇન્વોઇસિંગ સમરી (કોમર્શિયલ)".tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              _buildAuditRow("કુલ GST વસૂલાત".tr, _currency.format(_stats.totalPlatformGst.toInt()), color: const Color(0xFFFBBF24)),
              _buildAuditRow("CGST (૯%)".tr, _currency.format((_stats.totalPlatformGst / 2).toInt())),
              _buildAuditRow("SGST (૯%)".tr, _currency.format((_stats.totalPlatformGst / 2).toInt())),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ૩. ગેટ સિક્યોરિટી અને કમ્પ્લેઇન્ટ્સ પલ્સ
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  Text("પ્લેટફોર્મ ગેટ & સિક્યોરિટી પલ્સ".tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              _buildAuditRow("આજની કુલ વિઝિટર એન્ટ્રીઓ".tr, "${_stats.todayTotalVisitors} ${'guests_label'.tr}", color: const Color(0xFF38BDF8)),
              _buildAuditRow("કુલ ઓન-ડ્યુટી સિક્યોરિટી ગાર્ડ્સ".tr, "${_stats.totalWatchmen} ${'guards_label'.tr}"),
              _buildAuditRow("કુલ પેન્ડિંગ સોસાયટી ફરિયાદો".tr, "${(_stats.totalComplaints - _stats.resolvedComplaints).clamp(0, 999999)} ${'complaints_label'.tr}", color: const Color(0xFFF87171)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildAuditRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color ?? Colors.white)),
        ],
      ),
    );
  }

  // ==========================================
  // ટેબ ૪: સુપર એક્શન્સ (Super Admin Powers Tab)
  // ==========================================
  Widget _buildSuperActionsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _buildActionTile(
          title: "સોસાયટી અપીલ વિનંતીઓ (Appeals & Reviews)".tr,
          subtitle: "સ્થગિત સોસાયટીના એડમિન તરફથી આવેલી પુનઃસક્રિયતા અપીલો ચકાસો અને નિર્ણય લો".tr,
          icon: Icons.gavel_rounded,
          color: const Color(0xFFEF4444),
          onTap: _showAppealsListDialog,
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          title: "નવા કો-સુપર એડમિન બનાવો (Co-Super Admin)".tr,
          subtitle: "તમારા પાર્ટનર કે ઓપરેશન્સ મેનેજરને સંપૂર્ણ માસ્ટર એક્સેસ આપો".tr,
          icon: Icons.person_add_alt_1_rounded,
          color: const Color(0xFFF59E0B),
          onTap: _showCreateSuperAdminDialog,
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          title: "નવી સોસાયટી ઓનબોર્ડ કરો (1-Click Setup)".tr,
          subtitle: "નવું પરિસર બનાવીને ચેરમેન/સેક્રેટરીનો એડમિન પાસવર્ડ સેટ કરો".tr,
          icon: Icons.add_business_rounded,
          color: const Color(0xFF14B8A6),
          onTap: _showOnboardSocietyDialog,
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          title: "ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ (Global Notice)".tr,
          subtitle: "તમામ સોસાયટીના એડમિનો અથવા મેમ્બર્સને ઓફિશિયલ સૂચના મોકલો".tr,
          icon: Icons.campaign_rounded,
          color: const Color(0xFF38BDF8),
          onTap: _showGlobalBroadcastDialog,
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          title: "સિસ્ટમ કેશ ક્લીન & ડેટા રિફ્રેશ".tr,
          subtitle: "તમામ સોસાયટીઓ અને યુઝર્સનો ડેટાબેઝ કેશ ફરીથી સિંક કરો".tr,
          icon: Icons.cloud_sync_rounded,
          color: const Color(0xFFA855F7),
          onTap: () {
            _loadAllData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Color(0xFF0F766E),
                content: Text("સિસ્ટમ કેશ રિફ્રેશ સફળ થઈ ગઈ છે!".tr),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // મોડલ શીટ્સ અને ડાયલોગ્સ (Ultra-Sleek)
  // ==========================================

  // ૧. સોસાયટી સંપૂર્ણ કુંડળી ઇન્સ્પેક્શન શીટ
  void _showSocietyInspectionSheet(SocietyOverview soc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                soc.name,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
              ),
              Text(
                "આર્કિટેક્ચર: ${soc.architectureType} • શહેર: ${soc.city}".tr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF14B8A6), fontWeight: FontWeight.w600),
              ),
              const Divider(color: Colors.white12, height: 24),

              _buildInspectionRow("સોસાયટી આઈડી".tr, soc.id),
              _buildInspectionRow("મુખ્ય એડમિન".tr, "${soc.adminName} (${soc.adminPhone})"),
              _buildInspectionRow("એડમિન ઈમેલ".tr, soc.adminEmail),
              _buildInspectionRow("કુલ એકમો".tr, "${soc.totalUnits} ${'units_suffix'.tr}"),
              _buildInspectionRow("સભ્યો સંખ્યા".tr, "${soc.totalMembers} ${'members_suffix'.tr}"),
              _buildInspectionRow("સિક્યોરિટી સ્ટાફ".tr, "${soc.totalWatchmen} ${'guards_suffix'.tr}"),
              _buildInspectionRow("ચાલુ મહિને બિલિંગ".tr, _currency.format(soc.totalBilledMonth.toInt())),
              _buildInspectionRow("ચાલુ મહિને કલેક્શન".tr, _currency.format(soc.totalCollectedMonth.toInt())),
              _buildInspectionRow("પેન્ડિંગ ફરિયાદો".tr, "${soc.pendingComplaints} ${'complaints_suffix'.tr}"),
              _buildInspectionRow("સ્ટેટસ".tr, soc.isActive ? "એક્ટિવ (ચાલુ)".tr : "સસ્પેન્ડેડ (ફ્રીઝ)".tr),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shadowLogin(soc);
                  },
                  icon: const Icon(Icons.remove_red_eye_rounded),
                  label: Text("આ સોસાયટીમાં એડમિન તરીકે પ્રવેશ કરો (View As Admin)".tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AdminCredentialsModal.show(
                      context,
                      result: OnboardSocietyResult(
                        societyId: soc.id,
                        adminUid: 'admin_${soc.id}',
                        societyName: soc.name,
                        architectureType: soc.architectureType,
                        city: soc.city,
                        adminName: soc.adminName,
                        adminEmail: soc.adminEmail,
                        adminPassword: '••••••••',
                        adminPhone: soc.adminPhone,
                        totalUnits: soc.totalUnits,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 18),
                  label: Text(
                    "એડમિન ક્રેડેન્શિયલ્સ મોકલો (Email / WhatsApp)".tr,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSendNotificationModal(
                      societyId: soc.id,
                      societyName: soc.name,
                      adminUid: soc.adminUid,
                      recipientName: soc.adminName,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    "એડમિનને ડાયરેક્ટ નોટિફિકેશન મોકલો (Notify Admin)".tr,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    try {
                      await SuperAdminService.instance.sendAdminPasswordResetEmail(soc.adminEmail);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0D9488),
                          behavior: SnackBarBehavior.floating,
                          content: Text("🔑 '${soc.adminEmail}' પર પાસવર્ડ રીસેટ લિંક સફળતાપૂર્વક મોકલાઈ ગઈ છે!".tr),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          content: Text("લિંક મોકલવામાં ભૂલ: $e".tr),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF59E0B), size: 18),
                  label: Text(
                    "એડમિનને પાસવર્ડ રીસેટ લિંક મોકલો (Reset Password)".tr,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspectionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.white60)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  /// ચોક્કસ સોસાયટી કે તેના એડમિનને સીધી નોટિફિકેશન મોકલવાનું મોડલ (Send Direct Push Modal)
  void _showSendNotificationModal({
    required String societyId,
    required String societyName,
    String? adminUid,
    String? recipientName,
    bool canTargetWholeSociety = true,
  }) {
    final titleCtrl = TextEditingController(text: 'હેડ ઓફિસ સત્તાવાર સૂચના'.tr);
    final msgCtrl = TextEditingController();
    bool targetAll = false;
    bool isSending = false;

    final List<String> quickPresets = [
      '📊 વાર્ષિક ઓડિટ રિપોર્ટ સબમિટ કરવા બાબત'.tr,
      '⚠️ સિસ્ટમ મેન્ટેનન્સ & સિક્યોરિટી અપડેટ'.tr,
      '📋 એકાઉન્ટ/મેમ્બર ડેટા વેરિફિકેશન સૂચના'.tr,
      '💼 કમિટી મિટિંગ અને ઠરાવ અપલોડ કરવા બાબત'.tr,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: Color(0xFF0284C7), width: 2)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ચોક્કસ સોસાયટી / એડમિનને નોટિફિકેશન".tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "🏢 $societyName ${recipientName != null ? '• 👤 $recipientName' : ''}",
                              style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(bCtx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (canTargetWholeSociety) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                targetAll ? "📢 આખી સોસાયટીના તમામ સભ્યોને".tr : "👤 માત્ર સોસાયટી એડમિનને".tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              Text(
                                targetAll ? "તમામ ફ્લેટ માલિકોને પુશ જશે".tr : "માત્ર કમિટી/એડમિનના ફોનમાં પુશ જશે".tr,
                                style: const TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                            ],
                          ),
                          Switch(
                            value: targetAll,
                            activeTrackColor: const Color(0xFF0284C7),
                            onChanged: (val) => setModalState(() => targetAll = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text("ઝડપી ટેમ્પલેટ:".tr, style: TextStyle(fontSize: 11, color: Colors.white60)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: quickPresets.map((preset) => InkWell(
                      onTap: () {
                        setModalState(() {
                          titleCtrl.text = preset;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(preset, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "સૂચના શીર્ષક *".tr,
                      labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "સંદેશ / વિગત *".tr,
                      labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                      hintText: "સુપર એડમિન તરફથી અગત્યની સૂચના લખો...".tr,
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: isSending ? null : () async {
                        final title = titleCtrl.text.trim();
                        final msg = msgCtrl.text.trim();
                        if (title.isEmpty || msg.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("કૃપા કરીને શીર્ષક અને સંદેશ બંને ભરો.".tr), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        setModalState(() => isSending = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(bCtx);

                        try {
                          await SuperAdminService.instance.sendNotificationToSocietyAdmin(
                            societyId: societyId,
                            societyName: societyName,
                            adminUid: adminUid,
                            title: title,
                            message: msg,
                            targetWholeSociety: targetAll,
                          );
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0284C7),
                              content: Text(
                                targetAll
                                    ? "✅ '$societyName' ના તમામ સભ્યોને નોટિફિકેશન મોકલાઈ ગયું!".tr
                                    : "✅ '$societyName' ના એડમિનને પુશ નોટિફિકેશન સફળતાપૂર્વક મોકલાઈ ગયું!".tr,
                              ),
                            ),
                          );
                        } catch (e) {
                          setModalState(() => isSending = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text("નોટિફિકેશન મોકલવામાં ભૂલ: $e".tr), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isSending ? "મોકલાઈ રહ્યું છે...".tr : "પુશ નોટિફિકેશન મોકલો (Send Push)".tr,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ૨. શેડો લોગિન (View As Admin)
  void _shadowLogin(SocietyOverview soc) {
    SocietyService.instance.bindFromUserMap({
      'societyId': soc.id,
      'societyName': soc.name,
      'architectureType': soc.architectureType,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        content: Text("તમે '${soc.name}' માં એડમિન વ્યુ તરીકે પ્રવેશ કર્યો છે.".tr),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
    );
  }

  // ૩. કિલ-સ્વિચ કન્ફર્મેશન
  void _confirmToggleSociety(SocietyOverview soc, bool newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          newStatus ? "સોસાયટી સક્રિય કરવી છે?".tr : "સોસાયટી ફ્રીઝ (સસ્પેન્ડ) કરવી છે?".tr,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Text(
          newStatus
              ? "'${soc.name}' ફરીથી સક્રિય થશે અને તમામ સભ્યો તથા એડમિન એપ વાપરી શકશે.".tr
              : "'${soc.name}' ફ્રીઝ થશે. કોઈ પણ સભ્ય કે એડમિન એપમાં પ્રવેશ નહીં કરી શકે જ્યાં સુધી તમે ફરી ચાલુ ન કરો.".tr,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("રદ કરો".tr, style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? const Color(0xFF14B8A6) : Colors.redAccent,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.toggleSocietyStatus(soc.id, newStatus);
              _loadAllData();
            },
            child: Text(newStatus ? "હા, સક્રિય કરો".tr : "હા, ફ્રીઝ કરો".tr),
          ),
        ],
      ),
    );
  }

  // ૪. યુઝર બ્લોક/અનબ્લોક
  Future<void> _toggleUserActive(SuperAdminUserItem u) async {
    final newStatus = !u.isActive;
    await _service.toggleUserStatus(u.uid, newStatus);
    _loadAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? "${u.name} સક્રિય થઈ ગયા છે.".tr : "${u.name} ને બ્લોક કર્યા છે.".tr),
        ),
      );
    }
  }

  // ૫. નવી સોસાયટી ઓનબોર્ડિંગ સ્ક્રીન (Executive Full-Screen UI)
  void _showOnboardSocietyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuperAdminOnboardSocietyScreen(
          onSuccess: _loadAllData,
        ),
      ),
    );
  }

  // ૬. ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ સ્ક્રીન (Executive Full-Screen UI)
  void _showGlobalBroadcastDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuperAdminBroadcastScreen(
          onSuccess: _loadAllData,
        ),
      ),
    );
  }

  // ૭. નવા કો-સુપર એડમિન બનાવવાની સ્ક્રીન (Executive Full-Screen UI)
  void _showCreateSuperAdminDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuperAdminCreateAdminScreen(
          onSuccess: _loadAllData,
        ),
      ),
    );
  }

  // ૭.૧ સુપર એડમિન સૂચનાઓ & અપીલ કેન્દ્ર (Super Admin Notification & Appeals Hub)
  void _showAppealsListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'super_admin_notifications_title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Segmented Capsule Tabs
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gavel_rounded, size: 14),
                          const SizedBox(width: 6),
                          Text("society_appeals_tab".tr),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.campaign_rounded, size: 14),
                          const SizedBox(width: 6),
                          Text("admin_messages_tab".tr),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Society Appeals
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: SocietyAppealService.instance.streamAllAppeals(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        final appeals = snap.data ?? [];
                        if (appeals.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_rounded, size: 46, color: Colors.grey.shade600),
                                const SizedBox(height: 10),
                                Text(
                                  "no_pending_appeals_yet".tr,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: appeals.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final item = appeals[i];
                            final sName = (item['societyName'] ?? 'society'.tr).toString();
                            final aName = (item['adminName'] ?? 'admin'.tr).toString();
                            final aPhone = (item['adminPhone'] ?? '').toString();
                            final msg = (item['appealMessage'] ?? '').toString();
                            final status = (item['status'] ?? 'pending').toString();
                            final appealId = (item['appealId'] ?? item['docId'] ?? '').toString();

                            final (statusLabel, statusColor, statusBg) = switch (status) {
                              'resolved' => ('મંજૂર'.tr, const Color(0xFF10B981), const Color(0xFF064E3B)),
                              'rejected' => ('અસ્વીકૃત'.tr, const Color(0xFFEF4444), const Color(0xFF7F1D1D)),
                              _ => ('પેન્ડિંગ'.tr, const Color(0xFFF59E0B), const Color(0xFF78350F)),
                            };

                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SuperAdminAppealDetailScreen(
                                      appealId: appealId,
                                      initialData: item,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${'admins_label'.tr}: $aName ${aPhone.isNotEmpty ? '($aPhone)' : ''}",
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (aPhone.isNotEmpty)
                                          InkWell(
                                            onTap: () => _makePhoneCall(aPhone),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF059669).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.call_rounded, size: 12, color: Color(0xFF34D399)),
                                                  const SizedBox(width: 3),
                                                  Text("call_short".tr, style: const TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      msg,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Tab 2: Admin Direct Notifications
                    StreamBuilder<QuerySnapshot>(
                      stream: AppFirestore.instance
                          .collection('notifications')
                          .where(
                            'targetUID',
                            whereIn: FirebaseAuth.instance.currentUser?.uid != null &&
                                    FirebaseAuth.instance.currentUser!.uid.isNotEmpty
                                ? ['SUPER_ADMIN', FirebaseAuth.instance.currentUser!.uid]
                                : ['SUPER_ADMIN'],
                          )
                          .limit(50)
                          .snapshots(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        if (snap.hasError) {
                          debugPrint('Error loading notifications: ${snap.error}');
                        }
                        final docs = (snap.data?.docs ?? []).toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = aData['createdAt'];
                          final bTime = bData['createdAt'];
                          if (aTime is Timestamp && bTime is Timestamp) {
                            return bTime.compareTo(aTime);
                          }
                          return 0;
                        });

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_off_rounded, size: 46, color: Colors.grey.shade600),
                                const SizedBox(height: 10),
                                Text(
                                  'no_admin_notifications_yet'.tr,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final title = (data['title'] ?? 'સૂચના'.tr).toString();
                            final body = (data['body'] ?? '').toString();
                            final sName = (data['societyName'] ?? '').toString();
                            final aName = (data['adminName'] ?? '').toString();
                            final aPhone = (data['adminPhone'] ?? '').toString();
                            final appealId = (data['appealId'] ?? '').toString();
                            final type = (data['type'] ?? '').toString();

                            final displayBody = (type == 'admin_appeal_request' && sName.isNotEmpty)
                                ? "$sName ${aName.isNotEmpty ? '($aName) ' : ''}${'appeal_notif_suffix'.tr}"
                                : (body.isNotEmpty ? body.tr : '');

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.campaign_rounded, color: Color(0xFF38BDF8), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          title.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sName.isNotEmpty || aName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "$sName • $aName ${aPhone.isNotEmpty ? '($aPhone)' : ''}",
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    displayBody,
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                                  ),
                                  if (aPhone.isNotEmpty || appealId.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (aPhone.isNotEmpty)
                                          ElevatedButton.icon(
                                            onPressed: () => _makePhoneCall(aPhone),
                                            icon: const Icon(Icons.call_rounded, size: 13),
                                            label: Text("call_btn".tr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                          ),
                                        if (appealId.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => SuperAdminAppealDetailScreen(
                                                    appealId: appealId,
                                                    initialData: data,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.open_in_new_rounded, size: 13),
                                            label: Text("view_appeal_btn".tr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0284C7),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  // ૮. યુઝરને સુપર એડમિન બનાવવાની પુષ્ટિ
  void _confirmPromoteSuperAdmin(SuperAdminUserItem u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text("સુપર એડમિન બનાવો છો?".tr, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        content: Text(
          "શું તમે ખરેખર '${u.name}' ને સંપૂર્ણ સુપર એડમિન અધિકાર આપવા માંગો છો?\nતેઓ તમામ સોસાયટીઓ, યુઝર્સ અને હિસાબો જોઈ તથા નિયંત્રિત કરી શકશે.".tr,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("રદ કરો".tr, style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await _service.promoteToSuperAdmin(u.uid);
              _loadAllData();
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFF59E0B),
                  content: Text("${u.name} હવે સુપર એડમિન બની ગયા છે!".tr),
                ),
              );
            },
            child: Text("હા, સુપર એડમિન બનાવો".tr),
          ),
        ],
      ),
    );
  }

  // ૯. સુપર એડમિન સત્તા રદ્દ કરવાની પુષ્ટિ
  void _confirmRevokeSuperAdmin(SuperAdminUserItem u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "સુપર એડમિન અધિકાર રદ્દ કરવો છે?".tr,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Text(
          "શું તમે '${u.name}' પાસેથી સુપર એડમિન સત્તા પાછી ખેંચવા માંગો છો?".tr,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ના".tr, style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await _service.revokeSuperAdmin(u.uid);
              _loadAllData();
              messenger.showSnackBar(
                SnackBar(content: Text("${u.name} પાસેથી સુપર એડમિન સત્તા રદ્દ કરવામાં આવી છે.".tr)),
              );
            },
            child: Text("હા, સત્તા રદ્દ કરો".tr),
          ),
        ],
      ),
    );
  }

  // ૧૦. લૉગઆઉટ કન્ફર્મેશન
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("લૉગઆઉટ કરવું છે?".tr, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        content: Text(
          "શું તમે ખરેખર સુપર એડમિન કમાન્ડ સેન્ટરમાંથી લૉગઆઉટ કરવા માંગો છો?".tr,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ના".tr, style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted) {
                await SessionGuardService.performAppLogout(context);
              }
            },
            child: Text("હા, લૉગઆઉટ કરો".tr),
          ),
        ],
      ),
    );
  }

  void _launchCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse("tel:$cleanPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CustomHeaderDelegate({required this.child});

  @override
  double get minExtent => 64.0;
  @override
  double get maxExtent => 64.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_CustomHeaderDelegate oldDelegate) => true;
}
