import 'package:building_guard/screens/watchmen_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/society_service.dart';
import 'admin_dashboard.dart';
import 'member_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // FCM token + topic subscription: [NotificationService] via authStateChanges

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      SocietyService.instance
          .bindFromUserMap(userDoc.data() as Map<String, dynamic>?);

      String role = userDoc.get('role');

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else if (role == 'watchman') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const WatchmanScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MemberScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: cs.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 42,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "સોસાયટી મેનેજમેન્ટ એપ",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'ઇમેઇલ'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'પાસવર્ડ'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("લોગઈન"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text("એકાઉન્ટ નથી? નવું બનાવો"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'member'; // Default role
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('બધી વિગતો ભરો')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // fcmToken: [NotificationService] saves via authStateChanges after sign-in

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'societyId': SocietyService.kDefaultSocietyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('રજીસ્ટ્રેશન સફળ! હવે લોગિન કરો.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      // 🔥 અહીં પણ mounted ચેક ઉમેર્યું
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("નવું એકાઉન્ટ બનાવો")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'પૂરૂ નામ')),
            const SizedBox(height: 16),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'ઇમેઇલ')),
            const SizedBox(height: 16),
            TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'પાસવર્ડ')),
            const SizedBox(height: 16),

            // રોલ સિલેક્શન (પ્રોફેશનલ એપમાં આ છુપાવેલું હોય છે, પણ અત્યારે તમારા માટે રાખ્યું છે)
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              // અહીં 'watchman' ઉમેરી દીધું છે
              items: ['admin', 'member', 'watchman']
                  .map((role) => DropdownMenuItem(
                  value: role, child: Text(role.toUpperCase())))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
              decoration: const InputDecoration(labelText: 'તમારો રોલ'),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("રજીસ્ટર કરો"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// exports.sendNotification = functions.firestore
//     .document('notifications/{notifId}')
//     .onCreate(async (snapshot, context) => {
//         const data = snapshot.data();
//         const title = data.title;
//         const body = data.body;
//         const targetUID = data.targetUID; // 'ALL' અથવા ચોક્કસ Member UID
//
//         const payload = {
//             notification: {
//                 title: title,
//                 body: body,
//             },
//             data: {
//                 click_action: "FLUTTER_NOTIFICATION_CLICK",
//                 sound: "default",
//                 type: data.type || "general"
//             }
//         };
//
//         try {
//             if (targetUID === 'ALL') {
//                 // ૧. બધા મેમ્બર્સને મોકલવા માટે (Topic Messaging)
//                 // મેમ્બર્સ એપમાં 'society_members' ટોપિક સબસ્ક્રાઇબ કરેલા હોવા જોઈએ
//                 await admin.messaging().sendToTopic('society_members', payload);
//                 console.log('Broadcast notification sent successfully');
//             } else {
//                 // ૨. પર્ટિક્યુલર મેમ્બરને મોકલવા માટે (Single Device)
//                 const userDoc = await admin.firestore().collection('users').doc(targetUID).get();
//
//                 if (!userDoc.exists) {
//                     console.log('User not found');
//                     return null;
//                 }
//
//                 const fcmToken = userDoc.data().fcmToken;
//
//                 if (fcmToken) {
//                     await admin.messaging().sendToDevice(fcmToken, payload);
//                     console.log(`Notification sent to user: ${targetUID}`);
//                 } else {
//                     console.log('FCM Token not found for user');
//                 }
//             }
//         } catch (error) {
//             console.error('Error sending notification:', error);
//         }
//         return null;
//     });




exports.sendNotification = functions.firestore
    .document('notifications/{notifId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const title = data.title;
        const body = data.body;
        const targetUID = data.targetUID; // 'ALL' અથવા ચોક્કસ Member UID

        try {
            if (targetUID === 'ALL') {
                // ૧. બધા મેમ્બર્સને મોકલવા માટે (Topic Messaging)
                const message = {
                    topic: 'society_members',
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        type: data.type || "general",
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                };

                await admin.messaging().send(message);
                console.log('Broadcast notification sent successfully to topic');
            } else {
                // ૨. પર્ટિક્યુલર મેમ્બરને મોકલવા માટે (Single Device)
                const userDoc = await admin.firestore().collection('users').doc(targetUID).get();

                if (!userDoc.exists) {
                    console.log('User not found in Firestore');
                    return null;
                }

                const fcmToken = userDoc.data().fcmToken;

                if (fcmToken) {
                    // 🔥 નવો રસ્તો (v1 API)
                    const message = {
                        token: fcmToken,
                        notification: {
                            title: title,
                            body: body,
                        },
                        data: {
                            type: data.type || "general",
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                        },
                        // Android માટે સ્પેસિફિક સેટિંગ્સ
                        android: {
                            priority: "high",
                            notification: {
                                sound: "default",
                            }
                        }
                    };

                    await admin.messaging().send(message);
                    console.log(`Notification sent successfully to user: ${targetUID}`);
                } else {
                    console.log('FCM Token not found for user');
                }
            }
        } catch (error) {
            console.error('Error sending notification:', error);
        }
        return null;
    });




//////////////////////////////////////////////////////



    // જ્યારે 'visitors' કલેક્શનમાં status બદલાય ત્યારે
exports.onStatusChange = functions.firestore
    .document('visitors/{visitorId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // ૧. ચેક કરો કે સ્ટેટસમાં ફેરફાર થયો છે કે નહીં
        if (oldData.status !== newData.status) {

            // --- કન્ડિશન A: જો મહેમાન બહાર જાય (Check-out) ---
            if (newData.status === 'checked_out') {
                const memberUID = newData.memberId; // મેમ્બરની ID

                const payload = {
                    notification: {
                        title: "મહેમાન બહાર ગયા 🚪",
                        body: `${newData.name} સોસાયટીની બહાર નીકળી ગયા છે.`,
                    }
                };

                const userDoc = await admin.firestore().collection('users').doc(memberUID).get();
                const fcmToken = userDoc.data() ? userDoc.data().fcmToken : null;

                if (fcmToken) {
                    console.log(`Sending check-out notif to member: ${memberUID}`);
                    return admin.messaging().sendToDevice(fcmToken, payload);
                }
            }

            // --- કન્ડિશન B: જો મેમ્બર અપ્રૂવ કે રિજેક્ટ કરે ---
            else if (newData.status === 'approved' || newData.status === 'rejected') {
                const watchmanUID = newData.watchmanId; // એન્ટ્રી કરનાર વોચમેન

                let msgStatus = newData.status === 'approved' ? "મંજૂરી મળી ગઈ છે ✅" : "ના પાડી છે ❌";

                const payload = {
                    notification: {
                        title: "મેમ્બરનો જવાબ આવ્યો!",
                        body: `${newData.name} માટે: ${msgStatus}`,
                    }
                };

                const userDoc = await admin.firestore().collection('users').doc(watchmanUID).get();
                const fcmToken = userDoc.data() ? userDoc.data().fcmToken : null;

                if (fcmToken) {
                    console.log(`Sending response notif to watchman: ${watchmanUID}`);
                    return admin.messaging().sendToDevice(fcmToken, payload);
                }
            }
        }
        return null;
    });
 */