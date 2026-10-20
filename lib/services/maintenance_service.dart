import 'dart:convert';
import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maintenance_model.dart';
import 'firebase_app_guard.dart';
import 'society_service.dart';

class MaintenanceService {
  MaintenanceService._();
  static final MaintenanceService instance = MaintenanceService._();

  FirebaseFirestore get _firestore => AppFirestore.instance;

  String get _currentSocietyId => SocietyService.instance.societyId;
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// બલ્ક બિલ જનરેશન (સોસાયટીના તમામ ફ્લેટ્સ / મેમ્બર્સ માટે એક સાથે માસિક બિલ બનાવવું)
  Future<Map<String, int>> generateBulkBills({
    required String billingMonth, // દા.ત. '2026-10'
    required String billTitle, // દા.ત. 'ઓક્ટોબર ૨૦૨૬ મેન્ટેનન્સ'
    required double amount,
    required DateTime dueDate,
    double penaltyAmount = 0.0,
    double festivalCharge = 0.0,
    String festivalName = '',
  }) async {
    final societyId = _currentSocietyId;

    // ૧. સોસાયટીના તમામ એક્ટિવ મેમ્બર્સ લાવો (જો કોઈ હોય તો)
    final Map<String, Map<String, dynamic>> memberMap = {};
    try {
      final usersSnap = await _firestore
          .collection('users')
          .where('societyId', isEqualTo: societyId)
          .where('role', isEqualTo: 'member')
          .get();
      for (final doc in usersSnap.docs) {
        final u = doc.data();
        final block = (u['blockName'] ?? '').toString();
        final unit = (u['unitNumber'] ?? '').toString();
        final cleanBlock = SocietyService.instance.logicalBlockName(block);
        final prefixedBlock = SocietyService.instance.blockFirestoreId(cleanBlock);
        if (block.isNotEmpty || unit.isNotEmpty) {
          final info = {
            'uid': doc.id,
            'name': (u['name'] ?? '').toString(),
            'phone': (u['phone'] ?? '').toString(),
          };
          memberMap['$block-$unit'] = info;
          memberMap['$cleanBlock-$unit'] = info;
          memberMap['$prefixedBlock-$unit'] = info;
          memberMap['${societyId}_$block-$unit'] = info;
        }
      }
    } catch (_) {
      // જો users ક્વેરીમાં પરમિશન ન હોય તો units થી આગળ વધવું
    }

    // ૨. સોસાયટીના તમામ રજીસ્ટર્ડ ફ્લેટ્સ (units) લાવો
    final List<Map<String, String>> flatsToBill = [];
    try {
      final unitsSnap = await _firestore
          .collection('units')
          .where('societyId', isEqualTo: societyId)
          .get();
      for (final doc in unitsSnap.docs) {
        final d = doc.data();
        final block = (d['blockName'] ?? '').toString();
        final unit = (d['unitNumber'] ?? '').toString();
        final rawMem = (d['memberId'] ?? '').toString();
        if (block.isNotEmpty || unit.isNotEmpty) {
          flatsToBill.add({
            'block': block,
            'unit': unit,
            if (rawMem.isNotEmpty) 'unitMemberId': rawMem,
          });
        }
      }
    } catch (_) {}

    // જો units કલેક્શનમાં કોઈ ફ્લેટ ન મળ્યા હોય તો મેમ્બર મેપમાંથી લોડ કરો
    if (flatsToBill.isEmpty && memberMap.isNotEmpty) {
      for (final key in memberMap.keys) {
        final parts = key.split('-');
        final block = parts.isNotEmpty ? parts[0] : '';
        final unit = parts.length > 1 ? parts[1] : '';
        flatsToBill.add({'block': block, 'unit': unit});
      }
    }

    // ૩. વર્તમાન મહિનામાં પહેલાથી બનેલા બિલ્સ ચેક કરો જેથી ડુપ્લિકેટ ન બને
    final existingBillsSnap = await _firestore
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: societyId)
        .where('billingMonth', isEqualTo: billingMonth)
        .get();

    final Set<String> alreadyBilledUnits = {};
    for (final doc in existingBillsSnap.docs) {
      final data = doc.data();
      final block = (data['blockName'] ?? '').toString();
      final unit = (data['unitNumber'] ?? '').toString();
      if (block.isNotEmpty || unit.isNotEmpty) {
        alreadyBilledUnits.add('$block-$unit');
      }
    }

    int createdCount = 0;
    int skippedCount = 0;

    WriteBatch batch = _firestore.batch();
    int batchOps = 0;

    for (final flat in flatsToBill) {
      final block = flat['block'] ?? '';
      final unit = flat['unit'] ?? '';
      final key = '$block-$unit';

      if (alreadyBilledUnits.contains(key)) {
        skippedCount++;
        continue;
      }

      final cleanB = SocietyService.instance.logicalBlockName(block);
      final prefB = SocietyService.instance.blockFirestoreId(cleanB);
      final memberInfo = memberMap[key] ??
          memberMap['$cleanB-$unit'] ??
          memberMap['$prefB-$unit'];
      final memberUid = memberInfo?['uid'] ?? flat['unitMemberId'];
      final memberName = memberInfo?['name'] ?? '';
      final memberPhone = memberInfo?['phone'] ?? '';

      final newDocRef = _firestore.collection('maintenance_bills').doc();
      final bill = MaintenanceBill(
        id: newDocRef.id,
        societyId: societyId,
        billTitle: billTitle,
        billingMonth: billingMonth,
        dueDate: dueDate,
        amount: amount,
        penaltyAmount: penaltyAmount,
        festivalCharge: festivalCharge,
        festivalName: festivalName,
        blockName: block,
        unitNumber: unit,
        memberId: memberUid,
        memberName: memberName,
        memberPhone: memberPhone,
        status: MaintenanceStatus.pending,
      );

      batch.set(newDocRef, bill.toMap());
      batchOps++;
      createdCount++;
      alreadyBilledUnits.add(key);

      // Firestore batch max 500 operations
      if (batchOps >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchOps = 0;
      }
    }

    if (batchOps > 0) {
      await batch.commit();
    }

    return {
      'created': createdCount,
      'skipped': skippedCount,
    };
  }

  /// સભ્ય દ્વારા ૧-ટેપ UPI પેમેન્ટ પૂર્ણ થયા પછી UTR / ટ્રાન્ઝેક્શન નંબર સબમિટ કરવો
  Future<void> submitUpiPayment({
    required String billId,
    required String utrNumber,
    String note = '',
  }) async {
    final docRef = _firestore.collection('maintenance_bills').doc(billId);
    await docRef.update({
      'status': MaintenanceStatus.underReview.toDbString(),
      'paymentMode': 'upi',
      'utrNumber': utrNumber.trim(),
      'note': note.trim(),
      'paidAt': FieldValue.serverTimestamp(),
    });

    // એડમિનને નોટિફિકેશન
    try {
      await _firestore.collection('notifications').add({
        'title': '💳 નવું UPI મેન્ટેનન્સ પેમેન્ટ',
        'body': 'સભ્યે UPI પેમેન્ટ કર્યું (UTR: $utrNumber). કૃપા કરીને વેરિફાય કરો.',
        'targetUID': 'ADMINS',
        'societyId': _currentSocietyId,
        'type': 'maintenance_payment',
        'billId': billId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// એડમિનનું નામ મેળવવા માટે હેલ્પર
  Future<String> _getAdminDisplayName() async {
    try {
      if (_currentUserId == null) return 'સોસાયટી એડમિન';
      final doc = await _firestore.collection('users').doc(_currentUserId).get();
      final name = (doc.data()?['name'] ?? '').toString().trim();
      return name.isNotEmpty ? '$name (એડમિન)' : 'સોસાયટી એડમિન';
    } catch (_) {
      return 'સોસાયટી એડમિન';
    }
  }

  /// એડમિન દ્વારા પેમેન્ટ વેરિફિકેશન અને ડિજિટલ રસીદ જનરેશન
  Future<void> approvePayment({
    required String billId,
    required MaintenanceBill bill,
  }) async {
    final receiptNo =
        'REC-${bill.billingMonth.replaceAll('-', '')}-${bill.blockName}${bill.unitNumber}';
    final adminName = await _getAdminDisplayName();

    await _firestore.collection('maintenance_bills').doc(billId).update({
      'status': MaintenanceStatus.paid.toDbString(),
      'receiptNumber': receiptNo,
      'verifiedBy': adminName,
      if (bill.paidAt == null) 'paidAt': FieldValue.serverTimestamp(),
    });

    // સભ્યને પેમેન્ટ કન્ફર્મેશન એલર્ટ & સીધું FCM પુશ નોટિફિકેશન
    await _sendPaymentSuccessNotification(
      billId: billId,
      bill: bill,
      receiptNo: receiptNo,
      title: '✅ મેન્ટેનન્સ પેમેન્ટ મંજૂર',
      body: 'તમારું ${bill.billTitle} નું પેમેન્ટ મંજૂર કરવામાં આવ્યું છે. રસીદ નં: $receiptNo (ટેપ કરી રસીદ જુઓ)',
    );
  }

  /// રોકડા (Cash), ચેક (Cheque) કે રૂબરૂ UPI QR સ્કેન થી પેમેન્ટ એડમિન દ્વારા માર્ક કરવું
  Future<void> recordOfflinePayment({
    required String billId,
    required MaintenanceBill bill,
    required String paymentMode, // 'cash', 'cheque', or 'upi'
    String chequeNumber = '',
    String utrNumber = '',
    String note = '',
  }) async {
    final receiptNo =
        'REC-${bill.billingMonth.replaceAll('-', '')}-${bill.blockName}${bill.unitNumber}';
    final adminName = await _getAdminDisplayName();

    await _firestore.collection('maintenance_bills').doc(billId).update({
      'status': MaintenanceStatus.paid.toDbString(),
      'paymentMode': paymentMode,
      if (chequeNumber.trim().isNotEmpty) 'chequeNumber': chequeNumber.trim(),
      if (utrNumber.trim().isNotEmpty) 'utrNumber': utrNumber.trim(),
      'receiptNumber': receiptNo,
      'note': note.trim(),
      'verifiedBy': adminName,
      'paidAt': FieldValue.serverTimestamp(),
    });

    final modeDisplay = paymentMode == 'cash'
        ? 'રોકડ'
        : (paymentMode == 'upi' ? 'UPI (QR સ્કેન)' : 'ચેક');

    // સભ્યને પેમેન્ટ સફળતાનું સીધું નોટિફિકેશન
    await _sendPaymentSuccessNotification(
      billId: billId,
      bill: bill,
      receiptNo: receiptNo,
      title: '🧾 મેન્ટેનન્સ રસીદ જનરેટ થઈ',
      body: '$modeDisplay દ્વારા ${bill.billTitle} નું પેમેન્ટ સ્વીકારાઈ ગયું છે. રસીદ નં: $receiptNo (ટેપ કરી રસીદ જુઓ)',
    );
  }

  /// સભ્યને પેમેન્ટ સફળતાનું ડિજિટલ રસીદ પુશ નોટિફિકેશન મોકલવા માટેનું હેલ્પર
  Future<void> _sendPaymentSuccessNotification({
    required String billId,
    required MaintenanceBill bill,
    required String receiptNo,
    required String title,
    required String body,
  }) async {
    var memberUid = bill.memberId?.trim();

    // જો બિલમાં memberId ન હોય, તો યુનિટ નંબર દ્વારા સભ્ય શોધો
    if (memberUid == null || memberUid.isEmpty) {
      try {
        final cleanBlock = SocietyService.instance.logicalBlockName(bill.blockName);
        final userSnap = await _firestore
            .collection('users')
            .where('societyId', isEqualTo: _currentSocietyId)
            .where('unitNumber', isEqualTo: bill.unitNumber)
            .limit(5)
            .get();
        for (final uDoc in userSnap.docs) {
          final uData = uDoc.data();
          final uBlock = (uData['blockName'] ?? '').toString();
          if (uBlock == bill.blockName || SocietyService.instance.logicalBlockName(uBlock) == cleanBlock) {
            memberUid = uDoc.id;
            await _firestore.collection('maintenance_bills').doc(billId).update({
              'memberId': memberUid,
              'memberName': (uData['name'] ?? '').toString(),
              'memberPhone': (uData['phone'] ?? '').toString(),
            });
            break;
          }
        }
      } catch (_) {}
    }

    if (memberUid != null && memberUid.isNotEmpty) {
      // ૧. Firestore માં નોટિફિકેશન હિસ્ટ્રી સેવ કરો
      try {
        await _firestore.collection('notifications').add({
          'title': title,
          'body': body,
          'targetUID': memberUid,
          'societyId': _currentSocietyId,
          'type': 'maintenance_receipt',
          'billId': billId,
          'receiptNumber': receiptNo,
          'createdAt': FieldValue.serverTimestamp(),
          'skipTriggerPush': true,
          'deliveryMode': 'direct_callable',
        });
      } catch (_) {}

      // ૨. સભ્યના ફોન પર સીધું FCM પુશ નોટિફિકેશન મોકલો
      try {
        final uDoc = await _firestore.collection('users').doc(memberUid).get();
        final fcmToken = uDoc.data()?['fcmToken']?.toString().trim();
        final app = await ensureDefaultFirebaseApp();
        final functions = FirebaseFunctions.instanceFor(
          app: app,
          region: 'us-central1',
        );
        final callable = functions.httpsCallable('sendMemberPush');
        await callable.call<Map<String, dynamic>>({
          'memberUid': memberUid,
          'title': title,
          'body': body,
          'type': 'maintenance_receipt',
          'billId': billId,
          'receiptNumber': receiptNo,
          'senderUid': _currentUserId,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        });
      } catch (e) {
        debugPrint('Direct push send error on payment success: $e');
      }
    }
  }

  /// ૧-ક્લિક ડ્યુ રીમાઇન્ડર એલર્ટ (પેન્ડિંગ રહેલા તમામ સભ્યોને એક સાથે મોકલવું)
  Future<Map<String, int>> sendDueReminders({
    required String billingMonth,
    required String billTitle,
  }) async {
    final snap = await _firestore
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: _currentSocietyId)
        .where('billingMonth', isEqualTo: billingMonth)
        .where('status', isEqualTo: MaintenanceStatus.pending.toDbString())
        .get();

    int sentNotifCount = 0;
    int sentPushCount = 0;

    // Cache user tokens and member lookup
    final Map<String, String?> tokenCache = {};

    HttpsCallable? sendMemberPushCallable;
    try {
      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: 'us-central1',
      );
      sendMemberPushCallable = functions.httpsCallable(
        'sendMemberPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
    } catch (e) {
      debugPrint('Cloud Functions init error: $e');
    }

    for (final doc in snap.docs) {
      final data = doc.data();
      var memberUid = data['memberId']?.toString();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final block = (data['blockName'] ?? '').toString();
      final unit = (data['unitNumber'] ?? '').toString();
      final flat = '$block-$unit';

      // ૧. જો બિલમાં memberId ન હોય, તો units અથવા users કલેક્શનમાંથી શોધો
      if (memberUid == null || memberUid.isEmpty) {
        try {
          final cleanBlock = SocietyService.instance.logicalBlockName(block);
          final userSnap = await _firestore
              .collection('users')
              .where('societyId', isEqualTo: _currentSocietyId)
              .where('unitNumber', isEqualTo: unit)
              .limit(5)
              .get();
          for (final uDoc in userSnap.docs) {
            final uData = uDoc.data();
            final uBlock = (uData['blockName'] ?? '').toString();
            if (uBlock == block || SocietyService.instance.logicalBlockName(uBlock) == cleanBlock) {
              memberUid = uDoc.id;
              // બિલમાં memberId કાયમી અપડેટ કરી દો
              await doc.reference.update({
                'memberId': memberUid,
                'memberName': (uData['name'] ?? '').toString(),
                'memberPhone': (uData['phone'] ?? '').toString(),
              });
              break;
            }
          }
        } catch (_) {}
      }

      if (memberUid != null && memberUid.isNotEmpty) {
        // ૨. ઇન-એપ નોટિફિકેશન સેવ કરો (skipTriggerPush: true prevents duplicate FCM from sendNotification trigger)
        try {
          await _firestore.collection('notifications').add({
            'title': '⚠️ મેન્ટેનન્સ બિલ બાકી છે',
            'body':
                'ફ્લેટ $flat નું $billTitle (₹${amount.toStringAsFixed(0)}) બાકી છે. કૃપા કરીને તાત્કાલિક UPI થી ચૂકવણી કરો.',
            'targetUID': memberUid,
            'societyId': _currentSocietyId,
            'type': 'maintenance_due_reminder',
            'billId': doc.id,
            'createdAt': FieldValue.serverTimestamp(),
            'skipTriggerPush': true,
            'deliveryMode': 'direct_callable',
          });
          sentNotifCount++;
        } catch (_) {}

        // ૩. સીધું FCM પુશ નોટિફિકેશન મોકલો (માત્ર પેન્ડિંગ સભ્યને જ સીધું ૧ પુશ)
        if (sendMemberPushCallable != null) {
          try {
            if (!tokenCache.containsKey(memberUid)) {
              final uDoc = await _firestore.collection('users').doc(memberUid).get();
              tokenCache[memberUid] = uDoc.data()?['fcmToken']?.toString().trim();
            }
            final fcmToken = tokenCache[memberUid];
            final res = await sendMemberPushCallable.call<Map<String, dynamic>>({
              'memberUid': memberUid,
              'title': '⚠️ મેન્ટેનન્સ બિલ બાકી છે',
              'body':
                  'ફ્લેટ $flat નું $billTitle (₹${amount.toStringAsFixed(0)}) બાકી છે. કૃપા કરીને તાત્કાલિક UPI થી ચૂકવણી કરો.',
              'type': 'maintenance_due_reminder',
              'senderUid': _currentUserId,
              if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
            });
            if (res.data['ok'] == true) {
              sentPushCount++;
            }
          } catch (e) {
            debugPrint('Error sending member push for $memberUid: $e');
          }
        }
      }
    }

    return {
      'notifCount': sentNotifCount,
      'pushCount': sentPushCount,
      'totalPending': snap.docs.length,
    };
  }

  Map<String, dynamic>? _cachedPaymentSettings;

  Map<String, dynamic> get cachedOrFallbackSettings => _cachedPaymentSettings ?? {
    'upiId': '',
    'upiPayeeName': '',
    'defaultAmount': 1500.0,
    'dueDay': 10,
  };

  /// સોસાયટીના પેમેન્ટ સેટિંગ્સ લાવો (UPI ID, નામ, ડિફૉલ્ટ રકમ)
  Future<Map<String, dynamic>> getPaymentSettings({bool forceRefresh = false}) async {
    final societyId = _currentSocietyId.isNotEmpty ? _currentSocietyId : SocietyService.kDefaultSocietyId;

    // ૧. જો ઇન-મેમરી કેશમાં પહેલેથી UPI ID હાજર હોય
    if (!forceRefresh && _cachedPaymentSettings != null && (_cachedPaymentSettings!['upiId']?.toString().isNotEmpty ?? false)) {
      return _cachedPaymentSettings!;
    }

    // ૨. જો ઇન-મેમરી કેશ ખાલી હોય તો SharedPreferences માંથી તરત લાવો (૦ms લેગ)
    if (_cachedPaymentSettings == null || (_cachedPaymentSettings!['upiId']?.toString().isEmpty ?? true)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('society_payment_settings_$societyId') ??
            prefs.getString('society_payment_settings_${SocietyService.kDefaultSocietyId}');
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _cachedPaymentSettings = decoded;
          }
        }
      } catch (_) {}
    }

    // ૩. ક્લાઉડ ફાયરસ્ટોરમાંથી લેટેસ્ટ સેટિંગ્સ લાવો
    try {
      final doc = await _firestore
          .collection('society_settings')
          .doc(societyId)
          .get()
          .timeout(const Duration(seconds: 6));
      if (doc.exists && doc.data() != null) {
        _cachedPaymentSettings = doc.data()!;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('society_payment_settings_$societyId', jsonEncode(_cachedPaymentSettings));
        } catch (_) {}
        return _cachedPaymentSettings!;
      }
    } catch (e) {
      debugPrint('getPaymentSettings error: $e');
    }

    return cachedOrFallbackSettings;
  }

  /// સોસાયટીના પેમેન્ટ સેટિંગ્સ સેવ કરો
  Future<void> savePaymentSettings({
    required String upiId,
    required String upiPayeeName,
    required double defaultAmount,
    int dueDay = 10,
    String? signatureBase64,
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final societyId = _currentSocietyId.isNotEmpty ? _currentSocietyId : SocietyService.kDefaultSocietyId;
    final data = <String, dynamic>{
      'upiId': upiId.trim(),
      'upiPayeeName': upiPayeeName.trim(),
      'defaultAmount': defaultAmount,
      'dueDay': dueDay,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (signatureBase64 != null) data['signatureBase64'] = signatureBase64;
    if (signatoryName != null) data['signatoryName'] = signatoryName.trim();
    if (signatoryTitle != null) data['signatoryTitle'] = signatoryTitle.trim();

    _cachedPaymentSettings = {
      ...?_cachedPaymentSettings,
      'upiId': upiId.trim(),
      'upiPayeeName': upiPayeeName.trim(),
      'defaultAmount': defaultAmount,
      'dueDay': dueDay,
    };
    if (signatureBase64 != null) {
      _cachedPaymentSettings!['signatureBase64'] = signatureBase64;
    }
    if (signatoryName != null) {
      _cachedPaymentSettings!['signatoryName'] = signatoryName.trim();
    }
    if (signatoryTitle != null) {
      _cachedPaymentSettings!['signatoryTitle'] = signatoryTitle.trim();
    }

    // સ્થાનિક સ્ટોરેજમાં સેવ કરો જેથી દર વખતે UPI ID સેટ ન કરવો પડે
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = <String, dynamic>{
        'upiId': upiId.trim(),
        'upiPayeeName': upiPayeeName.trim(),
        'defaultAmount': defaultAmount,
        'dueDay': dueDay,
      };
      if (signatureBase64 != null) localData['signatureBase64'] = signatureBase64;
      if (signatoryName != null) localData['signatoryName'] = signatoryName.trim();
      if (signatoryTitle != null) localData['signatoryTitle'] = signatoryTitle.trim();
      await prefs.setString(
        'society_payment_settings_$societyId',
        jsonEncode(localData),
      );
    } catch (_) {}

    try {
      await _firestore
          .collection('society_settings')
          .doc(societyId)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('savePaymentSettings error: $e');
    }
  }

  /// ડાયરેક્ટ UPI URI જનરેટ કરવી (Google Pay, PhonePe, Paytm, BHIM માટે)
  Uri buildUpiUri({
    required String upiId,
    required String payeeName,
    required double amount,
    required String note,
  }) {
    // Standard UPI Intent URL format
    final cleanNote = Uri.encodeComponent(note);
    final cleanName = Uri.encodeComponent(payeeName.isEmpty ? 'Society Maintenance' : payeeName);
    final amtString = amount.toStringAsFixed(2);

    final upiString =
        'upi://pay?pa=$upiId&pn=$cleanName&am=$amtString&cu=INR&tn=$cleanNote';
    return Uri.parse(upiString);
  }

  /// સોસાયટીના ફ્લેટના જે બિલ્સમાં memberId મિસિંગ હોય તેને વર્તમાન લૉગિન મેમ્બર સાથે લિંક કરવું
  Future<void> linkMemberBillsIfUnassigned({
    required String currentUserId,
    required String blockName,
    required String unitNumber,
    String memberName = '',
    String memberPhone = '',
  }) async {
    if (unitNumber.trim().isEmpty) return;
    final societyId = _currentSocietyId;
    final cleanBlock = SocietyService.instance.logicalBlockName(blockName);
    final prefixedBlock = SocietyService.instance.blockFirestoreId(cleanBlock);

    try {
      final snap = await _firestore
          .collection('maintenance_bills')
          .where('societyId', isEqualTo: societyId)
          .where('unitNumber', isEqualTo: unitNumber.trim())
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final bBlock = (data['blockName'] ?? '').toString().trim();
        final bClean = SocietyService.instance.logicalBlockName(bBlock);
        final isMatch = bBlock == blockName.trim() ||
            bClean == cleanBlock ||
            bBlock == prefixedBlock ||
            cleanBlock.isEmpty;

        if (isMatch) {
          final existingMemberId = data['memberId']?.toString().trim();
          if (existingMemberId == null || existingMemberId.isEmpty) {
            await doc.reference.update({
              'memberId': currentUserId,
              if (memberName.isNotEmpty) 'memberName': memberName,
              if (memberPhone.isNotEmpty) 'memberPhone': memberPhone,
            });
          }
        }
      }
    } catch (_) {}
  }
}

