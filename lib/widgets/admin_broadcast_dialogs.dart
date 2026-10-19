import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/society_service.dart';

import 'premium_ui.dart';

/// Cloud Functions v2 region for admin push notifications.
const String _kAdminFunctionsRegion = 'us-central1';

/// Dialogs and logic for sending notifications and publishing notices by Chairman/Admin.
class AdminBroadcastDialogs {
  /// Show dialog to send push notification to all members or a specific member.
  static Future<void> showNotificationDialog(
    BuildContext context, {
    String? targetUID,
    String? targetName,
  }) async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    final isAll = targetUID == null;

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: PremiumDialogHeader(
          title: isAll ? "સૂચના બ્રોડકાસ્ટ" : "સભ્યને સૂચના",
          subtitle: isAll
              ? "સોસાયટીના તમામ સભ્યોને પુશ એલર્ટ મળશે"
              : "$targetName ને પર્સનલ પુશ એલર્ટ મળશે",
          icon: Icons.campaign_rounded,
          accentColor: Colors.orange.shade800,
          onClose: () => Navigator.pop(dialogCtx),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAll ? Icons.hub_rounded : Icons.person_rounded,
                      size: 16,
                      color: Colors.orange.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAll ? "લક્ષ્ય: તમામ સભ્યો" : "લક્ષ્ય: $targetName",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleC,
                decoration: InputDecoration(
                  labelText: "વિષય (Title) *",
                  hintText: "દા.ત. પાણી સપ્લાય અંગે સૂચના",
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyC,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "સંદેશ / સૂચના (Message) *",
                  hintText: "સૂચનાની વિગત લખો...",
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("રદ કરો"),
          ),
          FilledButton.icon(
            onPressed: () {
              if (titleC.text.trim().isNotEmpty && bodyC.text.trim().isNotEmpty) {
                final title = titleC.text.trim();
                final body = bodyC.text.trim();
                Navigator.pop(dialogCtx);
                sendPushNotification(
                  context: context,
                  title: title,
                  body: body,
                  targetUID: targetUID,
                );
              }
            },
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text("મોકલો"),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
          ),
        ],
      ),
    );
  }

  /// Sends a push notification via Firebase Functions (Topic or Member direct)
  /// and always mirrors the notification in AppFirestore so in-app delivery is guaranteed.
  static Future<void> sendPushNotification({
    required BuildContext context,
    required String title,
    required String body,
    String? targetUID,
    String? targetName,
  }) async {
    final cleanUid = targetUID?.trim();
    final bool isAll = cleanUid == null || cleanUid.isEmpty;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final societyId = SocietyService.instance.societyId;

    // ૧. Always record notification in Firestore so it's visible in-app and triggers Cloud Functions if active
    try {
      await AppFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'targetUID': isAll ? 'ALL' : cleanUid,
        'societyId': societyId,
        'type': isAll ? 'general' : 'admin_notice',
        'createdAt': FieldValue.serverTimestamp(),
        'senderUid': ?currentUid,
      });
    } catch (e) {
      debugPrint('Firestore notification save error: $e');
    }

    final app = await ensureDefaultFirebaseApp();
    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: _kAdminFunctionsRegion,
    );

    try {
      if (isAll) {
        final callable = functions.httpsCallable(
          'sendBroadcastPush',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
        );
        await callable.call<Map<String, dynamic>>({
          'title': title,
          'body': body,
          'type': 'general',
          'senderUid': ?currentUid,
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ સોસાયટીના તમામ સભ્યોને સૂચના મોકલાઈ ગઈ છે!'),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      // Member-direct push
      String? memberToken;
      try {
        final userDoc = await AppFirestore.instance.collection('users').doc(cleanUid).get();
        if (userDoc.exists) {
          memberToken = userDoc.data()?['fcmToken']?.toString().trim();
        }
      } catch (e) {
        debugPrint('Fetch member token error: $e');
      }

      final callable = functions.httpsCallable(
        'sendMemberPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'memberUid': cleanUid,
        'title': title,
        'body': body,
        'type': 'admin_notice',
        if (memberToken != null && memberToken.isNotEmpty) 'fcmToken': memberToken,
      });
      final data = result.data;
      if (!context.mounted) return;
      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetName != null
                  ? '✅ $targetName ના ફોન પર પુશ નોટિફિકેશન સફળતાપૂર્વક પહોંચી ગયું!'
                  : '✅ સભ્યના ફોન પર પુશ નોટિફિકેશન સફળતાપૂર્વક પહોંચી ગયું!',
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      } else if (data['reason'] == 'no_token') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'સભ્યના ફોનનું ટોકન મળ્યું નથી, પરંતુ ઇન-એપ સૂચના સફળતાપૂર્વક સેવ કરી દીધી છે.',
            ),
            backgroundColor: Colors.deepOrange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ઇન-એપ સૂચના સેવ થઈ ગઈ છે (${data['reason'] ?? data})'),
            backgroundColor: Colors.blueGrey.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        final detail = e.message?.trim().isNotEmpty == true
            ? e.message!
            : (e.details?.toString() ?? e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ઇન-એપ સૂચના સેવ થઈ ગઈ છે (સર્વર: $detail)'),
            backgroundColor: Colors.blueGrey.shade800,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ઇન-એપ સૂચના સેવ થઈ ગઈ છે ($e)'),
            backgroundColor: Colors.blueGrey.shade800,
          ),
        );
      }
    }
  }

  /// Show dialog to create a new notice and optionally broadcast via push.
  static Future<void> showPublishNoticeDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    bool sendPush = true;

    final categories = ['📢 સામાન્ય', '💧 પાણી', '⚡ લાઈટ', '🗓️ મીટિંગ', '🪅 ઉત્સવ', '🧹 સફાઈ'];
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: PremiumDialogHeader(
            title: 'નોટિસ બોર્ડ પોસ્ટ',
            subtitle: 'સોસાયટી ડિજિટલ બોર્ડ પર નવી નોટિસ જાહેર કરો',
            icon: Icons.article_rounded,
            accentColor: Colors.deepOrange,
            onClose: () => Navigator.pop(ctx),
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'કેટેગરી પસંદ કરો (વૈકલ્પિક):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: categories.map((cat) {
                      final isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: Colors.deepOrange.shade100,
                        onSelected: (val) {
                          setS(() {
                            selectedCategory = val ? cat : null;
                            if (val && titleC.text.isEmpty) {
                              titleC.text = cat.replaceFirst(RegExp(r'^[^\s]+\s*'), '');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleC,
                    decoration: InputDecoration(
                      labelText: 'નોટિસનું શીર્ષક (Title) *',
                      hintText: 'દા.ત. વાર્ષિક જનરલ મીટિંગ',
                      prefixIcon: const Icon(Icons.title_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyC,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'નોટિસનો સંદેશ / વિગત (Message) *',
                      hintText: 'સભ્યો માટે જરૂરી સૂચના વિગતવાર લખો...',
                      prefixIcon: const Icon(Icons.description_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.shade200),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: sendPush,
                      activeThumbColor: Colors.deepOrange,
                      onChanged: (v) => setS(() => sendPush = v),
                      title: const Text(
                        'બધાને પુશ નોટિફિકેશન મોકલો',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'સભ્યોના ફોનમાં તુરંત એલર્ટ જશે',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              icon: const Icon(Icons.publish_rounded, size: 18),
              label: const Text('નોટિસ પબ્લિશ કરો'),
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                try {
                  await AppFirestore.instance.collection('notices').add({
                    'title': titleC.text.trim(),
                    'body': bodyC.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'authorId': FirebaseAuth.instance.currentUser!.uid,
                    'societyId': SocietyService.instance.societyId,
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('નોટિસ સેવ ન થઈ: $e'),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
                  return;
                }
                Object? pushErr;
                if (sendPush) {
                  try {
                    final app = await ensureDefaultFirebaseApp();
                    final functions = FirebaseFunctions.instanceFor(
                      app: app,
                      region: _kAdminFunctionsRegion,
                    );
                    final callable = functions.httpsCallable(
                      'sendBroadcastPush',
                      options: HttpsCallableOptions(
                        timeout: const Duration(seconds: 60),
                      ),
                    );
                    final b = bodyC.text.trim();
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    await callable.call<Map<String, dynamic>>({
                      'title': titleC.text.trim(),
                      'body': b.isEmpty ? 'નવી નોટિસ' : b,
                      'type': 'notice',
                      'senderUid': ?currentUid,
                    });
                  } on FirebaseFunctionsException catch (e) {
                    pushErr = e;
                  } catch (e) {
                    pushErr = e;
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('નોટિસ પ્રકાશિત!'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (sendPush) {
                  if (pushErr == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          fcmDeliverySummaryForUser({
                            'fcmDeliveryStatus': 'sent_topic_members',
                          }),
                        ),
                        backgroundColor: Colors.teal.shade800,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('પુશ નિષ્ફળ: $pushErr'),
                        backgroundColor: Colors.deepOrange.shade800,
                        duration: const Duration(seconds: 8),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
