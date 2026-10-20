import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

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
      appBar: const PremiumAppBar(
        title: 'કાયમી સ્ટાફ & હેલ્પર્સ',
        subtitle: 'કામવાળા, ડ્રાઈવર & રસોઈયા ગેટ પાસ',
        icon: Icons.badge_rounded,
        accentColor: Color(0xFF0D9488),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Ultra-Premium 3D Hero Banner (Text strictly on left, 3D characters on right)
            _buildHeroBanner(),

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
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showAddForm = !_showAddForm);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        const Text(
                          'નવા સ્ટાફ / હેલ્પર ઉમેરો',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _showAddForm ? const Color(0xFFFEE2E2) : const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _showAddForm ? Icons.remove_rounded : Icons.add_rounded,
                            color: _showAddForm ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/staff_empty.jpg',
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'હજુ કોઈ સ્ટાફ નોંધાયેલ નથી!',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'ઉપરના બટન પર ક્લિક કરીને કામવાળા કે ડ્રાઈવર ઉમેરો, જેથી તેઓને ગેટ પર ડિજિટલ સિક્યોરિટી પાસ મળે.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                        ],
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
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
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
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF0D9488),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
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
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              role,
                                              style: const TextStyle(
                                                color: Color(0xFF0D9488),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              phone,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 18),
                                    ),
                                    tooltip: 'કોલ કરો',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _makeCall(phone);
                                    },
                                  ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                  ),
                                  tooltip: 'સ્ટાફ કાઢી નાખો',
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _deleteStaff(doc.id, name);
                                  },
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

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 3D Hero Image (domestic maid & driver characters on right, smooth teal gradient on left)
            Image.asset(
              'assets/images/staff_hero.jpg',
              height: 165,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Text strictly constrained to left portion (flex 12) so it NEVER covers the 3D artwork (flex 9)
            Container(
              height: 165,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'ડેઇલી સ્ટાફ & હેલ્પર્સ',
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'કાયમી સ્ટાફ મેનેજમેન્ટ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'કામવાળા, ડ્રાઈવર કે રસોઈયા ગેટ પર સરળતાથી પ્રવેશી શકે અને ડિજિટલ સિક્યોરિટી પાસ વેરિફાય થાય.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 9,
                    child: SizedBox(), // Area reserved for 3D art on right
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
