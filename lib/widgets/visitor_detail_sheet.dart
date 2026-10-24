import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visitor_model.dart';
import 'package:building_guard/l10n/app_strings.dart';

class VisitorDetailSheet extends StatelessWidget {
  final VisitorModel visitor;
  final bool isMyFlat;
  final Future<void> Function(String docId, String status)? onStatusUpdate;

  const VisitorDetailSheet({
    super.key,
    required this.visitor,
    required this.isMyFlat,
    this.onStatusUpdate,
  });

  static Future<void> show(
    BuildContext context, {
    required VisitorModel visitor,
    required bool isMyFlat,
    Future<void> Function(String docId, String status)? onStatusUpdate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VisitorDetailSheet(
        visitor: visitor,
        isMyFlat: isMyFlat,
        onStatusUpdate: onStatusUpdate,
      ),
    );
  }

  Future<void> _makeCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('માન્ય ફોન નંબર મળ્યો નથી.'.tr)),
      );
      return;
    }
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone = clean.length == 10 ? '91$clean' : clean;
    final guestText = 'મહેમાન'.tr;
    final uri = Uri.parse('https://wa.me/$intlPhone?text=નમસ્તે%20${visitor.name.isNotEmpty ? visitor.name : guestText},%20સોસાયટી%20ગેટ%20પાસ%20સંદર્ભે.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareVisitorDetails(BuildContext context) {
    final duration = _calculateStayDuration();
    final text = '''
🏢 *સોસાયટી વિઝિટર ગેટ પાસ વિગત*
━━━━━━━━━━━━━━━━━━
👤 મુલાકાતી: ${visitor.name.isNotEmpty ? visitor.name : 'અનામી'.tr}
📞 ફોન: ${visitor.phone.isNotEmpty ? visitor.phone : 'ઉપલબ્ધ નથી'.tr}
🎯 હેતુ: ${visitor.purpose.isNotEmpty ? visitor.purpose : 'મુલાકાત'.tr}
🏠 લક્ષ્ય ફ્લેટ: ${visitor.flatDisplay}
📌 સ્ટેટસ: ${_getStatusTitle()}
⏰ પ્રવેશ સમય: ${DateFormat('dd MMM yyyy, hh:mm a').format(visitor.entryTime)}
${visitor.exitTime != null ? '🚪 બહાર ગયા: ${DateFormat('dd MMM yyyy, hh:mm a').format(visitor.exitTime!)}' : ''}
⏱️ રોકાણ: $duration
━━━━━━━━━━━━━━━━━━
🛡️ My Building Guard Security System
''';
    SharePlus.instance.share(
      ShareParams(
        text: text.trim(),
        subject: 'વિઝિટર ગેટ પાસ વિગત - ${visitor.flatDisplay}'.tr,
      ),
    );
  }

  String _getStatusTitle() {
    return switch (visitor.status) {
      'approved' => 'પ્રવેશ મંજૂર (Approved)'.tr,
      'rejected' => 'પ્રવેશ નકાર્યો (Rejected)'.tr,
      'checked_out' => 'સોસાયટીમાંથી બહાર ગયા (Checked-out)'.tr,
      _ => 'મંજૂરીની રાહ (Pending Approval)'.tr,
    };
  }

  String _calculateStayDuration() {
    final end = visitor.exitTime ?? DateTime.now();
    final diff = end.difference(visitor.entryTime);
    if (diff.isNegative) return 'હમણાં જ આવ્યા'.tr;

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (visitor.status == 'checked_out') {
      if (hours > 0) return '$hours કલાક $minutes મિનિટ રોકાણ'.tr;
      return '$minutes મિનિટ રોકાણ'.tr;
    } else {
      if (hours > 0) return '$hours કલાક $minutes મિનિટથી અંદર છે'.tr;
      return '$minutes મિનિટથી અંદર છે'.tr;
    }
  }

  (IconData, Color, Color) _getVisitorMeta() {
    final p = visitor.purpose.toLowerCase();
    if (p.contains('swiggy') || p.contains('zomato') || p.contains('food') || p.contains('ખાવાનું'.tr)) {
      return (Icons.fastfood_rounded, const Color(0xFFEA580C), const Color(0xFFFFF7ED));
    }
    if (p.contains('amazon') || p.contains('flipkart') || p.contains('courier') || p.contains('પાર્સલ'.tr)) {
      return (Icons.local_shipping_rounded, const Color(0xFF0284C7), const Color(0xFFF0F9FF));
    }
    if (p.contains('blinkit') || p.contains('zepto') || p.contains('grocery') || p.contains('શાકભાજી'.tr)) {
      return (Icons.shopping_basket_rounded, const Color(0xFF16A34A), const Color(0xFFF0FDF4));
    }
    if (p.contains('cab') || p.contains('uber') || p.contains('ola') || p.contains('rapido')) {
      return (Icons.local_taxi_rounded, const Color(0xFFCA8A04), const Color(0xFFFEFCE8));
    }
    if (p.contains('maid') || p.contains('કામવાળા'.tr) || p.contains('કૂક'.tr) || p.contains('cook')) {
      return (Icons.cleaning_services_rounded, const Color(0xFF9333EA), const Color(0xFFFAF5FF));
    }
    if (p.contains('plumber') || p.contains('electrician') || p.contains('રિપેર'.tr) || p.contains('repair')) {
      return (Icons.handyman_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2));
    }
    return (Icons.person_rounded, const Color(0xFF4F46E5), const Color(0xFFEEF2FF));
  }

  @override
  Widget build(BuildContext context) {
    final isPending = visitor.status == 'pending';
    final (typeIcon, typeColor, typeBg) = _getVisitorMeta();
    final canAction = isPending && isMyFlat && onStatusUpdate != null;

    final (statusColor, statusBg, statusText, statusIcon) = switch (visitor.status) {
      'approved' => (const Color(0xFF059669), const Color(0xFFECFDF5), 'પ્રવેશ મંજૂર (Approved)'.tr, Icons.check_circle_rounded),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'પ્રવેશ નકાર્યો (Rejected)'.tr, Icons.cancel_rounded),
      'checked_out' => (const Color(0xFF475569), const Color(0xFFF1F5F9), 'બહાર ગયા (Checked Out)'.tr, Icons.logout_rounded),
      _ => (const Color(0xFFD97706), const Color(0xFFFFFBEB), 'મંજૂરીની રાહ (Pending)'.tr, Icons.hourglass_top_rounded),
    };

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'વિઝિટર સંપૂર્ણ વિગતો'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'શેર કરો'.tr,
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF0284C7)),
                  onPressed: () => _shareVisitorDetails(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Visitor Profile Hero Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Photo Avatar with Dialog Preview on tap
                        GestureDetector(
                          onTap: visitor.photoUrl.isNotEmpty
                              ? () => _showFullImageDialog(context, visitor.photoUrl)
                              : null,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: visitor.photoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: visitor.photoUrl,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => _fallbackAvatar(),
                                      )
                                    : _fallbackAvatar(),
                              ),
                              if (visitor.photoUrl.isNotEmpty)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visitor.name.isNotEmpty ? visitor.name : "અનામી મુલાકાતી".tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Purpose Tag
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: typeBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(typeIcon, size: 12, color: typeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          visitor.purpose.isNotEmpty ? visitor.purpose : 'સામાન્ય મુલાકાત'.tr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF475569)),
                                        const SizedBox(width: 4),
                                        Text(
                                          visitor.flatDisplay,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 13, color: statusColor),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Quick Communication Strip (Call & WhatsApp)
                  if (visitor.phone.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makeCall(context, visitor.phone),
                            icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 17),
                            label: Text(
                              'કૉલ: ${visitor.phone}'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openWhatsApp(context, visitor.phone),
                            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 17),
                            label: Text(
                              'વોટ્સએપ'.tr,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. Complete Detail Metrics Grid
                  Text(
                    'ચકાસણી અને સમય વિગત (Verification & Logs):'.tr,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.login_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'પ્રવેશ સમય (Entry Time)'.tr,
                          value: DateFormat('dd MMM yyyy, hh:mm:ss a').format(visitor.entryTime),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoTile(
                          icon: Icons.logout_rounded,
                          iconColor: visitor.exitTime != null ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                          title: 'બહાર ગયા (Exit Time)'.tr,
                          value: visitor.exitTime != null
                              ? DateFormat('dd MMM yyyy, hh:mm:ss a').format(visitor.exitTime!)
                              : 'હજુ સોસાયટીની અંદર જ છે'.tr,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoTile(
                          icon: Icons.timelapse_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          title: 'કુલ રોકાણનો સમયગાળો (Duration)'.tr,
                          value: _calculateStayDuration(),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoTile(
                          icon: Icons.meeting_room_rounded,
                          iconColor: const Color(0xFF059669),
                          title: 'લક્ષ્ય ફ્લેટ / મકાન'.tr,
                          value: visitor.flatDisplay,
                        ),
                        if (visitor.memberName.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _infoTile(
                            icon: Icons.person_pin_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'રહીશ / યજમાન (Host)'.tr,
                            value: visitor.memberName,
                          ),
                        ],
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoTile(
                          icon: Icons.security_rounded,
                          iconColor: const Color(0xFF0D9488),
                          title: 'નોંધણી ગેટ / સુરક્ષા'.tr,
                          value: 'મુખ્ય સોસાયટી ગેટ (સુરક્ષા ચેકપોઇન્ટ)'.tr,
                        ),
                      ],
                    ),
                  ),

                  // 4. Action Buttons (Pending Gate Approvals)
                  if (canAction) ...[
                    const SizedBox(height: 24),
                    Text(
                      'ગેટ પ્રવેશ નિર્ણય (Gate Action):'.tr,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onStatusUpdate!(visitor.id, 'approved');
                              },
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 19),
                              label: Text(
                                'પ્રવેશ મંજૂર કરો'.tr,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onStatusUpdate!(visitor.id, 'rejected');
                              },
                              icon: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 19),
                              label: Text(
                                'પ્રવેશ નકારો'.tr,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECACA), width: 1.4),
                                backgroundColor: const Color(0xFFFEF2F2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.person_rounded, size: 38, color: Color(0xFF0284C7)),
    );
  }

  void _showFullImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
