import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/society_service.dart';

class AdminEmergencyContactsScreen extends StatefulWidget {
  const AdminEmergencyContactsScreen({super.key});

  @override
  State<AdminEmergencyContactsScreen> createState() => _AdminEmergencyContactsScreenState();
}

class _AdminEmergencyContactsScreenState extends State<AdminEmergencyContactsScreen> {
  final _titleC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _isAdding = false;

  final List<(String, String, IconData, Color)> _quickPresets = [
    ('પોલીસ', '100', Icons.local_police_rounded, Colors.blue),
    ('એમ્બ્યુલન્સ', '108', Icons.medical_services_rounded, Colors.red),
    ('ફાયર બ્રિગેડ', '101', Icons.fire_truck_rounded, Colors.deepOrange),
    ('ઇલેક્ટ્રિશિયન', '', Icons.bolt_rounded, Colors.amber),
    ('પ્લમ્બર', '', Icons.plumbing_rounded, Colors.teal),
    ('લિફ્ટ સર્વિસ', '', Icons.elevator_rounded, Colors.indigo),
  ];

  @override
  void dispose() {
    _titleC.dispose();
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

  Future<void> _addContact({String? customTitle, String? customPhone}) async {
    final title = (customTitle ?? _titleC.text).trim();
    final phone = (customPhone ?? _phoneC.text).trim();

    if (title.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને સેવાનું નામ અને નંબર બંને દાખલ કરો."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final sid = SocietyService.instance.societyId;
      await AppFirestore.instance.collection('emergency_contacts').add({
        'title': title,
        'phone': phone,
        'societyId': sid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleC.clear();
      _phoneC.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'$title' ઈમરજન્સી ડિરેક્ટરીમાં ઉમેરાઈ ગયું!"),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ: $e"), backgroundColor: Colors.red.shade800),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ઈમરજન્સી હેલ્પલાઇન ડિરેક્ટરી",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "પોલીસ, ૧૦૮, ફાયર અને તાત્કાલિક સેવાઓ",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Emergency Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 26),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "૨૪x૭ તાત્કાલિક સેવાઓ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "તમામ સભ્યો અને વોચમેન આ નંબરો પર ૧-ટેપથી કૉલ કરી શકશે",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 1-Tap Presets
            const Text(
              "ઝડપી પ્રીસેટ્સ (૧-ટેપથી ઉમેરો):",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPresets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(p.$3, size: 16, color: p.$4),
                      label: Text(p.$2.isNotEmpty ? "${p.$1} (${p.$2})" : p.$1),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: p.$4.withValues(alpha: 0.3)),
                      ),
                      onPressed: () {
                        if (p.$2.isNotEmpty) {
                          _addContact(customTitle: p.$1, customPhone: p.$2);
                        } else {
                          setState(() {
                            _titleC.text = p.$1;
                            _phoneC.text = "";
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Add Custom Contact Form Card
            Container(
              padding: const EdgeInsets.all(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "નવો ઈમરજન્સી સંપર્ક ઉમેરો:",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleC,
                    decoration: InputDecoration(
                      labelText: "સેવા / વ્યક્તિનું નામ *",
                      hintText: "દા.ત. સુરત ફાયર કંટ્રોલ, ડૉ. પટેલ",
                      prefixIcon: const Icon(Icons.badge_rounded, size: 20, color: Color(0xFFDC2626)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneC,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "સંપર્ક નંબર (Phone Number) *",
                      hintText: "દા.ત. 101 અથવા 9876543210",
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFFDC2626)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _isAdding ? null : () => _addContact(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text("સંપર્ક સેવ કરો", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Contacts List
            const Text(
              "હાલની ઈમરજન્સી હેલ્પલાઇન લિસ્ટ:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.instance
                  .collection('emergency_contacts')
                  .where('societyId', isEqualTo: SocietyService.instance.societyId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        "હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના પ્રીસેટ પર ટેપ કરીને નંબર ઉમેરો.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final title = (d['title'] ?? '').toString();
                    final phone = (d['phone'] ?? '').toString();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFDC2626), size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _makeCall(phone),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.call_rounded, size: 16, color: Color(0xFF047857)),
                                  SizedBox(width: 4),
                                  Text(
                                    "કૉલ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                            onPressed: () async {
                              await AppFirestore.instance.collection('emergency_contacts').doc(docId).delete();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
