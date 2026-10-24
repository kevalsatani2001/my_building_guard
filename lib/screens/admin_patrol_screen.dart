import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:building_guard/core/app_firestore.dart';
import '../models/patrol_model.dart';
import '../services/guard_patrol_service.dart';
import '../l10n/app_strings.dart';
import '../services/localization_service.dart';

class AdminPatrolScreen extends StatefulWidget {
  final String? societyId;

  const AdminPatrolScreen({super.key, this.societyId});

  @override
  State<AdminPatrolScreen> createState() => _AdminPatrolScreenState();
}

class _AdminPatrolScreenState extends State<AdminPatrolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GuardPatrolService _service = GuardPatrolService();
  String? _effectiveSocietyId;
  String? _societyName;
  bool _isLoading = true;

  String? _selectedDateFilter; // 'yyyy-MM-dd' or null for all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSocietyContext();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSocietyContext() async {
    if (widget.societyId != null && widget.societyId!.isNotEmpty) {
      _effectiveSocietyId = widget.societyId;
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await AppFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _effectiveSocietyId = doc.data()?['societyId']?.toString();
        }
      }
    }

    if (_effectiveSocietyId != null && _effectiveSocietyId!.isNotEmpty) {
      final socDoc = await AppFirestore.instance
          .collection('societies')
          .doc(_effectiveSocietyId)
          .get();
      if (socDoc.exists) {
        _societyName = socDoc.data()?['name']?.toString() ?? 'સોસાયટી'.tr;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'સુરક્ષા નાઈટ પેટ્રોલિંગ ઓડિટ'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'વોચમેન QR સ્કેન અને રાત્રિ સુરક્ષા રિપોર્ટ'.tr,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5), size: 19),
            ),
            tooltip: 'પેટ્રોલિંગ માર્ગદર્શિકા'.tr,
            onPressed: _showInfoGuideSheet,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: LanguageSwitchButton()),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 17),
                      SizedBox(width: 8),
                      Text('ઓડિટ રિપોર્ટ લોગ'.tr),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 17),
                      SizedBox(width: 8),
                      Text('ચેકપોઇન્ટ્સ & QR કોડ'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _effectiveSocietyId == null || _effectiveSocietyId!.isEmpty
              ? Center(
                  child: Text('સોસાયટી ઓળખ મળી નથી. કૃપા કરીને ફરી લૉગિન કરો.'.tr),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPatrolAuditTab(),
                    _buildCheckpointsTab(),
                  ],
                ),
    );
  }

  // ================= TAB 1: PATROL AUDIT TAB =================

  Widget _buildPatrolAuditTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.getPatrolComplianceStats(_effectiveSocietyId!),
      builder: (context, statsSnap) {
        final stats = statsSnap.data ?? {};
        final compliancePercent = (stats['compliancePercent'] as num?)?.toInt() ?? 0;
        final completedRounds = (stats['completedRounds'] as num?)?.toInt() ?? 0;
        final targetRounds = (stats['targetRounds'] as num?)?.toInt() ?? 4;
        final totalIncidents = (stats['totalIncidents'] as num?)?.toInt() ?? 0;
        final statusMsg = stats['statusMessage'] as String? ?? 'ઓડિટ લોડ થઈ રહ્યું છે...'.tr;

        return Column(
          children: [
            // Top Compliance Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.verified_user_rounded,
                                color: Color(0xFF818CF8), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'સુરક્ષા કમ્પ્લાયન્સ સ્કોર'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: compliancePercent >= 75
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: compliancePercent >= 75
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        child: Text(
                          '$compliancePercent% સ્કોર'.tr,
                          style: TextStyle(
                            color: compliancePercent >= 75
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    statusMsg,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.check_circle_outline,
                          label: 'પૂર્ણ રાઉન્ડ'.tr,
                          value: '$completedRounds / $targetRounds',
                          color: const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.warning_amber_rounded,
                          label: 'નોંધાયેલ સમસ્યાઓ'.tr,
                          value: '$totalIncidents બાબત'.tr,
                          color: totalIncidents > 0
                              ? const Color(0xFFF87171)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date Filters Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'રાઉન્ડ હિસ્ટ્રી:'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  ChoiceChip(
                    label: Text('બધા'.tr),
                    selected: _selectedDateFilter == null,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDateFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('આજે'.tr),
                    selected: _selectedDateFilter ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    onSelected: (val) {
                      setState(() {
                        _selectedDateFilter = val
                            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('ગઈકાલે'.tr),
                    selected: _selectedDateFilter ==
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.now().subtract(const Duration(days: 1))),
                    onSelected: (val) {
                      setState(() {
                        _selectedDateFilter = val
                            ? DateFormat('yyyy-MM-dd').format(
                                DateTime.now().subtract(const Duration(days: 1)))
                            : null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Stream List of Sessions
            Expanded(
              child: StreamBuilder<List<PatrolShiftSession>>(
                stream: _service.streamSessions(
                  _effectiveSocietyId!,
                  dateFilter: _selectedDateFilter,
                ),
                builder: (context, sessionSnap) {
                  if (sessionSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessions = sessionSnap.data ?? [];
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nightlight_round,
                              size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'કોઈ પેટ્રોલિંગ રાઉન્ડ મળ્યા નથી'.tr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'વોચમેન એપમાંથી રાઉન્ડ શરૂ કરશે ત્યારે અહીં લાઈવ જોવા મળશે.'.tr,
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      return _buildSessionCard(s);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(PatrolShiftSession s) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM, yyyy');

    final bool isDone = s.isCompleted;
    final statusColor = isDone
        ? const Color(0xFF10B981)
        : s.isInProgress
            ? const Color(0xFF3B82F6)
            : const Color(0xFFEF4444);

    final statusText = isDone
        ? 'સફળતાપૂર્વક પૂર્ણ'.tr
        : s.isInProgress
            ? 'રાઉન્ડ ચાલુ છે'.tr
            : 'અધૂરો / છૂટી ગયેલ'.tr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            isDone ? Icons.check_circle_rounded : Icons.radar_rounded,
            color: statusColor,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              s.roundLabel.isNotEmpty ? s.roundLabel : 'રાઉન્ડ ${s.roundNumber}'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'તારીખ: ${dateFormat.format(s.startTime)} • સમય: ${timeFormat.format(s.startTime)}${s.endTime != null ? '.tr થી ${timeFormat.format(s.endTime!)}' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                'ગાર્ડ: ${s.guardName} (${s.guardPhone}) • ચેકપોઇન્ટ્સ: ${s.scannedCount}/${s.totalCheckpoints}'.tr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              if (s.hasIncident) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.report_problem, size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'નોંધાયેલ સમસ્યા છે (વિગત જુઓ)'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ચેકપોઇન્ટ સ્કેન ટાઇમલાઇન:'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                if (s.scanLogs.isEmpty)
                  Text(
                    'હજુ સુધી કોઈ ચેકપોઇન્ટ સ્કેન થયો નથી.'.tr,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  )
                else
                  ...s.scanLogs.map((log) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: log.isIncidentReported
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            log.isIncidentReported
                                ? Icons.warning_rounded
                                : Icons.check_circle,
                            size: 18,
                            color: log.isIncidentReported
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${log.checkpointCode} - ${log.checkpointName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeFormat.format(log.scannedAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (log.isIncidentReported &&
                                    log.incidentNote != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'નોંધ: ${log.incidentNote}'.tr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: CHECKPOINTS MANAGEMENT & QR =================

  Widget _buildCheckpointsTab() {
    return StreamBuilder<List<PatrolCheckpoint>>(
      stream: _service.streamCheckpoints(_effectiveSocietyId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final checkpoints = snap.data ?? [];

        return Column(
          children: [
            // Top Action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'કુલ ${checkpoints.length} સિક્યોરિટી ચેકપોઇન્ટ્સ'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ચેકપોઇન્ટના QR કોડ પ્રિન્ટ કરીને સંબંધિત જગ્યાએ ચોંટાડો'.tr,
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showAddCheckpointSheet(checkpoints.length + 1),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                    label: Text('નવો ઉમેરો'.tr, style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Checkpoints List
            Expanded(
              child: checkpoints.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 48,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'હજુ કોઈ ચેકપોઇન્ટ ઉમેરેલ નથી'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'વોચમેન નાઈટ પેટ્રોલિંગ માટે સોસાયટીના ગેટ, ટેરેસ, બેઝમેન્ટ જેવા સ્થળો ઉમેરો અને QR સ્ટીકર પ્રિન્ટ કરો.'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () => _showAddCheckpointSheet(1),
                              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                              label: Text(
                                '+ પ્રથમ ચેકપોઇન્ટ ઉમેરો'.tr,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: checkpoints.length,
                      itemBuilder: (context, index) {
                        final cp = checkpoints[index];
                        return _buildCheckpointCard(cp, index + 1);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckpointCard(PatrolCheckpoint cp, int seqNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order sequence badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
              '$seqNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        cp.code,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'સ્થળ: ${cp.location}'.tr,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (cp.notes != null && cp.notes!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'સૂચના: ${cp.notes}'.tr,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        foregroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                        ),
                      ),
                      onPressed: () => _showPrintableQrDialog(cp),
                      icon: const Icon(Icons.qr_code_2_rounded,
                          size: 16, color: Color(0xFF4F46E5)),
                      label: Text(
                        'QR કોડ જુઓ / પ્રિન્ટ'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 17, color: Color(0xFFEF4444)),
                      ),
                      tooltip: 'કાઢી નાખો'.tr,
                      onPressed: () => _confirmDeleteCheckpoint(cp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MODALS & DIALOGS =================

  void _showAddCheckpointSheet(int defaultOrder) {
    final codeCtrl = TextEditingController(text: 'CP0$defaultOrder');
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final suggestions = [
      {'name': 'મુખ્ય પ્રવેશ દ્વાર'.tr, 'loc': 'ગ્રાઉન્ડ ફ્લોર - ગેટ સામે'.tr},
      {'name': 'વિંગ A ટેરેસ એન્ટ્રી'.tr, 'loc': 'ટોપ ફ્લોર - ટેરેસ ડોર'.tr},
      {'name': 'વિંગ B ટેરેસ એન્ટ્રી'.tr, 'loc': 'ટોપ ફ્લોર - ટેરેસ ડોર'.tr},
      {'name': 'બેઝમેન્ટ B1 પાર્કિંગ'.tr, 'loc': 'બેઝમેન્ટ - પિલર નં. ૫ પાસે'.tr},
      {'name': 'જનરેટર / ઇલેક્ટ્રિક રૂમ'.tr, 'loc': 'ગ્રાઉન્ડ લેવલ - યુટિલિટી બ્લોક'.tr},
      {'name': 'પાછળનો ગાર્ડન / પ્લે એરિયા'.tr, 'loc': 'પાછળની બાઉન્ડ્રી વોલ'.tr},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'નવો સુરક્ષા ચેકપોઇન્ટ ઉમેરો'.tr,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'વોચમેન સ્કેન કરવા માટે QR સ્ટીકર જનરેટ થશે'.tr,
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkpoint Code & Order
                          Text(
                            'ચેકપોઇન્ટ કોડ & ક્રમ *'.tr,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  'ક્રમ: #$defaultOrder'.tr,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: codeCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'દા.ત. CP01, CP02'.tr,
                                    prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: Color(0xFF4F46E5)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checkpoint Name
                          Text(
                            'ચેકપોઇન્ટનું નામ *'.tr,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'દા.ત. મુખ્ય પ્રવેશ દ્વાર (Main Gate)'.tr,
                              prefixIcon: const Icon(Icons.business_rounded, size: 20, color: Color(0xFF4F46E5)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Quick Chips for Name
                          Text(
                            'ઝડપી પસંદગી:'.tr,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: suggestions.map((s) {
                              return InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    nameCtrl.text = s['name']!;
                                    locCtrl.text = s['loc']!;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: Text(
                                    s['name']!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Location description
                          Text(
                            'ચોક્કસ સ્થળ વર્ણન *'.tr,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: locCtrl,
                            decoration: InputDecoration(
                              hintText: 'દા.ત. ગ્રાઉન્ડ ફ્લોર - સિક્યોરિટી કેબિન સામે'.tr,
                              prefixIcon: const Icon(Icons.pin_drop_rounded, size: 20, color: Color(0xFF4F46E5)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Security instruction
                          Text(
                            'સુરક્ષા સૂચના / ગાર્ડ માટે નોંધ (વૈકલ્પિક)'.tr,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'દા.ત. રાત્રે તાળું અને લાઈટ ચાલુ છે તે ખાસ ચકાસવું...'.tr,
                              prefixIcon: const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom pinned button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('કૃપા કરીને નામ અને સ્થળ દાખલ કરો.'.tr)),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await _service.addCheckpoint(
                            societyId: _effectiveSocietyId!,
                            code: codeCtrl.text.trim().toUpperCase(),
                            name: nameCtrl.text.trim(),
                            location: locCtrl.text.trim(),
                            order: defaultOrder,
                            notes: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ચેકપોઇન્ટ સફળતાપૂર્વક ઉમેરાઈ ગયો! 🎉'.tr),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.verified_rounded, size: 20),
                        label: Text(
                          'ચેકપોઇન્ટ સાચવો અને QR મેળવો'.tr,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInfoGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_moon_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'નાઈટ પેટ્રોલિંગ સિસ્ટમ માર્ગદર્શિકા'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'સુરક્ષા ગાર્ડ અને કમિટી માટે ઓડિટ નિયમો'.tr,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
            _buildInfoStep(
              step: '૧'.tr,
              title: 'ચેકપોઇન્ટ્સ ઉમેરો (Add Checkpoints)'.tr,
              desc: 'સોસાયટીના મુખ્ય સુરક્ષા સ્થળો જેમ કે મુખ્ય ગેટ, ટેરેસ, બેઝમેન્ટ પાર્કિંગ, પંપ રૂમ ઉમેરો.'.tr,
              icon: Icons.add_location_alt_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoStep(
              step: '૨'.tr,
              title: 'QR સ્ટીકર પ્રિન્ટ કરી લગાવો'.tr,
              desc: 'દરેક ચેકપોઇન્ટનું "QR કોડ જુઓ / પ્રિન્ટ" કરી તે સંબંધિત સ્થળની દિવાલ પર વોટરપ્રૂફ સ્ટીકર લગાવો.'.tr,
              icon: Icons.qr_code_2_rounded,
            ),
            const SizedBox(height: 12),
            _buildInfoStep(
              step: '૩'.tr,
              title: 'વોચમેન રાત્રિ પેટ્રોલિંગ અને સ્કેન'.tr,
              desc: 'વોચમેન રાત્રે ૧૧:૦૦ PM થી સવારે ૬:૦૦ AM દરમિયાન એપથી ટોર્ચ અને કેમેરા વડે QR સ્કેન કરી રાઉન્ડ પૂર્ણ કરશે.'.tr,
              icon: Icons.radar_rounded,
            ),
            const SizedBox(height: 12),
            _buildInfoStep(
              step: '૪'.tr,
              title: 'સવારે લાઈવ ઓડિટ અને પ્રમાણપત્ર'.tr,
              desc: 'કમિટી સમય અને સ્થળ સાથે ૧૦૦% સુરક્ષા રિપોર્ટ જોઈ શકશે અને સભ્યોને પણ સુરક્ષાની ખાતરી મળશે.'.tr,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('સમજાયું (Close)'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep({
    required String step,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPrintableQrDialog(PatrolCheckpoint cp) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _societyName ?? 'માય બિલ્ડિંગ ગાર્ડ'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'સુરક્ષા પેટ્રોલિંગ સ્ટીકર'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Printable Sticker Frame
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'સુરક્ષા ચેકપોઇન્ટ: ${cp.code}'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: cp.qrPayload,
                        version: QrVersions.auto,
                        size: 190.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cp.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        cp.location,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'સુરક્ષા ગાર્ડ માટે: પેટ્રોલિંગ દરમિયાન અહીં સ્કેન કરો'.tr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Share / Print Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'સુરક્ષા ચેકપોઇન્ટ QR: [${cp.code}] ${cp.name} - ${cp.location}\nQR કોડ ડેટા: ${cp.qrPayload}'.tr,
                          subject: 'સુરક્ષા ચેકપોઇન્ટ QR - ${cp.name}'.tr,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('QR વિગત શેર કરો'.tr),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCheckpoint(PatrolCheckpoint cp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ચેકપોઇન્ટ કાઢી નાખવો છે?'.tr),
        content: Text('શું તમે ખરેખર "${cp.name}" ચેકપોઇન્ટ કાઢી નાખવા માંગો છો?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('રદ કરો'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteCheckpoint(_effectiveSocietyId!, cp.id);
            },
            child: Text('કાઢી નાખો'.tr),
          ),
        ],
      ),
    );
  }
}
