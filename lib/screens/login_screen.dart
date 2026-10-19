import 'package:building_guard/core/app_firestore.dart';
import 'package:building_guard/screens/watchmen_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_guard_service.dart';
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
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Register new active session ID to enforce 1-device policy
      await SessionGuardService.instance.registerNewLoginSession(userCredential.user!.uid);

      // FCM token + topic subscription: [NotificationService] via authStateChanges

      DocumentSnapshot userDoc = await AppFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        try {
          final oldDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (oldDoc.exists && oldDoc.data() != null) {
            await AppFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(oldDoc.data()!);
            userDoc = await AppFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();
          }
        } catch (_) {}
      }

      SocietyService.instance.bindFromUserMap(
        userDoc.data() as Map<String, dynamic>?,
      );

      String role = userDoc.get('role');

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (role == 'watchman') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WatchmanScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MemberScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "પાસવર્ડ ભૂલી ગયા?",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text("પાસવર્ડ રીસેટ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "તમારો રજીસ્ટર્ડ ઇમેઇલ દાખલ કરો. અમે તમને પાસવર્ડ રીસેટ કરવાની લિંક મોકલીશું.",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'ઇમેઇલ',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("રદ કરો"),
          ),
          FilledButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                          "પાસવર્ડ રીસેટ લિંક તમારા ઇમેઇલ પર મોકલવામાં આવી છે."),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("ભૂલ આવી: $e")),
                  );
                }
              }
            },
            child: const Text("લિંક મોકલો"),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegMode { member, newSocietyAdmin }

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _societyCodeController = TextEditingController();
  final _societyNameController = TextEditingController();
  final _blockController = TextEditingController();
  final _unitController = TextEditingController();

  _RegMode _mode = _RegMode.member;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _societyCodeController.dispose();
    _societyNameController.dispose();
    _blockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email.trim());
  }

  String _normalizeSocietyId(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return SocietyService.kDefaultSocietyId;
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final societyCode = _societyCodeController.text.trim();
    final societyName = _societyNameController.text.trim();
    final block = _blockController.text.trim();
    final unit = _unitController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને નામ, ઇમેઇલ અને પાસવર્ડ ભરો.')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને માન્ય ઇમેઇલ એડ્રેસ લખો.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ.')),
      );
      return;
    }

    if (_mode == _RegMode.newSocietyAdmin && societyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('નવી સોસાયટી માટે સોસાયટી કોડ લખવો ફરજિયાત છે.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resolvedSocietyId = _mode == _RegMode.newSocietyAdmin
          ? _normalizeSocietyId(societyCode)
          : (societyCode.isEmpty
              ? SocietyService.kDefaultSocietyId
              : _normalizeSocietyId(societyCode));

      final role = _mode == _RegMode.newSocietyAdmin ? 'admin' : 'member';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final userData = <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
        'role': role,
        'societyId': resolvedSocietyId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_mode == _RegMode.member) {
        if (block.isNotEmpty) userData['blockName'] = block;
        if (unit.isNotEmpty) userData['unitNumber'] = unit;
      }

      await AppFirestore.instance.collection('users').doc(uid).set(userData);

      // જો નવી સોસાયટી એડમિન તરીકે શરૂ કરી રહ્યા હોય, તો society_settings તૈયાર કરો
      if (_mode == _RegMode.newSocietyAdmin) {
        await AppFirestore.instance
            .collection('society_settings')
            .doc(resolvedSocietyId)
            .set({
          'societyId': resolvedSocietyId,
          'societyName': societyName.isEmpty ? resolvedSocietyId : societyName,
          'isSetupComplete': false,
          'adminUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            _mode == _RegMode.newSocietyAdmin
                ? 'સોસાયટી અને એડમિન એકાઉન્ટ સફળતાપૂર્વક બની ગયું! હવે લૉગિન કરો.'
                : 'રજીસ્ટ્રેશન સફળ! હવે તમારા એકાઉન્ટમાં લૉગિન કરો.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('ભૂલ: ${e.toString()}'),
          ),
        );
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
      appBar: AppBar(title: const Text("નવું એકાઉન્ટ બનાવો")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // રજીસ્ટ્રેશન પ્રકાર પસંદગી
            const Text(
              "તમારું એકાઉન્ટ પ્રકાર પસંદ કરો:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            SegmentedButton<_RegMode>(
              segments: const [
                ButtonSegment<_RegMode>(
                  value: _RegMode.member,
                  icon: Icon(Icons.person_outline),
                  label: Text("રહીશ / સભ્ય"),
                ),
                ButtonSegment<_RegMode>(
                  value: _RegMode.newSocietyAdmin,
                  icon: Icon(Icons.domain_add),
                  label: Text("નવી સોસાયટી (ચેરમેન)"),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (newSet) {
                setState(() => _mode = newSet.first);
              },
            ),
            const SizedBox(height: 14),

            // સુરક્ષા નોંધ (વોચમેન માત્ર એડમિન બનાવી શકે)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mode == _RegMode.member
                          ? "સોસાયટીમાં રહેતા તમામ પરિવારો અહીંથી રજીસ્ટર થઈ શકે છે."
                          : "નવી સોસાયટી શરૂ કરવા ચેરમેન / સેક્રેટરી અહીંથી સેટઅપ કરી શકે છે.",
                      style: TextStyle(fontSize: 13, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _mode == _RegMode.member ? 'પૂરું નામ' : 'ચેરમેન / એડમિનનું નામ',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'મોબાઇલ નંબર (કોન્ટેક્ટ)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ઇમેઇલ એડ્રેસ',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'પાસવર્ડ (ઓછામાં ઓછા ૬ અક્ષર)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),

            if (_mode == _RegMode.newSocietyAdmin) ...[
              TextField(
                controller: _societyNameController,
                decoration: const InputDecoration(
                  labelText: 'સોસાયટીનું નામ',
                  hintText: 'દા.ત. શિવ રેસીડેન્સી',
                  prefixIcon: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _societyCodeController,
                decoration: const InputDecoration(
                  labelText: 'નવો સોસાયટી કોડ (અંગ્રેજીમાં)',
                  hintText: 'દા.ત. shiv-residency',
                  helperText: 'અન્ય સભ્યો આ કોડ વાપરીને જોડાશે.',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
            ] else ...[
              TextField(
                controller: _societyCodeController,
                decoration: const InputDecoration(
                  labelText: 'સોસાયટી કોડ',
                  hintText: 'દા.ત. shiv-residency',
                  helperText: 'ખાલી રાખશો તો default society ગણાશે.',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _blockController,
                      decoration: const InputDecoration(
                        labelText: 'વિંગ / શેરી',
                        hintText: 'દા.ત. A અથવા શેરી-૧',
                        prefixIcon: Icon(Icons.holiday_village_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'ફ્લેટ / મકાન નં.',
                        hintText: 'દા.ત. 101',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // વોચમેન નોંધ
            Text(
              "ℹ️ નોંધ: સિક્યુરિટી ગાર્ડ / વોચમેનનું ખાતું માત્ર એડમિન ડેશબોર્ડમાંથી જ બનાવી શકાય છે.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

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
                    : Text(
                        _mode == _RegMode.newSocietyAdmin
                            ? "નવી સોસાયટી રજીસ્ટર કરો"
                            : "મેમ્બર તરીકે રજીસ્ટર કરો",
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

