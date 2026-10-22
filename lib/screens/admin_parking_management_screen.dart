import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/parking_slot_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

class AdminParkingManagementScreen extends StatefulWidget {
  const AdminParkingManagementScreen({super.key});

  @override
  State<AdminParkingManagementScreen> createState() => _AdminParkingManagementScreenState();
}

class _AdminParkingManagementScreenState extends State<AdminParkingManagementScreen> {
  String _selectedBlock = '';
  String _statusFilter = 'all'; // 'all', 'available', 'occupied'
  String _selectedParkingLevel = 'Ground'; // 'Ground', 'B1', 'B2', 'B3', 'Open', 'Loading'
  bool _isSaving = false;

  final TextEditingController _carSlotsC = TextEditingController(text: '12');
  final TextEditingController _bikeSlotsC = TextEditingController(text: '15');
  final TextEditingController _evSlotsC = TextEditingController(text: '3');
  final TextEditingController _commonPlotSlotsC = TextEditingController(text: '8');
  final TextEditingController _vadiSlotsC = TextEditingController(text: '4');
  final TextEditingController _customSlotC = TextEditingController();
  final TextEditingController _manualWingC = TextEditingController();

  @override
  void dispose() {
    _carSlotsC.dispose();
    _bikeSlotsC.dispose();
    _evSlotsC.dispose();
    _commonPlotSlotsC.dispose();
    _vadiSlotsC.dispose();
    _customSlotC.dispose();
    _manualWingC.dispose();
    super.dispose();
  }

  Future<void> _saveWingConfig(String societyId, List<SocietyBlockInfo> blocks) async {
    final cars = int.tryParse(_carSlotsC.text.trim()) ?? 12;
    final bikes = int.tryParse(_bikeSlotsC.text.trim()) ?? 15;
    final evs = int.tryParse(_evSlotsC.text.trim()) ?? 3;

    final targetBlock = _selectedBlock.isNotEmpty
        ? _selectedBlock
        : _manualWingC.text.trim().toUpperCase();

    if (targetBlock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને વિંગ સિલેક્ટ કરો અથવા નામ દાખલ કરો!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (targetBlock == '__ALL__') {
        int totalCount = 0;
        for (final b in blocks) {
          final count = await ParkingSlotService.instance.generateMultiLevelSlotsInFirestore(
            societyId: societyId,
            blockName: b.name,
            level: _selectedParkingLevel,
            carCount: cars,
            bikeCount: bikes,
            evCount: evs,
          );
          totalCount += count;
        }

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('તમામ ${blocks.length} વિંગ્સ ($_selectedParkingLevel) માટે કુલ $totalCount સ્લોટ્સ સફળતાપૂર્વક Firestore માં સેવ થઈ ગયા!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final count = await ParkingSlotService.instance.generateMultiLevelSlotsInFirestore(
          societyId: societyId,
          blockName: targetBlock,
          level: _selectedParkingLevel,
          carCount: cars,
          bikeCount: bikes,
          evCount: evs,
        );

        if (!mounted) return;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('વિંગ "$targetBlock" ($_selectedParkingLevel) માટે $count સ્લોટ્સ સફળતાપૂર્વક Firestore માં સેવ થઈ ગયા!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveStreetConfig(String societyId) async {
    final cpCount = int.tryParse(_commonPlotSlotsC.text.trim()) ?? 8;
    final vadiCount = int.tryParse(_vadiSlotsC.text.trim()) ?? 4;

    setState(() => _isSaving = true);
    try {
      final count = await ParkingSlotService.instance.generateAndSaveStreetCommonSlotsInFirestore(
        societyId: societyId,
        cpCount: cpCount,
        vadiCount: vadiCount,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('સોસાયટી માટે $count કોમન પ્લોટ & વાડી સ્લોટ્સ Firestore માં સેવ થઈ ગયા!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addCustomSlot(String societyId, bool isStreet) async {
    final name = _customSlotC.text.trim().toUpperCase();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ParkingSlotService.instance.addSingleCustomSlotInFirestore(
        societyId: societyId,
        slotNumber: name,
        blockName: isStreet
            ? 'કોમન પ્લોટ'
            : (_selectedBlock == '__ALL__'
                ? (_manualWingC.text.trim().isNotEmpty ? _manualWingC.text.trim().toUpperCase() : 'A')
                : (_selectedBlock.isNotEmpty ? _selectedBlock : (_manualWingC.text.trim().isNotEmpty ? _manualWingC.text.trim().toUpperCase() : 'A'))),
        category: isStreet ? 'Street' : 'Wing',
        slotType: 'general',
      );

      _customSlotC.clear();
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('નવો સ્લોટ "$name" ઉમેરાઈ ગયો!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSlot(String societyId, String slotName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('સ્લોટ ડિલીટ કરવો છે?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('શું તમે ખરેખર સ્લોટ "$slotName" કાયમ માટે કાઢી નાખવા માંગો છો?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ના')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('હા, ડિલીટ કરો'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ParkingSlotService.instance.deleteSlotFromFirestore(societyId, slotName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('સ્લોટ "$slotName" કાઢી નાખવામાં આવ્યો.'),
          backgroundColor: const Color(0xFF0F172A),
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
    final societyId = SocietyService.instance.societyId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const PremiumAppBar(
        title: 'પાર્કિંગ સ્લોટ મેનેજમેન્ટ',
        subtitle: 'ઓટો-જનરેટર, એલોટમેન્ટ અને સ્લોટ સ્ટેટસ',
        icon: Icons.local_parking_rounded,
        accentColor: Color(0xFF0284C7),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: SocietyService.instance.societySettingsDoc(AppFirestore.instance).snapshots(),
        builder: (context, settingsSnap) {
          final settingsData = settingsSnap.data?.data() as Map<String, dynamic>? ?? {};
          final societyArchType = (settingsData['architectureType'] ?? 'Wing').toString();
          final isStreet = societyArchType == 'Street';

          return StreamBuilder<List<SocietyBlockInfo>>(
            stream: ParkingSlotService.instance.streamSocietyBlocks(societyId),
            builder: (context, blockSnap) {
              final blocks = blockSnap.data ?? [];
              if (_selectedBlock.isEmpty && blocks.isNotEmpty) {
                _selectedBlock = blocks.first.name;
              }

              return StreamBuilder<Map<String, OccupiedSlotInfo>>(
                stream: ParkingSlotService.instance.streamOccupiedSlots(societyId),
                builder: (context, occSnap) {
                  final occupiedMap = occSnap.data ?? {};

                  return StreamBuilder<List<ParkingSlotModel>>(
                    stream: ParkingSlotService.instance.streamAllRealSlots(societyId),
                    builder: (context, realSlotSnap) {
                      final allRealSlots = realSlotSnap.data ?? [];

                      // Filter real slots based on active architecture mode
                      final relevantSlots = isStreet
                          ? allRealSlots.where((s) => s.category == 'Street').toList()
                          : (_selectedBlock == '__ALL__'
                              ? allRealSlots.where((s) => s.category == 'Wing').toList()
                              : allRealSlots.where((s) => s.blockName == _selectedBlock).toList());

                      int totalSlots = relevantSlots.length;
                      int occupiedCount = 0;
                      int availableCount = 0;

                      for (final s in relevantSlots) {
                        final status = ParkingSlotService.instance.checkSlotStatus(
                          slotName: s.slotNumber,
                          occupiedSlots: occupiedMap,
                        );
                        if (status == ParkingSlotStatus.occupied || status == ParkingSlotStatus.mySlot) {
                          occupiedCount++;
                        } else {
                          availableCount++;
                        }
                      }

                      // Filtered slots for display
                      final displaySlots = relevantSlots.where((s) {
                        final status = ParkingSlotService.instance.checkSlotStatus(
                          slotName: s.slotNumber,
                          occupiedSlots: occupiedMap,
                        );
                        final isOcc = status == ParkingSlotStatus.occupied || status == ParkingSlotStatus.mySlot;
                        if (_statusFilter == 'available') return !isOcc;
                        if (_statusFilter == 'occupied') return isOcc;
                        return true;
                      }).toList();

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          // 1. Top Hero Card with 3D Banner
                          _buildHeroHeader(isStreet, totalSlots, occupiedCount, availableCount),

                          // 2. Slot Generator Panel (Tailored for Wing vs Street)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: isStreet
                                ? _buildStreetGeneratorCard(societyId)
                                : _buildWingGeneratorCard(societyId, blocks),
                          ),
                          const SizedBox(height: 16),

                          // 3. Add Custom Slot Strip
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildAddCustomSlotCard(societyId, isStreet),
                          ),
                          const SizedBox(height: 20),

                          // 4. Slot Status Filters & Live Slots Grid
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.grid_view_rounded, color: Color(0xFF0284C7), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isStreet
                                      ? 'કોમન પ્લોટ સ્લોટ્સ લિસ્ટ (${displaySlots.length})'
                                      : (_selectedBlock == '__ALL__'
                                          ? 'તમામ સ્લોટ્સ (${displaySlots.length})'
                                          : '${SocietyService.instance.formatBlockDisplayName(_selectedBlock, architectureType: societyArchType)} સ્લોટ્સ (${displaySlots.length})'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const Spacer(),
                                _buildFilterSegment(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Grid of Slots
                          if (displaySlots.isEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  isStreet
                                      ? 'હજુ સુધી કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\n(શેરી સોસાયટીમાં દરેક સભ્ય ઘર આગળ પાર્ક કરે છે).'
                                      : (_selectedBlock == '__ALL__'
                                          ? 'હજુ સુધી કોઈ વિંગ્સ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.'
                                          : '${SocietyService.instance.formatBlockDisplayName(_selectedBlock, architectureType: societyArchType)} માં હજુ કોઈ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.8,
                                ),
                                itemCount: displaySlots.length,
                                itemBuilder: (context, idx) {
                                  final slot = displaySlots[idx];
                                  final occInfo = occupiedMap[slot.slotNumber.toUpperCase()];
                                  final isOcc = occInfo != null;

                                  return _buildAdminSlotTile(
                                    slot: slot.slotNumber,
                                    isOccupied: isOcc,
                                    occInfo: occInfo,
                                    onDelete: () => _deleteSlot(societyId, slot.slotNumber),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(bool isStreet, int total, int occupied, int available) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/parking_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isStreet ? Icons.cottage_rounded : Icons.apartment_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              isStreet ? 'શેરી / રો-હાઉસ સોસાયટી' : 'હાઇરાઇઝ એપાર્ટમેન્ટ વિંગ્સ',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👑 એડમિન કંટ્રોલ',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'સોસાયટી પાર્કિંગ કંટ્રોલ સેન્ટર',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _heroStatBadge('કુલ સ્લોટ્સ', '$total', Colors.white),
                          const SizedBox(width: 8),
                          _heroStatBadge('બુક થયેલ', '$occupied', const Color(0xFFFCA5A5)),
                          const SizedBox(width: 8),
                          _heroStatBadge('ઉપલબ્ધ', '$available', const Color(0xFF86EFAC)),
                        ],
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

  Widget _heroStatBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $val',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ૧. વિંગ સોસાયટી બલ્ક સ્લોટ જનરેટર
  Widget _buildWingGeneratorCard(
    String societyId,
    List<SocietyBlockInfo> blocks,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Text(
                'વિંગ વાઇઝ સ્લોટ્સ ઓટો-જનરેટર',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'દરેક વિંગ માટે ૪-વ્હીલર, ૨-વ્હીલર અને EV સ્લોટ્સની સંખ્યા સેટ કરી ડેટાબેઝમાં સેવ કરો:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Block Chooser
          if (blocks.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (blocks.length > 1) ...[
                    ChoiceChip(
                      label: const Text('⭐ તમામ વિંગ્સ (All)'),
                      selected: _selectedBlock == '__ALL__',
                      onSelected: (_) => setState(() => _selectedBlock = '__ALL__'),
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: _selectedBlock == '__ALL__' ? Colors.white : const Color(0xFF334155),
                        fontWeight: _selectedBlock == '__ALL__' ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ...blocks.map((b) {
                    final isSel = b.name == _selectedBlock;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(SocietyService.instance.formatBlockDisplayName(b.name, architectureType: b.type)),
                        selected: isSel,
                        onSelected: (_) => setState(() => _selectedBlock = b.name),
                        selectedColor: const Color(0xFF0284C7),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            TextField(
              controller: _manualWingC,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'વિંગનું નામ (દા.ત. S-1 અથવા A)',
                hintText: 'દા.ત. S-1',
                isDense: true,
                prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Level / Floor Selector
          const Text(
            'પાર્કિંગ લેવલ / ફ્લોર:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ('Ground', 'ગ્રાઉન્ડ / સ્ટીલ્ટ', Icons.garage_rounded),
                ('B1', 'બેઝમેન્ટ - ૧ (B1)', Icons.stairs_rounded),
                ('B2', 'બેઝમેન્ટ - ૨ (B2)', Icons.stairs_rounded),
                ('B3', 'બેઝમેન્ટ - ૩ (B3)', Icons.stairs_rounded),
                ('Open', 'ઓપન / સપાટી', Icons.wb_sunny_rounded),
                ('Loading', 'કોમર્શિયલ લોડિંગ બે', Icons.local_shipping_rounded),
              ].map((lvl) {
                final isSel = _selectedParkingLevel == lvl.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(lvl.$3, size: 14, color: isSel ? Colors.white : const Color(0xFF0284C7)),
                    label: Text(lvl.$2),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedParkingLevel = lvl.$1),
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF334155),
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _carSlotsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '૪-વ્હીલર (કાર)',
                    isDense: true,
                    prefixIcon: const Icon(Icons.directions_car_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _bikeSlotsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '૨-વ્હીલર (બાઇક)',
                    isDense: true,
                    prefixIcon: const Icon(Icons.two_wheeler_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _evSlotsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'EV સ્લોટ્સ',
                    isDense: true,
                    prefixIcon: const Icon(Icons.electric_car_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveWingConfig(societyId, blocks),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
              label: Text(
                _isSaving ? 'જનરેટ થઈ રહ્યું છે...' : '૧-ક્લિક સ્લોટ્સ જનરેટ & સેવ કરો',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ૨. શેરી સોસાયટી કોમન પ્લોટ / વાડી સ્લોટ જનરેટર
  Widget _buildStreetGeneratorCard(String societyId) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.park_rounded, color: Color(0xFF0D9488), size: 20),
              SizedBox(width: 8),
              Text(
                'શેરી કોમન પ્લોટ & વાડી સ્લોટ્સ સેટઅપ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'શેરી સોસાયટીમાં દરેક સભ્ય ઘર આંગણે પાર્ક કરે છે. જો કોમન પ્લોટ કે વાડીમાં વધારાનું પાર્કિંગ મંજૂર કરવું હોય તો જ સ્લોટ્સ બનાવો:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commonPlotSlotsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'કોમન પ્લોટ સ્લોટ્સ (CP)',
                    hintText: 'દા.ત. 8',
                    isDense: true,
                    prefixIcon: const Icon(Icons.park_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _vadiSlotsC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'વાડી પાર્કિંગ સ્લોટ્સ',
                    hintText: 'દા.ત. 4',
                    isDense: true,
                    prefixIcon: const Icon(Icons.deck_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveStreetConfig(societyId),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              label: Text(
                _isSaving ? 'સેવ થઈ રહ્યું છે...' : 'કોમન પ્લોટ સ્લોટ્સ સેવ કરો',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ૩. કસ્ટમ સ્લોટ ઉમેરવાનો કાર્ડ
  Widget _buildAddCustomSlotCard(String societyId, bool isStreet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customSlotC,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: isStreet ? 'કસ્ટમ સ્લોટ દા.ત. CP-VIP, GUEST-P1' : 'કસ્ટમ સ્લોટ દા.ત. BASEMENT-01, VIP-01',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                isDense: true,
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.add_box_rounded, color: Color(0xFF0284C7), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addCustomSlot(societyId, isStreet),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('ઉમેરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSegment() {
    final opts = [
      ('all', 'બધા'),
      ('available', 'ખાલી'),
      ('occupied', 'બુક'),
    ];

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: opts.map((o) {
          final isSel = _statusFilter == o.$1;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                o.$2,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminSlotTile({
    required String slot,
    required bool isOccupied,
    required OccupiedSlotInfo? occInfo,
    required VoidCallback onDelete,
  }) {
    final isBike = slot.contains('-B') || slot.startsWith('B');
    final isEV = slot.contains('EV');
    final isCommonPlot = slot.contains('CP') || slot.contains('કોમન') || slot.contains('વાડી');

    final bayIcon = isCommonPlot
        ? Icons.park_rounded
        : (isEV
            ? Icons.electric_car_rounded
            : (isBike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded));

    final textColor = isOccupied ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final bgColor = isOccupied ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isOccupied ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(bayIcon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  slot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: textColor),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (isOccupied && occInfo != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ફાળવેલ: ${occInfo.flatDisplay}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF991B1B)),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: occInfo.vehicleNumber));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text('વાહન નંબર કોપી થયો: ${occInfo.vehicleNumber}')),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${occInfo.vehicleNumber} (${occInfo.ownerName})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 10, color: Color(0xFF991B1B)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ઉપલબ્ધ (ખાલી)',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
