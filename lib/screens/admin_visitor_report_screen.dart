import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/society_service.dart';

class AdminVisitorReportScreen extends StatefulWidget {
  const AdminVisitorReportScreen({super.key});

  @override
  State<AdminVisitorReportScreen> createState() => _AdminVisitorReportScreenState();
}

class _AdminVisitorReportScreenState extends State<AdminVisitorReportScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "વિઝિટર રિપોર્ટ & રજીસ્ટર",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "મુલાકાતી એન્ટ્રી, એક્ઝિટ અને મંજૂરી વિગત",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppFirestore.instance
            .collection('visitors')
            .where('societyId', isEqualTo: SocietyService.instance.societyId)
            .orderBy('entryTime', descending: true)
            .limit(200)
            .snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

          final total = allDocs.length;
          final approved = allDocs.where((d) => (d.data() as Map)['status'] == 'approved').length;
          final pending = allDocs.where((d) => (d.data() as Map)['status'] == 'pending').length;
          final rejected = allDocs.where((d) => (d.data() as Map)['status'] == 'rejected').length;
          final checkedOut = allDocs.where((d) => (d.data() as Map)['status'] == 'checked_out').length;

          // Apply Filter & Search
          var filtered = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString();
            if (_selectedFilter != 'all' && status != _selectedFilter) return false;

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final name = (data['name'] ?? '').toString().toLowerCase();
              final phone = (data['phone'] ?? '').toString().toLowerCase();
              final vehicle = (data['vehicleNo'] ?? '').toString().toLowerCase();
              final unit = (data['unitNumber'] ?? '').toString().toLowerCase();
              final block = (data['blockName'] ?? '').toString().toLowerCase();
              return name.contains(q) || phone.contains(q) || vehicle.contains(q) || unit.contains(q) || block.contains(q);
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Top KPI Summary Container
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "મુલાકાતી આંકડા",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "કુલ મુલાકાતીઓ: $total",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _kpiItem("મંજૂર", approved, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                        const SizedBox(width: 8),
                        _kpiItem("પેન્ડિંગ", pending, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                        const SizedBox(width: 8),
                        _kpiItem("નકારેલ", rejected, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                        const SizedBox(width: 8),
                        _kpiItem("બહાર ગયા", checkedOut, const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "નામ, ફોન, વાહન અથવા ફ્લેટ નંબર શોધો...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _filterChip('all', 'બધા ($total)'),
                    const SizedBox(width: 6),
                    _filterChip('approved', '🟢 મંજૂર ($approved)'),
                    const SizedBox(width: 6),
                    _filterChip('pending', '🟠 પેન્ડિંગ ($pending)'),
                    const SizedBox(width: 6),
                    _filterChip('rejected', '🔴 નકારેલ ($rejected)'),
                    const SizedBox(width: 6),
                    _filterChip('checked_out', '🔵 બહાર ગયા ($checkedOut)'),
                  ],
                ),
              ),

              // Visitors List
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && allDocs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "'$_searchQuery' માટે કોઈ રેકોર્ડ મળ્યો નથી"
                                  : "આ કેટેગરીમાં કોઈ વિઝિટર નથી",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final data = filtered[i].data() as Map<String, dynamic>;
                          return _buildVisitorCard(data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiItem(String label, int count, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> d) {
    final name = (d['name'] ?? 'અનામી').toString();
    final phone = (d['phone'] ?? '').toString();
    final vehicle = (d['vehicleNo'] ?? '').toString();
    final purpose = (d['purpose'] ?? '').toString();
    final unit = (d['unitNumber'] ?? '').toString();
    final block = (d['blockName'] ?? '').toString();
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
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusLabel = "મંજૂર";
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = "નકારેલ";
        statusIcon = Icons.cancel_rounded;
        break;
      case 'checked_out':
        statusColor = const Color(0xFF0D9488);
        statusLabel = "બહાર ગયા";
        statusIcon = Icons.output_rounded;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = "પેન્ડિંગ";
        statusIcon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room_rounded, size: 14, color: Color(0xFF4338CA)),
                  const SizedBox(width: 4),
                  Text(
                    "ફ્લેટ: $block-$unit",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF4338CA)),
                  ),
                  if (purpose.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        purpose,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              if (vehicle.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.directions_car_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      vehicle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          if (entryTime != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "એન્ટ્રી: ${DateFormat('dd MMM, hh:mm a').format(entryTime)}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (exitTime != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.logout_rounded, size: 12, color: Color(0xFF0D9488)),
                  const SizedBox(width: 4),
                  Text(
                    "એક્ઝિટ: ${DateFormat('hh:mm a').format(exitTime)}",
                    style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
