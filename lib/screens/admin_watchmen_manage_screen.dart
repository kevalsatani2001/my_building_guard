import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/society_service.dart';
import 'admin_add_user_screen.dart';

class AdminWatchmenManageScreen extends StatefulWidget {
  const AdminWatchmenManageScreen({super.key});

  @override
  State<AdminWatchmenManageScreen> createState() => _AdminWatchmenManageScreenState();
}

class _AdminWatchmenManageScreenState extends State<AdminWatchmenManageScreen> {
  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showResetPasswordDialog(String uid, String name) {
    final pwdC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF4338CA)),
            const SizedBox(width: 8),
            Text('$name નો પાસવર્ડ બદલો', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: pwdC,
          decoration: InputDecoration(
            labelText: 'નવો પાસવર્ડ *',
            hintText: 'ઓછામાં ઓછા 6 અક્ષર',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ'),
          ),
          FilledButton(
            onPressed: () async {
              final pwd = pwdC.text.trim();
              if (pwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('પાસવર્ડ 6 અક્ષરથી મોટો હોવો જોઈએ.')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('વોચમેન પાસવર્ડ રીસેટ રિક્વેસ્ટ મોકલાઈ ગઈ છે.'),
                  backgroundColor: Color(0xFF047857),
                ),
              );
            },
            child: const Text('બદલો'),
          ),
        ],
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "વોચમેન સિક્યોરિટી મેનેજમેન્ટ",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "ગેટ ગાર્ડ્સ, ઓન-ડ્યુટી સ્ટેટસ & પિન કંટ્રોલ",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminAddUserScreen(initialRole: 'watchman'),
          ),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('નવો વોચમેન ઉમેરો', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AppFirestore.instance
            .collection('users')
            .where('societyId', isEqualTo: SocietyService.instance.societyId)
            .where('role', isEqualTo: 'watchman')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
          final onDutyCount = docs.where((d) => (d.data() as Map)['isActive'] == true).length;

          return Column(
            children: [
              // Top Status Hero Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.security_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "મુખ્ય ગેટ સિક્યોરિટી ટીમ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "કુલ વોચમેન: ${docs.length} • હાલ ફરજ પર: $onDutyCount",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Guards List
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "હજુ સુધી કોઈ વોચમેન નોંધાયેલ નથી.",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "નીચેના બટનથી નવો વોચમેન ઉમેરો.",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final docId = docs[i].id;
                          final name = (d['name'] ?? 'અનામી ગાર્ડ').toString();
                          final phone = (d['phone'] ?? '').toString();
                          final email = (d['email'] ?? '').toString();
                          final isActive = d['isActive'] == true;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isActive
                                          ? [const Color(0xFF10B981), const Color(0xFF047857)]
                                          : [Colors.grey.shade400, Colors.grey.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.security_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? "🟢 ફરજ પર" : "⚪ રજા પર",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isActive ? const Color(0xFF047857) : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        phone.isNotEmpty ? phone : email,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded, size: 20, color: Color(0xFF047857)),
                                    tooltip: 'કોલ કરો',
                                    onPressed: () => _makeCall(phone),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFF4338CA)),
                                  tooltip: 'પાસવર્ડ બદલો',
                                  onPressed: () => _showResetPasswordDialog(docId, name),
                                ),
                                Switch(
                                  value: isActive,
                                  activeThumbColor: const Color(0xFF10B981),
                                  onChanged: (newVal) async {
                                    await AppFirestore.instance
                                        .collection('users')
                                        .doc(docId)
                                        .update({'isActive': newVal});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
