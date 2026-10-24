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
        final cleanSlot = slot.slotNumber.toUpperCase();

        final status = ParkingSlotService.instance.checkSlotStatus(
          slotName: cleanSlot,
          occupiedSlots: occupiedMap,
          currentVehiclePlate: widget.vehiclePlate,
        );

        final isOccupied = status == ParkingSlotStatus.occupied;
        final isSelected = _selectedSlot?.toUpperCase() == cleanSlot;
        final occInfo = occupiedMap[cleanSlot];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isOccupied
                ? () {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'સ્લોટ "$cleanSlot" પહેલેથી ફ્લેટ ${occInfo?.flatDisplay ?? '.trઅન્ય સભ્ય'} ને ફાળવેલ છે!'.tr,
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSlot = cleanSlot);
                  },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE0F2FE)
                    : isOccupied
                        ? const Color(0xFFFEF2F2)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : isOccupied
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.0 : 1.2,
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
                        isOccupied ? Icons.lock_rounded : Icons.local_parking_rounded,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFF0284C7)
                            : isOccupied
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF10B981),
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
                            color: isOccupied ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOccupied
                          ? 'રોકાયેલ (${occInfo?.flatDisplay ?? '.trબુક'})'
                          : '🟢 ઉપલબ્ધ (Available)'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOccupied ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
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
}
