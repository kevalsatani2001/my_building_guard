import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/app_firestore.dart';
import '../../services/member_signature_sheet_pdf_service.dart';
import '../../services/society_service.dart';
import '../../widgets/data_animations.dart';
import '../../widgets/premium_app_bar.dart';

/// Screen: એડમિન દ્વારા સભ્ય સહી/સંમતિ પત્રક (Signature & Consent Sheet) તૈયાર અને એક્સપોર્ટ કરવા માટેની સ્ક્રીન
class AdminMemberSignatureSheetScreen extends StatefulWidget {
  const AdminMemberSignatureSheetScreen({super.key});

  @override
  State<AdminMemberSignatureSheetScreen> createState() =>
      _AdminMemberSignatureSheetScreenState();
}

class _AdminMemberSignatureSheetScreenState
    extends State<AdminMemberSignatureSheetScreen> {
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _resolutionCtrl;
  late final TextEditingController _declarationCtrl;

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
  List<({String icon, String title, String declaration})> get _presets => [
    (
      icon: '🛗',
      title: 'lift_modernization_repairing_approval'.tr,
      declaration: 'hence_we_all_the_members_unanimously'.tr,
    ),
    (
      icon: '📋',
      title: 'general_meeting_agm_resolution_approved'.tr,
      declaration: 'hence_we_all_the_members_ratify'.tr,
    ),
    (
      icon: '📹',
      title: 'cctv_camera_installation_consent'.tr,
      declaration: 'hence_we_the_members_agree_to'.tr,
    ),
    (
      icon: '🏢',
      title: 'society_redevelopment_consent_form'.tr,
      declaration: 'hence_we_members_agree_to_the'.tr,
    ),
    (
      icon: '🎨',
      title: 'society_colorwork_waterproofing_approved'.tr,
      declaration: 'we_the_members_hereby_consent_to'.tr,
    ),
    (
      icon: '☀️',
      title: 'solar_rooftop_panel_plant_installation'.tr,
      declaration: 'hence_we_members_agree_for_installation'.tr,
    ),
    (
      icon: '👮',
      title: 'security_consent_to_new_gate_pass'.tr,
      declaration: 'we_the_members_therefore_agree_to'.tr,
    ),
    (
      icon: '💰',
      title: 'special_maintenance_contribution_approval_form'.tr,
      declaration: 'therefore_we_members_agree_to_deposit'.tr,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final lang = LocalizationService.instance.currentCode;
    final ym = DateFormat('yyyy/MM').format(DateTime.now());

    final defaultPurpose = lang == 'en'
        ? 'General Assembly (AGM) Resolution'
        : lang == 'hi'
            ? 'आम बैठक (AGM) संकल्प स्वीकृति'
            : 'સામાન્ય સભા (AGM) ઠરાવ મંજૂરી';

    final defaultRes = lang == 'en'
        ? 'Res. No. $ym/01'
        : lang == 'hi'
            ? 'प्रस्ताव नं. $ym/01'
            : 'ઠરાવ નં. $ym/૦૧';

    final defaultDecl = lang == 'en'
        ? 'Therefore we all the members of the undersigned Society fully agree with the above subject/resolution and voluntarily sign below.'
        : lang == 'hi'
            ? 'इसलिए हम अधोहस्ताक्षरी सोसायटी के सभी सदस्य उपरोक्त विषय/संकल्प से पूरी तरह सहमत हैं और स्वेच्छा से नीचे हस्ताक्षर करते हैं।'
            : 'આથી અમે નીચે સહી કરનાર સોસાયટીના તમામ સભ્યો ઉપરોક્ત વિષય/ઠરાવ સાથે સંપૂર્ણ સંમત છીએ અને અમારી સ્વેચ્છાએ નીચે સહી કરીએ છીએ.';

    _purposeCtrl = TextEditingController(text: defaultPurpose);
    _resolutionCtrl = TextEditingController(text: defaultRes);
    _declarationCtrl = TextEditingController(text: defaultDecl);

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
            memberName: 'empty_unit'.tr,
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
        SnackBar(
          content: Text('no_members_or_flats_found_in'.tr),
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
        title: 'screen_member_signature_generator'.tr,
        subtitle: 'sub_member_signature_generator'.tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
            tooltip: 'refresh_data'.tr,
            onPressed: _fetchSocietyStructureAndMembers,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoadingData
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 14),
                  Text('loading_society_members_and_flats'.tr),
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
                              Text(
                                'official_member_signature_register'.tr,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: Color(0xFF1E3A8A), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'txt_1_purpose_of_signature'.tr,
                              style: const TextStyle(
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
                            labelText: 'name_of_subject_purpose'.tr,
                            hintText: 'eg_lift_repairing_approval_agm_resolution'.tr,
                            prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF1E3A8A), size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Suggestion Chips (ઝડપી પસંદગી)
                        Text(
                          'common_reasons_used_frequently_onetap_select'.tr,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, color: Color(0xFF1E3A8A), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'txt_2_sheet_settings_wing_selection'.tr,
                              style: const TextStyle(
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
                                  labelText: 'resolution_reference_no'.tr,
                                  hintText: 'eg_202601'.tr,
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
                        Text(
                          'select_wing_block'.tr,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
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
                                    ? 'all_units'.tr
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
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'declaration_text'.tr,
                            hintText: 'conditions_of_consent_printed_on_the'.tr,
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
                          title: Text('also_display_unoccupied_units'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('including_vacant_units_to_keep_all'.tr, style: const TextStyle(fontSize: 11)),
                          value: _includeUnoccupied,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: (v) => setState(() => _includeUnoccupied = v),
                        ),
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('include_a_consentcomment_box_column'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('member_may_mark_agreement_with_signature'.tr, style: const TextStyle(fontSize: 11)),
                          value: _includeRemarks,
                          activeTrackColor: const Color(0xFF1E3A8A),
                          onChanged: (v) => setState(() => _includeRemarks = v),
                        ),
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('include_the_mobile_number_column'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('phone_number_for_member_verification'.tr, style: const TextStyle(fontSize: 11)),
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
                              "${'total_included_units'.tr}: ${records.length}",
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                          ],
                        ),
                        Text(
                          _selectedWing == 'ALL'
                              ? 'all_the_wings'.tr
                              : SocietyService.instance.formatBlockDisplayName(_selectedWing),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🚀 5. Action Buttons (Preview, Direct Print, Share)
                  InteractiveBounce(
                    onTap: _openPdfPreview,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'pdf_preview_export_preview_pdf'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'sub_member_signature_generator'.tr,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: InteractiveBounce(
                          onTap: _directPrint,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.print_rounded,
                                    color: Color(0xFF1E3A8A),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'print'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InteractiveBounce(
                          onTap: _directShare,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.share_rounded,
                                    color: Color(0xFF059669),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'share_whatsapp'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
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
        title: 'member_signature_sheet_preview'.tr,
        subtitle: "$societyName ($selectedWing)",
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A)),
            tooltip: 'print'.tr,
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
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              SizedBox(height: 12),
              Text(
                "સહી પત્રક PDF જનરેટ થઈ રહ્યું છે...".tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
