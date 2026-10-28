import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_firestore.dart';
import '../../services/society_service.dart';
import '../../services/session_guard_service.dart';
import '../member/member_screen.dart';
import '../watchman/watchmen_screen.dart';
import '../../l10n/app_strings.dart';
import '../../services/localization_service.dart';

class SocietySuspendedNoticeScreen extends StatefulWidget {
  final Map<String, dynamic>? societyData;
  final String? societyName;

  const SocietySuspendedNoticeScreen({
    super.key,
    this.societyData,
    this.societyName,
  });

  @override
  State<SocietySuspendedNoticeScreen> createState() => _SocietySuspendedNoticeScreenState();
}

class _SocietySuspendedNoticeScreenState extends State<SocietySuspendedNoticeScreen> {
  StreamSubscription? _socSub;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _listenForUnblock();
  }

  void _listenForUnblock() {
    final sid = widget.societyData?['societyId'] ?? SocietyService.instance.societyId;
    if (sid == null || sid.toString().isEmpty) return;
    _socSub = AppFirestore.instance.collection('society_settings').doc(sid.toString()).snapshots().listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final socData = snap.data() as Map<String, dynamic>;
      final bool isSocActive = socData['isActive'] != false;
      final bool isAdminBlocked = socData['isAdminBlocked'] == true;
      final bool isSuspended = socData['isSuspendedBySuperAdmin'] == true;
      if (isSocActive && !isAdminBlocked && !isSuspended && mounted) {
        final isGuard = SocietyService.instance.isGuard;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => isGuard ? const WatchmanScreen() : const MemberScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  Future<void> _checkStatusManual() async {
    setState(() => _isChecking = true);
    HapticFeedback.lightImpact();
    final sid = widget.societyData?['societyId'] ?? SocietyService.instance.societyId;
    if (sid != null && sid.toString().isNotEmpty) {
      try {
        final snap = await AppFirestore.instance.collection('society_settings').doc(sid.toString()).get();
        if (snap.exists && snap.data() != null) {
          final socData = snap.data()!;
          final bool isSocActive = socData['isActive'] != false;
          final bool isAdminBlocked = socData['isAdminBlocked'] == true;
          final bool isSuspended = socData['isSuspendedBySuperAdmin'] == true;
          if (isSocActive && !isAdminBlocked && !isSuspended && mounted) {
            final isGuard = SocietyService.instance.isGuard;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => isGuard ? const WatchmanScreen() : const MemberScreen(),
              ),
              (route) => false,
            );
            return;
          }
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("હજુ સેવાઓ સ્થગિત છે. કૃપા કરીને થોડી વાર પછી તપાસો.".tr),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _socSub?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    await SessionGuardService.performAppLogout(context);
  }

  Future<void> _callAdmin(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sName = widget.societyName ??
        widget.societyData?['name'] ??
        widget.societyData?['societyName'] ??
        SocietyService.instance.societyName;

    final adminName = (widget.societyData?['adminName'] ?? 'સોસાયટી એડમિન'.tr).toString();
    final adminPhone = (widget.societyData?['adminPhone'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 5),
                        Text(
                          "સોસાયટી સ્થગિત".tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LanguageSwitchButton(isDark: true),
                ],
              ),

              const Spacer(),

              // 3D Animated Security Lock Emblem
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF78350F), Color(0xFFB45309)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.domain_disabled_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'society_services_suspended_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle with proper translation formatting
              Text(
                "${'society_suspended_msg_prefix'.tr} '$sName' ${'society_suspended_msg_suffix'.tr}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Notice Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.contact_support_rounded, size: 16, color: Color(0xFF818CF8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "સંપર્ક માહિતી:".tr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'contact_admin_notice'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.45,
                      ),
                    ),
                    if (adminPhone.isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFF334155)),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  adminPhone,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _callAdmin(adminPhone),
                            icon: const Icon(Icons.call_rounded, size: 14),
                            label: Text('call_society_admin'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Check Status Manual Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkStatusManual,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    'check_status_refresh'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(
                    "એપમાંથી બહાર નીકળો (લૉગઆઉટ)".tr,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFF991B1B), width: 1.2),
                    backgroundColor: const Color(0xFF450A0A).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
