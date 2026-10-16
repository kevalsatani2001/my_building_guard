import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';

import '../services/society_service.dart';
import 'architecture_preview.dart';

class AdminSetupWizardScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const AdminSetupWizardScreen({
    super.key,
    required this.onSetupComplete,
  });

  @override
  State<AdminSetupWizardScreen> createState() => _AdminSetupWizardScreenState();
}

class _AdminSetupWizardScreenState extends State<AdminSetupWizardScreen> {
  final TextEditingController _sNameC = TextEditingController();
  final TextEditingController _bNameC = TextEditingController();
  final TextEditingController _v1C = TextEditingController();
  final TextEditingController _v2C = TextEditingController();

  final List<Map<String, dynamic>> _tempBlocks = [];
  String _wizardType = 'Wing';
  bool _isLoading = false;

  @override
  void dispose() {
    _sNameC.dispose();
    _bNameC.dispose();
    _v1C.dispose();
    _v2C.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, [Color color = Colors.black87]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addBlockToList() {
    if (_bNameC.text.trim().isEmpty ||
        _v1C.text.trim().isEmpty ||
        _v2C.text.trim().isEmpty) {
      _showSnackBar("બ્લોકની બધી વિગતો ભરો!", Colors.orange);
      return;
    }

    final v1 = int.tryParse(_v1C.text.trim());
    final v2 = int.tryParse(_v2C.text.trim());
    if (v1 == null || v2 == null || v1 <= 0 || v2 <= 0) {
      _showSnackBar("માન્ય આંકડા દાખલ કરો!", Colors.orange);
      return;
    }

    final bID =
        "${_wizardType.substring(0, 1)}-${_bNameC.text.trim().toUpperCase()}";

    if (_tempBlocks.any((b) => b['id'] == bID)) {
      _showSnackBar("આ બ્લોક લિસ્ટમાં પહેલેથી છે!", Colors.orange);
      return;
    }

    setState(() {
      _tempBlocks.add({
        'id': bID,
        'name': _bNameC.text.trim().toUpperCase(),
        'v1': v1,
        'v2': v2,
      });
      _bNameC.clear();
      _v1C.clear();
      _v2C.clear();
    });
  }

  Future<void> _executeFinalInitialSetup() async {
    final sName = _sNameC.text.trim();
    if (sName.isEmpty) {
      _showSnackBar("સોસાયટીનું નામ લખો!", Colors.orange);
      return;
    }

    if (_tempBlocks.isEmpty) {
      _showSnackBar("ઓછામાં ઓછો એક બ્લોક ઉમેરો!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final batch = AppFirestore.instance.batch();
      final sid = SocietyService.instance.societyId;
      final cfg = {
        'societyName': sName,
        'architectureType': _wizardType,
        'isSetupComplete': true,
        'totalBlocks': _tempBlocks.length,
        'societyId': sid,
      };

      batch.set(
        SocietyService.instance.societySettingsDoc(AppFirestore.instance),
        cfg,
      );
      if (sid == SocietyService.kDefaultSocietyId) {
        batch.set(
          AppFirestore.instance
              .collection('settings')
              .doc('society_config'),
          cfg,
        );
      }

      for (var b in _tempBlocks) {
        String logical = b['id'];
        final phyBlock = SocietyService.instance.blockFirestoreId(logical);
        batch.set(
          AppFirestore.instance.collection('blocks').doc(phyBlock),
          {'name': logical, 'type': _wizardType, 'societyId': sid},
        );

        if (_wizardType == 'Wing') {
          for (int f = 1; f <= b['v1']; f++) {
            for (int u = 1; u <= b['v2']; u++) {
              String uID = "$f${u.toString().padLeft(2, '0')}";
              final uDoc = SocietyService.instance.unitFirestoreDocId(
                logical,
                uID,
              );
              batch.set(
                AppFirestore.instance.collection('units').doc(uDoc),
                {
                  'blockName': phyBlock,
                  'unitNumber': uID,
                  'floorNo': f,
                  'isOccupied': false,
                  'societyId': sid,
                },
              );
            }
          }
        } else {
          for (int i = b['v1']; i <= b['v2']; i++) {
            final uDoc = SocietyService.instance.unitFirestoreDocId(
              logical,
              i.toString(),
            );
            batch.set(
              AppFirestore.instance.collection('units').doc(uDoc),
              {
                'blockName': phyBlock,
                'unitNumber': i.toString(),
                'floorNo': 0,
                'isOccupied': false,
                'societyId': sid,
              },
            );
          }
        }
      }

      await batch.commit();
      _tempBlocks.clear();
      widget.onSetupComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("સેટઅપમાં ભૂલ: $e", Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("સોસાયટી અને યુનિટ્સ સેટઅપ થઈ રહ્યા છે..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("સોસાયટી સેટઅપ વિઝાર્ડ")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ચેતવણી બોક્સ
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: cs.error,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ચેતવણી: આર્કિટેક્ચર પ્રકાર કાયમી રહેશે. ઓછામાં ઓછી એક વિંગ અથવા શેરી ઉમેરવી ફરજિયાત છે.",
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _sNameC,
                decoration: const InputDecoration(
                  labelText: "સોસાયટીનું નામ *",
                  hintText: "દા.ત. શાંતિવન રેસિડેન્સી",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _wizardType,
                items: const [
                  DropdownMenuItem(
                    value: 'Wing',
                    child: Text("વિંગ સિસ્ટમ (A, B, C...)"),
                  ),
                  DropdownMenuItem(
                    value: 'Street',
                    child: Text("શેરી સિસ્ટમ (1, 2, 3...)"),
                  ),
                ],
                onChanged: _tempBlocks.isEmpty
                    ? (v) => setState(() => _wizardType = v!)
                    : null,
                decoration: InputDecoration(
                  labelText: "આર્કિટેક્ચર પ્રકાર",
                  border: const OutlineInputBorder(),
                  helperText: _tempBlocks.isNotEmpty
                      ? "બ્લોક ઉમેર્યા પછી પ્રકાર બદલી શકાશે નહીં"
                      : null,
                ),
              ),

              const Divider(height: 36, thickness: 1.5),
              Text(
                "બ્લોક ઉમેરો (${_wizardType == 'Wing' ? 'વિંગ' : 'શેરી'} વિગતો)",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _bNameC,
                decoration: InputDecoration(
                  labelText: _wizardType == 'Wing'
                      ? "વિંગ નામ (દા.ત. A)"
                      : "શેરી નંબર (દા.ત. 1)",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _v1C,
                      decoration: InputDecoration(
                        labelText: _wizardType == 'Wing'
                            ? "કુલ માળ"
                            : "શરૂઆત નંબર",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _v2C,
                      decoration: InputDecoration(
                        labelText: _wizardType == 'Wing'
                            ? "માળ દીઠ ઘર"
                            : "છેલ્લો નંબર",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _addBlockToList,
                  icon: const Icon(Icons.add),
                  label: const Text("લિસ્ટમાં બ્લોક ઉમેરો"),
                ),
              ),

              const SizedBox(height: 20),

              if (_tempBlocks.isNotEmpty) ...[
                const Text(
                  "ઉમેરેલા બ્લોક્સ:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tempBlocks.length,
                  itemBuilder: (context, index) {
                    final b = _tempBlocks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(b['name'].toString().substring(0, 1)),
                        ),
                        title: Text("$_wizardType: ${b['name']}"),
                        subtitle: Text(
                          _wizardType == 'Wing'
                              ? "${b['v1']} માળ, ${b['v2']} ઘર/માળ"
                              : "નંબર: ${b['v1']} થી ${b['v2']}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _tempBlocks.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
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
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text("આર્કિટેક્ચર પ્રિવ્યુ જુઓ"),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _executeFinalInitialSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                  ),
                  child: const Text(
                    "ફાઈનલ સેટઅપ પૂર્ણ કરો",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
