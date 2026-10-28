import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/app_firestore.dart';
import '../../services/society_appeal_service.dart';
import '../../services/society_service.dart';
import '../../services/session_guard_service.dart';
import '../../services/localization_service.dart';
import '../../l10n/app_strings.dart';
import '../admin/admin_dashboard.dart';

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
  bool _isPastHistoryExpanded = false;
  StreamSubscription? _userSub;
  StreamSubscription? _socSub;
  Map<String, dynamic>? _currentSocData;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _currentSocData = widget.societyData;
    _currentUserData = widget.userData;
    _listenForRealtimeStatus();
  }

  void _listenForRealtimeStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userSub = AppFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
        if (!snap.exists || snap.data() == null) return;
        if (mounted) {
          setState(() => _currentUserData = snap.data());
          _checkAutoUnblock();
        }
      });
    }

    final sid = widget.societyId;
    if (sid.isNotEmpty) {
      _socSub = AppFirestore.instance.collection('society_settings').doc(sid).snapshots().listen((snap) {
        if (!snap.exists || snap.data() == null) return;
        if (mounted) {
          setState(() => _currentSocData = snap.data());
          _checkAutoUnblock();
        }
      });
    }
  }

  void _checkAutoUnblock() {
    final isUserActive = _currentUserData?['isActive'] != false;
    final isSocActive = _currentSocData == null || _currentSocData?['isActive'] != false;
    final isAdminBlocked = _currentSocData?['isAdminBlocked'] == true;
    final isSuspended = _currentSocData?['isSuspendedBySuperAdmin'] == true;

    if (isUserActive && isSocActive && !isAdminBlocked && !isSuspended && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _socSub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  /// ચકાસો કે સ્ટ્રીમ થયેલી અપીલ આ વર્તમાન બ્લોક/સસ્પેન્શન માટેની છે કે અગાઉના જૂના બ્લોકની છે
  bool _isAppealForCurrentBlock(Map<String, dynamic>? appeal) {
    if (appeal == null) return false;

    final status = (appeal['status'] ?? '').toString().toLowerCase();
    final bool isArchived = appeal['isArchived'] == true;

    // ૧. જો અપીલ પહેલેથી જ ઉકેલાઈ ગઈ હોય (resolved) અથવા આર્કાઇવ થઈ ગઈ હોય, તો એ ૧૦૦% અગાઉના બ્લોકની જ છે!
    if (status == 'resolved' || isArchived) {
      return false;
    }

    // ૨. ટાઇમસ્ટેમ્પ સરખામણી:
    final appealCreated = appeal['createdAt'];
    DateTime? appealDt;
    if (appealCreated is Timestamp) {
      appealDt = appealCreated.toDate();
    }

    if (appealDt != null) {
      // A. છેલ્લે ક્યારે અનબ્લોક કરવામાં આવ્યું હતું?
      final unblockedAtRaw = _currentSocData?['lastUnblockedAt'] ??
          _currentSocData?['unblockedAt'] ??
          _currentUserData?['lastUnblockedAt'] ??
          _currentUserData?['unblockedAt'];
      if (unblockedAtRaw is Timestamp) {
        final unblockedDt = unblockedAtRaw.toDate();
        if (appealDt.isBefore(unblockedDt)) {
          return false;
        }
      }

      // B. છેલ્લે ક્યારે સસ્પેન્ડ / બ્લોક કરવામાં આવ્યું?
      final suspendedAtRaw = _currentSocData?['lastSuspendedAt'] ??
          _currentSocData?['suspendedAt'] ??
          _currentUserData?['lastSuspendedAt'] ??
          _currentUserData?['suspendedAt'];
      if (suspendedAtRaw is Timestamp) {
        final suspendedDt = suspendedAtRaw.toDate();
        // જો અપીલ આ તાજેતરના બ્લોક થવા પહેલાની હોય, તો એ જૂના બ્લોકની છે
        if (appealDt.isBefore(suspendedDt.subtract(const Duration(seconds: 10)))) {
          return false;
        }
      }
    }

    // ૩. જો સ્ટેટસ પેન્ડિંગ છે અને ઉપરોક્ત ફિલ્ટર્સ પાસ થયા છે, તો જ આ વર્તમાન બ્લોકની સક્રિય અપીલ છે.
    return status == 'pending';
  }

  Future<void> _submitAppeal() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("કૃપા કરીને અપીલ સંદેશો અથવા સ્પષ્ટતા લખો.".tr),
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
      final adminName = (widget.userData?['name'] ?? widget.societyData?['adminName'] ?? 'એડમિન'.tr).toString();
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
          SnackBar(
            content: Text("અપીલ વિનંતી સફળતાપૂર્વક સુપર એડમિનને મોકલાઈ ગઈ છે.".tr),
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
            content: Text("અપીલ મોકલવામાં ક્ષતિ: $e".tr),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    await SessionGuardService.performAppLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    final societyName = (widget.societyData?['name'] ?? widget.societyData?['societyName'] ?? 'સોસાયટી'.tr).toString();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                    tooltip: 'sign_out'.tr,
                  ),
                  const LanguageSwitchButton(isDark: true),
                ],
              ),
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
              Text(
                "સોસાયટી એડમિન સેવા સ્થગિત છે".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "સુપર એડમિન / હેડ ઓફિસ દ્વારા '$societyName' ની કામગીરી અસ્થાયી રૂપે નિષ્ક્રિય (Freeze) કરવામાં આવી છે.".tr,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFF87171), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "સમગ્ર સોસાયટી પર અસર:".tr,
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "આ સ્થગિતીકરણને કારણે તમારી સોસાયટીના તમામ સબ-એડમિન, સભ્યો (Members) અને વોચમેન (Watchmen) માટે પણ એપનું એક્સેસ બંધ છે.".tr,
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
                  final bool isCurrentAppeal = _isAppealForCurrentBlock(appeal);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ૧. જો આ સસ્પેન્શન માટે અપીલ મોકલી દીધેલ હોય અને પેન્ડિંગ સમીક્ષા હેઠળ હોય:
                      if (isCurrentAppeal && !_showNewAppealForm) ...[
                        _buildCurrentAppealPendingCard(appeal!),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showNewAppealForm = true);
                              },
                              icon: const Icon(Icons.add_comment_rounded, size: 15, color: Color(0xFF60A5FA)),
                              label: Text(
                                "send_additional_appeal_btn".tr,
                                style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // ૨. નવું અપીલ ફોર્મ (હંમેશા ખુલ્લું રહેશે જેથી રી-બ્લોક વખતે જૂનો ડેટા અડચણરૂપ ન બને)
                        _buildNewAppealForm(isAdditional: isCurrentAppeal),
                      ],

                      // ૩. જો અગાઉની કોઈ જૂની/ઉકેલાયેલ અપીલ હોય, તો તેને નીચે એક ભવ્ય એકોર્ડિયન/ઇતિહાસ કાર્ડમાં દર્શાવો
                      if (appeal != null && !isCurrentAppeal) ...[
                        const SizedBox(height: 16),
                        _buildPastAppealAccordion(appeal),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(
                  "એપમાંથી બહાર નીકળો (લૉગઆઉટ)".tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

  /// કરન્ટ બ્લોકની સક્રિય અપીલ કાર્ડ (સુપર એડમિન સમીક્ષા હેઠળ)
  Widget _buildCurrentAppealPendingCard(Map<String, dynamic> appeal) {
    DateTime? appealTime;
    if (appeal['createdAt'] != null) {
      appealTime = (appeal['createdAt'] as dynamic).toDate();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFBBF24), size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  "current_appeal_pending_title".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF78350F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "પેન્ડિંગ".tr,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "તમારી અપીલ વિગત:".tr,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    if (appealTime != null)
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(appealTime),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (appeal['appealMessage'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "current_appeal_pending_hint".tr,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// નવું અપીલ ફોર્મ (હંમેશા સહેલાઈથી ઉપલબ્ધ)
  Widget _buildNewAppealForm({required bool isAdditional}) {
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
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Text(
                isAdditional ? "સુધારેલી / વધારાની અપીલ નોંધ".tr : "reconsideration_appeal_form_title".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "સોસાયટી ફરીથી સક્રિય કરવા માટે જરૂરી વિગત કે સ્પષ્ટતા સુપર એડમિનને મોકલો:".tr,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "દા.ત. અમારી સોસાયટીનું વાર્ષિક રિન્યુઅલ પેમેન્ટ થઈ ગયું છે, કૃપા કરીને એકાઉન્ટ પુનઃસક્રિય કરશો...".tr,
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
              _isSubmitting ? "મોકલાઈ રહ્યું છે...".tr : "સુપર એડમિનને અપીલ મોકલો".tr,
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
              child: Text("રદ કરો".tr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// અગાઉની જૂની/ઉકેલાયેલ અપીલ અને સુપર એડમિન પ્રત્યુત્તર ઇતિહાસ એકોર્ડિયન
  Widget _buildPastAppealAccordion(Map<String, dynamic> pastAppeal) {
    DateTime? pastCreatedAt;
    if (pastAppeal['createdAt'] != null) {
      pastCreatedAt = (pastAppeal['createdAt'] as dynamic).toDate();
    }
    final superReply = pastAppeal['superAdminReply'] as String?;
    final replyMethod = (pastAppeal['replyMethod'] ?? 'notification').toString();
    DateTime? repliedAt;
    if (pastAppeal['repliedAt'] != null) {
      repliedAt = (pastAppeal['repliedAt'] as dynamic).toDate();
    }

    final pastStatus = (pastAppeal['status'] ?? 'resolved').toString();
    final (badgeLabel, badgeColor, badgeBg) = switch (pastStatus) {
      'resolved' => ('past_appeal_resolved_badge'.tr, const Color(0xFF10B981), const Color(0xFF064E3B)),
      'rejected' => ('અસ્વીકૃત / નકારેલ'.tr, const Color(0xFFEF4444), const Color(0xFF7F1D1D)),
      _ => ('અગાઉનો ઇતિહાસ'.tr, const Color(0xFF94A3B8), const Color(0xFF1E293B)),
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isPastHistoryExpanded = !_isPastHistoryExpanded);
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "past_appeal_history_title".tr,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isPastHistoryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isPastHistoryExpanded) ...[
            const Divider(color: Color(0xFF334155), height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "અગાઉ મોકલેલી અપીલ વિગત:".tr,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            if (pastCreatedAt != null)
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(pastCreatedAt),
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (pastAppeal['appealMessage'] ?? '').toString(),
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (superReply != null && superReply.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF34D399)),
                              const SizedBox(width: 6),
                              Text(
                                "સુપર એડમિનનો અગાઉનો પ્રત્યુત્તર:".tr,
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  replyMethod.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            superReply,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (repliedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "જવાબ સમય: ${DateFormat('dd MMM yyyy, hh:mm a').format(repliedAt)}".tr,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    "આ અગાઉના સસ્પેન્શનનો ઉકેલાયેલ ઇતિહાસ છે. વર્તમાન સસ્પેન્શન માટે ઉપરનું ફોર્મ ભરીને નવી અપીલ મોકલો.".tr,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontStyle: FontStyle.italic),
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
