import 'dart:io';
import 'dart:ui' as ui;
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

class MemberPreApproveScreen extends StatefulWidget {
  final String memberFlat;
  final String memberName;

  const MemberPreApproveScreen({
    super.key,
    this.memberFlat = '',
    this.memberName = '',
  });

  @override
  State<MemberPreApproveScreen> createState() => _MemberPreApproveScreenState();
}

class _MemberPreApproveScreenState extends State<MemberPreApproveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _qrKey = GlobalKey();

  String _selectedPurpose = '👪 સગા-સંબંધી';
  bool _isGenerating = false;
  String? _generatedPassId;
  String? _generatedGuestName;

  final List<String> _purposes = [
    '👪 સગા-સંબંધી',
    '📦 ડિલિવરી / કુરિયર',
    '🚗 કેબ / ડ્રાઈવર',
    '🔧 સર્વિસ / રિપેર',
    '🤝 મિત્ર / મુલાકાતી',
  ];

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  Future<void> _submitPreApproval() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isGenerating = true);

    try {
      final docRef = await AppFirestore.instance.collection('pre_approvals').add({
        'guestName': _nameC.text.trim(),
        'guestPhone': _phoneC.text.trim(),
        'purpose': _selectedPurpose,
        'memberId': currentUserId,
        'memberName': widget.memberName,
        'memberFlat': widget.memberFlat,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pre-approved',
        'societyId': SocietyService.instance.societyId,
      });

      setState(() {
        _generatedPassId = docRef.id;
        _generatedGuestName = _nameC.text.trim();
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('પાસ બનાવવામાં ભૂલ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareGeneratedPass() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/gate_pass_${_generatedPassId ?? 'qr'}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'નમસ્તે ${_generatedGuestName ?? 'મહેમાન'},\nઆ સોસાયટી ગેટ એન્ટ્રી QR પાસ છે.\nગેટ પર વોચમેનને આ QR કોડ બતાવવાથી તુરંત સીધી એન્ટ્રી મળશે.\nફ્લેટ: ${widget.memberFlat}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('પાસ શેરિંગમાં ભૂલ: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _generatedPassId = null;
      _generatedGuestName = null;
      _nameC.clear();
      _phoneC.clear();
      _selectedPurpose = '👪 સગા-સંબંધી';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const PremiumAppBar(
        title: 'મહેમાન પૂર્વ-મંજૂરી & પાસ',
        subtitle: 'QR ડિજિટલ એન્ટ્રી અને ગેસ્ટ ઇન્વિટેશન',
        icon: Icons.qr_code_scanner_rounded,
        accentColor: Color(0xFF0D9488),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Featured Illustration Banner
            Container(
              margin: const EdgeInsets.all(16),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/digital_pass.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D9488)),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0F172A).withValues(alpha: 0.88),
                              const Color(0xFF0D9488).withValues(alpha: 0.70),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF34D399)),
                            ),
                            child: const Text(
                              '✨ ડિજિટલ સિક્યોરિટી એન્ટ્રી',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'VIP ગેટ એન્ટ્રી QR પાસ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'વોચમેન પૂછપરછ વગર મહેમાનને સીધા આવવા માટે QR પાસ મોકલો.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_generatedPassId != null) ...[
              // Generated Pass Card with QR
              _buildGeneratedPassView(),
            ] else ...[
              // Form to generate pass
              _buildInputForm(),
            ],

            const SizedBox(height: 24),
            _buildPastPassesSection(currentUserId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'મહેમાનની વિગતો',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameC,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'મહેમાનનું નામ *',
                hintText: 'દા.ત. રાહુલ શાહ',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0D9488)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'કૃપા કરીને નામ દાખલ કરો' : null,
            ),
            const SizedBox(height: 16),
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
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0D9488)),
                prefixText: '+91 ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) {
                if (v == null || v.trim().length != 10) {
                  return 'સાચો ૧૦ અંકનો નંબર દાખલ કરો';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'આવવાનો હેતુ પસંદ કરો:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _purposes.map((p) {
                final isSelected = _selectedPurpose == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D9488),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (_) => setState(() => _selectedPurpose = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _submitPreApproval,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_rounded, color: Colors.white),
                label: Text(
                  _isGenerating ? 'પાસ જનરેટ થઈ રહ્યો છે...' : 'મંજૂર કરો & QR પાસ મેળવો',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedPassView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR પાસ તૈયાર છે!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'આ પાસ મહેમાન સાથે WhatsApp પર શેર કરો.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Digital Gate Pass Card to Capture & Share
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🛡️ સ્માર્ટ સોસાયટી પાસ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488)),
                          ),
                          Text(
                            _generatedGuestName ?? 'મહેમાન',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.memberFlat.isNotEmpty ? widget.memberFlat : 'ફ્લેટ',
                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: _generatedPassId!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'હેતુ: $_selectedPurpose',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'વોચમેન આ QR સ્કેન કરીને વગર કોઈ રોકટોક સીધી એન્ટ્રી આપશે.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareGeneratedPass,
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'WhatsApp શેર',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('નવો પાસ બનાવો'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastPassesSection(String currentUserId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'તાજેતરમાં જનરેટ કરેલા પાસ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
                .collection('pre_approvals')
                .where('memberId', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'હજુ સુધી કોઈ પૂર્વ-મંજૂરી પાસ બનાવેલ નથી.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  final name = (d['guestName'] ?? 'અનામી મહેમાન').toString();
                  final phone = (d['guestPhone'] ?? '').toString();
                  final purpose = (d['purpose'] ?? 'મુલાકાત').toString();
                  final status = (d['status'] ?? 'pre-approved').toString();

                  Color statusColor = Colors.orange;
                  String statusLabel = 'પેન્ડિંગ એન્ટ્રી';
                  if (status == 'entered' || status == 'completed') {
                    statusColor = Colors.green;
                    statusLabel = 'અંદર આવ્યા';
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$phone • $purpose',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
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
    );
  }
}
