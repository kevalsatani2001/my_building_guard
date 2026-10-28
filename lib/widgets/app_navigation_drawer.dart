import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_firestore.dart';
import '../services/society_service.dart';
import '../services/session_guard_service.dart';
import '../widgets/premium_ui.dart';

// Role-specific screens
import '../screens/admin/admin_society_bank_settings_screen.dart';
import '../screens/admin/admin_users_directory_screen.dart';
import '../screens/admin/admin_complaints_screen.dart';
import '../screens/admin/admin_maintenance_screen.dart';
import '../screens/admin/admin_accounts_screen.dart';
import '../screens/admin/admin_broadcast_screen.dart';
import '../screens/admin/admin_emergency_contacts_screen.dart';
import '../screens/admin/admin_polls_screen.dart';
import '../screens/admin/admin_patrol_screen.dart';

import '../screens/member/member_vehicles_screen.dart';
import '../screens/member/member_pre_approve_screen.dart';
import '../screens/member/member_daily_staff_screen.dart';
import '../screens/member/member_complaint_register_screen.dart';
import '../screens/member/member_accounts_screen.dart';
import '../screens/member/member_polls_screen.dart';

/// An ultra-premium, role-aware Navigation Drawer for the Building Guard app.
/// Seamlessly adapts its theme, shortcuts, and header to:
/// - Super Admin (`super_admin`)
/// - Society Admin / Chairman (`admin`)
/// - Member / Resident (`member`)
/// - Watchman / Security Guard (`watchman`)
class AppNavigationDrawer extends StatelessWidget {
  final String? role; // 'admin', 'member', 'watchman', 'super_admin'
  final bool? isDark;

  const AppNavigationDrawer({
    super.key,
    this.role,
    this.isDark,
  });

  String get _effectiveRole {
    if (role != null && role!.trim().isNotEmpty) return role!.trim().toLowerCase();
    final soc = SocietyService.instance;
    if (soc.isPlatformSuperAdmin) return 'super_admin';
    if (soc.isAdmin) return 'admin';
    if (soc.isGuard) return 'watchman';
    return 'member';
  }

  bool get _effectiveDark {
    if (isDark != null) return isDark!;
    return _effectiveRole == 'super_admin' || _effectiveRole == 'watchman';
  }

  @override
  Widget build(BuildContext context) {
    final dark = _effectiveDark;
    final roleType = _effectiveRole;

    return Drawer(
      backgroundColor: dark ? const Color(0xFF0F172A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // 1. Luxury Role-Themed Header
            _buildDrawerHeader(context, roleType, dark),

            // 2. Scrollable Navigation Menu
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  // GENERAL SECTION
                  _buildSectionLabel('drawer_general_settings'.tr, dark),
                  const SizedBox(height: 6),

                  _buildDrawerTile(
                    icon: Icons.person_outline_rounded,
                    title: 'drawer_my_profile'.tr,
                    subtitle: 'drawer_view_personal_flat'.tr,
                    dark: dark,
                    accentColor: _getRoleAccent(roleType),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileSheet(context, dark);
                    },
                  ),

                  _buildDrawerTile(
                    icon: Icons.translate_rounded,
                    title: 'drawer_change_language'.tr,
                    subtitle: _getCurrentLanguageLabel(),
                    trailingBadge: _getCurrentLanguageBadge(),
                    dark: dark,
                    accentColor: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(context);
                      LocalizationService.instance.showLanguagePicker(context);
                    },
                  ),

                  const SizedBox(height: 16),

                  // ROLE-SPECIFIC SHORTCUTS SECTION
                  _buildSectionLabel(
                    roleType == 'admin'
                        ? 'drawer_admin_shortcuts'.tr
                        : roleType == 'member'
                            ? 'drawer_my_shortcuts'.tr
                            : roleType == 'watchman'
                                ? 'drawer_security_shortcuts'.tr
                                : 'drawer_super_admin_shortcuts'.tr,
                    dark,
                  ),
                  const SizedBox(height: 6),

                  if (roleType == 'admin') ..._buildAdminMenuItems(context, dark),
                  if (roleType == 'member') ..._buildMemberMenuItems(context, dark),
                  if (roleType == 'watchman') ..._buildWatchmanMenuItems(context, dark),
                  if (roleType == 'super_admin') ..._buildSuperAdminMenuItems(context, dark),

                  const SizedBox(height: 16),

                  // SUPPORT & SECURITY SECTION
                  _buildSectionLabel('drawer_support_security'.tr, dark),
                  const SizedBox(height: 6),

                  _buildDrawerTile(
                    icon: Icons.contact_phone_outlined,
                    title: 'drawer_emergency_numbers'.tr,
                    subtitle: 'drawer_emergency_subtitle'.tr,
                    dark: dark,
                    accentColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminEmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDrawerTile(
                    icon: Icons.verified_user_outlined,
                    title: 'drawer_app_security'.tr,
                    subtitle: 'drawer_end_to_end_secure'.tr,
                    dark: dark,
                    accentColor: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _showSecurityInfoDialog(context, dark);
                    },
                  ),
                ],
              ),
            ),

            // 3. App Version & Logout Button
            _buildDrawerFooter(context, roleType, dark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildDrawerHeader(BuildContext context, String roleType, bool dark) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final soc = SocietyService.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: uid.isNotEmpty
          ? AppFirestore.instance.collection('users').doc(uid).snapshots()
          : null,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final displayName = (data?['name'] ?? data?['fullName'] ?? soc.currentUserName).toString().trim();
        final finalName = displayName.isNotEmpty ? displayName : _getRoleDefaultName(roleType);

        final societyName = (data?['societyName'] ?? soc.currentSocietyName).toString().trim();
        final unitNumber = (data?['unitNumber'] ?? soc.currentUserUnit).toString().trim();
        final blockName = (data?['blockName'] ?? soc.currentUserBlock).toString().trim();

        final flatDisplay = unitNumber.isNotEmpty
            ? (blockName.isNotEmpty ? '$blockName-$unitNumber' : unitNumber)
            : '';

        final roleBadge = _getRoleBadgeTitle(roleType);
        final gradientColors = _getRoleGradient(roleType);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 16, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with Monogram or Profile
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        finalName.isNotEmpty ? finalName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: gradientColors.last,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Live Connected Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'સક્રિય'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // User Name
              Text(
                finalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),

              // Society & Unit Row
              Row(
                children: [
                  Flexible(
                    child: Text(
                      societyName.isNotEmpty ? societyName : 'માય સોસાયટી'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (flatDisplay.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        flatDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Role Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  roleBadge,
                  style: TextStyle(
                    color: gradientColors.last,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION LABELS & TILES
  // ==========================================
  Widget _buildSectionLabel(String text, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingBadge,
    required bool dark,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.5),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: dark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: accentColor.withValues(alpha: dark ? 0.35 : 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailingBadge,
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ROLE MENU ITEMS
  // ==========================================
  List<Widget> _buildAdminMenuItems(BuildContext context, bool dark) {
    return [
      _buildDrawerTile(
        icon: Icons.account_balance_outlined,
        title: 'drawer_bank_settings'.tr,
        subtitle: 'drawer_bank_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFF4338CA),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminSocietyBankSettingsScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.people_outline_rounded,
        title: 'drawer_members_directory'.tr,
        subtitle: 'drawer_members_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFF0284C7),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersDirectoryScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.receipt_long_outlined,
        title: 'drawer_maintenance_mgmt'.tr,
        subtitle: 'drawer_maintenance_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFF0D9488),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.report_problem_outlined,
        title: 'drawer_complaints_res'.tr,
        subtitle: 'drawer_complaints_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFFEA580C),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.campaign_outlined,
        title: 'drawer_broadcast_notice'.tr,
        subtitle: 'drawer_broadcast_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminBroadcastScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'drawer_society_accounts'.tr,
        subtitle: 'drawer_society_accounts_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFF059669),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAccountsScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.how_to_vote_outlined,
        title: 'drawer_polls_opinions'.tr,
        subtitle: 'drawer_polls_subtitle'.tr,
        dark: dark,
        accentColor: const Color(0xFFD97706),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPollsScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.security_outlined,
        title: 'ગાર્ડ પેટ્રોલીંગ (QR Patrol)'.tr,
        subtitle: 'ચોકીદાર પેટ્રોલિંગ લોગ્સ'.tr,
        dark: dark,
        accentColor: const Color(0xFF4F46E5),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPatrolScreen()),
          );
        },
      ),
    ];
  }

  List<Widget> _buildMemberMenuItems(BuildContext context, bool dark) {
    return [
      _buildDrawerTile(
        icon: Icons.directions_car_filled_outlined,
        title: 'મારા વાહનો (My Vehicles)'.tr,
        subtitle: 'રજિસ્ટર્ડ વાહનો & પાર્કિંગ'.tr,
        dark: dark,
        accentColor: const Color(0xFF0284C7),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MemberVehiclesScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.person_add_alt_1_outlined,
        title: 'પ્રિ-અપ્રૂવ્ડ વિઝિટર્સ'.tr,
        subtitle: 'મહેમાન અથવા ડિલિવરી પાસ બનાવો'.tr,
        dark: dark,
        accentColor: const Color(0xFF0D9488),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberPreApproveScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.badge_outlined,
        title: 'ડેઇલી સ્ટાફ & હેલ્પર્સ'.tr,
        subtitle: 'કામવાળા બાઈ, ડ્રાઈવર, કૂક'.tr,
        dark: dark,
        accentColor: const Color(0xFF7C3AED),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberDailyStaffScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.rate_review_outlined,
        title: 'ફરિયાદ નોંધાવો (Complaints)'.tr,
        subtitle: 'સોસાયટી કમિટીને ફરિયાદ મોકલો'.tr,
        dark: dark,
        accentColor: const Color(0xFFDC2626),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberComplaintRegisterScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'સોસાયટી એકાઉન્ટ સ્ટેટમેન્ટ'.tr,
        subtitle: 'સોસાયટીના ખર્ચ અને ફંડ વિગતો'.tr,
        dark: dark,
        accentColor: const Color(0xFF059669),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberAccountsScreen()),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.how_to_vote_outlined,
        title: 'પોલ્સ & વોટિંગ (Polls)'.tr,
        subtitle: 'તમારો કિંમતી મત આપો'.tr,
        dark: dark,
        accentColor: const Color(0xFFD97706),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberPollsScreen()),
          );
        },
      ),
    ];
  }

  List<Widget> _buildWatchmanMenuItems(BuildContext context, bool dark) {
    return [
      _buildDrawerTile(
        icon: Icons.directions_car_filled_outlined,
        title: 'વાહન નંબર સર્ચ (Vehicle Search)'.tr,
        subtitle: 'વાહન માલિકની ફ્લેટ વિગતો જાણો'.tr,
        dark: dark,
        accentColor: const Color(0xFF38BDF8),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('કૃપા કરીને હોમ સ્ક્રીન પરથી વાહન સર્ચ આયકન દબાવો'.tr)),
          );
        },
      ),
      _buildDrawerTile(
        icon: Icons.warning_amber_rounded,
        title: 'ઇમરજન્સી SOS મોકલો'.tr,
        subtitle: 'તમામ એડમિન અને સભ્યોને તાત્કાલિક એલર્ટ'.tr,
        dark: dark,
        accentColor: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ઇમરજન્સી SOS હેડર આયકન પર ઉપલબ્ધ છે'.tr)),
          );
        },
      ),
    ];
  }

  List<Widget> _buildSuperAdminMenuItems(BuildContext context, bool dark) {
    return [
      _buildDrawerTile(
        icon: Icons.apartment_rounded,
        title: 'તમામ સોસાયટી ડિરેક્ટરી'.tr,
        subtitle: 'રજિસ્ટર્ડ સોસાયટીઓ તપાસો'.tr,
        dark: dark,
        accentColor: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.notifications_active_outlined,
        title: 'લાઈવ અપીલ્સ & વિનંતીઓ'.tr,
        subtitle: 'એડમિન્સ દ્વારા આવેલી અપીલ'.tr,
        dark: dark,
        accentColor: const Color(0xFF14B8A6),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    ];
  }

  // ==========================================
  // FOOTER (LOGOUT & VERSION)
  // ==========================================
  Widget _buildDrawerFooter(BuildContext context, String roleType, bool dark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Luxury Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleLogout(context, roleType),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.35 : 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'drawer_logout'.tr,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // App Info
          Text(
            'Building Guard • v1.0.0 Pro',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS & MODALS
  // ==========================================
  void _handleLogout(BuildContext context, String roleType) async {
    Navigator.pop(context); // close drawer first
    final confirmed = await PremiumLogoutDialog.show(
      context,
      roleName: _getRoleBadgeTitle(roleType),
    );
    if (confirmed && context.mounted) {
      await SessionGuardService.performAppLogout(context);
    }
  }

  void _showProfileSheet(BuildContext context, bool dark) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final soc = SocietyService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getRoleGradient(_effectiveRole),
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'પ્રોફાઇલ & એકાઉન્ટ માહિતી'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: dark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _getRoleBadgeTitle(_effectiveRole),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getRoleAccent(_effectiveRole),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildInfoRow('નામ:'.tr, soc.currentUserName.isNotEmpty ? soc.currentUserName : 'User', dark),
              _buildInfoRow('મોબાઇલ:'.tr, user?.phoneNumber ?? user?.email ?? 'N/A', dark),
              _buildInfoRow('સોસાયટી:'.tr, soc.currentSocietyName, dark),
              if (soc.currentUserUnit.isNotEmpty)
                _buildInfoRow('ફ્લેટ / યુનિટ:'.tr, '${soc.currentUserBlock} ${soc.currentUserUnit}', dark),
              _buildInfoRow('યુઝર આઈડી:'.tr, uid.length > 12 ? '${uid.substring(0, 12)}...' : uid, dark),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _getRoleAccent(_effectiveRole),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('સમજાઈ ગયું'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfoDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              'સુરક્ષા & ગોપનીયતા'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: dark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'આ એપ્લિકેશન રોલ-બેઝ્ડ એક્સેસ કંટ્રોલ (RBAC) અને એન્ક્રિપ્ટેડ ક્લાઉડ સુરક્ષા સાથે બનાવવામાં આવેલ છે. તમારો ડેટા ફક્ત અધિકૃત સભ્યો જ જોઈ શકે છે.'
              .tr,
          style: TextStyle(
            fontSize: 13,
            color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx),
            child: Text('બરાબર છે'.tr),
          ),
        ],
      ),
    );
  }

  // Language helpers
  String _getCurrentLanguageLabel() {
    final code = LocalizationService.instance.currentCode;
    if (code == 'gu') return 'ગુજરાતી (Default)';
    if (code == 'hi') return 'हिन्दी (Hindi)';
    return 'English';
  }

  Widget _getCurrentLanguageBadge() {
    final code = LocalizationService.instance.currentCode.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Role style helpers
  List<Color> _getRoleGradient(String role) {
    switch (role) {
      case 'super_admin':
        return [const Color(0xFF070B14), const Color(0xFF1E293B), const Color(0xFFD97706)];
      case 'admin':
        return [const Color(0xFF312E81), const Color(0xFF4338CA), const Color(0xFF6366F1)];
      case 'watchman':
        return [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF312E81)];
      case 'member':
      default:
        return [const Color(0xFF090D16), const Color(0xFF0D9488), const Color(0xFF14B8A6)];
    }
  }

  Color _getRoleAccent(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFFF59E0B);
      case 'admin':
        return const Color(0xFF6366F1);
      case 'watchman':
        return const Color(0xFF38BDF8);
      case 'member':
      default:
        return const Color(0xFF0D9488);
    }
  }

  String _getRoleBadgeTitle(String role) {
    switch (role) {
      case 'super_admin':
        return 'role_super_admin'.tr;
      case 'admin':
        return 'role_admin'.tr;
      case 'watchman':
        return 'role_guard'.tr;
      case 'member':
      default:
        return 'role_member'.tr;
    }
  }

  String _getRoleDefaultName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Society Admin';
      case 'watchman':
        return 'Security Guard';
      case 'member':
      default:
        return 'Member';
    }
  }
}
