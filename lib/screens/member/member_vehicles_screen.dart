import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/parking_slot_service.dart';
import '../../services/society_service.dart';
import '../../widgets/parking_slot_selector_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'member_complaint_register_screen.dart';
import '../../widgets/premium_app_bar.dart';

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

  String _selectedType = '૪-વ્હીલર (કાર)'.tr;
  bool _isAdding = false;
  bool _showAddForm = false;

  final List<(String, String, IconData, Color)> _vehicleTypeOptions = [
    ('૪-વ્હીલર (કાર)'.tr, 'કાર / SUV'.tr, Icons.directions_car_filled_rounded, Color(0xFF0284C7)),
    ('૨-વ્હીલર (બાઇક/સ્કૂટર)'.tr, 'બાઇક / સ્કૂટર'.tr, Icons.two_wheeler_rounded, Color(0xFF0D9488)),
    ('ઇલેક્ટ્રિક વાહન (EV)'.tr, 'ઇલેક્ટ્રિક EV'.tr, Icons.electric_car_rounded, Color(0xFF10B981)),
    ('અન્ય વાહન'.tr, 'કોમર્શિયલ / અન્ય'.tr, Icons.local_shipping_rounded, Color(0xFF6366F1)),
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
          content: Text(validationRes.errorMessage ?? 'અમાન્ય વાહન નંબર પ્લેટ!'.tr),
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
          content: Text('આ નંબર પ્લેટ ($plate) વાળું વાહન તમારી પ્રોફાઇલમાં પહેલેથી જ છે!'.tr),
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
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('વાહન પહેલેથી નોંધાયેલ છે'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'વાહન નંબર "$plate" સોસાયટીમાં સભ્ય ${entry.ownerName} (${entry.flatDisplay}) દ્વારા પહેલેથી જ રજીસ્ટર થયેલું છે.\n\nજો આ તમારું જ વાહન હોય તો સોસાયટી એડમિનનો સંપર્ક કરો.'.tr,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('સમજાઈ ગયું'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
      }
    } catch (_) {}

    final defaultHomeFront = '🏠 ઘર આંગણે ($flatDisplay)'.tr;
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
              content: Text('કૃપા કરીને વિંગ "$memberBlock" માટે ઉપલબ્ધ પાર્કિંગ સ્લોટ પસંદ કરો!'.tr),
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
        if (ParkingSlotService.instance.isSlotAlreadyTaken(
          slotName: chosenSlot,
          occupiedSlots: occSnap,
          currentVehiclePlate: plate,
        )) {
          final normKey = ParkingSlotService.normalizeSlotKey(chosenSlot);
          final occInfo = occSnap[chosenSlot] ?? occSnap[normKey];
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
                      ? 'વાહન સફળતાપૂર્વક નોંધાઈ ગયું અને પાર્કિંગ સ્લોટ "$chosenSlot" ફાળવાઈ ગયો છે.'.tr
                      : 'વાહન સફળતાપૂર્વક નોંધાઈ ગયું.'.tr,
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
          content: Text('વાહન નોંધવામાં ભૂલ: $e'.tr),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSlotAlreadyTakenDialog(String slot, OccupiedSlotInfo? occInfo) {
    HapticFeedback.heavyImpact();
    final bool isMyOwn = occInfo?.isCurrentMember == true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: isMyOwn ? const Color(0xFFD97706) : const Color(0xFFDC2626), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMyOwn ? 'સ્લોટ તમારા અન્ય વાહન પાસે છે!'.tr : 'સ્લોટ પહેલેથી બુક છે!'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMyOwn
                  ? 'પાર્કિંગ સ્લોટ "$slot" પહેલેથી તમારા વાહન (${occInfo?.vehicleNumber}) માટે ફાળવાયેલો છે. સોસાયટી નિયમ મુજબ એક સ્લોટ માત્ર એક જ વાહનને ફાળવી શકાય છે.'.tr
                  : 'પાર્કિંગ સ્લોટ "$slot" પહેલેથી અન્ય સભ્યને ફાળવાયેલો છે. સોસાયટી નિયમ મુજબ એક સ્લોટ માત્ર એક જ વાહનને ફાળવી શકાય છે.'.tr,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 12),
            if (occInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMyOwn ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isMyOwn ? const Color(0xFFFDE68A) : const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ફાળવેલ ફ્લેટ: ${occInfo.flatDisplay}'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 3),
                    Text('• વાહન: ${occInfo.vehicleNumber} (${occInfo.vehicleModel})'.tr, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'કૃપા કરીને અન્ય ખાલી (લીલો) સ્લોટ પસંદ કરો.'.tr,
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
            child: Text('અન્ય સ્લોટ પસંદ કરો'.tr),
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
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 26),
            SizedBox(width: 8),
            Text('વાહન કાઢી નાખવું છે?'.tr, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'વાહન નંબર $plate કાઢી નાખવાથી તેના માટે ફાળવેલ પાર્કિંગ સ્લોટ ${slot.isNotEmpty ? '.tr"$slot"' : ''} ખાલી થઈ જશે અને અન્ય સભ્યો માટે ઉપલબ્ધ બનશે.'.tr,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('રદ કરો'.tr, style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('કાઢી નાખો'.tr),
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
          content: Text('$plate કાઢી નાખવામાં આવ્યું. સ્લોટ ખાલી થઈ ગયો છે.'.tr),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'.tr), backgroundColor: Colors.red),
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
    final type = (vehicle['type'] ?? '૪-વ્હીલર (કાર)'.tr).toString();

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
          content: Text('વાહન $plate માટે સ્લોટ બદલીને "$newSlot" સફળતાપૂર્વક અપડેટ થઈ ગયો!'.tr),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સ્લોટ બદલવામાં ભૂલ આવી: $e'.tr), backgroundColor: Colors.red),
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
        final userName = (userData['name'] ?? 'સભ્ય'.tr).toString();
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
                    (memberBlock.contains('શેરી'.tr) ||
                        RegExp(r'\bstreet\b', caseSensitive: false).hasMatch(memberBlock)));

            // If flat member, reset any lingering street/common-plot slot selection
            if (!isStreet &&
                _selectedSlot != null &&
                (ParkingSlotService.instance.isFlexibleStreetParking(_selectedSlot!) ||
                    _selectedSlot!.startsWith('CP-') ||
                    _selectedSlot!.startsWith('વાડી-'.tr))) {
              _selectedSlot = null;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: PremiumAppBar(
                title: 'મારા વાહનો & પાર્કિંગ સ્લોટ'.tr,
                subtitle: 'નંબર પ્લેટ, સ્લોટ એલોટમેન્ટ અને ડિજિટલ પાસ'.tr,
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
                                          Text(
                                            'નવું વાહન ઉમેરો & સ્લોટ ફાળવો'.tr,
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isStreet
                                                ? 'શેરી સોસાયટી: ઘર આંગણે આપોઆપ સુરક્ષિત પાર્કિંગ'.tr
                                                : 'બિલ્ડિંગ વિંગ $memberBlock ના માન્ય સ્લોટમાંથી પસંદ કરો'.tr,
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
                                    Text(
                                      'વાહનનો પ્રકાર પસંદ કરો:'.tr,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.52,
                                      children: _vehicleTypeOptions.map((t) {
                                        final (name, subtitle, iconData, color) = t;
                                        final isSelected = _selectedType == name ||
                                            (name.contains('ઇલેક્ટ્રિક'.tr) && _selectedType.contains('ઇલેક્ટ્રિક'.tr));
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _selectedType = name);
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isSelected ? color : const Color(0xFFE2E8F0),
                                                  width: isSelected ? 1.8 : 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isSelected
                                                        ? color.withValues(alpha: 0.18)
                                                        : const Color(0xFF0F172A).withValues(alpha: 0.03),
                                                    blurRadius: isSelected ? 10 : 4,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [color, color.withValues(alpha: 0.8)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                          borderRadius: BorderRadius.circular(11),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: color.withValues(alpha: 0.25),
                                                              blurRadius: 6,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(iconData, size: 20, color: Colors.white),
                                                      ),
                                                      AnimatedContainer(
                                                        duration: const Duration(milliseconds: 180),
                                                        width: 18,
                                                        height: 18,
                                                        decoration: BoxDecoration(
                                                          color: isSelected ? color : Colors.transparent,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isSelected ? color : const Color(0xFFCBD5E1),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: isSelected
                                                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                                                          color: isSelected ? color : const Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        subtitle,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                          color: isSelected
                                                              ? color.withValues(alpha: 0.85)
                                                              : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),

                                    // 1. Authentic HSRP Number Plate Input
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('🇮🇳', style: TextStyle(fontSize: 14)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'વાહન નંબર પ્લેટ (HSRP) *'.tr,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _plateC,
                                          textCapitalization: TextCapitalization.characters,
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                          inputFormatters: [
                                            UpperCaseTextFormatter(),
                                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                                            LengthLimitingTextInputFormatter(16),
                                          ],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'GJ 01 AB 1234',
                                            hintStyle: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.5,
                                            ),
                                            prefixIcon: Padding(
                                              padding: const EdgeInsets.only(left: 12, right: 10),
                                              child: Container(
                                                width: 44,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF002B49),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF38BDF8),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3.5),
                                                    const Text(
                                                      'IND',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 44),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
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
                                              return 'આ નંબર પ્લેટવાળું વાહન તમે પહેલેથી જ ઉમેરેલું છે!'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.info_outline_rounded, size: 12.5, color: Color(0xFF0284C7)),
                                              const SizedBox(width: 5),
                                              Text(
                                                'માન્ય ફોર્મેટ: GJ 01 AB 1234 અથવા 22 BH 1234 AA'.tr,
                                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // 2. Vehicle Model Input
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'વાહન મોડેલ / બ્રાન્ડ (વૈકલ્પિક)'.tr,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _modelC,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
                                          decoration: InputDecoration(
                                            hintText: 'દા.ત. Tata Nexon / Activa 6G / Creta'.tr,
                                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                            prefixIcon: Padding(
                                              padding: const EdgeInsets.only(left: 12, right: 10),
                                              child: Container(
                                                width: 36,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _selectedType.contains('૨'.tr) || _selectedType.toLowerCase().contains('bike')
                                                      ? Icons.two_wheeler_rounded
                                                      : (_selectedType.contains('EV') || _selectedType.contains('ઇલેક્ટ્રિક'.tr)
                                                          ? Icons.electric_car_rounded
                                                          : (_selectedType.contains('અન્ય'.tr)
                                                              ? Icons.local_shipping_rounded
                                                              : Icons.directions_car_rounded)),
                                                  color: const Color(0xFF0284C7),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 44),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // 3. INTELLIGENT ARCHITECTURE-AWARE PARKING ALLOCATION
                                    if (isStreet) ...[
                                      // === શેરી / રો-હાઉસ સોસાયટી: ઘર આંગણે vs કોમન પ્લોટ ===
                                      Row(
                                        children: [
                                          Text(
                                            'સોસાયટી પાર્કિંગ વ્યવસ્થા:'.tr,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.home_work_rounded, size: 12, color: Color(0xFF15803D)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'શેરી / રો-હાઉસ સોસાયટી'.tr,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      StreamBuilder<List<ParkingSlotModel>>(
                                        stream: ParkingSlotService.instance.streamRealCommonPlotSlots(societyId),
                                        builder: (context, slotSnap) {
                                          final commonSlots = slotSnap.data ?? [];
                                          final isCpChosen = _selectedSlot != null &&
                                              (_selectedSlot!.startsWith('CP-') || _selectedSlot!.startsWith('વાડી-'.tr));
                                          final isHomeFrontActive = !isCpChosen;

                                          return Column(
                                            children: [
                                              // Option 1: ઘર આંગણે પાર્કિંગ (Home Front) - Tap to Select
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    HapticFeedback.selectionClick();
                                                    setState(() => _selectedSlot = null);
                                                  },
                                                  borderRadius: BorderRadius.circular(18),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    padding: const EdgeInsets.all(14),
                                                    decoration: BoxDecoration(
                                                      color: isHomeFrontActive ? const Color(0xFFF0FDF4) : Colors.white,
                                                      borderRadius: BorderRadius.circular(18),
                                                      border: Border.all(
                                                        color: isHomeFrontActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                                        width: isHomeFrontActive ? 1.8 : 1.2,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: isHomeFrontActive
                                                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                              : const Color(0xFF0F172A).withValues(alpha: 0.03),
                                                          blurRadius: isHomeFrontActive ? 10 : 4,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 44,
                                                          height: 44,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: isHomeFrontActive
                                                                  ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                                                  : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            ),
                                                            borderRadius: BorderRadius.circular(13),
                                                            boxShadow: [
                                                              if (isHomeFrontActive)
                                                                BoxShadow(
                                                                  color: const Color(0xFF10B981).withValues(alpha: 0.28),
                                                                  blurRadius: 8,
                                                                  offset: const Offset(0, 3),
                                                                ),
                                                            ],
                                                          ),
                                                          child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 22),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'ઘર આંગણે પાર્કિંગ (Home Front)'.tr,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w900,
                                                                      fontSize: 13.5,
                                                                      color: isHomeFrontActive ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                                                                    ),
                                                                  ),
                                                                  const Spacer(),
                                                                  AnimatedContainer(
                                                                    duration: const Duration(milliseconds: 180),
                                                                    width: 20,
                                                                    height: 20,
                                                                    decoration: BoxDecoration(
                                                                      color: isHomeFrontActive ? const Color(0xFF10B981) : Colors.transparent,
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(
                                                                        color: isHomeFrontActive ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                                                        width: 1.5,
                                                                      ),
                                                                    ),
                                                                    child: isHomeFrontActive
                                                                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                                                                        : null,
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Text(
                                                                'તમારા પોતાના મકાન/પ્લોટ ($flatDisplay) ની સામે વાહન પાર્ક થશે.'.tr,
                                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                                              ),
                                                              const SizedBox(height: 5),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: isHomeFrontActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                child: Text(
                                                                  isHomeFrontActive ? '✓ સક્રિય • કોઈ સ્લોટ નંબર પસંદ કરવાની જરૂર નથી'.tr : 'ટેપ કરીને પસંદ કરો'.tr,
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.w700,
                                                                    color: isHomeFrontActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Option 2: સોસાયટી કોમન પ્લોટ / વાડી સ્લોટ (Only if slots configured by Admin)
                                              if (commonSlots.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () => _openSlotPicker(
                                                      targetBlock: 'કોમન પ્લોટ'.tr,
                                                      isCommonPlotOnly: true,
                                                    ),
                                                    borderRadius: BorderRadius.circular(18),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(milliseconds: 200),
                                                      padding: const EdgeInsets.all(14),
                                                      decoration: BoxDecoration(
                                                        color: isCpChosen ? const Color(0xFFF0F9FF) : Colors.white,
                                                        borderRadius: BorderRadius.circular(18),
                                                        border: Border.all(
                                                          color: isCpChosen ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                                                          width: isCpChosen ? 1.8 : 1.2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: isCpChosen
                                                                ? const Color(0xFF0284C7).withValues(alpha: 0.14)
                                                                : const Color(0xFF0F172A).withValues(alpha: 0.03),
                                                            blurRadius: isCpChosen ? 10 : 4,
                                                            offset: const Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 44,
                                                            height: 44,
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: isCpChosen
                                                                    ? [const Color(0xFF0284C7), const Color(0xFF38BDF8)]
                                                                    : [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                              ),
                                                              borderRadius: BorderRadius.circular(13),
                                                              boxShadow: [
                                                                if (isCpChosen)
                                                                  BoxShadow(
                                                                    color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                                                                    blurRadius: 8,
                                                                    offset: const Offset(0, 3),
                                                                  ),
                                                              ],
                                                            ),
                                                            child: const Icon(Icons.park_rounded, color: Colors.white, size: 22),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      'સોસાયટી કોમન પ્લોટ / વાડી સ્લોટ'.tr,
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w900,
                                                                        fontSize: 13.5,
                                                                        color: isCpChosen ? const Color(0xFF0369A1) : const Color(0xFF1E293B),
                                                                      ),
                                                                    ),
                                                                    const Spacer(),
                                                                    AnimatedContainer(
                                                                      duration: const Duration(milliseconds: 180),
                                                                      width: 20,
                                                                      height: 20,
                                                                      decoration: BoxDecoration(
                                                                        color: isCpChosen ? const Color(0xFF0284C7) : Colors.transparent,
                                                                        shape: BoxShape.circle,
                                                                        border: Border.all(
                                                                          color: isCpChosen ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                                                          width: 1.5,
                                                                        ),
                                                                      ),
                                                                      child: isCpChosen
                                                                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                                                                          : null,
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 3),
                                                                Text(
                                                                  isCpChosen
                                                                      ? 'કોમન પ્લોટમાં પસંદ કરેલ સ્લોટ નંબર સુરક્ષિત રહેશે.'.tr
                                                                      : 'એડમિન દ્વારા મંજૂર થયેલ ${commonSlots.length} સ્લોટ્સ ઉપલબ્ધ (વૈકલ્પિક)'.tr,
                                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                                                ),
                                                                const SizedBox(height: 5),
                                                                Row(
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                      decoration: BoxDecoration(
                                                                        color: isCpChosen ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                                                                        borderRadius: BorderRadius.circular(6),
                                                                        border: Border.all(
                                                                          color: isCpChosen ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                                                                          width: 0.8,
                                                                        ),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            isCpChosen ? Icons.local_parking_rounded : Icons.touch_app_rounded,
                                                                            size: 11,
                                                                            color: isCpChosen ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                                                          ),
                                                                          const SizedBox(width: 4),
                                                                          Text(
                                                                            isCpChosen
                                                                                ? 'સ્લોટ: $_selectedSlot (ક્લિક કરી બદલો)'.tr
                                                                                : 'સ્લોટ પસંદ કરો (${commonSlots.length} ઉપલબ્ધ) →'.tr,
                                                                            style: TextStyle(
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.w800,
                                                                              color: isCpChosen ? const Color(0xFF0284C7) : const Color(0xFF475569),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    if (isCpChosen) ...[
                                                                      const SizedBox(width: 8),
                                                                      InkWell(
                                                                        onTap: () {
                                                                          HapticFeedback.lightImpact();
                                                                          setState(() => _selectedSlot = null);
                                                                        },
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                                          child: Text(
                                                                            'કાઢી નાખો'.tr,
                                                                            style: const TextStyle(
                                                                              fontSize: 10.5,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Color(0xFFEF4444),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      // === ફ્લેટ / એપાર્ટમેન્ટ: વિંગ સ્લોટ સિલેક્શન ફરજિયાત ===
                                      Row(
                                        children: [
                                          Text(
                                            'વિંગ $memberBlock પાર્કિંગ સ્લોટ:'.tr,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFBAE6FD)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF0284C7)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'બિલ્ડિંગ / એપાર્ટમેન્ટ વિંગ'.tr,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _openSlotPicker(
                                            targetBlock: memberBlock,
                                            isCommonPlotOnly: false,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Ink(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            decoration: BoxDecoration(
                                              color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                  ? const Color(0xFFF0FDF4)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                    ? const Color(0xFF86EFAC)
                                                    : const Color(0xFFCBD5E1),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                        ? const Color(0xFF15803D).withValues(alpha: 0.12)
                                                        : const Color(0xFF0284C7).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
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
                                                            ? 'સ્લોટ: $_selectedSlot (લૉક માટે પસંદ કરેલ)'.tr
                                                            : 'વિંગ $memberBlock સ્લોટ પસંદ કરો (Tap to Select)'.tr,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 13.5,
                                                          color: _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                              ? const Color(0xFF15803D)
                                                              : const Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _selectedSlot != null && _selectedSlot!.isNotEmpty
                                                            ? 'વિંગ $memberBlock • સ્લોટ બદલવા ટેપ કરો'.tr
                                                            : 'એડમિન દ્વારા બનાવેલા રીઅલ સ્લોટ્સમાંથી પસંદ કરો'.tr,
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

                                    // 4. Save Vehicle Button
                                    Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.38),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
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
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                              )
                                            : const Icon(Icons.verified_rounded, color: Colors.white, size: 21),
                                        label: Text(
                                          _isAdding ? 'નોંધાઈ રહ્યું છે...'.tr : 'વાહન & સ્લોટ સાચવો'.tr,
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15.5, letterSpacing: 0.4),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        ),
                                      ),
                                    ),                                  ],
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
                              flatDisplay.isNotEmpty ? flatDisplay : 'સોસાયટી સભ્ય'.tr,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ગેટ સિક્યોરિટી એક્ટિવ'.tr,
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
                      Text(
                        'સ્માર્ટ સોસાયટી પાર્કિંગ ગાર્ડ'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'નોંધાયેલા વાહનો: $vehicleCount • સિંગલ-અસાઇનમેન્ટ સ્લોટ પ્રોટેક્શન'.tr,
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
            Text(
              'હજુ કોઈ વાહન નોંધાયેલ નથી'.tr,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'ઉપરના "+ નવું વાહન ઉમેરો" પર ક્લિક કરી તમારી કાર/બાઇક અને ફાળવેલ પાર્કિંગ સ્લોટ સાચવો.'.tr,
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
                'નોંધાયેલા વાહનો (${vehicles.length})'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text(
                '૧ સ્લોટ = ૧ વાહન'.tr,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final v = Map<String, dynamic>.from(vehicles[index] as Map);
              final number = (v['number'] ?? '').toString();
              final type = (v['type'] ?? 'કાર'.tr).toString();
              final model = (v['model'] ?? '').toString();
              final slot = (v['slot'] ?? '').toString();

              final isBike = type.contains('૨'.tr) || type.toLowerCase().contains('bike');
              final isEV = type.contains('EV') || type.contains('ઇલેક્ટ્રિક'.tr);
              final vehicleIcon = isEV
                  ? Icons.electric_car_rounded
                  : (isBike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded);

              final primaryCardColor = isEV
                  ? const Color(0xFF0D9488)
                  : (isBike ? const Color(0xFF4F46E5) : const Color(0xFF0284C7));

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: primaryCardColor.withValues(alpha: 0.035),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Digital Parking Pass Header Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryCardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.verified_user_rounded, size: 12, color: primaryCardColor),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'ડિજિટલ પાર્કિંગ પાસ'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: slot.isNotEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: slot.isNotEmpty ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: slot.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  slot.isNotEmpty ? 'સક્રિય પાસ'.tr : 'સ્લોટ બાકી'.tr,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: slot.isNotEmpty ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Vehicle Info Body
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          // Vehicle Type Squircle Avatar with Glow
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isEV
                                        ? [const Color(0xFF0D9488), const Color(0xFF14B8A6)]
                                        : (isBike
                                            ? [const Color(0xFF4F46E5), const Color(0xFF6366F1)]
                                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)]),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryCardColor.withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(vehicleIcon, color: Colors.white, size: 28),
                              ),
                              if (isEV)
                                Positioned(
                                  right: -3,
                                  bottom: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Vehicle Plate & Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Authentic HSRP License Plate Badge with 1-Tap Copy
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
                                                'વાહન નંબર કોપી થયો: $number'.tr,
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
                                    message: 'નંબર કોપી કરવા માટે ક્લિક કરો'.tr,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF94A3B8), width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // HSRP Blue Strip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF002B49),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(6.8),
                                                bottomLeft: Radius.circular(6.8),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 4,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF38BDF8),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                const Text(
                                                  'IND',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            child: Text(
                                              number,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14.5,
                                                letterSpacing: 1.1,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (model.isNotEmpty) ...[
                                      Text(
                                        model,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Delete Action with soft rounded button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              tooltip: 'વાહન કાઢી નાખો'.tr,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteVehicle(societyId, v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Slot Allocation Bar with Action Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(21)),
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: slot.isNotEmpty
                                        ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                        : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.local_parking_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ફાળવેલ પાર્કિંગ સ્લોટ'.tr,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Text(
                                          slot.isNotEmpty ? slot : 'કોઈ સ્લોટ ફાળવેલ નથી'.tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: slot.isNotEmpty ? const Color(0xFF065F46) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        if (slot.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: const Color(0xFFA7F3D0), width: 0.6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.lock_rounded, size: 9, color: Color(0xFF15803D)),
                                                const SizedBox(width: 2.5),
                                                Text(
                                                  'સુરક્ષિત લૉક'.tr,
                                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'સ્લોટ બદલો'.tr,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFECDD3), width: 0.9),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.report_problem_rounded, size: 14, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'સ્લોટમાં સમસ્યા છે? (અન્ય વાહન / ફરિયાદ)'.tr,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFDC2626)),
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
        SnackBar(content: Text('કૃપા કરીને વાહન નંબર પ્લેટ લખો!'.tr), backgroundColor: Colors.orange),
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
        SnackBar(content: Text('સર્ચ કરવામાં ભૂલ આવી: $e'.tr), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _notifyOwner() async {
    if (_foundOwner == null) return;
    setState(() => _isNotifying = true);

    try {
      final title = '🚨 પાર્કિંગ સ્લોટ ખાલી કરવાની વિનંતી'.tr;
      final body =
          'તમારું વાહન (${_foundOwner!.vehicleNumber}) સભ્ય ${widget.flatDisplay} ના પાર્કિંગ સ્લોટ (${widget.assignedSlot}) માં પાર્ક થયેલું છે. કૃપા કરીને તેને તાત્કાલિક યોગ્ય જગ્યાએ હટાવો.'.tr;

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
          content: Text('સભ્ય ${_foundOwner!.ownerName} (${_foundOwner!.flatDisplay}) ને સીધું એલર્ટ મોકલી દીધું છે! એડમિનને ખલેલ પહોંચાડ્યા વગર સીધું સોલ્યુશન.'.tr),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('એલર્ટ મોકલવામાં ભૂલ: $e'.tr), backgroundColor: Colors.red),
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
      final title = '🚨 અનધિકૃત વાહન પાર્કિંગ એલર્ટ'.tr;
      final body =
          'સભ્ય ${widget.flatDisplay} ના પાર્કિંગ સ્લોટ (${widget.assignedSlot}) માં અજાણ્યું વાહન ($raw) ખોટી જગ્યાએ પાર્ક છે. કૃપા કરીને તપાસ કરી તાત્કાલિક હટાવો.'.tr;

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
          content: Text('સિક્યોરિટી ગાર્ડ / વૉચમેનને સ્લોટ ${widget.assignedSlot} અંગે એલર્ટ મોકલી દીધું છે!'.tr),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('એલર્ટ મોકલવામાં ભૂલ: $e'.tr), backgroundColor: Colors.red),
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
                      Text(
                        'પાર્કિંગ સ્લોટ સમસ્યા નિવારણ'.tr,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'સ્લોટ: ${widget.assignedSlot} • વાહન: ${widget.vehiclePlate}'.tr,
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
                    children: [
                      Icon(Icons.car_crash_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'મારા સ્લોટમાં અન્ય વાહન પાર્ક છે'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ખોટી જગ્યાએ પાર્ક થયેલ વાહન નંબર દાખલ કરી તપાસ કરો:'.tr,
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
                            hintText: 'દા.ત. GJ 01 AB 1234'.tr,
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
                            : Text('તપાસ કરો'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
                                'વાહન માલિક: ${_foundOwner!.ownerName}'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D)),
                              ),
                              const Spacer(),
                              Text(
                                'ફ્લેટ: ${_foundOwner!.flatDisplay}'.tr,
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
                                            child: Text('વાહન નંબર કોપી થયો: ${_foundOwner!.vehicleNumber}'.tr),
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
                                        child: Text('IND', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
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
                                          'કૉલ: ${_foundOwner!.ownerPhone}'.tr,
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
                              label: Text('માલિકને ગાડી હટાવવાનું એલર્ટ મોકલો'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, size: 13, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'આ નોટિફિકેશન સીધું વાહન માલિકને જશે (એડમિનને નહીં, જેથી આપસી સમજણથી તાત્કાલિક ગાડી હટી શકે).'.tr,
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
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'આ વાહન સોસાયટીના કોઈ સભ્યનું નથી (વિઝિટર/મહેમાનનું હોઈ શકે છે).'.tr,
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
                              label: Text('સિક્યોરિટી / વૉચમેનને તાત્કાલિક જાણ કરો'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
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
                            initialCategory: 'પાર્કિંગ વિવાદ'.tr,
                            initialTitle: 'પાર્કિંગ સ્લોટ ${widget.assignedSlot} અંગે સમસ્યા'.tr,
                            initialDesc: 'મારા ફાળવેલા સ્લોટ ${widget.assignedSlot} (વાહન: ${widget.vehiclePlate}) માં નીચે મુજબની સમસ્યા છે:\n'.tr,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_late_rounded, size: 16, color: Color(0xFF7C3AED)),
                    label: Text(
                      'પાર્કિંગ ફરિયાદ'.tr,
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
                    label: Text(
                      'સ્લોટ બદલો'.tr,
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
