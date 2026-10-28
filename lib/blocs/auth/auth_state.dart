import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Target destination screen computed by AuthBloc
enum AuthDestination {
  superAdmin,
  admin,
  watchman,
  member,
  adminSuspended,
  societySuspended,
}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before auth check starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during login or initial session resolution
class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// User is not logged in
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// User is authenticated and active session has been resolved
class Authenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? societyData;
  final AuthDestination destination;
  final String effectiveSocietyId;

  const Authenticated({
    required this.user,
    this.userData,
    this.societyData,
    required this.destination,
    required this.effectiveSocietyId,
  });

  @override
  List<Object?> get props => [
        user.uid,
        userData,
        societyData,
        destination,
        effectiveSocietyId,
      ];
}

/// Login attempt failed with error message
class AuthLoginFailure extends AuthState {
  final String errorMessage;
  const AuthLoginFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
