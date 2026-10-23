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
import 'services/session_guard_service.dart';
import 'services/society_service.dart';
import 'theme/premium_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Society Manager',
      theme: PremiumTheme.light(),
      home: const AuthWrapper(),
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
          return FutureBuilder<DocumentSnapshot>(
            future: () async {
              final newDb = AppFirestore.instance;
              final uid = currentUser.uid;
              var doc = await newDb.collection('users').doc(uid).get();
              if (!doc.exists) {
                try {
                  final oldDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                  if (oldDoc.exists && oldDoc.data() != null) {
                    await newDb.collection('users').doc(uid).set(oldDoc.data()!);
                    doc = await newDb.collection('users').doc(uid).get();
                  }
                } catch (_) {}
              }
              return doc;
            }(),
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
              final rawRole = (userData?['role'] ??
                      (userSnap.data!.data() as Map<String, dynamic>?)?['role'] ??
                      'member')
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
                  rawRole == 'president';

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

              // જો societyId હોય તો society_settings નો રીયલ-ટાઇમ પ્રવાહ સાંભળો જેથી કેસ્કેડ બ્લોક આપમેળે લાગુ પડે
              if (societyId.isNotEmpty && societyId != 'default') {
                return StreamBuilder<DocumentSnapshot>(
                  stream: AppFirestore.instance.collection('society_settings').doc(societyId).snapshots(),
                  builder: (context, socSnap) {
                    final socData = socSnap.data?.data() as Map<String, dynamic>?;
                    final bool isSocietyActive = socData == null || socData['isActive'] != false;
                    final bool isAdminBlocked = socData?['isAdminBlocked'] == true;
                    final bool isUserActive = userData?['isActive'] != false;

                    // જો સોસાયટી ફ્રીઝ હોય અથવા સોસાયટીનો એડમિન બ્લોક હોય અથવા યુઝર જાતે બ્લોક હોય:
                    if (!isSocietyActive || isAdminBlocked || !isUserActive) {
                      if (isAdmin) {
                        return AdminSuspendedScreen(
                          societyId: societyId,
                          userData: userData,
                          societyData: socData,
                        );
                      } else {
                        return SocietySuspendedNoticeScreen(
                          societyData: socData,
                          societyName: socData?['name'] ?? userData?['societyName'],
                        );
                      }
                    }

                    if (isAdmin || isSubAdminOrCommittee) return const AdminDashboard();
                    if (isGuard) return const WatchmanScreen();
                    return const MemberScreen();
                  },
                );
              }

              // Default society fallback
              if (userData != null && userData['isActive'] == false) {
                if (isAdmin) {
                  return AdminSuspendedScreen(societyId: 'default', userData: userData);
                } else {
                  return const SocietySuspendedNoticeScreen();
                }
              }

              if (isAdmin || isSubAdminOrCommittee) return const AdminDashboard();
              if (isGuard) return const WatchmanScreen();
              return const MemberScreen();
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
