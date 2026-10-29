import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/visitor/visitor_bloc.dart';
import '../../models/visitor_model.dart';
import '../../services/society_service.dart';
import '../../widgets/visitor_detail_sheet.dart';
import '../../widgets/premium_app_bar.dart';

class MemberVisitorsScreen extends StatefulWidget {
  final String? initialScope; // 'my_flat' or 'all_society'

  const MemberVisitorsScreen({super.key, this.initialScope});

  @override
  State<MemberVisitorsScreen> createState() => _MemberVisitorsScreenState();
}

class _MemberVisitorsScreenState extends State<MemberVisitorsScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchC = TextEditingController();
  String _searchQuery = '';

  late String _scope;
  String _statusFilter = 'all';
  String _timeFilter = 'today'; // 'today', '7d', '30d', 'all'

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope ?? 'my_flat';
    final societyId = SocietyService.instance.societyId;
    context.read<VisitorBloc>().add(
          VisitorSubscriptionRequested(
            societyId: societyId,
            scope: _scope,
            memberId: _currentUserId,
          ),
        );
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  DateTime? _getCutoffDate() {
    final now = DateTime.now();
    if (_timeFilter == 'today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (_timeFilter == '7d') {
      return now.subtract(const Duration(days: 7));
    }
    if (_timeFilter == '30d') {
      return now.subtract(const Duration(days: 30));
    }
    return null; // 'all'
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      if (status == 'approved') {
        context.read<VisitorBloc>().add(VisitorApproveRequested(visitorId: docId));
      } else if (status == 'rejected') {
        context.read<VisitorBloc>().add(VisitorRejectRequested(visitorId: docId));
      } else if (status == 'checked_out') {
        context.read<VisitorBloc>().add(VisitorCheckOutRequested(docId));
      } else {
        await AppFirestore.instance.collection('visitors').doc(docId).update({
          'status': status,
          'actionTime': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.'.tr : 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.'.tr,
          ),
          backgroundColor: status == 'approved' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સ્ટેટસ અપડેટ ભૂલ: $e'.tr), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: AppFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final rawBlock = (userData['blockName'] ?? '').toString();
        final userBlock = SocietyService.instance.logicalBlockName(rawBlock);
        final userUnit = (userData['unitNumber'] ?? '').toString();
        final userFlat = [userBlock, userUnit].where((s) => s.isNotEmpty).join(' • ');

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PremiumAppBar(
            title: 'વિઝિટર હિસ્ટ્રી & ટ્રેકિંગ'.tr,
            subtitle: 'ગેટ એન્ટ્રી, એક્ઝિટ અને લાઈવ સ્ટેટસ'.tr,
            icon: Icons.shield_rounded,
            accentColor: Color(0xFF0D9488),
          ),
          body: BlocBuilder<VisitorBloc, VisitorState>(
            builder: (context, visitorState) {
              final allVisitors = (visitorState is VisitorLoaded)
                  ? visitorState.allVisitors
                  : <VisitorModel>[];

              if (visitorState is VisitorLoading && allVisitors.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
              }

              // Filter by scope
              final myVisitors = allVisitors.where((v) {
                if (v.memberId == _currentUserId) return true;
                if (v.memberId == 'all_society') return true;
                if (userUnit.isNotEmpty &&
                    v.unitNumber == userUnit &&
                    (userBlock.isEmpty || v.blockName == userBlock)) {
                  return true;
                }
                return false;
              }).toList();

              final scopedList = _scope == 'my_flat' ? myVisitors : allVisitors;

              // Filter by Time
              final cutoff = _getCutoffDate();
              final timeFiltered = cutoff == null
                  ? scopedList
                  : scopedList.where((v) => v.entryTime.isAfter(cutoff)).toList();

              // Filter by Status
              final statusFiltered = _statusFilter == 'all'
                  ? timeFiltered
                  : timeFiltered.where((v) => v.status == _statusFilter).toList();

              // Search query filter
              final displayList = _searchQuery.isEmpty
                  ? statusFiltered
                  : statusFiltered.where((v) {
                      final q = _searchQuery.toLowerCase();
                      return v.name.toLowerCase().contains(q) ||
                          v.phone.contains(q) ||
                          v.purpose.toLowerCase().contains(q) ||
                          v.flatDisplay.toLowerCase().contains(q);
                    }).toList();

              // Compute Live Stats
              final pendingCount = scopedList.where((v) => v.status == 'pending').length;
              final approvedInsideCount = scopedList.where((v) => v.status == 'approved').length;
              final checkedOutCount = scopedList.where((v) => v.status == 'checked_out').length;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        // 1. Hero 3D Graphic Banner
                        _buildHeroHeader(userFlat, scopedList.length),

                        // 2. Search Box
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: TextField(
                            controller: _searchC,
                            decoration: InputDecoration(
                              hintText: 'નામ, ફોન, હેતુ કે ફ્લેટ નંબર શોધો...'.tr,
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                                      onPressed: () {
                                        _searchC.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                        ),

                        // 3. Scope Switcher
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildScopeBar(myVisitors.length, allVisitors.length),
                        ),
                        const SizedBox(height: 8),

                        // 4. Quick Metrics Strip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMetricsRow(
                            total: scopedList.length,
                            pending: pendingCount,
                            inside: approvedInsideCount,
                            out: checkedOutCount,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 5. Time Filter Options
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTimeFilterBar(),
                        ),
                        const SizedBox(height: 10),

                        // 6. Status Filter Tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatusTabs(
                            total: timeFiltered.length,
                            pending: timeFiltered.where((v) => v.status == 'pending').length,
                            approved: timeFiltered.where((v) => v.status == 'approved').length,
                            out: timeFiltered.where((v) => v.status == 'checked_out').length,
                            rejected: timeFiltered.where((v) => v.status == 'rejected').length,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 7. Visitor List Cards
                        if (displayList.isEmpty)
                          _buildEmptyState()
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final v = displayList[idx];
                                final isMyFlat = v.memberId == _currentUserId ||
                                    (userUnit.isNotEmpty &&
                                        v.unitNumber == userUnit &&
                                        (userBlock.isEmpty || v.blockName == userBlock)) ||
                                    v.memberId == 'all_society';

                                return _buildVisitorCard(v, isMyFlat: isMyFlat);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(String userFlat, int visitorCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/visitor_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF042F2E).withValues(alpha: 0.94),
                    const Color(0xFF0F766E).withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.apartment_rounded, color: Color(0xFF5EEAD4), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              userFlat.isNotEmpty ? userFlat : 'માય સોસાયટી'.tr,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'લાઇવ સિક્યુરિટી ગેટ'.tr,
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'સિક્યુરિટી વિઝિટર રજિસ્ટર'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'મુલાકાતીઓ: $visitorCount • કેમેરા ફોટો પુરાવા અને એન્ટ્રી/એક્ઝિટ સમય'.tr,
                        style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildScopeBar(int myCount, int allCount) {
    return Container(
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
              onTap: () => setState(() => _scope = 'my_flat'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _scope == 'my_flat' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _scope == 'my_flat'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                      color: _scope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'મારા ફ્લેટના'.tr,
                      style: TextStyle(
                        fontWeight: _scope == 'my_flat' ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        color: _scope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _scope == 'my_flat' ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$myCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _scope == 'my_flat' ? Colors.white : const Color(0xFF475569),
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
              onTap: () => setState(() => _scope = 'all_society'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _scope == 'all_society' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _scope == 'all_society'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                      color: _scope == 'all_society' ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'આખી સોસાયટી ગેટ'.tr,
                      style: TextStyle(
                        fontWeight: _scope == 'all_society' ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        color: _scope == 'all_society' ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _scope == 'all_society' ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$allCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _scope == 'all_society' ? Colors.white : const Color(0xFF475569),
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

  Widget _buildMetricsRow({required int total, required int pending, required int inside, required int out}) {
    return Row(
      children: [
        _metricPill('કુલ'.tr, total, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
        const SizedBox(width: 6),
        _metricPill('પેન્ડિંગ'.tr, pending, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        const SizedBox(width: 6),
        _metricPill('અંદર છે'.tr, inside, const Color(0xFF059669), const Color(0xFFECFDF5)),
        const SizedBox(width: 6),
        _metricPill('બહાર ગયા'.tr, out, const Color(0xFF64748B), const Color(0xFFF8FAFC)),
      ],
    );
  }

  Widget _metricPill(String label, int val, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              '$val',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterBar() {
    final opts = [
      ('today', 'આજે'.tr),
      ('7d', 'છેલ્લા ૭ દિવસ'.tr),
      ('30d', '૩૦ દિવસ'.tr),
      ('all', 'બધા સમય'.tr),
    ];

    return Row(
      children: opts.map((o) {
        final isSel = _timeFilter == o.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => setState(() => _timeFilter = o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF0D9488) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    o.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusTabs({
    required int total,
    required int pending,
    required int approved,
    required int out,
    required int rejected,
  }) {
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
          final isSelected = _statusFilter == t.$1;
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
                  setState(() => _statusFilter = key);
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

  (IconData, Color, Color) _getVisitorTypeMeta(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('pre-approved') || p.contains('પ્રી-એપ્રૂવ')) {
      return (Icons.how_to_reg_rounded, const Color(0xFF0F766E), const Color(0xFFCCFBF1));
    }
    if (p.contains('merchant') || p.contains('shop') || p.contains('દુકાન') || p.contains('વેપારી')) {
      return (Icons.storefront_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE));
    }
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

  String _getLocalizedPurpose(String purpose) {
    if (purpose.isEmpty) return 'અતિથિ (Guest)'.tr;
    final lower = purpose.toLowerCase().trim();
    if (lower == 'pre-approved guest' || lower.contains('pre-approved') || lower.contains('પ્રી-એપ્રૂવ')) {
      return 'Pre-Approved Guest'.tr;
    }
    if (lower == 'merchant / shop staff' || lower.contains('merchant') || lower.contains('shop staff') || lower.contains('વેપારી')) {
      return 'Merchant / Shop Staff'.tr;
    }
    if (lower == 'guest' || lower == 'અતિથિ' || lower.contains('guest')) {
      return 'Guest'.tr;
    }
    if (lower == 'delivery' || lower == 'ડિલિવરી' || lower.contains('delivery') || lower.contains('courier') || lower.contains('parcel')) {
      return 'Delivery'.tr;
    }
    if (lower == 'cab' || lower == 'taxi' || lower == 'ટેક્સી' || lower.contains('cab') || lower.contains('uber') || lower.contains('ola')) {
      return 'Cab'.tr;
    }
    if (lower == 'service / repair' || lower.contains('repair') || lower.contains('service') || lower.contains('રીપેરિંગ')) {
      return 'Service / Repair'.tr;
    }
    return purpose.tr;
  }

  Widget _buildVisitorCard(VisitorModel visitor, {required bool isMyFlat}) {
    final isPending = visitor.status == 'pending';
    final (typeIcon, typeColor, typeBg) = _getVisitorTypeMeta(visitor.purpose);
    final canAction = isPending && isMyFlat;

    final (statusColor, statusBg, statusBorder, statusText, statusIcon) = switch (visitor.status) {
      'approved' => (
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          'મંજૂર કરેલ'.tr,
          Icons.check_circle_rounded,
        ),
      'rejected' => (
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
          const Color(0xFFFECDD3),
          'અસ્વીકાર'.tr,
          Icons.cancel_rounded,
        ),
      'checked_out' => (
          const Color(0xFF475569),
          const Color(0xFFF1F5F9),
          const Color(0xFFCBD5E1),
          'બહાર ગયા'.tr,
          Icons.output_rounded,
        ),
      _ => (
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          'પેન્ડિંગ'.tr,
          Icons.hourglass_top_rounded,
        ),
    };

    final cardBorderColor = isPending
        ? const Color(0xFFFDE68A)
        : (visitor.status == 'rejected' ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorderColor,
          width: isPending ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: isPending ? 0.08 : 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              VisitorDetailSheet.show(
                context,
                visitor: visitor,
                isMyFlat: isMyFlat,
                onStatusUpdate: _updateStatus,
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canAction) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(19),
                        topRight: Radius.circular(19),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'ગેટ પર મંજૂરીની રાહ જુએ છે (Action Required)'.tr,
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF92400E)),
                      ],
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Visitor Photo with luxury squircle & purpose icon badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.8),
                              child: visitor.photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: visitor.photoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => _fallbackAvatar(visitor.name),
                                    )
                                  : _fallbackAvatar(visitor.name),
                            ),
                          ),
                          Positioned(
                            right: -3,
                            bottom: -3,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: typeBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(typeIcon, size: 11.5, color: typeColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 13),

                      // Middle Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    visitor.name.isNotEmpty ? visitor.name : "અનામી મુલાકાતી".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (visitor.purpose.toLowerCase().contains('pre-approved')) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0D9488)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (visitor.purpose.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: typeBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: typeColor.withValues(alpha: 0.25), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(typeIcon, size: 10.5, color: typeColor),
                                        const SizedBox(width: 3.5),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 130),
                                          child: Text(
                                            _getLocalizedPurpose(visitor.purpose),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
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
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.apartment_rounded, size: 10.5, color: Color(0xFF64748B)),
                                      const SizedBox(width: 3),
                                      Text(
                                        visitor.flatDisplay,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
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
                                const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 3.5),
                                Text(
                                  DateFormat('hh:mm a').format(visitor.entryTime),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                                if (visitor.status == 'checked_out' && visitor.exitTime != null) ...[
                                  const SizedBox(width: 6),
                                  const Text('•', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.logout_rounded, size: 11.5, color: Color(0xFF64748B)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      "બહાર: ${DateFormat('hh:mm a').format(visitor.exitTime!)}".tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Action Column (Call button + Status Badge)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (visitor.phone.isNotEmpty) ...[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _makeCall(visitor.phone),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF059669)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (!canAction)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusBorder, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 11, color: statusColor),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
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
      ),
    );
  }

  Widget _fallbackAvatar([String name = 'V']) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'V',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'કોઈ મુલાકાતી મળ્યા નથી'.tr,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 4),
            Text(
              'પસંદ કરેલ ફિલ્ટર અથવા સમયગાળામાં કોઈ એન્ટ્રી નથી.'.tr,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
