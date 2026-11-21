import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../services/session_guard_service.dart';
import '../admin/admin_dashboard.dart';
import '../member/member_screen.dart';
import '../super_admin/super_admin_dashboard.dart';
import '../watchman/watchmen_screen.dart';
import 'admin_suspended_screen.dart';
import 'society_suspended_notice_screen.dart';
import 'login_screen.dart';

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

          // Pop any pushed routes or dialogs so root dashboard is on top
          final nav = rootNavigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.popUntil((route) => route.isFirst);
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

