import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/amenity_model.dart';
import '../models/user_model.dart';
import '../services/amenity_booking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';

class MemberAmenitiesScreen extends StatefulWidget {
  const MemberAmenitiesScreen({super.key});

  @override
  State<MemberAmenitiesScreen> createState() => _MemberAmenitiesScreenState();
}

class _MemberAmenitiesScreenState extends State<MemberAmenitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AmenityBookingService _service = AmenityBookingService.instance;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await AppFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!, uid);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoadingUser = false);
  }

  String get _memberFlatDisplay {
    if (_currentUser == null) return '';
    final block = _currentUser!.blockName ?? _currentUser!.subGroup ?? '';
    final unit = _currentUser!.unitNumber ?? '';
    if (block.isNotEmpty && unit.isNotEmpty) return '$block-$unit';
    return unit.isNotEmpty ? unit : block;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
              'એમેનિટીઝ & હોલ બુકિંગ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            Text(
              'વાડી, પાર્ટી હોલ & સુવિધાઓનું બુકિંગ',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: '🏛️ સુવિધાઓ (Amenities)'),
            Tab(text: '🎫 મારાં બુકિંગ્સ (My Bookings)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAmenitiesList(),
          _buildMyBookingsList(currentUid),
        ],
      ),
    );
  }

  // --- ટેબ ૧: ઉપલબ્ધ એમેનિટીઝ લિસ્ટ ---
  Widget _buildAmenitiesList() {
    return StreamBuilder<List<AmenityModel>>(
      stream: _service.getActiveAmenitiesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final amenities = snapshot.data!;

        if (amenities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'અત્યારે કોઈ એમેનિટી ઉપલબ્ધ નથી.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: amenities.length,
          itemBuilder: (context, idx) {
            final a = amenities[idx];
            return _buildAmenityCard(a);
          },
        );
      },
    );
  }

  Widget _buildAmenityCard(AmenityModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.domain_rounded, color: Color(0xFF0F766E), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ક્ષમતા: ${a.capacity} મહેમાનો',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: a.isPaid ? const Color(0xFFFFFBEB) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: a.isPaid ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    a.isPaid ? '₹ ${a.rentAmount.toStringAsFixed(0)} / દિવસ' : 'મફત (Free)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: a.isPaid ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(a.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4)),
            ],
            if (a.isPaid && a.securityDeposit > 0) ...[
              const SizedBox(height: 6),
              Text(
                '• રીફંડેબલ સિક્યોરિટી ડિપોઝિટ: ₹ ${a.securityDeposit.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
              ),
            ],
            if (a.rulesAndTerms.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '• શરતો: ${a.rulesAndTerms}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showBookingDialog(a),
                icon: const Icon(Icons.event_available_rounded, size: 16),
                label: const Text('તારીખ & સ્લોટ બુક કરો', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- બુકિંગ ફોર્મ ડાયલોગ ---
  void _showBookingDialog(AmenityModel a) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = a.availableSlots.isNotEmpty ? a.availableSlots.first : 'આખો દિવસ (Full Day)';
    final purposeCtrl = TextEditingController();
    final guestCtrl = TextEditingController(text: '50');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${a.name} બુકિંગ',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('બુકિંગ તારીખ પસંદ કરો:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy (EEEE)').format(selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F766E)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slot selector
                  if (a.availableSlots.length > 1) ...[
                    const Text('સમય / સ્લોટ પસંદ કરો:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: a.availableSlots.map((slot) {
                        final isSel = selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSel,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedSlot = slot);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Purpose
                  TextField(
                    controller: purposeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'પ્રસંગ / હેતુ *',
                      hintText: 'દા.ત. સગાઈ, બર્થડે પાર્ટી, પારિવારિક ગેટ-ટુગેધર',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Guests
                  TextField(
                    controller: guestCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'અંદાજિત મહેમાનોની સંખ્યા',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing Summary Box
                  if (a.isPaid)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ભાડું + સિક્યોરિટી ડિપોઝિટ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            '₹ ${(a.rentAmount + a.securityDeposit).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final purpose = purposeCtrl.text.trim();
                        if (purpose.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('કૃપા કરીને પ્રસંગ/હેતુ લખો.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        try {
                          await _service.submitBookingRequest(
                            amenity: a,
                            bookingDate: selectedDate,
                            slotName: selectedSlot,
                            purpose: purpose,
                            expectedGuests: int.tryParse(guestCtrl.text) ?? 50,
                            memberName: _currentUser?.name ?? 'સભ્ય',
                            memberPhone: _currentUser?.phone ?? '',
                            unitDisplay: _memberFlatDisplay,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ બુકિંગ રિક્વેસ્ટ એડમિનને સફળતાપૂર્વક મોકલાઈ ગઈ છે.'),
                                backgroundColor: Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _tabController.animateTo(1);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('રિક્વેસ્ટ સબમિટ કરો', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

  // --- ટેબ ૨: મારાં બુકિંગ્સ ---
  Widget _buildMyBookingsList(String currentUid) {
    return StreamBuilder<List<AmenityBookingModel>>(
      stream: _service.getMemberBookingsStream(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final bookings = snapshot.data!;

        if (bookings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('આપે હજુ સુધી કોઈ સુવિધા બુક કરેલ નથી.'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, idx) {
            final b = bookings[idx];
            return _buildMemberBookingCard(b);
          },
        );
      },
    );
  }

  Widget _buildMemberBookingCard(AmenityBookingModel b) {
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
        statusLabel = 'ચકાસણી હેઠળ (Under Review)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.amenityName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'પ્રસંગ: ${b.purpose} • તારીખ: ${DateFormat('dd/MM/yyyy').format(b.bookingDate)} (${b.slotName})',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
          ),

          // Event Gate Pass Code Box (If Approved)
          if (b.isApproved && b.eventPassCode.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                      const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      const Text(
                        'મહેમાન ગેટ એન્ટ્રી પાસકોડ (Event Gate Pass):',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                      ),
                      const Spacer(),
                      Text(
                        b.eventPassCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final msg = 'નમસ્તે 🙏, આપને અમારા શુભ પ્રસંગ (${b.purpose}) માં આવવા હાર્દિક આમંત્રણ છે.\n\n📍 સ્થળ: ${b.amenityName}\n📅 તારીખ: ${DateFormat('dd/MM/yyyy').format(b.bookingDate)}\n🔐 સોસાયટી ગેટ એન્ટ્રી પાસકોડ: *${b.eventPassCode}*\n\nગેટ પર આ પાસકોડ બતાવવાથી તુરંત પ્રવેશ મળશે.';
                        launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.share_rounded, size: 14, color: Colors.white),
                      label: const Text('WhatsApp પર મહેમાનોને પાસકોડ શેર કરો', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
