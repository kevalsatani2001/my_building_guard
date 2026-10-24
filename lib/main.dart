import 'package:building_guard/core/app_firestore.dart';
import 'dart:async';

import 'package:building_guard/screens/watchmen_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_messaging_background.dart';
import 'firebase_options.dart';
import 'screens/admin_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/member_screen.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/admin_suspended_screen.dart';
import 'screens/society_suspended_notice_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/localization_service.dart';
import 'services/session_guard_service.dart';
import 'services/society_service.dart';
import 'theme/premium_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize selected language (Gujarati, Hindi, or English)
  await LocalizationService.instance.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM topic/token sync often hits SERVICE_NOT_AVAILABLE before Play Services is ready.
  // Defer notification setup until after the first frame so the UI thread is not blocked (helps MIUI / low-RAM devices).
  runApp(const SocietyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationService.instance.initialize());
  });
}

class SocietyApp extends StatelessWidget {
  const SocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, activeLocale, child) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Society Manager',
          theme: PremiumTheme.light(),
          locale: activeLocale,
          supportedLocales: const [
            Locale('gu'),
            Locale('hi'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final currentUser = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: AppFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (!userSnap.hasData || !userSnap.data!.exists) {
                SocietyService.instance.clear();
                SessionGuardService.instance.stopListening();
                return const LoginScreen();
              }
              final userData = userSnap.data!.data() as Map<String, dynamic>?;
              SocietyService.instance.bindFromUserMap(userData);

              // Bind single-device session guard listener
              SessionGuardService.instance.validateAndAttachSession(context, currentUser.uid, userData);

              final email = (currentUser.email ?? '').toLowerCase().trim();
              final rawRole = (userData?['role'] ?? 'member')
                  .toString()
                  .toLowerCase()
                  .trim();

              final bool isSuper = email == 'kevaladmin@gmail.com' ||
                  rawRole == 'super_admin' ||
                  rawRole == 'superadmin' ||
                  userData?['isSuperAdmin'] == true;

              // સુપર એડમિન સીધા સુપર એડમિન ડેશબોર્ડમાં પ્રવેશશે
              if (isSuper) return const SuperAdminDashboard();

              final bool isAdmin = rawRole == 'admin' ||
                  rawRole == 'chairman' ||
                  rawRole == 'president' ||
                  userData?['isAdmin'] == true;

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

              final bool isGuard = rawRole == 'watchman' ||
                  rawRole == 'guard' ||
                  rawRole == 'security' ||
                  rawRole == 'gate_staff' ||
                  userData?['isGuard'] == true;

              final societyId = (userData?['societyId'] ?? '').toString().trim();
              final effectiveSocietyId = societyId.isEmpty ? SocietyService.kDefaultSocietyId : societyId;

              // સોસાયટી સેટિંગ્સનો રીયલ-ટાઇમ પ્રવાહ સાંભળો જેથી કેસ્કેડ બ્લોક આપમેળે લાગુ પડે
              return StreamBuilder<DocumentSnapshot>(
                stream: AppFirestore.instance.collection('society_settings').doc(effectiveSocietyId).snapshots(),
                builder: (context, socSnap) {
                  if (socSnap.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  final socData = socSnap.data?.data() as Map<String, dynamic>?;
                  final bool isSocietyActive = socData == null || socData['isActive'] != false;
                  final bool isAdminBlocked = socData?['isAdminBlocked'] == true;
                  final bool isSuspendedBySuperAdmin = socData?['isSuspendedBySuperAdmin'] == true;
                  final bool isUserActive = userData?['isActive'] != false;

                  // જો સોસાયટી ફ્રીઝ હોય અથવા સોસાયટીનો એડમિન બ્લોક હોય અથવા યુઝર જાતે બ્લોક હોય:
                  if (!isSocietyActive || isAdminBlocked || isSuspendedBySuperAdmin || !isUserActive) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final nav = rootNavigatorKey.currentState;
                      if (nav != null && nav.canPop()) {
                        nav.popUntil((route) => route.isFirst);
                      }
                    });

                    if (isAdmin) {
                      return AdminSuspendedScreen(
                        societyId: effectiveSocietyId,
                        userData: userData,
                        societyData: socData,
                      );
                    } else {
                      return SocietySuspendedNoticeScreen(
                        societyData: socData,
                        societyName: socData?['name'] ?? socData?['societyName'] ?? userData?['societyName'],
                      );
                    }
                  }

                  if (isAdmin || isSubAdminOrCommittee) return const AdminDashboard();
                  if (isGuard) return const WatchmanScreen();
                  return const MemberScreen();
                },
              );
            },
          );
        }
        SocietyService.instance.clear();
        SessionGuardService.instance.stopListening();
        return const LoginScreen();
      },
    );
  }
}

class _AccountBlockedMessage extends StatefulWidget {
  const _AccountBlockedMessage();

  @override
  State<_AccountBlockedMessage> createState() => _AccountBlockedMessageState();
}

class _AccountBlockedMessageState extends State<_AccountBlockedMessage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAuth.instance.signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'આ એકાઉન્ટ નિષ્ક્રિય અથવા બ્લૉક કરવામાં આવ્યું છે.\nએડમિનનો સંપર્ક કરો.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
