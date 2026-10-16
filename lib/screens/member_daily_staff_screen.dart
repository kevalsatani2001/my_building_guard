import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/society_service.dart';

class MemberDailyStaffScreen extends StatefulWidget {
  const MemberDailyStaffScreen({super.key});

  @override
  State<MemberDailyStaffScreen> createState() => _MemberDailyStaffScreenState();
}

class _MemberDailyStaffScreenState extends State<MemberDailyStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();

  String _selectedRole = 'કામવાળા (Maid)';
  bool _isAdding = false;
  bool _showAddForm = false;

  final List<String> _roles = [
    'કામવાળા (Maid)',
    'ડ્રાઈવર (Driver)',
    'રસોઈયા (Cook)',
    'માળી (Gardener)',
    'ટ્યુટર (Tutor)',
    'અન્ય હેલ્પર',
  ];

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _addStaff() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isAdding = true);

    try {
      await AppFirestore.instance.collection('daily_staff').add({
        'memberId': uid,
        'staffName': _nameC.text.trim(),
        'staffPhone': _phoneC.text.trim(),
        'staffRole': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'societyId': SocietyService.instance.societyId,
      });

      _nameC.clear();
      _phoneC.clear();

      setState(() {
        _isAdding = false;
        _showAddForm = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('સ્ટાફ સફળતાપૂર્વક ઉમેરાઈ ગયો.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isAdding = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સ્ટાફ ઉમેરવામાં ભૂલ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteStaff(String docId, String name) async {
    try {
      await AppFirestore.instance.collection('daily_staff').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name કાઢી નાખવામાં આવ્યા.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'કાયમી સ્ટાફ & હેલ્પર્સ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Modern Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ડેઇલી હેલ્પર્સ મેનેજમેન્ટ',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'કામવાળા, ડ્રાઈવર કે રસોઈયા ગેટ પર સરળતાથી પ્રવેશી શકે.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Add Staff Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'નવા સ્ટાફ / હેલ્પર ઉમેરો',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _showAddForm ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                          color: const Color(0xFF0D9488),
                        ),
                        onPressed: () => setState(() => _showAddForm = !_showAddForm),
                      ),
                    ],
                  ),
                  if (_showAddForm) ...[
                    const Divider(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'કામગીરી / ભૂમિકા:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _roles.map((r) {
                              final isSelected = _selectedRole == r;
                              return ChoiceChip(
                                label: Text(r),
                                selected: isSelected,
                                selectedColor: const Color(0xFF0D9488),
                                backgroundColor: const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (_) => setState(() => _selectedRole = r),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameC,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'સ્ટાફનું નામ *',
                              hintText: 'દા.ત. મીનાબેન',
                              prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF0D9488)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'નામ દાખલ કરો' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneC,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'મોબાઈલ નંબર *',
                              hintText: '૧૦ આંકડાનો નંબર',
                              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF0D9488)),
                              prefixText: '+91 ',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length != 10) {
                                return 'સાચો ૧૦ અંકનો નંબર દાખલ કરો';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isAdding ? null : _addStaff,
                              icon: _isAdding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_rounded, color: Colors.white),
                              label: Text(
                                _isAdding ? 'ઉમેરાઈ રહ્યું છે...' : 'સ્ટાફ સાચવો',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
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

            const SizedBox(height: 20),

            // Registered Staff Stream
            StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.instance
                  .collection('daily_staff')
                  .where('memberId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.badge_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'હજુ કોઈ સ્ટાફ નોંધાયેલ નથી',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ઉપરના બટન પર ક્લિક કરીને કામવાળા કે ડ્રાઈવર ઉમેરો.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'નોંધાયેલ સ્ટાફ (${docs.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final d = doc.data() as Map<String, dynamic>;
                          final name = (d['staffName'] ?? 'અનામી').toString();
                          final phone = (d['staffPhone'] ?? '').toString();
                          final role = (d['staffRole'] ?? 'હેલ્પર').toString();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF0D9488),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              role,
                                              style: const TextStyle(
                                                color: Color(0xFF0D9488),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              phone,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 22),
                                    tooltip: 'કોલ કરો',
                                    onPressed: () => _makeCall(phone),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                                  tooltip: 'સ્ટાફ કાઢી નાખો',
                                  onPressed: () => _deleteStaff(doc.id, name),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
