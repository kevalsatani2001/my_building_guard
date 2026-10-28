import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app start to subscribe to Firebase Auth and Firestore streams
class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

/// Fired internally when the Firebase Auth user changes
class AuthUserChanged extends AuthEvent {
  final User? user;
  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user?.uid];
}

/// Fired internally when the Firestore user document updates
class AuthUserDataUpdated extends AuthEvent {
  final Map<String, dynamic>? userData;
  const AuthUserDataUpdated(this.userData);

  @override
  List<Object?> get props => [userData];
}

/// Fired internally when society settings document updates
class AuthSocietySettingsUpdated extends AuthEvent {
  final Map<String, dynamic>? societyData;
  const AuthSocietySettingsUpdated(this.societyData);

  @override
  List<Object?> get props => [societyData];
}

/// Fired internally when auth streams fail
class AuthStreamErrorOccurred extends AuthEvent {
  final String error;
  const AuthStreamErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Fired when the user submits login credentials (email or 10-digit mobile number)
class AuthLoginRequested extends AuthEvent {
  final String input;
  final String password;

  const AuthLoginRequested({
    required this.input,
    required this.password,
  });

  @override
  List<Object?> get props => [input, password];
}

/// Fired when logout is requested
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
