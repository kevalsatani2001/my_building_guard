import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/parking_slot_service.dart';
import '../services/society_service.dart';
import 'package:building_guard/l10n/app_strings.dart';

class ParkingSlotSelectorSheet extends StatefulWidget {
  final String? initialSlot;
  final String targetBlock;
  final bool isCommonPlotOnly;
  final String vehicleType;
  final String? vehiclePlate;

  const ParkingSlotSelectorSheet({
    super.key,
    this.initialSlot,
    required this.targetBlock,
    this.isCommonPlotOnly = false,
    required this.vehicleType,
    this.vehiclePlate,
  });

  static Future<String?> show(
    BuildContext context, {
    String? initialSlot,
    required String targetBlock,
    bool isCommonPlotOnly = false,
    required String vehicleType,
    String? vehiclePlate,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ParkingSlotSelectorSheet(
        initialSlot: initialSlot,
        targetBlock: targetBlock,
        isCommonPlotOnly: isCommonPlotOnly,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
      ),
    );
  }

  @override
  State<ParkingSlotSelectorSheet> createState() => _ParkingSlotSelectorSheetState();
}

class _ParkingSlotSelectorSheetState extends State<ParkingSlotSelectorSheet> {
  String _categoryFilter = 'all'; // 'all', 'car', 'bike', 'ev'
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlot?.trim();

    // Auto-detect category filter based on vehicle type
    if (widget.vehicleType.contains('૨'.tr) || widget.vehicleType.toLowerCase().contains('bike')) {
      _categoryFilter = 'bike';
    } else if (widget.vehicleType.contains('EV') || widget.vehicleType.contains('ઇલેક્ટ્રિક'.tr)) {
      _categoryFilter = 'ev';
    } else if (widget.vehicleType.contains('૪'.tr) || widget.vehicleType.toLowerCase().contains('car')) {
      _categoryFilter = 'car';
    }
  }

  @override
  Widget build(BuildContext context) {
    final societyId = SocietyService.instance.societyId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isCommonPlotOnly ? Icons.park_rounded : Icons.local_parking_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isCommonPlotOnly
                            ? 'સોસાયટી કોમન પ્લોટ પાર્કિંગ'.tr
                            : '${widget.targetBlock} પાર્કિંગ સ્લોટ પસંદગી'.tr,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isCommonPlotOnly
                            ? 'એડમિન દ્વારા મંજૂર કરેલા કોમન પ્લોટ સ્લોટ્સ'.tr
                            : 'તમારી વિંગના એડમિન દ્વારા માન્ય સ્લોટ્સ'.tr,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Type Filters (For Wing Only)
          if (!widget.isCommonPlotOnly) ...[
            const SizedBox(height: 10),
            _buildVehicleTypeChips(),
            const SizedBox(height: 6),
          ],

          // Visual Status Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendIndicator(
                    color: const Color(0xFF10B981),
                    bg: const Color(0xFFDCFCE7),
                    label: 'ઉપલબ્ધ'.tr,
                  ),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(
                    color: const Color(0xFF0284C7),
                    bg: const Color(0xFFE0F2FE),
                    label: 'તમારો સ્લોટ'.tr,
                  ),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    label: 'તમારું અન્ય વાહન'.tr,
                  ),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEE2E2),
                    label: 'રોકાયેલ સ્લોટ'.tr,
                  ),
                ],
              ),
            ),
          ),

          // Stream of Real Slots from Firestore
          Expanded(
            child: StreamBuilder<Map<String, OccupiedSlotInfo>>(
              stream: ParkingSlotService.instance.streamOccupiedSlots(societyId),
              builder: (context, occSnap) {
                final occupiedMap = occSnap.data ?? {};

                return widget.isCommonPlotOnly
                    ? StreamBuilder<List<ParkingSlotModel>>(
                        stream: ParkingSlotService.instance.streamRealCommonPlotSlots(societyId),
                        builder: (context, slotSnap) {
                          if (slotSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
                          }
                          final slots = slotSnap.data ?? [];
                          if (slots.isEmpty) {
                            return _buildEmptyState(
                              title: 'કોઈ કોમન પ્લોટ સ્લોટ્સ નથી'.tr,
                              message: 'સોસાયટી એડમિન દ્વારા હજુ કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.'.tr,
                              icon: Icons.park_outlined,
                            );
                          }
                          return _buildSlotsGrid(slots, occupiedMap);
                        },
                      )
                    : StreamBuilder<List<ParkingSlotModel>>(
                        stream: ParkingSlotService.instance.streamRealSlotsForBlock(
                          societyId: societyId,
                          blockName: widget.targetBlock,
                        ),
                        builder: (context, slotSnap) {
                          if (slotSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
                          }
                          final rawSlots = slotSnap.data ?? [];
                          final filteredSlots = _filterSlotsByType(rawSlots);

                          if (filteredSlots.isEmpty) {
                            return _buildEmptyState(
                              title: 'સ્લોટ્સ મળ્યા નથી'.tr,
                              message: rawSlots.isEmpty
                                  ? 'એડમિન દ્વારા ${widget.targetBlock} માટે હજુ પાર્કિંગ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\nકૃપા કરીને સોસાયટી એડમિનનો સંપર્ક કરો.'.tr
                                  : 'આ કેટેગરીમાં કોઈ સ્લોટ્સ ઉપલબ્ધ નથી.'.tr,
                              icon: Icons.local_parking_rounded,
                            );
                          }
                          return _buildSlotsGrid(filteredSlots, occupiedMap);
                        },
                      );
              },
            ),
          ),

          // Bottom Action Confirm Button
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'પસંદ કરેલ પાર્કિંગ સ્લોટ:'.tr,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedSlot != null && _selectedSlot!.isNotEmpty
                            ? _selectedSlot!
                            : 'કોઈ સ્લોટ પસંદ નથી'.tr,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: _selectedSlot != null ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selectedSlot != null && _selectedSlot!.isNotEmpty
                        ? () => Navigator.pop(context, _selectedSlot)
                        : null,
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'પાર્કિંગ કન્ફર્મ કરો'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ParkingSlotModel> _filterSlotsByType(List<ParkingSlotModel> slots) {
    if (_categoryFilter == 'all') return slots;
    return slots.where((s) {
      if (_categoryFilter == 'car') return s.slotType == 'car' || s.slotType == 'general';
      if (_categoryFilter == 'bike') return s.slotType == 'bike';
      if (_categoryFilter == 'ev') return s.slotType == 'ev';
      return true;
    }).toList();
  }

  Widget _buildVehicleTypeChips() {
    final types = [
      ('all', 'બધા સ્લોટ્સ'.tr, Icons.apps_rounded),
      ('car', '૪-વ્હીલર કાર'.tr, Icons.directions_car_rounded),
      ('bike', '૨-વ્હીલર બાઇક'.tr, Icons.two_wheeler_rounded),
      ('ev', '⚡ EV ચાર્જિંગ'.tr, Icons.electric_car_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.map((t) {
          final isSelected = _categoryFilter == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t.$3,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(t.$2),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _categoryFilter = t.$1),
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlotsGrid(List<ParkingSlotModel> slots, Map<String, OccupiedSlotInfo> occupiedMap) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 88,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final cleanSlot = slot.slotNumber.trim().toUpperCase();
        final normSlot = ParkingSlotService.normalizeSlotKey(cleanSlot);

        // Fallback: If not in occupiedMap from users collection, check slot.isAssigned in Firestore
        final occInfo = occupiedMap[cleanSlot] ??
            occupiedMap[normSlot] ??
            (slot.isAssigned
                ? OccupiedSlotInfo(
                    slotName: slot.slotNumber,
                    vehicleNumber: (slot.assignedVehiclePlate ?? '').toUpperCase(),
                    vehicleModel: slot.assignedVehicleModel ?? '',
                    vehicleType: slot.slotType,
                    ownerName: slot.assignedMemberName ?? '',
                    ownerPhone: '',
                    flatDisplay: (slot.assignedFlat != null && slot.assignedFlat!.isNotEmpty)
                        ? slot.assignedFlat!
                        : 'સોસાયટી સભ્ય'.tr,
                    ownerUid: slot.assignedMemberId ?? '',
                    isCurrentMember: (slot.assignedMemberId?.isNotEmpty == true) &&
                        slot.assignedMemberId == currentUid,
                  )
                : null);

        final bool isOccupied = occInfo != null;
        final bool isMySlot = occInfo?.isCurrentMember == true;

        // Check if this slot belongs specifically to the vehicle being managed/edited
        final bool isThisVehicle = isMySlot && (
          (widget.vehiclePlate != null &&
           widget.vehiclePlate!.trim().isNotEmpty &&
           occInfo != null &&
           VehiclePlateValidator.clean(widget.vehiclePlate!) == VehiclePlateValidator.clean(occInfo.vehicleNumber)) ||
          (widget.initialSlot != null &&
           widget.initialSlot!.trim().toUpperCase() == cleanSlot)
        );

        final bool isMyOtherVehicle = isMySlot && !isThisVehicle;
        final bool isOccupiedByOther = isOccupied && !isMySlot;
        final bool isSelected = _selectedSlot?.trim().toUpperCase() == cleanSlot;

        final String assignedPlate = occInfo?.vehicleNumber ?? '';
        final String assignedFlat = occInfo?.flatDisplay ?? 'અન્ય સભ્ય'.tr;

        // Interaction
        VoidCallback? onTap;
        if (isOccupiedByOther) {
          onTap = () {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'સ્લોટ "$cleanSlot" પહેલેથી $assignedFlat ને ફાળવેલ છે!'.tr,
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          };
        } else if (isMyOtherVehicle) {
          onTap = () {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'સ્લોટ "$cleanSlot" પહેલેથી તમારા વાહન ($assignedPlate) માટે ફાળવેલ છે! ૧ સ્લોટ માત્ર ૧ વાહનને જ મળી શકે.'.tr,
                ),
                backgroundColor: const Color(0xFFD97706),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          };
        } else {
          // Available or current vehicle's slot
          onTap = () {
            HapticFeedback.selectionClick();
            setState(() => _selectedSlot = cleanSlot);
          };
        }

        // Color & badge tokens
        final Color cardBg;
        final Color borderColor;
        final double borderWidth;
        final Color iconColor;
        final IconData iconData;
        final Color titleColor;
        final Color badgeBg;
        final Color badgeTextColor;
        final String badgeText;

        if (isSelected) {
          cardBg = const Color(0xFFE0F2FE);
          borderColor = const Color(0xFF0284C7);
          borderWidth = 2.0;
          iconColor = const Color(0xFF0284C7);
          iconData = Icons.check_circle_rounded;
          titleColor = const Color(0xFF0369A1);
          if (isThisVehicle) {
            badgeBg = const Color(0xFFBAE6FD);
            badgeTextColor = const Color(0xFF0369A1);
            badgeText = 'તમારો હાલનો સ્લોટ'.tr;
          } else {
            badgeBg = const Color(0xFFBAE6FD);
            badgeTextColor = const Color(0xFF0284C7);
            badgeText = 'પસંદ કરેલ'.tr;
          }
        } else if (isOccupiedByOther) {
          cardBg = const Color(0xFFFEF2F2);
          borderColor = const Color(0xFFFECACA);
          borderWidth = 1.2;
          iconColor = const Color(0xFFDC2626);
          iconData = Icons.lock_rounded;
          titleColor = const Color(0xFF991B1B);
          badgeBg = const Color(0xFFFEE2E2);
          badgeTextColor = const Color(0xFFB91C1C);
          badgeText = '🔴 રોકાયેલ ($assignedFlat)'.tr;
        } else if (isMyOtherVehicle) {
          cardBg = const Color(0xFFFFFBEB);
          borderColor = const Color(0xFFFDE68A);
          borderWidth = 1.2;
          iconColor = const Color(0xFFD97706);
          iconData = Icons.lock_rounded;
          titleColor = const Color(0xFF92400E);
          badgeBg = const Color(0xFFFEF3C7);
          badgeTextColor = const Color(0xFFB45309);
          badgeText = '🔒 બુક ($assignedPlate)'.tr;
        } else if (isThisVehicle) {
          cardBg = const Color(0xFFF0F9FF);
          borderColor = const Color(0xFF93C5FD);
          borderWidth = 1.4;
          iconColor = const Color(0xFF2563EB);
          iconData = Icons.verified_user_rounded;
          titleColor = const Color(0xFF1E40AF);
          badgeBg = const Color(0xFFDBEAFE);
          badgeTextColor = const Color(0xFF1D4ED8);
          badgeText = '🔵 તમારો સ્લોટ'.tr;
        } else {
          // Available
          cardBg = Colors.white;
          borderColor = const Color(0xFFE2E8F0);
          borderWidth = 1.2;
          iconColor = const Color(0xFF10B981);
          iconData = Icons.local_parking_rounded;
          titleColor = const Color(0xFF0F172A);
          badgeBg = const Color(0xFFDCFCE7);
          badgeTextColor = const Color(0xFF15803D);
          badgeText = '🟢 ઉપલબ્ધ (Available)'.tr;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        iconData,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cleanSlot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator({
    required Color color,
    required Color bg,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

