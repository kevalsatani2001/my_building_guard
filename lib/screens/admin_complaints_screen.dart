import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/society_service.dart';

/// Admin: list member complaints and mark resolved.
class AdminComplaintsScreen extends StatelessWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ફરિયાદ નિવારણ'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .limit(120)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ભૂલ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs
              .where((d) => SocietyService.instance
                  .documentBelongsToCurrentTenant(
                      d.data() as Map<String, dynamic>?))
              .toList();
          if (docs.isEmpty) {
            return const Center(child: Text('હજી કોઈ ફરિયાદ નથી.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>;
              final status = m['status'] as String? ?? 'pending';
              final title = m['title'] as String? ?? '';
              final desc = m['description'] as String? ?? '';
              final memberName = m['memberName'] as String? ?? '';
              final photoUrl = m['photoUrl'] as String? ?? '';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Chip(
                            label: Text(
                              status == 'resolved' ? 'ઉકેલાઈ' : 'બાકી',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: status == 'resolved'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),
                        ],
                      ),
                      Text('મેમ્બર: $memberName',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Text(desc),
                      if (photoUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photoUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image)),
                        ),
                      ],
                      if (status != 'resolved')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('complaints')
                                  .doc(d.id)
                                  .update({
                                'status': 'resolved',
                                'resolvedAt': FieldValue.serverTimestamp(),
                              });
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Resolved'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
