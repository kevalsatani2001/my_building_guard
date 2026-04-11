import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Topic used by Cloud Functions when [targetUID] is `ALL`.
const String kSocietyMembersTopic = 'society_members';

/// Must match AndroidManifest default_notification_channel_id and Cloud Function `channelId`.
const String kAndroidNotificationChannelId = 'high_importance_channel';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  Timer? _pushSyncDebounce;

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    kAndroidNotificationChannelId,
    'Society notifications',
    description: 'Alerts, visitors, and broadcasts',
    importance: Importance.max,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    await _requestFcmPermissionAndPresentation();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    _fcm.getInitialMessage().then(_onInitialMessage);

    _tokenRefreshSub = _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    _authSub = FirebaseAuth.instance.authStateChanges().listen(_schedulePushSyncDebounced);
    _schedulePushSyncDebounced(FirebaseAuth.instance.currentUser);
  }

  /// હોમ સ્ક્રીન ખુલે ત્યારે ફોનમાં `fcmToken` તાજો રાખો — ગેટ એલર્ટ માટે જરૂરી.
  Future<void> ensureTokenRegistered() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ensureTokenRegistered: $e');
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    } catch (e) {
      if (kDebugMode) debugPrint('ensureTokenRegistered retry: $e');
    }
  }

  Future<void> dispose() async {
    _pushSyncDebounce?.cancel();
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
  }

  /// Batches rapid auth updates; avoids overlapping FCM I/O on startup/login.
  void _schedulePushSyncDebounced(User? user) {
    _pushSyncDebounce?.cancel();
    _pushSyncDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_syncPushForUser(user));
    });
  }

  Duration get _playServicesWarmupDelay {
    if (kIsWeb) return Duration.zero;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const Duration(seconds: 2);
    }
    return const Duration(milliseconds: 500);
  }

  Future<void> _withRetries(Future<void> Function() action, {String label = 'FCM'}) async {
    const backoff = <Duration>[
      Duration.zero,
      Duration(seconds: 3),
      Duration(seconds: 8),
      Duration(seconds: 20),
    ];
    Object? lastError;
    for (var i = 0; i < backoff.length; i++) {
      if (backoff[i] > Duration.zero) {
        await Future<void>.delayed(backoff[i]);
      }
      try {
        await action();
        return;
      } catch (e, st) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('$label attempt ${i + 1}/${backoff.length} failed: $e');
          debugPrint('$st');
        }
      }
    }
    if (kDebugMode && lastError != null) {
      debugPrint('$label: giving up after retries ($lastError). Direct token messages may still work; topic broadcast may be delayed until next app open.');
    }
  }

  Future<void> _syncPushForUser(User? user) async {
    if (user == null) {
      await _withRetries(
        () => _fcm.unsubscribeFromTopic(kSocietyMembersTopic),
        label: 'FCM unsubscribe',
      );
      return;
    }

    await Future<void>.delayed(_playServicesWarmupDelay);

    await _withRetries(
      () => _fcm.subscribeToTopic(kSocietyMembersTopic),
      label: 'FCM subscribe topic',
    );

    await _withRetries(() async {
      final token = await _fcm.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    }, label: 'FCM getToken');
  }

  Future<void> _setupLocalNotifications() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestFcmPermissionAndPresentation() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('FCM save token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    }
    final notification = message.notification;
    if (notification == null) return;

    if (_useLocalNotificationInForeground) {
      _showLocalNotification(message);
    }
  }

  bool get _useLocalNotificationInForeground {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;
    final id = message.messageId?.hashCode ?? notification.hashCode;

    final NotificationDetails details;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            kAndroidNotificationChannelId,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
        );
        break;
      case TargetPlatform.windows:
        details = const NotificationDetails(windows: WindowsNotificationDetails());
        break;
      case TargetPlatform.linux:
        details = const NotificationDetails(linux: LinuxNotificationDetails());
        break;
      default:
        return;
    }

    try {
      await _local.show(
        id: id,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Local notification show: $e');
    }
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    if (kDebugMode && response.payload != null) {
      debugPrint('Local notification tap payload: ${response.payload}');
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM opened from background: ${message.notification?.title}');
    }
  }

  void _onInitialMessage(RemoteMessage? message) {
    if (message == null) return;
    if (kDebugMode) {
      debugPrint('FCM opened from terminated: ${message.notification?.title}');
    }
  }
}
