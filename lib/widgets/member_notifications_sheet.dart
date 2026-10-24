import 'package:building_guard/core/app_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/notification_navigation_service.dart';
import '../services/society_service.dart';
import 'package:building_guard/l10n/app_strings.dart';

/// સભ્ય અને એડમિન માટે પ્રીમિયમ ઇન-એપ નોટિફિકેશન સેન્ટર બોટમ શીટ
class MemberNotificationsSheet {
  static Future<void> show(BuildContext context, {String? userBlock}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final societyId = SocietyService.instance.societyId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // સ્લીક ડ્રેગ હેન્ડલ
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // હેડર બાર
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF0F766E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'નોટિફિકેશન અને એલર્ટ્સ'.tr,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'રસીદ અને મહત્ત્વપૂર્ણ અપડેટ્સ'.tr,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // નોટિફિકેશન લિસ્ટ (રીયલટાઇમ Firestore Stream)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: AppFirestore.instance
                      .collection('notifications')
                      .where('societyId', isEqualTo: societyId)
                      .orderBy('createdAt', descending: true)
                      .limit(40)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // વર્તમાન મેમ્બર માટે ફિલ્ટર: પોતાના targetUID અથવા 'ALL' અથવા 'MEMBERS' અથવા પોતાના બ્લોકની નોટિસ
                    final uid = user.uid;
                    final notifs = snapshot.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final target = (data['targetUID'] ?? '').toString().trim();
                      final tBlock = (data['targetBlock'] ?? '').toString().trim();
                      final isMyBlock = userBlock != null &&
                          userBlock.isNotEmpty &&
                          (tBlock == userBlock || target == 'BLOCK_$userBlock');
                      return target == uid || target == 'ALL' || target == 'MEMBERS' || isMyBlock;
                    }).toList();

                    if (notifs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: notifs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = notifs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildNotificationCard(ctx, context, data, doc.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// પ્રીમિયમ નોટિફિકેશન કાર્ડ
  static Widget _buildNotificationCard(
    BuildContext sheetCtx,
    BuildContext rootCtx,
    Map<String, dynamic> data,
    String notifDocId,
  ) {
    final type = (data['type'] ?? '').toString().trim();
    final title = (data['title'] ?? 'સૂચના'.tr).toString().trim();
    final body = (data['body'] ?? '').toString().trim();
    final ts = data['createdAt'];

    DateTime? createdTime;
    if (ts is Timestamp) {
      createdTime = ts.toDate();
    }

    final isReceipt = type == 'maintenance_receipt' || type == 'maintenance_payment';
    final isReminder = type == 'maintenance_due_reminder' || type == 'maintenance_bill';
    final isSos = type == 'sos' || type == 'emergency';
    final isParking = type == 'parking_alert' || type == 'parking_wrong_slot';
    final isVisitor = type == 'visitor_alert';
    final isVisitorCheckout = type == 'visitor_checked_out';

    final Color badgeBg;
    final Color badgeBorder;
    final Color iconColor;
    final IconData icon;

    if (isReceipt) {
      badgeBg = const Color(0xFFECFDF5);
      badgeBorder = const Color(0xFFA7F3D0);
      iconColor = const Color(0xFF059669);
      icon = Icons.receipt_long_rounded;
    } else if (isReminder) {
      badgeBg = const Color(0xFFFFF1F2);
      badgeBorder = const Color(0xFFFECDD3);
      iconColor = const Color(0xFFE11D48);
      icon = Icons.account_balance_wallet_rounded;
    } else if (isSos) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFCA5A5);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.emergency_rounded;
    } else if (isParking) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      icon = Icons.car_crash_rounded;
    } else if (isVisitor || isVisitorCheckout) {
      badgeBg = const Color(0xFFF0FDFA);
      badgeBorder = const Color(0xFF99F6E4);
      iconColor = const Color(0xFF0F766E);
      icon = isVisitor ? Icons.person_pin_circle_rounded : Icons.door_sliding_rounded;
    } else {
      badgeBg = const Color(0xFFEEF2FF);
      badgeBorder = const Color(0xFFC7D2FE);
      iconColor = const Color(0xFF4338CA);
      icon = Icons.campaign_rounded;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(sheetCtx);
        NotificationNavigationService.handleNotificationData(
          data,
          fallbackContext: rootCtx,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isReceipt
              ? const Color(0xFFF0FDF4)
              : (isParking ? const Color(0xFFFFFDF5) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReceipt
                ? const Color(0xFFA7F3D0)
                : (isParking ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
            width: isReceipt || isParking ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeBorder),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (createdTime != null)
                        Text(
                          DateFormat('hh:mm a').format(createdTime),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  if (isVisitor && data['visitorDocId'] != null) ...[
                    const SizedBox(height: 10),
                    _buildVisitorActionRow(rootCtx, data, notifDocId),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (createdTime != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(createdTime),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isReceipt ? 'રસીદ જુઓ'.tr : (isVisitor ? 'વિગતો'.tr : 'ખોલો'.tr),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded, size: 9, color: iconColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildVisitorActionRow(
    BuildContext rootCtx,
    Map<String, dynamic> data,
    String notifDocId,
  ) {
    final visitorDocId = (data['visitorDocId'] ?? '').toString();
    final status = (data['status'] ?? 'pending').toString();

    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
            const SizedBox(width: 5),
            Text(
              'visitor_status_approved'.tr,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
            ),
          ],
        ),
      );
    }

    if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 5),
            Text(
              'visitor_status_rejected'.tr,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                try {
                  if (visitorDocId.isNotEmpty) {
                    await AppFirestore.instance.collection('visitors').doc(visitorDocId).update({
                      'status': 'approved',
                      'actionTime': FieldValue.serverTimestamp(),
                    });
                  }
                  await AppFirestore.instance.collection('notifications').doc(notifDocId).update({
                    'status': 'approved',
                  });
                  if (rootCtx.mounted) {
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                      SnackBar(
                        content: Text('visitor_approved_success'.tr),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error approving visitor: $e');
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
              label: Text(
                'approve_visitor_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                try {
                  if (visitorDocId.isNotEmpty) {
                    await AppFirestore.instance.collection('visitors').doc(visitorDocId).update({
                      'status': 'rejected',
                      'actionTime': FieldValue.serverTimestamp(),
                    });
                  }
                  await AppFirestore.instance.collection('notifications').doc(notifDocId).update({
                    'status': 'rejected',
                  });
                  if (rootCtx.mounted) {
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                      SnackBar(
                        content: Text('visitor_denied_success'.tr),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error rejecting visitor: $e');
                }
              },
              icon: const Icon(Icons.cancel_rounded, size: 15, color: Color(0xFFDC2626)),
              label: Text(
                'deny_visitor_btn'.tr,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFDC2626)),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'હાલ કોઈ નવી નોટિફિકેશન નથી'.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'જ્યારે એડમિન પેમેન્ટ સ્વીકારશે અથવા સોસાયટી એલર્ટ મોકલશે, ત્યારે અહીં દેખાશે.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
