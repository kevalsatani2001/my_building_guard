import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/society_service.dart';

class AdminAddBlockScreen extends StatefulWidget {
  final String architectureType;

  const AdminAddBlockScreen({
    super.key,
    required this.architectureType,
  });

  @override
  State<AdminAddBlockScreen> createState() => _AdminAddBlockScreenState();
}

class _AdminAddBlockScreenState extends State<AdminAddBlockScreen> {
  // Commercial controllers
  int _commercialMode = 0; // 0: Single Floor, 1: Multi Floor Range
  final _cSingleFloorNameC = TextEditingController(text: 'G');
  final _cSingleUnitsCountC = TextEditingController();
  final _cSingleAreaC = TextEditingController(text: '350');
  String _cSingleUnitType = 'shop';

  final _cRangeBlockNameC = TextEditingController();
  final _cRangeFromFloorC = TextEditingController(text: '2');
  final _cRangeToFloorC = TextEditingController(text: '10');
  final _cRangeUnitsPerFloorC = TextEditingController();
  final _cRangeAreaC = TextEditingController(text: '500');
  String _cRangeUnitType = 'office';

  // Mixed controllers
  int _mixedCategory = 0; // 0: Commercial, 1: Residential
  final _mCommFloorNameC = TextEditingController(text: 'G');
  final _mCommUnitsCountC = TextEditingController();
  final _mCommAreaC = TextEditingController(text: '350');

  final _mResWingNameC = TextEditingController(text: 'A');
  final _mResFloorsC = TextEditingController();
  final _mResUnitsPerFloorC = TextEditingController();
  final _mResAreaC = TextEditingController(text: '1000');

  // Wing controllers
  final _wNameC = TextEditingController(text: 'A');
  final _wFloorsC = TextEditingController();
  final _wUnitsPerFloorC = TextEditingController();
  final _wAreaC = TextEditingController(text: '1000');

  // Street controllers
  final _sStreetNameC = TextEditingController(text: '1');
  final _sStartUnitC = TextEditingController(text: '1');
  final _sEndUnitC = TextEditingController();
  final _sAreaC = TextEditingController(text: '1200');

  bool _isSaving = false;

  @override
  void dispose() {
    _cSingleFloorNameC.dispose();
    _cSingleUnitsCountC.dispose();
    _cSingleAreaC.dispose();
    _cRangeBlockNameC.dispose();
    _cRangeFromFloorC.dispose();
    _cRangeToFloorC.dispose();
    _cRangeUnitsPerFloorC.dispose();
    _cRangeAreaC.dispose();
    _mCommFloorNameC.dispose();
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

  void _showSnackBar(String msg, [Color color = Colors.red]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submitForm() async {
    String cleanBlockName = '';
    String displayName = '';
    String category = 'general';
    String unitType = 'flat';
    final List<Map<String, dynamic>> generatedUnits = [];

    if (widget.architectureType == 'Commercial') {
      category = 'commercial';
      if (_commercialMode == 0) {
        // Single Floor
        cleanBlockName = SocietyService.instance.normalizeBlockName(_cSingleFloorNameC.text.trim());
        final count = int.tryParse(_cSingleUnitsCountC.text.trim()) ?? 0;
        final area = double.tryParse(_cSingleAreaC.text.trim()) ?? 350.0;
        unitType = _cSingleUnitType;

        if (cleanBlockName.isEmpty || count <= 0) {
          _showSnackBar("ફ્લોરનું નામ અને દુકાનોની માન્ય સંખ્યા દાખલ કરો!");
          return;
        }

        final displayLabel = SocietyService.instance.formatBlockDisplayName(
          cleanBlockName,
          architectureType: 'Commercial',
          category: category,
        );
        displayName = "$displayLabel ($count એકમો)";
        final isGround = SocietyService.instance.isGroundBlock(cleanBlockName);
        final isBasement = cleanBlockName.startsWith('B') || cleanBlockName.contains('BASEMENT');
        int floorNo = isGround ? 0 : (isBasement ? -1 : (int.tryParse(cleanBlockName) ?? 1));

        for (int i = 1; i <= count; i++) {
          final uID = isGround
              ? 'G-${i.toString().padLeft(2, '0')}'
              : (isBasement
                  ? '$cleanBlockName-${i.toString().padLeft(2, '0')}'
                  : (int.tryParse(cleanBlockName) != null
                      ? '$cleanBlockName${i.toString().padLeft(2, '0')}'
                      : '$cleanBlockName-${i.toString().padLeft(2, '0')}'));

          generatedUnits.add({
            'unitNumber': uID,
            'floorNo': floorNo,
            'unitType': unitType,
            'areaSqFt': area,
          });
        }
      } else {
        // Floor Range
        final fromF = int.tryParse(_cRangeFromFloorC.text.trim()) ?? 0;
        final toF = int.tryParse(_cRangeToFloorC.text.trim()) ?? 0;
        final perFloor = int.tryParse(_cRangeUnitsPerFloorC.text.trim()) ?? 0;
        final area = double.tryParse(_cRangeAreaC.text.trim()) ?? 500.0;
        cleanBlockName = _cRangeBlockNameC.text.trim().toUpperCase();
        unitType = _cRangeUnitType;

        if (fromF <= 0 || toF < fromF || perFloor <= 0) {
          _showSnackBar("માન્ય ફ્લોર રેન્જ (દા.ત. 2 થી 10) અને માળ દીઠ સંખ્યા લખો!");
          return;
        }

        if (cleanBlockName.isEmpty) cleanBlockName = "F$fromF-F$toF";
        displayName = "ફ્લોર $fromF થી $toF ($cleanBlockName)";

        for (int f = fromF; f <= toF; f++) {
          for (int u = 1; u <= perFloor; u++) {
            final uID = '$f${u.toString().padLeft(2, '0')}';
            generatedUnits.add({
              'unitNumber': uID,
              'floorNo': f,
              'unitType': unitType,
              'areaSqFt': area,
            });
          }
        }
      }
    } else if (widget.architectureType == 'Mixed') {
      if (_mixedCategory == 0) {
        // Mixed Commercial
        category = 'commercial';
        unitType = 'shop';
        cleanBlockName = SocietyService.instance.normalizeBlockName(_mCommFloorNameC.text.trim());
        final count = int.tryParse(_mCommUnitsCountC.text.trim()) ?? 0;
        final area = double.tryParse(_mCommAreaC.text.trim()) ?? 350.0;

        if (cleanBlockName.isEmpty || count <= 0) {
          _showSnackBar("શોપિંગ ઝોન નામ અને દુકાનોની સંખ્યા લખો!");
          return;
        }

        final displayLabel = SocietyService.instance.formatBlockDisplayName(
          cleanBlockName,
          architectureType: 'Mixed',
          category: 'commercial',
        );
        displayName = "$displayLabel ($count દુકાનો)";
        final isGround = SocietyService.instance.isGroundBlock(cleanBlockName);

        for (int i = 1; i <= count; i++) {
          final uID = isGround
              ? 'G-${i.toString().padLeft(2, '0')}'
              : '$cleanBlockName-${i.toString().padLeft(2, '0')}';
          generatedUnits.add({
            'unitNumber': uID,
            'floorNo': 0,
            'unitType': 'shop',
            'areaSqFt': area,
          });
        }
      } else {
        // Mixed Residential
        category = 'residential';
        unitType = 'flat';
        cleanBlockName = SocietyService.instance.normalizeBlockName(_mResWingNameC.text.trim());
        final floors = int.tryParse(_mResFloorsC.text.trim()) ?? 0;
        final perFloor = int.tryParse(_mResUnitsPerFloorC.text.trim()) ?? 0;
        final area = double.tryParse(_mResAreaC.text.trim()) ?? 1000.0;

        if (cleanBlockName.isEmpty || floors <= 0 || perFloor <= 0) {
          _showSnackBar("વિંગ નામ, કુલ માળ અને ફ્લેટ્સ/માળ દાખલ કરો!");
          return;
        }

        displayName = "🏢 વિંગ $cleanBlockName ($floors માળ)";
        for (int f = 1; f <= floors; f++) {
          for (int u = 1; u <= perFloor; u++) {
            final uID = '$cleanBlockName-$f${u.toString().padLeft(2, '0')}';
            generatedUnits.add({
              'unitNumber': uID,
              'floorNo': f,
              'unitType': 'flat',
              'areaSqFt': area,
            });
          }
        }
      }
    } else if (widget.architectureType == 'Wing') {
      category = 'residential';
      unitType = 'flat';
      cleanBlockName = SocietyService.instance.normalizeBlockName(_wNameC.text.trim());
      final floors = int.tryParse(_wFloorsC.text.trim()) ?? 0;
      final perFloor = int.tryParse(_wUnitsPerFloorC.text.trim()) ?? 0;
      final area = double.tryParse(_wAreaC.text.trim()) ?? 1000.0;

      if (cleanBlockName.isEmpty || floors <= 0 || perFloor <= 0) {
        _showSnackBar("વિંગ નામ, કુલ માળ અને ફ્લેટ્સ/માળ દાખલ કરો!");
        return;
      }

      displayName = "વિંગ $cleanBlockName";
      for (int f = 1; f <= floors; f++) {
        for (int u = 1; u <= perFloor; u++) {
          final uID = '$f${u.toString().padLeft(2, '0')}';
          generatedUnits.add({
            'unitNumber': uID,
            'floorNo': f,
            'unitType': 'flat',
            'areaSqFt': area,
          });
        }
      }
    } else {
      // Street
      category = 'street';
      unitType = 'bungalow';
      cleanBlockName = _sStreetNameC.text.trim().toUpperCase();
      final start = int.tryParse(_sStartUnitC.text.trim()) ?? 0;
      final end = int.tryParse(_sEndUnitC.text.trim()) ?? 0;
      final area = double.tryParse(_sAreaC.text.trim()) ?? 1200.0;

      if (cleanBlockName.isEmpty || start <= 0 || end < start) {
        _showSnackBar("શેરી નામ અને શરૂઆત/અંતિમ ઘર નંબર સાચા લખો!");
        return;
      }

      displayName = "શેરી નં. $cleanBlockName";
      for (int i = start; i <= end; i++) {
        generatedUnits.add({
          'unitNumber': i.toString(),
          'floorNo': 0,
          'unitType': 'bungalow',
          'areaSqFt': area,
        });
      }
    }

    setState(() => _isSaving = true);
    try {
      final sid = SocietyService.instance.societyId;

      // ડુપ્લિકેટ બ્લોક તપાસ (દા.ત. G અને Ground ફરી ન બને)
      final existingBlocks = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: sid)
          .get();

      final alreadyExists = existingBlocks.docs.any((d) {
        final bData = d.data();
        final raw = (bData['name'] ?? d.id).toString();
        return SocietyService.instance.normalizeBlockName(raw) == cleanBlockName;
      });

      if (alreadyExists) {
        _showSnackBar("આ બ્લોક/ફ્લોર '$cleanBlockName' સોસાયટીમાં પહેલેથી જ હાજર છે!", Colors.orange);
        return;
      }

      final phyBlockId = SocietyService.instance.blockFirestoreId(cleanBlockName);

      // ૧. બ્લોક સેવ
      final blockBatch = AppFirestore.instance.batch();
      blockBatch.set(
        AppFirestore.instance.collection('blocks').doc(phyBlockId),
        {
          'name': cleanBlockName,
          'displayName': displayName,
          'type': widget.architectureType,
          'category': category,
          'unitType': unitType,
          'createdAt': FieldValue.serverTimestamp(),
          'societyId': sid,
        },
        SetOptions(merge: true),
      );
      await blockBatch.commit();

      // ૨. યુનિટ્સ સેવ (ચંકડ બેચ - ૩૫૦ ops per batch)
      const int chunkSize = 350;
      for (int i = 0; i < generatedUnits.length; i += chunkSize) {
        final b = AppFirestore.instance.batch();
        final end = (i + chunkSize < generatedUnits.length) ? i + chunkSize : generatedUnits.length;
        for (int j = i; j < end; j++) {
          final u = generatedUnits[j];
          final docId = SocietyService.instance.unitFirestoreDocId(cleanBlockName, u['unitNumber'].toString());
          b.set(
            AppFirestore.instance.collection('units').doc(docId),
            {
              'blockName': phyBlockId,
              'unitNumber': u['unitNumber'],
              'floorNo': u['floorNo'],
              'isOccupied': false,
              'unitType': u['unitType'],
              'areaSqFt': u['areaSqFt'],
              'societyId': sid,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        await b.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("નવો બ્લોક '$cleanBlockName' અને તેના ${generatedUnits.length} એકમો સફળતાપૂર્વક બની ગયા!"),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnackBar("ભૂલ આવી: $e", Colors.red.shade800);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "નવો બ્લોક / ફ્લોર ઉમેરો",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              "${widget.architectureType} આર્કિટેક્ચર અંતર્ગત નવો એકમ",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // હેડર બેનર
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.domain_add_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "નવો ${widget.architectureType} એકમ ઉમેરો",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "તમામ એકમો અને સ્ક્વેર ફીટ સાઈઝ આપમેળે સિસ્ટમમાં જોડાઈ જશે",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ડાયનેમિક ફોર્મ કાર્ડ
            _buildDynamicFormCard(context),

            const SizedBox(height: 24),

            // સબમિટ બટન
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "નવો બ્લોક સેવ કરો (Generate Units)",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFormCard(BuildContext context) {
    if (widget.architectureType == 'Commercial') {
      return _buildCommercialCard();
    } else if (widget.architectureType == 'Mixed') {
      return _buildMixedCard();
    } else if (widget.architectureType == 'Wing') {
      return _buildWingCard();
    } else {
      return _buildStreetCard();
    }
  }

  // 🏬 COMMERCIAL
  Widget _buildCommercialCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text("સિંગલ ફ્લોર (Single)")),
              ButtonSegment(value: 1, label: Text("ફ્લોર રેન્જ (Range)")),
            ],
            selected: {_commercialMode},
            onSelectionChanged: (s) => setState(() => _commercialMode = s.first),
          ),
          const SizedBox(height: 16),
          if (_commercialMode == 0) ...[
            TextField(
              controller: _cSingleFloorNameC,
              decoration: const InputDecoration(
                labelText: "ફ્લોર કોડ / નામ *",
                hintText: "દા.ત. G, 1, 2, B1",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cSingleUnitsCountC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "દુકાન/ઓફિસ સંખ્યા *",
                      hintText: "દા.ત. 20",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cSingleAreaC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "સરેરાશ Sq.Ft",
                      hintText: "દા.ત. 350",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _cSingleUnitType,
              items: const [
                DropdownMenuItem(value: 'shop', child: Text("🏪 દુકાન (Shop)")),
                DropdownMenuItem(value: 'office', child: Text("💼 ઓફિસ (Office)")),
                DropdownMenuItem(value: 'showroom', child: Text("🏬 શો-રૂમ (Showroom)")),
                DropdownMenuItem(value: 'godown', child: Text("📦 ગોડાઉન (Godown)")),
              ],
              onChanged: (v) => setState(() => _cSingleUnitType = v!),
              decoration: const InputDecoration(labelText: "એકમ પ્રકાર", border: OutlineInputBorder()),
            ),
          ] else ...[
            TextField(
              controller: _cRangeBlockNameC,
              decoration: const InputDecoration(
                labelText: "બ્લોક નામ (વૈકલ્પિક)",
                hintText: "દા.ત. Corporate Floors",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cRangeFromFloorC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "ક્યાંથી માળ *", hintText: "દા.ત. 2", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cRangeToFloorC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "ક્યાં સુધી *", hintText: "દા.ત. 10", border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: "માળ દીઠ એકમો *", hintText: "દા.ત. 8", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cRangeAreaC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "સરેરાશ Sq.Ft", hintText: "દા.ત. 500", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _cRangeUnitType,
              items: const [
                DropdownMenuItem(value: 'office', child: Text("💼 ઓફિસ (Office)")),
                DropdownMenuItem(value: 'shop', child: Text("🏪 દુકાન (Shop)")),
              ],
              onChanged: (v) => setState(() => _cRangeUnitType = v!),
              decoration: const InputDecoration(labelText: "એકમ પ્રકાર", border: OutlineInputBorder()),
            ),
          ],
        ],
      ),
    );
  }

  // 🏙️ MIXED
  Widget _buildMixedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text("🏬 કોમર્શિયલ શોપ્સ")),
              ButtonSegment(value: 1, label: Text("🏢 રેસિડેન્શિયલ વિંગ")),
            ],
            selected: {_mixedCategory},
            onSelectionChanged: (s) => setState(() => _mixedCategory = s.first),
          ),
          const SizedBox(height: 16),
          if (_mixedCategory == 0) ...[
            TextField(
              controller: _mCommFloorNameC,
              decoration: const InputDecoration(labelText: "શોપિંગ ઝોન / ફ્લોર *", hintText: "દા.ત. G", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mCommUnitsCountC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "દુકાનો સંખ્યા *", hintText: "દા.ત. 18", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mCommAreaC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "સરેરાશ Sq.Ft", hintText: "દા.ત. 350", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _mResWingNameC,
              decoration: const InputDecoration(labelText: "વિંગ નામ *", hintText: "દા.ત. A", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mResFloorsC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "કુલ માળ *", hintText: "દા.ત. 10", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mResUnitsPerFloorC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "માળ દીઠ ફ્લેટ્સ *", hintText: "દા.ત. 4", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mResAreaC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "સરેરાશ ફ્લેટ સાઈઝ (Sq.Ft)", hintText: "દા.ત. 1000", border: OutlineInputBorder()),
            ),
          ],
        ],
      ),
    );
  }

  // 🏢 WING
  Widget _buildWingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _wNameC,
            decoration: const InputDecoration(labelText: "વિંગ નામ *", hintText: "દા.ત. A", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wFloorsC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "કુલ માળ *", hintText: "દા.ત. 5", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _wUnitsPerFloorC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "માળ દીઠ ફ્લેટ *", hintText: "દા.ત. 4", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wAreaC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "સરેરાશ ફ્લેટ સાઈઝ (Sq.Ft)", hintText: "દા.ત. 1000", border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  // 🏡 STREET
  Widget _buildStreetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _sStreetNameC,
            decoration: const InputDecoration(labelText: "શેરી નંબર / નામ *", hintText: "દા.ત. 1", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sStartUnitC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "શરૂઆત ઘર નં. *", hintText: "દા.ત. 1", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _sEndUnitC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "છેલ્લો ઘર નં. *", hintText: "દા.ત. 25", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sAreaC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "સરેરાશ સાઈઝ (Sq.Ft)", hintText: "દા.ત. 1200", border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
