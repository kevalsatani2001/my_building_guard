import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/society_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/localization_service.dart';

class AdminVisitorReportScreen extends StatefulWidget {
  const AdminVisitorReportScreen({super.key});

  @override
  State<AdminVisitorReportScreen> createState() => _AdminVisitorReportScreenState();
}

class _AdminVisitorReportScreenState extends State<AdminVisitorReportScreen> {
  // Status filter: 'all', 'approved', 'pending', 'rejected', 'checked_out'
  String _selectedFilter = 'all';

  // Purpose filter: 'all', 'food', 'parcel', 'cab', 'service', 'guest'
  String _selectedPurpose = 'all';

  // Date filter: 'all', 'today', 'yesterday', 'this_week', 'this_month', 'custom'
  String _selectedDateFilter = 'all';
  DateTimeRange? _customDateRange;

  // Wing / Block filter
  String _selectedBlock = 'all';

  // Search
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilter = 'all';
      _selectedPurpose = 'all';
      _selectedDateFilter = 'all';
      _customDateRange = null;
      _selectedBlock = 'all';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters =>
      _selectedFilter != 'all' ||
      _selectedPurpose != 'all' ||
      _selectedDateFilter != 'all' ||
      _selectedBlock != 'all' ||
      _searchQuery.isNotEmpty;

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = 'custom';
        _customDateRange = picked;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("કૉલ કરી શકાયો નથી: $cleanPhone".tr),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "વિઝિટર રિપોર્ટ & રજીસ્ટર".tr,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "મુલાકાતી એન્ટ્રી, એક્ઝિટ અને મંજૂરી વિગત".tr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: LanguageSwitchButton()),
          ),
          if (_hasActiveFilters)
            IconButton(
              tooltip: "ફિલ્ટર્સ રીસેટ કરો".tr,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(Icons.filter_alt_off_rounded, size: 18, color: Color(0xFFDC2626)),
              ),
              onPressed: _clearAllFilters,
            ),
          IconButton(
            tooltip: "તારીખ ફિલ્ટર".tr,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _selectedDateFilter != 'all' ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedDateFilter != 'all' ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: _selectedDateFilter != 'all' ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
            onPressed: _pickCustomDateRange,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppFirestore.instance
            .collection('visitors')
            .where('societyId', isEqualTo: SocietyService.instance.societyId)
            .orderBy('entryTime', descending: true)
            .limit(300)
            .snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

          final total = allDocs.length;
          final approved = allDocs.where((d) => (d.data() as Map)['status'] == 'approved').length;
          final pending = allDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;
          final rejected = allDocs.where((d) => (d.data() as Map)['status'] == 'rejected').length;
          final checkedOut = allDocs.where((d) => (d.data() as Map)['status'] == 'checked_out').length;

          // Extract unique block names for wing filter
          final blockSet = <String>{};
          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final b = (data['blockName'] ?? '').toString().trim();
            if (b.isNotEmpty && b != 'All') {
              final cleanB = b.contains('_') ? b.split('_').last : b;
              blockSet.add(cleanB);
            }
          }
          final sortedBlocks = blockSet.toList()..sort();

          // Prepare Date Bounds
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          final yesterdayStart = todayStart.subtract(const Duration(days: 1));
          final yesterdayEnd = DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 23, 59, 59, 999);
          final thisWeekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
          final thisMonthStart = DateTime(now.year, now.month, 1);

          // Apply Filter & Search
          var filtered = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString();

            // Status filter
            if (_selectedFilter != 'all' && status != _selectedFilter) return false;

            // Date filter
            if (_selectedDateFilter != 'all') {
              DateTime? entryTime;
              if (data['entryTime'] is Timestamp) {
                entryTime = (data['entryTime'] as Timestamp).toDate();
              }
              if (entryTime == null) return false;

              if (_selectedDateFilter == 'today') {
                if (entryTime.isBefore(todayStart) || entryTime.isAfter(todayEnd)) return false;
              } else if (_selectedDateFilter == 'yesterday') {
                if (entryTime.isBefore(yesterdayStart) || entryTime.isAfter(yesterdayEnd)) return false;
              } else if (_selectedDateFilter == 'this_week') {
                if (entryTime.isBefore(thisWeekStart)) return false;
              } else if (_selectedDateFilter == 'this_month') {
                if (entryTime.isBefore(thisMonthStart)) return false;
              } else if (_selectedDateFilter == 'custom' && _customDateRange != null) {
                final customStart = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
                final customEnd = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59, 999);
                if (entryTime.isBefore(customStart) || entryTime.isAfter(customEnd)) return false;
              }
            }

            // Wing / Block filter
            if (_selectedBlock != 'all') {
              final rawBlock = (data['blockName'] ?? '').toString();
              final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
              if (cleanBlock != _selectedBlock && rawBlock != _selectedBlock) return false;
            }

            // Purpose / Category filter
            if (_selectedPurpose != 'all') {
              final p = (data['purpose'] ?? '').toString().toLowerCase();
              final n = (data['name'] ?? '').toString().toLowerCase();
              final vt = (data['visitorType'] ?? '').toString().toLowerCase();

              if (_selectedPurpose == 'food') {
                if (!p.contains('zomato') &&
                    !p.contains('swiggy') &&
                    !p.contains('blinkit') &&
                    !p.contains('zepto') &&
                    !p.contains('food') &&
                    !p.contains('ગ્રોસરી'.tr) &&
                    !p.contains('ખાવાનું'.tr) &&
                    !n.contains('zomato') &&
                    !n.contains('swiggy') &&
                    vt != 'delivery') {
                  return false;
                }
              } else if (_selectedPurpose == 'parcel') {
                if (!p.contains('amazon') &&
                    !p.contains('flipkart') &&
                    !p.contains('parcel') &&
                    !p.contains('courier') &&
                    !p.contains('કુરિયર'.tr) &&
                    !p.contains('પાર્સલ'.tr) &&
                    !p.contains('delivery') &&
                    !n.contains('amazon') &&
                    !n.contains('flipkart')) {
                  return false;
                }
              } else if (_selectedPurpose == 'cab') {
                if (!p.contains('cab') &&
                    !p.contains('taxi') &&
                    !p.contains('uber') &&
                    !p.contains('ola') &&
                    !p.contains('rapido') &&
                    !p.contains('કેબ'.tr) &&
                    !n.contains('uber') &&
                    !n.contains('ola') &&
                    vt != 'cab') {
                  return false;
                }
              } else if (_selectedPurpose == 'service') {
                if (!p.contains('service') &&
                    !p.contains('repair') &&
                    !p.contains('સર્વિસ'.tr) &&
                    !p.contains('રિપેર'.tr) &&
                    !p.contains('ટેકનિશિયન'.tr) &&
                    !p.contains('પ્લમ્બર'.tr) &&
                    !p.contains('ઇલેક્ટ્રિશિયન'.tr) &&
                    vt != 'service') {
                  return false;
                }
              } else if (_selectedPurpose == 'guest') {
                if (!p.contains('guest') &&
                    !p.contains('મહેમાન'.tr) &&
                    !p.contains('મુલાકાત'.tr) &&
                    !p.contains('મિત્ર'.tr) &&
                    vt != 'guest') {
                  return false;
                }
              }
            }

            // Search query filter
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final name = (data['name'] ?? '').toString().toLowerCase();
              final phone = (data['phone'] ?? '').toString().toLowerCase();
              final vehicle = (data['vehicleNo'] ?? data['vehicleNumber'] ?? data['vehicle'] ?? '').toString().toLowerCase();
              final unit = (data['unitNumber'] ?? '').toString().toLowerCase();
              final block = (data['blockName'] ?? '').toString().toLowerCase();
              final purpose = (data['purpose'] ?? '').toString().toLowerCase();
              return name.contains(q) ||
                  phone.contains(q) ||
                  vehicle.contains(q) ||
                  unit.contains(q) ||
                  block.contains(q) ||
                  purpose.contains(q);
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Top KPI Summary Container with Interactive Cards
              _buildTopKpiSection(
                total: total,
                approved: approved,
                pending: pending,
                rejected: rejected,
                checkedOut: checkedOut,
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchQuery.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                      width: _searchQuery.isNotEmpty ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: "નામ, ફોન, વાહન અથવા ફ્લેટ નંબર શોધો...".tr,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search_rounded, size: 21, color: Color(0xFF6366F1)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),

              // Date Range Filter Horizon
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _dateFilterChip('all', '📅 બધા સમય'.tr),
                    const SizedBox(width: 6),
                    _dateFilterChip('today', '⚡ આજે'.tr),
                    const SizedBox(width: 6),
                    _dateFilterChip('yesterday', '⏮️ ગઈકાલે'.tr),
                    const SizedBox(width: 6),
                    _dateFilterChip('this_week', '📆 આ સપ્તાહ'.tr),
                    const SizedBox(width: 6),
                    _dateFilterChip('this_month', '🗓️ આ મહિનો'.tr),
                    const SizedBox(width: 6),
                    _customDateChip(),
                  ],
                ),
              ),

              // Status Filter Pills (Row 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                child: Row(
                  children: [
                    _filterChip('all', 'બધા ($total)'.tr, Icons.people_outline_rounded, const Color(0xFF0F172A)),
                    const SizedBox(width: 6),
                    _filterChip('approved', '🟢 મંજૂર ($approved)'.tr, Icons.check_circle_rounded, const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    _filterChip('pending', '⏳ પેન્ડિંગ ($pending)'.tr, Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _filterChip('rejected', '🔴 નકારેલ ($rejected)'.tr, Icons.cancel_rounded, const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    _filterChip('checked_out', '🚪 બહાર ગયા ($checkedOut)'.tr, Icons.logout_rounded, const Color(0xFF0D9488)),
                  ],
                ),
              ),

              // Purpose / Category Filter Chips (Row 2)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                child: Row(
                  children: [
                    _purposeChip('all', '✨ બધા હેતુ'.tr),
                    const SizedBox(width: 6),
                    _purposeChip('food', '🍔 ફૂડ & ગ્રોસરી'.tr),
                    const SizedBox(width: 6),
                    _purposeChip('parcel', '📦 પાર્સલ & કુરિયર'.tr),
                    const SizedBox(width: 6),
                    _purposeChip('cab', '🚕 કેબ & રાઈડ'.tr),
                    const SizedBox(width: 6),
                    _purposeChip('service', '🔧 સર્વિસ & રિપેર'.tr),
                    const SizedBox(width: 6),
                    _purposeChip('guest', '👥 મહેમાન (Guest)'.tr),
                  ],
                ),
              ),

              // Wing Filter Pills (Row 3 - shown if multiple wings exist)
              if (sortedBlocks.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: Row(
                    children: [
                      _wingChip('all', 'બધા બ્લોક્સ'.tr),
                      ...sortedBlocks.map((b) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _wingChip(b, 'વિંગ $b'.tr),
                          )),
                    ],
                  ),
                ),

              // Active Filters Summary Bar
              if (_hasActiveFilters) _buildActiveFilterSummary(filtered.length),

              const SizedBox(height: 4),

              // Visitors List
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && allDocs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final doc = filtered[i];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildVisitorCard(data, doc.id);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Top KPI Section with Interactive Cards
  Widget _buildTopKpiSection({
    required int total,
    required int approved,
    required int pending,
    required int rejected,
    required int checkedOut,
  }) {
    final isAllSelected = _selectedFilter == 'all';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.query_stats_rounded, size: 18, color: Color(0xFF0F172A)),
                  SizedBox(width: 6),
                  Text(
                    "મુલાકાતી આંકડા".tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = 'all');
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAllSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAllSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 13,
                        color: isAllSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "કુલ મુલાકાતીઓ: $total".tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: isAllSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _interactiveKpiCard(
                label: "મંજૂર".tr,
                count: approved,
                key: 'approved',
                color: const Color(0xFF10B981),
                activeBorder: const Color(0xFF059669),
                bg: const Color(0xFFECFDF5),
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 8),
              _interactiveKpiCard(
                label: "પેન્ડિંગ".tr,
                count: pending,
                key: 'pending',
                color: const Color(0xFFF59E0B),
                activeBorder: const Color(0xFFD97706),
                bg: const Color(0xFFFFFBEB),
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 8),
              _interactiveKpiCard(
                label: "નકારેલ".tr,
                count: rejected,
                key: 'rejected',
                color: const Color(0xFFEF4444),
                activeBorder: const Color(0xFFDC2626),
                bg: const Color(0xFFFEF2F2),
                icon: Icons.cancel_rounded,
              ),
              const SizedBox(width: 8),
              _interactiveKpiCard(
                label: "બહાર ગયા".tr,
                count: checkedOut,
                key: 'checked_out',
                color: const Color(0xFF0D9488),
                activeBorder: const Color(0xFF0F766E),
                bg: const Color(0xFFF0FDFA),
                icon: Icons.logout_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _interactiveKpiCard({
    required String label,
    required int count,
    required String key,
    required Color color,
    required Color activeBorder,
    required Color bg,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == key;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = isSelected ? 'all' : key;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? bg : bg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeBorder : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    "$count",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 10.5,
                      color: color,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.check_rounded, size: 11, color: activeBorder),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateFilterChip(String key, String label) {
    final isSelected = _selectedDateFilter == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDateFilter = key;
          if (key != 'custom') _customDateRange = null;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 11,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _customDateChip() {
    final isSelected = _selectedDateFilter == 'custom' && _customDateRange != null;
    final label = isSelected
        ? "${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}"
        : "🔍 તારીખ પસંદ કરો".tr;

    return InkWell(
      onTap: _pickCustomDateRange,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 11,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'all';
                    _customDateRange = null;
                  });
                },
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label, IconData icon, Color color) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = key);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 11.5,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purposeChip(String key, String label) {
    final isSelected = _selectedPurpose == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPurpose = key);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4338CA).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 12, color: Color(0xFF4338CA)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wingChip(String key, String label) {
    final isSelected = _selectedBlock == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedBlock = key);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 10.5,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterSummary(int resultCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$resultCount",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "ફિલ્ટર સક્રિય છે".tr,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
          InkWell(
            onTap: _clearAllFilters,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFEF4444)),
                SizedBox(width: 4),
                Text(
                  "બધા સાફ કરો".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                _hasActiveFilters ? Icons.filter_alt_off_rounded : Icons.person_search_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? "'$_searchQuery' માટે કોઈ રેકોર્ડ મળ્યો નથી".tr
                  : _hasActiveFilters
                      ? "આ ફિલ્ટર્સ મુજબ કોઈ વિઝિટર મળ્યા નથી".tr
                      : "આ કેટેગરીમાં કોઈ વિઝિટર નથી".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "ફિલ્ટર બદલો અથવા બધા ફિલ્ટર્સ સાફ કરો".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: Text(
                  "બધા ફિલ્ટર્સ સાફ કરો".tr,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Premium Visitor Card matching Image 3 design
  Widget _buildVisitorCard(Map<String, dynamic> d, String docId) {
    final name = (d['name'] ?? 'અનામી'.tr).toString();
    final phone = (d['phone'] ?? '').toString();
    final vehicle = (d['vehicleNo'] ?? d['vehicleNumber'] ?? d['vehicle'] ?? '').toString();
    final purpose = (d['purpose'] ?? 'મુલાકાત'.tr).toString();
    final photoUrl = (d['photoUrl'] ?? '').toString();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString();
    final flatDisplay = cleanBlock.isNotEmpty && unit.isNotEmpty
        ? '$cleanBlock - $unit'
        : (unit.isNotEmpty ? unit : 'સોસાયટી'.tr);
    final status = (d['status'] ?? 'pending').toString();

    DateTime? entryTime;
    if (d['entryTime'] is Timestamp) {
      entryTime = (d['entryTime'] as Timestamp).toDate();
    }

    DateTime? exitTime;
    if (d['exitTime'] is Timestamp) {
      exitTime = (d['exitTime'] as Timestamp).toDate();
    }

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF047857);
        statusBg = const Color(0xFFECFDF5);
        statusLabel = "અંદર છે".tr;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFB91C1C);
        statusBg = const Color(0xFFFEF2F2);
        statusLabel = "નકારેલ".tr;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'checked_out':
        statusColor = const Color(0xFF0F766E);
        statusBg = const Color(0xFFF0FDFA);
        statusLabel = "બહાર ગયા".tr;
        statusIcon = Icons.output_rounded;
        break;
      default:
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFFFFBEB);
        statusLabel = "પેન્ડિંગ".tr;
        statusIcon = Icons.schedule_rounded;
        break;
    }

    // Determine visitor type icon/colors
    final (typeIcon, typeColor, typeBg) = _classifyVisitorType(purpose);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showAdminVisitorDetailSheet(context, d, docId),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Squircle with corner type badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => _fallbackAvatar(name, statusColor),
                              )
                            : _fallbackAvatar(name, statusColor),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: typeBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(typeIcon, size: 10.5, color: typeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name, Badges & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          // Purpose tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: typeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 10.5, color: typeColor),
                                const SizedBox(width: 3.5),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 90),
                                  child: Text(
                                    purpose,
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

                          // Destination flat
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.apartment_rounded, size: 10.5, color: Color(0xFF475569)),
                                const SizedBox(width: 3.5),
                                Text(
                                  flatDisplay,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
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
                            entryTime != null ? DateFormat('hh:mm a').format(entryTime) : 'સમય નોંધાયેલ નથી'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (status == 'checked_out' && exitTime != null) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(width: 6),
                            Icon(Icons.logout_rounded, size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('hh:mm a').format(exitTime),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (vehicle.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(width: 6),
                            Icon(Icons.directions_car_rounded, size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                vehicle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Actions: Call button & Status Pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phone.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _makePhoneCall(phone),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
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
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  (IconData, Color, Color) _classifyVisitorType(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('delivery') ||
        p.contains('zomato') ||
        p.contains('swiggy') ||
        p.contains('blinkit') ||
        p.contains('zepto') ||
        p.contains('food') ||
        p.contains('ખાવાનું'.tr)) {
      return (Icons.delivery_dining_rounded, const Color(0xFFEA580C), const Color(0xFFFFF7ED));
    }
    if (p.contains('parcel') ||
        p.contains('courier') ||
        p.contains('amazon') ||
        p.contains('flipkart') ||
        p.contains('પાર્સલ'.tr) ||
        p.contains('કુરિયર'.tr)) {
      return (Icons.inventory_2_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB));
    }
    if (p.contains('cab') ||
        p.contains('taxi') ||
        p.contains('uber') ||
        p.contains('ola') ||
        p.contains('rapido') ||
        p.contains('કેબ'.tr)) {
      return (Icons.local_taxi_rounded, const Color(0xFF0284C7), const Color(0xFFF0F9FF));
    }
    if (p.contains('service') ||
        p.contains('repair') ||
        p.contains('સર્વિસ'.tr) ||
        p.contains('રિપેર'.tr) ||
        p.contains('ટેકનિશિયન'.tr) ||
        p.contains('ઇલેક્ટ્રિશિયન'.tr)) {
      return (Icons.build_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
    }
    return (Icons.people_alt_rounded, const Color(0xFF059669), const Color(0xFFECFDF5));
  }

  // Detailed Modal Sheet for Visitor
  void _showAdminVisitorDetailSheet(BuildContext context, Map<String, dynamic> d, String docId) {
    final name = (d['name'] ?? 'મુલાકાતી'.tr).toString();
    final phone = (d['phone'] ?? '').toString();
    final purpose = (d['purpose'] ?? 'મુલાકાત'.tr).toString();
    final photoUrl = (d['photoUrl'] ?? '').toString();
    final vehicle = (d['vehicleNo'] ?? d['vehicleNumber'] ?? d['vehicle'] ?? '').toString();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString();
    final flatDisplay = cleanBlock.isNotEmpty && unit.isNotEmpty
        ? '$cleanBlock - $unit'
        : (unit.isNotEmpty ? unit : 'સોસાયટી'.tr);
    final status = (d['status'] ?? 'pending').toString();
    final entryTs = d['entryTime'] as Timestamp?;
    final exitTs = d['exitTime'] as Timestamp?;

    final (statusLabel, statusColor, statusBg) = switch (status) {
      'approved' => ('અંદર છે (Approved)'.tr, const Color(0xFF047857), const Color(0xFFECFDF5)),
      'rejected' => ('નકારેલ (Rejected)'.tr, const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
      'checked_out' => ('બહાર ગયા (Checked Out)'.tr, const Color(0xFF0F766E), const Color(0xFFF0FDFA)),
      _ => ('પેન્ડિંગ (Pending)'.tr, const Color(0xFFB45309), const Color(0xFFFFFBEB)),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
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
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _fallbackAvatar(name, statusColor),
                        )
                      : _fallbackAvatar(name, statusColor),
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
                        "ગંતવ્ય: $flatDisplay".tr,
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
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                  _detailRow('મુલાકાત હેતુ:'.tr, purpose),
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
                            fontWeight: FontWeight.w600,
                          ),
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
                              const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF059669)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (vehicle.isNotEmpty) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _detailRow('વાહન નંબર:'.tr, vehicle),
                  ],
                  if (entryTs != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _detailRow(
                      'પ્રવેશ સમય:'.tr,
                      DateFormat('dd MMM yyyy, hh:mm a').format(entryTs.toDate()),
                    ),
                  ],
                  if (exitTs != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _detailRow(
                      'બહાર નીકળ્યા:'.tr,
                      DateFormat('dd MMM yyyy, hh:mm a').format(exitTs.toDate()),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                if (phone.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(phone),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: Text('કૉલ કરો'.tr, style: TextStyle(fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (phone.isNotEmpty && status == 'approved') const SizedBox(width: 10),
                if (status == 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await AppFirestore.instance.collection('visitors').doc(docId).update({
                          'status': 'checked_out',
                          'exitTime': FieldValue.serverTimestamp(),
                        });
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("મુલાકાતી બહાર ગયા તરીકે નોંધાયા.".tr),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.output_rounded, size: 16),
                      label: Text('એક્ઝિટ માર્ક કરો'.tr, style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _detailRow(String label, String value) {
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
}
