import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';
import '../services/society_service.dart';
import '../widgets/admin_broadcast_dialogs.dart';

class AdminBroadcastScreen extends StatefulWidget {
  final String? targetUID;
  final String? targetName;

  const AdminBroadcastScreen({
    super.key,
    this.targetUID,
    this.targetName,
  });

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleC = TextEditingController();
  final _bodyC = TextEditingController();
  String _selectedCategory = 'સામાન્ય';
  bool _isSending = false;

  final List<(String, String, IconData)> _categories = [
    ('સામાન્ય', 'સોસાયટી સૂચના', Icons.campaign_rounded),
    ('પાણી', 'પાણી સપ્લાય અપડેટ', Icons.water_drop_rounded),
    ('વીજળી', 'લાઈટ / પાવર કટ સૂચના', Icons.bolt_rounded),
    ('મીટિંગ', 'સોસાયટી સામાન્ય સભા', Icons.groups_rounded),
    ('ઇમરજન્સી', 'તાકીદની સુરક્ષા સૂચના', Icons.warning_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _titleC.text = "સોસાયટી સામાન્ય સૂચના";
  }

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleC.text.trim();
    final body = _bodyC.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને શીર્ષક અને સંદેશ બંને દાખલ કરો."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // જો તમામ સભ્યો માટે હોય તો 'notices' કલેક્શનમાં પણ નોટિસ સેવ કરો જેથી મેમ્બર ડેશબોર્ડના નોટિસ બોર્ડ પર દેખાય
      if (widget.targetUID == null) {
        try {
          await AppFirestore.instance.collection('notices').add({
            'title': title,
            'body': body,
            'description': body,
            'category': _selectedCategory,
            'societyId': SocietyService.instance.societyId,
            'createdAt': FieldValue.serverTimestamp(),
            'authorId': FirebaseAuth.instance.currentUser?.uid,
            'authorRole': 'admin',
          });
        } catch (e) {
          debugPrint('Save notice error: $e');
        }
      }

      if (!mounted) return;
      await AdminBroadcastDialogs.sendPushNotification(
        context: context,
        title: title,
        body: body,
        targetUID: widget.targetUID,
        targetName: widget.targetName,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("સૂચના મોકલવામાં ભૂલ: $e"),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAll = widget.targetUID == null;

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
              isAll ? "લાઈવ બ્રોડકાસ્ટ" : "વ્યક્તિગત સૂચના",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              isAll
                  ? "સોસાયટીના તમામ સભ્યોને પુશ નોટિફિકેશન"
                  : "${widget.targetName} ને ડાયરેક્ટ નોટિફિકેશન",
              style: const TextStyle(
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
            // Target Recipient Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAll ? Icons.hub_rounded : Icons.person_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAll ? "પ્રાપ્તકર્તા: તમામ સભ્યો (Broadcasting)" : "પ્રાપ્તકર્તા: ${widget.targetName}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          isAll
                              ? "આ સૂચના તમામ એપ યુઝર્સના ફોન પર તરત વાગશે"
                              : "આ સભ્યના મોબાઈલ પર પુશ એલર્ટ જશે",
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Chips
            const Text(
              "સૂચનાનો વિષય પસંદ કરો:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        c.$3,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                      ),
                      label: Text(c.$1),
                      selected: isSelected,
                      selectedColor: const Color(0xFFF59E0B),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategory = c.$1;
                            _titleC.text = c.$2;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Form Inputs Card
            Container(
              padding: const EdgeInsets.all(20),
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
                  TextField(
                    controller: _titleC,
                    decoration: InputDecoration(
                      labelText: "સૂચનાનું શીર્ષક (Title) *",
                      hintText: "દા.ત. આવતીકાલે સવારે પાણી 7 વાગે આવશે",
                      prefixIcon: const Icon(Icons.title_rounded, size: 20, color: Color(0xFFF59E0B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyC,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "સંપૂર્ણ સંદેશ / વિગત (Message Details) *",
                      hintText: "વિગતવાર માહિતી લખો...",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mobile Notification Live Preview
            const Text(
              "મોબાઈલ પર આ રીતે દેખાશે:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Building Guard",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "હમણાં",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _titleC.text.isEmpty ? "સૂચનાનું શીર્ષક" : _titleC.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _bodyC.text.isEmpty ? "અહીં તમારો સંદેશ દેખાશે..." : _bodyC.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSending ? null : _sendNotification,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "તુરંત પુશ સૂચના મોકલો",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
