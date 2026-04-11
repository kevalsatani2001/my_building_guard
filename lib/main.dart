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
import 'services/notification_service.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Society Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (!userSnap.hasData || !userSnap.data!.exists) {
                return const LoginScreen();
              }
              final userData = userSnap.data!.data() as Map<String, dynamic>?;
              if (userData != null && userData['isActive'] == false) {
                return const _AccountBlockedMessage();
              }
              String role = userSnap.data!.get('role');
              if (role == 'admin') return const AdminDashboard();
              if (role == 'watchman') return const WatchmanScreen();
              return const MemberScreen();
            },
          );
        }
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
