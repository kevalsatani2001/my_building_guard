import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/society_service.dart';
import '../widgets/admin_broadcast_dialogs.dart';

class AdminPublishNoticeScreen extends StatefulWidget {
  const AdminPublishNoticeScreen({super.key});

  @override
  State<AdminPublishNoticeScreen> createState() => _AdminPublishNoticeScreenState();
}

class _AdminPublishNoticeScreenState extends State<AdminPublishNoticeScreen> {
  final _titleC = TextEditingController();
  final _bodyC = TextEditingController();

  String _selectedCategory = 'સામાન્ય';
  bool _isUrgent = false;
  bool _isPinned = true;
  bool _sendPushAlert = true;
  bool _isPublishing = false;

  final List<(String, String, IconData, Color)> _categories = [
    ('સામાન્ય', 'સામાન્ય સૂચના', Icons.campaign_rounded, Colors.orange),
    ('પાણી', 'પાણી પુરવઠા સમય', Icons.water_drop_rounded, Colors.blue),
    ('લાઈટ', 'વીજળી / જનરેટર', Icons.bolt_rounded, Colors.amber),
    ('મીટિંગ', 'વાર્ષિક / માસિક મીટિંગ', Icons.groups_rounded, Colors.indigo),
    ('ઉત્સવ', 'તહેવાર / ઇવેન્ટ આયોજન', Icons.celebration_rounded, Colors.purple),
    ('સફાઈ', 'સોસાયટી સ્વચ્છતા અભિયાન', Icons.cleaning_services_rounded, Colors.teal),
  ];

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  Future<void> _publishNotice() async {
    final title = _titleC.text.trim();
    final body = _bodyC.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને શીર્ષક અને વિગત બંને ભરો."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final sid = SocietyService.instance.societyId;
      await AppFirestore.instance.collection('notices').add({
        'title': title,
        'body': body,
        'category': _selectedCategory,
        'isUrgent': _isUrgent,
        'isPinned': _isPinned,
        'societyId': sid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_sendPushAlert && mounted) {
        await AdminBroadcastDialogs.sendPushNotification(
          context: context,
          title: "📢 નવી નોટિસ: $title",
          body: body,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text("નોટિસ બોર્ડ પર સફળતાપૂર્વક પબ્લિશ થઈ ગઈ!"),
            ],
          ),
          backgroundColor: Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("નોટિસ પબ્લિશ કરવામાં ભૂલ: $e"),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
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
              "ડિજિટલ નોટિસ બોર્ડ",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "સોસાયટી પરિપત્ર અને સભાઓની જાહેરાત",
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
            // Category Chips
            const Text(
              "નોટિસ પ્રકાર / કેટેગરી:",
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
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        c.$3,
                        size: 16,
                        color: isSelected ? Colors.white : c.$4,
                      ),
                      label: Text(c.$1),
                      selected: isSelected,
                      selectedColor: const Color(0xFFEA580C),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategory = c.$1;
                            if (_titleC.text.isEmpty) _titleC.text = c.$2;
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
                      labelText: "નોટિસનું શીર્ષક (Title) *",
                      hintText: "દા.ત. સોસાયટી સામાન્ય વાર્ષિક સભા",
                      prefixIcon: const Icon(Icons.article_rounded, size: 20, color: Color(0xFFEA580C)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyC,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "નોટિસની સંપૂર્ણ વિગતો (Notice Content) *",
                      hintText: "તારીખ, સમય, એજન્ડા અથવા નિયમો લખો...",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Switches Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "તાત્કાલિક / અર્જન્ટ નોટિસ (Urgent)",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: const Text(
                      "લાલ રંગના એલર્ટ બેજ સાથે હાઇલાઇટ થશે",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _isUrgent,
                    activeThumbColor: Colors.red,
                    onChanged: (v) => setState(() => _isUrgent = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "ટોચ પર પિન કરો (Pin to Top)",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: const Text(
                      "નોટિસ બોર્ડમાં સૌથી ઉપર દેખાશે",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _isPinned,
                    activeThumbColor: const Color(0xFFEA580C),
                    onChanged: (v) => setState(() => _isPinned = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "તમામને તુરંત પુશ નોટિફિકેશન મોકલો",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: const Text(
                      "નોટિસ પબ્લિશ થતા જ બધા સભ્યોના ફોનમાં એલર્ટ વાગશે",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _sendPushAlert,
                    activeThumbColor: const Color(0xFF047857),
                    onChanged: (v) => setState(() => _sendPushAlert = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Notice Board Preview
            const Text(
              "નોટિસ બોર્ડ પ્રિવ્યુ:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFFED7AA),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isUrgent ? Colors.red : Colors.orange).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isUrgent ? "🔴 અર્જન્ટ નોટિસ" : "📢 $_selectedCategory",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _isUrgent ? Colors.red.shade800 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                      if (_isPinned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "📌 પિન કરેલ",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Text(
                        "આજે",
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _titleC.text.isEmpty ? "નોટિસનું શીર્ષક" : _titleC.text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _bodyC.text.isEmpty ? "અહીં નોટિસની વિગતો દેખાશે..." : _bodyC.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isPublishing ? null : _publishNotice,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.publish_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "નોટિસ પબ્લિશ કરો",
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
