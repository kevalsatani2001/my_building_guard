import 'dart:ui';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../services/society_service.dart';
import '../../services/localization_service.dart';
import '../../l10n/app_strings.dart';

enum CyberToastType { info, warning, error, success }

void showCyberToast(
  BuildContext context, {
  required String message,
  CyberToastType type = CyberToastType.warning,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  Color accentColor;
  IconData iconData;
  String badgeLabel;

  switch (type) {
    case CyberToastType.error:
      accentColor = const Color(0xFFF43F5E);
      iconData = Icons.error_outline_rounded;
      badgeLabel = "ERROR";
      break;
    case CyberToastType.success:
      accentColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_outline_rounded;
      badgeLabel = "SUCCESS";
      break;
    case CyberToastType.info:
      accentColor = const Color(0xFF06B6D4);
      iconData = Icons.info_outline_rounded;
      badgeLabel = "INFO";
      break;
    case CyberToastType.warning:
      accentColor = const Color(0xFFF59E0B);
      iconData = Icons.warning_amber_rounded;
      badgeLabel = "NOTICE";
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 4),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 16,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.25,
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
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF090E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final rawInput = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (rawInput.isEmpty || password.isEmpty) {
      showCyberToast(
        context,
        message: AppStrings.get('input_required'),
        type: CyberToastType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            input: rawInput,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF090E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF090E17),
        body: Stack(
        children: [
          // ============================================================
          // ૧. ફુલ-સ્ક્રીન સિનેમેટિક આર્કિટેક્ચરલ બેકગ્રાઉન્ડ ઇમેજ
          // ============================================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_hero.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ============================================================
          // ૨. ડીપ મલ્ટી-લેયર ડાર્ક ગ્રેડિયન્ટ ઓવરલે
          // ============================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.28, 0.65, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    const Color(0xFF090E17).withValues(alpha: 0.78),
                    const Color(0xFF0B1322).withValues(alpha: 0.90),
                    const Color(0xFF090E17).withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // ૩. એમ્બિયન્ટ સાયબર-નિયોન ગ્લો ઓર્બ્સ (Electric Teal & Royal Indigo)
          // ============================================================
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4338CA).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // ૪. ફોરગ્રાઉન્ડ કન્ટેન્ટ (Safe Area + Full Scrollable Surface)
          // ============================================================
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ટોપ બાર: ERP બેજ + લેંગ્વેજ સ્વિચર
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ફ્રોસ્ટેડ ગ્લાસ ERP બેજ
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.85),
                                            blurRadius: 8,
                                            spreadRadius: 1.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "BUILDING GUARD ERP",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ફ્રોસ્ટેડ ગ્લાસ લેંગ્વેજ સ્વિચર
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1,
                                  ),
                                ),
                                child: const LanguageSwitchButton(isDark: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // બ્રાન્ડ એમ્બ્લેમ & હેડલાઇન
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF10B981)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF14B8A6).withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.shield_rounded, size: 28, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.get('login_hero_title'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.get('login_hero_subtitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.78),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ============================================================
                      // ૫. ફ્રોસ્ટેડ ગ્લાસ કાર્ડ (Glassmorphism Masterpiece)
                      // ============================================================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                  blurRadius: 36,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // કાર્ડ ટાઇટલ & સબટાઇટલ
                                Text(
                                  AppStrings.get('login_to_account'),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.get('login_subtitle'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // સ્માર્ટ ઑટો-રોલ પિલ સ્ટ્રિપ
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.32),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 13,
                                              color: Color(0xFF5EEAD4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppStrings.get('auto_role_detection'),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF5EEAD4),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "AI-ROUTING",
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF5EEAD4),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 7,
                                        children: [
                                          _buildRoleMiniBadge(AppStrings.get('role_badge_admin'), const Color(0xFF14B8A6)),
                                          _buildRoleMiniBadge(AppStrings.get('role_badge_committee'), const Color(0xFF60A5FA)),
                                          _buildRoleMiniBadge(AppStrings.get('role_badge_guard'), const Color(0xFFFBBF24)),
                                          _buildRoleMiniBadge(AppStrings.get('role_badge_member'), const Color(0xFFCBD5E1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // ============================================================
                                // ઇનપુટ ફીલ્ડ્સ (Translucent High-Tech Inputs)
                                // ============================================================
                                // ૧. ઇમેઇલ અથવા મોબાઇલ નંબર
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  cursorColor: const Color(0xFF2DD4BF),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.get('email_or_phone_label'),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: AppStrings.get('email_or_phone_hint'),
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                    prefixIcon: _inputIcon(Icons.alternate_email_rounded),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.08),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // ૨. પાસવર્ડ
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  cursorColor: const Color(0xFF2DD4BF),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.get('password_label'),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    hintText: AppStrings.get('password_hint'),
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                    prefixIcon: _inputIcon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white.withValues(alpha: 0.75),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.08),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // પાસવર્ડ ભૂલી ગયા?
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.key_rounded, size: 14, color: Color(0xFF2DD4BF)),
                                    label: Text(
                                      AppStrings.get('forgot_password'),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2DD4BF),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ============================================================
                                // મુખ્ય લૉગિન બટન (Luminous Cyber-Teal Gradient CTA)
                                // ============================================================
                                BlocConsumer<AuthBloc, AuthState>(
                                  listener: (context, state) {
                                    if (state is AuthLoginFailure) {
                                      showCyberToast(
                                        context,
                                        message: state.errorMessage,
                                        type: CyberToastType.error,
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    final isLoggingIn = state is AuthLoading;

                                    return SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF10B981)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0D9488).withValues(alpha: 0.5),
                                              blurRadius: 20,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isLoggingIn ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: isLoggingIn
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
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      AppStrings.get('login_button'),
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.22),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.arrow_forward_rounded,
                                                        size: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // સત્તાવાર એકાઉન્ટ નીતિ (Frosted Glass Tile)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Material(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    child: InkWell(
                                      onTap: () => _showAccountAccessPolicySheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.14),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.verified_user_outlined,
                                                size: 16,
                                                color: Color(0xFF5EEAD4),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    AppStrings.get('how_to_get_account'),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 12.5,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    AppStrings.get('account_policy_sub'),
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white.withValues(alpha: 0.65),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 12,
                                              color: Colors.white.withValues(alpha: 0.6),
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
                      const SizedBox(height: 20),

                      // બોટમ ટ્રસ્ટ બેજ સીલ
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              "256-Bit SSL",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                            ),
                            Icon(Icons.verified_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              "ISO 27001",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("•", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                            ),
                            Icon(Icons.cloud_done_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              "Cloud ERP",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2DD4BF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "એકાઉન્ટ એક્સેસ નીતિ".tr,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "સુરક્ષા માટે જાતે રજીસ્ટ્રેશન પ્રતિબંધિત છે".tr,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Building Guard એપમાં કોઈ સભ્ય કે એડમિન સીધા જાતે એકાઉન્ટ બનાવી શકતા નથી. ફક્ત અધિકૃત એડમિન જ નવું એકાઉન્ટ બનાવીને લૉગિન વિગતો આપી શકે છે.".tr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFFDE68A), height: 1.4),
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
                    color: const Color(0xFF2DD4BF),
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyItem(
                    title: "૨. સોસાયટી મેમ્બર / રહીશ".tr,
                    desc: "તમારા ફ્લેટ/ઘર માટેનું એકાઉન્ટ તમારી સોસાયટીના એડમિન (ચેરમેન) દ્વારા ડેશબોર્ડમાંથી ઉમેરવામાં આવે છે અને તમને લૉગિન ઈમેલ/મોબાઈલ અને પાસવર્ડ આપવામાં આવે છે.".tr,
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyItem(
                    title: "૩. સબ-એડમિન અને વોચમેન (ગાર્ડ)".tr,
                    desc: "કમિટી મેમ્બર, વિંગ એડમિન તથા સિક્યોરિટી ગાર્ડ્સનું એકાઉન્ટ પણ સોસાયટી એડમિન દ્વારા તેમના એડમિન પેનલમાંથી તૈયાર કરવામાં આવે છે.".tr,
                    icon: Icons.security_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          "સમજાઈ ગયું (Close)".tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white, letterSpacing: 0.1),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
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
      margin: const EdgeInsets.only(left: 12, right: 10, top: 9, bottom: 9),
      padding: const EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF5EEAD4)),
    );
  }

  Widget _buildRoleMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2DD4BF), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "પાસવર્ડ રીસેટ".tr,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "તમારો રજીસ્ટર્ડ ઇમેઇલ દાખલ કરો. અમે તમને પાસવર્ડ રીસેટ કરવાની લિંક મોકલીશું.".tr,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'ઇમેઇલ'.tr,
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF2DD4BF)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text("રદ કરો".tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () async {
                              final email = resetEmailController.text.trim();
                              if (email.isEmpty) return;
                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  showCyberToast(
                                    context,
                                    message: "પાસવર્ડ રીસેટ લિંક તમારા ઇમેઇલ પર મોકલવામાં આવી છે.".tr,
                                    type: CyberToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  showCyberToast(
                                    context,
                                    message: "ભૂલ આવી: $e".tr,
                                    type: CyberToastType.error,
                                  );
                                }
                              }
                            },
                            child: Text(
                              "લિંક મોકલો".tr,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
      showCyberToast(
        context,
        message: 'કૃપા કરીને નામ, ઇમેઇલ અને પાસવર્ડ ભરો.'.tr,
        type: CyberToastType.warning,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      showCyberToast(
        context,
        message: 'કૃપા કરીને માન્ય ઇમેઇલ એડ્રેસ લખો.'.tr,
        type: CyberToastType.warning,
      );
      return;
    }

    if (password.length < 6) {
      showCyberToast(
        context,
        message: 'પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ.'.tr,
        type: CyberToastType.warning,
      );
      return;
    }

    if (_mode == _RegMode.newSocietyAdmin && societyCode.isEmpty) {
      showCyberToast(
        context,
        message: 'નવી સોસાયટી માટે સોસાયટી કોડ લખવો ફરજિયાત છે.'.tr,
        type: CyberToastType.warning,
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
      showCyberToast(
        context,
        message: _mode == _RegMode.newSocietyAdmin
            ? 'સોસાયટી અને એડમિન એકાઉન્ટ સફળતાપૂર્વક બની ગયું! હવે લૉગિન કરો.'.tr
            : 'રજીસ્ટ્રેશન સફળ! હવે તમારા એકાઉન્ટમાં લૉગિન કરો.'.tr,
        type: CyberToastType.success,
      );
    } catch (e) {
      if (mounted) {
        showCyberToast(
          context,
          message: 'ભૂલ: ${e.toString()}'.tr,
          type: CyberToastType.error,
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
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(Icons.help_center_rounded, color: Color(0xFF2DD4BF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "રજીસ્ટ્રેશન માર્ગદર્શિકા (Help)".tr,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildGuideStep(
                    number: "૧".tr,
                    title: "રહીશ / સભ્ય રજીસ્ટ્રેશન".tr,
                    description:
                        "તમારા ચેરમેન કે સેક્રેટરી પાસેથી મેળવેલ સોસાયટી કોડ દાખલ કરો. તમારો વિંગ (દા.ત. A) અને ફ્લેટ/દુકાન નંબર (દા.ત. 101, G-02) લખીને રજીસ્ટર કરો.".tr,
                    icon: Icons.person_pin_rounded,
                    color: const Color(0xFF2DD4BF),
                  ),
                  const SizedBox(height: 12),

                  _buildGuideStep(
                    number: "૨".tr,
                    title: "નવી સોસાયટી (ચેરમેન / બિલ્ડર)".tr,
                    description:
                        "નવી સોસાયટી, રેસીડેન્સી કે શોપિંગ મોલનું સેટઅપ કરવા અહીંથી રજીસ્ટર કરો. તમારી સોસાયટી માટે અંગ્રેજીમાં યુનિક કોડ (દા.ત. shiv-residency) પસંદ કરો. લૉગિન કર્યા પછી એડમિન સેટઅપ વિઝાર્ડમાં વિંગ અને દુકાનો ઉમેરી શકશો.".tr,
                    icon: Icons.domain_add_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 12),

                  _buildGuideStep(
                    number: "૩".tr,
                    title: "વોચમેન / સિક્યુરિટી ગાર્ડ એકાઉન્ટ".tr,
                    description:
                        "સુરક્ષાના કારણોસર વોચમેનનું એકાઉન્ટ બહારથી રજીસ્ટર થઈ શકતું નથી. માત્ર ચેરમેન પોતાના એડમિન ડેશબોર્ડના 'સ્ટાફ મેનેજમેન્ટ'માંથી જ વોચમેનનું ખાતું બનાવી શકે છે.".tr,
                    icon: Icons.shield_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          "સમજાઈ ગયું".tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white, letterSpacing: 0.1),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
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
