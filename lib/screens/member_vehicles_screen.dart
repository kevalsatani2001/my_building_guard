import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/parking_slot_service.dart';
import '../services/society_service.dart';
import '../widgets/parking_slot_selector_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'member_complaint_register_screen.dart';
import '../widgets/premium_app_bar.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class MemberVehiclesScreen extends StatefulWidget {
  const MemberVehiclesScreen({super.key});

  @override
  State<MemberVehiclesScreen> createState() => _MemberVehiclesScreenState();
}

class _MemberVehiclesScreenState extends State<MemberVehiclesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateC = TextEditingController();
  final _modelC = TextEditingController();
  String? _selectedSlot;

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
    super.dispose();
  }

  Future<void> _openSlotPicker({
    required String targetBlock,
    required bool isCommonPlotOnly,
  }) async {
    HapticFeedback.lightImpact();
    final picked = await ParkingSlotSelectorSheet.show(
      context,
      initialSlot: _selectedSlot,
      targetBlock: targetBlock,
      isCommonPlotOnly: isCommonPlotOnly,
      vehicleType: _selectedType,
      vehiclePlate: _plateC.text.trim().toUpperCase(),
    );

    if (picked != null && picked.isNotEmpty) {
      setState(() => _selectedSlot = picked);
    }
  }

  Future<void> _addVehicle({
    required String societyId,
    required bool isStreet,
    required String memberBlock,
    required String flatDisplay,
    required String userName,
    required List userVehicles,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final validationRes = VehiclePlateValidator.validate(_plateC.text);
    if (!validationRes.isValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationRes.errorMessage ?? 'અમાન્ય વાહન નંબર પ્લેટ!'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final plate = validationRes.formattedPlate!;
    final cleanPlate = validationRes.cleanPlate!;

    // ૧. પોતાના લિસ્ટમાં આ વાહન પહેલેથી છે કે નહીં તેની ચકાસણી
    final isAlreadyInUserVehicles = userVehicles.any((item) {
      final existingClean = VehiclePlateValidator.clean((item['number'] ?? '').toString());
      return existingClean == cleanPlate;
    });
    if (isAlreadyInUserVehicles) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('આ નંબર પ્લેટ ($plate) વાળું વાહન તમારી પ્રોફાઇલમાં પહેલેથી જ છે!'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ૨. સોસાયટીમાં અન્ય કોઈ સભ્યએ આ જ વાહન નંબર રજીસ્ટર કરેલ છે કે નહીં તેની ચકાસણી
    try {
      final occSnap = await ParkingSlotService.instance.streamOccupiedSlots(societyId).first;
      for (final entry in occSnap.values) {
        final otherClean = VehiclePlateValidator.clean(entry.vehicleNumber);
        if (otherClean == cleanPlate && entry.ownerUid != uid) {
          HapticFeedback.heavyImpact();
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('વાહન પહેલેથી નોંધાયેલ છે', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'વાહન નંબર "$plate" સોસાયટીમાં સભ્ય ${entry.ownerName} (${entry.flatDisplay}) દ્વારા પહેલેથી જ રજીસ્ટર થયેલું છે.\n\nજો આ તમારું જ વાહન હોય તો સોસાયટી એડમિનનો સંપર્ક કરો.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('સમજાઈ ગયું', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
      }
    } catch (_) {}

    final defaultHomeFront = '🏠 ઘર આંગણે ($flatDisplay)';
    final chosenSlot = isStreet
        ? ((_selectedSlot != null && _selectedSlot!.isNotEmpty)
            ? _selectedSlot!.trim().toUpperCase()
            : defaultHomeFront)
        : (_selectedSlot?.trim().toUpperCase() ?? '');

    // For apartment members: if slots exist for their wing, slot selection is required
    if (!isStreet && chosenSlot.isEmpty) {
      try {
        final existingSlots = await ParkingSlotService.instance
            .streamRealSlotsForBlock(societyId: societyId, blockName: memberBlock)
            .first;
        if (existingSlots.isNotEmpty) {
          HapticFeedback.mediumImpact();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('કૃપા કરીને વિંગ "$memberBlock" માટે ઉપલબ્ધ પાર્કિંગ સ્લોટ પસંદ કરો!'),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } catch (_) {}
    }

    // Check if slot is taken (only if not flexible street parking)
    if (chosenSlot.isNotEmpty && !ParkingSlotService.instance.isFlexibleStreetParking(chosenSlot)) {
      setState(() => _isAdding = true);
      try {
        final occSnap = await ParkingSlotService.instance.streamOccupiedSlots(societyId).first;
        if (ParkingSlotService.instance.isSlotAlreadyTakenByOther(
          slotName: chosenSlot,
          occupiedSlots: occSnap,
        )) {
          final occInfo = occSnap[chosenSlot];
          setState(() => _isAdding = false);
          if (!mounted) return;
          _showSlotAlreadyTakenDialog(chosenSlot, occInfo);
          return;
        }
      } catch (_) {
        // Continue if stream snapshot check fails
      }
    }

    setState(() => _isAdding = true);

    try {
      final model = _modelC.text.trim();

      final newVehicle = {
        'number': plate,
        'type': _selectedType,
        'model': model,
        'slot': chosenSlot,
        'addedAt': DateTime.now().toIso8601String(),
      };

      await AppFirestore.instance.collection('users').doc(uid).update({
        'vehicles': FieldValue.arrayUnion([newVehicle]),
      });

      // Synchronize with Firestore parking_slots collection if real slot
      if (!ParkingSlotService.instance.isFlexibleStreetParking(chosenSlot)) {
        await ParkingSlotService.instance.markSlotAssignedInFirestore(
          societyId: societyId,
          slotNumber: chosenSlot,
          memberUid: uid,
          memberName: userName,
          flatDisplay: flatDisplay,
          vehiclePlate: plate,
          vehicleModel: model,
          vehicleType: _selectedType,
        );
      }

      _plateC.clear();
      _modelC.clear();
      _selectedSlot = null;

      setState(() {
        _isAdding = false;
        _showAddForm = false;
      });

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chosenSlot.isNotEmpty
                      ? 'વાહન સફળતાપૂર્વક નોંધાઈ ગયું અને પાર્કિંગ સ્લોટ "$chosenSlot" ફાળવાઈ ગયો છે.'
                      : 'વાહન સફળતાપૂર્વક નોંધાઈ ગયું.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      setState(() => _isAdding = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('વાહન નોંધવામાં ભૂલ: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSlotAlreadyTakenDialog(String slot, OccupiedSlotInfo? occInfo) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'સ્લોટ પહેલેથી બુક છે!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'પાર્કિંગ સ્લોટ "$slot" પહેલેથી અન્ય સભ્યને ફાળવાયેલો છે. સોસાયટી નિયમ મુજબ એક સ્લોટ માત્ર એક જ વાહનને ફાળવી શકાય છે.',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 12),
            if (occInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ફાળવેલ ફ્લેટ: ${occInfo.flatDisplay}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 3),
                    Text('• વાહન: ${occInfo.vehicleNumber} (${occInfo.vehicleModel})', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'કૃપા કરીને અન્ય ખાલી (લીલો) સ્લોટ પસંદ કરો.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('અન્ય સ્લોટ પસંદ કરો'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteVehicle(String societyId, Map<String, dynamic> vehicle) async {
    final plate = (vehicle['number'] ?? '').toString();
    final slot = (vehicle['slot'] ?? '').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 26),
            SizedBox(width: 8),
            Text('વાહન કાઢી નાખવું છે?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'વાહન નંબર $plate કાઢી નાખવાથી તેના માટે ફાળવેલ પાર્કિંગ સ્લોટ ${slot.isNotEmpty ? '"$slot"' : ''} ખાલી થઈ જશે અને અન્ય સભ્યો માટે ઉપલબ્ધ બનશે.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('રદ કરો', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('કાઢી નાખો'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await AppFirestore.instance.collection('users').doc(uid).update({
        'vehicles': FieldValue.arrayRemove([vehicle]),
      });

      if (slot.isNotEmpty && !ParkingSlotService.instance.isFlexibleStreetParking(slot)) {
        await ParkingSlotService.instance.releaseSlotInFirestore(
          societyId: societyId,
          slotNumber: slot,
        );
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$plate કાઢી નાખવામાં આવ્યું. સ્લોટ ખાલી થઈ ગયો છે.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _changeVehicleSlot({
    required String societyId,
    required bool isStreet,
    required String memberBlock,
    required String flatDisplay,
    required String userName,
    required Map<String, dynamic> vehicle,
  }) async {
    final currentSlot = (vehicle['slot'] ?? '').toString();
    final plate = (vehicle['number'] ?? '').toString();
    final type = (vehicle['type'] ?? '૪-વ્હીલર (કાર)').toString();

    final newSlot = await ParkingSlotSelectorSheet.show(
      context,
      initialSlot: currentSlot,
      targetBlock: memberBlock,
      isCommonPlotOnly: isStreet,
      vehicleType: type,
      vehiclePlate: plate,
    );

    if (newSlot == null || newSlot.isEmpty || newSlot == currentSlot) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isAdding = true);
    try {
      // 1. Release previous slot in Firestore if real slot
      if (currentSlot.isNotEmpty && !ParkingSlotService.instance.isFlexibleStreetParking(currentSlot)) {
        await ParkingSlotService.instance.releaseSlotInFirestore(
          societyId: societyId,
          slotNumber: currentSlot,
        );
      }

      // 2. Mark new slot assigned in Firestore if real slot
      if (!ParkingSlotService.instance.isFlexibleStreetParking(newSlot)) {
        await ParkingSlotService.instance.markSlotAssignedInFirestore(
          societyId: societyId,
          slotNumber: newSlot,
          memberUid: uid,
          memberName: userName,
          flatDisplay: flatDisplay,
          vehiclePlate: plate,
          vehicleModel: (vehicle['model'] ?? '').toString(),
          vehicleType: type,
        );
      }

      // 3. Update vehicle object in user's vehicles list in Firestore
      final userDoc = await AppFirestore.instance.collection('users').doc(uid).get();
      final currentVehicles = List<Map<String, dynamic>>.from(
        (userDoc.data()?['vehicles'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final updatedVehicles = currentVehicles.map((item) {
        if ((item['number'] ?? '').toString().toUpperCase() == plate.toUpperCase()) {
          return {
            ...item,
            'slot': newSlot,
            'slotUpdatedAt': DateTime.now().toIso8601String(),
          };
        }
        return item;
      }).toList();

      await AppFirestore.instance.collection('users').doc(uid).update({
        'vehicles': updatedVehicles,
      });

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('વાહન $plate માટે સ્લોટ બદલીને "$newSlot" સફળતાપૂર્વક અપડેટ થઈ ગયો!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સ્લોટ બદલવામાં ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _openParkingIssueSheet({
    required String societyId,
    required Map<String, dynamic> vehicle,
    required String memberBlock,
    required String flatDisplay,
    required String userName,
    required bool isStreet,
  }) {
    final plate = (vehicle['number'] ?? '').toString();
    final slot = (vehicle['slot'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ParkingIssueBottomSheet(
        societyId: societyId,
        vehiclePlate: plate,
        assignedSlot: slot,
        flatDisplay: flatDisplay,
        userName: userName,
        onChangeSlot: () => _changeVehicleSlot(
          societyId: societyId,
          isStreet: isStreet,
          memberBlock: memberBlock,
          flatDisplay: flatDisplay,
          userName: userName,
          vehicle: vehicle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final societyId = SocietyService.instance.societyId;

    return StreamBuilder<DocumentSnapshot>(
      stream: AppFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final rawBlock = userData['blockName']?.toString() ?? '';
        final memberBlock = SocietyService.instance.logicalBlockName(rawBlock);
        final unitNumber = userData['unitNumber']?.toString() ?? '';
        final flatDisplay = [memberBlock, unitNumber].where((s) => s.isNotEmpty).join(' • ');
        final userName = (userData['name'] ?? 'સભ્ય').toString();
        final List vehicles = List.from(userData['vehicles'] ?? []);

        return StreamBuilder<DocumentSnapshot>(
          stream: SocietyService.instance.societySettingsDoc(AppFirestore.instance).snapshots(),
          builder: (context, settingsSnap) {
            final settingsData = settingsSnap.data?.data() as Map<String, dynamic>? ?? {};
            final societyArchType = (settingsData['architectureType'] ?? 'Wing').toString();

            // Accurate Architecture Check:
            // Flat / Apartment: societyArchType == 'Wing' (Default for buildings).
            // Street / Row House: ONLY IF societyArchType is explicitly 'Street' or block contains 'શેરી'.
            final isStreet = societyArchType == 'Street' ||
                (societyArchType != 'Wing' &&
                    (memberBlock.contains('શેરી') ||
                        RegExp(r'\bstreet\b', caseSensitive: false).hasMatch(memberBlock)));

            // If flat member, reset any lingering street/common-plot slot selection
            if (!isStreet &&
                _selectedSlot != null &&
                (ParkingSlotService.instance.isFlexibleStreetParking(_selectedSlot!) ||
                    _selectedSlot!.startsWith('CP-') ||
                    _selectedSlot!.startsWith('વાડી-'))) {
              _selectedSlot = null;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: const PremiumAppBar(
                title: 'મારા વાહનો & પાર્કિંગ સ્લોટ',
                subtitle: 'નંબર પ્લેટ, સ્લોટ એલોટમેન્ટ અને ડિજિટલ પાસ',
                icon: Icons.directions_car_rounded,
                accentColor: Color(0xFF0284C7),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    // 1. Ultra-Premium Hero Banner with Generated 3D Asset
                    _buildHeroBanner(vehicles.length, flatDisplay),

                    // 2. Add Vehicle Card (Toggle Form)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _showAddForm = !_showAddForm),
                              borderRadius: BorderRadius.circular(22),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.add_circle_rounded, color: Color(0xFF0284C7), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'નવું વાહન ઉમેરો & સ્લોટ ફાળવો',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isStreet
                                                ? 'શેરી સોસાયટી: ઘર આંગણે આપોઆપ સુરક્ષિત પાર્કિંગ'
                                                : 'બિલ્ડિંગ વિંગ $memberBlock ના માન્ય સ્લોટમાંથી પસંદ કરો',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _showAddForm ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 26),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (_showAddForm) ...[
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'વાહનનો પ્રકાર:',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
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
                                            color: isSelected ? Colors.white : const Color(0xFF334155),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 11.5,
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (_) => setState(() => _selectedType = t.$1),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),

                                    // Number Plate Input
                                    TextFormField(
                                      controller: _plateC,
                                      textCapitalization: TextCapitalization.characters,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      inputFormatters: [
                                        UpperCaseTextFormatter(),
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                                        LengthLimitingTextInputFormatter(16),
                                      ],
                                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                      decoration: InputDecoration(
                                        labelText: 'વાહન નંબર પ્લેટ *',
                                        hintText: 'દા.ત. GJ 01 AB 1234',
                                        helperText: 'ફોર્મેટ: GJ 01 AB 1234 અથવા 22 BH 1234 AA',
                                        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                      validator: (v) {
                                        final res = VehiclePlateValidator.validate(v);
                                        if (!res.isValid) {
                                          return res.errorMessage;
                                        }
                                        final cleanPlate = res.cleanPlate!;
                                        final isDuplicate = vehicles.any((item) {
                                          final existingClean = VehiclePlateValidator.clean((item['number'] ?? '').toString());
                                          return existingClean == cleanPlate;
                                        });
                                        if (isDuplicate) {
                                          return 'આ નંબર પ્લેટવાળું વાહન તમે પહેલેથી જ ઉમેરેલું છે!';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Model / Company Input
                                    TextFormField(
                                      controller: _modelC,
                                      decoration: InputDecoration(
                                        labelText: 'વાહન મોડેલ / કંપની',
                                        hintText: 'દા.ત. Swift / Activa / Nexon EV',
                                        prefixIcon: const Icon(Icons.car_repair_rounded, color: Color(0xFF0284C7)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 3. INTELLIGENT ARCHITECTURE-AWARE PARKING ALLOCATION
                                    if (isStreet) ...[
                                      // === શેરી / રો-હાઉસ સોસાયટી: ઘર આંગણે ડિફોલ્ટ ફાળવણી ===
                                      const Text(
                                        'સોસાયટી પાર્કિંગ વ્યવસ્થા:',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(height: 8),

                                      // Primary Home Front Card
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: (_selectedSlot == null ||
                                                  _selectedSlot!.isEmpty ||
                                                  ParkingSlotService.instance.isFlexibleStreetParking(_selectedSlot!))
                                              ? const Color(0xFFF0FDF4)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: (_selectedSlot == null ||
                                                    _selectedSlot!.isEmpty ||
                                                    ParkingSlotService.instance.isFlexibleStreetParking(_selectedSlot!))
                                                ? const Color(0xFF86EFAC)
                                                : const Color(0xFFCBD5E1),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF15803D).withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.home_work_rounded, color: Color(0xFF15803D), size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Text(
                                                        'ઘર આંગણે પાર્કિંગ (Home Front)',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 13.5,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      if (_selectedSlot == null ||
                                                          _selectedSlot!.isEmpty ||
                                                          ParkingSlotService.instance.isFlexibleStreetParking(_selectedSlot!))
                                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'તમારા પોતાના મકાન/પ્લોટ ($flatDisplay) ની સામે વાહન પાર્ક થશે.',
                                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    '✓ શેરી સોસાયટી: કોઈ સ્લોટ નંબર પસંદ કરવાની જરૂર નથી.',
                                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Optional Common Plot Section (Appears ONLY IF Admin created real common plot slots in Firestore)
                                      StreamBuilder<List<ParkingSlotModel>>(
                                        stream: ParkingSlotService.instance.streamRealCommonPlotSlots(societyId),
                                        builder: (context, slotSnap) {
                                          final commonSlots = slotSnap.data ?? [];
                                          if (commonSlots.isEmpty) {
                                            // Admin has NOT created Common Plot slots in Firestore.
                                            // Absolutely no fake static lists shown!
                                            return const SizedBox.shrink();
                                          }

                                          final isCpChosen = _selectedSlot != null &&
                                              (_selectedSlot!.startsWith('CP-') || _selectedSlot!.startsWith('વાડી-'));

                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isCpChosen ? const Color(0xFFF0FDF4) : Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isCpChosen ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.park_rounded,
                                                    size: 20,
                                                    color: isCpChosen ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          isCpChosen
                                                              ? 'કોમન પ્લોટ સ્લોટ: $_selectedSlot (પસંદ કરેલ)'
                                                              : 'સોસાયટી કોમન પ્લોટ / વાડી સ્લોટ',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12.5,
                                                            color: isCpChosen ? const Color(0xFF15803D) : const Color(0xFF334155),
                                                          ),
                                                        ),
                                                        Text(
                                                          isCpChosen
                                                              ? 'સોસાયટી કોમન પ્લોટમાં સ્લોટ સુરક્ષિત છે.'
                                                              : 'એડમિન દ્વારા મંજૂર થયેલ ${commonSlots.length} સ્લોટ્સ ઉપલબ્ધ (વૈકલ્પિક)',
                                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isCpChosen)
                                                    TextButton(
                                                      onPressed: () => setState(() => _selectedSlot = null),
                                                      child: const Text('ઘર આંગણે રાખો', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                                                    )
                                                  else
                                                    OutlinedButton(
                                                      onPressed: () => _openSlotPicker(
                                                        targetBlock: 'કોમન પ્લોટ',
                                                        isCommonPlotOnly: true,
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        side: const BorderSide(color: Color(0xFF0284C7)),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                      child: const Text('સ્લોટ પસંદ કરો', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      // === ફ્લેટ / એપાર્ટમેન્ટ: વિંગ સ્લોટ સિલેક્શન ફરજિયાત ===
                                      Text(
                                        'વિંગ $memberBlock પાર્કિંગ સ્લોટ:',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(height: 6),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _openSlotPicker(
                                            targetBlock: memberBlock,
                                            isCommonPlotOnly: false,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          child: Ink(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                  ? const Color(0xFFF0FDF4)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                    ? const Color(0xFF86EFAC)
                                                    : const Color(0xFFCBD5E1),
                                                width: 1.4,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                        ? const Color(0xFF15803D).withValues(alpha: 0.12)
                                                        : const Color(0xFF0284C7).withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.local_parking_rounded,
                                                    size: 20,
                                                    color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                        ? const Color(0xFF15803D)
                                                        : const Color(0xFF0284C7),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                            ? 'સ્લોટ: $_selectedSlot (લૉક માટે પસંદ કરેલ)'
                                                            : 'વિંગ $memberBlock સ્લોટ પસંદ કરો (Tap to Select)',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13.5,
                                                          color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                              ? const Color(0xFF15803D)
                                                              : const Color(0xFF334155),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                            ? 'વિંગ $memberBlock • સ્લોટ બદલવા ટેપ કરો'
                                                            : 'એડમિન દ્વારા બનાવેલા રીઅલ સ્લોટ્સમાંથી પસંદ કરો',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  size: 14,
                                                  color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                      ? const Color(0xFF15803D)
                                                      : const Color(0xFF94A3B8),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    // Save Vehicle Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: _isAdding
                                            ? null
                                            : () => _addVehicle(
                                                  societyId: societyId,
                                                  isStreet: isStreet,
                                                  memberBlock: memberBlock,
                                                  flatDisplay: flatDisplay,
                                                  userName: userName,
                                                  userVehicles: vehicles,
                                                ),
                                        icon: _isAdding
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Icon(Icons.add_task_rounded, color: Colors.white),
                                        label: Text(
                                          _isAdding ? 'નોંધાઈ રહ્યું છે...' : 'વાહન & સ્લોટ સાચવો',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
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
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 4. Registered Vehicles List or 3D Empty State
                    if (vehicles.isEmpty)
                      _buildEmptyState()
                    else
                      _buildRegisteredVehiclesList(
                        societyId: societyId,
                        vehicles: vehicles,
                        memberBlock: memberBlock,
                        isStreet: isStreet,
                        flatDisplay: flatDisplay,
                        userName: userName,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroBanner(int vehicleCount, String flatDisplay) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Generated 3D Asset
            Image.asset(
              'assets/images/parking_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Gradient Overlay for Maximum Readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B192C).withValues(alpha: 0.92),
                    const Color(0xFF0F172A).withValues(alpha: 0.75),
                    const Color(0xFF0284C7).withValues(alpha: 0.3),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              flatDisplay.isNotEmpty ? flatDisplay : 'સોસાયટી સભ્ય',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ગેટ સિક્યોરિટી એક્ટિવ',
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'સ્માર્ટ સોસાયટી પાર્કિંગ ગાર્ડ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'નોંધાયેલા વાહનો: $vehicleCount • સિંગલ-અસાઇનમેન્ટ સ્લોટ પ્રોટેક્શન',
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            // Generated 3D Vehicle Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/vehicle_3d_icon.jpg',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.directions_car_rounded,
                  size: 64,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'હજુ કોઈ વાહન નોંધાયેલ નથી',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'ઉપરના "+ નવું વાહન ઉમેરો" પર ક્લિક કરી તમારી કાર/બાઇક અને ફાળવેલ પાર્કિંગ સ્લોટ સાચવો.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredVehiclesList({
    required String societyId,
    required List vehicles,
    required String memberBlock,
    required bool isStreet,
    required String flatDisplay,
    required String userName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.garage_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Text(
                'નોંધાયેલા વાહનો (${vehicles.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              const Text(
                '૧ સ્લોટ = ૧ વાહન',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final v = Map<String, dynamic>.from(vehicles[index] as Map);
              final number = (v['number'] ?? '').toString();
              final type = (v['type'] ?? 'કાર').toString();
              final model = (v['model'] ?? '').toString();
              final slot = (v['slot'] ?? '').toString();

              final isBike = type.contains('૨') || type.toLowerCase().contains('bike');
              final isEV = type.contains('EV') || type.contains('ઇલેક્ટ્રિક');
              final vehicleIcon = isEV
                  ? Icons.electric_car_rounded
                  : (isBike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Vehicle Type Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isEV
                                    ? [const Color(0xFF0D9488), const Color(0xFF14B8A6)]
                                    : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(vehicleIcon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),

                          // Vehicle Plate & Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Realistic License Plate Badge with 1-Tap Copy
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: number));
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'વાહન નંબર કોપી થયો: $number',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: const Color(0xFF0F172A),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Tooltip(
                                    message: 'નંબર કોપી કરવા માટે ક્લિક કરો',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D4ED8),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'IND',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            number,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                              letterSpacing: 0.6,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.copy_rounded,
                                            size: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    if (model.isNotEmpty) ...[
                                      Text(
                                        model,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      type,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Delete Action
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                            tooltip: 'વાહન કાઢી નાખો',
                            onPressed: () => _confirmDeleteVehicle(societyId, v),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Slot Allocation Bar with Action Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_parking_rounded, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      slot.isNotEmpty ? 'સ્લોટ: $slot' : 'કોઈ સ્લોટ ફાળવેલ નથી',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: slot.isNotEmpty ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (slot.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          'સુરક્ષિત લૉક',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Change Slot Action Button
                              InkWell(
                                onTap: () => _changeVehicleSlot(
                                  societyId: societyId,
                                  isStreet: isStreet,
                                  memberBlock: memberBlock,
                                  flatDisplay: flatDisplay,
                                  userName: userName,
                                  vehicle: v,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF0284C7)),
                                      SizedBox(width: 4),
                                      Text(
                                        'સ્લોટ બદલો',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Parking Dispute / Issue Resolution Bar
                          if (slot.isNotEmpty && !ParkingSlotService.instance.isFlexibleStreetParking(slot)) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _openParkingIssueSheet(
                                societyId: societyId,
                                vehicle: v,
                                memberBlock: memberBlock,
                                flatDisplay: flatDisplay,
                                userName: userName,
                                isStreet: isStreet,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.report_problem_rounded, size: 14, color: Color(0xFFDC2626)),
                                    SizedBox(width: 6),
                                    Text(
                                      'સ્લોટમાં સમસ્યા છે? (અન્ય વાહન / ફરિયાદ)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                    ),
                                    Spacer(),
                                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFDC2626)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// પાર્કિંગ સ્લોટ સમસ્યા નિવારણ (ખોટું પાર્કિંગ, વોચમેન એલર્ટ, ફરિયાદ)
class _ParkingIssueBottomSheet extends StatefulWidget {
  final String societyId;
  final String vehiclePlate;
  final String assignedSlot;
  final String flatDisplay;
  final String userName;
  final VoidCallback onChangeSlot;

  const _ParkingIssueBottomSheet({
    required this.societyId,
    required this.vehiclePlate,
    required this.assignedSlot,
    required this.flatDisplay,
    required this.userName,
    required this.onChangeSlot,
  });

  @override
  State<_ParkingIssueBottomSheet> createState() => _ParkingIssueBottomSheetState();
}

class _ParkingIssueBottomSheetState extends State<_ParkingIssueBottomSheet> {
  final _wrongPlateC = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isNotifying = false;
  OccupiedSlotInfo? _foundOwner;

  @override
  void dispose() {
    _wrongPlateC.dispose();
    super.dispose();
  }

  Future<void> _searchOwner() async {
    final raw = _wrongPlateC.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને વાહન નંબર પ્લેટ લખો!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final clean = VehiclePlateValidator.clean(raw);
    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _foundOwner = null;
    });

    try {
      final occSnap = await ParkingSlotService.instance.streamOccupiedSlots(widget.societyId).first;
      OccupiedSlotInfo? match;
      for (final entry in occSnap.values) {
        if (VehiclePlateValidator.clean(entry.vehicleNumber) == clean) {
          match = entry;
          break;
        }
      }

      setState(() {
        _foundOwner = match;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સર્ચ કરવામાં ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _notifyOwner() async {
    if (_foundOwner == null) return;
    setState(() => _isNotifying = true);

    try {
      final title = '🚨 પાર્કિંગ સ્લોટ ખાલી કરવાની વિનંતી';
      final body =
          'તમારું વાહન (${_foundOwner!.vehicleNumber}) સભ્ય ${widget.flatDisplay} ના પાર્કિંગ સ્લોટ (${widget.assignedSlot}) માં પાર્ક થયેલું છે. કૃપા કરીને તેને તાત્કાલિક યોગ્ય જગ્યાએ હટાવો.';

      await AppFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'targetUID': _foundOwner!.ownerUid,
        'targetRole': 'member',
        'societyId': widget.societyId,
        'type': 'parking_alert',
        'senderName': widget.userName,
        'senderFlat': widget.flatDisplay,
        'senderUid': FirebaseAuth.instance.currentUser?.uid,
        'slot': widget.assignedSlot,
        'vehicleNumber': _foundOwner!.vehicleNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('સભ્ય ${_foundOwner!.ownerName} (${_foundOwner!.flatDisplay}) ને સીધું એલર્ટ મોકલી દીધું છે! એડમિનને ખલેલ પહોંચાડ્યા વગર સીધું સોલ્યુશન.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('એલર્ટ મોકલવામાં ભૂલ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isNotifying = false);
    }
  }

  Future<void> _notifyWatchman() async {
    final raw = _wrongPlateC.text.trim().toUpperCase();
    if (raw.isEmpty) return;
    setState(() => _isNotifying = true);

    try {
      final title = '🚨 અનધિકૃત વાહન પાર્કિંગ એલર્ટ';
      final body =
          'સભ્ય ${widget.flatDisplay} ના પાર્કિંગ સ્લોટ (${widget.assignedSlot}) માં અજાણ્યું વાહન ($raw) ખોટી જગ્યાએ પાર્ક છે. કૃપા કરીને તપાસ કરી તાત્કાલિક હટાવો.';

      await AppFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'societyId': widget.societyId,
        'type': 'parking_alert',
        'targetRole': 'watchman',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('સિક્યોરિટી ગાર્ડ / વૉચમેનને સ્લોટ ${widget.assignedSlot} અંગે એલર્ટ મોકલી દીધું છે!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('એલર્ટ મોકલવામાં ભૂલ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isNotifying = false);
    }
  }

  void _callOwner(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'પાર્કિંગ સ્લોટ સમસ્યા નિવારણ',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'સ્લોટ: ${widget.assignedSlot} • વાહન: ${widget.vehiclePlate}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // SECTION 1: કોઈ અન્ય વ્યક્તિએ મારો સ્લોટ રોક્યો છે
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.car_crash_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'મારા સ્લોટમાં અન્ય વાહન પાર્ક છે',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ખોટી જગ્યાએ પાર્ક થયેલ વાહન નંબર દાખલ કરી તપાસ કરો:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wrongPlateC,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            UpperCaseTextFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'દા.ત. GJ 01 AB 1234',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.pin_rounded, size: 18, color: Color(0xFFDC2626)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchOwner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        child: _isSearching
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('તપાસ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ],
                  ),

                  // Search Result: Found Society Resident
                  if (_hasSearched && _foundOwner != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'વાહન માલિક: ${_foundOwner!.ownerName}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D)),
                              ),
                              const Spacer(),
                              Text(
                                'ફ્લેટ: ${_foundOwner!.flatDisplay}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Number plate badge with 1-tap copy
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _foundOwner!.vehicleNumber));
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('વાહન નંબર કોપી થયો: ${_foundOwner!.vehicleNumber}'),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF0F172A),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D4ED8),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text('IND', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _foundOwner!.vehicleNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_foundOwner!.ownerPhone.isNotEmpty)
                                InkWell(
                                  onTap: () => _callOwner(_foundOwner!.ownerPhone),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'કૉલ: ${_foundOwner!.ownerPhone}',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isNotifying ? null : _notifyOwner,
                              icon: const Icon(Icons.notification_important_rounded, size: 16, color: Colors.white),
                              label: const Text('માલિકને ગાડી હટાવવાનું એલર્ટ મોકલો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.shield_outlined, size: 13, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'આ નોટિફિકેશન સીધું વાહન માલિકને જશે (એડમિનને નહીં, જેથી આપસી સમજણથી તાત્કાલિક ગાડી હટી શકે).',
                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search Result: Not Found in Society Residents (Visitor)
                  if (_hasSearched && _foundOwner == null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'આ વાહન સોસાયટીના કોઈ સભ્યનું નથી (વિઝિટર/મહેમાનનું હોઈ શકે છે).',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isNotifying ? null : _notifyWatchman,
                              icon: const Icon(Icons.shield_rounded, size: 16, color: Colors.white),
                              label: const Text('સિક્યોરિટી / વૉચમેનને તાત્કાલિક જાણ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            const SizedBox(height: 14),

            // SECTION 2: અન્ય સમસ્યાઓ (ફરિયાદ / સ્લોટ બદલવો)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberComplaintRegisterScreen(
                            memberName: widget.userName,
                            memberFlat: widget.flatDisplay,
                            initialCategory: 'પાર્કિંગ વિવાદ',
                            initialTitle: 'પાર્કિંગ સ્લોટ ${widget.assignedSlot} અંગે સમસ્યા',
                            initialDesc: 'મારા ફાળવેલા સ્લોટ ${widget.assignedSlot} (વાહન: ${widget.vehiclePlate}) માં નીચે મુજબની સમસ્યા છે:\n',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_late_rounded, size: 16, color: Color(0xFF7C3AED)),
                    label: const Text(
                      'પાર્કિંગ ફરિયાદ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      backgroundColor: const Color(0xFFF5F3FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onChangeSlot();
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF0284C7)),
                    label: const Text(
                      'સ્લોટ બદલો',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      backgroundColor: const Color(0xFFF0F9FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
