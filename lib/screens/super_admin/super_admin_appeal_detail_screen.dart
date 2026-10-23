import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/society_appeal_service.dart';
import '../../services/super_admin_service.dart';

class SuperAdminAppealDetailScreen extends StatefulWidget {
  final String appealId;
  final Map<String, dynamic>? initialData;

  const SuperAdminAppealDetailScreen({
    super.key,
    required this.appealId,
    this.initialData,
  });

  @override
  State<SuperAdminAppealDetailScreen> createState() => _SuperAdminAppealDetailScreenState();
}

class _SuperAdminAppealDetailScreenState extends State<SuperAdminAppealDetailScreen> {
  final SuperAdminService _superAdminService = SuperAdminService.instance;
  bool _isProcessing = false;

  Future<void> _sendMail(String email, String societyName, String adminName) async {
    if (email.isEmpty) {
      _showToast("ઈમેલ સરનામું ઉપલબ્ધ નથી.");
      return;
    }
    final subject = Uri.encodeComponent("BuildingGuard: સોસાયટી પુનઃસક્રિયતા અપીલ સંદર્ભે ($societyName)");
    final body = Uri.encodeComponent(
      "નમસ્તે $adminName,\n\n"
      "તમારી સોસાયટી '$societyName' ની સસ્પેન્શન અપીલ સંદર્ભે જણાવવાનું કે,\n\n"
      "[અહીં તમારો સંદેશો લખો]\n\n"
      "આભાર,\n"
      "સુપર એડમિન હેડ ઓફિસ - BuildingGuard",
    );
    final uri = Uri.parse("mailto:$email?subject=$subject&body=$body");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showToast("ઈમેલ એપ ખોલી શકાઈ નથી.");
    }
  }

  Future<void> _sendWhatsApp(String phone, String societyName, String adminName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      _showToast("ફોન નંબર ઉપલબ્ધ નથી.");
      return;
    }
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = Uri.encodeComponent(
      "નમસ્તે $adminName,\n"
      "તમારી સોસાયટી *$societyName* ની અપીલ વિનંતી સંદર્ભે સુપર એડમિન ટીમ તરફથી સંપર્ક કરવામાં આવ્યો છે.\n\n"
      "[અહીં વિગત લખો]",
    );
    final uri = Uri.parse("https://wa.me/$formattedPhone?text=$msg");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showToast("WhatsApp ખોલી શકાયું નથી.");
    }
  }

  Future<void> _unblockSocietyDirectly(String societyId, String adminUid, String societyName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("સોસાયટી સક્રિય કરવી છે?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          "'$societyName' અને તેના એડમિનને પુનઃસક્રિય કરવામાં આવશે. તમામ સભ્યો અને વોચમેન માટે એપ ફરીથી ચાલુ થશે.",
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("રદ કરો", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("હા, સક્રિય કરો"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _superAdminService.toggleSocietyStatus(societyId, true);
      if (adminUid.isNotEmpty) {
        await _superAdminService.toggleUserStatus(adminUid, true);
      }
      await SocietyAppealService.instance.replyToAppeal(
        appealId: widget.appealId,
        societyId: societyId,
        adminUid: adminUid,
        replyMessage: "તમારી અપીલ સ્વીકારી લેવામાં આવી છે અને સોસાયટી પુનઃસક્રિય કરી દેવામાં આવી છે.",
        replyStatus: 'resolved',
        replyMethod: 'notification',
        unblockSociety: true,
      );

      _showToast("સોસાયટી અને એડમિન સફળતાપૂર્વક સક્રિય થઈ ગયા છે.");
    } catch (e) {
      _showToast("ક્ષતિ: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showInAppReplyDialog({
    required String societyId,
    required String adminUid,
    required String societyName,
  }) {
    final replyCtrl = TextEditingController();
    String selectedStatus = 'resolved';
    bool unblockToo = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "એપ પુશ નોટિફિકેશન રિપ્લાય",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "આ સંદેશો સીધો એડમિનના ફોનમાં નોટિફિકેશન તરીકે જશે.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // Status Selector
              Row(
                children: [
                  _statusChoicePill(
                    label: "મંજૂર (Resolved)",
                    selected: selectedStatus == 'resolved',
                    color: const Color(0xFF10B981),
                    onTap: () => setModalState(() {
                      selectedStatus = 'resolved';
                      unblockToo = true;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _statusChoicePill(
                    label: "વધુ વિગત (Needs Info)",
                    selected: selectedStatus == 'pending_info',
                    color: const Color(0xFFF59E0B),
                    onTap: () => setModalState(() {
                      selectedStatus = 'pending_info';
                      unblockToo = false;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Message Input
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "સુપર એડમિન તરીકે તમારો સત્તાવાર સંદેશો લખો...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),

              // Unblock checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: unblockToo,
                activeColor: const Color(0xFF10B981),
                title: const Text(
                  "સાથે સાથે સોસાયટી અને એડમિનને અનબ્લોક (સક્રિય) કરો",
                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                onChanged: (val) => setModalState(() => unblockToo = val ?? false),
              ),
              const SizedBox(height: 14),

              // Send button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final text = replyCtrl.text.trim();
                  if (text.isEmpty) {
                    _showToast("કૃપા કરીને સંદેશો લખો.");
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() => _isProcessing = true);
                  try {
                    await SocietyAppealService.instance.replyToAppeal(
                      appealId: widget.appealId,
                      societyId: societyId,
                      adminUid: adminUid,
                      replyMessage: text,
                      replyStatus: selectedStatus,
                      replyMethod: 'notification',
                      unblockSociety: unblockToo,
                    );
                    _showToast("નોટિફિકેશન રિપ્લાય સફળતાપૂર્વક મોકલાઈ ગયો છે.");
                  } catch (e) {
                    _showToast("ક્ષતિ: $e");
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text("જવાબ મોકલો", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChoicePill({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : const Color(0xFF334155), width: selected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "અપીલ રિવ્યુ & નિર્ણય",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              "સુપર એડમિન કંટ્રોલ સેન્ટર",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: SocietyAppealService.instance.streamAppealById(widget.appealId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? widget.initialData;
          if (data == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final societyName = (data['societyName'] ?? 'સોસાયટી').toString();
          final societyId = (data['societyId'] ?? '').toString();
          final adminName = (data['adminName'] ?? 'એડમિન').toString();
          final adminPhone = (data['adminPhone'] ?? '').toString();
          final adminEmail = (data['adminEmail'] ?? '').toString();
          final adminUid = (data['adminUid'] ?? '').toString();
          final message = (data['appealMessage'] ?? '').toString();
          final status = (data['status'] ?? 'pending').toString();
          final superReply = data['superAdminReply'] as String?;

          DateTime? createdAt;
          if (data['createdAt'] != null) {
            createdAt = (data['createdAt'] as dynamic).toDate();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Society Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  societyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "ID: $societyId",
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status == 'resolved' ? const Color(0xFF064E3B) : const Color(0xFF78350F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: status == 'resolved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ),
                            child: Text(
                              status == 'resolved' ? "✅ સક્રિય / ઉકેલાયેલ" : "⏳ અપીલ પેન્ડિંગ",
                              style: TextStyle(
                                color: status == 'resolved' ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFF475569)),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 5),
                          Text("એડમિન: $adminName", style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          if (adminPhone.isNotEmpty)
                            Text(adminPhone, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (adminEmail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(adminEmail, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Appeal Message Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          const Text(
                            "એડમિનનો અપીલ સંદેશો:",
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(createdAt),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Super Admin Previous Reply (if exists)
                if (superReply != null && superReply.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "તમારો અગાઉનો સત્તાવાર જવાબ:",
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(superReply, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action 1: Direct Unblock Button
                FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _unblockSocietyDirectly(societyId, adminUid, societyName),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text(
                    "સોસાયટી & એડમિન સક્રિય કરો (Unblock Now)",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 14),

                // 3 Reply Channels
                const Text(
                  "એડમિન સાથે પ્રત્યુત્તર માધ્યમ:",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Mail
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendMail(adminEmail, societyName, adminName),
                        icon: const Icon(Icons.mail_rounded, size: 16),
                        label: const Text("Mail", style: TextStyle(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // WhatsApp
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendWhatsApp(adminPhone, societyName, adminName),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // In-App Push
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showInAppReplyDialog(
                          societyId: societyId,
                          adminUid: adminUid,
                          societyName: societyName,
                        ),
                        icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
                        label: const Text("પુશ રિપ્લાય", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
