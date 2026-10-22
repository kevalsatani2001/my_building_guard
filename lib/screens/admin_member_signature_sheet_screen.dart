import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../core/app_firestore.dart';
import '../services/member_signature_sheet_pdf_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

/// Screen: એડમિન દ્વારા સભ્ય સહી/સંમતિ પત્રક (Signature & Consent Sheet) તૈયાર અને એક્સપોર્ટ કરવા માટેની સ્ક્રીન
class AdminMemberSignatureSheetScreen extends StatefulWidget {
  const AdminMemberSignatureSheetScreen({super.key});

  @override
  State<AdminMemberSignatureSheetScreen> createState() =>
      _AdminMemberSignatureSheetScreenState();
}

class _AdminMemberSignatureSheetScreenState
    extends State<AdminMemberSignatureSheetScreen> {
  final _purposeCtrl = TextEditingController(text: 'સામાન્ય સભા ઠરાવ મંજૂરી');
  final _resolutionCtrl = TextEditingController(
      text: 'ઠરાવ નં. ${DateFormat('yyyy/MM').format(DateTime.now())}/૦૧');
  final _declarationCtrl = TextEditingController(
    text:
        'આથી અમે નીચે સહી કરનાર સોસાયટીના તમામ સભ્યો ઉપરોક્ત વિષય/ઠરાવ સાથે સંપૂર્ણ સંમત છીએ અને અમારી સ્વેચ્છાએ નીચે સહી કરીએ છીએ.',
  );

  DateTime _selectedDate = DateTime.now();
  String _selectedWing = 'ALL';
  bool _includeUnoccupied = true;
  bool _includeContact = true;
  bool _includeRemarks = true;
  bool _isLoadingData = true;

  List<String> _availableWings = ['ALL'];
  List<Map<String, dynamic>> _rawUnits = [];
  List<Map<String, dynamic>> _rawMembers = [];

  // Quick Preset Reasons (સામાન્ય સોસાયટી કારણો)
  final List<({String icon, String title, String declaration})> _presets = [
    (
      icon: '🛗',
      title: 'લિફ્ટ મોડર્નાઇઝેશન / રીપેરીંગ મંજૂરી',
      declaration:
          'આથી સોસાયટીની લિફ્ટ રીપેરીંગ/AMC રીન્યુઅલ અને મોડર્નાઇઝેશનના ખર્ચ બાબતે અમે તમામ સભ્યો સર્વાનુમતે સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '📋',
      title: 'સામાન્ય સભા (AGM) ઠરાવ મંજૂરી',
      declaration:
          'આથી સોસાયટીની સામાન્ય વાર્ષિક સભામાં પસાર કરાયેલ ઉપરોક્ત ઠરાવને અમે તમામ સભ્યો બહાલી આપીએ છીએ.',
    ),
    (
      icon: '📹',
      title: 'સીસીટીવી કેમેરા ઇન્સ્ટોલેશન સંમતિ',
      declaration:
          'આથી સોસાયટી પરિસરની સુરક્ષા માટે નવા સીસીટીવી કેમેરા સિસ્ટમ ઇન્સ્ટોલ કરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '🏢',
      title: 'સોસાયટી રિડેવલપમેન્ટ સંમતિ પત્રક',
      declaration:
          'આથી સોસાયટીના રિડેવલપમેન્ટ પ્રક્રિયા અને કમિટી દ્વારા આગળની કાર્યવાહી હાથ ધરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '🎨',
      title: 'સોસાયટી કલરકામ & વોટરપ્રૂફિંગ મંજૂરી',
      declaration:
          'આથી સોસાયટીની બિલ્ડિંગના બાહ્ય કલરકામ અને ટેરેસ વોટરપ્રૂફિંગ કાર્ય હાથ ધરવા માટે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '☀️',
      title: 'સોલાર રૂફટોપ પેનલ પ્લાન્ટ ઇન્સ્ટોલેશન',
      declaration:
          'આથી કોમન લાઈટિંગ અને લિફ્ટ માટે સોલાર રૂફટોપ સિસ્ટમ બેસાડવા તથા સબસિડી પ્રક્રિયા માટે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '👮',
      title: 'સિક્યોરિટી & નવા ગેટ પાસ નિયમો સંમતિ',
      declaration:
          'આથી સોસાયટીમાં મુલાકાતીઓ (વિઝિટર્સ) અને વાહનો માટેના નવા સુરક્ષા નિયમોનું પાલન કરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
    (
      icon: '💰',
      title: 'વિશેષ મેન્ટેનન્સ / ફાળો મંજૂરી પત્રક',
      declaration:
          'આથી ઉપરોક્ત કામગીરી પેટે નક્કી કરેલ વિશેષ ફાળો નિયત સમયમાં જમા કરાવવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSocietyStructureAndMembers();
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _resolutionCtrl.dispose();
    _declarationCtrl.dispose();
    super.dispose();
  }

  /// સોસાયટીના એકમો (units) અને સભ્યો (users) લાવીને વિંગ લિસ્ટ બનાવવું
  Future<void> _fetchSocietyStructureAndMembers() async {
    setState(() => _isLoadingData = true);
    final sid = SocietyService.instance.societyId;

    try {
      // ૧. બ્લોક્સ/વિંગ્સ ક્વેરી
      final blocksSnap = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: sid)
          .get();

      final Set<String> wingSet = {};
      for (final doc in blocksSnap.docs) {
        final d = doc.data();
        final rawName = (d['name'] ?? doc.id).toString();
        final cleanName = SocietyService.instance.normalizeBlockName(rawName);
        if (cleanName.isNotEmpty) wingSet.add(cleanName);
      }

      // ૨. યુનિટ્સ ક્વેરી
      final unitsSnap = await AppFirestore.instance
          .collection('units')
          .where('societyId', isEqualTo: sid)
          .get();

      final List<Map<String, dynamic>> uList = [];
      for (final doc in unitsSnap.docs) {
        final d = doc.data();
        final bName = SocietyService.instance.normalizeBlockName(
            (d['blockName'] ?? d['blockId'] ?? '').toString());
        if (bName.isNotEmpty) wingSet.add(bName);
        uList.add({
          'id': doc.id,
          'blockName': bName,
          'unitNumber': (d['unitNumber'] ?? '').toString(),
          'unitType': (d['unitType'] ?? 'flat').toString(),
          'isOccupied': d['isOccupied'] == true,
          'memberId': (d['memberId'] ?? '').toString(),
        });
      }

      // ૩. રજીસ્ટર્ડ સભ્યો ક્વેરી
      final usersSnap = await AppFirestore.instance
          .collection('users')
          .where('societyId', isEqualTo: sid)
          .where('role', isEqualTo: 'member')
          .get();

      final List<Map<String, dynamic>> mList = [];
      for (final doc in usersSnap.docs) {
        final d = doc.data();
        final bName = SocietyService.instance.normalizeBlockName(
            (d['blockName'] ?? d['block'] ?? '').toString());
        if (bName.isNotEmpty) wingSet.add(bName);
        mList.add({
          'uid': doc.id,
          'name': (d['name'] ?? '').toString().trim(),
          'phone': (d['displayPhone'] ?? d['phone'] ?? '').toString().trim(),
          'blockName': bName,
          'unitNumber': (d['unitNumber'] ?? d['flatNumber'] ?? '').toString().trim(),
        });
      }

      final sortedWings = wingSet.toList()
        ..sort((a, b) {
          if (a == 'G') return -1;
          if (b == 'G') return 1;
          return a.compareTo(b);
        });
      setState(() {
        _availableWings = ['ALL', ...sortedWings];
        _rawUnits = uList;
        _rawMembers = mList;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint("Error fetching society units/members: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  /// વર્તમાન ફિલ્ટર મુજબ પ્રિન્ટ માટે સભ્યોનું લિસ્ટ ફિલ્ટર કરવું
  List<MemberSignatureRecord> _buildRecordList() {
    final Map<String, Map<String, dynamic>> memberByUnit = {};
    for (final m in _rawMembers) {
      final b = m['blockName'].toString();
      final u = m['unitNumber'].toString();
      if (b.isNotEmpty && u.isNotEmpty) {
        memberByUnit['$b-$u'] = m;
      }
    }

    final List<MemberSignatureRecord> records = [];

    // જો units હાજર હોય તો units આધારિત ક્રમબદ્ધ લિસ્ટ બનાવવું
    if (_rawUnits.isNotEmpty) {
      // Sort units by block then unit number naturally
      final sorted = List<Map<String, dynamic>>.from(_rawUnits);
      sorted.sort((a, b) {
        final blockComp = (a['blockName'] ?? '').compareTo(b['blockName'] ?? '');
        if (blockComp != 0) return blockComp;
        final uA = int.tryParse(a['unitNumber'] ?? '') ?? 0;
        final uB = int.tryParse(b['unitNumber'] ?? '') ?? 0;
        if (uA != 0 && uB != 0) return uA.compareTo(uB);
        return (a['unitNumber'] ?? '').compareTo(b['unitNumber'] ?? '');
      });

      int sr = 1;
      for (final u in sorted) {
        final b = u['blockName'].toString();
        final uNum = u['unitNumber'].toString();

        // વિંગ ફિલ્ટર
        if (_selectedWing != 'ALL' && b != _selectedWing) continue;

        final matchedMember = memberByUnit['$b-$uNum'];
        if (matchedMember != null) {
          records.add(MemberSignatureRecord(
            srNo: sr++,
            wingOrBlock: b.isNotEmpty ? b : '-',
            unitNumber: uNum.isNotEmpty ? uNum : '-',
            memberName: matchedMember['name'] ?? '-',
            phone: matchedMember['phone'] ?? '-',
            unitType: u['unitType'] ?? 'flat',
            isOccupied: true,
          ));
        } else if (_includeUnoccupied) {
          records.add(MemberSignatureRecord(
            srNo: sr++,
            wingOrBlock: b.isNotEmpty ? b : '-',
            unitNumber: uNum.isNotEmpty ? uNum : '-',
            memberName: '— (ખાલી એકમ) —',
            phone: '—',
            unitType: u['unitType'] ?? 'flat',
            isOccupied: false,
          ));
        }
      }
    } else {
      // જો units કલેક્શન ન હોય તો માત્ર રજીસ્ટર્ડ સભ્યોમાંથી લિસ્ટ બનાવવું
      int sr = 1;
      for (final m in _rawMembers) {
        final b = m['blockName'].toString();
        if (_selectedWing != 'ALL' && b != _selectedWing) continue;
        records.add(MemberSignatureRecord(
          srNo: sr++,
          wingOrBlock: b.isNotEmpty ? b : '-',
          unitNumber: m['unitNumber'].toString().isNotEmpty ? m['unitNumber'] : '-',
          memberName: m['name'] ?? '-',
          phone: m['phone'] ?? '-',
          isOccupied: true,
        ));
      }
    }

    return records;
  }

  Future<void> _openPdfPreview() async {
    final records = _buildRecordList();
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("પસંદ કરેલ વિંગમાં કોઈ સભ્યો કે ફ્લેટ્સ મળ્યા નથી!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final socName = SocietyService.instance.societyName;
    const city = '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberSignaturePdfPreviewScreen(
          societyName: socName,
          city: city,
          purposeTitle: _purposeCtrl.text.trim(),
          resolutionNumber: _resolutionCtrl.text.trim(),
          purposeDescription: _declarationCtrl.text.trim(),
          eventDate: _selectedDate,
          selectedWing: _selectedWing,
          members: records,
          includeRemarksColumn: _includeRemarks,
          includeContactColumn: _includeContact,
        ),
      ),
    );
  }

  Future<void> _directPrint() async {
    final records = _buildRecordList();
    if (records.isEmpty) return;

    final bytes = await MemberSignatureSheetPdfService.generateSignatureSheetPdf(
      societyName: SocietyService.instance.societyName,
      city: '',
      purposeTitle: _purposeCtrl.text.trim(),
      resolutionNumber: _resolutionCtrl.text.trim(),
      purposeDescription: _declarationCtrl.text.trim(),
      eventDate: _selectedDate,
      selectedWing: _selectedWing,
      members: records,
      includeRemarksColumn: _includeRemarks,
      includeContactColumn: _includeContact,
    );
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> _directShare() async {
    final records = _buildRecordList();
    if (records.isEmpty) return;

    final bytes = await MemberSignatureSheetPdfService.generateSignatureSheetPdf(
      societyName: SocietyService.instance.societyName,
      city: '',
      purposeTitle: _purposeCtrl.text.trim(),
      resolutionNumber: _resolutionCtrl.text.trim(),
      purposeDescription: _declarationCtrl.text.trim(),
      eventDate: _selectedDate,
      selectedWing: _selectedWing,
      members: records,
      includeRemarksColumn: _includeRemarks,
      includeContactColumn: _includeContact,
    );

    final cleanTitle = _purposeCtrl.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final filename =
        'Signature_Sheet_${cleanTitle.isNotEmpty ? cleanTitle : 'Register'}_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  @override
  Widget build(BuildContext context) {
    final records = _buildRecordList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: "સભ્ય સહી પત્રક જનરેટર",
        subtitle: "વિષય & સહી કોલમ સાથે વિંગ-વાઇઝ PDF એક્સપોર્ટ",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
            tooltip: "રીફ્રેશ ડેટા",
            onPressed: _fetchSocietyStructureAndMembers,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  SizedBox(height: 14),
                  Text("સોસાયટી સભ્યો અને ફ્લેટ્સ લોડ થઈ રહ્યા છે..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 1. Header Banner & Premise Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.draw_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SocietyService.instance.societyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "સત્તાવાર સભ્ય સહી & સંમતિ રજીસ્ટર (Official Member Signature Register)",
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📝 2. Purpose / Reason Selection Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "૧. સહી લેવાનું કારણ / ઠરાવ વિષય (Purpose)",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _purposeCtrl,
                          decoration: InputDecoration(
                            labelText: "વિષય / હેતુનું નામ *",
                            hintText: "દા.ત. લિફ્ટ રીપેરીંગ મંજૂરી / AGM ઠરાવ",
                            prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF1E3A8A), size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Suggestion Chips (ઝડપી પસંદગી)
                        const Text(
                          "વારંવાર વપરાતા સામાન્ય કારણો (વન-ટેપ સિલેક્ટ):",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presets.map((p) {
                            final isSel = _purposeCtrl.text == p.title;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _purposeCtrl.text = p.title;
                                  _declarationCtrl.text = p.declaration;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p.icon, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 5),
                                    Text(
                                      p.title,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ⚙️ 3. Settings & Filters Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Color(0xFF1E3A8A), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "૨. પત્રક સેટિંગ્સ & વિંગ પસંદગી",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Resolution / Ref Number & Date Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _resolutionCtrl,
                                decoration: InputDecoration(
                                  labelText: "ઠરાવ / સંદર્ભ નં.",
                                  hintText: "દા.ત. ૨૦૨૬/૦૧",
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF1E3A8A)),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Wing Selector
                        const Text(
                          "વિંગ / બ્લોક પસંદ કરો:",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableWings.map((w) {
                            final isSel = _selectedWing == w;
                            return ChoiceChip(
                              label: Text(
                                w == 'ALL'
                                    ? 'તમામ એકમો (All)'
                                    : SocietyService.instance.formatBlockDisplayName(w),
                                style: TextStyle(
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF1E3A8A),
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (_) => setState(() => _selectedWing = w),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Detailed Declaration Note
                        TextField(
                          controller: _declarationCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: "જાહેરનામું / સંમતિ નોંધ (Declaration Text)",
                            hintText: "સહી પત્રક ઉપર છપાતી સંમતિની શરતો...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Column Options Switches
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text("ખાલી એકમો (Unoccupied) પણ દર્શાવો", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text("તમામ ફ્લેટ ક્રમબદ્ધ રહે તે માટે ખાલી એકમો સહિત", style: TextStyle(fontSize: 11)),
                          value: _includeUnoccupied,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: (v) => setState(() => _includeUnoccupied = v),
                        ),
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text("સંમતિ / મંતવ્ય બોક્સ કોલમ સમાવો", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text("સભ્ય સહી સાથે [✓] સંમત માર્કિંગ કરી શકે", style: TextStyle(fontSize: 11)),
                          value: _includeRemarks,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: (v) => setState(() => _includeRemarks = v),
                        ),
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text("મોબાઈલ નંબર કોલમ સમાવો", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text("સભ્યના વેરિફિકેશન માટે ફોન નંબર", style: TextStyle(fontSize: 11)),
                          value: _includeContact,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: (v) => setState(() => _includeContact = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 👥 4. Live Preview Stats Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: Color(0xFF1D4ED8), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "કુલ સમાવિષ્ટ સભ્યો/યુનિટ્સ: ${records.length}",
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                          ],
                        ),
                        Text(
                          _selectedWing == 'ALL' ? 'બધી વિંગ્સ' : 'વિંગ: $_selectedWing',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🚀 5. Action Buttons (Preview, Direct Print, Share)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openPdfPreview,
                      icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "📄 પીડીએફ પ્રિવ્યૂ & એક્સપોર્ટ (Preview PDF)",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _directPrint,
                            icon: const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A), size: 18),
                            label: const Text(
                              "પ્રિન્ટ (Print)",
                              style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _directShare,
                            icon: const Icon(Icons.share_rounded, color: Color(0xFF059669), size: 18),
                            label: const Text(
                              "શેર (WhatsApp)",
                              style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF059669)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

/// Preview Screen using native interactive PdfPreview widget
class MemberSignaturePdfPreviewScreen extends StatelessWidget {
  final String societyName;
  final String city;
  final String purposeTitle;
  final String resolutionNumber;
  final String purposeDescription;
  final DateTime eventDate;
  final String selectedWing;
  final List<MemberSignatureRecord> members;
  final bool includeRemarksColumn;
  final bool includeContactColumn;

  const MemberSignaturePdfPreviewScreen({
    super.key,
    required this.societyName,
    required this.city,
    required this.purposeTitle,
    required this.resolutionNumber,
    required this.purposeDescription,
    required this.eventDate,
    required this.selectedWing,
    required this.members,
    required this.includeRemarksColumn,
    required this.includeContactColumn,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyyMMdd').format(eventDate);
    final wingPart = selectedWing != 'ALL' ? '_Wing_$selectedWing' : '';
    final filename = 'Member_Signature_Sheet${wingPart}_$dateStr.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PremiumAppBar(
        title: "સભ્ય સહી પત્રક પ્રિવ્યૂ",
        subtitle: "$societyName ($selectedWing)",
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A)),
            tooltip: "પ્રિન્ટ કરો",
            onPressed: () async {
              final pdfBytes = await MemberSignatureSheetPdfService.generateSignatureSheetPdf(
                societyName: societyName,
                city: city,
                purposeTitle: purposeTitle,
                resolutionNumber: resolutionNumber,
                purposeDescription: purposeDescription,
                eventDate: eventDate,
                selectedWing: selectedWing,
                members: members,
                includeRemarksColumn: includeRemarksColumn,
                includeContactColumn: includeContactColumn,
              );
              await Printing.layoutPdf(onLayout: (_) => pdfBytes);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        build: (format) => MemberSignatureSheetPdfService.generateSignatureSheetPdf(
          societyName: societyName,
          city: city,
          purposeTitle: purposeTitle,
          resolutionNumber: resolutionNumber,
          purposeDescription: purposeDescription,
          eventDate: eventDate,
          selectedWing: selectedWing,
          members: members,
          includeRemarksColumn: includeRemarksColumn,
          includeContactColumn: includeContactColumn,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: filename,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              SizedBox(height: 12),
              Text(
                "સહી પત્રક PDF જનરેટ થઈ રહ્યું છે...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
