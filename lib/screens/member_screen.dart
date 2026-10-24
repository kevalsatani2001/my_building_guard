import 'dart:async';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/visitor_model.dart';
import '../models/maintenance_model.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/session_guard_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/member_maintenance_sheet.dart';
import '../widgets/member_notifications_sheet.dart';
import '../services/notification_navigation_service.dart';
import 'member_complaint_register_screen.dart';
import 'member_daily_staff_screen.dart';
import 'member_pre_approve_screen.dart';
import 'member_vehicles_screen.dart';
import 'member_visitors_screen.dart';
import 'member_accounts_screen.dart';
import 'member_polls_screen.dart';
import 'member_amenities_screen.dart';
import '../services/amenity_booking_service.dart';
import '../models/patrol_model.dart';
import '../services/guard_patrol_service.dart';
import '../widgets/visitor_detail_sheet.dart';
import '../widgets/app_navigation_drawer.dart';

const String _kMemberFunctionsRegion = 'us-central1';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _visitorStatusFilter = 'all';
  String _visitorTimeFilter = '30d';
  String _visitorScope = 'my_flat'; // 'my_flat' or 'all_society'

  Stream<QuerySnapshot>? _cachedVisitorsStream;
  String? _lastQuerySocietyId;
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
      NotificationNavigationService.checkAndHandlePendingColdStart(context);
    });
    _userStream = AppFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots();
  }

  Stream<QuerySnapshot> _getVisitorsStream(String societyId) {
    if (_cachedVisitorsStream != null && _lastQuerySocietyId == societyId) {
      return _cachedVisitorsStream!;
    }
    _lastQuerySocietyId = societyId;
    if (societyId.isNotEmpty) {
      _cachedVisitorsStream = AppFirestore.instance
          .collection('visitors')
          .where('societyId', isEqualTo: societyId)
          .limit(150)
          .snapshots();
    } else {
      _cachedVisitorsStream = AppFirestore.instance
          .collection('visitors')
          .where('memberId', isEqualTo: currentUserId)
          .limit(100)
          .snapshots();
    }
    return _cachedVisitorsStream!;
  }

  // ૧. સ્ટેટસ અપડેટ ફંક્શન (મંજૂરી કે અસ્વીકાર)
  Future<void> _updateStatus(String docId, String status) async {
    await AppFirestore.instance.collection('visitors').doc(docId).update({
      'status': status,
      'actionTime': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.'.tr : 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.'.tr,
          ),
          backgroundColor: status == 'approved' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// મેમ્બર ઘરે પ્રોબ્લેમ / ઇમરજન્સી — એડમિન + ગેટ વોચમેનને નોટિફિકેશન (Ultra-Premium Luxury Dialog)
  Future<void> _showMemberEmergencyDialog() async {
    final noteC = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 20,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Crimson Pulse Squircle Emblem
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.crisis_alert_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ઇમરજન્સી SOS મદદ'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'તાત્કાલિક સુરક્ષા સહાયતા એલર્ટ'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                // Alert Callout Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'એડમિન અને સોસાયટી ગેટ વોચમેનને સાયરન સાથે તાત્કાલિક એલર્ટ પુશ નોટિફિકેશન જશે.'.tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // TextField
                TextField(
                  controller: noteC,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'સમસ્યા અથવા વિગત (વૈકલ્પિક)'.tr,
                    labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    hintText: 'દા.ત. તબિયત ખરાબ છે, લિફ્ટ સમસ્યા, સુરક્ષા...'.tr,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dual Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12.5),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'રદ કરો'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, true),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 12.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emergency_share_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text(
                                'હા, SOS મોકલો'.tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;

      final userDoc = await AppFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final d = userDoc.data() ?? {};
      final name = d['name'] ?? 'મેમ્બર'.tr;
      final block = d['blockName'] ?? '';
      final unit = d['unitNumber'] ?? '';
      final flat = [
        block,
        unit,
      ].where((e) => e.toString().isNotEmpty).join('-');
      final note = noteC.text.trim();
      final bodyBase =
          '$name — ઘર: ${flat.isEmpty ? "?" : flat}. મેમ્બર ઇમરજન્સી માંગે છે.'.tr;
      final body = note.isEmpty ? bodyBase : '$bodyBase\nવિગત: $note'.tr;

      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: _kMemberFunctionsRegion,
      );
      final callable = functions.httpsCallable(
        'sendTopicAlertPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
      );
      await callable.call<Map<String, dynamic>>({
        'topicKind': 'admins',
        'title': '🚨 મેમ્બર ઇમરજન્સી'.tr,
        'body': body,
        'type': 'member_emergency',
      });
      await callable.call<Map<String, dynamic>>({
        'topicKind': 'watchmen',
        'title': '🚨 મેમ્બર ઇમરજન્સી (ગેટ)'.tr,
        'body': body,
        'type': 'member_emergency',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('મદદની સૂચના એડમિન અને ગેટને સફળતાપૂર્વક મોકલાઈ.'.tr),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        final detail = e.message?.trim();
        final line = detail != null && detail.isNotEmpty
            ? '${e.code}: $detail'
            : e.code;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $line'.tr), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $e'.tr), backgroundColor: Colors.red),
        );
      }
    } finally {
      noteC.dispose();
    }
  }

  // ૨. Pre-Approve Guest (Dedicated Screen)
  void _showPreApproveDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberPreApproveScreen()),
    );
  }

  Future<void> _showMaintenancePortal({MaintenanceBill? initialBill}) async {
    await MemberMaintenanceSheet.showMaintenancePortal(
      context,
      currentUserId: currentUserId,
      initialBill: initialBill,
    );
  }

  void _showComplaintDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberComplaintRegisterScreen()),
    );
  }

  void _showAddStaffDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberDailyStaffScreen()),
    );
  }

  void _showMyVehiclesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberVehiclesScreen()),
    );
  }

  DateTime _memberCutoffDate() {
    final now = DateTime.now();
    if (_visitorTimeFilter == 'today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (_visitorTimeFilter == '7d') {
      return now.subtract(const Duration(days: 7));
    }
    if (_visitorTimeFilter == '30d') {
      return now.subtract(const Duration(days: 30));
    }
    return DateTime(2020);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final memberName = userData['name']?.toString() ?? 'મેમ્બર'.tr;
        final blockName = userData['blockName']?.toString() ?? '';
        final unitNumber = userData['unitNumber']?.toString() ?? '';
        final flatDisplay = [blockName, unitNumber].where((s) => s.isNotEmpty).join(' • ');
        final userSocId = userData['societyId']?.toString().trim();
        final effectiveSocietyId = (userSocId != null && userSocId.isNotEmpty)
            ? userSocId
            : SocietyService.instance.societyId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: const AppNavigationDrawer(role: 'member'),
          appBar: _buildMemberAppBar(flatDisplay, blockName),
          body: StreamBuilder<QuerySnapshot>(
            stream: _getVisitorsStream(effectiveSocietyId),
            builder: (context, visitorSnap) {
              final rawDocs = visitorSnap.hasData ? visitorSnap.data!.docs : <QueryDocumentSnapshot>[];

              // Filter by tenant
              final tenantDocs = rawDocs.where((d) {
                return SocietyService.instance.documentBelongsToCurrentTenant(
                  d.data() as Map<String, dynamic>?,
                );
              }).toList();

              // Sort in Dart by entryTime descending (no composite index needed!)
              tenantDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;
                final aTime = aData?['entryTime'] as Timestamp?;
                final bTime = bData?['entryTime'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              // Separate My Flat visitors vs All Society visitors
              final myFlatDocs = tenantDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final mId = data['memberId']?.toString().trim();
                final uNum = data['unitNumber']?.toString().trim();
                final bName = data['blockName']?.toString().trim();
                if (mId == currentUserId) return true;
                if (mId == 'all_society') return true;
                if (unitNumber.isNotEmpty &&
                    uNum == unitNumber &&
                    (blockName.isEmpty || bName == blockName)) {
                  return true;
                }
                return false;
              }).toList();

              // Active scope selection: 'my_flat' or 'all_society'
              final activeScopeDocs = _visitorScope == 'all_society' ? tenantDocs : myFlatDocs;

              // Calculate Status Counts for the active scope
              final pendingCount = activeScopeDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;
              final approvedCount = activeScopeDocs.where((d) => (d.data() as Map)['status'] == 'approved').length;
              final checkedOutCount = activeScopeDocs.where((d) => (d.data() as Map)['status'] == 'checked_out').length;
              final rejectedCount = activeScopeDocs.where((d) => (d.data() as Map)['status'] == 'rejected').length;

              // Total pending for my flat alert hero
              final myFlatPending = myFlatDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;

              // Filter by cutoff date
              final cutoff = _memberCutoffDate();
              final timeFiltered = activeScopeDocs.where((d) {
                final ts = (d.data() as Map<String, dynamic>?)?['entryTime'];
                if (ts is! Timestamp) return false;
                return ts.toDate().isAfter(cutoff);
              }).toList();

              // Filter by status tab
              final filteredVisitors = _visitorStatusFilter == 'all'
                  ? timeFiltered
                  : timeFiltered.where((d) => (d.data() as Map)['status'] == _visitorStatusFilter).toList();

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                  children: [
                    // ૧. Member Profile & Flat Card
                    _buildMemberProfileHero(memberName, flatDisplay, myFlatPending),
                    const SizedBox(height: 14),

                    // ૨. Top Executive Stat Cards (Interactive tap filters)
                    _buildExecutiveStatsRow(pendingCount, approvedCount, checkedOutCount),
                    const SizedBox(height: 14),

                    // ૩. Notice Board (Executive styling)
                    _buildNoticeBoard(),

                    // ૪. Maintenance Alert Banner
                    _buildMaintenanceBanner(),
                    const SizedBox(height: 14),

                    // ૫. Quick Actions Grid
                    _buildQuickActionGrid(),
                    const SizedBox(height: 22),

                    // ૬. Visitors Section Header (Title & 'View All' Pill)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              AppStrings.get('recent_visitors'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MemberVisitorsScreen(initialScope: _visitorScope),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.get('view_all'),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF0F766E)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ૭. Scope Switcher Bar: [ 🏠 મારા ફ્લેટ (myCount) ] | [ 🏢 આખી સોસાયટી ગેટ (allCount) ]
                    _buildScopeSwitcher(myFlatDocs.length, tenantDocs.length),
                    const SizedBox(height: 12),

                    // ૮. Filter Control Header: Status Filter Bar + Executive Time Selector
                    _buildFilterControlHeader(),
                    const SizedBox(height: 10),

                    // ૯. Full-Width Premium Status Filter Chips
                    _buildStatusFilterTabs(
                      activeScopeDocs.length,
                      pendingCount,
                      approvedCount,
                      rejectedCount,
                      checkedOutCount,
                    ),
                    const SizedBox(height: 14),

                    // ૯. Visitor List Items or Premium Empty State
                    if (visitorSnap.connectionState == ConnectionState.waiting && rawDocs.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF0F766E))))
                    else if (filteredVisitors.isEmpty)
                      _buildEmptyState(allSocietyCount: tenantDocs.length)
                    else
                      ...filteredVisitors.map((doc) {
                        final v = VisitorModel.fromFirestore(doc);
                        final isForMyFlat = v.memberId == currentUserId ||
                            (unitNumber.isNotEmpty &&
                                v.unitNumber == unitNumber &&
                                (blockName.isEmpty || v.blockName == blockName)) ||
                            v.memberId == 'all_society';
                        return _buildVisitorCard(v, isMyFlat: isForMyFlat);
                      }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildMemberAppBar(String flatDisplay, [String blockName = '']) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
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
      leadingWidth: 50,
      titleSpacing: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.get('my_society'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1.5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (flatDisplay.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                        ),
                        child: Text(
                          flatDisplay,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4338CA),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.5),
                    ],
                    Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppStrings.get('member_portal'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10,
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
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emergency SOS Glowing Button (Compact 34x34)
              Tooltip(
                message: 'ઇમરજન્સી SOS મદદ'.tr,
                child: InkWell(
                  onTap: _showMemberEmergencyDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sos_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Notification Bell Button with live stream count
              Tooltip(
                message: 'નોટિફિકેશન અને એલર્ટ્સ'.tr,
                child: StreamBuilder<QuerySnapshot>(
                  stream: AppFirestore.instance
                      .collection('notifications')
                      .where('societyId', isEqualTo: SocietyService.instance.societyId)
                      .orderBy('createdAt', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, notifSnap) {
                    int unreadCount = 0;
                    if (notifSnap.hasData) {
                      final docs = notifSnap.data!.docs;
                      final uid = currentUserId;
                      unreadCount = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final target = (data['targetUID'] ?? '').toString().trim();
                        final tBlock = (data['targetBlock'] ?? '').toString().trim();
                        final isBlock = blockName.isNotEmpty && (tBlock == blockName || target == 'BLOCK_$blockName');
                        return target == uid || target == 'ALL' || target == 'MEMBERS' || isBlock;
                      }).length;
                    }

                    return InkWell(
                      onTap: () => MemberNotificationsSheet.show(context, userBlock: blockName),
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: unreadCount > 0
                                  ? const Color(0xFFF0FDFA)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: unreadCount > 0
                                    ? const Color(0xFF99F6E4)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              unreadCount > 0
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              size: 18,
                              color: unreadCount > 0
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 5),
              // Multi-language switch button (GU / HI / EN)
              const LanguageSwitchButton(),
              const SizedBox(width: 5),
              // Logout Button
              Tooltip(
                message: 'લોગઆઉટ'.tr,
                child: InkWell(
                  onTap: () async {
                    final confirm = await PremiumLogoutDialog.show(
                      context,
                      roleName: 'મેમ્બર પોર્ટલ'.tr,
                    );
                    if (confirm && mounted) {
                      await SessionGuardService.performAppLogout(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 17,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberProfileHero(String name, String flat, int pending) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF090D16), Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF090D16).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient glowing gradient background orbs
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0D9488).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Hero Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Monogram Avatar with luxury gradient ring
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2DD4BF), Color(0xFF38BDF8), Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14.5),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "${'namaste'.tr}, $name",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.verified_rounded, size: 17, color: Color(0xFF38BDF8)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              flat.isNotEmpty ? "${'resident'.tr} • ${'flat_label'.tr}: $flat" : 'verified_society_member'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Live Gate Protection status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 12, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text(
                              "લાઈવ ગેટ".tr,
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (pending > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFCA5A5), size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "$pending મુલાકાતી ગેટ પર તમારી મંજૂરીની રાહ જુએ છે!".tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveStatsRow(int pending, int approved, int out) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "પેન્ડિંગ".tr,
            subtitle: "પ્રતીક્ષા".tr,
            count: pending,
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFD97706),
            tintColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            isSelected: _visitorStatusFilter == 'pending',
            onTap: () {
              setState(() {
                _visitorStatusFilter = _visitorStatusFilter == 'pending' ? 'all' : 'pending';
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "મંજૂર કરેલ".tr,
            subtitle: "માન્ય મુલાકાતી".tr,
            count: approved,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF059669),
            tintColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            isSelected: _visitorStatusFilter == 'approved',
            onTap: () {
              setState(() {
                _visitorStatusFilter = _visitorStatusFilter == 'approved' ? 'all' : 'approved';
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "બહાર ગયા".tr,
            subtitle: "રવાના થયેલ".tr,
            count: out,
            icon: Icons.output_rounded,
            color: const Color(0xFF475569),
            tintColor: const Color(0xFFF8FAFC),
            borderColor: const Color(0xFFE2E8F0),
            isSelected: _visitorStatusFilter == 'checked_out',
            onTap: () {
              setState(() {
                _visitorStatusFilter = _visitorStatusFilter == 'checked_out' ? 'all' : 'checked_out';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required Color tintColor,
    required Color borderColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? tintColor : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.22 : 0.06),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Column(
      children: [
        // Top 2 Primary VIP Actions (Guest Pass QR & Maintenance Bill)
        Row(
          children: [
            Expanded(
              child: _primaryActionCard(
                title: AppStrings.get('guest_pass_title'),
                subtitle: AppStrings.get('guest_pass_sub'),
                icon: Icons.qr_code_2_rounded,
                gradient: const [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF4F46E5)],
                onTap: _showPreApproveDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _primaryActionCard(
                title: AppStrings.get('maintenance_bill_title'),
                subtitle: AppStrings.get('maintenance_bill_sub'),
                icon: Icons.receipt_long_rounded,
                gradient: const [Color(0xFF064E3B), Color(0xFF0D9488), Color(0xFF10B981)],
                onTap: () => _showMaintenancePortal(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary 3 Service Actions (Luxury Micro-Cards)
        Row(
          children: [
            Expanded(
              child: _secondaryActionCard(
                title: AppStrings.get('complaint_action_title'),
                subtitle: AppStrings.get('complaint_action_sub'),
                icon: Icons.campaign_rounded,
                color: const Color(0xFF7C3AED),
                gradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                borderColor: const Color(0xFFDDD6FE),
                onTap: _showComplaintDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _secondaryActionCard(
                title: AppStrings.get('daily_staff_title'),
                subtitle: AppStrings.get('daily_staff_sub'),
                icon: Icons.badge_rounded,
                color: const Color(0xFFD97706),
                gradient: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                borderColor: const Color(0xFFFDE68A),
                onTap: _showAddStaffDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _secondaryActionCard(
                title: AppStrings.get('vehicles_action_title'),
                subtitle: AppStrings.get('vehicles_action_sub'),
                icon: Icons.directions_car_rounded,
                color: const Color(0xFF0284C7),
                gradient: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                borderColor: const Color(0xFFBAE6FD),
                onTap: _showMyVehiclesDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Society Accounts & Treasury Fund VIP Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberAccountsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF99F6E4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('society_accounts_title'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.get('society_accounts_sub'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.get('view_accounts_btn'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Society Digital Polls VIP Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberPollsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('society_polls_card_title'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.get('society_polls_card_sub'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.get('vote_now_btn'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Society Amenities & Clubhouse Booking Card (ONLY IF ENABLED)
        StreamBuilder<bool>(
          stream: AmenityBookingService.instance.hasAmenitiesStream(),
          builder: (context, snapshot) {
            final hasAmenities = snapshot.data == true;
            if (!hasAmenities) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberAmenitiesScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.domain_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "એમેનિટીઝ & વાડી બુકિંગ".tr,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "વાડી, ક્લબહાઉસ કે ટેરેસ સ્લોટ બુક કરો અને ગેટ પાસ મેળવો".tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "બુક કરો".tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Security Night Patrol Compliance Audit Banner
        _buildSecurityPatrolAuditBanner(),
      ],
    );
  }

  Widget _buildSecurityPatrolAuditBanner() {
    final societyId = SocietyService.instance.societyId;
    if (societyId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: GuardPatrolService().getPatrolComplianceStats(societyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = snapshot.data!;
        final statusMsg = stats['statusMessage'] as String? ?? '';
        final compliance = (stats['compliancePercent'] as num?)?.toInt() ?? 0;

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMemberPatrolDetailsSheet(stats),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "રાત્રિ સુરક્ષા ઓડિટ (Night Patrol)".tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (compliance >= 75
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$compliance%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: compliance >= 75
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFBBF24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusMsg,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "રિપોર્ટ".tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMemberPatrolDetailsSheet(Map<String, dynamic> stats) {
    final completed = (stats['completedRounds'] as num?)?.toInt() ?? 0;
    final target = (stats['targetRounds'] as num?)?.toInt() ?? 4;
    final compliance = (stats['compliancePercent'] as num?)?.toInt() ?? 0;
    final lastPatrol = stats['lastPatrol'] as PatrolShiftSession?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'સોસાયટી સુરક્ષા પ્રમાણપત્ર'.tr,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'વોચમેન ૨૪x૭ રાત્રિ પેટ્રોલિંગ ઓડિટ સ્ટેટસ'.tr,
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('સુરક્ષા કમ્પ્લાયન્સ:'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('$compliance% સુરક્ષિત'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('રાત્રિ પેટ્રોલિંગ રાઉન્ડ:'.tr, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('$completed / $target રાઉન્ડ પૂર્ણ'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (lastPatrol != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('છેલ્લો રાઉન્ડ:'.tr, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text('${lastPatrol.guardName} (${DateFormat('hh:mm a').format(lastPatrol.startTime)})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'મુખ્ય ગેટ, ટેરેસ, બેઝમેન્ટ પાર્કિંગ & પંપ રૂમ સુરક્ષિત રીતે તપાસવામાં આવ્યા છે.'.tr,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('સમજાયું (ઓકે)'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _primaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterControlHeader() {
    final timeLabel = switch (_visitorTimeFilter) {
      'today' => 'આજે'.tr,
      '7d' => '૭ દિવસ'.tr,
      '30d' => '૩૦ દિવસ'.tr,
      'all' => 'બધો સમય'.tr,
      _ => '૩૦ દિવસ'.tr,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(width: 8),
            Text(
              "સ્થિતિ ફિલ્ટર".tr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        // Executive Time Period Chip Button
        InkWell(
          onTap: _showTimeFilterModal,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF0F766E)),
                const SizedBox(width: 6),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTimeFilterModal() {
    final options = [
      ('today', 'આજે'.tr, 'આજના તમામ મુલાકાતીઓ'.tr, Icons.today_rounded),
      ('7d', 'છેલ્લા ૭ દિવસ'.tr, 'છેલ્લા એક અઠવાડિયાની વિગત'.tr, Icons.date_range_rounded),
      ('30d', 'છેલ્લા ૩૦ દિવસ'.tr, 'ચાલુ માસની મુલાકાતો'.tr, Icons.calendar_month_rounded),
      ('all', 'બધો સમય'.tr, 'તમામ ઐતિહાસિક રેકોર્ડ્સ'.tr, Icons.all_inclusive_rounded),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF0F766E), size: 20),
                SizedBox(width: 8),
                Text(
                  "સમયગાળો પસંદ કરો (Time Range)".tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...options.map((opt) {
              final isSelected = _visitorTimeFilter == opt.$1;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      opt.$4,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  title: Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    opt.$3,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 22)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _visitorTimeFilter = opt.$1);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterTabs(int total, int pending, int approved, int rejected, int out) {
    final tabs = [
      ('all', 'બધા'.tr, total, Icons.grid_view_rounded, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
      ('pending', 'પેન્ડિંગ'.tr, pending, Icons.hourglass_top_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      ('approved', 'મંજૂર'.tr, approved, Icons.check_circle_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5)),
      ('checked_out', 'બહાર ગયા'.tr, out, Icons.logout_rounded, const Color(0xFF475569), const Color(0xFFF1F5F9)),
      ('rejected', 'અસ્વીકાર'.tr, rejected, Icons.cancel_rounded, const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _visitorStatusFilter == t.$1;
          final key = t.$1;
          final label = t.$2;
          final count = t.$3;
          final icon = t.$4;
          final primaryColor = t.$5;
          final lightBg = t.$6;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _visitorStatusFilter = key);
                },
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.18),
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
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : lightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScopeSwitcher(int myCount, int allCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _visitorScope = 'my_flat'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _visitorScope == 'my_flat' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _visitorScope == 'my_flat'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 16,
                      color: _visitorScope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.get('scope_my_flat'),
                      style: TextStyle(
                        fontWeight: _visitorScope == 'my_flat' ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        color: _visitorScope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _visitorScope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$myCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _visitorScope == 'my_flat' ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _visitorScope = 'all_society'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _visitorScope == 'all_society' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _visitorScope == 'all_society'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 16,
                      color: _visitorScope == 'all_society' ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.get('scope_all_society'),
                      style: TextStyle(
                        fontWeight: _visitorScope == 'all_society' ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        color: _visitorScope == 'all_society' ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _visitorScope == 'all_society' ? const Color(0xFF4338CA) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$allCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _visitorScope == 'all_society' ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required int allSocietyCount}) {
    final isMyFlat = _visitorScope == 'my_flat';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFCCFBF1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 34,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isMyFlat ? "કોઈ મુલાકાતી બાકી નથી".tr : "સોસાયટી ગેટ પર કોઈ એન્ટ્રી નથી".tr,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMyFlat
                ? (allSocietyCount > 0
                    ? "તમારા ફ્લેટ માટે કોઈ મુલાકાતી નથી. સોસાયટી ગેટ પર કુલ $allSocietyCount મુલાકાતીઓ નોંધાયેલ છે.".tr
                    : "તમારા ફ્લેટ માટે તમામ એન્ટ્રી સુરક્ષિત અને અપ-ટૂ-ડેટ છે.".tr)
                : "પસંદ કરેલ સમયગાળામાં સોસાયટી ગેટ પર કોઈ મુલાકાતી મળ્યા નથી.".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isMyFlat && allSocietyCount > 0) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => setState(() => _visitorScope = 'all_society'),
              icon: const Icon(Icons.apartment_rounded, size: 16),
              label: Text('${"સોસાયટી ગેટ લાઈવ જુઓ".tr} ($allSocietyCount)'.tr),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showPreApproveDialog,
              icon: const Icon(Icons.qr_code_2_rounded, size: 16),
              label: Text('મહેમાન માટે ગેસ્ટ પાસ બનાવો'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
      return (Icons.local_shipping_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7));
    }
    if (p.contains('cab') ||
        p.contains('taxi') ||
        p.contains('uber') ||
        p.contains('ola') ||
        p.contains('auto') ||
        p.contains('ટેક્સી'.tr) ||
        p.contains('રીક્ષા'.tr)) {
      return (Icons.local_taxi_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF));
    }
    if (p.contains('service') ||
        p.contains('repair') ||
        p.contains('plumber') ||
        p.contains('electric') ||
        p.contains('maid') ||
        p.contains('કામવાળા'.tr) ||
        p.contains('રીપેરિંગ'.tr)) {
      return (Icons.handyman_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
    }
    return (Icons.people_alt_rounded, const Color(0xFF0D9488), const Color(0xFFCCFBF1));
  }

  Future<void> _callVisitor(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildVisitorCard(VisitorModel visitor, {required bool isMyFlat}) {
    final isPending = visitor.status == 'pending';
    final (typeIcon, typeColor, typeBg) = _getVisitorTypeMeta(visitor.purpose);
    final canAction = isPending && isMyFlat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isPending ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => VisitorDetailSheet.show(
            context,
            visitor: visitor,
            isMyFlat: isMyFlat,
            onStatusUpdate: _updateStatus,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canAction) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'ગેટ પર મંજૂરીની રાહ જુએ છે (Action Required)'.tr,
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: visitor.photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: visitor.photoUrl,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => _fallbackVisitorAvatar(visitor.name),
                                )
                              : _fallbackVisitorAvatar(visitor.name),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: typeBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(typeIcon, size: 11, color: typeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  visitor.name.isNotEmpty ? visitor.name : "અનામી મુલાકાતી".tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (visitor.phone.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _callVisitor(visitor.phone),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (visitor.purpose.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: typeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(typeIcon, size: 11, color: typeColor),
                                            const SizedBox(width: 3.5),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 115),
                                              child: Text(
                                                visitor.purpose,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: typeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.apartment_rounded, size: 11, color: Color(0xFF64748B)),
                                          const SizedBox(width: 3),
                                          Text(
                                            visitor.flatDisplay,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 3.5),
                              Text(
                                DateFormat('hh:mm a').format(visitor.entryTime),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                              if (visitor.status == 'checked_out' && visitor.exitTime != null) ...[
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(width: 8),
                                Icon(Icons.logout_rounded, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 3),
                                Text(
                                  "બહાર: ${DateFormat('hh:mm a').format(visitor.exitTime!)}".tr,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!canAction) _buildStatusAction(visitor),
                  ],
                ),
              ),
              if (canAction) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(visitor.id, 'approved'),
                              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 17),
                              label: Text(
                                'પ્રવેશ મંજૂર'.tr,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus(visitor.id, 'rejected'),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 17),
                            label: Text(
                              'નકારો'.tr,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _fallbackVisitorAvatar(String name) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'V',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAction(VisitorModel visitor) {
    final (color, bgColor, text, icon) = switch (visitor.status) {
      'approved' => (const Color(0xFF059669), const Color(0xFFECFDF5), 'મંજૂર કરેલ'.tr, Icons.check_circle_rounded),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'અસ્વીકાર'.tr, Icons.cancel_rounded),
      'checked_out' => (const Color(0xFF475569), const Color(0xFFF1F5F9), 'બહાર ગયા'.tr, Icons.output_rounded),
      _ => (const Color(0xFFD97706), const Color(0xFFFFFBEB), 'પેન્ડિંગ'.tr, Icons.hourglass_top_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // નોટિસ બોર્ડ વિજેટ (Executive Warm Gold Frosted Card)
  Widget _buildNoticeBoard() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final tenantDocs = snapshot.data!.docs.where((d) {
          return SocietyService.instance.documentBelongsToCurrentTenant(
            d.data() as Map<String, dynamic>?,
          );
        }).toList();
        if (tenantDocs.isEmpty) return const SizedBox.shrink();
        var notice = tenantDocs.first;
        final data = notice.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString();
        final body = (data['body'] ?? data['description'] ?? data['message'] ?? '').toString();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "સોસાયટી પરિપત્ર / નોટિસ".tr,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          body,
                          style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('બંધ કરો'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          "સોસાયટી મહત્વની સૂચના".tr,
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFFFDE68A)),
                            SizedBox(width: 3),
                            Text(
                              "તાજી અપડેટ".tr,
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceBanner() {
    return MemberMaintenanceSheet.buildMaintenanceBanner(
      context,
      currentUserId: currentUserId,
    );
  }
}
