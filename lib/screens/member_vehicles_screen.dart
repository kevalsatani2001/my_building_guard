import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberVehiclesScreen extends StatefulWidget {
  const MemberVehiclesScreen({super.key});

  @override
  State<MemberVehiclesScreen> createState() => _MemberVehiclesScreenState();
}

class _MemberVehiclesScreenState extends State<MemberVehiclesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateC = TextEditingController();
  final _modelC = TextEditingController();
  final _slotC = TextEditingController();

  String _selectedType = '૪-વ્હીલર (કાર)';
  bool _isAdding = false;
  bool _showAddForm = false;

  final List<(String, IconData)> _types = [
    ('૪-વ્હીલર (કાર)', Icons.directions_car_rounded),
    ('૨-વ્હીલર (બાઇક/સ્કૂટર)', Icons.two_wheeler_rounded),
    ('⚡ ઇલેક્ટ્રિક EV', Icons.electric_car_rounded),
    ('અન્ય વાહન', Icons.airport_shuttle_rounded),
  ];

  @override
  void dispose() {
    _plateC.dispose();
    _modelC.dispose();
    _slotC.dispose();
    super.dispose();
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isAdding = true);

    try {
      final newVehicle = {
        'number': _plateC.text.trim().toUpperCase(),
        'type': _selectedType,
        'model': _modelC.text.trim(),
        'slot': _slotC.text.trim().toUpperCase(),
        'addedAt': DateTime.now().toIso8601String(),
      };

      await AppFirestore.instance.collection('users').doc(uid).update({
        'vehicles': FieldValue.arrayUnion([newVehicle]),
      });

      _plateC.clear();
      _modelC.clear();
      _slotC.clear();

      setState(() {
        _isAdding = false;
        _showAddForm = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('વાહન સફળતાપૂર્વક નોંધાઈ ગયું.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isAdding = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('વાહન નોંધવામાં ભૂલ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteVehicle(Map<String, dynamic> vehicle) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await AppFirestore.instance.collection('users').doc(uid).update({
        'vehicles': FieldValue.arrayRemove([vehicle]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vehicle['number']} કાઢી નાખવામાં આવ્યું.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'મારા વાહનો & પાર્કિંગ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Modern Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'સોસાયટી વ્હીકલ ગાર્ડ',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ગેટ ઓટો-એન્ટ્રી અને ફાળવેલ પાર્કિંગ સ્લોટ મેનેજ કરો.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Add Vehicle Form Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'નવું વાહન ઉમેરો',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_showAddForm ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                            color: const Color(0xFF0284C7)),
                        onPressed: () => setState(() => _showAddForm = !_showAddForm),
                      ),
                    ],
                  ),
                  if (_showAddForm) ...[
                    const Divider(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'વાહનનો પ્રકાર:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _types.map((t) {
                              final isSelected = _selectedType == t.$1;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(t.$2, size: 14, color: isSelected ? Colors.white : const Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(t.$1),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF0284C7),
                                backgroundColor: const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (_) => setState(() => _selectedType = t.$1),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _plateC,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'વાહન નંબર પ્લેટ *',
                              hintText: 'દા.ત. GJ 01 AB 1234',
                              prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'નંબર પ્લેટ દાખલ કરો' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _modelC,
                                  decoration: InputDecoration(
                                    labelText: 'મોડેલ / કંપની',
                                    hintText: 'દા.ત. Swift / Activa',
                                    prefixIcon: const Icon(Icons.car_repair_rounded, color: Color(0xFF0284C7)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _slotC,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'પાર્કિંગ સ્લોટ',
                                    hintText: 'દા.ત. P-14',
                                    prefixIcon: const Icon(Icons.local_parking_rounded, color: Color(0xFF0284C7)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isAdding ? null : _addVehicle,
                              icon: _isAdding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_rounded, color: Colors.white),
                              label: Text(
                                _isAdding ? 'નોંધાઈ રહ્યું છે...' : 'વાહન સાચવો',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Registered Vehicles Stream
            StreamBuilder<DocumentSnapshot>(
              stream: AppFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final List vehicles = List.from(data['vehicles'] ?? []);

                if (vehicles.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'હજુ કોઈ વાહન નોંધાયેલ નથી',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ઉપરના બટન પર ક્લિક કરીને તમારી કાર કે બાઇક ઉમેરો.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'નોંધાયેલા વાહનો (${vehicles.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final v = Map<String, dynamic>.from(vehicles[index] as Map);
                          final number = (v['number'] ?? '').toString();
                          final type = (v['type'] ?? 'કાર').toString();
                          final model = (v['model'] ?? '').toString();
                          final slot = (v['slot'] ?? '').toString();
                          final isCar = type.contains('૪') || type.toLowerCase().contains('car');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  child: Icon(
                                    isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                                    color: const Color(0xFF0284C7),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        number,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          if (model.isNotEmpty) ...[
                                            Text(
                                              model,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (slot.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'સ્લોટ: $slot',
                                                style: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                                  tooltip: 'વાહન કાઢી નાખો',
                                  onPressed: () => _deleteVehicle(v),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
