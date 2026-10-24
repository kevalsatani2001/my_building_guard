import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_firestore.dart';
import '../screens/login_screen.dart';
import 'society_service.dart';
import 'package:building_guard/l10n/app_strings.dart';

import '../screens/admin_suspended_screen.dart';
import '../screens/society_suspended_notice_screen.dart';

/// Global navigator key allowing the SessionGuardService to present
/// non-dismissible kick-out dialogs regardless of current route or open modal.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Ensures that a user account (Admin, Member, or Watchman) can ONLY be logged in
/// on a single device at any given time. If an account is logged in on a second device,
/// the previous device is immediately notified, shows an alert, and is signed out.
class SessionGuardService {
  static final SessionGuardService instance = SessionGuardService._internal();
  SessionGuardService._internal();

  static const String _kSessionKey = 'active_session_id';
  StreamSubscription<DocumentSnapshot>? _subscription;
  StreamSubscription<DocumentSnapshot>? _societySubscription;
  String? _listeningUid;
  bool _isEvicting = false;
  bool _isSuspended = false;

  /// Complete, unified app logout that cleans all state and immediately resets Navigator to LoginScreen
  static Future<void> performAppLogout([BuildContext? context]) async {
    try {
      await SessionGuardService.instance.clearSession();
      SessionGuardService.instance.stopListening();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    SocietyService.instance.clear();

    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (context != null && context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Retrieves the locally stored session ID for this device
  Future<String?> getLocalSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kSessionKey);
    } catch (_) {
      return null;
    }
  }

  /// Persists the active session ID locally
  Future<void> saveLocalSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSessionKey, sessionId);
    } catch (_) {}
  }

  /// Clears local session on manual logout
  Future<void> clearSession() async {
    stopListening();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSessionKey);
    } catch (_) {}
  }

  /// Cancels any active Firestore stream subscription
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _societySubscription?.cancel();
    _societySubscription = null;
    _listeningUid = null;
    _isSuspended = false;
  }

  /// Registers a new active session on this device upon successful login or registration
  Future<String> registerNewLoginSession(String uid) async {
    final randomSuffix = Random().nextInt(900000) + 100000;
    final sessionId = '${DateTime.now().millisecondsSinceEpoch}_$randomSuffix';
    await saveLocalSessionId(sessionId);

    try {
      await AppFirestore.instance.collection('users').doc(uid).update({
        'currentSessionId': sessionId,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('SessionGuardService: Error updating session in Firestore: $e');
    }

    startListening(uid);
    return sessionId;
  }

  /// Validates the device's session on app launch / auth restoration in AuthWrapper.
  /// Returns false if a conflict is detected and the device is being evicted.
  Future<bool> validateAndAttachSession(
    BuildContext context,
    String uid,
    Map<String, dynamic>? userData,
  ) async {
    final remoteSessionId = userData?['currentSessionId'] as String?;
    final localSessionId = await getLocalSessionId();

    // If remote has a different session ID than local, user logged in on another device!
    if (remoteSessionId != null &&
        localSessionId != null &&
        remoteSessionId != localSessionId) {
      _triggerDeviceKickout();
      return false;
    }

    if (localSessionId == null) {
      if (remoteSessionId != null) {
        // First run on existing logged-in session, adopt the remote ID
        await saveLocalSessionId(remoteSessionId);
      } else {
        // Firestore doesn't have a session ID yet, initialize one
        await registerNewLoginSession(uid);
        return true;
      }
    }

    final sid = (userData?['societyId'] ?? '').toString();
    startListening(uid, societyId: sid.isNotEmpty ? sid : null);
    return true;
  }

  /// Actively monitors the Firestore user document for session invalidations and block status
  void startListening(String uid, {String? societyId}) {
    if (_listeningUid == uid && _subscription != null) return;
    stopListening();
    _listeningUid = uid;

    _subscription = AppFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data() as Map<String, dynamic>;
      final remoteSessionId = data['currentSessionId'] as String?;
      final localSessionId = await getLocalSessionId();

      // Another device has logged in and changed the session ID!
      if (remoteSessionId != null &&
          localSessionId != null &&
          remoteSessionId != localSessionId) {
        _triggerDeviceKickout();
        return;
      }

      // Check if user account was blocked by Super Admin
      final bool isUserActive = data['isActive'] != false;
      if (!isUserActive) {
        final rawRole = (data['role'] ?? '').toString().toLowerCase().trim();
        final bool isAdmin = rawRole == 'admin' ||
            rawRole == 'chairman' ||
            rawRole == 'president' ||
            data['isAdmin'] == true;
        final sid = (data['societyId'] ?? societyId ?? SocietyService.kDefaultSocietyId).toString();
        _triggerSuspensionKickout(isAdmin: isAdmin, societyId: sid, userData: data);
      }
    }, onError: (err) {
      debugPrint('SessionGuardService listener error: $err');
    });

    // Also monitor society_settings for cascade admin block or society freeze
    final effectiveSid = (societyId != null && societyId.trim().isNotEmpty)
        ? societyId.trim()
        : SocietyService.instance.societyId;
    if (effectiveSid.isNotEmpty) {
      _societySubscription = AppFirestore.instance
          .collection('society_settings')
          .doc(effectiveSid)
          .snapshots()
          .listen((socSnap) {
        if (!socSnap.exists || socSnap.data() == null) return;
        final socData = socSnap.data() as Map<String, dynamic>;
        final bool isSocietyActive = socData['isActive'] != false;
        final bool isAdminBlocked = socData['isAdminBlocked'] == true;
        final bool isSuspendedBySuperAdmin = socData['isSuspendedBySuperAdmin'] == true;

        if (!isSocietyActive || isAdminBlocked || isSuspendedBySuperAdmin) {
          final bool isAdmin = SocietyService.instance.isAdmin;
          _triggerSuspensionKickout(
            isAdmin: isAdmin,
            societyId: effectiveSid,
            societyData: socData,
          );
        }
      }, onError: (err) {
        debugPrint('SessionGuardService society listener error: $err');
      });
    }
  }

  void _triggerSuspensionKickout({
    required bool isAdmin,
    required String societyId,
    Map<String, dynamic>? societyData,
    Map<String, dynamic>? userData,
  }) {
    if (_isSuspended) return;
    _isSuspended = true;

    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isAdmin
              ? AdminSuspendedScreen(
                  societyId: societyId.isEmpty ? SocietyService.kDefaultSocietyId : societyId,
                  userData: userData,
                  societyData: societyData,
                )
              : SocietySuspendedNoticeScreen(
                  societyData: societyData,
                  societyName: societyData?['name'] ?? societyData?['societyName'] ?? userData?['societyName'],
                ),
        ),
        (route) => false,
      );
    }
  }

  /// Evicts the current device with a luxury non-dismissible alert dialog
  Future<void> _triggerDeviceKickout() async {
    if (_isEvicting) return;
    _isEvicting = true;

    stopListening();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSessionKey);
    } catch (_) {}
    SocietyService.instance.clear();

    final nav = rootNavigatorKey.currentState;
    final context = rootNavigatorKey.currentContext;

    if (context != null && nav != null && context.mounted) {
      try {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const SessionConflictDialog(),
        );
      } catch (_) {}

      await FirebaseAuth.instance.signOut();
      _isEvicting = false;

      if (nav.mounted) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      await FirebaseAuth.instance.signOut();
      _isEvicting = false;
    }
  }
}

/// Luxury Dialog displayed when an active session is taken over by another device
class SessionConflictDialog extends StatelessWidget {
  const SessionConflictDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amber glowing device icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.devices_other_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "અન્ય ડિવાઇસમાં લૉગિન થયેલ છે".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "તમારું એકાઉન્ટ અન્ય ડિવાઇસ પર લૉગિન કરવામાં આવ્યું હોવાથી આ ડિવાઇસમાંથી સુરક્ષિત રીતે લૉગઆઉટ કરવામાં આવ્યું છે.\n\nસુરક્ષાના નિયમ મુજબ એક સમયે માત્ર ૧ જ ડિવાઇસમાં લૉગિન રહી શકાય છે.".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(13),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "સમજાઈ ગયું (લૉગિન કરો)".tr,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
  }
}
