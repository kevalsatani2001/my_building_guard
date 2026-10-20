import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/society_service.dart';
import '../widgets/premium_ui.dart';

/// Admin: list member complaints and mark resolved with modern filters and cards.
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'resolved'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const PremiumAppBar(
        title: "ફરિયાદ નિવારણ ડેસ્ક",
        subtitle: "સભ્યોની સમસ્યાઓ અને રિઝોલ્યુશન સ્ટેટસ",
        icon: Icons.support_agent_rounded,
        accentColor: Color(0xFF6D28D9),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .limit(150)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('ડેટા લોડ કરવામાં ભૂલ: ${snap.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final allDocs = snap.hasData
              ? snap.data!.docs
                  .where((d) => SocietyService.instance.documentBelongsToCurrentTenant(d.data() as Map<String, dynamic>?))
                  .toList()
              : <QueryDocumentSnapshot>[];

          final pendingDocs = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] != 'resolved').toList();
          final resolvedDocs = allDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'resolved').toList();

          final filteredDocs = switch (_selectedFilter) {
            'pending' => pendingDocs,
            'resolved' => resolvedDocs,
            _ => allDocs,
          };

          return Column(
            children: [
              // 3D Hero Banner for Admin Complaints
              _buildAdminHeroBanner(pendingDocs.length, resolvedDocs.length),

              // Filter Chips Bar (ALWAYS visible)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildFilterChip('બધા (${allDocs.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('બાકી (${pendingDocs.length})', 'pending', badgeColor: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    _buildFilterChip('ઉકેલાઈ (${resolvedDocs.length})', 'resolved', badgeColor: Colors.green.shade700),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Complaints List (Only this section loads)
              Expanded(
                child: !snap.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDocs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.asset(
                                      'assets/images/complaint_empty.jpg',
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _selectedFilter == 'pending'
                                        ? 'કોઈ બાકી ફરિયાદ નથી!'
                                        : 'હજી સુધી કોઈ ફરિયાદ નોંધાયેલ નથી.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFilter == 'pending'
                                        ? 'બધા પ્રશ્નો ઉકેલાઈ ગયા છે. બધું સરસ ચાલે છે!'
                                        : 'જ્યારે કોઈ સભ્ય ફરિયાદ નોંધાવશે ત્યારે અહીં દેખાશે.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, i) {
                          final d = filteredDocs[i];
                          final m = d.data() as Map<String, dynamic>;
                          return _buildComplaintCard(context, d.id, m);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey, {Color? badgeColor}) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: badgeColor ?? Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filterKey);
      },
    );
  }

  Widget _buildComplaintCard(BuildContext context, String docId, Map<String, dynamic> m) {
    final status = m['status'] as String? ?? 'pending';
    final isResolved = status == 'resolved';
    final title = (m['title'] as String? ?? '').trim();
    final desc = (m['description'] as String? ?? '').trim();
    final memberName = (m['memberName'] as String? ?? 'મેમ્બર').trim();
    final photoUrl = (m['photoUrl'] as String? ?? '').trim();

    DateTime? createdAt;
    final rawTs = m['createdAt'];
    if (rawTs is Timestamp) {
      createdAt = rawTs.toDate();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved ? Colors.green.shade100 : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.isNotEmpty ? title : 'ફરિયાદ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isResolved ? Colors.green.shade300 : Colors.amber.shade400,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: 13,
                        color: isResolved ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isResolved ? 'ઉકેલાઈ ગઈ' : 'બાકી (Pending)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isResolved ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Member Info & Timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade800,
                  child: const Icon(Icons.person, size: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  memberName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
                if (createdAt != null) ...[
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy hh:mm a').format(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Description text box
            if (desc.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ),

            // Photo attachment (if any)
            if (photoUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showImagePreview(context, photoUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        photoUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 100,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('ઝૂમ કરો', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action: Mark Resolved Button
            if (!isResolved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await AppFirestore.instance.collection('complaints').doc(docId).update({
                      'status': 'resolved',
                      'resolvedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ફરિયાદ ઉકેલાઈ ગઈ તરીકે નોંધાઈ ગઈ!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('ઉકેલાઈ તરીકે માર્ક કરો'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeroBanner(int pending, int resolved) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/complaint_hero.jpg',
              height: 145,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              height: 145,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'એડમિન કંટ્રોલ પેનલ',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ફરિયાદ નિવારણ સેન્ટર',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: pending > 0 ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$pending બાકી',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$resolved ઉકેલાયેલ',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 9,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
