import 'dart:async';
import 'package:building_guard/core/app_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/maintenance_model.dart';
import '../screens/admin_complaints_screen.dart';
import '../screens/admin_maintenance_screen.dart';
import '../screens/member_complaint_register_screen.dart';
import '../screens/watchmen_screen.dart';
import '../widgets/member_maintenance_sheet.dart';
import '../screens/super_admin/super_admin_appeal_detail_screen.dart';
import 'session_guard_service.dart';

/// સેન્ટ્રલ નોટિફિકેશન નેવિગેશન રાઉટર
/// FCM પુશ, લોકલ નોટિફિકેશન અથવા ઇન-એપ નોટિફિકેશન પર ટેપ કરતા જ યોગ્ય સેક્શન/સ્ક્રીન પર રીડાયરેક્ટ કરે છે.
class NotificationNavigationService {
  NotificationNavigationService._();
  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  static Map<String, dynamic>? pendingColdStartData;

  /// નોટિફિકેશન ડેટા આધારિત ડીપ-લિંક નેવિગેશન એક્ઝિક્યુટ કરો
  static Future<void> handleNotificationData(
    Map<String, dynamic> rawData, {
    BuildContext? fallbackContext,
  }) async {
    final type = (rawData['type'] ?? '').toString().trim();
    final billId = (rawData['billId'] ?? '').toString().trim();
    final receiptNumber = (rawData['receiptNumber'] ?? '').toString().trim();
    final complaintId = (rawData['complaintId'] ?? '').toString().trim();
    final visitorId = (rawData['visitorId'] ?? '').toString().trim();
    final title = (rawData['title'] ?? '').toString().trim();
    final body = (rawData['body'] ?? '').toString().trim();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      pendingColdStartData = rawData;
      return;
    }

    String role = 'member';
    try {
      final uDoc = await AppFirestore.instance.collection('users').doc(user.uid).get();
      role = (uDoc.data()?['role'] ?? 'member').toString().trim();
    } catch (_) {}

    if (kDebugMode) {
      debugPrint('NotificationNavigation: Handling type=$type, billId=$billId, role=$role');
    }

    switch (type) {
      // ૧. મેન્ટેનન્સ રસીદ / પેમેન્ટ સફળતાપૂર્વક ચૂકવાયું
      case 'maintenance_receipt':
      case 'maintenance_payment':
      case 'maintenance_paid':
        await _handleMaintenanceReceipt(user.uid, role, billId, receiptNumber);
        break;

      // ૨. મેન્ટેનન્સ બાકી રકમ યાદી / નવું બિલ
      case 'maintenance_due_reminder':
      case 'maintenance_reminder':
      case 'maintenance_bill':
        await _handleMaintenanceReminder(user.uid, role, billId);
        break;

      // ૩. ફરિયાદ / ગ્રીવન્સ
      case 'complaint':
      case 'complaint_status':
      case 'complaint_reply':
        _handleComplaint(role, complaintId);
        break;

      // ૪. વિઝિટર એન્ટ્રી / અપ્રુવલ
      case 'visitor_alert':
      case 'visitor_entry':
      case 'visitor_approval':
      case 'visitor_status':
        _handleVisitor(role, visitorId);
        break;

      // ૫. પાર્કિંગ સ્લોટ એલર્ટ (રોંગ પાર્કિંગ)
      case 'parking_alert':
      case 'parking_wrong_slot':
        _handleParkingAlert(title, body);
        break;

      // ૬. SOS / ઇમરજન્સી એલર્ટ (ગેટ કે વોચમેન તરફથી)
      case 'sos':
      case 'emergency':
        _handleSosAlert(title, body);
        break;

      // ૭. સુપર એડમિન / પ્લેટફોર્મ હેડ ઓફિસ નોટિસ
      case 'super_admin_notice':
        _handleSuperAdminNotice(title, body);
        break;

      // ૮. સુપર એડમિન માટે સોસાયટી અપીલ વિનંતી
      case 'admin_appeal_request':
      case 'society_appeal':
        _handleAdminAppealRequest(rawData['appealId']?.toString() ?? '');
        break;

      // ૯. એડમિન માટે સુપર એડમિન તરફથી અપીલ રિપ્લાય
      case 'super_admin_appeal_reply':
        _handleSuperAdminAppealReply(title, body);
        break;

      // ૧૦. સોસાયટી નોટિસ / સામાન્ય બ્રોડકાસ્ટ
      case 'admin_notice':
      case 'general':
      case 'notice':
      case 'broadcast':
      default:
        _handleGeneralNotice(title, body);
        break;
    }
  }

  /// એપ કોલ્ડ સ્ટાર્ટ પર બાકી રહેલ નોટિફિકેશન ચેક કરી નેવિગેટ કરે છે
  static void checkAndHandlePendingColdStart(BuildContext context) {
    if (pendingColdStartData != null) {
      final data = pendingColdStartData!;
      pendingColdStartData = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationData(data, fallbackContext: context);
      });
    }
  }

  // --- હેન્ડલર્સ ---

  /// ૧. મેન્ટેનન્સ રસીદ વિભાગ પર રીડાયરેક્ટ
  static Future<void> _handleMaintenanceReceipt(
    String userId,
    String role,
    String billId,
    String receiptNumber,
  ) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (role == 'admin') {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
      );
      return;
    }

    // મેમ્બર માટે સીધી ડિજિટલ રસીદ અથવા પોર્ટલનો હિસ્ટ્રી/રસીદ વિભાગ ખોલો
    MaintenanceBill? bill;
    if (billId.isNotEmpty) {
      try {
        final bDoc = await AppFirestore.instance
            .collection('maintenance_bills')
            .doc(billId)
            .get();
        if (bDoc.exists) {
          bill = MaintenanceBill.fromFirestore(bDoc);
        }
      } catch (e) {
        debugPrint('Fetch bill error: $e');
      }
    }

    final currentCtx = rootNavigatorKey.currentContext;
    if (currentCtx == null || !currentCtx.mounted) return;

    if (bill != null && bill.status == MaintenanceStatus.paid) {
      // ૧-ટેપ સીધી ડિજિટલ રસીદ મોડલ શીટ ખોલો
      MemberMaintenanceSheet.showReceiptDialog(currentCtx, bill);
    } else {
      // મેન્ટેનન્સ પોર્ટલ ખોલો (જે સીધા રસીદ હિસ્ટ્રી ટેબ પર ખુલશે)
      await MemberMaintenanceSheet.showMaintenancePortal(
        currentCtx,
        currentUserId: userId,
        initialBill: bill,
      );
    }
  }

  /// ૨. મેન્ટેનન્સ પેમેન્ટ પોર્ટલ (Pay Tab) પર રીડાયરેક્ટ
  static Future<void> _handleMaintenanceReminder(
    String userId,
    String role,
    String billId,
  ) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (role == 'admin') {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
      );
      return;
    }

    MaintenanceBill? bill;
    if (billId.isNotEmpty) {
      try {
        final bDoc = await AppFirestore.instance
            .collection('maintenance_bills')
            .doc(billId)
            .get();
        if (bDoc.exists) {
          bill = MaintenanceBill.fromFirestore(bDoc);
        }
      } catch (_) {}
    }

    final currentCtx = rootNavigatorKey.currentContext;
    if (currentCtx == null || !currentCtx.mounted) return;

    await MemberMaintenanceSheet.showMaintenancePortal(
      currentCtx,
      currentUserId: userId,
      initialBill: bill,
    );
  }

  /// ૩. ફરિયાદ સ્ક્રીન પર રીડાયરેક્ટ
  static void _handleComplaint(String role, String complaintId) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (role == 'admin') {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()),
      );
    } else {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const MemberComplaintRegisterScreen()),
      );
    }
  }

  /// ૪. વિઝિટર સેક્શન પર રીડાયરેક્ટ
  static void _handleVisitor(String role, String visitorId) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (role == 'watchman') {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const WatchmanScreen()),
      );
    }
  }

  /// ૫. જનરલ નોટિસ ડાયલોગ
  static void _handleGeneralNotice(String title, String body) {
    if (title.isEmpty && body.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF4338CA), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : 'સોસાયટી સૂચના',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('સમજાઈ ગયું'),
          ),
        ],
      ),
    );
  }

  /// ૫. પાર્કિંગ સ્લોટ એલર્ટ ડાયલોગ (મેમ્બર-ટુ-મેમ્બર)
  static void _handleParkingAlert(String title, String body) {
    if (title.isEmpty && body.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.car_crash_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : 'પાર્કિંગ સ્લોટ એલર્ટ',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogCtx),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('હું ગાડી હટાવી લઉં છું'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// ૬. SOS ઇમરજન્સી એલર્ટ ડાયલોગ (ગેટ / વોચમેન તરફથી તાત્કાલિક મદદ)
  static void _handleSosAlert(String title, String body) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFEF2F2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : '🚨 ગેટ ઇમરજન્સી SOS એલર્ટ!',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body.isNotEmpty ? body : 'ગેટ પર સુરક્ષા સહાયતાની તાત્કાલિક જરૂર છે.',
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'વોચમેન અથવા સિક્યોરિટી કેબિનનો તાત્કાલિક સંપર્ક કરો.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogCtx),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('મેં એલર્ટ જોયો (Dismiss)'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// ૭. સુપર એડમિન / હેડ ઓફિસ સત્તાવાર નોટિસ ડાયલોગ
  static void _handleSuperAdminNotice(String title, String body) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'સત્તાવાર હેડ ઓફિસ નોટિસ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    title.isNotEmpty ? title : 'સુપર એડમિન સૂચના',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                body.isNotEmpty ? body : 'હેડ ઓફિસ તરફથી અગત્યની સૂચના આપવામાં આવી છે.',
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF0C4A6E)),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('સમજાઈ ગયું (Acknowledge)'),
          ),
        ],
      ),
    );
  }

  /// ૮. સુપર એડમિન માટે સોસાયટી અપીલ વિનંતી સ્ક્રીન ખોલો
  static void _handleAdminAppealRequest(String appealId) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted || appealId.isEmpty) return;
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => SuperAdminAppealDetailScreen(appealId: appealId),
      ),
    );
  }

  /// ૯. એડમિન માટે સુપર એડમિન તરફથી અપીલ રિપ્લાય દર્શાવો
  static void _handleSuperAdminAppealReply(String title, String body) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : 'સુપર એડમિન તરફથી જવાબ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            body.isNotEmpty ? body : 'તમારી સોસાયટીની અપીલ અંગે સુપર એડમિન દ્વારા પ્રત્યુત્તર આપવામાં આવ્યો છે.',
            style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('સમજાઈ ગયું (OK)'),
          ),
        ],
      ),
    );
  }
}
