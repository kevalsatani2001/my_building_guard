import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/society_service.dart';

class WatchmanVehicleLookupSheet extends StatefulWidget {
  final Future<void> Function({
    required String memberUid,
    required String title,
    required String body,
    required String type,
  }) onNotifyMemberPush;
  final void Function(String msg, Color color) onShowSnackBar;

  const WatchmanVehicleLookupSheet({
    super.key,
    required this.onNotifyMemberPush,
    required this.onShowSnackBar,
  });

  static void show(
    BuildContext context, {
    required Future<void> Function({
      required String memberUid,
      required String title,
      required String body,
      required String type,
    }) onNotifyMemberPush,
    required void Function(String msg, Color color) onShowSnackBar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WatchmanVehicleLookupSheet(
        onNotifyMemberPush: onNotifyMemberPush,
        onShowSnackBar: onShowSnackBar,
      ),
    );
  }

  @override
  State<WatchmanVehicleLookupSheet> createState() =>
      _WatchmanVehicleLookupSheetState();
}

class _WatchmanVehicleLookupSheetState
    extends State<WatchmanVehicleLookupSheet> {
  final TextEditingController _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      widget.onShowSnackBar('માન્ય ફોન નંબર મળ્યો નથી', Colors.orange);
      return;
    }
    final launchUri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        widget.onShowSnackBar(
          'કૉલ શરૂ કરી શકાયો નહીં: $phoneNumber',
          Colors.red,
        );
      }
    } catch (e) {
      widget.onShowSnackBar('કૉલ ભૂલ: $e', Colors.red);
    }
  }

  Future<void> _sendWrongParkingAlert(
    Map<String, dynamic> v,
    String ownerUid,
  ) async {
    final plate = v['number'] ?? '';
    final name = v['ownerName'] ?? 'સભ્ય';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ખોટું પાર્કિંગ એલર્ટ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$name ને તેમના વાહન ($plate) માટે તાત્કાલિક ગાડી હટાવવાનું પાર્કિંગ નોટિફિકેશન મોકલવું છે?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'રદ કરો',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'એલર્ટ મોકલો',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final title = '🚨 વાહન હટાવવાની વિનંતી';
    final body =
        'તમારું વાહન ($plate) સોસાયટીમાં ખોટી જગ્યાએ પાર્ક છે અથવા રસ્તો રોકે છે. કૃપા કરીને તેને તાત્કાલિક યોગ્ય જગ્યાએ હટાવો.';

    try {
      final sid = SocietyService.instance.societyId;
      await widget.onNotifyMemberPush(
        memberUid: ownerUid,
        title: title,
        body: body,
        type: 'parking_alert',
      );

      await AppFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'targetUID': ownerUid,
        'societyId': sid,
        'type': 'parking_alert',
        'createdAt': FieldValue.serverTimestamp(),
        'skipTriggerPush': true,
        'deliveryMode': 'direct_callable',
      });

      widget.onShowSnackBar(
        'પાર્કિંગ એલર્ટ સફળતાપૂર્વક મોકલાયું!',
        Colors.green,
      );
    } catch (e) {
      widget.onShowSnackBar('એલર્ટ મોકલવામાં ભૂલ: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectiveBottomSafe = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "વાહન નંબર સર્ચ (Vehicle Lookup)",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "રહેવાસી વાહન વિગત અને પાર્કિંગ માહિતી",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF64748B),
                    splashRadius: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchC,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "ગાડી નંબર (દા.ત. GJ-01), મોડેલ કે ફ્લેટ શોધો...",
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchC.clear();
                            setState(() => _query = '');
                          },
                          color: const Color(0xFF64748B),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _query = val.trim().toUpperCase());
                },
              ),
            ),
            const SizedBox(height: 8),

            // Vehicles list / stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: AppFirestore.instance
                    .collection('users')
                    .where('societyId',
                        isEqualTo: SocietyService.instance.societyId)
                    .where('role', isEqualTo: 'member')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF4F46E5),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      isSearch: false,
                      query: '',
                      bottomPadding: effectiveBottomSafe,
                    );
                  }

                  final List<Map<String, dynamic>> allVehicles = [];
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final vehicles = data['vehicles'] as List<dynamic>? ?? [];
                    final ownerName = (data['name'] ?? '').toString();
                    final ownerPhone = (data['phone'] ?? '').toString();
                    final block = (data['blockName'] ?? '').toString();
                    final unit = (data['unitNumber'] ?? '').toString();
                    final flat = [block, unit]
                        .where((e) => e.isNotEmpty)
                        .join('-');

                    for (var v in vehicles) {
                      if (v is Map) {
                        final vMap = Map<String, dynamic>.from(v);
                        vMap['ownerUid'] = doc.id;
                        vMap['ownerName'] = ownerName;
                        vMap['ownerPhone'] = ownerPhone;
                        vMap['flat'] = flat;
                        allVehicles.add(vMap);
                      }
                    }
                  }

                  var filtered = allVehicles;
                  if (_query.isNotEmpty) {
                    filtered = allVehicles.where((v) {
                      final numStr =
                          (v['number'] ?? '').toString().toUpperCase();
                      final modelStr =
                          (v['model'] ?? '').toString().toUpperCase();
                      final ownerStr =
                          (v['ownerName'] ?? '').toString().toUpperCase();
                      final flatStr = (v['flat'] ?? '').toString().toUpperCase();

                      return numStr.contains(_query) ||
                          modelStr.contains(_query) ||
                          ownerStr.contains(_query) ||
                          flatStr.contains(_query);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return _buildEmptyState(
                      isSearch: _query.isNotEmpty,
                      query: _query,
                      bottomPadding: effectiveBottomSafe,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      20 + effectiveBottomSafe,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      final num = (v['number'] ?? '').toString();
                      final model = (v['model'] ?? '').toString();
                      final slot = (v['slot'] ?? '').toString();
                      final ownerName = (v['ownerName'] ?? '').toString();
                      final phone = (v['ownerPhone'] ?? '').toString();
                      final flat = (v['flat'] ?? '').toString();
                      final ownerUid = (v['ownerUid'] ?? '').toString();
                      final type = (v['type'] ?? '').toString();
                      final isCar = type.contains('4') ||
                          type.toLowerCase().contains('car');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Number plate styled badge with 1-tap copy
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: num));
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text('વાહન નંબર કોપી થયો: $num'),
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
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF0F172A),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A8A),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              "IND",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            num,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.copy_rounded,
                                            size: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Flat badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFC7D2FE),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.home_rounded,
                                          size: 13,
                                          color: Color(0xFF4F46E5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          flat.isNotEmpty
                                              ? 'ફ્લેટ $flat'
                                              : 'સોસાયટી',
                                          style: const TextStyle(
                                            color: Color(0xFF3730A3),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Vehicle details row
                              Row(
                                children: [
                                  Icon(
                                    isCar
                                        ? Icons.directions_car_rounded
                                        : Icons.two_wheeler_rounded,
                                    size: 16,
                                    color: const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      [
                                        if (model.isNotEmpty) model,
                                        if (slot.isNotEmpty)
                                          '🅿️ પાર્કિંગ: $slot',
                                      ].join(' • '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Resident info row
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ownerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 10),

                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (phone.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () => _makePhoneCall(phone),
                                      icon: const Icon(Icons.call_rounded,
                                          size: 15),
                                      label: const Text('કૉલ કરો'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF16A34A),
                                        side: const BorderSide(
                                          color: Color(0xFF86EFAC),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () => _sendWrongParkingAlert(
                                      v,
                                      ownerUid,
                                    ),
                                    icon: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 15,
                                    ),
                                    label: const Text('પાર્કિંગ એલર્ટ'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isSearch,
    required String query,
    double bottomPadding = 0,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + (bottomPadding > 0 ? bottomPadding : 16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isSearch
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSearch
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFC7D2FE),
                  width: 2,
                ),
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.directions_car_filled_rounded,
                size: 38,
                color: isSearch
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? "'$query' વાળું કોઈ વાહન મળ્યું નથી"
                  : "સોસાયટીમાં કોઈ વાહન નોંધાયેલ નથી",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? "ગાડી નંબર, મોડેલ અથવા ફ્લેટ નંબર ફરીથી ચકાસો."
                  : "હજુ સુધી કોઈ સભ્ય દ્વારા વાહનની નોંધણી કરવામાં આવી નથી.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (!isSearch)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "સભ્યો પોતાની પ્રોફાઇલમાંથી વાહન નંબર ઉમેરી શકે છે.",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  _searchC.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("બધા વાહનો જુઓ"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
