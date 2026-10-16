import 'dart:async';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/visitor_model.dart';
import '../models/maintenance_model.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/member_maintenance_sheet.dart';
import 'member_complaint_register_screen.dart';
import 'member_daily_staff_screen.dart';
import 'member_pre_approve_screen.dart';
import 'member_vehicles_screen.dart';

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

  late final Stream<QuerySnapshot> _visitorsStream;
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
    });
    // Single field equality query prevents Cloud Firestore composite index requirement
    _visitorsStream = AppFirestore.instance
        .collection('visitors')
        .where('memberId', isEqualTo: currentUserId)
        .limit(100)
        .snapshots();
    _userStream = AppFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots();
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
            status == 'approved' ? 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.' : 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.',
          ),
          backgroundColor: status == 'approved' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// મેમ્બર ઘરે પ્રોબ્લેમ / ઇમરજન્સી — એડમિન + ગેટ વોચમેનને નોટિફિકેશન
  Future<void> _showMemberEmergencyDialog() async {
    final noteC = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.emergency_share_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('ઇમરજન્સી SOS મદદ'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'એડમિન અને સોસાયટી ગેટ વોચમેનને તાત્કાલિક એલર્ટ નોટિફિકેશન જશે.',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteC,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'વિગત (વૈકલ્પિક)',
                  hintText: 'દા.ત. તબિયત ખરાબ છે, સુરક્ષા સમસ્યા...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('રદ કરો'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('હા, SOS મોકલો'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final userDoc = await AppFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final d = userDoc.data() ?? {};
      final name = d['name'] ?? 'મેમ્બર';
      final block = d['blockName'] ?? '';
      final unit = d['unitNumber'] ?? '';
      final flat = [
        block,
        unit,
      ].where((e) => e.toString().isNotEmpty).join('-');
      final note = noteC.text.trim();
      final bodyBase =
          '$name — ઘર: ${flat.isEmpty ? "?" : flat}. મેમ્બર ઇમરજન્સી માંગે છે.';
      final body = note.isEmpty ? bodyBase : '$bodyBase\nવિગત: $note';

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
        'title': '🚨 મેમ્બર ઇમરજન્સી',
        'body': body,
        'type': 'member_emergency',
      });
      await callable.call<Map<String, dynamic>>({
        'topicKind': 'watchmen',
        'title': '🚨 મેમ્બર ઇમરજન્સી (ગેટ)',
        'body': body,
        'type': 'member_emergency',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('મદદની સૂચના એડમિન અને ગેટને સફળતાપૂર્વક મોકલાઈ.'),
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
          SnackBar(content: Text('ભૂલ: $line'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ભૂલ: $e'), backgroundColor: Colors.red),
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
      MaterialPageRoute(builder: (_) => const MemberVehiclesScreen()),
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
    return now.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final memberName = userData['name']?.toString() ?? 'મેમ્બર';
        final blockName = userData['blockName']?.toString() ?? '';
        final unitNumber = userData['unitNumber']?.toString() ?? '';
        final flatDisplay = [blockName, unitNumber].where((s) => s.isNotEmpty).join(' • ');

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildMemberAppBar(flatDisplay),
          body: StreamBuilder<QuerySnapshot>(
            stream: _visitorsStream,
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

              // Calculate Status Counts
              final pendingCount = tenantDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;
              final approvedCount = tenantDocs.where((d) => (d.data() as Map)['status'] == 'approved').length;
              final checkedOutCount = tenantDocs.where((d) => (d.data() as Map)['status'] == 'checked_out').length;
              final rejectedCount = tenantDocs.where((d) => (d.data() as Map)['status'] == 'rejected').length;

              // Filter by cutoff date
              final cutoff = _memberCutoffDate();
              final timeFiltered = tenantDocs.where((d) {
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
                    _buildMemberProfileHero(memberName, flatDisplay, pendingCount),
                    const SizedBox(height: 14),

                    // ૨. Top Executive Stat Cards
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

                    // ૬. Visitors Section Header
                    Row(
                      children: [
                        const Expanded(
                          child: PremiumSectionHeader(
                            title: "તાજેતરના મુલાકાતીઓ",
                            icon: Icons.history_rounded,
                          ),
                        ),
                        _buildTimeFilterPill(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ૭. Status Filter Tabs (Admin style)
                    _buildStatusFilterTabs(
                      tenantDocs.length,
                      pendingCount,
                      approvedCount,
                      rejectedCount,
                      checkedOutCount,
                    ),
                    const SizedBox(height: 14),

                    // ૮. Visitor List Items
                    if (visitorSnap.connectionState == ConnectionState.waiting && rawDocs.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    else if (filteredVisitors.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "કોઈ મુલાકાતી મળ્યા નથી",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _visitorStatusFilter == 'all'
                                  ? "તમારા ફ્લેટ પર હાલમાં કોઈ મુલાકાતી આવ્યા નથી."
                                  : "આ ફિલ્ટરમાં કોઈ મુલાકાતી મળ્યા નથી.",
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredVisitors.map((doc) {
                        final v = VisitorModel.fromFirestore(doc);
                        return _buildVisitorCard(v);
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

  PreferredSizeWidget _buildMemberAppBar(String flatDisplay) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
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
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 21),
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
                    const Flexible(
                      child: Text(
                        "માય સોસાયટી",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (flatDisplay.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Text(
                          flatDisplay,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ],
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
                        "મેમ્બર પોર્ટલ • ૨૪×૭ સુરક્ષિત નિવાસ",
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
              // Emergency SOS Button
              Tooltip(
                message: 'ઇમરજન્સી SOS મદદ',
                child: InkWell(
                  onTap: _showMemberEmergencyDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEE2E8F0 != 0 ? 0xFFFEE2E2 : 0xFFFFFFFF)),
                    ),
                    child: const Icon(
                      Icons.emergency_share_rounded,
                      size: 19,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              // Logout Button
              Tooltip(
                message: 'લોગઆઉટ',
                child: InkWell(
                  onTap: () => FirebaseAuth.instance.signOut(),
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
                      Icons.logout_rounded,
                      size: 18,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
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
                            "નમસ્તે, $name",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF38BDF8)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      flat.isNotEmpty ? "રહેવાસી • ફ્લેટ: $flat" : "સોસાયટી માન્ય સભ્ય",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Color(0xFFF87171), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$pending મુલાકાતી ગેટ પર તમારી મંજૂરીની રાહ જુએ છે!",
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveStatsRow(int pending, int approved, int out) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "પેન્ડિંગ",
            count: pending,
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "મંજૂર કરેલ",
            count: approved,
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "બહાર ગયા",
            count: out,
            icon: Icons.output_rounded,
            color: const Color(0xFF475569),
            bgColor: const Color(0xFFF8FAFC),
            borderColor: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Column(
      children: [
        // Top 2 Primary Actions (Guest Pass QR & Maintenance Bill)
        Row(
          children: [
            Expanded(
              child: _primaryActionCard(
                title: "ગેસ્ટ પાસ (QR)",
                subtitle: "પ્રી-એપ્રુવલ પાસ",
                icon: Icons.qr_code_scanner_rounded,
                gradient: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                onTap: _showPreApproveDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _primaryActionCard(
                title: "મેન્ટેનન્સ બિલ",
                subtitle: "બિલિંગ & QR પે",
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                onTap: () => _showMaintenancePortal(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Secondary 3 Actions
        Row(
          children: [
            Expanded(
              child: _secondaryActionCard(
                title: "ફરિયાદ",
                icon: Icons.report_problem_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: _showComplaintDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _secondaryActionCard(
                title: "કાયમી સ્ટાફ",
                icon: Icons.badge_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                onTap: _showAddStaffDialog,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _secondaryActionCard(
                title: "વાહનો",
                icon: Icons.directions_car_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: _showMyVehiclesDialog,
              ),
            ),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _secondaryActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterTabs(int total, int pending, int approved, int rejected, int out) {
    final tabs = [
      ('all', 'બધા ($total)'),
      ('pending', 'પેન્ડિંગ ($pending)'),
      ('approved', 'મંજૂર ($approved)'),
      ('rejected', 'અસ્વીકાર ($rejected)'),
      ('checked_out', 'બહાર ગયા ($out)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSelected = _visitorStatusFilter == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _visitorStatusFilter = t.$1),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    t.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeFilterPill() {
    final options = [
      ('today', 'આજે'),
      ('7d', '૭ દિવસ'),
      ('30d', '૩૦ દિવસ'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = _visitorTimeFilter == opt.$1;
          return GestureDetector(
            onTap: () => setState(() => _visitorTimeFilter = opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Visitor Photo or Squircle Initial
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: visitor.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: visitor.photoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _fallbackVisitorAvatar(visitor.name),
                  )
                : _fallbackVisitorAvatar(visitor.name),
          ),
          const SizedBox(width: 12),
          // Visitor Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name.isNotEmpty ? visitor.name : "અનામી મુલાકાતી",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (visitor.purpose.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          visitor.purpose,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      DateFormat('hh:mm a').format(visitor.entryTime),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (visitor.status == 'checked_out' && visitor.exitTime != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    "બહાર ગયા: ${DateFormat('hh:mm a').format(visitor.exitTime!)}",
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status / Approval Actions
          _buildStatusAction(visitor),
        ],
      ),
    );
  }

  Widget _fallbackVisitorAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'V',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAction(VisitorModel visitor) {
    if (visitor.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accept Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _updateStatus(visitor.id, 'approved'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Color(0xFF059669), size: 15),
                    SizedBox(width: 4),
                    Text(
                      "મંજૂર",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Reject Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _updateStatus(visitor.id, 'rejected'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 15),
              ),
            ),
          ),
        ],
      );
    }

    final (color, bgColor, text, icon) = switch (visitor.status) {
      'approved' => (const Color(0xFF059669), const Color(0xFFECFDF5), 'મંજૂર કરેલ', Icons.check_circle_rounded),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'અસ્વીકાર', Icons.cancel_rounded),
      'checked_out' => (const Color(0xFF475569), const Color(0xFFF1F5F9), 'બહાર ગયા', Icons.output_rounded),
      _ => (const Color(0xFFD97706), const Color(0xFFFFFBEB), 'પેન્ડિંગ', Icons.hourglass_top_rounded),
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

  // નોટિસ બોર્ડ વિજેટ (Executive Gradient Card)
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
        final body = (data['body'] ?? '').toString();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.22),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFFFCD34D), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "સોસાયટી મહત્વની સૂચના",
                    style: TextStyle(
                      color: Color(0xFFFCD34D),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ],
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
