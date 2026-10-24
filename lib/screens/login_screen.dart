import 'package:building_guard/core/app_firestore.dart';
import 'package:building_guard/screens/watchmen_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_guard_service.dart';
import '../services/society_service.dart';
import 'admin_dashboard.dart';
import 'member_screen.dart';
import 'super_admin/super_admin_dashboard.dart';
import 'admin_suspended_screen.dart';
import 'society_suspended_notice_screen.dart';
import '../services/localization_service.dart';
import '../l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final rawInput = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (rawInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('input_required'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String resolvedEmail = rawInput;

      // જો યુઝરે ૧૦ કે તેથી વધુ અંકનો ફોન નંબર દાખલ કર્યો હોય, તો તેના આધારે ઇમેઇલ શોધો
      final cleanDigits = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.length >= 10 && !rawInput.contains('@')) {
        // ૧. પૂરા નંબરે સર્ચ
        var phoneQuery = await AppFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanDigits)
            .limit(1)
            .get();

        // ૨. ૧૦-અંકના સ્ટાન્ડર્ડ ફોર્મેટમાં સર્ચ (દા.ત. 9876543210)
        final last10 = cleanDigits.substring(cleanDigits.length - 10);
        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: last10)
              .limit(1)
              .get();
        }
        // ૩. +91 ફોર્મેટમાં સર્ચ
        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: '+91$last10')
              .limit(1)
              .get();
        }
        // ૪. displayPhone ફિલ્ડમાં સર્ચ
        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('displayPhone', isEqualTo: rawInput)
              .limit(1)
              .get();
        }

        if (phoneQuery.docs.isNotEmpty) {
          final foundEmail = (phoneQuery.docs.first.data()['email'] ?? '').toString().trim();
          if (foundEmail.isNotEmpty) {
            resolvedEmail = foundEmail;
          }
        }
      }

      final normalizedEmail = resolvedEmail.trim().toLowerCase();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

      final uid = userCredential.user!.uid;

      // Register new active session ID to enforce 1-device policy
      await SessionGuardService.instance.registerNewLoginSession(uid);

      DocumentSnapshot userDoc = await AppFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        try {
          final oldDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (oldDoc.exists && oldDoc.data() != null) {
            await AppFirestore.instance
                .collection('users')
                .doc(uid)
                .set(oldDoc.data()!);
            userDoc = await AppFirestore.instance
                .collection('users')
                .doc(uid)
                .get();
          }
        } catch (_) {}
      }

      // જો UID આધારે ન મળે, તો ઈમેલ આધારે શોધો અને સેલ્ફ-હીલ (UID લિંક) કરો
      if (!userDoc.exists) {
        final emailToSearch = (userCredential.user!.email ?? normalizedEmail).trim().toLowerCase();
        if (emailToSearch.isNotEmpty) {
          final q = await AppFirestore.instance
              .collection('users')
              .where('email', isEqualTo: emailToSearch)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final existingDoc = q.docs.first;
            final existingData = Map<String, dynamic>.from(existingDoc.data());
            existingData['uid'] = uid;
            // સાચા Auth UID હેઠળ દસ્તાવેજ સેવ કરી લો
            await AppFirestore.instance.collection('users').doc(uid).set(existingData, SetOptions(merge: true));
            userDoc = await AppFirestore.instance.collection('users').doc(uid).get();
          }
        }
      }

      final userData = userDoc.data() as Map<String, dynamic>?;

      SocietyService.instance.bindFromUserMap(userData);

      final email = (userCredential.user!.email ?? normalizedEmail).toLowerCase().trim();
      final String rawRole = (userData?['role'] ?? '').toString().toLowerCase().trim();

      // ઓટોમેટિક રોલ ડિટેક્શન (Automatic Role Fetching)
      // ૧. સુપર એડમિન (Super Admin)
      final bool isSuper = rawRole == 'super_admin' ||
          rawRole == 'superadmin' ||
          userData?['isSuperAdmin'] == true ||
          email == 'kevaladmin@gmail.com';

      // ૨. મુખ્ય સોસાયટી એડમિન (Chairman / Admin)
      final bool isAdmin = rawRole == 'admin' ||
          rawRole == 'chairman' ||
          rawRole == 'president' ||
          userData?['isAdmin'] == true;

      // ૩. સબ એડમિન / કમિટી મેમ્બર (Sub-Admin / Committee Member)
      final bool isSubAdminOrCommittee = rawRole == 'sub_admin' ||
          rawRole == 'subadmin' ||
          rawRole == 'wing_admin' ||
          rawRole == 'committee' ||
          rawRole == 'committee_member' ||
          rawRole == 'kamiti' ||
          rawRole == 'kamiti_member' ||
          userData?['isCommitteeMember'] == true ||
          userData?['subAdmin'] == true ||
          userData?['isSubAdmin'] == true;

      // ૪. સિક્યુરિટી ગાર્ડ / વોચમેન (Gate Staff / Guard)
      final bool isGuard = rawRole == 'watchman' ||
          rawRole == 'guard' ||
          rawRole == 'security' ||
          rawRole == 'gate_staff' ||
          userData?['isGuard'] == true;

      if (!mounted) return;

      // જો સુપર એડમિન ન હોય, તો યુઝર અને સોસાયટી બ્લોક/સસ્પેન્શન તપાસો (Strict Enforcement)
      if (!isSuper) {
        final societyId = (userData?['societyId'] ?? '').toString().trim();
        final effectiveSocietyId = societyId.isEmpty ? SocietyService.kDefaultSocietyId : societyId;

        Map<String, dynamic>? socData;
        try {
          final socDoc = await AppFirestore.instance.collection('society_settings').doc(effectiveSocietyId).get();
          if (socDoc.exists) {
            socData = socDoc.data();
          }
        } catch (_) {}

        if (!mounted) return;

        final bool isUserActive = userData?['isActive'] != false;
        final bool isSocietyActive = socData == null || socData['isActive'] != false;
        final bool isAdminBlocked = socData?['isAdminBlocked'] == true;
        final bool isSuspendedBySuperAdmin = socData?['isSuspendedBySuperAdmin'] == true;

        if (!isUserActive || !isSocietyActive || isAdminBlocked || isSuspendedBySuperAdmin) {
          if (isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AdminSuspendedScreen(
                  societyId: effectiveSocietyId,
                  userData: userData,
                  societyData: socData,
                ),
              ),
            );
            return;
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SocietySuspendedNoticeScreen(
                  societyData: socData,
                  societyName: socData?['name'] ?? socData?['societyName'] ?? userData?['societyName'],
                ),
              ),
            );
            return;
          }
        }
      }

      if (isSuper) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      } else if (isAdmin || isSubAdminOrCommittee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (isGuard) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WatchmanScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MemberScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'લૉગિન ભૂલ: ${e.message ?? e.code}'.tr;
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          msg = 'અમાન્ય ક્રેડેન્શિયલ્સ: ઈમેલ/મોબાઇલ અથવા પાસવર્ડ ખોટો છે. કૃપા કરીને તપાસો અથવા એડમિનનો સંપર્ક કરો.'.tr;
        } else if (e.code == 'invalid-email') {
          msg = 'ઈમેલ એડ્રેસ અમાન્ય છે. કૃપા કરીને સાચો ઈમેલ દાખલ કરો.'.tr;
        } else if (e.code == 'user-disabled') {
          msg = 'આ એકાઉન્ટ નિષ્ક્રિય (ડીસેબલ) કરેલું છે. સોસાયટી એડમિનનો સંપર્ક કરો.'.tr;
        } else if (e.code == 'too-many-requests') {
          msg = 'ઘણી બધી અસફળ કોશિશો થઈ છે. થોડી મિનિટો પછી ફરી પ્રયાસ કરો.'.tr;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text(msg),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('લૉગિન ભૂલ: ${e.toString()}'.tr),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ટોપ પ્રીમિયમ હીરો બેનર
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/register_hero.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        const Color(0xFF0F172A).withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  top: 48,
                  right: 16,
                  child: LanguageSwitchButton(isDark: true),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "My Building Guard ERP",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get('login_hero_title'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.get('login_hero_subtitle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // લૉગિન કાર્ડ
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_person_rounded, size: 20, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get('login_to_account'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.get('login_subtitle'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),

                        // સ્માર્ટ ઓટો-રોલ ડિટેક્શન બેનર
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF99F6E4), width: 1.1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.get('auto_role_detection'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.get('auto_role_desc'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF047857),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildRoleMiniBadge(AppStrings.get('role_badge_admin'), const Color(0xFF0F766E)),
                                  _buildRoleMiniBadge(AppStrings.get('role_badge_committee'), const Color(0xFF2563EB)),
                                  _buildRoleMiniBadge(AppStrings.get('role_badge_guard'), const Color(0xFFD97706)),
                                  _buildRoleMiniBadge(AppStrings.get('role_badge_member'), const Color(0xFF475569)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ઇમેઇલ અથવા મોબાઇલ નંબર
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('email_or_phone_label'),
                            hintText: AppStrings.get('email_or_phone_hint'),
                            prefixIcon: _inputIcon(Icons.person_outline_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // પાસવર્ડ
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: AppStrings.get('password_label'),
                            hintText: AppStrings.get('password_hint'),
                            prefixIcon: _inputIcon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppStrings.get('forgot_password'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // લૉગિન બટન
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppStrings.get('logging_in'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.login_rounded, size: 20, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppStrings.get('login_button'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // એકાઉન્ટ મેળવવા માટે સત્તાવાર નીતિ & સહાય
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showAccountAccessPolicySheet(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shield_outlined,
                                        size: 18,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.get('how_to_get_account'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppStrings.get('account_policy_sub'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountAccessPolicySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F766E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "એકાઉન્ટ એક્સેસ નીતિ".tr,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          "સુરક્ષા માટે જાતે રજીસ્ટ્રેશન પ્રતિબંધિત છે".tr,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Building Guard એપમાં કોઈ સભ્ય કે એડમિન સીધા જાતે એકાઉન્ટ બનાવી શકતા નથી. ફક્ત અધિકૃત એડમિન જ નવું એકાઉન્ટ બનાવીને લૉગિન વિગતો આપી શકે છે.".tr,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPolicyItem(
                title: "૧. સોસાયટી એડમિન (ચેરમેન / પ્રમુખ)".tr,
                desc: "નવી સોસાયટીના મુખ્ય એડમિનનું એકાઉન્ટ પ્લેટફોર્મના 'સુપર એડમિન' દ્વારા બનાવવામાં આવે છે અને તેમને સુરક્ષિત લૉગિન ક્રેડેન્શિયલ્સ આપવામાં આવે છે.".tr,
                icon: Icons.business_rounded,
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(height: 12),
              _buildPolicyItem(
                title: "૨. સોસાયટી મેમ્બર / રહીશ".tr,
                desc: "તમારા ફ્લેટ/ઘર માટેનું એકાઉન્ટ તમારી સોસાયટીના એડમિન (ચેરમેન) દ્વારા ડેશબોર્ડમાંથી ઉમેરવામાં આવે છે અને તમને લૉગિન ઈમેલ/મોબાઈલ અને પાસવર્ડ આપવામાં આવે છે.".tr,
                icon: Icons.apartment_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _buildPolicyItem(
                title: "૩. સબ-એડમિન અને વોચમેન (ગાર્ડ)".tr,
                desc: "કમિટી મેમ્બર, વિંગ એડમિન તથા સિક્યોરિટી ગાર્ડ્સનું એકાઉન્ટ પણ સોસાયટી એડમિન દ્વારા તેમના એડમિન પેનલમાંથી તૈયાર કરવામાં આવે છે.".tr,
                icon: Icons.security_rounded,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("સમજાઈ ગયું (Close)".tr, style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPolicyItem({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
    );
  }

  Widget _buildRoleMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text("પાસવર્ડ રીસેટ".tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "તમારો રજીસ્ટર્ડ ઇમેઇલ દાખલ કરો. અમે તમને પાસવર્ડ રીસેટ કરવાની લિંક મોકલીશું.".tr,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: 'ઇમેઇલ'.tr,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("રદ કરો".tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                          "પાસવર્ડ રીસેટ લિંક તમારા ઇમેઇલ પર મોકલવામાં આવી છે.".tr),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("ભૂલ આવી: $e".tr)),
                  );
                }
              }
            },
            child: Text("લિંક મોકલો".tr),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegMode { member, newSocietyAdmin }

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _societyCodeController = TextEditingController();
  final _societyNameController = TextEditingController();
  final _blockController = TextEditingController();
  final _unitController = TextEditingController();

  _RegMode _mode = _RegMode.member;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _blockController.addListener(_refreshUi);
    _unitController.addListener(_refreshUi);
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _blockController.removeListener(_refreshUi);
    _unitController.removeListener(_refreshUi);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _societyCodeController.dispose();
    _societyNameController.dispose();
    _blockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email.trim());
  }

  String _normalizeSocietyId(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return SocietyService.kDefaultSocietyId;
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final societyCode = _societyCodeController.text.trim();
    final societyName = _societyNameController.text.trim();
    final block = _blockController.text.trim();
    final unit = _unitController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('કૃપા કરીને નામ, ઇમેઇલ અને પાસવર્ડ ભરો.'.tr)),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('કૃપા કરીને માન્ય ઇમેઇલ એડ્રેસ લખો.'.tr)),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ.'.tr)),
      );
      return;
    }

    if (_mode == _RegMode.newSocietyAdmin && societyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('નવી સોસાયટી માટે સોસાયટી કોડ લખવો ફરજિયાત છે.'.tr)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resolvedSocietyId = _mode == _RegMode.newSocietyAdmin
          ? _normalizeSocietyId(societyCode)
          : (societyCode.isEmpty
              ? SocietyService.kDefaultSocietyId
              : _normalizeSocietyId(societyCode));

      final role = _mode == _RegMode.newSocietyAdmin ? 'admin' : 'member';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final userData = <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'role': role,
        'societyId': resolvedSocietyId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_mode == _RegMode.member) {
        if (block.isNotEmpty) userData['blockName'] = block;
        if (unit.isNotEmpty) userData['unitNumber'] = unit;
      }

      await AppFirestore.instance.collection('users').doc(uid).set(userData);

      // જો નવી સોસાયટી એડમિન તરીકે શરૂ કરી રહ્યા હોય, તો society_settings તૈયાર કરો
      if (_mode == _RegMode.newSocietyAdmin) {
        await AppFirestore.instance
            .collection('society_settings')
            .doc(resolvedSocietyId)
            .set({
          'societyId': resolvedSocietyId,
          'societyName': societyName.isEmpty ? resolvedSocietyId : societyName,
          'isSetupComplete': false,
          'adminUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            _mode == _RegMode.newSocietyAdmin
                ? 'સોસાયટી અને એડમિન એકાઉન્ટ સફળતાપૂર્વક બની ગયું! હવે લૉગિન કરો.'.tr
                : 'રજીસ્ટ્રેશન સફળ! હવે તમારા એકાઉન્ટમાં લૉગિન કરો.'.tr,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('ભૂલ: ${e.toString()}'.tr),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegistrationGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.help_center_rounded, color: Color(0xFF0F766E), size: 24),
                  SizedBox(width: 10),
                  Text(
                    "રજીસ્ટ્રેશન માર્ગદર્શિકા (Help)".tr,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildGuideStep(
                number: "૧".tr,
                title: "રહીશ / સભ્ય રજીસ્ટ્રેશન".tr,
                description:
                    "તમારા ચેરમેન કે સેક્રેટરી પાસેથી મેળવેલ સોસાયટી કોડ દાખલ કરો. તમારો વિંગ (દા.ત. A) અને ફ્લેટ/દુકાન નંબર (દા.ત. 101, G-02) લખીને રજીસ્ટર કરો.".tr,
                icon: Icons.person_pin_rounded,
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(height: 10),

              _buildGuideStep(
                number: "૨".tr,
                title: "નવી સોસાયટી (ચેરમેન / બિલ્ડર)".tr,
                description:
                    "નવી સોસાયટી, રેસીડેન્સી કે શોપિંગ મોલનું સેટઅપ કરવા અહીંથી રજીસ્ટર કરો. તમારી સોસાયટી માટે અંગ્રેજીમાં યુનિક કોડ (દા.ત. shiv-residency) પસંદ કરો. લૉગિન કર્યા પછી એડમિન સેટઅપ વિઝાર્ડમાં વિંગ અને દુકાનો ઉમેરી શકશો.".tr,
                icon: Icons.domain_add_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 10),

              _buildGuideStep(
                number: "૩".tr,
                title: "વોચમેન / સિક્યુરિટી ગાર્ડ એકાઉન્ટ".tr,
                description:
                    "સુરક્ષાના કારણોસર વોચમેનનું એકાઉન્ટ બહારથી રજીસ્ટર થઈ શકતું નથી. માત્ર ચેરમેન પોતાના એડમિન ડેશબોર્ડના 'સ્ટાફ મેનેજમેન્ટ'માંથી જ વોચમેનનું ખાતું બનાવી શકે છે.".tr,
                icon: Icons.shield_rounded,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "સમજાઈ ગયું".tr,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewBlock = _blockController.text.trim();
    final previewUnit = _unitController.text.trim();
    final hasAddressPreview = _mode == _RegMode.member && (previewBlock.isNotEmpty || previewUnit.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ટોપ પ્રીમિયમ ૩D હીરો એપ્પબાર
          SliverAppBar(
            expandedHeight: 190.0,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: InkWell(
                    onTap: () => _showRegistrationGuideModal(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            "માર્ગદર્શિકા".tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/register_hero.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          const Color(0xFF0F172A).withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            "✨ સ્માર્ટ સોસાયટી એન્ડ પ્રિમાઇસીસ પોર્ટલ".tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "નવું એકાઉન્ટ બનાવો".tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _mode == _RegMode.member
                              ? "રહીશ, ભાડુઆત કે દુકાનદાર તરીકે પ્રવેશ મેળવો".tr
                              : "નવી સોસાયટી, મોલ કે બંગલો પ્રોજેક્ટ સેટઅપ કરો".tr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ફોર્મ બોડી
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ૧. એકાઉન્ટ પ્રકાર સિલેક્ટર કાર્ડ્સ
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF0F766E)),
                      SizedBox(width: 8),
                      Text(
                        "૧. તમારું એકાઉન્ટ પ્રકાર પસંદ કરો:".tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // સભ્ય મોડ કાર્ડ
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _mode = _RegMode.member),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _mode == _RegMode.member
                                  ? const Color(0xFF0F766E).withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _mode == _RegMode.member
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFFE2E8F0),
                                width: _mode == _RegMode.member ? 2 : 1.2,
                              ),
                              boxShadow: _mode == _RegMode.member
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.family_restroom_rounded,
                                          size: 22, color: Color(0xFF0F766E)),
                                    ),
                                    if (_mode == _RegMode.member)
                                      const Icon(Icons.check_circle_rounded,
                                          size: 22, color: Color(0xFF0F766E))
                                    else
                                      const Icon(Icons.circle_outlined,
                                          size: 20, color: Color(0xFFCBD5E1)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "રહીશ / સભ્ય".tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "ફ્લેટ, બંગલો કે દુકાનદાર".tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ચેરમેન / એડમિન મોડ કાર્ડ
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _mode = _RegMode.newSocietyAdmin),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _mode == _RegMode.newSocietyAdmin
                                  ? const Color(0xFF0F766E).withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _mode == _RegMode.newSocietyAdmin
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFFE2E8F0),
                                width: _mode == _RegMode.newSocietyAdmin ? 2 : 1.2,
                              ),
                              boxShadow: _mode == _RegMode.newSocietyAdmin
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.domain_add_rounded,
                                          size: 22, color: Color(0xFF0F766E)),
                                    ),
                                    if (_mode == _RegMode.newSocietyAdmin)
                                      const Icon(Icons.check_circle_rounded,
                                          size: 22, color: Color(0xFF0F766E))
                                    else
                                      const Icon(Icons.circle_outlined,
                                          size: 20, color: Color(0xFFCBD5E1)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "નવી સોસાયટી".tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "ચેરમેન / એડમિન સેટઅપ".tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ૨. પ્રીમિયમ ઇન્ફો બેનર
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F766E).withValues(alpha: 0.08),
                          const Color(0xFF14B8A6).withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF0F766E), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _mode == _RegMode.member
                                ? "સોસાયટીમાં રહેતા તમામ પરિવારો કે દુકાનદારો અહીંથી સીધા જોડાઈ શકે છે.".tr
                                : "નવી સોસાયટી શરૂ કરવા ચેરમેન / સેક્રેટરી અહીંથી સેટઅપ કરી શકે છે.".tr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F766E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ૩. ફોર્મ કાર્ડ ૧: વ્યક્તિગત વિગતો
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_rounded, size: 18, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text(
                              "વ્યક્તિગત પ્રોફાઇલ માહિતી".tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // નામ
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _mode == _RegMode.member ? 'પૂરું નામ *'.tr : 'ચેરમેન / એડમિનનું નામ *'.tr,
                            hintText: "દા.ત. રમેશભાઈ પટેલ".tr,
                            prefixIcon: _inputIcon(Icons.person_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // મોબાઇલ
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'મોબાઇલ નંબર (કોન્ટેક્ટ)'.tr,
                            hintText: "દા.ત. 9876543210".tr,
                            prefixIcon: _inputIcon(Icons.phone_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ઇમેઇલ
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'ઇમેઇલ એડ્રેસ *'.tr,
                            hintText: "દા.ત. ramesh@example.com".tr,
                            prefixIcon: _inputIcon(Icons.alternate_email_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // પાસવર્ડ
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'પાસવર્ડ (ઓછામાં ઓછા ૬ અક્ષર) *'.tr,
                            hintText: "••••••••",
                            prefixIcon: _inputIcon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ૪. ફોર્મ કાર્ડ ૨: પ્રિમાઇસીસ અને યુનિટ વિગતો
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Text(
                              _mode == _RegMode.member ? "સોસાયટી અને યુનિટ વિગતો".tr : "નવી સોસાયટી કોન્ફિગરેશન".tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (_mode == _RegMode.newSocietyAdmin) ...[
                          // સોસાયટી નામ
                          TextField(
                            controller: _societyNameController,
                            decoration: InputDecoration(
                              labelText: 'સોસાયટીનું નામ *'.tr,
                              hintText: 'દા.ત. શિવ રેસીડેન્સી / રત્નમ મોલ'.tr,
                              prefixIcon: _inputIcon(Icons.location_city_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // નવો સોસાયટી કોડ
                          TextField(
                            controller: _societyCodeController,
                            decoration: InputDecoration(
                              labelText: 'નવો સોસાયટી કોડ (અંગ્રેજીમાં) *'.tr,
                              hintText: 'દા.ત. shiv-residency'.tr,
                              helperText: 'અન્ય સભ્યો આ કોડ વાપરીને જોડાશે.'.tr,
                              helperStyle: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                              prefixIcon: _inputIcon(Icons.tag_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                              ),
                            ),
                          ),
                        ] else ...[
                          // સભ્ય સોસાયટી કોડ
                          TextField(
                            controller: _societyCodeController,
                            decoration: InputDecoration(
                              labelText: 'સોસાયટી કોડ (Society Code)'.tr,
                              hintText: 'દા.ત. shiv-residency'.tr,
                              helperText: 'ખાલી રાખશો તો default society ગણાશે.'.tr,
                              helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              prefixIcon: _inputIcon(Icons.tag_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // વિંગ અને ફ્લેટ નંબર
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _blockController,
                                  decoration: InputDecoration(
                                    labelText: 'વિંગ / શેરી'.tr,
                                    hintText: 'દા.ત. A, શેરી 1'.tr,
                                    prefixIcon: _inputIcon(Icons.home_work_rounded),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _unitController,
                                  decoration: InputDecoration(
                                    labelText: 'ફ્લેટ / દુકાન નં.'.tr,
                                    hintText: 'દા.ત. 101, G-01'.tr,
                                    prefixIcon: _inputIcon(Icons.door_front_door_rounded),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // લાઇવ એડ્રેસ પ્રીવ્યૂ બેજ
                          if (hasAddressPreview) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "તમારું યુનિટ: વિંગ '${previewBlock.isEmpty ? '-' : previewBlock}' - ફ્લેટ/દુકાન '${previewUnit.isEmpty ? '-' : previewUnit}'".tr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ૫. સુરક્ષા નોંધ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: Color(0xFF475569)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "સુરક્ષા નિયમ: વોચમેન / ગાર્ડનું ખાતું માત્ર એડમિન ડેશબોર્ડના સ્ટાફ વિભાગમાંથી જ બની શકે છે.".tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ૬. સબમિટ CTA બટન
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _mode == _RegMode.newSocietyAdmin
                                        ? Icons.rocket_launch_rounded
                                        : Icons.how_to_reg_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _mode == _RegMode.newSocietyAdmin
                                        ? "નવી સોસાયટી રજીસ્ટર કરો".tr
                                        : "મેમ્બર તરીકે રજીસ્ટર કરો".tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ૭. લૉગિન પેજ લિંક
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: "પહેલેથી એકાઉન્ટ છે? ".tr,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          children: [
                            TextSpan(
                              text: "લૉગિન કરો".tr,
                              style: TextStyle(
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
    );
  }
}
