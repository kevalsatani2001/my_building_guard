import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/society_appeal_service.dart';
import '../services/society_service.dart';
import '../services/session_guard_service.dart';
import 'login_screen.dart';

class AdminSuspendedScreen extends StatefulWidget {
  final String societyId;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? societyData;

  const AdminSuspendedScreen({
    super.key,
    required this.societyId,
    this.userData,
    this.societyData,
  });

  @override
  State<AdminSuspendedScreen> createState() => _AdminSuspendedScreenState();
}

class _AdminSuspendedScreenState extends State<AdminSuspendedScreen> {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _showNewAppealForm = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("કૃપા કરીને અપીલ સંદેશો અથવા સ્પષ્ટતા લખો."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final adminUid = user?.uid ?? '';
      final adminName = (widget.userData?['name'] ?? widget.societyData?['adminName'] ?? 'એડમિન').toString();
      final adminPhone = (widget.userData?['phone'] ?? widget.societyData?['adminPhone'] ?? '').toString();
      final adminEmail = (user?.email ?? widget.userData?['email'] ?? widget.societyData?['adminEmail'] ?? '').toString();
      final societyName = (widget.societyData?['name'] ?? widget.societyData?['societyName'] ?? SocietyService.instance.societyName).toString();

      await SocietyAppealService.instance.submitAppeal(
        societyId: widget.societyId,
        societyName: societyName,
        adminUid: adminUid,
        adminName: adminName,
        adminPhone: adminPhone,
        adminEmail: adminEmail,
        message: text,
      );

      _messageController.clear();
      setState(() {
        _isSubmitting = false;
        _showNewAppealForm = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("અપીલ વિનંતી સફળતાપૂર્વક સુપર એડમિનને મોકલાઈ ગઈ છે."),
            backgroundColor: Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("અપીલ મોકલવામાં ક્ષતિ: $e"),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    SocietyService.instance.clear();
    SessionGuardService.instance.stopListening();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final societyName = (widget.societyData?['name'] ?? widget.societyData?['societyName'] ?? 'સોસાયટી').toString();
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Header Badge & Icon
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              const Text(
                "સોસાયટી એડમિન સેવા સ્થગિત છે",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "સુપર એડમિન / હેડ ઓફિસ દ્વારા '$societyName' ની કામગીરી અસ્થાયી રૂપે નિષ્ક્રિય (Freeze) કરવામાં આવી છે.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Impact Alert Card (All members/watchmen affected)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFF87171), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "સમગ્ર સોસાયટી પર અસર:",
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "આ સ્થગિતીકરણને કારણે તમારી સોસાયટીના તમામ સબ-એડમિન, સભ્યો (Members) અને વોચમેન (Watchmen) માટે પણ એપનું એક્સેસ બંધ છે.",
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Real-Time Appeal Stream
              StreamBuilder<Map<String, dynamic>?>(
                stream: SocietyAppealService.instance.streamLatestAppealForAdmin(widget.societyId, adminUid),
                builder: (context, snapshot) {
                  final appeal = snapshot.data;

                  // જો કોઈ અપીલ પેન્ડિંગ હોય અથવા સુપર એડમિનનો જવાબ આવ્યો હોય:
                  if (appeal != null && !_showNewAppealForm) {
                    final status = (appeal['status'] ?? 'pending').toString();
                    final superReply = appeal['superAdminReply'] as String?;
                    final replyMethod = (appeal['replyMethod'] ?? 'notification').toString();
                    DateTime? repliedAt;
                    if (appeal['repliedAt'] != null) {
                      repliedAt = (appeal['repliedAt'] as dynamic).toDate();
                    }

                    final (statusLabel, statusColor, statusBg) = switch (status) {
                      'resolved' => ('મંજૂર / ઉકેલાયેલ', const Color(0xFF10B981), const Color(0xFF064E3B)),
                      'rejected' => ('અસ્વીકૃત / નકારેલ', const Color(0xFFEF4444), const Color(0xFF7F1D1D)),
                      _ => ('સુપર એડમિન સમીક્ષા હેઠળ', const Color(0xFFF59E0B), const Color(0xFF78350F)),
                    };

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "તાજેતરની અપીલ સ્થિતિ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "તમારી અપીલ વિગત:",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (appeal['appealMessage'] ?? '').toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),

                          // સુપર એડમિનનો જવાબ (Super Admin's Official Reply)
                          if (superReply != null && superReply.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF34D399)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "સુપર એડમિનનો સત્તાવાર પ્રત્યુત્તર:",
                                        style: TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF047857),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          replyMethod.toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    superReply,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (repliedAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "જવાબ સમય: ${DateFormat('dd MMM yyyy, hh:mm a').format(repliedAt)}",
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _showNewAppealForm = true);
                                },
                                icon: const Icon(Icons.add_comment_rounded, size: 15, color: Color(0xFF60A5FA)),
                                label: const Text(
                                  "નવી અપીલ લખો",
                                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // અપીલ ફોર્મ (New Appeal Submission Form)
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF38BDF8)),
                            SizedBox(width: 8),
                            Text(
                              "પુનઃવિચારણા અપીલ ફોર્મ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "સોસાયટી ફરીથી સક્રિય કરવા માટે જરૂરી વિગત કે સ્પષ્ટતા સુપર એડમિનને મોકલો:",
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "દા.ત. અમારી સોસાયટીનું વાર્ષિક રિન્યુઅલ પેમેન્ટ થઈ ગયું છે, કૃપા કરીને એકાઉન્ટ પુનઃસક્રિય કરશો...",
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF475569)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAppeal,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            _isSubmitting ? "મોકલાઈ રહ્યું છે..." : "સુપર એડમિનને અપીલ મોકલો",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                        if (_showNewAppealForm)
                          TextButton(
                            onPressed: () => setState(() => _showNewAppealForm = false),
                            child: const Text("રદ કરો", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  "એપમાંથી બહાર નીકળો (લૉગઆઉટ)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
