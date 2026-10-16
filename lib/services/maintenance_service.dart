import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_model.dart';
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
        if (block.isNotEmpty || unit.isNotEmpty) {
          memberMap['$block-$unit'] = {
            'uid': doc.id,
            'name': (u['name'] ?? '').toString(),
            'phone': (u['phone'] ?? '').toString(),
          };
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
        if (block.isNotEmpty || unit.isNotEmpty) {
          flatsToBill.add({'block': block, 'unit': unit});
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

      final memberInfo = memberMap[key];
      final memberUid = memberInfo?['uid'];
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
        'targetUID': 'ALL',
        'societyId': _currentSocietyId,
        'type': 'maintenance_payment',
        'billId': billId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// એડમિન દ્વારા પેમેન્ટ વેરિફિકેશન અને ડિજિટલ રસીદ જનરેશન
  Future<void> approvePayment({
    required String billId,
    required MaintenanceBill bill,
  }) async {
    final receiptNo =
        'REC-${bill.billingMonth.replaceAll('-', '')}-${bill.blockName}${bill.unitNumber}';

    await _firestore.collection('maintenance_bills').doc(billId).update({
      'status': MaintenanceStatus.paid.toDbString(),
      'receiptNumber': receiptNo,
      'verifiedBy': _currentUserId ?? 'admin',
      if (bill.paidAt == null) 'paidAt': FieldValue.serverTimestamp(),
    });

    // સભ્યને પેમેન્ટ કન્ફર્મેશન એલર્ટ
    if (bill.memberId != null && bill.memberId!.isNotEmpty) {
      try {
        await _firestore.collection('notifications').add({
          'title': '✅ મેન્ટેનન્સ પેમેન્ટ મંજૂર',
          'body':
              'તમારું ${bill.billTitle} નું પેમેન્ટ મંજૂર કરવામાં આવ્યું છે. રસીદ નં: $receiptNo',
          'targetUID': bill.memberId,
          'societyId': _currentSocietyId,
          'type': 'maintenance_receipt',
          'billId': billId,
          'receiptNumber': receiptNo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
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

    await _firestore.collection('maintenance_bills').doc(billId).update({
      'status': MaintenanceStatus.paid.toDbString(),
      'paymentMode': paymentMode,
      if (chequeNumber.trim().isNotEmpty) 'chequeNumber': chequeNumber.trim(),
      if (utrNumber.trim().isNotEmpty) 'utrNumber': utrNumber.trim(),
      'receiptNumber': receiptNo,
      'note': note.trim(),
      'verifiedBy': _currentUserId ?? 'admin',
      'paidAt': FieldValue.serverTimestamp(),
    });

    if (bill.memberId != null && bill.memberId!.isNotEmpty) {
      final modeDisplay = paymentMode == 'cash'
          ? 'રોકડ'
          : (paymentMode == 'upi' ? 'UPI (QR સ્કેન)' : 'ચેક');
      try {
        await _firestore.collection('notifications').add({
          'title': '🧾 મેન્ટેનન્સ રસીદ જનરેટ થઈ',
          'body':
              '$modeDisplay દ્વારા ${bill.billTitle} સ્વીકારવામાં આવ્યું. રસીદ નં: $receiptNo',
          'targetUID': bill.memberId,
          'societyId': _currentSocietyId,
          'type': 'maintenance_receipt',
          'billId': billId,
          'receiptNumber': receiptNo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  /// ૧-ક્લિક ડ્યુ રીમાઇન્ડર એલર્ટ (પેન્ડિંગ રહેલા તમામ સભ્યોને એક સાથે મોકલવું)
  Future<int> sendDueReminders({
    required String billingMonth,
    required String billTitle,
  }) async {
    final snap = await _firestore
        .collection('maintenance_bills')
        .where('societyId', isEqualTo: _currentSocietyId)
        .where('billingMonth', isEqualTo: billingMonth)
        .where('status', isEqualTo: MaintenanceStatus.pending.toDbString())
        .get();

    int sentCount = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final memberUid = data['memberId']?.toString();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final flat = '${data['blockName'] ?? ''}-${data['unitNumber'] ?? ''}';

      if (memberUid != null && memberUid.isNotEmpty) {
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
          });
          sentCount++;
        } catch (_) {}
      }
    }

    return sentCount;
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
    if (!forceRefresh && _cachedPaymentSettings != null) {
      return _cachedPaymentSettings!;
    }
    final societyId = _currentSocietyId;
    try {
      final doc = await _firestore
          .collection('society_settings')
          .doc(societyId)
          .get()
          .timeout(const Duration(seconds: 2));
      if (doc.exists && doc.data() != null) {
        _cachedPaymentSettings = doc.data()!;
        return _cachedPaymentSettings!;
      }
    } catch (_) {}

    return cachedOrFallbackSettings;
  }

  /// સોસાયટીના પેમેન્ટ સેટિંગ્સ સેવ કરો
  Future<void> savePaymentSettings({
    required String upiId,
    required String upiPayeeName,
    required double defaultAmount,
    int dueDay = 10,
  }) async {
    final societyId = _currentSocietyId;
    final data = {
      'upiId': upiId.trim(),
      'upiPayeeName': upiPayeeName.trim(),
      'defaultAmount': defaultAmount,
      'dueDay': dueDay,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    _cachedPaymentSettings = {
      'upiId': upiId.trim(),
      'upiPayeeName': upiPayeeName.trim(),
      'defaultAmount': defaultAmount,
      'dueDay': dueDay,
    };
    try {
      await _firestore
          .collection('society_settings')
          .doc(societyId)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
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
}
