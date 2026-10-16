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
  final _nameC = TextEditingController();
  final _v1C = TextEditingController();
  final _v2C = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameC.dispose();
    _v1C.dispose();
    _v2C.dispose();
    super.dispose();
  }

  void _generateUnits(
    WriteBatch batch,
    String logicalBlockId,
    String type,
    int v1,
    int v2,
  ) {
    final phy = SocietyService.instance.blockFirestoreId(logicalBlockId);
    final sid = SocietyService.instance.societyId;
    if (type == 'Wing') {
      for (int f = 1; f <= v1; f++) {
        for (int u = 1; u <= v2; u++) {
          String uID = "$f${u.toString().padLeft(2, '0')}";
          final docId = SocietyService.instance.unitFirestoreDocId(
            logicalBlockId,
            uID,
          );
          batch.set(AppFirestore.instance.collection('units').doc(docId), {
            'blockName': phy,
            'unitNumber': uID,
            'floorNo': f,
            'isOccupied': false,
            'societyId': sid,
          });
        }
      }
    } else {
      for (int i = v1; i <= v2; i++) {
        final docId = SocietyService.instance.unitFirestoreDocId(
          logicalBlockId,
          i.toString(),
        );
        batch.set(AppFirestore.instance.collection('units').doc(docId), {
          'blockName': phy,
          'unitNumber': i.toString(),
          'isOccupied': false,
          'societyId': sid,
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final name = _nameC.text.trim();
    final v1 = int.tryParse(_v1C.text.trim());
    final v2 = int.tryParse(_v2C.text.trim());

    if (name.isEmpty || v1 == null || v2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને બધી વિગતો સાચી ભરો!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (v1 <= 0 || v2 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("સંખ્યા 0 કરતા વધુ હોવી જોઈએ!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.architectureType != 'Wing' && v1 > v2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("પ્રથમ ઘર નંબર અંતિમ ઘર નંબર કરતા નાનો હોવો જોઈએ!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final batch = AppFirestore.instance.batch();
      final sid = SocietyService.instance.societyId;
      final phyBlockId = SocietyService.instance.blockFirestoreId(name);

      batch.set(
        AppFirestore.instance.collection('blocks').doc(phyBlockId),
        {
          'type': widget.architectureType,
          'createdAt': FieldValue.serverTimestamp(),
          'societyId': sid,
        },
      );

      _generateUnits(batch, name, widget.architectureType, v1, v2);

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("નવી ${widget.architectureType} '$name' અને તેના ફ્લેટ્સ બની ગયા!"),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ભૂલ આવી: $e"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWing = widget.architectureType == 'Wing';
    final v1 = int.tryParse(_v1C.text.trim()) ?? 0;
    final v2 = int.tryParse(_v2C.text.trim()) ?? 0;
    final totalUnitsCount = isWing ? (v1 * v2) : (v2 >= v1 && v1 > 0 ? (v2 - v1 + 1) : 0);

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
              "નવી ${widget.architectureType} ઉમેરો",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "સોસાયટી બ્લોક અને ઓટો ફ્લેટ જનરેશન",
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
            // Visual Banner
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
                    child: Icon(
                      isWing ? Icons.apartment_rounded : Icons.holiday_village_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWing ? "નવો વિંગ / ટાવર સેટઅપ" : "નવી શેરી / લાઇન સેટઅપ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isWing
                              ? "માળ અને ફ્લેટ્સ આપમેળે 101, 102... થી બની જશે"
                              : "ઘર નંબર આપમેળે ક્રમ અનુસાર બની જશે",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                    controller: _nameC,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "${widget.architectureType} નું નામ / કોડ *",
                      hintText: "દા.ત. A, B અથવા C",
                      prefixIcon: const Icon(Icons.domain_rounded, size: 20, color: Color(0xFF0D9488)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _v1C,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isWing ? "કુલ માળ (Total Floors) *" : "પ્રથમ ઘર નંબર (Start Unit) *",
                      hintText: isWing ? "દા.ત. 5 (પાંચ માળ)" : "દા.ત. 1",
                      prefixIcon: Icon(
                        isWing ? Icons.layers_rounded : Icons.tag_rounded,
                        size: 20,
                        color: const Color(0xFF0D9488),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _v2C,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isWing ? "દરેક માળે ફ્લેટ્સ (Flats per floor) *" : "અંતિમ ઘર નંબર (End Unit) *",
                      hintText: isWing ? "દા.ત. 4 (દરેક માળે 4 ફ્લેટ)" : "દા.ત. 30",
                      prefixIcon: Icon(
                        isWing ? Icons.grid_view_rounded : Icons.tag_rounded,
                        size: 20,
                        color: const Color(0xFF0D9488),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Generation Preview Card
            if (totalUnitsCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF047857),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "કુલ $totalUnitsCount એકમો બનશે",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isWing
                                ? "દા.ત. ફ્લેટ્સ: 101 થી ${_v1C.text}${_v2C.text.padLeft(2, '0')}"
                                : "દા.ત. ઘર નંબર: ${_v1C.text} થી ${_v2C.text}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                onPressed: _isSaving ? null : _submitForm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_business_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "નવી ${widget.architectureType} બનાવો",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
