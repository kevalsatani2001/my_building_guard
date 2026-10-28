import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/society_service.dart';
import '../../widgets/premium_app_bar.dart';

class _PresetItem {
  final String titleKey;
  final String defaultTitle;
  final String phone;
  final IconData icon;
  final Color color;
  final String tag;

  const _PresetItem({
    required this.titleKey,
    required this.defaultTitle,
    required this.phone,
    required this.icon,
    required this.color,
    required this.tag,
  });

  String get localizedTitle => titleKey.tr;
}

class _ContactVisualMeta {
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradient;
  final String tag;

  const _ContactVisualMeta({
    required this.icon,
    required this.primaryColor,
    required this.gradient,
    required this.tag,
  });
}

class AdminEmergencyContactsScreen extends StatefulWidget {
  const AdminEmergencyContactsScreen({super.key});

  @override
  State<AdminEmergencyContactsScreen> createState() => _AdminEmergencyContactsScreenState();
}

class _AdminEmergencyContactsScreenState extends State<AdminEmergencyContactsScreen> {
  final _titleC = TextEditingController();
  final _phoneC = TextEditingController();
  final _searchC = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isAdding = false;
  String _searchQuery = '';

  static const List<_PresetItem> _quickPresets = [
    _PresetItem(
      titleKey: 'preset_police',
      defaultTitle: 'પોલીસ',
      phone: '100',
      icon: Icons.local_police_rounded,
      color: Color(0xFF2563EB),
      tag: 'પોલીસ',
    ),
    _PresetItem(
      titleKey: 'preset_ambulance',
      defaultTitle: 'એમ્બ્યુલન્સ',
      phone: '108',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE11D48),
      tag: 'મેડિકલ',
    ),
    _PresetItem(
      titleKey: 'preset_fire_brigade',
      defaultTitle: 'ફાયર બ્રિગેડ',
      phone: '101',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEA580C),
      tag: 'અગ્નિશામક',
    ),
    _PresetItem(
      titleKey: 'ડિઝાસ્ટર હેલ્પલાઇન',
      defaultTitle: 'ડિઝાસ્ટર હેલ્પલાઇન',
      phone: '1077',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFF7C3AED),
      tag: 'આપત્તિ',
    ),
    _PresetItem(
      titleKey: 'મહિલા હેલ્પલાઇન',
      defaultTitle: 'મહિલા હેલ્પલાઇન',
      phone: '1091',
      icon: Icons.support_agent_rounded,
      color: Color(0xFFDB2777),
      tag: 'સુરક્ષા',
    ),
    _PresetItem(
      titleKey: 'preset_electrician',
      defaultTitle: 'ઇલેક્ટ્રિશિયન',
      phone: '',
      icon: Icons.bolt_rounded,
      color: Color(0xFFD97706),
      tag: 'મેન્ટેનન્સ',
    ),
    _PresetItem(
      titleKey: 'preset_plumber',
      defaultTitle: 'પ્લમ્બર',
      phone: '',
      icon: Icons.plumbing_rounded,
      color: Color(0xFF0284C7),
      tag: 'મેન્ટેનન્સ',
    ),
    _PresetItem(
      titleKey: 'preset_lift_service',
      defaultTitle: 'લિફ્ટ સર્વિસ',
      phone: '',
      icon: Icons.elevator_rounded,
      color: Color(0xFF4F46E5),
      tag: 'મેન્ટેનન્સ',
    ),
    _PresetItem(
      titleKey: 'વોચમેન કેબિન',
      defaultTitle: 'વોચમેન કેબિન',
      phone: '',
      icon: Icons.shield_rounded,
      color: Color(0xFF059669),
      tag: 'ગેટ સિક્યોરિટી',
    ),
  ];

  @override
  void dispose() {
    _titleC.dispose();
    _phoneC.dispose();
    _searchC.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("કૉલ શરૂ કરી શકાયો નહીં: $phone".tr),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ: $e".tr), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Future<void> _addContact({String? customTitle, String? customPhone}) async {
    final title = (customTitle ?? _titleC.text).trim();
    final phone = (customPhone ?? _phoneC.text).trim();

    if (title.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("કૃપા કરીને સેવાનું નામ અને નંબર બંને દાખલ કરો.".tr),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final sid = SocietyService.instance.societyId;

      // Duplicate check for convenience
      final existing = await AppFirestore.instance
          .collection('emergency_contacts')
          .where('societyId', isEqualTo: sid)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text("આ નંબર ($phone) પહેલેથી જ ઈમરજન્સી લિસ્ટમાં છે.".tr)),
              ],
            ),
            backgroundColor: const Color(0xFFB45309),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await AppFirestore.instance.collection('emergency_contacts').add({
        'title': title,
        'phone': phone,
        'societyId': sid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleC.clear();
      _phoneC.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("'$title' ($phone) ઈમરજન્સી ડિરેક્ટરીમાં ઉમેરાઈ ગયું!".tr)),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ: $e".tr), backgroundColor: Colors.red.shade800),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _seedDefaultHelplines() async {
    setState(() => _isAdding = true);
    try {
      final sid = SocietyService.instance.societyId;
      final defaults = [
        {'title': 'preset_police'.tr, 'phone': '100'},
        {'title': 'preset_ambulance'.tr, 'phone': '108'},
        {'title': 'preset_fire_brigade'.tr, 'phone': '101'},
      ];

      final batch = AppFirestore.instance.batch();
      final col = AppFirestore.instance.collection('emergency_contacts');

      for (final item in defaults) {
        final docRef = col.doc();
        batch.set(docRef, {
          'title': item['title'],
          'phone': item['phone'],
          'societyId': sid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("પોલીસ (100), ૧૦૮ અને ફાયર (101) સંપર્કો સફળતાપૂર્વક ઉમેરાયા!".tr)),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ભૂલ: $e".tr), backgroundColor: Colors.red.shade800),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _confirmDeleteContact(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "સંપર્ક ડિલીટ કરવો છે?".tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          "શું તમે ખરેખર '$title' ને ઈમરજન્સી લિસ્ટમાંથી દૂર કરવા માંગો છો? આના પછી વોચમેન અથવા સભ્યો આ નંબર જોઈ શકશે નહીં.".tr,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "રદ કરો".tr,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text("ડિલીટ કરો".tr, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppFirestore.instance.collection('emergency_contacts').doc(docId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'$title' સફળતાપૂર્વક દૂર કરવામાં આવ્યું.".tr),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ભૂલ: $e".tr), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  _ContactVisualMeta _getContactVisualMeta(String title, String phone) {
    final text = '$title $phone'.toLowerCase();

    // Police / Law enforcement
    if (text.contains('પોલીસ') || text.contains('police') || text.contains('100') || text.contains('112') || text.contains('સુરક્ષા')) {
      return const _ContactVisualMeta(
        icon: Icons.local_police_rounded,
        primaryColor: Color(0xFF2563EB),
        gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        tag: 'પોલીસ સુરક્ષા',
      );
    }

    // Medical / Hospital / Doctor / 108
    if (text.contains('એમ્બ્યુલન્સ') ||
        text.contains('ambulance') ||
        text.contains('108') ||
        text.contains('મેડિકલ') ||
        text.contains('doctor') ||
        text.contains('ડોક્ટર') ||
        text.contains('hospital') ||
        text.contains('દવાખાનું')) {
      return const _ContactVisualMeta(
        icon: Icons.medical_services_rounded,
        primaryColor: Color(0xFFE11D48),
        gradient: [Color(0xFFF43F5E), Color(0xFFBE123C)],
        tag: 'મેડિકલ ઇમરજન્સી',
      );
    }

    // Fire brigade / 101
    if (text.contains('ફાયર') || text.contains('fire') || text.contains('101') || text.contains('આગ')) {
      return const _ContactVisualMeta(
        icon: Icons.local_fire_department_rounded,
        primaryColor: Color(0xFFEA580C),
        gradient: [Color(0xFFF97316), Color(0xFFC2410C)],
        tag: 'અગ્નિશામક સેવા',
      );
    }

    // Lift Service
    if (text.contains('લિફ્ટ') || text.contains('lift') || text.contains('elevator')) {
      return const _ContactVisualMeta(
        icon: Icons.elevator_rounded,
        primaryColor: Color(0xFF4F46E5),
        gradient: [Color(0xFF6366F1), Color(0xFF4338CA)],
        tag: 'લિફ્ટ ટેકનિશિયન',
      );
    }

    // Electrician / Power
    if (text.contains('ઇલેક્ટ્રિ') || text.contains('electric') || text.contains('લાઈટ') || text.contains('power')) {
      return const _ContactVisualMeta(
        icon: Icons.bolt_rounded,
        primaryColor: Color(0xFFD97706),
        gradient: [Color(0xFFF59E0B), Color(0xFFB45309)],
        tag: 'ઇલેક્ટ્રિકલ સેવા',
      );
    }

    // Plumber / Water
    if (text.contains('પ્લમ્બર') || text.contains('plumb') || text.contains('પાણી') || text.contains('water')) {
      return const _ContactVisualMeta(
        icon: Icons.plumbing_rounded,
        primaryColor: Color(0xFF0284C7),
        gradient: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
        tag: 'પ્લમ્બિંગ સેવા',
      );
    }

    // Watchman / Security Gate
    if (text.contains('વોચમેન') || text.contains('ગેટ') || text.contains('guard') || text.contains('gate') || text.contains('સિક્યોરિટી')) {
      return const _ContactVisualMeta(
        icon: Icons.shield_rounded,
        primaryColor: Color(0xFF059669),
        gradient: [Color(0xFF10B981), Color(0xFF047857)],
        tag: 'ગેટ સિક્યોરિટી',
      );
    }

    // Women Helpline
    if (text.contains('મહિલા') || text.contains('women') || text.contains('1091')) {
      return const _ContactVisualMeta(
        icon: Icons.support_agent_rounded,
        primaryColor: Color(0xFFDB2777),
        gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
        tag: 'મહિલા સહાય',
      );
    }

    // Disaster Helpline
    if (text.contains('ડિઝાસ્ટર') || text.contains('disaster') || text.contains('1077') || text.contains('આપત્તિ')) {
      return const _ContactVisualMeta(
        icon: Icons.warning_amber_rounded,
        primaryColor: Color(0xFF7C3AED),
        gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        tag: 'આપત્તિ વ્યવસ્થાપન',
      );
    }

    // Default Emergency Contact
    return const _ContactVisualMeta(
      icon: Icons.phone_in_talk_rounded,
      primaryColor: Color(0xFFDC2626),
      gradient: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      tag: 'ઈમરજન્સી હેલ્પલાઇન',
    );
  }

  Widget _buildPresetCard(_PresetItem item) {
    final title = item.localizedTitle;
    final hasNumber = item.phone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.color.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (hasNumber) {
              _addContact(customTitle: title, customPhone: item.phone);
            } else {
              setState(() {
                _titleC.text = title;
                _phoneC.text = "";
              });
              _phoneFocusNode.requestFocus();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("કૃપા કરીને '$title' નો નંબર દાખલ કરો.".tr),
                  backgroundColor: item.color,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, size: 19, color: item.color),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasNumber)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.phone,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: item.color,
                          ),
                        ),
                      )
                    else
                      Text(
                        "+ નંબર ઉમેરો".tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> data, String docId) {
    final title = (data['title'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final meta = _getContactVisualMeta(title, phone);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color-coded vertical indicator stripe
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: meta.gradient,
                ),
              ),
            ),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    // Squircle Icon Badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: meta.gradient,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: meta.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(meta.icon, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tag pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: meta.primaryColor.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meta.tag.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: meta.primaryColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Contact Title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Copyable Phone Pill
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: phone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text("નંબર કોપી કર્યો: $phone".tr)),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF0F172A),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.call_rounded, size: 12, color: meta.primaryColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.copy_rounded, size: 11, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Actions: Call button & Delete button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // High-End Call Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _makeCall(phone),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      "કૉલ".tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Delete Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmDeleteContact(docId, title),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 19),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: "ઈમરજન્સી હેલ્પલાઇન ડિરેક્ટરી".tr,
        subtitle: "પોલીસ, ૧૦૮, ફાયર અને તાત્કાલિક સેવાઓ".tr,
        icon: Icons.emergency_rounded,
        accentColor: const Color(0xFFDC2626),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Emergency 3D Banner
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/emergency_hero.jpg',
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                    // Dark scrim gradient on left for crystal clear readability
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.82),
                            Colors.black.withValues(alpha: 0.40),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 13,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shield_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '૨૪x૭ તાત્કાલિક સેવાઓ'.tr,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  "ઇમરજન્સી હેલ્પલાઇન".tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "તમામ સભ્યો અને વોચમેન આ નંબરો પર ૧-ટેપથી કૉલ કરી શકશે.".tr,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            flex: 8,
                            child: SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Quick Presets Row Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 8),
                Text(
                  "ઝડપી પ્રીસેટ્સ (૧-ટેપથી ઉમેરો):".tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Presets Horizontal Scrolling List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _quickPresets.map(_buildPresetCard).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Add Custom Contact Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.contact_phone_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "નવો ઈમરજન્સી સંપર્ક ઉમેરો:".tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "વોચમેન અને રહેવાસીઓને તાત્કાલિક મદદ માટે".tr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Service Name Input
                  TextField(
                    controller: _titleC,
                    decoration: InputDecoration(
                      labelText: "સેવા / વ્યક્તિનું નામ *".tr,
                      hintText: "દા.ત. સુરત ફાયર કંટ્રોલ, ડૉ. પટેલ".tr,
                      prefixIcon: const Icon(Icons.badge_rounded, size: 20, color: Color(0xFFDC2626)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone Number Input
                  TextField(
                    controller: _phoneC,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "સંપર્ક નંબર (Phone Number) *".tr,
                      hintText: "દા.ત. 101 અથવા 9876543210".tr,
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFFDC2626)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11D48), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isAdding ? null : () => _addContact(),
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: _isAdding
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "સંપર્ક સેવ કરો".tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Active Contacts List Header
            StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.instance
                  .collection('emergency_contacts')
                  .where('societyId', isEqualTo: SocietyService.instance.societyId)
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.hasData ? snap.data!.docs.length : 0;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "હાલની ઈમરજન્સી હેલ્પલાઇન લિસ્ટ:".tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        "$count સંપર્કો".tr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Active Contacts List Stream
            StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.instance
                  .collection('emergency_contacts')
                  .where('societyId', isEqualTo: SocietyService.instance.societyId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snap.hasData ? List<QueryDocumentSnapshot>.from(snap.data!.docs) : <QueryDocumentSnapshot>[];

                // Client-side sort by createdAt so composite Firestore index is not strictly required
                docs.sort((a, b) {
                  final da = a.data() as Map<String, dynamic>;
                  final db = b.data() as Map<String, dynamic>;
                  final ta = (da['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final tb = (db['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return ta.compareTo(tb);
                });

                // Filter by search query if present
                final filteredDocs = _searchQuery.trim().isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final t = (data['title'] ?? '').toString().toLowerCase();
                        final p = (data['phone'] ?? '').toString().toLowerCase();
                        final q = _searchQuery.trim().toLowerCase();
                        return t.contains(q) || p.contains(q);
                      }).toList();

                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                          ),
                          child: const Icon(Icons.shield_outlined, size: 30, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.".tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "સોસાયટી સુરક્ષા માટે પોલીસ, ૧૦૮ અને ફાયર નંબર તાત્કાલિક સેટ કરો.".tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _isAdding ? null : () => _seedDefaultHelplines(),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                          label: Text(
                            "મુખ્ય નંબરો ઉમેરો (પોલીસ, 108, 101)".tr,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Search bar when there are 4 or more contacts
                    if (docs.length >= 4) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchC,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: "સંપર્ક અથવા નંબર શોધો...".tr,
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                    onPressed: () {
                                      _searchC.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ],

                    // Cards List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, i) {
                        final d = filteredDocs[i].data() as Map<String, dynamic>;
                        final docId = filteredDocs[i].id;
                        return _buildContactCard(d, docId);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
