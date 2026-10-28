import 'dart:async';

import 'package:building_guard/screens/watchman/watchmen_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_messaging_background.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/member/member_screen.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/auth/admin_suspended_screen.dart';
import 'screens/auth/society_suspended_notice_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/localization_service.dart';
import 'services/session_guard_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/blocs.dart';
import 'theme/premium_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize selected language (Gujarati, Hindi, or English)
  await LocalizationService.instance.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Root MultiBlocProvider provides all application-wide BLoC instances
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(const AuthSubscriptionRequested()),
        ),
        BlocProvider<VisitorBloc>(
          create: (_) => VisitorBloc(),
        ),
        BlocProvider<MaintenanceBloc>(
          create: (_) => MaintenanceBloc(),
        ),
        BlocProvider<GuardPatrolBloc>(
          create: (_) => GuardPatrolBloc(),
        ),
        BlocProvider<SocietyAccountsBloc>(
          create: (_) => SocietyAccountsBloc(),
        ),
        BlocProvider<PollsBloc>(
          create: (_) => PollsBloc(),
        ),
        BlocProvider<AmenitiesBloc>(
          create: (_) => AmenitiesBloc(),
        ),
        BlocProvider<ComplaintsBloc>(
          create: (_) => ComplaintsBloc(),
        ),
        BlocProvider<ParkingBloc>(
          create: (_) => ParkingBloc(),
        ),
        BlocProvider<NoticeBloc>(
          create: (_) => NoticeBloc(),
        ),
        BlocProvider<StaffBloc>(
          create: (_) => StaffBloc(),
        ),
        BlocProvider<SuperAdminBloc>(
          create: (_) => SuperAdminBloc(),
        ),
        BlocProvider<SocietySetupBloc>(
          create: (_) => SocietySetupBloc(),
        ),
      ],
      child: const SocietyApp(),
    ),
  );
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          SessionGuardService.instance.validateAndAttachSession(
            context,
            state.user.uid,
            state.userData,
          );

          if (state.destination == AuthDestination.adminSuspended ||
              state.destination == AuthDestination.societySuspended) {
            final nav = rootNavigatorKey.currentState;
            if (nav != null && nav.canPop()) {
              nav.popUntil((route) => route.isFirst);
            }
          }
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || (state is AuthLoading && state.message == null)) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            ),
          );
        }

        if (state is Authenticated) {
          switch (state.destination) {
            case AuthDestination.superAdmin:
              return const SuperAdminDashboard();
            case AuthDestination.adminSuspended:
              return AdminSuspendedScreen(
                societyId: state.effectiveSocietyId,
                userData: state.userData,
                societyData: state.societyData,
              );
            case AuthDestination.societySuspended:
              return SocietySuspendedNoticeScreen(
                societyData: state.societyData,
                societyName: state.societyData?['name'] ??
                    state.societyData?['societyName'] ??
                    state.userData?['societyName'],
              );
            case AuthDestination.admin:
              return const AdminDashboard();
            case AuthDestination.watchman:
              return const WatchmanScreen();
            case AuthDestination.member:
              return const MemberScreen();
          }
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
