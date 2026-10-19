import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_firestore.dart';
import '../screens/login_screen.dart';
import 'society_service.dart';

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
  String? _listeningUid;
  bool _isEvicting = false;

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
    _listeningUid = null;
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

    startListening(uid);
    return true;
  }

  /// Actively monitors the Firestore user document for session invalidations
  void startListening(String uid) {
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
      }
    }, onError: (err) {
      debugPrint('SessionGuardService listener error: $err');
    });
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
              const Text(
                "અન્ય ડિવાઇસમાં લૉગિન થયેલ છે",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "તમારું એકાઉન્ટ અન્ય ડિવાઇસ પર લૉગિન કરવામાં આવ્યું હોવાથી આ ડિવાઇસમાંથી સુરક્ષિત રીતે લૉગઆઉટ કરવામાં આવ્યું છે.\n\nસુરક્ષાના નિયમ મુજબ એક સમયે માત્ર ૧ જ ડિવાઇસમાં લૉગિન રહી શકાય છે.",
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
                    child: const Center(
                      child: Text(
                        "સમજાઈ ગયું (લૉગિન કરો)",
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
