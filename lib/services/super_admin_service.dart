import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/app_firestore.dart';
import '../models/super_admin_models.dart';
import '../services/society_service.dart';
import '../services/firebase_app_guard.dart';
import '../services/admin_credential_dispatcher_service.dart';
import '../l10n/app_strings.dart';

class SuperAdminService {
  SuperAdminService._();
  static final SuperAdminService instance = SuperAdminService._();

  FirebaseFirestore get _firestore => AppFirestore.instance;

  /// આખા પ્લેટફોર્મનું ગ્લોબલ એનાલિટિક્સ લાવવું
  Future<GlobalPlatformStats> fetchGlobalStats() async {
    try {
      // ૧. સોસાયટીઓ લાવો
      final socSnap = await _firestore.collection('society_settings').get();
      final societiesMap = <String, Map<String, dynamic>>{};
      for (final doc in socSnap.docs) {
        societiesMap[doc.id] = doc.data();
      }

      // જો જૂની default સોસાયટી હોય
      if (!societiesMap.containsKey(SocietyService.kDefaultSocietyId)) {
        societiesMap[SocietyService.kDefaultSocietyId] = {
          'societyName': 'Default Society',
          'architectureType': 'Wing',
        };
      }

      int commSoc = 0;
      int mixedSoc = 0;
      int resSoc = 0;
      int streetSoc = 0;

      for (final data in societiesMap.values) {
        final arch = (data['architectureType'] ?? 'Wing').toString().toLowerCase();
        if (arch == 'commercial' || arch == 'shopping' || arch == 'mall') {
          commSoc++;
        } else if (arch == 'mixed') {
          mixedSoc++;
        } else if (arch == 'street' || arch == 'rowhouse' || arch == 'bungalow') {
          streetSoc++;
        } else {
          resSoc++;
        }
      }

      // ૨. યુઝર્સ લાવો
      final userSnap = await _firestore.collection('users').get();
      int admins = 0;
      int subAdmins = 0;
      int guards = 0;
      int members = 0;

      for (final doc in userSnap.docs) {
        final d = doc.data();
        final role = (d['role'] ?? 'member').toString().toLowerCase();
        if (role == 'admin') {
          admins++;
        } else if (role == 'wing_admin' || role == 'sub_admin') {
          subAdmins++;
        } else if (role == 'watchman') {
          guards++;
        } else if (role != 'super_admin' && role != 'superadmin') {
          members++;
        }
      }

      // ૩. એકમો (Units) લાવો
      final unitSnap = await _firestore.collection('units').get();
      final totalUnits = unitSnap.docs.length;

      // ૪. મેન્ટેનન્સ બિલિંગ & GST લાવો
      final billSnap = await _firestore.collection('maintenance_bills').get();
      double billed = 0.0;
      double collected = 0.0;
      double pending = 0.0;
      double totalGst = 0.0;

      for (final doc in billSnap.docs) {
        final d = doc.data();
        final amt = (d['amount'] as num?)?.toDouble() ?? 0.0;
        final fest = (d['festivalCharge'] as num?)?.toDouble() ?? 0.0;
        final pen = (d['penalty'] as num?)?.toDouble() ?? 0.0;
        final gst = (d['gstAmount'] as num?)?.toDouble() ?? 0.0;
        final totalPayable = amt + fest + pen + gst;
        final status = (d['status'] ?? 'pending').toString().toLowerCase();

        billed += totalPayable;
        totalGst += gst;

        if (status == 'paid') {
          collected += totalPayable;
        } else {
          pending += totalPayable;
        }
      }

      // ૫. આજના વિઝિટર્સ
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      int todayVisitors = 0;
      try {
        final vSnap = await _firestore
            .collection('visitors')
            .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get();
        todayVisitors = vSnap.docs.length;
      } catch (_) {
        // Fallback જો ઇન્ડેક્સ ન હોય તો કુલ વિઝિટર્સ લાવો
        final vSnap = await _firestore.collection('visitors').limit(100).get();
        todayVisitors = vSnap.docs.length;
      }

      // ૬. ફરિયાદો
      int totalComplaints = 0;
      int resolvedComplaints = 0;
      try {
        final cSnap = await _firestore.collection('complaints').get();
        totalComplaints = cSnap.docs.length;
        for (final doc in cSnap.docs) {
          final s = (doc.data()['status'] ?? '').toString().toLowerCase();
          if (s == 'resolved' || s == 'closed') resolvedComplaints++;
        }
      } catch (_) {}

      return GlobalPlatformStats(
        totalSocieties: societiesMap.length,
        commercialSocieties: commSoc,
        mixedSocieties: mixedSoc,
        residentialSocieties: resSoc,
        streetSocieties: streetSoc,
        totalAdmins: admins,
        totalSubAdmins: subAdmins,
        totalWatchmen: guards,
        totalMembers: members,
        totalUnits: totalUnits,
        totalPlatformBilled: billed,
        totalPlatformCollected: collected,
        totalPlatformPending: pending,
        totalPlatformGst: totalGst,
        todayTotalVisitors: todayVisitors,
        totalComplaints: totalComplaints,
        resolvedComplaints: resolvedComplaints,
      );
    } catch (e) {
      return GlobalPlatformStats.empty();
    }
  }

  /// તમામ સોસાયટીઓનું વિગતવાર લિસ્ટ લાવવું
  Future<List<SocietyOverview>> fetchSocietiesList() async {
    try {
      final socSnap = await _firestore.collection('society_settings').get();
      final userSnap = await _firestore.collection('users').get();
      final unitSnap = await _firestore.collection('units').get();
      final billSnap = await _firestore.collection('maintenance_bills').get();
      final complaintSnap = await _firestore.collection('complaints').get();
      final visitorSnap = await _firestore.collection('visitors').get();

      final list = <SocietyOverview>[];

      final usersBySoc = <String, List<Map<String, dynamic>>>{};
      for (final doc in userSnap.docs) {
        final d = doc.data();
        final sid = (d['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        usersBySoc.putIfAbsent(sid, () => []).add(d);
      }

      final unitsBySoc = <String, int>{};
      for (final doc in unitSnap.docs) {
        final sid = (doc.data()['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        unitsBySoc[sid] = (unitsBySoc[sid] ?? 0) + 1;
      }

      final billsBySoc = <String, Map<String, double>>{};
      for (final doc in billSnap.docs) {
        final d = doc.data();
        final sid = (d['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        final amt = (d['amount'] as num?)?.toDouble() ?? 0.0;
        final fest = (d['festivalCharge'] as num?)?.toDouble() ?? 0.0;
        final gst = (d['gstAmount'] as num?)?.toDouble() ?? 0.0;
        final total = amt + fest + gst;
        final isPaid = (d['status'] ?? '').toString().toLowerCase() == 'paid';

        final map = billsBySoc.putIfAbsent(sid, () => {'billed': 0.0, 'collected': 0.0});
        map['billed'] = (map['billed'] ?? 0.0) + total;
        if (isPaid) {
          map['collected'] = (map['collected'] ?? 0.0) + total;
        }
      }

      final complaintsBySoc = <String, int>{};
      for (final doc in complaintSnap.docs) {
        final d = doc.data();
        final sid = (d['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        final status = (d['status'] ?? '').toString().toLowerCase();
        if (status != 'resolved' && status != 'closed') {
          complaintsBySoc[sid] = (complaintsBySoc[sid] ?? 0) + 1;
        }
      }

      final visitorsBySoc = <String, int>{};
      for (final doc in visitorSnap.docs) {
        final sid = (doc.data()['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        visitorsBySoc[sid] = (visitorsBySoc[sid] ?? 0) + 1;
      }

      final seenIds = <String>{};

      for (final doc in socSnap.docs) {
        final sid = doc.id;
        seenIds.add(sid);
        final d = doc.data();
        final socUsers = usersBySoc[sid] ?? [];

        Map<String, dynamic>? mainAdmin;
        int adminCount = 0;
        int watchmanCount = 0;
        int memberCount = 0;

        for (final u in socUsers) {
          final r = (u['role'] ?? '').toString().toLowerCase();
          if (r == 'admin') {
            adminCount++;
            mainAdmin ??= u;
          } else if (r == 'watchman') {
            watchmanCount++;
          } else if (r != 'super_admin' && r != 'superadmin') {
            memberCount++;
          }
        }

        final bMap = billsBySoc[sid] ?? {'billed': 0.0, 'collected': 0.0};
        final arch = (d['architectureType'] ?? 'Wing').toString();

        list.add(
          SocietyOverview(
            id: sid,
            name: (d['societyName'] ?? sid).toString(),
            architectureType: arch,
            city: (d['city'] ?? 'સુરત').toString(),
            address: d['address']?.toString(),
            adminUid: mainAdmin?['uid']?.toString(),
            adminName: (mainAdmin?['name'] ?? 'એડમિન ફાળવ્યો નથી').toString(),
            adminPhone: (mainAdmin?['phone'] ?? '-').toString(),
            adminEmail: (mainAdmin?['email'] ?? '-').toString(),
            totalUnits: unitsBySoc[sid] ?? 0,
            totalMembers: memberCount,
            totalWatchmen: watchmanCount,
            totalAdmins: adminCount,
            totalBilledMonth: bMap['billed'] ?? 0.0,
            totalCollectedMonth: bMap['collected'] ?? 0.0,
            pendingComplaints: complaintsBySoc[sid] ?? 0,
            todayVisitors: visitorsBySoc[sid] ?? 0,
            isActive: d['isActive'] != false,
            createdAt: (d['createdAt'] is Timestamp)
                ? (d['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ),
        );
      }

      // જો જૂની default સોસાયટી લિસ્ટમાં ન હોય
      if (!seenIds.contains(SocietyService.kDefaultSocietyId) && usersBySoc.containsKey(SocietyService.kDefaultSocietyId)) {
        final socUsers = usersBySoc[SocietyService.kDefaultSocietyId] ?? [];
        Map<String, dynamic>? mainAdmin;
        int adminCount = 0;
        int watchmanCount = 0;
        int memberCount = 0;

        for (final u in socUsers) {
          final r = (u['role'] ?? '').toString().toLowerCase();
          if (r == 'admin') {
            adminCount++;
            mainAdmin ??= u;
          } else if (r == 'watchman') {
            watchmanCount++;
          } else {
            memberCount++;
          }
        }

        final bMap = billsBySoc[SocietyService.kDefaultSocietyId] ?? {'billed': 0.0, 'collected': 0.0};

        list.add(
          SocietyOverview(
            id: SocietyService.kDefaultSocietyId,
            name: 'ડિફોલ્ટ રેસિડેન્શિયલ સંકુલ',
            architectureType: 'Wing',
            city: 'સુરત',
            adminName: (mainAdmin?['name'] ?? 'સુપર સેક્રેટરી').toString(),
            adminPhone: (mainAdmin?['phone'] ?? '-').toString(),
            adminEmail: (mainAdmin?['email'] ?? '-').toString(),
            totalUnits: unitsBySoc[SocietyService.kDefaultSocietyId] ?? 0,
            totalMembers: memberCount,
            totalWatchmen: watchmanCount,
            totalAdmins: adminCount,
            totalBilledMonth: bMap['billed'] ?? 0.0,
            totalCollectedMonth: bMap['collected'] ?? 0.0,
            pendingComplaints: complaintsBySoc[SocietyService.kDefaultSocietyId] ?? 0,
            todayVisitors: visitorsBySoc[SocietyService.kDefaultSocietyId] ?? 0,
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
        );
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  /// તમામ યુઝર્સનું માસ્ટર લિસ્ટ લાવવું
  Future<List<SuperAdminUserItem>> fetchUsersList({String? roleFilter, String? searchQuery}) async {
    try {
      final userSnap = await _firestore.collection('users').get();
      final socSnap = await _firestore.collection('society_settings').get();

      final socNames = <String, String>{};
      for (final doc in socSnap.docs) {
        socNames[doc.id] = (doc.data()['societyName'] ?? doc.id).toString();
      }

      final list = <SuperAdminUserItem>[];
      final query = (searchQuery ?? '').trim().toLowerCase();

      for (final doc in userSnap.docs) {
        final d = doc.data();
        final role = (d['role'] ?? 'member').toString();
        final name = (d['name'] ?? '').toString();
        final email = (d['email'] ?? '').toString();
        final phone = (d['phone'] ?? '').toString();
        final sid = (d['societyId'] ?? SocietyService.kDefaultSocietyId).toString();
        final socName = socNames[sid] ?? (sid == SocietyService.kDefaultSocietyId ? 'Default Society' : sid);

        if (roleFilter != null && roleFilter != 'all') {
          if (role.toLowerCase() != roleFilter.toLowerCase()) continue;
        }

        if (query.isNotEmpty) {
          final matches = name.toLowerCase().contains(query) ||
              email.toLowerCase().contains(query) ||
              phone.toLowerCase().contains(query) ||
              socName.toLowerCase().contains(query);
          if (!matches) continue;
        }

        list.add(
          SuperAdminUserItem(
            uid: doc.id,
            name: name.isEmpty ? 'અનામી યુઝર' : name,
            email: email,
            phone: phone.isEmpty ? '-' : phone,
            role: role,
            societyId: sid,
            societyName: socName,
            unitNumber: d['unitNumber']?.toString(),
            blockName: d['blockName']?.toString(),
            isActive: d['isActive'] != false,
            createdAt: (d['createdAt'] is Timestamp)
                ? (d['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ),
        );
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  /// સોસાયટી ફ્રીઝ / સસ્પેન્ડ કિલ-સ્વિચ (Freeze / Suspend Society)
  Future<void> toggleSocietyStatus(String societyId, bool isActive) async {
    final effectiveSocietyId = societyId.trim().isEmpty ? SocietyService.kDefaultSocietyId : societyId.trim();
    final updateData = <String, dynamic>{
      'isActive': isActive,
      'isSuspendedBySuperAdmin': !isActive,
      'isAdminBlocked': !isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isActive) {
      updateData['unblockedAt'] = FieldValue.serverTimestamp();
      updateData['lastUnblockedAt'] = FieldValue.serverTimestamp();
    } else {
      updateData['suspendedAt'] = FieldValue.serverTimestamp();
      updateData['lastSuspendedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('society_settings').doc(effectiveSocietyId).set(updateData, SetOptions(merge: true));

    // જ્યારે અનબ્લોક કરવામાં આવે, ત્યારે તે સોસાયટીની અગાઉની પેન્ડિંગ અપીલ્સ આપોઆપ ક્લોઝ/રિઝોલ્વ કરો
    if (isActive) {
      try {
        final pending = await _firestore
            .collection('society_appeals')
            .where('societyId', isEqualTo: effectiveSocietyId)
            .where('status', isEqualTo: 'pending')
            .get();
        for (final doc in pending.docs) {
          await doc.reference.update({
            'status': 'resolved',
            'superAdminReply': 'સોસાયટી પુનઃસક્રિય (Unblocked) કરવામાં આવી છે.'.tr,
            'resolvedAt': FieldValue.serverTimestamp(),
            'replyMethod': 'system',
            'isArchived': true,
          });
        }
      } catch (e) {
        debugPrint('Error auto-resolving appeals on society unblock: $e');
      }
    }
  }

  /// યુઝર બ્લોક / અનબ્લોક (એડમિન બ્લોક થાય તો સોસાયટીના તમામ યુઝર્સ પણ આપોઆપ સ્થગિત થશે)
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    final updateData = <String, dynamic>{
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isActive) {
      updateData['unblockedAt'] = FieldValue.serverTimestamp();
      updateData['lastUnblockedAt'] = FieldValue.serverTimestamp();
    } else {
      updateData['suspendedAt'] = FieldValue.serverTimestamp();
      updateData['lastSuspendedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('users').doc(uid).set(updateData, SetOptions(merge: true));

    // જો આ યુઝર સોસાયટીનો એડમિન/પ્રમુખ હોય તો સોસાયટી સેટિંગ્સમાં isAdminBlocked અપડેટ કરો
    try {
      final uDoc = await _firestore.collection('users').doc(uid).get();
      if (uDoc.exists) {
        final uData = uDoc.data();
        final rawRole = (uData?['role'] ?? '').toString().toLowerCase().trim();
        final societyId = (uData?['societyId'] ?? '').toString().trim();
        final bool isAdminUser = rawRole == 'admin' ||
            rawRole == 'chairman' ||
            rawRole == 'president' ||
            uData?['isAdmin'] == true;

        if (isAdminUser) {
          final effectiveSocietyId = societyId.isEmpty ? SocietyService.kDefaultSocietyId : societyId;
          final socUpdate = <String, dynamic>{
            'isAdminBlocked': !isActive,
            'isSuspendedBySuperAdmin': !isActive,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (isActive) {
            socUpdate['lastUnblockedAt'] = FieldValue.serverTimestamp();
          } else {
            socUpdate['lastSuspendedAt'] = FieldValue.serverTimestamp();
          }

          await _firestore.collection('society_settings').doc(effectiveSocietyId).set(socUpdate, SetOptions(merge: true));

          // જો આ એડમિનના UID સાથે જોડાયેલ અન્ય કોઈ society_settings હોય તો તે પણ અપડેટ કરો
          final q = await _firestore.collection('society_settings').where('adminUid', isEqualTo: uid).get();
          for (final doc in q.docs) {
            await doc.reference.set(socUpdate, SetOptions(merge: true));
          }

          // એડમિન અનબ્લોક થાય ત્યારે પેન્ડિંગ અપીલ્સ ક્લોઝ કરો
          if (isActive) {
            final pending = await _firestore
                .collection('society_appeals')
                .where('adminUid', isEqualTo: uid)
                .where('status', isEqualTo: 'pending')
                .get();
            for (final doc in pending.docs) {
              await doc.reference.update({
                'status': 'resolved',
                'superAdminReply': 'એડમિન એકાઉન્ટ પુનઃસક્રિય (Unblocked) કરવામાં આવ્યું છે.'.tr,
                'resolvedAt': FieldValue.serverTimestamp(),
                'replyMethod': 'system',
                'isArchived': true,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Cascade admin block error in toggleUserStatus: $e');
    }
  }

  /// નવી સોસાયટીનું ડાયરેક્ટ ઓનબોર્ડિંગ (Super Admin One-Click Onboard)
  Future<OnboardSocietyResult> onboardNewSociety({
    required String societyName,
    required String architectureType,
    required String city,
    required String adminName,
    required String adminPhone,
    required String adminEmail,
    required String adminPassword,
    int? totalUnits,
  }) async {
    final cleanEmail = adminEmail.trim().toLowerCase();
    final cleanPhone = adminPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPass = adminPassword.trim();

    if (cleanPass.length < 6) {
      throw Exception('સિક્યોરિટી પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.');
    }

    final societyId = 'soc_${DateTime.now().millisecondsSinceEpoch}';
    String adminUid = '';

    // ૧. સેકન્ડરી Firebase App દ્વારા Firebase Auth એકાઉન્ટ તૈયાર કરવું (સુપર એડમિન સેશન અકબંધ રહે)
    final defaultApp = await ensureDefaultFirebaseApp();
    final tempAppName = 'SocietyAdminReg_${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: tempAppName,
      options: defaultApp.options,
    );

    try {
      final userCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
      if (userCred.user != null) {
        adminUid = userCred.user!.uid;
      }
    } on FirebaseAuthException catch (authError) {
      debugPrint('SuperAdminService: Auth registration error: $authError');
      if (authError.code == 'email-already-in-use') {
        throw Exception(
          'આ ઇમેઇલ ($cleanEmail) પહેલેથી જ Firebase Auth માં રજીસ્ટર થયેલો છે. કૃપા કરીને અન્ય ઇમેઇલ વાપરો અથવા પાસવર્ડ રીસેટ કરો.',
        );
      } else if (authError.code == 'weak-password') {
        throw Exception('પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.');
      } else if (authError.code == 'invalid-email') {
        throw Exception('અમાન્ય ઈમેલ એડ્રેસ: $cleanEmail');
      } else {
        throw Exception('Firebase Auth એરર (${authError.code}): ${authError.message}');
      }
    } catch (e) {
      debugPrint('SuperAdminService: General Auth creation error: $e');
      throw Exception('એડમિન એકાઉન્ટ બનાવવામાં ભૂલ આવી: $e');
    } finally {
      try {
        await tempApp.delete();
      } catch (delError) {
        debugPrint('SuperAdminService: tempApp.delete warning: $delError');
      }
    }

    if (adminUid.isEmpty) {
      throw Exception('એડમિનનું Firebase Auth એકાઉન્ટ તૈયાર થઈ શક્યું નથી. ફરી પ્રયાસ કરો.');
    }

    // ૨. સોસાયટી સેટિંગ્સ દસ્તાવેજ
    await _firestore.collection('society_settings').doc(societyId).set({
      'societyId': societyId,
      'societyName': societyName.trim(),
      'architectureType': architectureType,
      'city': city.trim(),
      'isSetupComplete': false,
      'isActive': true,
      'adminUid': adminUid,
      'adminName': adminName.trim(),
      'adminEmail': cleanEmail,
      'adminPhone': cleanPhone.isNotEmpty ? cleanPhone : adminPhone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ૩. એડમિન યુઝર રેકોર્ડ
    await _firestore.collection('users').doc(adminUid).set({
      'uid': adminUid,
      'name': adminName.trim(),
      'email': cleanEmail,
      'phone': cleanPhone.isNotEmpty ? cleanPhone : adminPhone.trim(),
      'displayPhone': adminPhone.trim(),
      'role': 'admin',
      'societyId': societyId,
      'societyName': societyName.trim(),
      'architectureType': architectureType,
      'city': city.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ૪. ફાયરસ્ટોર બેકએન્ડ સિસ્ટમ ઈમેલ ક્યુમાં રેકોર્ડ સેવ કરવો
    await AdminCredentialDispatcherService.instance.queueEmailInFirestore(
      societyName: societyName.trim(),
      adminName: adminName.trim(),
      adminEmail: cleanEmail,
      adminPassword: cleanPass,
      adminPhone: cleanPhone.isNotEmpty ? cleanPhone : adminPhone.trim(),
      architectureType: architectureType,
      city: city.trim(),
    );

    return OnboardSocietyResult(
      societyId: societyId,
      adminUid: adminUid,
      societyName: societyName.trim(),
      architectureType: architectureType,
      city: city.trim(),
      adminName: adminName.trim(),
      adminEmail: cleanEmail,
      adminPassword: cleanPass,
      adminPhone: cleanPhone.isNotEmpty ? cleanPhone : adminPhone.trim(),
      totalUnits: totalUnits,
    );
  }

  /// સોસાયટી એડમિન માટે પાસવર્ડ રીસેટ લિંક મોકલવી
  Future<void> sendAdminPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) throw Exception('ઈમેલ એડ્રેસ ખાલી છે.');
    await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
  }

  /// પ્લેટફોર્મ ગ્લોબલ બ્રોડકાસ્ટ (Global Broadcast Announcement)
  Future<void> sendGlobalBroadcast({
    required String title,
    required String message,
    required String targetCategory, // 'all', 'admins_only', 'commercial'
    required String priority, // 'normal', 'urgent', 'emergency'
  }) async {
    final id = 'broadcast_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('global_broadcasts').doc(id).set({
      'id': id,
      'title': title.trim(),
      'message': message.trim(),
      'targetCategory': targetCategory,
      'priority': priority,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': 'Super Admin',
    });
  }

  /// ચોક્કસ સોસાયટી અથવા તેના એડમિનને ડાયરેક્ટ પુશ નોટિફિકેશન મોકલવું (Direct Push to Specific Society / Admin)
  Future<void> sendNotificationToSocietyAdmin({
    required String societyId,
    required String societyName,
    String? adminUid,
    required String title,
    required String message,
    bool targetWholeSociety = false,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? 'super_admin';
    final target = targetWholeSociety
        ? 'ALL'
        : (adminUid != null && adminUid.isNotEmpty ? adminUid : 'ADMINS');

    await _firestore.collection('notifications').add({
      'title': title.trim(),
      'body': message.trim(),
      'societyId': societyId,
      'targetUID': target,
      'type': 'super_admin_notice',
      'createdAt': FieldValue.serverTimestamp(),
      'senderUid': senderUid,
      'senderRole': 'super_admin',
      'societyName': societyName,
    });
  }

  /// નવા કો-સુપર એડમિન બનાવવા (Create another Super Admin)
  Future<void> createSuperAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPass = password.trim();

    if (cleanPass.length < 6) {
      throw Exception('પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.');
    }

    String uid = '';

    // Firebase Auth માં રજીસ્ટ્રેશન
    final defaultApp = await ensureDefaultFirebaseApp();
    final tempAppName = 'SuperAdminReg_${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: tempAppName,
      options: defaultApp.options,
    );

    try {
      final userCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
      if (userCred.user != null) {
        uid = userCred.user!.uid;
      }
    } on FirebaseAuthException catch (authError) {
      debugPrint('SuperAdminService: Auth creation error: $authError');
      if (authError.code == 'email-already-in-use') {
        throw Exception(
          'આ ઇમેઇલ ($cleanEmail) પહેલેથી જ Firebase Auth માં રજીસ્ટર થયેલો છે. કૃપા કરીને અન્ય ઇમેઇલ વાપરો.',
        );
      } else if (authError.code == 'weak-password') {
        throw Exception('પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.');
      } else if (authError.code == 'invalid-email') {
        throw Exception('અમાન્ય ઈમેલ એડ્રેસ: $cleanEmail');
      } else {
        throw Exception('સુપર એડમિન બનાવવામાં ભૂલ: ${authError.message}');
      }
    } catch (e) {
      throw Exception('સુપર એડમિન બનાવવામાં ભૂલ આવી: $e');
    } finally {
      try {
        await tempApp.delete();
      } catch (delError) {
        debugPrint('SuperAdminService: tempApp delete warning: $delError');
      }
    }

    if (uid.isEmpty) {
      throw Exception('સુપર એડમિનનું Auth એકાઉન્ટ તૈયાર થઈ શક્યું નથી.');
    }

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'email': cleanEmail,
      'phone': cleanPhone.isNotEmpty ? cleanPhone : phone.trim(),
      'displayPhone': phone.trim(),
      'role': 'super_admin',
      'isSuperAdmin': true,
      'societyId': 'global_master',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// કોઈપણ યુઝરને સુપર એડમિન બનાવવો (Promote to Super Admin)
  Future<void> promoteToSuperAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'role': 'super_admin',
      'isSuperAdmin': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// સુપર એડમિન ઓથોરિટી રદ્દ કરવી (Revoke Super Admin Role)
  Future<void> revokeSuperAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'role': 'member',
      'isSuperAdmin': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
