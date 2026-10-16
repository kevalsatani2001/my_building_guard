import 'package:building_guard/core/app_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/visitor_model.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/member_maintenance_sheet.dart';
import '../models/maintenance_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
    });
  }

  // ૧. સ્ટેટસ અપડેટ ફંક્શન (watchmanId ડોક પર રહે — Cloud Function થી વોચમેનને નોટિફિકેશન)
  Future<void> _updateStatus(String docId, String status) async {
    await AppFirestore.instance.collection('visitors').doc(docId).update({
      'status': status,
      'actionTime': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'મંજૂરી મોકલી.' : 'નકાર મોકલ્યો.',
          ),
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
          title: const Text('ઇમરજન્સી મદદ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'એડમિન અને સોસાયટી ગેટને સૂચના જશે. ખોટી કૉલ ન કરતાં.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteC,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'વિગત (વૈકલ્પિક)',
                  hintText: 'દા.ત. તબિયત, સલામતી...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('રદ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red[800]),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('મદદ મોકલો'),
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
            content: Text('મદદની સૂચના મોકલાઈ. શાંતિ રાખો.'),
            backgroundColor: Colors.green,
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "માય સોસાયટી",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "મેમ્બર પોર્ટલ • સુરક્ષિત નિવાસ",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: IconButton(
              icon: const Icon(Icons.emergency_share_rounded, size: 20, color: Colors.red),
              tooltip: 'ઇમરજન્સી મદદ',
              onPressed: _showMemberEmergencyDialog,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF64748B)),
              tooltip: 'લોગઆઉટ',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            _buildMemberSummaryCard(),
            // --- ૧. Notice Board Section ---
            _buildNoticeBoard(),

            // --- ૧.૫ મેન્ટેનન્સ એલર્ટ બેનર ---
            _buildMaintenanceBanner(),

            // --- ૨. Quick Actions ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showPreApproveDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "ગેસ્ટ પાસ (QR)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showMaintenancePortal(),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "મેન્ટેનન્સ બિલ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSmallMemberAction(
                      icon: Icons.report_problem_rounded,
                      label: 'ફરિયાદ',
                      color: const Color(0xFF8B5CF6),
                      onTap: _showComplaintDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallMemberAction(
                      icon: Icons.badge_rounded,
                      label: 'કાયમી સ્ટાફ',
                      color: const Color(0xFFF59E0B),
                      onTap: _showAddStaffDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallMemberAction(
                      icon: Icons.directions_car_rounded,
                      label: 'વાહનો',
                      color: const Color(0xFF3B82F6),
                      onTap: _showMyVehiclesDialog,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PremiumSectionHeader(
                  title: "તાજેતરના મુલાકાતીઓ",
                  icon: Icons.history_rounded,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildVisitorFilterRow(),
            _buildVisitorTimeFilterRow(),
            _buildMemberVisitorGraph(),

            // --- ૩. Visitor History List ---
            Expanded(child: _buildVisitorList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMemberAction({
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('visitors')
          .where('memberId', isEqualTo: currentUserId)
          .orderBy('entryTime', descending: true)
          .limit(120)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData
            ? snapshot.data!.docs.where((d) {
                return SocietyService.instance.documentBelongsToCurrentTenant(
                  d.data() as Map<String, dynamic>?,
                );
              }).toList()
            : <QueryDocumentSnapshot>[];
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final checkedOut = docs
            .where((d) => d['status'] == 'checked_out')
            .length;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
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
              _miniStat("બાકી મુલાકાતી", pending, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              _miniStat("મંજૂર કરેલ", approved, const Color(0xFF10B981), const Color(0xFFECFDF5)),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              _miniStat("બહાર ગયેલ", checkedOut, const Color(0xFF64748B), const Color(0xFFF8FAFC)),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, int count, Color color, Color bg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorFilterRow() {
    final options = <(String, String)>[
      ('all', 'All'),
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
      ('checked_out', 'Out'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((item) {
          final selected = _visitorStatusFilter == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: selected,
              onSelected: (_) {
                setState(() => _visitorStatusFilter = item.$1);
              },
            ),
          );
        }).toList(),
      ),
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

  Widget _buildVisitorTimeFilterRow() {
    final options = <(String, String)>[
      ('today', 'Today'),
      ('7d', '7 Days'),
      ('30d', '30 Days'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: _visitorTimeFilter == item.$1,
              onSelected: (_) => setState(() => _visitorTimeFilter = item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberVisitorGraph() {
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('visitors')
          .where('memberId', isEqualTo: currentUserId)
          .orderBy('entryTime', descending: true)
          .limit(250)
          .snapshots(),
      builder: (context, snapshot) {
        final cutoff = _memberCutoffDate();
        final docs = snapshot.hasData
            ? snapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>?;
                if (!SocietyService.instance.documentBelongsToCurrentTenant(
                  data,
                )) {
                  return false;
                }
                final ts = data?['entryTime'];
                if (ts is! Timestamp) return false;
                return ts.toDate().isAfter(cutoff);
              }).toList()
            : <QueryDocumentSnapshot>[];
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final rejected = docs.where((d) => d['status'] == 'rejected').length;
        final out = docs.where((d) => d['status'] == 'checked_out').length;
        final maxVal = [
          approved,
          pending,
          rejected,
          out,
          1,
        ].reduce((a, b) => a > b ? a : b);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _graphCol('Appr', approved, maxVal, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _graphCol('Pend', pending, maxVal, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(child: _graphCol('Rej', rejected, maxVal, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _graphCol('Out', out, maxVal, Colors.blueGrey)),
            ],
          ),
        );
      },
    );
  }

  Widget _graphCol(String label, int count, int maxCount, Color color) {
    final ratio = (count / maxCount).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 14 + (56 * ratio),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // નોટિસ બોર્ડ વિજેટ
  Widget _buildNoticeBoard() {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: AppFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final tenantDocs = snapshot.data!.docs.where((d) {
          return SocietyService.instance.documentBelongsToCurrentTenant(
            d.data() as Map<String, dynamic>?,
          );
        }).toList();
        if (tenantDocs.isEmpty) return const SizedBox();
        var notice = tenantDocs.first;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.secondary.withValues(alpha: 0.9), cs.primary],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cs.secondary.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "મહત્વની સૂચના",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notice['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((notice['body'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  notice['body'].toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  // --- મારા વાહનો મેનેજમેન્ટ ---
  void _showMyVehiclesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberVehiclesScreen()),
    );
  }

  // વિઝિટર લિસ્ટ વિજેટ
  Widget _buildVisitorList() {
    return StreamBuilder<QuerySnapshot>(
      // societyId ફિલ્ટર ક્વેરીમાં નહીં — જૂના visitors પાસે ફીલ્ડ ન હોય તો પણ દેખાય; ક્લાયન્ટ પર ટેનન્ટ ચેક.
      stream: AppFirestore.instance
          .collection('visitors')
          .where('memberId', isEqualTo: currentUserId)
          .orderBy('entryTime', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'લોડ ભૂલ: ${snapshot.error}\n'
                '(Firestore કમ્પોઝિટ ઇન્ડેક્સ જોઈએ: memberId + entryTime)',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.where((d) {
          return SocietyService.instance.documentBelongsToCurrentTenant(
            d.data() as Map<String, dynamic>?,
          );
        }).toList();
        final cutoff = _memberCutoffDate();
        final timeFiltered = docs.where((d) {
          final ts = (d.data() as Map<String, dynamic>?)?['entryTime'];
          if (ts is! Timestamp) return false;
          return ts.toDate().isAfter(cutoff);
        }).toList();
        final filteredByStatus = _visitorStatusFilter == 'all'
            ? timeFiltered
            : timeFiltered
                  .where((d) => d['status'] == _visitorStatusFilter)
                  .toList();
        if (filteredByStatus.isEmpty) {
          return const PremiumEmptyState(
            message: "કોઈ ડેટા નથી",
            icon: Icons.history_toggle_off,
          );
        }

        return ListView.builder(
          itemCount: filteredByStatus.length,
          itemBuilder: (context, index) {
            var visitor = VisitorModel.fromFirestore(filteredByStatus[index]);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: visitor.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: visitor.photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.person),
                        )
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.person, size: 40),
                        ),
                ),
                title: Text(
                  visitor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // બધું ડાબી બાજુથી શરૂ થાય તે માટે
                  children: [
                    // જૂનું હેતુ અને સમયનું ટેક્સ્ટ
                    Text(
                      "${visitor.purpose}\n${DateFormat('jm').format(visitor.entryTime)}",
                    ),

                    // 🔥 અહીં નવું 'Checked Out' સમયનું લોજિક
                    if (visitor.status == 'checked_out' &&
                        visitor.exitTime != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ), // થોડી જગ્યા રાખવા માટે
                        child: Text(
                          "બહાર ગયા: ${DateFormat('hh:mm a').format(visitor.exitTime!)}",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: _buildStatusAction(visitor),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildStatusAction(VisitorModel visitor) {
    if (visitor.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            onPressed: () => _updateStatus(visitor.id, 'approved'),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            onPressed: () => _updateStatus(visitor.id, 'rejected'),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visitor.status == 'approved' ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        visitor.status == 'approved' ? "મંજૂર" : "અસ્વીકાર",
        style: TextStyle(
          color: visitor.status == 'approved'
              ? Colors.green[700]
              : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
