import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/amenity_model.dart';
import '../services/amenity_booking_service.dart';

class AdminAmenitiesScreen extends StatefulWidget {
  const AdminAmenitiesScreen({super.key});

  @override
  State<AdminAmenitiesScreen> createState() => _AdminAmenitiesScreenState();
}

class _AdminAmenitiesScreenState extends State<AdminAmenitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AmenityBookingService _service = AmenityBookingService.instance;
  bool _hasAmenities = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final enabled = await _service.checkHasAmenitiesEnabled();
    if (mounted) {
      setState(() {
        _hasAmenities = enabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'એમેનિટીઝ & હોલ મેનેજર',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'વાડી, ક્લબહાઉસ, ટેરેસ & સ્લોટ બુકિંગ',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: _hasAmenities
            ? TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0F766E),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF0F766E),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(text: '📅 બુકિંગ્સ & કેલેન્ડર'),
                  Tab(text: '🏛️ સુવિધાઓ ગોઠવણી (Setup)'),
                ],
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Master Switch Card: "Does this society have amenities?"
            _buildMasterSwitchCard(),

            if (!_hasAmenities)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_off_rounded, size: 44, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'એમેનિટીઝ મોડ્યુલ અક્ષમ (Disabled) છે',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'જો તમારી સોસાયટીમાં વાડી, ક્લબહાઉસ કે કોમન હોલ ન હોય, તો આ ફીચર બંધ રાખવાથી સભ્યો અને વોચમેનને એપમાં કોઈ વધારાની ખાલી સ્ક્રીન જોવા નહીં મળે.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: MediaQuery.of(context).size.height - 180,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsTab(),
                    _buildAmenitiesSetupTab(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Master Switch Card
  Widget _buildMasterSwitchCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hasAmenities ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0),
          width: _hasAmenities ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hasAmenities ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.domain_rounded,
              color: _hasAmenities ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'સોસાયટીમાં એમેનિટીઝ / વાડી છે?',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  _hasAmenities ? 'સક્રિય • સમગ્ર એપમાં બુકિંગ ઉપલબ્ધ' : 'અદ્રશ્ય • બુકિંગ મોડ્યુલ છુપાયેલું છે',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _hasAmenities ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasAmenities,
            activeTrackColor: const Color(0xFF0F766E).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFF0F766E),
            onChanged: (val) async {
              setState(() => _hasAmenities = val);
              await _service.toggleHasAmenities(val);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? '✅ એમેનિટીઝ મોડ્યુલ સક્ષમ થયું. હવે સભ્યો અને ગેટ પર ઉપલબ્ધ રહેશે.'
                          : 'એમેનિટીઝ મોડ્યુલ બંધ કરવામાં આવ્યું છે.',
                    ),
                    backgroundColor: val ? const Color(0xFF0F766E) : Colors.blueGrey,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- ટેબ ૧: બુકિંગ્સ લિસ્ટ & મંજૂરી ---
  Widget _buildBookingsTab() {
    return StreamBuilder<List<AmenityBookingModel>>(
      stream: _service.getAllBookingsAdminStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final bookings = snapshot.data!;

        if (bookings.isEmpty) {
          return const Center(child: Text('હજુ કોઈ બુકિંગ રિક્વેસ્ટ આવેલ નથી.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, idx) {
            final b = bookings[idx];
            return _buildBookingAdminCard(b);
          },
        );
      },
    );
  }

  Widget _buildBookingAdminCard(AmenityBookingModel b) {
    Color statusColor;
    String statusLabel;
    switch (b.status) {
      case 'approved':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'મંજૂર થયેલ (Approved)';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'નામંજૂર (Rejected)';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'પેન્ડિંગ મંજૂરી (Pending)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ફ્લેટ: ${b.unitDisplay}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            b.amenityName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'હેતુ: ${b.purpose} • ${b.expectedGuests} અંદાજિત મહેમાનો',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 14, color: Color(0xFF0F766E)),
              const SizedBox(width: 4),
              Text(
                'તારીખ: ${DateFormat('dd/MM/yyyy').format(b.bookingDate)} (${b.slotName})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
              ),
            ],
          ),

          if (b.rentAmount > 0 || b.securityDeposit > 0) ...[
            const SizedBox(height: 8),
            Text(
              'ભાડું: ₹${b.rentAmount.toStringAsFixed(0)} | ડિપોઝિટ: ₹${b.securityDeposit.toStringAsFixed(0)} (સ્ટેટસ: ${b.depositStatus})',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],

          if (b.isApproved && b.eventPassCode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    'ગેટ પાસકોડ: ${b.eventPassCode}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Action Buttons
          if (b.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateBooking(b, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('નામંજૂર (Reject)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateBooking(b, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('મંજૂર કરો (Approve)'),
                  ),
                ),
              ],
            )
          else if (b.isApproved && b.depositStatus == 'held')
            // Sub-Admin / Committee Inspection Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDepositInspectionDialog(b),
                icon: const Icon(Icons.fact_check_rounded, size: 16),
                label: const Text('ઇવેન્ટ નિરીક્ષણ & ડિપોઝિટ રીફંડ નોંધ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateBooking(AmenityBookingModel b, String status) async {
    final remarkCtrl = TextEditingController();
    final isApprove = status == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'બુકિંગ મંજૂર કરવું છે?' : 'બુકિંગ નામંજૂર કરવું છે?'),
        content: TextField(
          controller: remarkCtrl,
          decoration: InputDecoration(
            labelText: isApprove ? 'ખાસ સૂચના (વૈકલ્પિક)' : 'નામંજૂર કરવાનું કારણ *',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('રદ કરો')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF0F766E) : Colors.red,
            ),
            child: Text(isApprove ? 'મંજૂર કરો' : 'નામંજૂર કરો'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.updateBookingStatus(
        bookingId: b.id,
        status: status,
        adminRemarks: remarkCtrl.text.trim(),
      );
    }
  }

  void _showDepositInspectionDialog(AmenityBookingModel b) {
    final noteCtrl = TextEditingController(text: 'કોઈ નુકસાન નથી, હોલ સાફ છે.');
    String depositStatus = 'refunded';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('ઇવેન્ટ પછીનું નિરીક્ષણ (Inspection)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('સુવિધા: ${b.amenityName} (${b.unitDisplay})', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('ડિપોઝિટ સ્ટેટસ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'refunded',
                      icon: Icon(Icons.check_circle, size: 16),
                      label: Text('રીફંડ (Refunded)'),
                    ),
                    ButtonSegment(
                      value: 'deducted',
                      icon: Icon(Icons.money_off, size: 16),
                      label: Text('જપ્ત (Deducted)'),
                    ),
                  ],
                  selected: {depositStatus},
                  onSelectionChanged: (val) => setDialogState(() => depositStatus = val.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'નિરીક્ષણ નોંધ (Inspection Note)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.updateDepositInspection(
                    bookingId: b.id,
                    depositStatus: depositStatus,
                    inspectionNotes: noteCtrl.text.trim(),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                child: const Text('સેવ કરો'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ટેબ ૨: એમેનિટીઝ ગોઠવણી & સેટઅપ ---
  Widget _buildAmenitiesSetupTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAmenityDialog(),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('નવી સુવિધા ઉમેરો', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<List<AmenityModel>>(
        stream: _service.getAllAmenitiesAdminStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final amenities = snapshot.data!;

          if (amenities.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('કોઈ સુવિધા ઉમેરેલ નથી.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addDefaultAmenities(),
                    child: const Text('ડિફૉલ્ટ સુવિધાઓ ઉમેરો (વાડી & હોલ)'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: amenities.length,
            itemBuilder: (context, idx) {
              final a = amenities[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    child: const Icon(Icons.domain_rounded, color: Color(0xFF0F766E)),
                  ),
                  title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'ક્ષમતા: ${a.capacity} | ભાડું: ₹${a.rentAmount.toStringAsFixed(0)} | ડિપોઝિટ: ₹${a.securityDeposit.toStringAsFixed(0)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _service.deleteAmenity(a.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addDefaultAmenities() async {
    await _service.saveAmenity(
      name: 'કોમ્યુનિટી હોલ / વાડી (Community Hall)',
      category: 'hall',
      capacity: 250,
      description: 'લગ્ન, સગાઈ, બર્થડે પાર્ટી કે સામાજિક પ્રસંગો માટે મોટો હોલ.',
      isPaid: true,
      rentAmount: 2000,
      securityDeposit: 1000,
      slotType: 'time_slots',
      availableSlots: ['આખો દિવસ (Full Day)', 'સવાર (Day: 9 AM - 4 PM)', 'સાંજ (Evening: 5 PM - 11 PM)'],
      rulesAndTerms: 'રાત્રે ૧૦ વાગ્યા પછી ડીજે/લાઉડસ્પીકર બંધ. સાફ-સફાઈ સભ્યની રહેશે.',
    );
  }

  void _showAddAmenityDialog() {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '100');
    final rentCtrl = TextEditingController(text: '0');
    final depCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    final rulesCtrl = TextEditingController(text: 'રાત્રે ૧૦ વાગ્યા પછી લાઉડસ્પીકર બંધ.');
    bool isPaid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('નવી એમેનિટી ઉમેરો', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'સુવિધાનું નામ (દા.ત. ક્લબહાઉસ, વાડી, ટેરેસ) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ક્ષમતા (મહેમાનો)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('પેઇડ સુવિધા (ભાડું / ડિપોઝિટ લાગશે?)'),
                    value: isPaid,
                    onChanged: (v) => setDialogState(() => isPaid = v),
                  ),
                  if (isPaid) ...[
                    TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ભાડું (₹)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: depCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'સિક્યોરિટી ડિપોઝિટ (₹ - રીફંડેબલ)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'સમજૂતી', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rulesCtrl,
                    decoration: const InputDecoration(labelText: 'નિયમો અને શરતો', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        await _service.saveAmenity(
                          name: nameCtrl.text.trim(),
                          category: 'hall',
                          capacity: int.tryParse(capCtrl.text) ?? 100,
                          description: descCtrl.text.trim(),
                          isPaid: isPaid,
                          rentAmount: double.tryParse(rentCtrl.text) ?? 0.0,
                          securityDeposit: double.tryParse(depCtrl.text) ?? 0.0,
                          slotType: 'full_day',
                          availableSlots: ['આખો દિવસ (Full Day)'],
                          rulesAndTerms: rulesCtrl.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                      child: const Text('ઉમેરો'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
