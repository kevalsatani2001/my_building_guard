import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';
import '../services/society_service.dart';
import '../widgets/admin_broadcast_dialogs.dart';
import '../widgets/premium_app_bar.dart';

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
  String _targetBlock = 'ALL';
  List<String> _availableBlocks = [];
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
    _loadBlocks();
    _loadCustomCategories();
  }

  Future<void> _loadBlocks() async {
    try {
      final snap = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .get();
      final blocks = <String>{};
      for (final doc in snap.docs) {
        final raw = (doc.data()['name'] ?? '').toString();
        final clean = SocietyService.instance.logicalBlockName(raw);
        if (clean.isNotEmpty) blocks.add(clean);
      }
      final sorted = blocks.toList()..sort();
      if (mounted) {
        setState(() {
          _availableBlocks = sorted;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCustomCategories() async {
    try {
      final sid = SocietyService.instance.societyId;
      final doc = await AppFirestore.instance.collection('society_settings').doc(sid).get();
      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['customBroadcastCategories'];
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              final cat = (item['category'] ?? '').toString().trim();
              final defaultTitle = (item['title'] ?? '').toString().trim();
              if (cat.isNotEmpty && !_categories.any((c) => c.$1 == cat)) {
                _categories.add((cat, defaultTitle.isNotEmpty ? defaultTitle : cat, Icons.label_important_rounded));
              }
            }
          }
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _showAddCategoryDialog() async {
    final catController = TextEditingController();
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('નવી મેસેજ કેટેગરી ઉમેરો', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: catController,
              decoration: const InputDecoration(
                labelText: 'કેટેગરી નામ *',
                hintText: 'દા.ત. લિફ્ટ, સિક્યોરિટી, પાર્કિંગ, વગેરે',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'ડિફૉલ્ટ શીર્ષક (વૈકલ્પિક)',
                hintText: 'દા.ત. લિફ્ટ મેઇન્ટેનન્સ જરૂરી સૂચના',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('રદ કરો'),
          ),
          FilledButton(
            onPressed: () {
              if (catController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('ઉમેરો'),
          ),
        ],
      ),
    );

    if (result == true && catController.text.trim().isNotEmpty) {
      final newCat = catController.text.trim();
      final newTitle = titleController.text.trim().isNotEmpty
          ? titleController.text.trim()
          : 'સોસાયટી $newCat સૂચના';

      setState(() {
        if (!_categories.any((c) => c.$1 == newCat)) {
          _categories.add((newCat, newTitle, Icons.label_important_rounded));
        }
        _selectedCategory = newCat;
        _titleC.text = newTitle;
      });

      try {
        final sid = SocietyService.instance.societyId;
        await AppFirestore.instance.collection('society_settings').doc(sid).set({
          'customBroadcastCategories': FieldValue.arrayUnion([
            {'category': newCat, 'title': newTitle}
          ])
        }, SetOptions(merge: true));
      } catch (_) {}
    }
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
            'targetBlock': _targetBlock == 'ALL' ? null : _targetBlock,
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
        targetBlock: _targetBlock,
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
      appBar: PremiumAppBar(
        title: isAll ? "લાઈવ બ્રોડકાસ્ટ" : "વ્યક્તિગત સૂચના",
        subtitle: isAll
            ? "સોસાયટીના તમામ સભ્યોને પુશ નોટિફિકેશન"
            : "${widget.targetName} ને ડાયરેક્ટ નોટિફિકેશન",
        icon: Icons.campaign_rounded,
        accentColor: const Color(0xFFF59E0B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D Hero Banner for Broadcast
            Container(
              width: double.infinity,
              height: 155,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/broadcast_hero.jpg',
                      width: double.infinity,
                      height: 155,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 155,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                                      Icon(Icons.notifications_active_rounded, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'ઈન્સ્ટન્ટ બ્રોડકાસ્ટ',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  isAll ? "સોસાયટી બ્રોડકાસ્ટ" : "ડાયરેક્ટ એલર્ટ",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAll
                                      ? "તમામ સભ્યોના મોબાઇલ પર તાત્કાલિક સાઉન્ડ સાથે પુશ નોટિસ પહોંચશે."
                                      : "${widget.targetName} ને તાત્કાલિક સૂચના પહોંચાડવામાં આવશે.",
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
                            child: SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            if (isAll && _availableBlocks.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "લક્ષ્ય પરિસર / વિંગ (Target Audience):",
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
                  children: [
                    ChoiceChip(
                      avatar: Icon(
                        Icons.domain_rounded,
                        size: 15,
                        color: _targetBlock == 'ALL' ? Colors.white : const Color(0xFFF59E0B),
                      ),
                      label: const Text('સમગ્ર પરિસર (All)'),
                      selected: _targetBlock == 'ALL',
                      selectedColor: const Color(0xFFF59E0B),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _targetBlock == 'ALL' ? Colors.white : const Color(0xFF334155),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _targetBlock = 'ALL');
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._availableBlocks.map((b) {
                      final isSelected = _targetBlock == b;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.apartment_rounded,
                            size: 15,
                            color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                          ),
                          label: Text('${SocietyService.instance.vocabulary.blockShortLabel} $b'),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF59E0B),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _targetBlock = b);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
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
                children: [
                  ..._categories.map((c) {
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
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFF59E0B)),
                      label: const Text('+ નવી કેટેગરી', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E))),
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      onPressed: _showAddCategoryDialog,
                    ),
                  ),
                ],
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
