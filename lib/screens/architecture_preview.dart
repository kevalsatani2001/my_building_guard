import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/premise_type.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import 'admin_add_user_screen.dart';
import 'admin_member_signature_sheet_screen.dart';

class ArchitecturePreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tempBlocks;
  final String architectureType;

  const ArchitecturePreviewScreen({
    super.key,
    required this.tempBlocks,
    required this.architectureType,
  });

  @override
  State<ArchitecturePreviewScreen> createState() => _ArchitecturePreviewScreenState();
}

class _ArchitecturePreviewScreenState extends State<ArchitecturePreviewScreen> {
  String _filterOccupancy = 'all'; // 'all', 'occupied', 'vacant'
  String _searchQuery = '';
  final TextEditingController _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocab = PremiseVocabulary.fromString(widget.architectureType);
    final themeConfig = _getArchitectureTheme(widget.architectureType);

    // Flatten all real units from admin setup
    final allUnits = <Map<String, dynamic>>[];
    for (final b in widget.tempBlocks) {
      final uList = b['units'] as List?;
      if (uList != null) {
        for (final u in uList) {
          if (u is Map) {
            allUnits.add(Map<String, dynamic>.from(u));
          }
        }
      } else {
        final v1 = (b['v1'] as num?)?.toInt() ?? 0;
        final v2 = (b['v2'] as num?)?.toInt() ?? 0;
        final isMultiLevel = (widget.architectureType == 'Wing' ||
            widget.architectureType == 'Commercial' ||
            widget.architectureType == 'Mixed');
        final count = widget.architectureType == 'Mixed'
            ? ((v1 + 1) * v2)
            : (isMultiLevel ? (v1 * v2) : (v2 >= v1 ? (v2 - v1 + 1) : 0));
        for (int i = 1; i <= count; i++) {
          allUnits.add({
            'unitNumber': i.toString(),
            'floorNo': 0,
            'unitType': b['category'] == 'commercial' ? 'shop' : 'flat',
            'isOccupied': false,
          });
        }
      }
    }

    final totalUnits = allUnits.length;
    final occupiedCount = allUnits.where((u) => u['isOccupied'] == true).length;
    final vacantCount = totalUnits - occupiedCount;
    final occupancyPct = totalUnits > 0 ? ((occupiedCount / totalUnits) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 🌟 1. PROFESSIONAL EXECUTIVE APP BAR (100% REAL DATA)
          SliverAppBar(
            expandedHeight: 185,
            pinned: true,
            elevation: 0,
            backgroundColor: themeConfig.appBarColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: "સહી પત્રક જુઓ (Signature Sheet)".tr,
                icon: const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminMemberSignatureSheetScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeConfig.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Premise Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(themeConfig.icon, size: 13, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Text(
                                themeConfig.premiseBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Professional Title
                        Text(
                          themeConfig.gujaratiTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          themeConfig.gujaratiSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🌟 2. ACCURATE REAL METRICS DASHBOARD
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Total Units
                      Expanded(
                        child: _buildMetricItem(
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF0F766E),
                          value: '$totalUnits',
                          label: 'કુલ ${vocab.unitShortLabel}'.tr,
                        ),
                      ),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      // Occupied
                      Expanded(
                        child: _buildMetricItem(
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          value: '$occupiedCount',
                          label: 'કબજેદાર'.tr,
                        ),
                      ),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      // Vacant
                      Expanded(
                        child: _buildMetricItem(
                          icon: Icons.meeting_room_outlined,
                          color: const Color(0xFFF59E0B),
                          value: '$vacantCount',
                          label: 'ખાલી (ઉપલબ્ધ)'.tr,
                        ),
                      ),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      // Blocks
                      Expanded(
                        child: _buildMetricItem(
                          icon: Icons.layers_rounded,
                          color: const Color(0xFF4F46E5),
                          value: '${widget.tempBlocks.length}',
                          label: vocab.blockShortLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: totalUnits > 0 ? (occupiedCount / totalUnits) : 0,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ઓક્યુપન્સી ગુણોત્તર: $occupancyPct%'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '💡 વિગતો માટે કોઈપણ એકમ પર ટૅપ કરો'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🌟 3. SEARCH & REAL-TIME OCCUPANCY FILTERS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextField(
                      controller: _searchC,
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "એકમ નંબર શોધો (દા.ત. G-01, 102, Shop 4)...".tr,
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchC.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('all', '🌟 તમામ ($totalUnits)'.tr),
                      const SizedBox(width: 8),
                      _buildFilterChip('occupied', '🟢 કબજેદાર ($occupiedCount)'.tr),
                      const SizedBox(width: 8),
                      _buildFilterChip('vacant', '⚪ ખાલી ($vacantCount)'.tr),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🌟 4. REAL BLOCK / FLOOR ELEVATION CARDS
          if (widget.tempBlocks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: PremiumEmptyState(
                message: "કોઈ આર્કિટેક્ચર ડેટા ઉપલબ્ધ નથી.".tr,
                icon: Icons.grid_view_rounded,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final block = widget.tempBlocks[index];
                    return _buildRealBlockCard(context, block, themeConfig, vocab);
                  },
                  childCount: widget.tempBlocks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- METRIC ITEM ---
  Widget _buildMetricItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // --- FILTER CHIP ---
  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterOccupancy == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterOccupancy = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 🏢 REAL BLOCK CARD (ACCURATE REAL DATA ONLY)
  // =========================================================================
  Widget _buildRealBlockCard(
    BuildContext context,
    Map<String, dynamic> b,
    _ArchThemeConfig themeConfig,
    PremiseVocabulary vocab,
  ) {
    final rawUnits = b['units'] as List?;
    final blockName = (b['name'] ?? '').toString();
    final displayName = (b['displayName'] ?? b['name'] ?? 'બ્લોક'.tr).toString();
    final category = (b['category'] ?? '').toString().toLowerCase();
    final isCommercialBlock = category == 'commercial' || widget.architectureType == 'Commercial';
    final isGround = SocietyService.instance.isGroundBlock(blockName);

    // Filter real units
    List<Map<String, dynamic>> processedUnits = [];
    if (rawUnits != null) {
      for (final u in rawUnits) {
        if (u is Map) {
          final uMap = Map<String, dynamic>.from(u);
          final uNum = (uMap['unitNumber'] ?? '').toString().toLowerCase();
          final isOcc = uMap['isOccupied'] == true;

          if (_filterOccupancy == 'occupied' && !isOcc) continue;
          if (_filterOccupancy == 'vacant' && isOcc) continue;
          if (_searchQuery.isNotEmpty && !uNum.contains(_searchQuery)) continue;

          processedUnits.add(uMap);
        }
      }
    } else {
      final v1 = (b['v1'] as num?)?.toInt() ?? 0;
      final v2 = (b['v2'] as num?)?.toInt() ?? 0;
      final isMultiLevel = (widget.architectureType == 'Wing' ||
          widget.architectureType == 'Commercial' ||
          widget.architectureType == 'Mixed');
      final count = widget.architectureType == 'Mixed'
          ? ((v1 + 1) * v2)
          : (isMultiLevel ? (v1 * v2) : (v2 >= v1 ? (v2 - v1 + 1) : 0));

      for (int i = 1; i <= count; i++) {
        final uID = i.toString();
        if (_searchQuery.isNotEmpty && !uID.toLowerCase().contains(_searchQuery)) continue;
        processedUnits.add({
          'unitNumber': uID,
          'floorNo': 0,
          'unitType': isCommercialBlock ? 'shop' : 'flat',
          'isOccupied': false,
        });
      }
    }

    final totalBlockUnits = rawUnits?.length ?? processedUnits.length;
    final blockOccupied = processedUnits.where((u) => u['isOccupied'] == true).length;

    // Header Color Palettes
    final List<Color> headerGradients = isGround
        ? const [Color(0xFF0F172A), Color(0xFF1E293B)] // Executive Charcoal Slate
        : (isCommercialBlock
            ? const [Color(0xFF042F2E), Color(0xFF0F766E)] // Deep Corporate Emerald
            : const [Color(0xFF0F172A), Color(0xFF1E3A8A)]); // Midnight Navy

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. REAL BLOCK HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isGround
                        ? Icons.storefront_rounded
                        : (isCommercialBlock ? Icons.business_center_rounded : Icons.apartment_rounded),
                    color: isGround ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGround
                            ? 'ગ્રાઉન્ડ લેવલ એકમો • $totalBlockUnits એકમો નોંધાયેલ'.tr
                            : (isCommercialBlock
                                ? 'કોમર્શિયલ ફ્લોર • $totalBlockUnits એકમો નોંધાયેલ'.tr
                                : 'રેસિડેન્શિયલ એકમો • $totalBlockUnits ફ્લેટ્સ'.tr),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    "$blockOccupied / $totalBlockUnits સક્રિય".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. REAL UNITS GRID
          Padding(
            padding: const EdgeInsets.all(14),
            child: processedUnits.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'આ બ્લોકમાં "$_searchQuery" વાળો કોઈ એકમ મળ્યો નથી.'.tr
                            : 'પસંદ કરેલા ફિલ્ટર મુજબ કોઈ એકમ નથી.'.tr,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  )
                : _buildRealUnitsGrid(context, processedUnits, blockName, displayName),
          ),
        ],
      ),
    );
  }

  // --- REAL UNITS GRID ---
  Widget _buildRealUnitsGrid(
    BuildContext context,
    List<Map<String, dynamic>> units,
    String blockName,
    String blockDisplayName,
  ) {
    // Check if units span multiple distinct floors configured by admin
    final Map<int, List<Map<String, dynamic>>> floorGroups = {};
    for (final u in units) {
      final f = (u['floorNo'] as num?)?.toInt() ?? 0;
      floorGroups.putIfAbsent(f, () => []).add(u);
    }

    final hasMultipleFloors = floorGroups.keys.length > 1;

    if (!hasMultipleFloors) {
      // Single floor / block: clean responsive grid
      return _buildUnitsWrapGrid(context, units, blockName, blockDisplayName);
    }

    // Multiple distinct floors in this block (e.g. F1-F5 range)
    final sortedFloors = floorGroups.keys.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedFloors.map((fKey) {
        final fUnits = floorGroups[fKey]!;
        final floorTitle = fKey == 0
            ? 'ગ્રાઉન્ડ ફ્લોર (Floor 0)'.tr
            : (fKey < 0 ? 'બેઝમેન્ટ B${fKey.abs()}'.tr : '$fKey મો માળ (Floor $fKey)'.tr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Floor Level Subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      floorTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "(${fUnits.length} એકમો)".tr,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              _buildUnitsWrapGrid(context, fUnits, blockName, blockDisplayName),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- CLEAN ADAPTIVE GRID OF UNITS ---
  Widget _buildUnitsWrapGrid(
    BuildContext context,
    List<Map<String, dynamic>> units,
    String blockName,
    String blockDisplayName,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 3 columns on standard phone, 4 on wider screens
        final crossCount = width > 500 ? 4 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: units.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final u = units[i];
            return _buildModernUnitTile(context, u, blockName, blockDisplayName);
          },
        );
      },
    );
  }

  // --- 🚪 MODERN PREMISE UNIT TILE (ACCURATE REAL DATA) ---
  Widget _buildModernUnitTile(
    BuildContext context,
    Map<String, dynamic> unit,
    String blockName,
    String blockDisplayName,
  ) {
    final unitId = (unit['unitNumber'] ?? '').toString();
    final unitType = (unit['unitType'] ?? 'flat').toString().toLowerCase();
    final areaSqFt = (unit['areaSqFt'] as num?)?.toDouble();
    final isOccupied = unit['isOccupied'] == true;
    final typeSpecs = _getUnitTypeSpecs(unitType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showUnitDetailSheet(context, unit, blockName, blockDisplayName);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isOccupied ? Colors.white : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOccupied ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              width: isOccupied ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isOccupied
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Unit Icon with Category Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(typeSpecs.icon, size: 16, color: typeSpecs.accentColor),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOccupied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Real Unit Number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  unitId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              // Real Area (Sq.Ft) or Unit Category
              if (areaSqFt != null && areaSqFt > 0) ...[
                Text(
                  "${areaSqFt.toInt()} sqft",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  typeSpecs.shortName,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isOccupied ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOccupied ? "સક્રિય".tr : "ખાલી".tr,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isOccupied ? const Color(0xFF166534) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 🌟 5. DETAILED UNIT BOTTOM SHEET (ACCURATE REAL DATA MODAL)
  // =========================================================================
  void _showUnitDetailSheet(
    BuildContext context,
    Map<String, dynamic> unit,
    String blockName,
    String blockDisplayName,
  ) {
    final unitId = (unit['unitNumber'] ?? '').toString();
    final unitType = (unit['unitType'] ?? 'flat').toString().toLowerCase();
    final floorNo = (unit['floorNo'] as num?)?.toInt() ?? 0;
    final areaSqFt = (unit['areaSqFt'] as num?)?.toDouble();
    final isOccupied = unit['isOccupied'] == true;
    final typeSpecs = _getUnitTypeSpecs(unitType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Unit Hero Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      typeSpecs.accentColor.withValues(alpha: 0.12),
                      typeSpecs.accentColor.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: typeSpecs.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: typeSpecs.accentColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: typeSpecs.accentColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(typeSpecs.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${typeSpecs.labelGujarati} $unitId',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOccupied ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOccupied ? '🟢 કબજેદાર'.tr : '⚪ ખાલી'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOccupied ? const Color(0xFF166534) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$blockDisplayName • ${floorNo == 0 ? "ગ્રાઉન્ડ ફ્લોર" : "$floorNo લો માળ"}'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Architectural Specifications Grid (4 Cards)
              Row(
                children: [
                  Expanded(
                    child: _buildSpecCard(
                      label: 'ક્ષેત્રફળ (Area)'.tr,
                      value: areaSqFt != null && areaSqFt > 0 ? '${areaSqFt.toInt()} Sq.Ft.' : 'N/A',
                      icon: Icons.square_foot_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecCard(
                      label: 'માળ લેવલ (Floor)'.tr,
                      value: floorNo == 0 ? 'ગ્રાઉન્ડ (0)'.tr : (floorNo < 0 ? 'બેઝમેન્ટ B${floorNo.abs()}'.tr : '$floorNo લો માળ'.tr),
                      icon: Icons.layers_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSpecCard(
                      label: 'એકમ શ્રેણી (Type)'.tr,
                      value: typeSpecs.labelGujarati,
                      icon: typeSpecs.icon,
                      color: typeSpecs.accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSpecCard(
                      label: 'બ્લોક / ફ્લોર'.tr,
                      value: blockName,
                      icon: Icons.apartment_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. REAL-TIME RESIDENT DETAILS FROM DATABASE
              Text(
                "કબજેદાર / સભ્ય વિગતો (Resident Info)".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUnitResident(unit, blockName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  final resident = snapshot.data;

                  if (resident != null) {
                    final resName = (resident['name'] ?? 'અજાણ્યો સભ્ય'.tr).toString();
                    final resPhone = (resident['displayPhone'] ?? resident['phone'] ?? '').toString();
                    final resEmail = (resident['email'] ?? '').toString();
                    final resRole = (resident['role'] ?? 'member').toString();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF10B981),
                                child: Text(
                                  resName.isNotEmpty ? resName[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      resRole == 'sub_admin' ? 'સબ-એડમિન / કમિટી મેમ્બર'.tr : 'નોંધાયેલ સભ્ય / દુકાનદાર'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    if (resEmail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        resEmail,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (resPhone.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                // Call Button
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => launchUrl(Uri.parse('tel:$resPhone')),
                                    icon: const Icon(Icons.phone_rounded, size: 16),
                                    label: Text('કૉલ કરો'.tr),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // WhatsApp Button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final clean = resPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                      launchUrl(
                                        Uri.parse('https://wa.me/$clean'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF16A34A)),
                                    label: Text('વોટ્સએપ'.tr),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF16A34A),
                                      side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  // VACANT / NO RESIDENT ASSIGNED
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.meeting_room_outlined, color: Color(0xFF64748B), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "કોઈ સભ્ય ફાળવેલ નથી (Vacant)".tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "આ એકમ હાલમાં ખાલી છે. તમે સીધા જ નવા સભ્યને એલોટ કરી શકો છો.".tr,
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAddUserScreen(
                                    initialRole: 'member',
                                    initialBlock: blockName,
                                    initialUnit: unitId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('આ યુનિટમાં સભ્ય ઉમેરો (Add Member)'.tr),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('બંધ કરો'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SPEC GRID CARD ---
  Widget _buildSpecCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FETCH RESIDENT IN FIRESTORE ---
  Future<Map<String, dynamic>?> _fetchUnitResident(Map<String, dynamic> unit, String blockName) async {
    try {
      final sid = SocietyService.instance.societyId;
      final uNum = (unit['unitNumber'] ?? '').toString();
      final normBlock = SocietyService.instance.normalizeBlockName(blockName);

      // 1. Direct memberId lookup if present
      final memberId = unit['memberId']?.toString();
      if (memberId != null && memberId.isNotEmpty) {
        final doc = await AppFirestore.instance.collection('users').doc(memberId).get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      }

      // 2. Query users collection by societyId, unitNumber and blockName
      final snap = await AppFirestore.instance
          .collection('users')
          .where('societyId', isEqualTo: sid)
          .where('unitNumber', isEqualTo: uNum)
          .get();

      for (final doc in snap.docs) {
        final d = doc.data();
        final b = (d['blockName'] ?? '').toString();
        if (SocietyService.instance.normalizeBlockName(b) == normBlock || b == blockName) {
          return d;
        }
      }
    } catch (_) {}
    return null;
  }

  // --- UNIT TYPE SPECIFICATION HELPERS ---
  _UnitTypeSpecs _getUnitTypeSpecs(String unitType) {
    switch (unitType) {
      case 'shop':
        return _UnitTypeSpecs(
          labelGujarati: 'દુકાન (Shop)'.tr,
          shortName: 'રીટેલ શોપ'.tr,
          icon: Icons.storefront_rounded,
          accentColor: const Color(0xFFD97706), // Amber Bronze
        );
      case 'showroom':
        return _UnitTypeSpecs(
          labelGujarati: 'શોરૂમ (Showroom)'.tr,
          shortName: 'શોરૂમ'.tr,
          icon: Icons.store_mall_directory_rounded,
          accentColor: const Color(0xFF7C3AED), // Luxury Violet
        );
      case 'office':
        return _UnitTypeSpecs(
          labelGujarati: 'ઓફિસ (Corporate)'.tr,
          shortName: 'ઓફિસ'.tr,
          icon: Icons.business_center_rounded,
          accentColor: const Color(0xFF0284C7), // Sky Blue
        );
      case 'bungalow':
      case 'villa':
      case 'rowhouse':
        return _UnitTypeSpecs(
          labelGujarati: 'બંગલો / રો-હાઉસ'.tr,
          shortName: 'બંગલો'.tr,
          icon: Icons.holiday_village_rounded,
          accentColor: const Color(0xFF059669), // Forest Emerald
        );
      case 'godown':
      case 'warehouse':
        return _UnitTypeSpecs(
          labelGujarati: 'ગોડાઉન / વેરહાઉસ'.tr,
          shortName: 'ગોડાઉન'.tr,
          icon: Icons.warehouse_rounded,
          accentColor: const Color(0xFFEA580C), // Orange
        );
      case 'flat':
      default:
        return _UnitTypeSpecs(
          labelGujarati: 'ફ્લેટ (Apartment)'.tr,
          shortName: 'ફ્લેટ'.tr,
          icon: Icons.door_front_door_rounded,
          accentColor: const Color(0xFF0F766E), // Deep Teal
        );
    }
  }

  // --- ARCHITECTURE THEME CONFIGURATION ---
  _ArchThemeConfig _getArchitectureTheme(String architectureType) {
    switch (architectureType.toLowerCase()) {
      case 'commercial':
        return _ArchThemeConfig(
          appBarColor: const Color(0xFF042F2E),
          gradientColors: const [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF0F766E)],
          icon: Icons.storefront_rounded,
          premiseBadge: 'COMMERCIAL PREMISE',
          gujaratiTitle: 'કોમર્શિયલ પરિસર એકમો'.tr,
          gujaratiSubtitle: 'એડમિન દ્વારા સેટઅપ કરેલ શોપ્સ અને ઓફિસ યુનિટ્સ'.tr,
        );
      case 'mixed':
        return _ArchThemeConfig(
          appBarColor: const Color(0xFF0F172A),
          gradientColors: const [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF0F766E)],
          icon: Icons.domain_verification_rounded,
          premiseBadge: 'MIXED-USE COMPLEX',
          gujaratiTitle: 'મિક્સ્ડ સંકુલ એકમો'.tr,
          gujaratiSubtitle: 'એડમિન દ્વારા સેટઅપ કરેલ શોપ્સ અને રેસિડેન્શિયલ ફ્લેટ્સ'.tr,
        );
      case 'street':
        return _ArchThemeConfig(
          appBarColor: const Color(0xFF022C22),
          gradientColors: const [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF047857)],
          icon: Icons.holiday_village_rounded,
          premiseBadge: 'STREET / VILLA',
          gujaratiTitle: 'સોસાયટી શેરી અને રો-હાઉસ'.tr,
          gujaratiSubtitle: 'એડમિન દ્વારા સેટઅપ કરેલ બંગલો અને પ્લોટ એકમો'.tr,
        );
      case 'wing':
      default:
        return _ArchThemeConfig(
          appBarColor: const Color(0xFF0F172A),
          gradientColors: const [Color(0xFF0B132B), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          icon: Icons.apartment_rounded,
          premiseBadge: 'RESIDENTIAL WINGS',
          gujaratiTitle: 'સોસાયટી વિંગ્સ અને ફ્લેટ્સ'.tr,
          gujaratiSubtitle: 'એડમિન દ્વારા સેટઅપ કરેલ વિંગ્સ અને એપાર્ટમેન્ટ્સ'.tr,
        );
    }
  }
}

class _UnitTypeSpecs {
  final String labelGujarati;
  final String shortName;
  final IconData icon;
  final Color accentColor;

  _UnitTypeSpecs({
    required this.labelGujarati,
    required this.shortName,
    required this.icon,
    required this.accentColor,
  });
}

class _ArchThemeConfig {
  final Color appBarColor;
  final List<Color> gradientColors;
  final IconData icon;
  final String premiseBadge;
  final String gujaratiTitle;
  final String gujaratiSubtitle;

  _ArchThemeConfig({
    required this.appBarColor,
    required this.gradientColors,
    required this.icon,
    required this.premiseBadge,
    required this.gujaratiTitle,
    required this.gujaratiSubtitle,
  });
}