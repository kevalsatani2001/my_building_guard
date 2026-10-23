import 'dart:async';
import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class SocietyAppealService {
  SocietyAppealService._();
  static final SocietyAppealService instance = SocietyAppealService._();

  final FirebaseFirestore _db = AppFirestore.instance;

  /// ૧. એડમિન તરફથી સુપર એડમિનને અપીલ વિનંતી મોકલો (Submit Appeal Request)
  Future<String> submitAppeal({
    required String societyId,
    required String societyName,
    required String adminUid,
    required String adminName,
    required String adminPhone,
    required String adminEmail,
    required String message,
  }) async {
    final cleanMsg = message.trim();
    if (cleanMsg.isEmpty) {
      throw Exception("કૃપા કરીને અપીલ સંદેશો લખો.");
    }

    final appealRef = _db.collection('society_appeals').doc();
    final appealId = appealRef.id;

    // Save appeal document
    await appealRef.set({
      'appealId': appealId,
      'societyId': societyId,
      'societyName': societyName,
      'adminUid': adminUid,
      'adminName': adminName,
      'adminPhone': adminPhone,
      'adminEmail': adminEmail,
      'appealMessage': cleanMsg,
      'status': 'pending', // 'pending', 'resolved', 'rejected'
      'superAdminReply': null,
      'replyMethod': null, // 'notification', 'mail', 'whatsapp'
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'repliedAt': null,
    });

    // Send Notification to Super Admins (Topic & notifications collection)
    try {
      await _db.collection('notifications').add({
        'title': '🚨 સોસાયટી પુનઃસક્રિયતા અપીલ',
        'body': '$societyName ના એડમિન $adminName તરફથી અપીલ વિનંતી આવી છે.',
        'societyId': societyId,
        'societyName': societyName,
        'targetUID': 'SUPER_ADMIN',
        'targetTopic': kPlatformSuperAdminsTopic,
        'type': 'admin_appeal_request',
        'appealId': appealId,
        'adminUid': adminUid,
        'adminName': adminName,
        'adminPhone': adminPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'senderUid': adminUid,
        'senderRole': 'admin',
      });
    } catch (e) {
      debugPrint('Error writing super admin notification: $e');
    }

    return appealId;
  }

  /// ૨. એડમિન માટે તાજેતરની અપીલનો રીયલ-ટાઇમ સ્નેપશોટ મેળવો
  Stream<Map<String, dynamic>?> streamLatestAppealForAdmin(String societyId, String adminUid) {
    return _db
        .collection('society_appeals')
        .where('societyId', isEqualTo: societyId)
        .where('adminUid', isEqualTo: adminUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      data['docId'] = snap.docs.first.id;
      return data;
    });
  }

  /// ૩. સુપર એડમિન માટે તમામ અપીલ વિનંતીઓનો પ્રવાહ (Stream all appeals for Super Admin)
  Stream<List<Map<String, dynamic>>> streamAllAppeals() {
    return _db
        .collection('society_appeals')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['docId'] = d.id;
        return data;
      }).toList();
    });
  }

  /// ૪. ચોક્કસ અપીલ વિગતનો સિંગલ સ્નેપશોટ
  Stream<Map<String, dynamic>?> streamAppealById(String appealId) {
    return _db.collection('society_appeals').doc(appealId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['docId'] = doc.id;
      return data;
    });
  }

  /// ૫. સુપર એડમિનનો પ્રત્યુત્તર (Reply to Appeal with unblock options)
  Future<void> replyToAppeal({
    required String appealId,
    required String societyId,
    required String adminUid,
    required String replyMessage,
    required String replyStatus, // 'resolved', 'rejected', 'pending_info'
    required String replyMethod, // 'notification', 'mail', 'whatsapp'
    bool unblockSociety = false,
  }) async {
    final currentSuperAdminUid = FirebaseAuth.instance.currentUser?.uid ?? 'super_admin';

    // ૧. અપીલ ડોક્યુમેન્ટ અપડેટ
    await _db.collection('society_appeals').doc(appealId).update({
      'status': replyStatus,
      'superAdminReply': replyMessage.trim(),
      'replyMethod': replyMethod,
      'repliedAt': FieldValue.serverTimestamp(),
      'resolvedByUid': currentSuperAdminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ૨. જો સોસાયટી અને એડમિન અનબ્લોક કરવાનો વિકલ્પ પસંદ કર્યો હોય:
    if (unblockSociety) {
      await _db.collection('society_settings').doc(societyId).set({
        'isActive': true,
        'isAdminBlocked': false,
        'unblockedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (adminUid.isNotEmpty) {
        await _db.collection('users').doc(adminUid).set({
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    // ૩. જો રિપ્લાય પદ્ધતિ 'notification' હોય, તો એડમિનને પુશ નોટિફિકેશન મોકલો
    if (replyMethod == 'notification') {
      await _db.collection('notifications').add({
        'title': unblockSociety
            ? '✅ સોસાયટી પુનઃસક્રિય કરાઈ'
            : '📢 સુપર એડમિન / હેડ ઓફિસ તરફથી જવાબ',
        'body': replyMessage.trim(),
        'societyId': societyId,
        'targetUID': adminUid,
        'type': 'super_admin_appeal_reply',
        'appealId': appealId,
        'status': replyStatus,
        'isUnblocked': unblockSociety,
        'createdAt': FieldValue.serverTimestamp(),
        'senderUid': currentSuperAdminUid,
        'senderRole': 'super_admin',
      });
    }
  }
}
