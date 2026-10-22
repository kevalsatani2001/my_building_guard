import 'dart:math';
import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/amenity_model.dart';
import 'firebase_app_guard.dart';
import 'society_service.dart';

class AmenityBookingService {
  AmenityBookingService._();
  static final AmenityBookingService instance = AmenityBookingService._();

  FirebaseFirestore get _firestore => AppFirestore.instance;
  String get _currentSocietyId => SocietyService.instance.societyId;
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _amenitiesRef =>
      _firestore.collection('societies').doc(_currentSocietyId).collection('amenities');

  CollectionReference get _bookingsRef =>
      _firestore.collection('societies').doc(_currentSocietyId).collection('amenity_bookings');

  /// ૧. શું આ સોસાયટીમાં એમેનિટીઝ / વાડી / ક્લબહાઉસ સુવિધા સક્ષમ (Enabled) છે?
  Future<bool> checkHasAmenitiesEnabled() async {
    final societyId = _currentSocietyId;
    if (societyId.isEmpty) return false;

    try {
      final doc = await _firestore.collection('society_settings').doc(societyId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['hasAmenities'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// લાઈવ સ્ટ્રીમ જેથી જ્યારે પણ એડમિન એમેનિટીઝ ઓન/ઓફ કરે ત્યારે UI તાત્કાલિક અપડેટ થાય
  Stream<bool> hasAmenitiesStream() {
    final societyId = _currentSocietyId;
    return _firestore
        .collection('society_settings')
        .doc(societyId)
        .snapshots()
        .map((doc) => doc.data()?['hasAmenities'] == true);
  }

  /// એડમિન દ્વારા એમેનિટીઝ મોડ્યુલ ON / OFF કરવું
  Future<void> toggleHasAmenities(bool enabled) async {
    final societyId = _currentSocietyId;
    await _firestore.collection('society_settings').doc(societyId).set({
      'hasAmenities': enabled,
    }, SetOptions(merge: true));
  }

  /// ૨. ઉપલબ્ધ સક્રિય એમેનિટીઝ લિસ્ટ લાવો
  Stream<List<AmenityModel>> getActiveAmenitiesStream() {
    return _amenitiesRef.where('isActive', isEqualTo: true).snapshots().map((snap) {
      return snap.docs.map((d) => AmenityModel.fromFirestore(d)).toList();
    });
  }

  Stream<List<AmenityModel>> getAllAmenitiesAdminStream() {
    return _amenitiesRef.snapshots().map((snap) {
      return snap.docs.map((d) => AmenityModel.fromFirestore(d)).toList();
    });
  }

  /// નવી એમેનિટી ઉમેરવી અથવા એડિટ કરવી
  Future<void> saveAmenity({
    String? id,
    required String name,
    required String category,
    required int capacity,
    required String description,
    required bool isPaid,
    required double rentAmount,
    required double securityDeposit,
    required String slotType,
    required List<String> availableSlots,
    required String rulesAndTerms,
    bool isActive = true,
  }) async {
    final societyId = _currentSocietyId;

    final data = {
      'societyId': societyId,
      'name': name.trim(),
      'category': category,
      'capacity': capacity,
      'description': description.trim(),
      'isPaid': isPaid,
      'rentAmount': isPaid ? rentAmount : 0.0,
      'securityDeposit': isPaid ? securityDeposit : 0.0,
      'slotType': slotType,
      'availableSlots': availableSlots,
      'rulesAndTerms': rulesAndTerms.trim(),
      'isActive': isActive,
      'requiresAdminApproval': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id != null && id.isNotEmpty) {
      await _amenitiesRef.doc(id).set(data, SetOptions(merge: true));
    } else {
      await _amenitiesRef.add(data);
    }
  }

  Future<void> deleteAmenity(String id) async {
    await _amenitiesRef.doc(id).delete();
  }

  /// ૩. સભ્ય દ્વારા બુકિંગ રિક્વેસ્ટ સબમિટ કરવી
  Future<String> submitBookingRequest({
    required AmenityModel amenity,
    required DateTime bookingDate, // YYYY-MM-DD
    required String slotName,
    required String purpose,
    required int expectedGuests,
    required String memberName,
    required String memberPhone,
    required String unitDisplay,
  }) async {
    final societyId = _currentSocietyId;
    final uid = _currentUserId ?? '';

    // ૧. ડુપ્લિકેટ બુકિંગ ચેક કરો (શું આ તારીખ અને સ્લોટ પર પહેલેથી એપ્રુવ થયેલ બુકિંગ છે?)
    final normalizedDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
    final existingSnap = await _bookingsRef
        .where('amenityId', isEqualTo: amenity.id)
        .where('bookingDate', isEqualTo: Timestamp.fromDate(normalizedDate))
        .where('status', isEqualTo: 'approved')
        .get();

    for (final doc in existingSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final bookedSlot = (d['slotName'] ?? '').toString();
      if (bookedSlot == slotName || slotName.contains('Full Day') || bookedSlot.contains('Full Day')) {
        throw Exception('આ તારીખ અને સ્લોટ પર ${amenity.name} પહેલેથી બુક થયેલ છે.');
      }
    }

    // ૨. ૬-આંકડાનો યુનિક ગેસ્ટ ગેટ પાસકોડ જનરેટ કરો
    final eventPassCode = (100000 + Random().nextInt(900000)).toString();

    final docRef = await _bookingsRef.add({
      'societyId': societyId,
      'amenityId': amenity.id,
      'amenityName': amenity.name,
      'memberUid': uid,
      'memberName': memberName.trim(),
      'memberPhone': memberPhone.trim(),
      'unitDisplay': unitDisplay.trim(),
      'bookingDate': Timestamp.fromDate(normalizedDate),
      'slotName': slotName.trim(),
      'purpose': purpose.trim(),
      'expectedGuests': expectedGuests,
      'status': 'pending',
      'rentAmount': amenity.rentAmount,
      'securityDeposit': amenity.securityDeposit,
      'depositStatus': 'pending',
      'eventPassCode': eventPassCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify admins
    _notifyAdminsNewBooking(
      bookingId: docRef.id,
      amenityName: amenity.name,
      unitDisplay: unitDisplay,
      dateStr: '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
    );

    return docRef.id;
  }

  Future<void> _notifyAdminsNewBooking({
    required String bookingId,
    required String amenityName,
    required String unitDisplay,
    required String dateStr,
  }) async {
    try {
      final societyId = _currentSocietyId;

      await _firestore.collection('notifications').add({
        'title': '🏛️ નવું એમેનિટી બુકિંગ',
        'body': 'ફ્લેટ $unitDisplay એ $dateStr માટે $amenityName બુકિંગની મંજૂરી માંગી છે.',
        'societyId': societyId,
        'type': 'new_amenity_booking',
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: 'us-central1',
      );
      final callable = functions.httpsCallable(
        'sendTopicAlertPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      await callable.call<Map<String, dynamic>>({
        'topicKind': 'admins',
        'title': '🏛️ નવું એમેનિટી બુકિંગ',
        'body': 'ફ્લેટ $unitDisplay એ $dateStr માટે $amenityName બુકિંગની મંજૂરી માંગી છે.',
        'type': 'new_amenity_booking',
      });
    } catch (e) {
      debugPrint('Error notifying admins for booking: $e');
    }
  }

  /// ૪. એડમિન દ્વારા બુકિંગ મંજૂર (Approve) કે અસ્વીકાર (Reject) કરવું
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status, // 'approved', 'rejected', 'cancelled'
    String? adminRemarks,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      if (adminRemarks != null && adminRemarks.trim().isNotEmpty)
        'adminRemarks': adminRemarks.trim(),
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'approved') 'depositStatus': 'held',
    };

    await _bookingsRef.doc(bookingId).update(updateData);

    // If approved, notify member with gate pass code
    if (status == 'approved') {
      try {
        final doc = await _bookingsRef.doc(bookingId).get();
        final d = doc.data() as Map<String, dynamic>?;
        final memberUid = d?['memberUid']?.toString();
        final amenityName = d?['amenityName']?.toString() ?? 'હોલ';
        final passCode = d?['eventPassCode']?.toString() ?? '';

        if (memberUid != null && memberUid.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'title': '🎉 એમેનિટી બુકિંગ મંજૂર થયું!',
            'body': '$amenityName નું બુકિંગ મંજૂર થયું છે. આપનો મહેમાન ગેટ પાસકોડ છે: $passCode',
            'targetUID': memberUid,
            'societyId': _currentSocietyId,
            'type': 'amenity_booking_approved',
            'bookingId': bookingId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }
  }

  /// ૫. ઇવેન્ટ પછી સબ-એડમિન / કમિટી દ્વારા ડિપોઝિટ નિરીક્ષણ & રીફંડ નોંધ
  Future<void> updateDepositInspection({
    required String bookingId,
    required String depositStatus, // 'refunded', 'held', 'deducted'
    required String inspectionNotes,
  }) async {
    await _bookingsRef.doc(bookingId).update({
      'depositStatus': depositStatus,
      'inspectionNotes': inspectionNotes.trim(),
      'inspectedByUid': _currentUserId,
      'inspectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ૬. ગેટ વોચમેન માટે "આજની ઇવેન્ટ્સ" લાઈવ સ્ટ્રીમ
  Stream<List<AmenityBookingModel>> getTodayEventsStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _bookingsRef
        .where('status', isEqualTo: 'approved')
        .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
        .snapshots()
        .map((snap) => snap.docs.map((d) => AmenityBookingModel.fromFirestore(d)).toList());
  }

  /// ૭. સભ્યના પોતાના બુકિંગ્સ
  Stream<List<AmenityBookingModel>> getMemberBookingsStream(String memberUid) {
    return _bookingsRef
        .where('memberUid', isEqualTo: memberUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AmenityBookingModel.fromFirestore(d)).toList());
  }

  /// ૮. એડમિન માટે તમામ બુકિંગ્સ
  Stream<List<AmenityBookingModel>> getAllBookingsAdminStream() {
    return _bookingsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AmenityBookingModel.fromFirestore(d)).toList());
  }
}
