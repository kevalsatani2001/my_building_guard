import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/society_service.dart';
import '../services/session_guard_service.dart';
import 'login_screen.dart';

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
    final sName = widget.societyName ??
        widget.societyData?['name'] ??
        widget.societyData?['societyName'] ??
        SocietyService.instance.societyName;

    final adminName = (widget.societyData?['adminName'] ?? 'સોસાયટી એડમિન').toString();
    final adminPhone = (widget.societyData?['adminPhone'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon with glowing container
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFFD97706),
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                "સોસાયટી સેવાઓ અસ્થાયી સ્થગિત છે",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                "તમારી સોસાયટી '$sName' ની એપ સેવાઓ સુપર એડમિન દ્વારા અસ્થાયી રૂપે નિષ્ક્રિય (Inactive) કરવામાં આવી છે.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Notice Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_support_rounded, size: 20, color: Color(0xFF4338CA)),
                        SizedBox(width: 8),
                        Text(
                          "સંપર્ક માહિતી:",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "સેવાઓ ફરી શરૂ કરવા માટે અથવા વધુ વિગત માટે તમારી સોસાયટીના મુખ્ય એડમિન / પ્રમુખશ્રીનો સંપર્ક કરો.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    if (adminPhone.isNotEmpty) ...[
                      const Divider(height: 18, color: Color(0xFFF1F5F9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            adminPhone,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  "એપમાંથી બહાર નીકળો (લૉગઆઉટ)",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
