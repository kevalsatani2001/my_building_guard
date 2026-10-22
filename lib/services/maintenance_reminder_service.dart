import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/maintenance_model.dart';
import 'firebase_app_guard.dart';
import 'society_service.dart';

class MaintenanceReminderService {
  MaintenanceReminderService._();
  static final MaintenanceReminderService instance = MaintenanceReminderService._();

  FirebaseFirestore get _firestore => AppFirestore.instance;
  String get _currentSocietyId => SocietyService.instance.societyId;
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// ફોન નંબરને ઈન્ટરનેશનલ વોટ્સએપ ફોર્મેટ (૯૧ + ૧૦ આંકડા) માં ફેરવવો
  String sanitizePhoneNumber(String rawPhone) {
    String clean = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    } else if (clean.length == 11 && clean.startsWith('0')) {
      clean = '91${clean.substring(1)}';
    }
    return clean;
  }

  /// ગુજરાતી ભાષામાં સત્તાવાર અને આદરપૂર્વકનું WhatsApp રિમાઇન્ડર લખાણ
  String buildWhatsAppReminderMessage({
    required MaintenanceBill bill,
    required String societyName,
    required String upiId,
    required String upiPayeeName,
    String? customNote,
  }) {
    final memberName = bill.memberName.trim().isNotEmpty ? bill.memberName.trim() : 'સભ્ય';
    final socName = societyName.trim().isNotEmpty ? societyName.trim() : 'સોસાયટી';
    final payee = upiPayeeName.trim().isNotEmpty ? upiPayeeName.trim() : socName;
    final dueDateStr = DateFormat('dd/MM/yyyy').format(bill.dueDate);
    final amountStr = bill.totalPayable.toStringAsFixed(0);
    final unitDisplay = bill.cleanFlatDisplay;

    final upiDeepLink = upiId.isNotEmpty
        ? 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(payee)}&am=$amountStr&cu=INR&tn=${Uri.encodeComponent('$unitDisplay $socName Maintenance')}'
        : '';

    final buffer = StringBuffer();
    buffer.writeln('નમસ્તે $memberName જી 🙏,');
    buffer.writeln();
    buffer.writeln('*$socName* તરફથી નમ્ર સ્મૃતિપત્ર (મેન્ટેનન્સ રીમાઇન્ડર):');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🏠 *એકમ / ફ્લેટ:* $unitDisplay');
    buffer.writeln('📋 *વિગત:* ${bill.billTitle}');
    buffer.writeln('💰 *બાકી રકમ:* ₹ $amountStr /-');
    buffer.writeln('📅 *ચુકવણીની છેલ્લી તારીખ:* $dueDateStr');

    if (bill.penaltyAmount > 0) {
      buffer.writeln('⚠️ *વિલંબિત દંડ:* ₹ ${bill.penaltyAmount.toStringAsFixed(0)}');
    }
    if (bill.festivalCharge > 0) {
      buffer.writeln('🎉 *તહેવાર ફાળો:* ₹ ${bill.festivalCharge.toStringAsFixed(0)} (${bill.festivalName})');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (customNote != null && customNote.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 *ખાસ નોંધ:* ${customNote.trim()}');
    }

    if (upiId.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💳 *સોસાયટી UPI ID પર ચૂકવણી કરવા:*');
      buffer.writeln('`$upiId`');
      buffer.writeln('(નામ: $payee)');
      buffer.writeln();
      buffer.writeln('🔗 *તત્કાલ ૧-ટૅપ UPI ચુકવણી લિંક:*');
      buffer.writeln(upiDeepLink);
    }

    buffer.writeln();
    buffer.writeln('📲 આપ *My Building Guard* એપ ખોલીને પણ સીધા QR કોડથી પેમેન્ટ કરી તુરંત પાકી PDF રસીદ મેળવી શકો છો.');
    buffer.writeln();
    buffer.writeln('જો આપ દ્વારા આ રકમ ચૂકવાઈ ગઈ હોય, તો કૃપા કરીને આ મેસેજને અવગણશો.');
    buffer.writeln();
    buffer.writeln('આભાર સહ,');
    buffer.writeln('*મેનેજમેન્ટ કમિટી • $socName*');

    return buffer.toString();
  }

  /// સિંગલ સભ્યને WhatsApp પર રિમાઇન્ડર મોકલવું (Deep-Link)
  Future<bool> sendSingleWhatsAppReminder({
    required BuildContext context,
    required MaintenanceBill bill,
    required String societyName,
    required String upiId,
    required String upiPayeeName,
    String? customNote,
  }) async {
    final rawPhone = bill.memberPhone.trim();
    if (rawPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('આ સભ્યનો મોબાઈલ નંબર નોંધાયેલ નથી.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final cleanPhone = sanitizePhoneNumber(rawPhone);
    final message = buildWhatsAppReminderMessage(
      bill: bill,
      societyName: societyName,
      upiId: upiId,
      upiPayeeName: upiPayeeName,
      customNote: customNote,
    );

    final Uri waUri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (launched) {
        // Log to reminder history in Firestore
        await recordReminderLog(
          billId: bill.id,
          unitNumber: bill.cleanFlatDisplay,
          memberName: bill.memberName,
          phone: cleanPhone,
          channel: 'whatsapp',
          amount: bill.totalPayable,
        );
        return true;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp ખોલવામાં મુશ્કેલી આવી. કૃપા કરીને ચેક કરો કે એપ ઇન્સ્ટોલ છે.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  /// પેન્ડિંગ સભ્યને ડિરેક્ટ FCM પુશ નોટિફિકેશન મોકલવું
  Future<bool> sendDirectPushReminder({
    required MaintenanceBill bill,
    required String societyName,
  }) async {
    final societyId = _currentSocietyId;
    final memberUid = bill.memberId;
    final amountStr = bill.totalPayable.toStringAsFixed(0);
    final flat = bill.cleanFlatDisplay;

    if (memberUid == null || memberUid.isEmpty) {
      return false;
    }

    try {
      // ૧. Firestore Notification Record
      await _firestore.collection('notifications').add({
        'title': '⚠️ મેન્ટેનન્સ બિલ બાકી છે',
        'body': 'ફ્લેટ $flat નું ${bill.billTitle} (₹$amountStr) ચૂકવવાનું બાકી છે. કૃપા કરીને તાત્કાલિક UPI થી ચૂકવણી કરો.',
        'targetUID': memberUid,
        'societyId': societyId,
        'type': 'maintenance_due_reminder',
        'billId': bill.id,
        'createdAt': FieldValue.serverTimestamp(),
        'skipTriggerPush': true,
        'deliveryMode': 'direct_callable',
      });

      // ૨. Cloud Functions FCM Push
      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: 'us-central1',
      );
      final callable = functions.httpsCallable(
        'sendMemberPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final userDoc = await _firestore.collection('users').doc(memberUid).get();
      final fcmToken = userDoc.data()?['fcmToken']?.toString().trim();

      final res = await callable.call<Map<String, dynamic>>({
        'memberUid': memberUid,
        'title': '⚠️ મેન્ટેનન્સ બિલ બાકી છે',
        'body': 'ફ્લેટ $flat નું ${bill.billTitle} (₹$amountStr) ચૂકવવાનું બાકી છે. કૃપા કરીને તાત્કાલિક UPI થી ચૂકવણી કરો.',
        'type': 'maintenance_due_reminder',
        'senderUid': _currentUserId,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      });

      final isOk = res.data['ok'] == true;
      if (isOk) {
        await recordReminderLog(
          billId: bill.id,
          unitNumber: flat,
          memberName: bill.memberName,
          phone: bill.memberPhone,
          channel: 'push',
          amount: bill.totalPayable,
        );
      }
      return isOk;
    } catch (e) {
      debugPrint('sendDirectPushReminder error: $e');
      return false;
    }
  }

  /// રિમાઇન્ડર મોકલ્યાની હિસ્ટ્રી સેવ કરવી
  Future<void> recordReminderLog({
    required String billId,
    required String unitNumber,
    required String memberName,
    required String phone,
    required String channel, // 'whatsapp', 'push', 'bulk_push'
    required double amount,
  }) async {
    try {
      final societyId = _currentSocietyId;
      if (societyId.isEmpty) return;

      await _firestore
          .collection('societies')
          .doc(societyId)
          .collection('reminder_history')
          .add({
        'billId': billId,
        'unitNumber': unitNumber,
        'memberName': memberName,
        'phone': phone,
        'channel': channel,
        'amount': amount,
        'sentByUid': _currentUserId,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('recordReminderLog error: $e');
    }
  }

  /// ચોક્કસ મહિના માટે છેલ્લા રિમાઇન્ડર લોગ્સ લાવો
  Stream<QuerySnapshot> getReminderHistoryStream() {
    final societyId = _currentSocietyId;
    return _firestore
        .collection('societies')
        .doc(societyId)
        .collection('reminder_history')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
