import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import 'architecture_preview.dart';

/// Ultra-Premium, World-Class Universal Premise Setup Wizard
/// Designed with Apple/Linear aesthetic, 3D Hero integration, visual property cards,
/// live blueprint preview, and zero-overflow responsive controls.
class AdminSetupWizardScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  final String? initialSocietyName;
  final String? initialArchitectureType;

  const AdminSetupWizardScreen({
    super.key,
    required this.onSetupComplete,
    this.initialSocietyName,
    this.initialArchitectureType,
  });

  @override
  State<AdminSetupWizardScreen> createState() => _AdminSetupWizardScreenState();
}

class _AdminSetupWizardScreenState extends State<AdminSetupWizardScreen> {
  final TextEditingController _sNameC = TextEditingController();

  // Commercial controllers
  int _commercialModeIndex = 0; // 0: Single Floor, 1: Multi-Floor Range
  final TextEditingController _cSingleFloorNameC = TextEditingController(text: 'G');
  final TextEditingController _cSingleUnitsCountC = TextEditingController();
  final TextEditingController _cSingleAreaC = TextEditingController(text: '350');
  String _cSingleUnitType = 'shop';

  final TextEditingController _cRangeBlockNameC = TextEditingController();
  final TextEditingController _cRangeFromFloorC = TextEditingController(text: '2');
  final TextEditingController _cRangeToFloorC = TextEditingController(text: '10');
  final TextEditingController _cRangeUnitsPerFloorC = TextEditingController();
  final TextEditingController _cRangeAreaC = TextEditingController(text: '500');
  String _cRangeUnitType = 'office';

  // Mixed controllers
  int _mixedCategoryIndex = 0; // 0: Commercial Shops, 1: Residential Wing
  final TextEditingController _mCommNameC = TextEditingController(text: 'G');
  final TextEditingController _mCommUnitsCountC = TextEditingController();
  final TextEditingController _mCommAreaC = TextEditingController(text: '350');

  final TextEditingController _mResWingNameC = TextEditingController(text: 'A');
  final TextEditingController _mResFloorsC = TextEditingController();
  final TextEditingController _mResUnitsPerFloorC = TextEditingController();
  final TextEditingController _mResAreaC = TextEditingController(text: '1000');

  // Wing controllers
  final TextEditingController _wNameC = TextEditingController(text: 'A');
  final TextEditingController _wFloorsC = TextEditingController();
  final TextEditingController _wUnitsPerFloorC = TextEditingController();
  final TextEditingController _wAreaC = TextEditingController(text: '1000');

  // Street controllers
  final TextEditingController _sStreetNameC = TextEditingController(text: '1');
  final TextEditingController _sStartUnitC = TextEditingController(text: '1');
  final TextEditingController _sEndUnitC = TextEditingController();
  final TextEditingController _sAreaC = TextEditingController(text: '1200');

  final List<Map<String, dynamic>> _tempBlocks = [];
  String _wizardType = 'Commercial';
  bool _isLoading = false;
  bool _hasSavedArchitecture = false;

  bool get _isArchitectureLocked => _tempBlocks.isNotEmpty || _hasSavedArchitecture;

  @override
  void initState() {
    super.initState();

    final initialName = widget.initialSocietyName ?? SocietyService.instance.societyName;
    if (initialName.isNotEmpty && initialName != 'માય સોસાયટી (My Society)') {
      _sNameC.text = initialName;
    }
    final initialArch = widget.initialArchitectureType ?? SocietyService.instance.architectureType;
    if (initialArch.isNotEmpty && ['Commercial', 'Mixed', 'Wing', 'Street'].contains(initialArch)) {
      _wizardType = initialArch;
    }

    _loadRemoteSocietyDetails();

    void updatePreview() {
      if (mounted) setState(() {});
    }

    _cSingleFloorNameC.addListener(updatePreview);
    _cSingleUnitsCountC.addListener(updatePreview);
    _cSingleAreaC.addListener(updatePreview);
    _cRangeFromFloorC.addListener(updatePreview);
    _cRangeToFloorC.addListener(updatePreview);
    _cRangeUnitsPerFloorC.addListener(updatePreview);
    _cRangeAreaC.addListener(updatePreview);
    _mCommNameC.addListener(updatePreview);
    _mCommUnitsCountC.addListener(updatePreview);
    _mCommAreaC.addListener(updatePreview);
    _mResWingNameC.addListener(updatePreview);
    _mResFloorsC.addListener(updatePreview);
    _mResUnitsPerFloorC.addListener(updatePreview);
    _mResAreaC.addListener(updatePreview);
    _wNameC.addListener(updatePreview);
    _wFloorsC.addListener(updatePreview);
    _wUnitsPerFloorC.addListener(updatePreview);
    _wAreaC.addListener(updatePreview);
    _sStreetNameC.addListener(updatePreview);
    _sStartUnitC.addListener(updatePreview);
    _sEndUnitC.addListener(updatePreview);
    _sAreaC.addListener(updatePreview);
  }

  @override
  void dispose() {
    _sNameC.dispose();
    _cSingleFloorNameC.dispose();
    _cSingleUnitsCountC.dispose();
    _cSingleAreaC.dispose();
    _cRangeBlockNameC.dispose();
    _cRangeFromFloorC.dispose();
    _cRangeToFloorC.dispose();
    _cRangeUnitsPerFloorC.dispose();
    _cRangeAreaC.dispose();
    _mCommNameC.dispose();
    _mCommUnitsCountC.dispose();
    _mCommAreaC.dispose();
    _mResWingNameC.dispose();
    _mResFloorsC.dispose();
    _mResUnitsPerFloorC.dispose();
    _mResAreaC.dispose();
    _wNameC.dispose();
    _wFloorsC.dispose();
    _wUnitsPerFloorC.dispose();
    _wAreaC.dispose();
    _sStreetNameC.dispose();
    _sStartUnitC.dispose();
    _sEndUnitC.dispose();
    _sAreaC.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, [Color color = Colors.black87]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadRemoteSocietyDetails() async {
    try {
      final doc = await SocietyService.instance
          .societySettingsDoc(AppFirestore.instance)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        final name = (data['societyName'] ?? '').toString().trim();
        final arch = (data['architectureType'] ?? '').toString().trim();
        final isSetup = data['isSetupComplete'] == true;
        setState(() {
          if (_sNameC.text.isEmpty && name.isNotEmpty && name != 'માય સોસાયટી (My Society)') {
            _sNameC.text = name;
          }
          if (arch.isNotEmpty && ['Commercial', 'Mixed', 'Wing', 'Street'].contains(arch)) {
            _wizardType = arch;
            if (isSetup) {
              _hasSavedArchitecture = true;
            }
          }
        });
      }

      final sid = SocietyService.instance.societyId;
      final existingBlocks = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: sid)
          .limit(1)
          .get();
      if (existingBlocks.docs.isNotEmpty && mounted) {
        setState(() {
          _hasSavedArchitecture = true;
        });
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE SETUP GUIDE MODAL
  // ---------------------------------------------------------------------------

  void _showSetupGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: PremiumDialogHeader(
                title: "પરિસર સેટઅપ માર્ગદર્શિકા",
                subtitle: "તમામ કેસો અને વિવિધ માળનું સચોટ સેટઅપ કેવી રીતે કરવું?",
                icon: Icons.auto_awesome_rounded,
                accentColor: const Color(0xFF0F766E),
                onClose: () => Navigator.pop(ctx),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildGuideCard(
                    icon: Icons.storefront_rounded,
                    color: Colors.amber.shade800,
                    title: "૧. શોપિંગ મોલ / કોમર્શિયલ સંકુલ (Commercial)",
                    description: "જો ૧૦ માળનું શોપિંગ હોય અને દરેક માળે અલગ-અલગ દુકાનો હોય:",
                    steps: [
                      "🔹 ગ્રાઉન્ડ ફ્લોર: 'સિંગલ ફ્લોર' પસંદ કરી 'G' અને '20' લખો ➜ 'G-01' થી 'G-20' આપમેળે બની જશે.",
                      "🔹 પહેલો માળ: 'સિંગલ ફ્લોર' માં '1' અને '15' લખો ➜ '101' થી '115' બની જશે.",
                      "🔹 ૨ થી ૧૦ માળ: 'બહુમાળી રેન્જ' પસંદ કરી '2' થી '10' અને માળ દીઠ '8' લખો ➜ '201' થી '1008' (કુલ ૭૨ ઓફિસો) બની જશે.",
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideCard(
                    icon: Icons.domain_rounded,
                    color: Colors.indigo.shade700,
                    title: "૨. મિક્સ્ડ પ્રોજેક્ટ (દુકાન + ફ્લેટ્સ)",
                    description: "ગ્રાઉન્ડ પર દુકાનો અને ઉપર રેસિડેન્શિયલ ટાવર હોય:",
                    steps: [
                      "🔹 પ્રથમ '🏬 કોમર્શિયલ શોપ્સ' પસંદ કરી 'G' અને '18' લખી નીચેની દુકાનો એડ કરો (SHOP-01 થી SHOP-18).",
                      "🔹 ત્યારબાદ '🏢 રેસિડેન્શિયલ વિંગ' પસંદ કરી 'A' અને ૧૦ માળ, ૪ ફ્લેટ લખી 'વિંગ A' એડ કરો.",
                      "🔹 આ જ રીતે 'વિંગ B' પણ એડ કરી શકો છો. બંનેનો હિસાબ અને બિલ અલગ રહેશે.",
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideCard(
                    icon: Icons.apartment_rounded,
                    color: Colors.teal.shade700,
                    title: "૩. સામાન્ય એપાર્ટમેન્ટ (Wing)",
                    description: "સામાન્ય બહુમાળી ફ્લેટ પ્રોજેક્ટ માટે:",
                    steps: [
                      "🔹 વિંગ નામ 'A', કુલ માળ '5' અને માળ દીઠ '4' લખી એડ કરો ➜ '101' થી '504' આપમેળે બની જશે.",
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideCard(
                    icon: Icons.holiday_village_rounded,
                    color: Colors.green.shade700,
                    title: "૪. રો-હાઉસ / સોસાયટી (Street)",
                    description: "શેરી અને બંગલાની સોસાયટી માટે:",
                    steps: [
                      "🔹 શેરી '૧', પ્રથમ ઘર '૧' અને છેલ્લો ઘર '૨૫' લખી એડ કરો ➜ ઘર નં. ૧ થી ૨૫ બની જશે.",
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideCard(
                    icon: Icons.straighten_rounded,
                    color: Colors.purple.shade700,
                    title: "૫. સ્ક્વેર ફીટ (Sq.Ft) અને મેન્ટેનન્સ બિલિંગ",
                    description: "દુકાન કે ફ્લેટની સરેરાશ સાઈઝ લખવી શા માટે જરૂરી છે?",
                    steps: [
                      "🔹 કોમર્શિયલ સંકુલમાં નાની દુકાન (૨૦૦ ચો.ફૂટ) અને મોટા શો-રૂમ (૧૨૦૦ ચો.ફૂટ) નું બિલ સ્ક્વેર ફીટના દર મુજબ આપમેળે સાચું ગણાશે જેથી કોઈ વિવાદ ન થાય.",
                      "🔹 સેટઅપ પછી પણ એડમિન પેનલમાંથી કોઈપણ દુકાનની ચોક્કસ સાઈઝ બદલી શકાય છે.",
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("સમજાઈ ગયું, સેટઅપ ચાલુ રાખો", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                s,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UNIT GENERATION HELPERS
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _buildSingleFloorUnits({
    required String floorCode,
    required int count,
    required String unitType,
    required double areaSqFt,
  }) {
    final list = <Map<String, dynamic>>[];
    final clean = floorCode.trim().toUpperCase();
    final isGround = clean == 'G' || clean == 'GROUND' || clean == '0';
    final isBasement = clean.startsWith('B') || clean.contains('BASEMENT');

    int floorNo = 1;
    if (isGround) floorNo = 0;
    if (isBasement) floorNo = -1;
    final parsedNo = int.tryParse(clean);
    if (parsedNo != null) floorNo = parsedNo;

    for (int i = 1; i <= count; i++) {
      String uID;
      if (isGround) {
        uID = 'G-${i.toString().padLeft(2, '0')}';
      } else if (isBasement) {
        uID = '$clean-${i.toString().padLeft(2, '0')}';
      } else if (parsedNo != null) {
        uID = '$parsedNo${i.toString().padLeft(2, '0')}';
      } else {
        uID = '$clean-${i.toString().padLeft(2, '0')}';
      }

      list.add({
        'unitNumber': uID,
        'floorNo': floorNo,
        'unitType': unitType,
        'areaSqFt': areaSqFt,
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _buildRangeFloorUnits({
    required int fromFloor,
    required int toFloor,
    required int unitsPerFloor,
    required String unitType,
    required double areaSqFt,
  }) {
    final list = <Map<String, dynamic>>[];
    for (int f = fromFloor; f <= toFloor; f++) {
      for (int u = 1; u <= unitsPerFloor; u++) {
        final uID = '$f${u.toString().padLeft(2, '0')}';
        list.add({
          'unitNumber': uID,
          'floorNo': f,
          'unitType': unitType,
          'areaSqFt': areaSqFt,
        });
      }
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // ADD BLOCK LOGIC
  // ---------------------------------------------------------------------------

  void _addBlockToList() {
    if (_wizardType == 'Commercial') {
      _addCommercialBlock();
    } else if (_wizardType == 'Mixed') {
      _addMixedBlock();
    } else if (_wizardType == 'Wing') {
      _addWingBlock();
    } else {
      _addStreetBlock();
    }
  }

  void _addCommercialBlock() {
    if (_commercialModeIndex == 0) {
      final rawFloor = _cSingleFloorNameC.text.trim();
      final floorName = SocietyService.instance.normalizeBlockName(rawFloor.isEmpty ? 'G' : rawFloor);
      final count = int.tryParse(_cSingleUnitsCountC.text.trim()) ?? 0;
      final area = double.tryParse(_cSingleAreaC.text.trim()) ?? 350.0;

      if (floorName.isEmpty || count <= 0) {
        _showSnackBar("કૃપા કરીને ફ્લોર કોડ અને દુકાનોની માન્ય સંખ્યા લખો!", Colors.orange);
        return;
      }

      final blockId = "FLOOR-$floorName";
      if (_tempBlocks.any((b) => SocietyService.instance.normalizeBlockName(b['name'].toString()) == floorName)) {
        _showSnackBar("ફ્લોર '$floorName' પહેલેથી લિસ્ટમાં ઉમેરેલ છે!", Colors.orange);
        return;
      }

      final units = _buildSingleFloorUnits(
        floorCode: floorName,
        count: count,
        unitType: _cSingleUnitType,
        areaSqFt: area,
      );

      final typeLabel = _cSingleUnitType == 'shop'
          ? 'દુકાનો'
          : (_cSingleUnitType == 'office' ? 'ઓફિસો' : 'એકમો');

      final displayLabel = SocietyService.instance.formatBlockDisplayName(
        floorName,
        architectureType: 'Commercial',
        category: 'commercial',
      );

      setState(() {
        _tempBlocks.add({
          'id': blockId,
          'name': floorName,
          'displayName': '$displayLabel ($count $typeLabel)',
          'category': 'commercial',
          'unitType': _cSingleUnitType,
          'units': units,
          'v1': 1,
          'v2': count,
          'unitPreview': '${units.first['unitNumber']} થી ${units.last['unitNumber']} ($count $typeLabel • ${area.toInt()} sqft)',
        });
        _cSingleUnitsCountC.clear();
      });
      _showSnackBar("ફ્લોર '$floorName' ($count એકમો) ઉમેરાયો!", const Color(0xFF0F766E));
    } else {
      final fromF = int.tryParse(_cRangeFromFloorC.text.trim()) ?? 0;
      final toF = int.tryParse(_cRangeToFloorC.text.trim()) ?? 0;
      final perFloor = int.tryParse(_cRangeUnitsPerFloorC.text.trim()) ?? 0;
      final area = double.tryParse(_cRangeAreaC.text.trim()) ?? 500.0;
      var blockName = _cRangeBlockNameC.text.trim().toUpperCase();

      if (fromF <= 0 || toF < fromF || perFloor <= 0) {
        _showSnackBar("માન્ય ફ્લોર રેન્જ (દા.ત. 2 થી 10) અને માળ દીઠ સંખ્યા લખો!", Colors.orange);
        return;
      }

      if (blockName.isEmpty) blockName = "F$fromF-F$toF";

      final blockId = "FLOORS-$blockName";
      if (_tempBlocks.any((b) => b['id'] == blockId || b['name'] == blockName)) {
        _showSnackBar("આ બ્લોક લિસ્ટમાં પહેલેથી છે!", Colors.orange);
        return;
      }

      final units = _buildRangeFloorUnits(
        fromFloor: fromF,
        toFloor: toF,
        unitsPerFloor: perFloor,
        unitType: _cRangeUnitType,
        areaSqFt: area,
      );

      final typeLabel = _cRangeUnitType == 'office' ? 'ઓફિસો' : 'દુકાનો';

      setState(() {
        _tempBlocks.add({
          'id': blockId,
          'name': blockName,
          'displayName': 'ફ્લોર $fromF થી $toF ($blockName)',
          'category': 'commercial',
          'unitType': _cRangeUnitType,
          'units': units,
          'v1': (toF - fromF + 1),
          'v2': perFloor,
          'unitPreview': '${units.first['unitNumber']} થી ${units.last['unitNumber']} (${units.length} $typeLabel • ${area.toInt()} sqft)',
        });
        _cRangeUnitsPerFloorC.clear();
        _cRangeBlockNameC.clear();
      });
      _showSnackBar("ફ્લોર રેન્જ ($fromF થી $toF) ઉમેરાઈ ગઈ!", const Color(0xFF0F766E));
    }
  }

  void _addMixedBlock() {
    if (_mixedCategoryIndex == 0) {
      final rawName = _mCommNameC.text.trim();
      final name = SocietyService.instance.normalizeBlockName(rawName.isEmpty ? 'G' : rawName);
      final count = int.tryParse(_mCommUnitsCountC.text.trim()) ?? 0;
      final area = double.tryParse(_mCommAreaC.text.trim()) ?? 350.0;

      if (name.isEmpty || count <= 0) {
        _showSnackBar("દુકાનોનું ફ્લોર નામ અને સંખ્યા લખો!", Colors.orange);
        return;
      }

      final blockId = "COMM-$name";
      if (_tempBlocks.any((b) => SocietyService.instance.normalizeBlockName(b['name'].toString()) == name)) {
        _showSnackBar("આ શોપિંગ ફ્લોર/ઝોન '$name' પહેલેથી ઉમેરેલો છે!", Colors.orange);
        return;
      }

      final units = _buildSingleFloorUnits(
        floorCode: name,
        count: count,
        unitType: 'shop',
        areaSqFt: area,
      );

      final displayLabel = SocietyService.instance.formatBlockDisplayName(
        name,
        architectureType: 'Mixed',
        category: 'commercial',
      );

      setState(() {
        _tempBlocks.add({
          'id': blockId,
          'name': name,
          'displayName': '$displayLabel ($count દુકાનો)',
          'category': 'commercial',
          'unitType': 'shop',
          'units': units,
          'v1': 1,
          'v2': count,
          'unitPreview': '${units.first['unitNumber']} થી ${units.last['unitNumber']} ($count શોપ્સ • ${area.toInt()} sqft)',
        });
        _mCommUnitsCountC.clear();
      });
      _showSnackBar("કોમર્શિયલ શોપ્સ ઉમેરાઈ!", const Color(0xFF0F766E));
    } else {
      final rawWing = _mResWingNameC.text.trim();
      final wingName = SocietyService.instance.normalizeBlockName(rawWing);
      final floors = int.tryParse(_mResFloorsC.text.trim()) ?? 0;
      final perFloor = int.tryParse(_mResUnitsPerFloorC.text.trim()) ?? 0;
      final area = double.tryParse(_mResAreaC.text.trim()) ?? 1000.0;

      if (wingName.isEmpty || floors <= 0 || perFloor <= 0) {
        _showSnackBar("વિંગ નામ, કુલ માળ અને ફ્લેટ્સ/માળ દાખલ કરો!", Colors.orange);
        return;
      }

      final blockId = "RES-WING-$wingName";
      if (_tempBlocks.any((b) => SocietyService.instance.normalizeBlockName(b['name'].toString()) == wingName)) {
        _showSnackBar("વિંગ '$wingName' પહેલેથી જ ઉમેરેલી છે!", Colors.orange);
        return;
      }

      final units = <Map<String, dynamic>>[];
      for (int f = 1; f <= floors; f++) {
        for (int u = 1; u <= perFloor; u++) {
          final uID = '$wingName-$f${u.toString().padLeft(2, '0')}';
          units.add({
            'unitNumber': uID,
            'floorNo': f,
            'unitType': 'flat',
            'areaSqFt': area,
          });
        }
      }

      setState(() {
        _tempBlocks.add({
          'id': blockId,
          'name': wingName,
          'displayName': '🏢 વિંગ $wingName (${units.length} ફ્લેટ્સ)',
          'category': 'residential',
          'unitType': 'flat',
          'units': units,
          'v1': floors,
          'v2': perFloor,
          'unitPreview': '${units.first['unitNumber']} થી ${units.last['unitNumber']} (${units.length} ફ્લેટ્સ • ${area.toInt()} sqft)',
        });
        _mResFloorsC.clear();
        _mResUnitsPerFloorC.clear();
      });
      _showSnackBar("રેસિડેન્શિયલ વિંગ '$wingName' ઉમેરાઈ!", const Color(0xFF0F766E));
    }
  }

  void _addWingBlock() {
    final rawWing = _wNameC.text.trim();
    final wingName = SocietyService.instance.normalizeBlockName(rawWing);
    final floors = int.tryParse(_wFloorsC.text.trim()) ?? 0;
    final perFloor = int.tryParse(_wUnitsPerFloorC.text.trim()) ?? 0;
    final area = double.tryParse(_wAreaC.text.trim()) ?? 1000.0;

    if (wingName.isEmpty || floors <= 0 || perFloor <= 0) {
      _showSnackBar("વિંગ નામ, કુલ માળ અને ફ્લેટ્સ/માળ દાખલ કરો!", Colors.orange);
      return;
    }

    final blockId = "W-$wingName";
    if (_tempBlocks.any((b) => SocietyService.instance.normalizeBlockName(b['name'].toString()) == wingName)) {
      _showSnackBar("વિંગ '$wingName' પહેલેથી જ ઉમેરેલી છે!", Colors.orange);
      return;
    }

    final units = <Map<String, dynamic>>[];
    for (int f = 1; f <= floors; f++) {
      for (int u = 1; u <= perFloor; u++) {
        final uID = '$f${u.toString().padLeft(2, '0')}';
        units.add({
          'unitNumber': uID,
          'floorNo': f,
          'unitType': 'flat',
          'areaSqFt': area,
        });
      }
    }

    setState(() {
      _tempBlocks.add({
        'id': blockId,
        'name': wingName,
        'displayName': 'વિંગ $wingName ($floors માળ • ${units.length} ફ્લેટ્સ)',
        'category': 'residential',
        'unitType': 'flat',
        'units': units,
        'v1': floors,
        'v2': perFloor,
        'unitPreview': '$wingName-${units.first['unitNumber']} થી $wingName-${units.last['unitNumber']} (${units.length} ફ્લેટ્સ)',
      });
      _wFloorsC.clear();
      _wUnitsPerFloorC.clear();
    });
    _showSnackBar("વિંગ '$wingName' ઉમેરાઈ!", const Color(0xFF0F766E));
  }

  void _addStreetBlock() {
    final streetName = _sStreetNameC.text.trim().toUpperCase();
    final start = int.tryParse(_sStartUnitC.text.trim()) ?? 0;
    final end = int.tryParse(_sEndUnitC.text.trim()) ?? 0;
    final area = double.tryParse(_sAreaC.text.trim()) ?? 1200.0;

    if (streetName.isEmpty || start <= 0 || end < start) {
      _showSnackBar("શેરી નામ અને શરૂઆત/અંતિમ ઘર નંબર સાચા લખો!", Colors.orange);
      return;
    }

    final blockId = "S-$streetName";
    if (_tempBlocks.any((b) => b['id'] == blockId)) {
      _showSnackBar("શેરી '$streetName' પહેલેથી જ ઉમેરેલી છે!", Colors.orange);
      return;
    }

    final units = <Map<String, dynamic>>[];
    for (int i = start; i <= end; i++) {
      units.add({
        'unitNumber': i.toString(),
        'floorNo': 0,
        'unitType': 'bungalow',
        'areaSqFt': area,
      });
    }

    setState(() {
      _tempBlocks.add({
        'id': blockId,
        'name': streetName,
        'displayName': 'શેરી નં. $streetName (${units.length} મકાનો)',
        'category': 'street',
        'unitType': 'bungalow',
        'units': units,
        'v1': start,
        'v2': end,
        'unitPreview': 'ઘર નં. $start થી $end (${units.length} મકાનો)',
      });
      _sEndUnitC.clear();
    });
    _showSnackBar("શેરી '$streetName' ઉમેરાઈ!", const Color(0xFF0F766E));
  }

  // ---------------------------------------------------------------------------
  // FINAL SETUP & BATCH CHUNKING COMMIT
  // ---------------------------------------------------------------------------

  Future<void> _executeFinalInitialSetup() async {
    final sName = _sNameC.text.trim();
    if (sName.isEmpty) {
      _showSnackBar("સોસાયટીનું નામ લખો!", Colors.orange);
      return;
    }

    if (_tempBlocks.isEmpty) {
      _showSnackBar("ઓછામાં ઓછો એક બ્લોક અથવા ફ્લોર ઉમેરો!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sid = SocietyService.instance.societyId;
      final cfg = {
        'societyName': sName,
        'architectureType': _wizardType,
        'isSetupComplete': true,
        'totalBlocks': _tempBlocks.length,
        'societyId': sid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ૧. સોસાયટી સેટિંગ્સ સેવ
      final settingsBatch = AppFirestore.instance.batch();
      settingsBatch.set(
        SocietyService.instance.societySettingsDoc(AppFirestore.instance),
        cfg,
        SetOptions(merge: true),
      );
      if (sid == SocietyService.kDefaultSocietyId) {
        settingsBatch.set(
          AppFirestore.instance.collection('settings').doc('society_config'),
          cfg,
          SetOptions(merge: true),
        );
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        settingsBatch.set(
          AppFirestore.instance.collection('users').doc(currentUser.uid),
          {
            'societyName': sName,
            'architectureType': _wizardType,
          },
          SetOptions(merge: true),
        );
      }

      // ૨. બ્લોક્સ સેવ
      for (final b in _tempBlocks) {
        final logical = SocietyService.instance.normalizeBlockName(b['name'].toString());
        final phyBlock = SocietyService.instance.blockFirestoreId(logical);
        final displayName = b['displayName'] ??
            SocietyService.instance.formatBlockDisplayName(
              logical,
              architectureType: _wizardType,
              category: b['category']?.toString(),
            );
        settingsBatch.set(
          AppFirestore.instance.collection('blocks').doc(phyBlock),
          {
            'name': logical,
            'displayName': displayName,
            'type': _wizardType,
            'category': b['category'] ?? 'general',
            'unitType': b['unitType'] ?? 'flat',
            'societyId': sid,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await settingsBatch.commit();

      // ૩. યુનિટ્સ લિસ્ટ કલેક્ટ કરી ૩૫૦ ના ચંકમાં સેફ બેચ કમિટ
      final allUnitOps = <Map<String, dynamic>>[];
      for (final b in _tempBlocks) {
        final logical = SocietyService.instance.normalizeBlockName(b['name'].toString());
        final phyBlock = SocietyService.instance.blockFirestoreId(logical);
        final units = (b['units'] as List<Map<String, dynamic>>?) ?? [];

        for (final u in units) {
          final uNumber = u['unitNumber'].toString();
          final docId = SocietyService.instance.unitFirestoreDocId(logical, uNumber);
          allUnitOps.add({
            'docId': docId,
            'data': {
              'blockName': phyBlock,
              'unitNumber': uNumber,
              'floorNo': u['floorNo'] ?? 0,
              'isOccupied': false,
              'unitType': u['unitType'] ?? 'flat',
              'areaSqFt': u['areaSqFt'] ?? 0.0,
              'societyId': sid,
              'createdAt': FieldValue.serverTimestamp(),
            },
          });
        }
      }

      const int chunkSize = 350;
      for (int i = 0; i < allUnitOps.length; i += chunkSize) {
        final batch = AppFirestore.instance.batch();
        final end = (i + chunkSize < allUnitOps.length) ? i + chunkSize : allUnitOps.length;
        for (int j = i; j < end; j++) {
          final op = allUnitOps[j];
          batch.set(
            AppFirestore.instance.collection('units').doc(op['docId'] as String),
            op['data'] as Map<String, dynamic>,
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }

      SocietyService.instance.setArchitectureType(_wizardType);
      SocietyService.instance.setSocietyName(sName);
      _tempBlocks.clear();
      widget.onSetupComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("સેટઅપમાં ભૂલ: $e", Colors.red);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD UI (ULTRA-PREMIUM)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    int totalUnits = 0;
    for (final b in _tempBlocks) {
      final uList = b['units'] as List?;
      if (uList != null) {
        totalUnits += uList.length;
      } else {
        final v1 = (b['v1'] as num?)?.toInt() ?? 0;
        final v2 = (b['v2'] as num?)?.toInt() ?? 0;
        totalUnits += (v1 * v2);
      }
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0F766E)),
              const SizedBox(height: 18),
              Text(
                "સોસાયટી અને એકમો સેટઅપ થઈ રહ્યા છે...\n(કુલ $totalUnits એકમો બની રહ્યા છે)",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Subtle modern slate canvas
      body: CustomScrollView(
        slivers: [
          // 🌟 1. LUXURY 3D HERO SLIVER APP BAR
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F766E),
            surfaceTintColor: Colors.transparent,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: "લૉગઆઉટ (Sign Out)",
                    onPressed: () async {
                      SocietyService.instance.clear();
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
            actions: [
              // Glassmorphic Guide Action Button
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: InkWell(
                  onTap: _showSetupGuideModal,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "માર્ગદર્શિકા",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 3D Hero Rendered Asset
                  Image.asset(
                    'assets/images/wizard_hero.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.apartment_rounded, color: Colors.white24, size: 80),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  // Hero Content
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "✨ સર્વસમાવેશી પરિસર એન્જિન (Universal Space Engine)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "સ્માર્ટ સોસાયટી & મોલ સેટઅપ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "દરેક માળે અલગ-અલગ દુકાનો કે મિક્સ્ડ પ્રોજેક્ટનું સચોટ સેટઅપ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🌟 2. BODY CONTENT SLIVER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏢 STEP 1: PREMISE NAME
                  _buildPremiseNameCard(),

                  const SizedBox(height: 18),

                  // 🎨 STEP 2: VISUAL ARCHITECTURE TYPE CARDS (NO OVERFLOW DROPDOWN)
                  _buildVisualArchitectureSelector(),

                  const SizedBox(height: 18),

                  // 🛠️ STEP 3: DYNAMIC CONFIGURATOR FORM
                  _buildArchitectureForm(context),

                  const SizedBox(height: 22),

                  // 📋 STEP 4: ADDED BLOCKS DECK & CTA
                  _buildAddedBlocksDeck(totalUnits),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: PREMISE NAME CARD
  // ---------------------------------------------------------------------------

  Widget _buildPremiseNameCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                "૧. પરિસરનું નામ દાખલ કરો",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sNameC,
            decoration: InputDecoration(
              hintText: "દા.ત. રત્નમ શોપિંગ સેન્ટર / શિવાલિક હબ / શાંતિવન રેસિડેન્સી",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_rounded, color: Color(0xFF0F766E), size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: VISUAL ARCHITECTURE TYPE CARDS (REPLACES CLUNKY DROPDOWN)
  // ---------------------------------------------------------------------------

  Widget _buildVisualArchitectureSelector() {
    final types = [
      {
        'key': 'Commercial',
        'icon': Icons.storefront_rounded,
        'title': 'શોપિંગ મોલ / માર્કેટ',
        'subtitle': 'દુકાનો, ઓફિસો, શો-રૂમ, ગોડાઉન',
        'tag': 'Sq.Ft + GST',
        'color': Colors.amber.shade800,
        'bg': Colors.amber.shade50,
      },
      {
        'key': 'Mixed',
        'icon': Icons.domain_rounded,
        'title': 'મિક્સ્ડ પ્રોજેક્ટ',
        'subtitle': 'ગ્રાઉન્ડ શોપ્સ + રેસિડેન્શિયલ ટાવર',
        'tag': 'હાઇબ્રિડ સ્પેસ',
        'color': Colors.indigo.shade700,
        'bg': Colors.indigo.shade50,
      },
      {
        'key': 'Wing',
        'icon': Icons.apartment_rounded,
        'title': 'એપાર્ટમેન્ટ ટાવર્સ',
        'subtitle': 'વિંગ A, B... બહુમાળી ફ્લેટ્સ',
        'tag': 'ફ્લેટ્સ / ટાવર',
        'color': Colors.teal.shade700,
        'bg': Colors.teal.shade50,
      },
      {
        'key': 'Street',
        'icon': Icons.holiday_village_rounded,
        'title': 'રો-હાઉસ / સોસાયટી',
        'subtitle': 'શેરી નં. ૧, ૨... બંગલા / ટેનામેન્ટ',
        'tag': 'શેરી લેઆઉટ',
        'color': Colors.green.shade700,
        'bg': Colors.green.shade50,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.category_rounded, size: 20, color: Color(0xFF0F766E)),
                  SizedBox(width: 8),
                  Text(
                    "૨. પરિસરનો પ્રકાર પસંદ કરો",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              if (_isArchitectureLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        "લૉક થયેલ છે",
                        style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ⚠️ Architecture Planning Rule Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isArchitectureLocked ? const Color(0xFFF8FAFC) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isArchitectureLocked ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isArchitectureLocked ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
                  size: 20,
                  color: _isArchitectureLocked ? const Color(0xFF64748B) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArchitectureLocked
                            ? "આર્કિટેક્ચર પ્રકાર કાયમી લૉક છે"
                            : "મહત્વનો પ્લાનિંગ નિયમ (Permanent Architecture Rule)",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isArchitectureLocked ? const Color(0xFF334155) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isArchitectureLocked
                            ? "આ સોસાયટી માટે આર્કિટેક્ચર નક્કી થઈ ગયું છે. એકવાર એકમો જનરેટ થયા પછી મુખ્ય પ્રકાર બદલી શકાતો નથી. જોકે તમે આ જ પ્રકાર હેઠળ નીચેના ફોર્મથી નવા ફ્લોર, શેરી કે બ્લોક ઉમેરી શકો છો."
                            : "એકવાર આર્કિટેક્ચર પસંદ કરીને એકમો જનરેટ થઈ ગયા પછી તેનો મુખ્ય પ્રકાર (જેમ કે Wing, Street, Commercial) બદલી શકાશે નહીં. જોકે તમે પસંદ કરેલા પ્રકાર હેઠળ નવા ફ્લોર, શેરી, વિંગ કે બ્લોક ગમે ત્યારે વધારી શકશો.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _isArchitectureLocked ? const Color(0xFF64748B) : const Color(0xFFB45309),
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2x2 Clean Interactive Card Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: types.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, i) {
              final t = types[i];
              final isSelected = _wizardType == t['key'];
              final isLocked = _isArchitectureLocked && !isSelected;

              return InkWell(
                onTap: isLocked
                    ? () => _showArchitectureLockedDialog(t['title'] as String, types)
                    : () => setState(() => _wizardType = t['key'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: isLocked ? 0.55 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? (t['bg'] as Color) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (t['color'] as Color) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (t['color'] as Color).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (t['color'] as Color).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(t['icon'] as IconData, size: 18, color: t['color'] as Color),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: 18, color: t['color'] as Color)
                            else if (isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 10, color: Colors.amber.shade900),
                                    const SizedBox(width: 2),
                                    Text(
                                      'લૉક',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t['tag'] as String,
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? (t['color'] as Color) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showArchitectureLockedDialog(String targetArchitectureName, List<Map<String, dynamic>> types) {
    final currentTitle = types.firstWhere(
      (e) => e['key'] == _wizardType,
      orElse: () => {'title': _wizardType},
    )['title'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, size: 36, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            const Text(
              'આર્કિટેક્ચર પ્રકાર લૉક થયેલ છે',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'આ સોસાયટી માટે વર્તમાન પ્રકાર "$currentTitle" પહેલેથી નક્કી થયેલ છે. સોસાયટીનું માળખું અને યુનિટ્સ/મેમ્બર્સના ડેટાની સુરક્ષા માટે એકવાર આર્કિટેક્ચર જનરેટ થયા પછી મુખ્ય પ્રકાર બદલી શકાતો નથી.\n\nજો તમારે વધારાના એકમો ઉમેરવા હોય તો તમે પસંદ કરેલા "$currentTitle" પ્રકાર હેઠળ નીચેના ફોર્મમાંથી નવા માળ, શેરી, વિંગ કે બ્લોક ઉમેરી શકો છો.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'સમજાઈ ગયું (Understood)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: DYNAMIC CONFIGURATOR FORM
  // ---------------------------------------------------------------------------

  Widget _buildArchitectureForm(BuildContext context) {
    switch (_wizardType) {
      case 'Commercial':
        return _buildCommercialCard();
      case 'Mixed':
        return _buildMixedCard();
      case 'Street':
        return _buildStreetCard();
      case 'Wing':
      default:
        return _buildWingCard();
    }
  }

  // 🏬 COMMERCIAL SHOPPING FORM CARD
  Widget _buildCommercialCard() {
    String previewText = '';
    if (_commercialModeIndex == 0) {
      final fCode = _cSingleFloorNameC.text.trim().toUpperCase();
      final count = int.tryParse(_cSingleUnitsCountC.text.trim()) ?? 0;
      final area = _cSingleAreaC.text.trim();
      final clean = fCode.isEmpty ? 'G' : fCode;
      final typeLabel = _cSingleUnitType == 'shop'
          ? 'દુકાનો'
          : (_cSingleUnitType == 'office' ? 'ઓફિસો' : (_cSingleUnitType == 'showroom' ? 'શો-રૂમ' : 'ગોડાઉન'));

      if (count > 0) {
        final firstUnit = clean == 'G' ? 'G-01' : (int.tryParse(clean) != null ? '${clean}01' : '$clean-01');
        final lastUnit = clean == 'G'
            ? 'G-${count.toString().padLeft(2, '0')}'
            : (int.tryParse(clean) != null
                ? '$clean${count.toString().padLeft(2, '0')}'
                : '$clean-${count.toString().padLeft(2, '0')}');
        previewText = "✨ બ્લુપ્રિન્ટ: $firstUnit થી $lastUnit (કુલ $count $typeLabel • ${area.isEmpty ? '350' : area} Sq.Ft)";
      }
    } else {
      final fromF = int.tryParse(_cRangeFromFloorC.text.trim()) ?? 0;
      final toF = int.tryParse(_cRangeToFloorC.text.trim()) ?? 0;
      final perF = int.tryParse(_cRangeUnitsPerFloorC.text.trim()) ?? 0;
      final area = _cRangeAreaC.text.trim();
      if (fromF > 0 && toF >= fromF && perF > 0) {
        final total = (toF - fromF + 1) * perF;
        final typeLabel = _cRangeUnitType == 'office' ? 'ઓફિસો' : 'દુકાનો';
        previewText = "✨ બ્લુપ્રિન્ટ: ${fromF}01 થી $toF${perF.toString().padLeft(2, '0')} (કુલ $total $typeLabel • ${area.isEmpty ? '500' : area} Sq.Ft)";
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.layers_rounded, size: 20, color: Color(0xFF0F766E)),
                  SizedBox(width: 8),
                  Text(
                    "૩. ફ્લોર & દુકાનો કોન્ફિગરેશન",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: _showSetupGuideModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline_rounded, size: 12, color: Color(0xFF0F766E)),
                      SizedBox(width: 4),
                      Text(
                        "ગાઈડ",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Segmented Switch
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _commercialModeIndex = 0),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _commercialModeIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _commercialModeIndex == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear_rounded,
                            size: 16,
                            color: _commercialModeIndex == 0 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "સિંગલ ફ્લોર (G, 1...)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _commercialModeIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _commercialModeIndex == 0 ? const Color(0xFF0F766E) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _commercialModeIndex = 1),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _commercialModeIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _commercialModeIndex == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stacked_bar_chart_rounded,
                            size: 16,
                            color: _commercialModeIndex == 1 ? const Color(0xFF0F766E) : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "બહુમાળી રેન્જ (2 થી 10)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _commercialModeIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: _commercialModeIndex == 1 ? const Color(0xFF0F766E) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_commercialModeIndex == 0) ...[
            // 🔹 સિંગલ ફ્લોર
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cSingleFloorNameC,
                    decoration: InputDecoration(
                      labelText: "ફ્લોર કોડ *",
                      hintText: "G, 1, 2...",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _cSingleUnitsCountC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "દુકાન સંખ્યા *",
                      hintText: "દા.ત. 20",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ઝડપી ફ્લોર પિલ્સ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text("ઝડપી ફ્લોર: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ...['G', '1', '2', '3', '4', 'B1', 'B2'].map((c) {
                    final isSelected = _cSingleFloorNameC.text.trim().toUpperCase() == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _cSingleFloorNameC.text = c),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _cSingleUnitType,
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'shop', child: Text("🏪 દુકાન (Shop)", overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'office', child: Text("💼 ઓફિસ (Office)", overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'showroom', child: Text("🏬 શો-રૂમ", overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'godown', child: Text("📦 ગોડાઉન", overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _cSingleUnitType = v!),
                    decoration: InputDecoration(
                      labelText: "એકમ પ્રકાર",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cSingleAreaC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "સરેરાશ સાઈઝ",
                      suffixText: "Sq.Ft",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 🔹 બહુમાળી રેન્જ
            TextField(
              controller: _cRangeBlockNameC,
              decoration: InputDecoration(
                labelText: "બ્લોકનું નામ (વૈકલ્પિક)",
                hintText: "દા.ત. Tower-1 અથવા Offices",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cRangeFromFloorC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "ક્યાંથી માળ *",
                      hintText: "દા.ત. 2",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cRangeToFloorC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "ક્યાં સુધી *",
                      hintText: "દા.ત. 10",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cRangeUnitsPerFloorC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "માળ દીઠ એકમો *",
                      hintText: "દા.ત. 8",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cRangeAreaC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "સરેરાશ સાઈઝ",
                      suffixText: "Sq.Ft",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _cRangeUnitType,
              isExpanded: true,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'office', child: Text("💼 ઓફિસ (Office)", overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'shop', child: Text("🏪 દુકાન (Shop)", overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _cRangeUnitType = v!),
              decoration: InputDecoration(
                labelText: "એકમ પ્રકાર",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],

          // ⚡ લાઈવ પ્રિવ્યુ
          if (previewText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: Text(
                previewText,
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ઉમેરો બટન
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _addBlockToList,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: Text(
                _commercialModeIndex == 0 ? "+ આ ફ્લોર ઉમેરો" : "+ આ ફ્લોર રેન્જ ઉમેરો",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏙️ MIXED-USE FORM CARD
  Widget _buildMixedCard() {
    String previewText = '';
    if (_mixedCategoryIndex == 0) {
      final name = _mCommNameC.text.trim().toUpperCase();
      final prefix = name.isEmpty ? 'SHOP' : name;
      final count = int.tryParse(_mCommUnitsCountC.text.trim()) ?? 0;
      final area = _mCommAreaC.text.trim();
      if (count > 0) {
        previewText = "✨ બ્લુપ્રિન્ટ: $prefix-01 થી $prefix-${count.toString().padLeft(2, '0')} (કુલ $count શોપ્સ • ${area.isEmpty ? '350' : area} Sq.Ft)";
      }
    } else {
      final wing = _mResWingNameC.text.trim().toUpperCase();
      final floors = int.tryParse(_mResFloorsC.text.trim()) ?? 0;
      final perFloor = int.tryParse(_mResUnitsPerFloorC.text.trim()) ?? 0;
      final area = _mResAreaC.text.trim();
      if (floors > 0 && perFloor > 0) {
        final total = floors * perFloor;
        previewText = "✨ બ્લુપ્રિન્ટ: $wing-101 થી $wing-$floors${perFloor.toString().padLeft(2, '0')} (કુલ $total ફ્લેટ્સ • ${area.isEmpty ? '1000' : area} Sq.Ft)";
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.domain_rounded, size: 20, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                "૩. મિક્સ્ડ એકમ પસંદ કરો",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mixedCategoryIndex = 0),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mixedCategoryIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _mixedCategoryIndex == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, size: 16, color: _mixedCategoryIndex == 0 ? const Color(0xFF0F766E) : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            "🏬 કોમર્શિયલ શોપ્સ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _mixedCategoryIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _mixedCategoryIndex == 0 ? const Color(0xFF0F766E) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mixedCategoryIndex = 1),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mixedCategoryIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _mixedCategoryIndex == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_rounded, size: 16, color: _mixedCategoryIndex == 1 ? const Color(0xFF0F766E) : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            "🏢 રેસિડેન્શિયલ વિંગ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _mixedCategoryIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: _mixedCategoryIndex == 1 ? const Color(0xFF0F766E) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_mixedCategoryIndex == 0) ...[
            TextField(
              controller: _mCommNameC,
              decoration: InputDecoration(
                labelText: "શોપિંગ ઝોન / ફ્લોર કોડ *",
                hintText: "દા.ત. G અથવા FRONT-SHOPS",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mCommUnitsCountC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "દુકાનોની સંખ્યા *",
                      hintText: "દા.ત. 18",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mCommAreaC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "સરેરાશ સાઈઝ",
                      suffixText: "Sq.Ft",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _mResWingNameC,
              decoration: InputDecoration(
                labelText: "રેસિડેન્શિયલ વિંગ નામ *",
                hintText: "દા.ત. A, B અથવા C",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mResFloorsC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "કુલ માળ *",
                      hintText: "દા.ત. 10",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mResUnitsPerFloorC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "માળ દીઠ ફ્લેટ્સ *",
                      hintText: "દા.ત. 4",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mResAreaC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "સરેરાશ ફ્લેટ સાઈઝ (Sq.Ft)",
                hintText: "દા.ત. 1000",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],

          if (previewText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: Text(
                previewText,
                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _addBlockToList,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: Text(
                _mixedCategoryIndex == 0 ? "+ કોમર્શિયલ શોપ્સ ઉમેરો" : "+ રેસિડેન્શિયલ વિંગ ઉમેરો",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏢 RESIDENTIAL WING FORM CARD
  Widget _buildWingCard() {
    final wing = _wNameC.text.trim().toUpperCase();
    final floors = int.tryParse(_wFloorsC.text.trim()) ?? 0;
    final perF = int.tryParse(_wUnitsPerFloorC.text.trim()) ?? 0;
    String preview = '';
    if (floors > 0 && perF > 0) {
      preview = "✨ બ્લુપ્રિન્ટ: $wing-101 થી $wing-$floors${perF.toString().padLeft(2, '0')} (કુલ ${floors * perF} ફ્લેટ્સ)";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                "૩. વિંગ અને ફ્લેટ વિગતો",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _wNameC,
            decoration: InputDecoration(
              labelText: "વિંગ નામ *",
              hintText: "દા.ત. A, B અથવા C",
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wFloorsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "કુલ માળ *",
                    hintText: "દા.ત. 5",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _wUnitsPerFloorC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "માળ દીઠ ફ્લેટ *",
                    hintText: "દા.ત. 4",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wAreaC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "સરેરાશ ફ્લેટ સાઈઝ (Sq.Ft)",
              hintText: "દા.ત. 1000",
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: Text(
                preview,
                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _addBlockToList,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: const Text("+ લિસ્ટમાં વિંગ ઉમેરો", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏡 STREET FORM CARD
  Widget _buildStreetCard() {
    final street = _sStreetNameC.text.trim();
    final start = int.tryParse(_sStartUnitC.text.trim()) ?? 0;
    final end = int.tryParse(_sEndUnitC.text.trim()) ?? 0;
    String preview = '';
    if (start > 0 && end >= start) {
      final sLabel = street.isEmpty ? 'શેરી' : 'શેરી $street';
      preview = "✨ બ્લુપ્રિન્ટ: $sLabel (ઘર નં. $start થી $end • કુલ ${end - start + 1} મકાનો)";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.holiday_village_rounded, size: 20, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                "૩. શેરી અને મકાન વિગતો",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sStreetNameC,
            decoration: InputDecoration(
              labelText: "શેરી નંબર / નામ *",
              hintText: "દા.ત. 1 અથવા રત્નદીપ",
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sStartUnitC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "શરૂઆત ઘર નં. *",
                    hintText: "દા.ત. 1",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _sEndUnitC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "છેલ્લો ઘર નં. *",
                    hintText: "દા.ત. 25",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sAreaC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "સરેરાશ પ્લોટ / મકાન સાઈઝ (Sq.Ft)",
              hintText: "દા.ત. 1200",
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: Text(
                preview,
                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _addBlockToList,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: const Text("+ લિસ્ટમાં શેરી ઉમેરો", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: ADDED BLOCKS DECK & CTA
  // ---------------------------------------------------------------------------

  Widget _buildAddedBlocksDeck(int totalUnits) {
    if (_tempBlocks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.architecture_rounded, color: Color(0xFF0F766E), size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                "કોઈ બ્લોક કે ફ્લોર ઉમેરેલ નથી",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                "ઉપરના ફોર્મમાંથી ફ્લોર વિગત ભરી '+ આ ફ્લોર ઉમેરો' દબાવો.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF0F766E)),
                const SizedBox(width: 8),
                const Text(
                  "ઉમેરેલા બ્લોક્સ & સ્પેસ બ્લુપ્રિન્ટ",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${_tempBlocks.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: Text(
                "કુલ: $totalUnits એકમો",
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tempBlocks.length,
          itemBuilder: (context, index) {
            final b = _tempBlocks[index];
            final isComm = b['category'] == 'commercial';
            final isStreet = b['category'] == 'street';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isComm
                        ? Colors.amber.shade50
                        : (isStreet ? Colors.green.shade50 : Colors.indigo.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isComm
                          ? Colors.amber.shade200
                          : (isStreet ? Colors.green.shade200 : Colors.indigo.shade200),
                    ),
                  ),
                  child: Icon(
                    isComm
                        ? Icons.storefront_rounded
                        : (isStreet ? Icons.holiday_village_rounded : Icons.apartment_rounded),
                    color: isComm
                        ? Colors.amber.shade900
                        : (isStreet ? Colors.green.shade900 : Colors.indigo.shade900),
                    size: 22,
                  ),
                ),
                title: Text(
                  b['displayName'] ?? b['name'],
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                subtitle: Text(
                  b['unitPreview'] ?? "એકમો ઉપલબ્ધ",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => setState(() => _tempBlocks.removeAt(index)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // પ્રિવ્યુ બટન
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArchitecturePreviewScreen(
                    tempBlocks: _tempBlocks,
                    architectureType: _wizardType,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.preview_rounded, size: 18),
            label: const Text("આર્કિટેક્ચર પ્રિવ્યુ જુઓ (Full Preview)"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 🚀 ફાઇનલ સેટઅપ પૂર્ણ કરો બટન
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _executeFinalInitialSetup,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "ફાઈનલ સેટઅપ પૂર્ણ કરો (${_tempBlocks.length} બ્લોક્સ • $totalUnits એકમો)",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
