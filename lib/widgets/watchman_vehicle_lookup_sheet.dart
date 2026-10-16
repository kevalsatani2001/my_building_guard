import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      builder: (ctx) => AlertDialog(
        title: const Text('🚨 ખોટું પાર્કિંગ એલર્ટ'),
        content: Text(
          '$name ને વાહન ($plate) હટાવવા માટે તાત્કાલિક નોટિફિકેશન મોકલવું છે?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('રદ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('એલર્ટ મોકલો'),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // હેડર
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car_rounded, color: cs.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "વાહન નંબર સર્ચ (Vehicle Lookup)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // સર્ચ બાર
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchC,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "ગાડી નંબર શોધો (દા.ત. GJ01, 1234, Swift)...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchC.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onChanged: (val) {
                setState(() => _query = val.trim().toUpperCase());
              },
            ),
          ),

          // વાહનોની યાદી
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("સોસાયટીમાં કોઈ સભ્યો મળ્યા નથી."),
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? "સોસાયટીમાં હજુ સુધી કોઈ વાહનો નોંધાયેલા નથી."
                              : "'$_query' વાળું કોઈ વાહન મળ્યું નથી.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final v = filtered[index];
                    final num = v['number'] ?? '';
                    final model = v['model'] ?? '';
                    final slot = v['slot'] ?? '';
                    final ownerName = v['ownerName'] ?? '';
                    final phone = v['ownerPhone'] ?? '';
                    final flat = v['flat'] ?? '';
                    final ownerUid = v['ownerUid'] ?? '';
                    final type = (v['type'] ?? '').toString();
                    final isCar = type.contains('4') ||
                        type.toLowerCase().contains('car');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: cs.primary
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    isCar
                                        ? Icons.directions_car_rounded
                                        : Icons.two_wheeler_rounded,
                                    color: cs.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        num,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        [
                                          if (model.isNotEmpty) model,
                                          if (slot.isNotEmpty)
                                            'પાર્કિંગ સ્લોટ: $slot',
                                        ].join(' • '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    flat.isNotEmpty ? flat : 'ફ્લેટ -',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (phone.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _makePhoneCall(phone),
                                    icon: const Icon(Icons.call, size: 16),
                                    label: const Text('કૉલ કરો'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Colors.green.shade700,
                                      side: BorderSide(
                                        color: Colors.green.shade400,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _sendWrongParkingAlert(
                                    v,
                                    ownerUid,
                                  ),
                                  icon: const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('પાર્કિંગ એલર્ટ'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
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
    );
  }
}
