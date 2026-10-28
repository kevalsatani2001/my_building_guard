import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_firestore.dart';
import '../../services/session_guard_service.dart';
import '../../services/society_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<DocumentSnapshot>? _societyDocSubscription;

  User? _currentUser;
  Map<String, dynamic>? _currentUserData;
  Map<String, dynamic>? _currentSocietyData;
  String _currentSubscribedSocietyId = '';

  AuthBloc({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const AuthInitial()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthStreamErrorOccurred>((event, emit) => emit(AuthLoginFailure(event.error)));
    on<AuthUserChanged>(_onUserChanged);
    on<AuthUserDataUpdated>(_onUserDataUpdated);
    on<AuthSocietySettingsUpdated>(_onSocietySettingsUpdated);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // ==========================================
  // SUBSCRIPTION & STREAM HANDLERS
  // ==========================================
  void _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _firebaseAuth.authStateChanges().listen((user) {
      add(AuthUserChanged(user));
    });
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    _currentUser = user;

    if (user == null) {
      _cancelFirestoreSubscriptions();
      _currentUserData = null;
      _currentSocietyData = null;
      _currentSubscribedSocietyId = '';
      SocietyService.instance.clear();
      SessionGuardService.instance.stopListening();
      emit(const Unauthenticated());
      return;
    }

    // If already authenticated with this exact user and data, keep it
    if (state is Authenticated && (state as Authenticated).user.uid == user.uid) {
      return;
    }

    emit(const AuthLoading());

    // Cancel existing user document subscription
    _userDocSubscription?.cancel();
    _userDocSubscription = AppFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists || snap.data() == null) {
        // Self-healing attempt by UID and email
        final healedData = await _attemptSelfHealUserDoc(user);
        add(AuthUserDataUpdated(healedData));
      } else {
        add(AuthUserDataUpdated(snap.data()));
      }
    }, onError: (err) {
      add(AuthStreamErrorOccurred(err.toString()));
    });
  }

  void _onUserDataUpdated(
    AuthUserDataUpdated event,
    Emitter<AuthState> emit,
  ) {
    final data = event.userData;
    _currentUserData = data;

    if (_currentUser == null) {
      _cancelFirestoreSubscriptions();
      SocietyService.instance.clear();
      SessionGuardService.instance.stopListening();
      emit(const Unauthenticated());
      return;
    }

    final effectiveData = data ?? {
      'uid': _currentUser!.uid,
      'email': _currentUser!.email ?? '',
      'role': 'member',
      'isActive': true,
    };

    // Bind global SocietyService state
    SocietyService.instance.bindFromUserMap(effectiveData);

    // Compute effective society id
    final socId = (effectiveData['societyId'] ?? '').toString().trim();
    final effectiveSocId = socId.isEmpty ? SocietyService.kDefaultSocietyId : socId;

    // Subscribe to society settings if changed
    if (_currentSubscribedSocietyId != effectiveSocId) {
      _currentSubscribedSocietyId = effectiveSocId;
      _societyDocSubscription?.cancel();
      _societyDocSubscription = AppFirestore.instance
          .collection('society_settings')
          .doc(effectiveSocId)
          .snapshots()
          .listen((socSnap) {
        if (socSnap.exists && socSnap.data() != null) {
          add(AuthSocietySettingsUpdated(socSnap.data()));
        }
      }, onError: (_) {});
    }

    final destination = _resolveDestination(
      user: _currentUser!,
      userData: effectiveData,
      societyData: _currentSocietyData,
    );

    emit(Authenticated(
      user: _currentUser!,
      userData: effectiveData,
      societyData: _currentSocietyData,
      destination: destination,
      effectiveSocietyId: effectiveSocId,
    ));
  }

  void _onSocietySettingsUpdated(
    AuthSocietySettingsUpdated event,
    Emitter<AuthState> emit,
  ) {
    _currentSocietyData = event.societyData;

    if (_currentUser != null && _currentUserData != null) {
      final socId = (_currentUserData!['societyId'] ?? '').toString().trim();
      final effectiveSocId = socId.isEmpty ? SocietyService.kDefaultSocietyId : socId;

      final destination = _resolveDestination(
        user: _currentUser!,
        userData: _currentUserData,
        societyData: event.societyData,
      );

      emit(Authenticated(
        user: _currentUser!,
        userData: _currentUserData,
        societyData: event.societyData,
        destination: destination,
        effectiveSocietyId: effectiveSocId,
      ));
    }
  }

  // ==========================================
  // LOGIN & LOGOUT ACTIONS
  // ==========================================
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final rawInput = event.input.trim();
    final password = event.password.trim();

    if (rawInput.isEmpty || password.isEmpty) {
      emit(const AuthLoginFailure('કૃપા કરીને ઇમેઇલ / મોબાઇલ અને પાસવર્ડ દાખલ કરો'));
      return;
    }

    emit(const AuthLoading(message: 'લૉગિન થઈ રહ્યું છે...'));

    try {
      String resolvedEmail = rawInput;

      // Check if user entered a 10-digit mobile number instead of email
      final cleanDigits = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.length >= 10 && !rawInput.contains('@')) {
        final last10 = cleanDigits.substring(cleanDigits.length - 10);

        // Search in AppFirestore (named database)
        var phoneQuery = await AppFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanDigits)
            .limit(1)
            .get();

        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: last10)
              .limit(1)
              .get();
        }
        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: '+91$last10')
              .limit(1)
              .get();
        }
        if (phoneQuery.docs.isEmpty) {
          phoneQuery = await AppFirestore.instance
              .collection('users')
              .where('displayPhone', isEqualTo: rawInput)
              .limit(1)
              .get();
        }

        // Search in default FirebaseFirestore if not found
        if (phoneQuery.docs.isEmpty) {
          try {
            var oldQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: cleanDigits)
                .limit(1)
                .get();
            if (oldQuery.docs.isEmpty) {
              oldQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('phone', isEqualTo: last10)
                  .limit(1)
                  .get();
            }
            if (oldQuery.docs.isEmpty) {
              oldQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('phone', isEqualTo: '+91$last10')
                  .limit(1)
                  .get();
            }
            if (oldQuery.docs.isNotEmpty) {
              phoneQuery = oldQuery;
            }
          } catch (_) {}
        }

        if (phoneQuery.docs.isNotEmpty) {
          final foundEmail = (phoneQuery.docs.first.data()['email'] ?? '').toString().trim();
          if (foundEmail.isNotEmpty) {
            resolvedEmail = foundEmail;
          }
        }
      }

      final normalizedEmail = resolvedEmail.trim().toLowerCase();

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(const AuthLoginFailure('લૉગિન નિષ્ફળ: યુઝર ખાતું મળ્યું નથી.'));
        return;
      }

      // Register session in local SharedPreferences and Firestore
      final sessionId = await SessionGuardService.instance.registerNewLoginSession(user.uid);

      // Fetch or self-heal user document
      DocumentSnapshot userDoc = await AppFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? userData;
      if (!userDoc.exists || userDoc.data() == null) {
        userData = await _attemptSelfHealUserDoc(user);
      } else {
        userData = Map<String, dynamic>.from(userDoc.data() as Map<String, dynamic>);
      }

      if (userData == null) {
        userData = {
          'uid': user.uid,
          'email': normalizedEmail,
          'role': 'member',
          'isActive': true,
          'currentSessionId': sessionId,
        };
        await AppFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
      } else {
        userData['currentSessionId'] = sessionId;
      }

      // Bind global society service
      SocietyService.instance.bindFromUserMap(userData);

      // Fetch society settings
      final socId = (userData['societyId'] ?? '').toString().trim();
      final effectiveSocId = socId.isEmpty ? SocietyService.kDefaultSocietyId : socId;

      Map<String, dynamic>? socData;
      try {
        final socDoc = await AppFirestore.instance
            .collection('society_settings')
            .doc(effectiveSocId)
            .get();
        if (socDoc.exists) {
          socData = socDoc.data();
        }
      } catch (_) {}

      _currentUser = user;
      _currentUserData = userData;
      _currentSocietyData = socData;
      _currentSubscribedSocietyId = effectiveSocId;

      // Start real-time listeners for updates
      _cancelFirestoreSubscriptions();
      _userDocSubscription = AppFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snap) {
        if (snap.exists && snap.data() != null) {
          add(AuthUserDataUpdated(snap.data()));
        }
      }, onError: (_) {});

      _societyDocSubscription = AppFirestore.instance
          .collection('society_settings')
          .doc(effectiveSocId)
          .snapshots()
          .listen((socSnap) {
        if (socSnap.exists && socSnap.data() != null) {
          add(AuthSocietySettingsUpdated(socSnap.data()));
        }
      }, onError: (_) {});

      final destination = _resolveDestination(
        user: user,
        userData: userData,
        societyData: socData,
      );

      emit(Authenticated(
        user: user,
        userData: userData,
        societyData: socData,
        destination: destination,
        effectiveSocietyId: effectiveSocId,
      ));
    } on FirebaseAuthException catch (e) {
      String message = 'લૉગિન ભૂલ: ${e.message ?? e.code}';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'અમાન્ય ક્રેડેન્શિયલ્સ: ઈમેલ/મોબાઇલ અથવા પાસવર્ડ ખોટો છે. કૃપા કરીને તપાસો.';
      } else if (e.code == 'invalid-email') {
        message = 'ઈમેલ એડ્રેસ અમાન્ય છે. કૃપા કરીને સાચો ઈમેલ દાખલ કરો.';
      } else if (e.code == 'user-disabled') {
        message = 'આ એકાઉન્ટ નિષ્ક્રિય (ડીસેબલ) કરેલું છે. સોસાયટી એડમિનનો સંપર્ક કરો.';
      } else if (e.code == 'too-many-requests') {
        message = 'ઘણી બધી અસફળ કોશિશો થઈ છે. થોડી મિનિટો પછી ફરી પ્રયાસ કરો.';
      }
      emit(AuthLoginFailure(message));
    } catch (e) {
      emit(AuthLoginFailure('લૉગિન નિષ્ફળ: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _cancelFirestoreSubscriptions();
    SocietyService.instance.clear();
    SessionGuardService.instance.stopListening();
    await _firebaseAuth.signOut();
    emit(const Unauthenticated());
  }

  // ==========================================
  // HELPERS
  // ==========================================
  AuthDestination _resolveDestination({
    required User user,
    required Map<String, dynamic>? userData,
    required Map<String, dynamic>? societyData,
  }) {
    final email = (user.email ?? '').toLowerCase().trim();
    final rawRole = (userData?['role'] ?? 'member').toString().toLowerCase().trim();

    final bool isSuper = email == 'kevaladmin@gmail.com' ||
        rawRole == 'super_admin' ||
        rawRole == 'superadmin' ||
        userData?['isSuperAdmin'] == true;

    if (isSuper) return AuthDestination.superAdmin;

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

    // Check Suspension / Freeze Status
    final bool isUserActive = userData?['isActive'] != false;
    final bool isSocietyActive = societyData == null || societyData['isActive'] != false;
    final bool isAdminBlocked = societyData?['isAdminBlocked'] == true;
    final bool isSuspendedBySuperAdmin = societyData?['isSuspendedBySuperAdmin'] == true;

    if (!isSocietyActive || isAdminBlocked || isSuspendedBySuperAdmin || !isUserActive) {
      if (isAdmin) {
        return AuthDestination.adminSuspended;
      } else {
        return AuthDestination.societySuspended;
      }
    }

    if (isAdmin || isSubAdminOrCommittee) return AuthDestination.admin;
    if (isGuard) return AuthDestination.watchman;
    return AuthDestination.member;
  }

  Future<Map<String, dynamic>?> _attemptSelfHealUserDoc(User user) async {
    try {
      // 1. Check default Firestore instance by UID
      try {
        final oldDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (oldDoc.exists && oldDoc.data() != null) {
          final data = Map<String, dynamic>.from(oldDoc.data()!);
          data['uid'] = user.uid;
          await AppFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(data, SetOptions(merge: true));
          return data;
        }
      } catch (_) {}

      // 2. Search by email in AppFirestore
      final email = (user.email ?? '').trim().toLowerCase();
      if (email.isNotEmpty) {
        final q = await AppFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final existing = Map<String, dynamic>.from(q.docs.first.data());
          existing['uid'] = user.uid;
          await AppFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(existing, SetOptions(merge: true));
          return existing;
        }

        // 3. Search by email in default FirebaseFirestore
        try {
          final oldQ = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (oldQ.docs.isNotEmpty) {
            final existing = Map<String, dynamic>.from(oldQ.docs.first.data());
            existing['uid'] = user.uid;
            await AppFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(existing, SetOptions(merge: true));
            return existing;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  void _cancelFirestoreSubscriptions() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _societyDocSubscription?.cancel();
    _societyDocSubscription = null;
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    _cancelFirestoreSubscriptions();
    return super.close();
  }
}
