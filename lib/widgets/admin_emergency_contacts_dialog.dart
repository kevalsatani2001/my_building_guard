import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/society_service.dart';
import 'premium_ui.dart';

class AdminEmergencyContactsDialog extends StatefulWidget {
  const AdminEmergencyContactsDialog({
    super.key,
    this.initialContacts = const [],
  });

  static Future<void> show(BuildContext context) async {
    final sid = SocietyService.instance.societyId;
    var doc = await SocietyService.instance
        .societySettingsDoc(AppFirestore.instance)
        .get();
    if (!doc.exists && sid == SocietyService.kDefaultSocietyId) {
      doc = await AppFirestore.instance
          .collection('settings')
          .doc('society_config')
          .get();
    }
    final List<Map<String, dynamic>> contacts = [];
    if (doc.exists) {
      final raw = doc.data()?['emergencyContacts'];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            contacts.add({
              'name': '${e['name'] ?? ''}',
              'phone': '${e['phone'] ?? ''}',
            });
          }
        }
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AdminEmergencyContactsDialog._(initialContacts: contacts),
    );
  }

  final List<Map<String, dynamic>> initialContacts;

  AdminEmergencyContactsDialog._({
    required this.initialContacts,
  });

  @override
  State<AdminEmergencyContactsDialog> createState() =>
      _AdminEmergencyContactsDialogState();
}

class _AdminEmergencyContactsDialogState
    extends State<AdminEmergencyContactsDialog> {
  late final List<Map<String, dynamic>> _contacts;
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();

  final List<(String, String)> _presets = [
    ('પોલીસ'.tr, '100'),
    ('એમ્બ્યુલન્સ'.tr, '108'),
    ('ફાયર બ્રિગેડ'.tr, '101'),
    ('ઇલેક્ટ્રિશિયન'.tr, ''),
    ('પ્લમ્બર'.tr, ''),
    ('લિફ્ટ સર્વિસ'.tr, ''),
  ];

  @override
  void initState() {
    super.initState();
    _contacts = List.from(widget.initialContacts);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  void _addContact() {
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() {
      _contacts.add({'name': name, 'phone': phone});
      _nameC.clear();
      _phoneC.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: PremiumDialogHeader(
        title: 'ઈમરજન્સી કોન્ટેક્ટ્સ'.tr,
        subtitle: 'સોસાયટી સભ્યો માટે તાત્કાલિક હેલ્પલાઇન'.tr,
        icon: Icons.phone_in_talk_rounded,
        accentColor: Colors.red.shade700,
        onClose: () => Navigator.pop(context),
      ),
      content: SizedBox(
        width: 380,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick preset chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 14, color: Colors.red),
                      label: Text(
                        preset.$2.isNotEmpty ? '${preset.$1} (${preset.$2})' : preset.$1,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.red.shade50,
                      side: BorderSide(color: Colors.red.shade200),
                      onPressed: () {
                        setState(() {
                          _nameC.text = preset.$1;
                          _phoneC.text = preset.$2;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Input card to add new contact
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameC,
                          decoration: InputDecoration(
                            hintText: 'સેવાનું નામ (દા.ત. લિફ્ટ)'.tr,
                            prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneC,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'ફોન નંબર'.tr,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text('લિસ્ટમાં ઉમેરો'.tr, style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Contact List
            Expanded(
              child: _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.contact_phone_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'હજુ કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના સૂચન બટન પર ક્લિક કરીને ઉમેરો.'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _contacts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final c = _contacts[i];
                        final name = (c['name'] ?? '').toString();
                        final phone = (c['phone'] ?? '').toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                child: const Icon(Icons.phone_rounded, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      phone,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _contacts.removeAt(i)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('રદ'.tr),
        ),
        FilledButton.icon(
          onPressed: () async {
            await SocietyService.instance
                .societySettingsDoc(AppFirestore.instance)
                .set({
              'emergencyContacts': _contacts,
            }, SetOptions(merge: true));
            await SocietyService.instance.mirrorLegacySocietyConfig({
              'emergencyContacts': _contacts,
            });
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ઈમરજન્સી કોન્ટેક્ટ્સ સેવ થઈ ગયા!'.tr),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: Text('સાચવો'.tr),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
        ),
      ],
    );
  }
}
