import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/visitor_model.dart';
import '../services/society_service.dart';
import '../widgets/visitor_detail_sheet.dart';
import '../widgets/premium_app_bar.dart';

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
      await AppFirestore.instance.collection('visitors').doc(docId).update({
        'status': status,
        'actionTime': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.' : 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.',
          ),
          backgroundColor: status == 'approved' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સ્ટેટસ અપડેટ ભૂલ: $e'), backgroundColor: Colors.red),
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
    final societyId = SocietyService.instance.societyId;

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
          appBar: const PremiumAppBar(
            title: 'વિઝિટર હિસ્ટ્રી & ટ્રેકિંગ',
            subtitle: 'ગેટ એન્ટ્રી, એક્ઝિટ અને લાઈવ સ્ટેટસ',
            icon: Icons.shield_rounded,
            accentColor: Color(0xFF0D9488),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
                .collection('visitors')
                .where('societyId', isEqualTo: societyId)
                .limit(200)
                .snapshots(),
            builder: (context, visitorSnap) {
              if (visitorSnap.connectionState == ConnectionState.waiting && !visitorSnap.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
              }

              final rawDocs = visitorSnap.hasData ? visitorSnap.data!.docs : <QueryDocumentSnapshot>[];

              // Parse to VisitorModels
              final allVisitors = rawDocs.map((d) => VisitorModel.fromFirestore(d)).toList();

              // Sort newest first
              allVisitors.sort((a, b) => b.entryTime.compareTo(a.entryTime));

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
                              hintText: 'નામ, ફોન, હેતુ કે ફ્લેટ નંબર શોધો...',
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
                              userFlat.isNotEmpty ? userFlat : 'માય સોસાયટી',
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'લાઇવ સિક્યુરિટી ગેટ',
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
                      const Text(
                        'સિક્યુરિટી વિઝિટર રજિસ્ટર',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'મુલાકાતીઓ: $visitorCount • કેમેરા ફોટો પુરાવા અને એન્ટ્રી/એક્ઝિટ સમય',
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
                      'મારા ફ્લેટના',
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
                      'આખી સોસાયટી ગેટ',
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
        _metricPill('કુલ', total, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
        const SizedBox(width: 6),
        _metricPill('પેન્ડિંગ', pending, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        const SizedBox(width: 6),
        _metricPill('અંદર છે', inside, const Color(0xFF059669), const Color(0xFFECFDF5)),
        const SizedBox(width: 6),
        _metricPill('બહાર ગયા', out, const Color(0xFF64748B), const Color(0xFFF8FAFC)),
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
      ('today', 'આજે'),
      ('7d', 'છેલ્લા ૭ દિવસ'),
      ('30d', '૩૦ દિવસ'),
      ('all', 'બધા સમય'),
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
      ('all', 'બધા', total, Icons.grid_view_rounded, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
      ('pending', 'પેન્ડિંગ', pending, Icons.hourglass_top_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      ('approved', 'મંજૂર', approved, Icons.check_circle_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5)),
      ('checked_out', 'બહાર ગયા', out, Icons.logout_rounded, const Color(0xFF475569), const Color(0xFFF1F5F9)),
      ('rejected', 'અસ્વીકાર', rejected, Icons.cancel_rounded, const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
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

  Widget _buildVisitorCard(VisitorModel visitor, {required bool isMyFlat}) {
    final isPending = visitor.status == 'pending';
    final canAction = isPending && isMyFlat;

    final (statusColor, statusBg, statusText) = switch (visitor.status) {
      'approved' => (const Color(0xFF059669), const Color(0xFFECFDF5), 'મંજૂર કરેલ'),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'અસ્વીકાર'),
      'checked_out' => (const Color(0xFF475569), const Color(0xFFF1F5F9), 'બહાર ગયા'),
      _ => (const Color(0xFFD97706), const Color(0xFFFFFBEB), 'પેન્ડિંગ'),
    };

    return Container(
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
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ગેટ પર મંજૂરીની રાહ જુએ છે (Action Required)',
                          style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: visitor.photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: visitor.photoUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _fallbackAvatar(),
                            )
                          : _fallbackAvatar(),
                    ),
                    const SizedBox(width: 14),

                    // Middle Column (Safe from overflow via Wrap and Flexible)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  visitor.name.isNotEmpty ? visitor.name : "અનામી મુલાકાતી",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (visitor.phone.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _makeCall(visitor.phone),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Badges in Wrap to avoid any pixel overflow
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (visitor.purpose.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    visitor.purpose,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  visitor.flatDisplay,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('hh:mm a').format(visitor.entryTime),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                              if (visitor.status == 'checked_out' && visitor.exitTime != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  "• બહાર: ${DateFormat('hh:mm a').format(visitor.exitTime!)}",
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                      ),
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
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(visitor.id, 'approved'),
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            label: const Text('પ્રવેશ મંજૂર', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus(visitor.id, 'rejected'),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 16),
                            label: const Text('નકારો', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: const Color(0xFFFEF2F2),
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

  Widget _fallbackAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFF0D9488)),
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
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'કોઈ મુલાકાતી મળ્યા નથી',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 4),
            Text(
              'પસંદ કરેલ ફિલ્ટર અથવા સમયગાળામાં કોઈ એન્ટ્રી નથી.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
