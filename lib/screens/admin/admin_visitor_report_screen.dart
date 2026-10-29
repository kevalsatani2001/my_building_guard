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

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedFilter != 'all') count++;
    if (_selectedDateFilter != 'all') count++;
    if (_selectedPurpose != 'all') count++;
    if (_selectedBlock != 'all') count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

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
            onPressed: _showDateFilterSheet,
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
              // Executive KPI Metric Deck
              _buildTopKpiSection(
                total: total,
                approved: approved,
                pending: pending,
                rejected: rejected,
                checkedOut: checkedOut,
              ),

              // Professional Unified Control Console (Search + Segmented Time Slider + Dropdowns)
              _buildUnifiedControlConsole(sortedBlocks, filtered.length),

              const SizedBox(height: 6),

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

  // Executive KPI Section with Live Gate Activity Indicator
  Widget _buildTopKpiSection({
    required int total,
    required int approved,
    required int pending,
    required int rejected,
    required int checkedOut,
  }) {
    final isAllSelected = _selectedFilter == 'all';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 14,
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
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.45),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "ગેટ એક્ટિવિટી આંકડા".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
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
                        Icons.people_alt_rounded,
                        size: 13,
                        color: isAllSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${"કુલ:".tr} $total",
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

  // Professional Unified Control Console (Search + Segmented Slider + Dropdowns)
  Widget _buildUnifiedControlConsole(List<String> sortedBlocks, int filteredCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar with Integrated Master Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _searchQuery.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                      width: _searchQuery.isNotEmpty ? 1.4 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: "નામ, ફોન, વાહન અથવા ફ્લેટ નંબર શોધો...".tr,
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterLauncherButton(sortedBlocks),
            ],
          ),
          const SizedBox(height: 10),

          // 2. iOS/Linear Style Segmented Timeframe Slider
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeSegment(
                    key: 'today',
                    label: 'આજે'.tr,
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  _buildTimeSegment(
                    key: 'yesterday',
                    label: 'ગઈકાલે'.tr,
                  ),
                  _buildTimeSegment(
                    key: 'this_week',
                    label: 'આ સપ્તાહ'.tr,
                  ),
                  _buildTimeSegment(
                    key: 'this_month',
                    label: 'આ મહિનો'.tr,
                  ),
                  _buildTimeSegment(
                    key: 'custom',
                    label: _selectedDateFilter == 'custom' && _customDateRange != null
                        ? "${DateFormat('dd/MM').format(_customDateRange!.start)}-${DateFormat('dd/MM').format(_customDateRange!.end)}"
                        : 'કસ્ટમ 📅'.tr,
                  ),
                  _buildTimeSegment(
                    key: 'all',
                    label: 'બધા સમય'.tr,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Contextual Filter Row (Purpose + Wing + Active Status)
          Row(
            children: [
              _buildPurposeFilterDropdownPill(),
              if (sortedBlocks.length > 1) ...[
                const SizedBox(width: 8),
                _buildWingFilterDropdownPill(sortedBlocks),
              ],
              const Spacer(),
              if (_hasActiveFilters)
                InkWell(
                  onTap: _clearAllFilters,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, size: 12, color: Color(0xFFDC2626)),
                        const SizedBox(width: 3),
                        Text(
                          "સાફ કરો".tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  "${"પરિણામ:".tr} $filteredCount",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Segment Tab Helper
  Widget _buildTimeSegment({
    required String key,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    final isSelected = _selectedDateFilter == key;
    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        if (key == 'custom') {
          await _pickCustomDateRange();
        } else {
          setState(() {
            _selectedDateFilter = key;
            _customDateRange = null;
          });
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? const Color(0xFF2563EB) : (iconColor ?? const Color(0xFF64748B)),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Purpose Dropdown Pill inside Console
  Widget _buildPurposeFilterDropdownPill() {
    String purposeLabel;
    if (_selectedPurpose == 'all') {
      purposeLabel = "હેતુ: બધા".tr;
    } else if (_selectedPurpose == 'food') {
      purposeLabel = "🍔 ફૂડ".tr;
    } else if (_selectedPurpose == 'parcel') {
      purposeLabel = "📦 પાર્સલ".tr;
    } else if (_selectedPurpose == 'cab') {
      purposeLabel = "🚕 કેબ".tr;
    } else if (_selectedPurpose == 'service') {
      purposeLabel = "🔧 સર્વિસ".tr;
    } else if (_selectedPurpose == 'guest') {
      purposeLabel = "👥 મહેમાન".tr;
    } else {
      purposeLabel = "હેતુ".tr;
    }

    final isPurposeActive = _selectedPurpose != 'all';

    return InkWell(
      onTap: _showPurposeFilterSheet,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPurposeActive ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPurposeActive ? const Color(0xFF9333EA) : const Color(0xFFE2E8F0),
            width: isPurposeActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_rounded,
              size: 13,
              color: isPurposeActive ? const Color(0xFF9333EA) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              purposeLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isPurposeActive ? FontWeight.w900 : FontWeight.w700,
                color: isPurposeActive ? const Color(0xFF9333EA) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isPurposeActive ? const Color(0xFF9333EA) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // Wing Dropdown Pill inside Console
  Widget _buildWingFilterDropdownPill(List<String> sortedBlocks) {
    String wingLabel;
    if (_selectedBlock == 'all') {
      wingLabel = "વિંગ: બધા".tr;
    } else {
      wingLabel = "વિંગ $_selectedBlock".tr;
    }

    final isWingActive = _selectedBlock != 'all';

    return InkWell(
      onTap: () => _showWingFilterSheet(sortedBlocks),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isWingActive ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isWingActive ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
            width: isWingActive ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apartment_rounded,
              size: 13,
              color: isWingActive ? const Color(0xFF0D9488) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              wingLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isWingActive ? FontWeight.w900 : FontWeight.w700,
                color: isWingActive ? const Color(0xFF0D9488) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isWingActive ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Launcher Button with Badge Counter
  Widget _buildFilterLauncherButton(List<String> sortedBlocks) {
    final count = _activeFiltersCount;
    final hasFilters = count > 0;

    return InkWell(
      onTap: () => _showAllFiltersSheet(sortedBlocks),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasFilters ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFilters ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 19,
              color: hasFilters ? Colors.white : const Color(0xFF475569),
            ),
            if (hasFilters)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "$count",
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Bottom Sheet Option Tile Helper
  Widget _buildSheetOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? iconColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? iconColor : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? iconColor : iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: isSelected ? Colors.white : iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: iconColor, size: 20)
                else
                  Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modal Chip for Master Filter Sheet
  Widget _buildModalChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color activeColor = const Color(0xFF0F172A),
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? activeColor : const Color(0xFF64748B)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeColor : const Color(0xFF334155),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_rounded, size: 13, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }

  // Date Filter Bottom Sheet
  void _showDateFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "તારીખ ફિલ્ટર પસંદ કરો".tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "મુલાકાતી એન્ટ્રી તારીખ મુજબ ફિલ્ટર કરો".tr,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDateFilter != 'all')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateFilter = 'all';
                          _customDateRange = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "રીસેટ".tr,
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetOptionTile(
                icon: Icons.all_inclusive_rounded,
                iconColor: const Color(0xFF475569),
                title: "બધા સમય".tr,
                subtitle: "શરૂઆતથી અત્યાર સુધીની તમામ એન્ટ્રીઓ".tr,
                isSelected: _selectedDateFilter == 'all',
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'all';
                    _customDateRange = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: "આજે (Today)".tr,
                subtitle: "આજના દિવસમાં આવેલ તમામ વિઝિટર્સ".tr,
                isSelected: _selectedDateFilter == 'today',
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'today';
                    _customDateRange = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.history_rounded,
                iconColor: const Color(0xFF6366F1),
                title: "ગઈકાલે (Yesterday)".tr,
                subtitle: "ગઈકાલના દિવસની એન્ટ્રીઓ".tr,
                isSelected: _selectedDateFilter == 'yesterday',
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'yesterday';
                    _customDateRange = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF0D9488),
                title: "આ સપ્તાહ (This Week)".tr,
                subtitle: "આ સપ્તાહની તમામ મુલાકાતો".tr,
                isSelected: _selectedDateFilter == 'this_week',
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'this_week';
                    _customDateRange = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.calendar_view_month_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: "આ મહિનો (This Month)".tr,
                subtitle: "આ મહિનાની તમામ વિઝિટર એન્ટ્રીઓ".tr,
                isSelected: _selectedDateFilter == 'this_month',
                onTap: () {
                  setState(() {
                    _selectedDateFilter = 'this_month';
                    _customDateRange = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.edit_calendar_rounded,
                iconColor: const Color(0xFFEA580C),
                title: _selectedDateFilter == 'custom' && _customDateRange != null
                    ? "${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}"
                    : "કસ્ટમ તારીખ પસંદ કરો...".tr,
                subtitle: "તમારી પસંદ મુજબની તારીખ રેન્જ સેટ કરો".tr,
                isSelected: _selectedDateFilter == 'custom',
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCustomDateRange();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Purpose Filter Bottom Sheet
  void _showPurposeFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.category_rounded, color: Color(0xFF9333EA), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "મુલાકાતનો હેતુ (Purpose)".tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "ડિલિવરી, કેબ, સર્વિસ કે મહેમાન મુજબ ફિલ્ટર".tr,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPurpose != 'all')
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedPurpose = 'all');
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "રીસેટ".tr,
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetOptionTile(
                icon: Icons.all_inclusive_rounded,
                iconColor: const Color(0xFF475569),
                title: "બધા હેતુ (All Purposes)".tr,
                subtitle: "કોઈપણ પ્રકારના મુલાકાતીઓ".tr,
                isSelected: _selectedPurpose == 'all',
                onTap: () {
                  setState(() => _selectedPurpose = 'all');
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.fastfood_rounded,
                iconColor: const Color(0xFFEA580C),
                title: "ફૂડ & ગ્રોસરી ડિલિવરી".tr,
                subtitle: "Zomato, Swiggy, Blinkit, Zepto, ઇત્યાદિ".tr,
                isSelected: _selectedPurpose == 'food',
                onTap: () {
                  setState(() => _selectedPurpose = 'food');
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFFB45309),
                title: "પાર્સલ & કુરિયર".tr,
                subtitle: "Amazon, Flipkart, Bluedart, વગેરે".tr,
                isSelected: _selectedPurpose == 'parcel',
                onTap: () {
                  setState(() => _selectedPurpose = 'parcel');
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.local_taxi_rounded,
                iconColor: const Color(0xFFEAB308),
                title: "કેબ & રાઈડ".tr,
                subtitle: "Uber, Ola, Rapido, Taxi".tr,
                isSelected: _selectedPurpose == 'cab',
                onTap: () {
                  setState(() => _selectedPurpose = 'cab');
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.build_rounded,
                iconColor: const Color(0xFF0284C7),
                title: "સર્વિસ & રિપેર".tr,
                subtitle: "ઇલેક્ટ્રિશિયન, પ્લમ્બર, કારપેન્ટર, વગેરે".tr,
                isSelected: _selectedPurpose == 'service',
                onTap: () {
                  setState(() => _selectedPurpose = 'service');
                  Navigator.pop(ctx);
                },
              ),
              _buildSheetOptionTile(
                icon: Icons.group_rounded,
                iconColor: const Color(0xFF059669),
                title: "મહેમાન (Guest / Personal)".tr,
                subtitle: "રહેવાસીઓના અંગત સગાસંબંધી અને મિત્રો".tr,
                isSelected: _selectedPurpose == 'guest',
                onTap: () {
                  setState(() => _selectedPurpose = 'guest');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Wing Filter Bottom Sheet
  void _showWingFilterSheet(List<String> sortedBlocks) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF0D9488), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "વિંગ / બ્લોક ફિલ્ટર".tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "ચોક્કસ બિલ્ડિંગ અથવા વિંગના મુલાકાતીઓ".tr,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedBlock != 'all')
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedBlock = 'all');
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "રીસેટ".tr,
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetOptionTile(
                icon: Icons.domain_rounded,
                iconColor: const Color(0xFF475569),
                title: "બધા બ્લોક્સ (All Wings)".tr,
                subtitle: "સમગ્ર સોસાયટીના વિઝિટર્સ".tr,
                isSelected: _selectedBlock == 'all',
                onTap: () {
                  setState(() => _selectedBlock = 'all');
                  Navigator.pop(ctx);
                },
              ),
              ...sortedBlocks.map((b) => _buildSheetOptionTile(
                    icon: Icons.apartment_rounded,
                    iconColor: const Color(0xFF0D9488),
                    title: "વિંગ $b".tr,
                    subtitle: "$b બ્લોકમાં આવેલ મુલાકાતીઓ".tr,
                    isSelected: _selectedBlock == b,
                    onTap: () {
                      setState(() => _selectedBlock = b);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // Master Filter Sheet (All Controls in One View)
  void _showAllFiltersSheet(List<String> sortedBlocks) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "મુલાકાતી ફિલ્ટર્સ".tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              _clearAllFilters();
                              setSheetState(() {});
                            },
                            child: Text(
                              "બધા સાફ કરો".tr,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),

                  // Scrollable Filter Sections
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Status Section
                          Text(
                            "સ્ટેટસ (Status)".tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChip(
                                label: "બધા".tr,
                                isSelected: _selectedFilter == 'all',
                                onTap: () {
                                  setState(() => _selectedFilter = 'all');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "મંજૂર".tr,
                                isSelected: _selectedFilter == 'approved',
                                icon: Icons.check_circle_rounded,
                                activeColor: const Color(0xFF10B981),
                                onTap: () {
                                  setState(() => _selectedFilter = 'approved');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "પેન્ડિંગ".tr,
                                isSelected: _selectedFilter == 'pending',
                                icon: Icons.hourglass_top_rounded,
                                activeColor: const Color(0xFFF59E0B),
                                onTap: () {
                                  setState(() => _selectedFilter = 'pending');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "નકારેલ".tr,
                                isSelected: _selectedFilter == 'rejected',
                                icon: Icons.cancel_rounded,
                                activeColor: const Color(0xFFEF4444),
                                onTap: () {
                                  setState(() => _selectedFilter = 'rejected');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "બહાર ગયા".tr,
                                isSelected: _selectedFilter == 'checked_out',
                                icon: Icons.logout_rounded,
                                activeColor: const Color(0xFF0D9488),
                                onTap: () {
                                  setState(() => _selectedFilter = 'checked_out');
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. Date Section
                          Text(
                            "તારીખ રેન્જ (Date Range)".tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChip(
                                label: "બધા સમય".tr,
                                isSelected: _selectedDateFilter == 'all',
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = 'all';
                                    _customDateRange = null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "આજે".tr,
                                isSelected: _selectedDateFilter == 'today',
                                icon: Icons.bolt_rounded,
                                activeColor: const Color(0xFF2563EB),
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = 'today';
                                    _customDateRange = null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "ગઈકાલે".tr,
                                isSelected: _selectedDateFilter == 'yesterday',
                                icon: Icons.history_rounded,
                                activeColor: const Color(0xFF2563EB),
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = 'yesterday';
                                    _customDateRange = null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "આ સપ્તાહ".tr,
                                isSelected: _selectedDateFilter == 'this_week',
                                icon: Icons.date_range_rounded,
                                activeColor: const Color(0xFF2563EB),
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = 'this_week';
                                    _customDateRange = null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "આ મહિનો".tr,
                                isSelected: _selectedDateFilter == 'this_month',
                                icon: Icons.calendar_view_month_rounded,
                                activeColor: const Color(0xFF2563EB),
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = 'this_month';
                                    _customDateRange = null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: _selectedDateFilter == 'custom' && _customDateRange != null
                                    ? "${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}"
                                    : "કસ્ટમ તારીખ...".tr,
                                isSelected: _selectedDateFilter == 'custom',
                                icon: Icons.edit_calendar_rounded,
                                activeColor: const Color(0xFFEA580C),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  await _pickCustomDateRange();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. Purpose Section
                          Text(
                            "મુલાકાતનો હેતુ (Purpose)".tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalChip(
                                label: "બધા હેતુ".tr,
                                isSelected: _selectedPurpose == 'all',
                                onTap: () {
                                  setState(() => _selectedPurpose = 'all');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "🍔 ફૂડ & ગ્રોસરી".tr,
                                isSelected: _selectedPurpose == 'food',
                                activeColor: const Color(0xFFEA580C),
                                onTap: () {
                                  setState(() => _selectedPurpose = 'food');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "📦 પાર્સલ & કુરિયર".tr,
                                isSelected: _selectedPurpose == 'parcel',
                                activeColor: const Color(0xFFB45309),
                                onTap: () {
                                  setState(() => _selectedPurpose = 'parcel');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "🚕 કેબ & રાઈડ".tr,
                                isSelected: _selectedPurpose == 'cab',
                                activeColor: const Color(0xFFCA8A04),
                                onTap: () {
                                  setState(() => _selectedPurpose = 'cab');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "🔧 સર્વિસ & રિપેર".tr,
                                isSelected: _selectedPurpose == 'service',
                                activeColor: const Color(0xFF0284C7),
                                onTap: () {
                                  setState(() => _selectedPurpose = 'service');
                                  setSheetState(() {});
                                },
                              ),
                              _buildModalChip(
                                label: "👥 મહેમાન (Guest)".tr,
                                isSelected: _selectedPurpose == 'guest',
                                activeColor: const Color(0xFF059669),
                                onTap: () {
                                  setState(() => _selectedPurpose = 'guest');
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ),

                          // 4. Wing Section (if available)
                          if (sortedBlocks.length > 1) ...[
                            const SizedBox(height: 20),
                            Text(
                              "વિંગ / બ્લોક (Wing / Block)".tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildModalChip(
                                  label: "બધા બ્લોક્સ".tr,
                                  isSelected: _selectedBlock == 'all',
                                  onTap: () {
                                    setState(() => _selectedBlock = 'all');
                                    setSheetState(() {});
                                  },
                                ),
                                ...sortedBlocks.map((b) => _buildModalChip(
                                      label: "વિંગ $b".tr,
                                      isSelected: _selectedBlock == b,
                                      activeColor: const Color(0xFF0D9488),
                                      onTap: () {
                                        setState(() => _selectedBlock = b);
                                        setSheetState(() {});
                                      },
                                    )),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Apply Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          "લાગુ કરો (Apply)".tr,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
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

  Widget _buildEmptyState() {
    final isToday = _selectedDateFilter == 'today';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isToday ? Icons.shield_rounded : Icons.search_off_rounded,
                    size: 32,
                    color: isToday ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isToday
                    ? "આજના દિવસમાં હજુ કોઈ મુલાકાતી નથી".tr
                    : _searchQuery.isNotEmpty
                        ? "'$_searchQuery' માટે કોઈ પરિણામ મળ્યું નથી".tr
                        : _hasActiveFilters
                            ? "પસંદ કરેલા ફિલ્ટર્સ મુજબ કોઈ વિઝિટર નથી".tr
                            : "આ કેટેગરીમાં કોઈ વિઝિટર નોંધાયેલ નથી".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isToday
                    ? "સિક્યોરિટી ગાર્ડ ગેટ પરથી નવી એન્ટ્રી કરશે ત્યારે તે અહીં તરત લાઈવ દેખાશે.".tr
                    : "ફિલ્ટર બદલો અથવા બધા સમયની હિસ્ટ્રી જોવા માટે નીચે ટેપ કરો.".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (isToday) ...[
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDateFilter = 'all';
                      _customDateRange = null;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: Text(
                    "બધા સમયનો રિપોર્ટ જુઓ".tr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ] else if (_hasActiveFilters) ...[
                FilledButton.icon(
                  onPressed: _clearAllFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    "બધા ફિલ્ટર્સ સાફ કરો".tr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
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
