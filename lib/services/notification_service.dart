import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'society_service.dart';

/// ડિફૉલ્ટ સોસાયટી ટોપિક (અન્ય સોસાયટી માટે [SocietyService.topicMembers] વાપરો).
const String kSocietyMembersTopic = 'society_members';
const String kSocietyAdminsTopic = 'society_admins';
const String kSocietyWatchmenTopic = 'society_watchmen';

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

  /// લોગઆઉટ / સોસાયટી બદલાવ પર અનસબસ્ક્રાઇબ માટે.
  final List<String> _subscribedTopics = [];

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

  /// ડેશબોર્ડ ખુલે ત્યારે ટોકન Firestoreમાં સેવ કરો અને **સાચા FCM ટોપિક** પર સબસ્ક્રાઇબ રહો.
  ///
  /// ફક્ત `getToken` નહીં — `society_members` vs `soc_xxx_members` મેળ ખાય તે જરૂરી છે,
  /// નહીંતર મોકલનારને “મોકલાયું” લાગે પણ મેળવનારને પુશ મળતું નથી.
  Future<void> ensureTokenRegistered() async {
    await _syncPushForUser(FirebaseAuth.instance.currentUser);
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

  Future<void> _unsubscribeTrackedTopics() async {
    for (final t in List<String>.from(_subscribedTopics)) {
      await _withRetries(
        () => _fcm.unsubscribeFromTopic(t),
        label: 'FCM unsubscribe $t',
      );
    }
    _subscribedTopics.clear();
  }

  Future<void> _syncPushForUser(User? user) async {
    await _unsubscribeTrackedTopics();

    if (user == null) {
      return;
    }

    await Future<void>.delayed(_playServicesWarmupDelay);

    String? role;
    String? societyId;
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final d = snap.data();
      role = d?['role'] as String?;
      societyId = d?['societyId'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM read role: $e');
    }
    SocietyService.instance.bindFromUserMap(
      societyId != null ? {'societyId': societyId} : null,
    );

    final tMembers = SocietyService.instance.topicMembers;
    final tAdmins = SocietyService.instance.topicAdmins;
    final tWatch = SocietyService.instance.topicWatchmen;

    await _withRetries(
      () => _fcm.subscribeToTopic(tMembers),
      label: 'FCM subscribe members topic',
    );
    _subscribedTopics.add(tMembers);

    if (role == 'admin') {
      await _withRetries(
        () => _fcm.subscribeToTopic(tAdmins),
        label: 'FCM subscribe admins topic',
      );
      _subscribedTopics.add(tAdmins);
    }

    if (role == 'watchman') {
      await _withRetries(
        () => _fcm.subscribeToTopic(tWatch),
        label: 'FCM subscribe watchmen topic',
      );
      _subscribedTopics.add(tWatch);
    }

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
    // Android 13+ (API 33): POST_NOTIFICATIONS વગર સિસ્ટમ ટ્રેમાં FCM દેખાતું નથી.
    await androidPlugin?.requestNotificationsPermission();
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
      debugPrint(
        'FCM foreground: notif.title=${message.notification?.title} data=${message.data}',
      );
    }
    if (!_useLocalNotificationInForeground) return;
    unawaited(_showLocalNotification(message));
  }

  /// Android ફોરગ્રાઉન્ડમાં [RemoteMessage.notification] ઘણી વખત ખાલી આવે છે — `data` માંથી શીર્ષક/સંદેશ.
  ({String title, String body})? _fcmTitleBody(RemoteMessage message) {
    final n = message.notification;
    final nt = n?.title?.trim() ?? '';
    final nb = n?.body?.trim() ?? '';
    if (nt.isNotEmpty && nb.isNotEmpty) {
      return (title: nt, body: nb);
    }
    final dt = message.data['title']?.toString().trim() ?? '';
    final db = message.data['body']?.toString().trim() ?? '';
    if (dt.isNotEmpty && db.isNotEmpty) {
      return (title: dt, body: db);
    }
    return null;
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
    final parsed = _fcmTitleBody(message);
    if (parsed == null) {
      if (kDebugMode) {
        debugPrint('FCM: શીર્ષક/સંદેશ ન મળ્યો (notification અથવા data.title/body)');
      }
      return;
    }

    final notification = message.notification;
    final android = notification?.android;
    final id = message.messageId?.hashCode ?? '${parsed.title}${parsed.body}'.hashCode;

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
        title: parsed.title,
        body: parsed.body,
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

/// `notifications` ડોક પર Cloud Function [fcmDeliveryStatus] લખ્યા પછી યુઝરને સમજાવવા.
String fcmDeliverySummaryForUser(Map<String, dynamic>? doc) {
  final status = doc?['fcmDeliveryStatus'] as String?;
  final err = doc?['fcmError'] as String?;
  if (status == null || status.isEmpty) {
    if (kReleaseMode) {
      return 'પુશની પુષ્ટિ મળી નહીં. સામાન્ય રીતે Firebase પર Functions ડિપ્લોય થયેલા નથી અથવા સર્વર ધીમો છે — એડમિન/ડેવલપરને તપાસ કરાવો. મેમ્બર એપ ખોલી નોટિફિકેશન પરવાનગી આપે તે પણ જરૂરી છે.';
    }
    return 'સર્વર પુશની પુષ્ટિ મળી નહીં — Cloud Function `sendNotification` ચાલતું હોવું જોઈએ. ટર્મિનલ: firebase deploy --only functions';
  }
  switch (status) {
    case 'sent_token':
      return 'મેમ્બરના ફોન પર પુશ મોકલાયો (FCM સ્વીકાર્યું). સ્ક્રીન પર ન દેખાય તો ફોનની નોટિફિકેશન પરવાનગી તપાસો.';
    case 'sent_topic_members':
    case 'sent_fanout_members':
      return 'બધા મેમ્બર્સને પુશ મોકલાયો (ટોપિક અથવા સીધા ફોન ટોકન).';
    case 'sent_topic_admins':
    case 'sent_fanout_admins':
      return 'એડમિનને પુશ મોકલાયો.';
    case 'sent_topic_watchmen':
    case 'sent_fanout_watchmen':
      return 'વોચમેનને પુશ મોકલાયો.';
    case 'skipped_no_token':
      return 'મેમ્બર પાસે ફોન ટોકન નથી — એમને એપ એક વાર ખોલવા કહો.';
    case 'skipped_user_not_found':
      return 'આ યુઝર મળ્યો નથી — UID તપાસો.';
    case 'skipped_invalid':
      return 'શીર્ષક કે સંદેશ ખૂટે છે.';
    case 'error':
      return 'પુશ નિષ્ફળ: ${err ?? "અજાણી ભૂલ"}';
    default:
      return 'સ્થિતિ: $status';
  }
}

void _showFcmDeliverySnack(BuildContext ctx, Map<String, dynamic>? data) {
  if (!ctx.mounted) return;
  final st = data?['fcmDeliveryStatus'] as String?;
  if (st == null || st.isEmpty) return;
  final warn =
      st.startsWith('skipped_') || st == 'error' || st == 'skipped_invalid';
  final ok = st.startsWith('sent_');
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(fcmDeliverySummaryForUser(data)),
    backgroundColor: warn
        ? Colors.deepOrange.shade800
        : (ok ? Colors.green.shade800 : Colors.blueGrey.shade800),
    duration: const Duration(seconds: 9),
  ));
}

/// `notifications/{id}` પર Cloud Function `fcmDeliveryStatus` લખાય એટલે SnackBar.
///
/// પહેલાં ફક્ત `get()` વાપરતા કેશમાં જૂનું ડોક રહેતું અને `fcmDeliveryStatus` ક્યારેય ન દેખાતું.
/// હવે: (૧) રીયલટાઇમ `snapshots()` (૨) સાથે સર્વર `get(Source.server)` પોલ.
Future<void> pollFcmDeliveryAndShowSnackBar(
  BuildContext ctx,
  DocumentReference ref,
) async {
  await Future<void>.delayed(const Duration(seconds: 1));

  var finished = false;
  late final StreamSubscription<DocumentSnapshot> streamSub;

  void complete(Map<String, dynamic>? data) {
    if (finished || !ctx.mounted) return;
    final st = data?['fcmDeliveryStatus'] as String?;
    if (st == null || st.isEmpty) return;
    finished = true;
    streamSub.cancel();
    _showFcmDeliverySnack(ctx, data);
  }

  streamSub = ref.snapshots().listen(
    (snap) {
      final raw = snap.data();
      final data = raw is Map<String, dynamic> ? raw : null;
      complete(data);
    },
    onError: (Object e, StackTrace st) {
      if (finished || !ctx.mounted) return;
      finished = true;
      streamSub.cancel();
      final isPerm = e is FirebaseException && e.code == 'permission-denied';
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
          isPerm
              ? (kReleaseMode
                  ? 'Firestore rules: notifications ડોક વાંચી શકાતું નથી. Console માં મોકલનાર (senderId) ને read પરવાનગી આપો.'
                  : 'permission-denied reading notification: $e')
              : (kReleaseMode
                  ? 'સૂચના સ્થિતિ વાંચવામાં ભૂલ — ઇન્ટરનેટ તપાસો.'
                  : '$e'),
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 10),
      ));
    },
  );

  const maxAttempts = 30;
  for (var i = 0; i < maxAttempts && !finished; i++) {
    if (!ctx.mounted) break;
    try {
      final snap = await ref.get(const GetOptions(source: Source.server));
      final raw = snap.data();
      final data = raw is Map<String, dynamic> ? raw : null;
      complete(data);
      if (finished) break;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (!finished && ctx.mounted) {
          finished = true;
          streamSub.cancel();
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              kReleaseMode
                  ? 'Firestore rules: notifications ડોક સર્વર પરથી વાંચી શકાતું નથી — મોકલનાર user ને read કરવા દો.'
                  : e.message ?? e.code,
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 10),
          ));
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('pollFcmDelivery: get $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('pollFcmDelivery: get failed $e');
      }
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  await streamSub.cancel();

  if (!ctx.mounted || finished) return;
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(fcmDeliverySummaryForUser(null)),
    backgroundColor: Colors.amber.shade900,
    duration: const Duration(seconds: 8),
  ));
}
