import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_app_guard.dart';
import '../../services/society_service.dart';
import '../../models/premise_type.dart';
import '../../widgets/premium_ui.dart';

class AdminAddUserScreen extends StatefulWidget {
  final String initialRole;
  final String? initialBlock;
  final String? initialUnit;

  const AdminAddUserScreen({
    super.key,
    this.initialRole = 'member',
    this.initialBlock,
    this.initialUnit,
  });

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _phoneC = TextEditingController();
  final _unitC = TextEditingController();
  final _customBlockC = TextEditingController();

  late String _selectedRole;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  String? _selectedBlock;
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == 'admin' ? 'sub_admin' : widget.initialRole;
    if (widget.initialBlock != null && widget.initialBlock!.isNotEmpty) {
      _selectedBlock = widget.initialBlock;
    }
    if (widget.initialUnit != null && widget.initialUnit!.isNotEmpty) {
      _selectedUnit = widget.initialUnit;
      _unitC.text = widget.initialUnit!;
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _phoneC.dispose();
    _unitC.dispose();
    _customBlockC.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  int _unitMemberCount(Map<String, dynamic>? d) {
    if (d == null) return 0;
    final ids = <String>{};
    final mid = d['memberId'];
    if (mid is String && mid.isNotEmpty) ids.add(mid);
    final arr = d['memberIds'];
    if (arr is List) {
      for (final x in arr) {
        if (x is String && x.isNotEmpty) ids.add(x);
      }
    }
    return ids.length;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();
    final phone = _phoneC.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('કૃપા કરીને નામ, ઈમેલ અને પાસવર્ડ દાખલ કરો.'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('કૃપા કરીને સાચું ઈમેલ આઈડી દાખલ કરો.'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String effectiveBlock = (_selectedBlock != null && _selectedBlock!.trim().isNotEmpty)
        ? _selectedBlock!.trim()
        : _customBlockC.text.trim();

    final String effectiveUnit = (_selectedUnit != null && _selectedUnit!.trim().isNotEmpty)
        ? _selectedUnit!.trim()
        : _unitC.text.trim();

    if (_selectedRole == 'member' && (effectiveBlock.isEmpty || effectiveUnit.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('કૃપા કરીને મેમ્બર માટે બ્લોક અને ફ્લેટ / ઘર નંબર પસંદ કરો.'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final targetSocietyId = SocietyService.instance.societyId;

      // Member assignment validation and warning check
      if (_selectedRole == 'member' && effectiveBlock.isNotEmpty && effectiveUnit.isNotEmpty) {
        final cleanBlock = SocietyService.instance.logicalBlockName(effectiveBlock);

        // Verification: ensure unit is from this block's registered units if units exist
        final unitsSnapshot = await AppFirestore.instance
            .collection('units')
            .where('societyId', isEqualTo: targetSocietyId)
            .get();

        final normEffectiveBlock = SocietyService.instance.normalizeBlockName(effectiveBlock);
        final registeredUnitsInBlock = unitsSnapshot.docs.where((doc) {
          final d = doc.data();
          final bName = (d['blockName'] ?? '').toString();
          final normB = SocietyService.instance.normalizeBlockName(bName);
          return normB == normEffectiveBlock ||
              bName == effectiveBlock ||
              bName == cleanBlock ||
              doc.id.startsWith('$effectiveBlock-') ||
              doc.id.startsWith('$cleanBlock-') ||
              doc.id.startsWith('$normEffectiveBlock-');
        }).map((doc) => (doc.data()['unitNumber'] ?? '').toString()).toSet();

        if (registeredUnitsInBlock.isNotEmpty && !registeredUnitsInBlock.contains(effectiveUnit)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ફ્લેટ "$effectiveUnit" બ્લોક "$cleanBlock" ના રજિસ્ટર્ડ યુનિટ્સમાં નથી. કૃપા કરીને લિસ્ટમાંથી જ માન્ય ફ્લેટ પસંદ કરો.'.tr,
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final unitDocId = SocietyService.instance.unitFirestoreDocId(
          cleanBlock,
          effectiveUnit,
        );
        try {
          final uDoc = await AppFirestore.instance.collection('units').doc(unitDocId).get();
          if (uDoc.exists) {
            final count = _unitMemberCount(uDoc.data());
            if (count > 0) {
              if (!mounted) return;
              final proceed = await PremiumConfirmationDialog.show(
                context,
                title: 'ફ્લેટમાં પહેલેથી સભ્ય છે'.tr,
                message:
                    'આ ફ્લેટ ($cleanBlock-$effectiveUnit) પર પહેલેથી $count મેમ્બર નોંધાયેલ છે. વધારાના પરિવાર સભ્ય તરીકે ઉમેરવા માંગો છો?'.tr,
                icon: Icons.info_outline_rounded,
                gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                cancelText: 'ના, રદ કરો'.tr,
                confirmText: 'હા, ઉમેરો'.tr,
                confirmGradient: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                confirmColor: const Color(0xFF4338CA),
                confirmIcon: Icons.person_add_rounded,
              );
              if (proceed != true) {
                setState(() => _isSubmitting = false);
                return;
              }
            }
          }
        } catch (e) {
          debugPrint('Error checking unit member count: $e');
        }
      }

      final cleanEmail = email.trim().toLowerCase();
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanPass = password.trim();

      final defaultApp = await ensureDefaultFirebaseApp();
      final tempApp = await Firebase.initializeApp(
        name: 'UserRegApp_${DateTime.now().millisecondsSinceEpoch}',
        options: defaultApp.options,
      );

      try {
        UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: cleanEmail, password: cleanPass);

        final batch = AppFirestore.instance.batch();
        final usersCol = AppFirestore.instance.collection('users');

        final cleanBlockName = SocietyService.instance.normalizeBlockName(effectiveBlock);

        final userData = <String, dynamic>{
          'uid': userCred.user!.uid,
          'name': name.trim(),
          'phone': cleanPhone.isNotEmpty ? cleanPhone : phone.trim(),
          'displayPhone': phone.trim(),
          'email': cleanEmail,
          'role': _selectedRole,
          'blockName': _selectedRole == 'member' ? cleanBlockName : '',
          'unitNumber': _selectedRole == 'member' ? effectiveUnit : '',
          'societyId': targetSocietyId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        };

        if (_selectedRole == 'sub_admin') {
          userData['isSubAdmin'] = true;
          userData['isCommitteeMember'] = true;
        }

        batch.set(usersCol.doc(userCred.user!.uid), userData);

        if (_selectedRole == 'member' && effectiveBlock.isNotEmpty && effectiveUnit.isNotEmpty) {
          final unitDocId = SocietyService.instance.unitFirestoreDocId(
            cleanBlockName,
            effectiveUnit,
          );
          final uRef = AppFirestore.instance.collection('units').doc(unitDocId);
          batch.set(
            uRef,
            {
              'blockName': effectiveBlock,
              'unitNumber': effectiveUnit,
              'isOccupied': true,
              'memberId': userCred.user!.uid,
              'memberIds': FieldValue.arrayUnion([userCred.user!.uid]),
              'societyId': targetSocietyId,
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();
      } finally {
        try {
          await tempApp.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      final roleLabel = _selectedRole == 'sub_admin'
          ? 'સબ-એડમિન'.tr
          : (_selectedRole == 'watchman' ? 'વોચમેન'.tr : 'મેમ્બર'.tr);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('$name ($roleLabel) નું એકાઉન્ટ સફળતાપૂર્વક બની ગયું!'.tr)),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (authErr) {
      if (!mounted) return;
      String msg = 'ભૂલ આવી: ${authErr.message ?? authErr.code}'.tr;
      if (authErr.code == 'email-already-in-use') {
        msg = 'આ ઇમેઇલ ($email) પહેલેથી જ રજીસ્ટર થયેલો છે. કૃપા કરીને અન્ય ઇમેઇલ વાપરો.'.tr;
      } else if (authErr.code == 'weak-password') {
        msg = 'પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.'.tr;
      } else if (authErr.code == 'invalid-email') {
        msg = 'અમાન્ય ઈમેલ એડ્રેસ: $email'.tr;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ભૂલ આવી: $e'.tr),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color get _currentRoleColor {
    switch (_selectedRole) {
      case 'sub_admin':
        return const Color(0xFF7C3AED);
      case 'watchman':
        return const Color(0xFF059669);
      case 'member':
      default:
        return const Color(0xFF2563EB);
    }
  }

  List<Color> get _currentRoleGradient {
    switch (_selectedRole) {
      case 'sub_admin':
        return const [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF8B5CF6)];
      case 'watchman':
        return const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)];
      case 'member':
      default:
        return const [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: "યુઝર રજીસ્ટ્રેશન".tr,
        subtitle: "સોસાયટી મેમ્બર, વોચમેન અથવા એડમિન એડ કરો".tr,
        icon: Icons.person_add_alt_1_rounded,
        accentColor: _currentRoleColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Role Hero Banner
              _buildRoleHeroBanner(),
              const SizedBox(height: 22),

              // 1. Role Selection Header & Cards
              _buildSectionHeader(
                step: "STEP 1",
                title: "૧. યુઝર રોલ પસંદ કરો".tr,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      label: 'મેમ્બર'.tr,
                      role: 'member',
                      subtitle: 'ફ્લેટ ધારક'.tr,
                      icon: Icons.apartment_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRoleCard(
                      label: 'સબ-એડમિન'.tr,
                      role: 'sub_admin',
                      subtitle: 'કમિટી સભ્ય'.tr,
                      icon: Icons.admin_panel_settings_rounded,
                      gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRoleCard(
                      label: 'વોચમેન'.tr,
                      role: 'watchman',
                      subtitle: 'ગેટ સ્ટાફ'.tr,
                      icon: Icons.security_rounded,
                      gradient: const [Color(0xFF059669), Color(0xFF047857)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Personal Information Card
              _buildSectionHeader(
                step: "STEP 2",
                title: "૨. વ્યક્તિગત વિગતો".tr,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _nameC,
                      label: 'પૂરું નામ (Full Name)'.tr,
                      hint: 'દા.ત. રમેશભાઈ પટેલ'.tr,
                      isRequired: true,
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _phoneC,
                      label: 'મોબાઈલ નંબર (Mobile Number)'.tr,
                      hint: 'દા.ત. 9876543210'.tr,
                      isRequired: false,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailC,
                      label: 'ઈમેલ આઈડી (Email / Login ID)'.tr,
                      hint: 'દા.ત. user@gmail.com'.tr,
                      isRequired: true,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordC,
                      label: 'પાસવર્ડ (Login Password)'.tr,
                      hint: 'ઓછામાં ઓછા 6 અક્ષર'.tr,
                      isRequired: true,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      helperText: 'યુઝર આ પાસવર્ડ વડે Building Guard એપમાં લોગિન કરશે.'.tr,
                    ),
                  ],
                ),
              ),

              // 3. Conditional: Flat/Unit Selection for Members
              if (_selectedRole == 'member') ...[
                const SizedBox(height: 24),
                _buildSectionHeader(
                  step: "STEP 3",
                  title: "૩. બ્લોક & ફ્લેટ / ઘર નંબરની વિગતો".tr,
                  icon: Icons.home_work_outlined,
                  accentColor: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: AppFirestore.instance
                        .collection('blocks')
                        .where('societyId', isEqualTo: SocietyService.instance.societyId)
                        .snapshots(),
                    builder: (context, blockSnap) {
                      final blocks = blockSnap.hasData ? blockSnap.data!.docs : <QueryDocumentSnapshot>[];

                      // Deduplicate blocks by canonical normalized name
                      final uniqueBlocks = <String, Map<String, dynamic>>{};
                      for (final b in blocks) {
                        final d = b.data() as Map<String, dynamic>?;
                        final rawName = (d?['name'] ?? SocietyService.instance.logicalBlockName(b.id)).toString();
                        final clean = SocietyService.instance.normalizeBlockName(rawName);
                        if (clean.isEmpty) continue;
                        if (!uniqueBlocks.containsKey(clean)) {
                          uniqueBlocks[clean] = {
                            'id': b.id,
                            'name': clean,
                            'type': (d?['type'] ?? 'Wing').toString(),
                            'category': (d?['category'] ?? '').toString(),
                          };
                        }
                      }
                      final sortedBlockKeys = uniqueBlocks.keys.toList()
                        ..sort((a, b) {
                          if (SocietyService.instance.isGroundBlock(a)) return -1;
                          if (SocietyService.instance.isGroundBlock(b)) return 1;
                          return a.compareTo(b);
                        });
                      final hasBlocks = sortedBlockKeys.isNotEmpty;

                      return StreamBuilder<QuerySnapshot>(
                        stream: AppFirestore.instance
                            .collection('units')
                            .where('societyId', isEqualTo: SocietyService.instance.societyId)
                            .snapshots(),
                        builder: (context, unitSnap) {
                          // Find units matching currently selected block
                          final matchingUnits = <Map<String, dynamic>>[];
                          if (unitSnap.hasData && _selectedBlock != null) {
                            final normSelected = SocietyService.instance.normalizeBlockName(_selectedBlock!);
                            for (final doc in unitSnap.data!.docs) {
                              final d = doc.data() as Map<String, dynamic>;
                              final bName = (d['blockName'] ?? '').toString();
                              final normB = SocietyService.instance.normalizeBlockName(bName);
                              if (normB == normSelected ||
                                  bName == _selectedBlock ||
                                  doc.id.startsWith('$_selectedBlock-') ||
                                  doc.id.startsWith('$normSelected-')) {
                                matchingUnits.add({
                                  'id': doc.id,
                                  'unitNumber': d['unitNumber']?.toString() ?? '',
                                  'memberCount': _unitMemberCount(d),
                                  'isOccupied': d['isOccupied'] == true,
                                });
                              }
                            }
                            matchingUnits.sort((a, b) {
                              final nA = int.tryParse(a['unitNumber'] as String) ?? 0;
                              final nB = int.tryParse(b['unitNumber'] as String) ?? 0;
                              if (nA != 0 && nB != 0) return nA.compareTo(nB);
                              return (a['unitNumber'] as String).compareTo(b['unitNumber'] as String);
                            });
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Helpful note
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'મેમ્બરને ફ્લેટ સાથે લિંક કરવાથી તેઓ મેન્ટેનન્સ બિલ અને વિઝિટર એપ્રુવલ જોઈ શકશે.'.tr,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF0F766E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 1. Block Selector / Input
                              if (hasBlocks) ...[
                                DropdownButtonFormField<String>(
                                  key: ValueKey('block_$_selectedBlock'),
                                  initialValue: (_selectedBlock != null &&
                                          sortedBlockKeys.contains(SocietyService.instance.normalizeBlockName(_selectedBlock!)))
                                      ? SocietyService.instance.normalizeBlockName(_selectedBlock!)
                                      : null,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
                                  decoration: InputDecoration(
                                    labelText: '${"બ્લોક / વિંગ / ફ્લોર".tr} *',
                                    labelStyle: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
                                    hintText: 'બ્લોક પસંદ કરો'.tr,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 10),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF0D9488)),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 46),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
                                    ),
                                  ),
                                  items: sortedBlockKeys.map((k) {
                                    final item = uniqueBlocks[k]!;
                                    final label = SocietyService.instance.formatBlockDisplayName(
                                      k,
                                      architectureType: item['type'] as String?,
                                      category: item['category'] as String?,
                                    );
                                    return DropdownMenuItem<String>(
                                      value: k,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedBlock = val;
                                      _selectedUnit = null;
                                      _unitC.clear();
                                    });
                                  },
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _customBlockC,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: '${"બ્લોક / વિંગ નામ (Block / Wing)".tr} *',
                                    labelStyle: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
                                    hintText: 'દા.ત. A, B, વિંગ-1'.tr,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 10),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF0D9488)),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 46),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
                                    ),
                                    helperText: 'હજુ કોઈ બ્લોક નોંધાયેલ નથી, નામ સીધું લખો.'.tr,
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedBlock = v.trim();
                                      _selectedUnit = null;
                                      _unitC.clear();
                                    });
                                  },
                                ),
                              ],

                              const SizedBox(height: 16),

                              // 2. Flat / Unit Number Selection (Dynamic Architecture Noun)
                              if (matchingUnits.isNotEmpty) ...[
                                () {
                                  final selectedBlockItem = _selectedBlock != null ? uniqueBlocks[_selectedBlock] : null;
                                  final blockArchType = selectedBlockItem?['type'] as String? ?? SocietyService.instance.architectureType;
                                  final vocab = PremiseVocabulary.fromString(blockArchType);
                                  final unitNoun = vocab.unitShortLabel;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF0D9488)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "રજિસ્ટર્ડ ${vocab.unitLabel} લિસ્ટમાંથી પસંદ કરો:".tr,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('unit_${_selectedBlock}_$_selectedUnit'),
                                        initialValue: (_selectedUnit != null && matchingUnits.any((u) => u['unitNumber'] == _selectedUnit))
                                            ? _selectedUnit
                                            : null,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
                                        decoration: InputDecoration(
                                          labelText: '${vocab.unitLabel} *',
                                          labelStyle: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
                                          hintText: 'માન્ય $unitNoun પસંદ કરો'.tr,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.only(left: 12, right: 10),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.meeting_room_rounded, size: 20, color: Color(0xFF0D9488)),
                                            ),
                                          ),
                                          prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 46),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
                                          ),
                                        ),
                                        items: matchingUnits.map((u) {
                                          final num = u['unitNumber'] as String;
                                          final count = u['memberCount'] as int;
                                          final isOccupied = count > 0;
                                          return DropdownMenuItem<String>(
                                            value: num,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        unitNoun,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF0D9488),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      num,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 14.5,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isOccupied ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: isOccupied ? const Color(0xFFFCD34D) : const Color(0xFFA7F3D0),
                                                      width: 0.9,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isOccupied ? Icons.people_alt_rounded : Icons.check_circle_rounded,
                                                        size: 11,
                                                        color: isOccupied ? const Color(0xFF92400E) : const Color(0xFF059669),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isOccupied ? '$count સભ્ય'.tr : 'ખાલી (Vacant)'.tr,
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: isOccupied ? const Color(0xFF92400E) : const Color(0xFF059669),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedUnit = val;
                                            _unitC.text = val ?? '';
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                }(),
                              ] else if (_selectedBlock == null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.touch_app_rounded, size: 20, color: Color(0xFF64748B)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'કૃપા કરીને પહેલા ઉપરથી બ્લોક / વિંગ પસંદ કરો.'.tr,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'આ બ્લોકમાં અગાઉથી કોઈ ફ્લેટ ડેટાબેઝમાં નોંધાયેલ નથી.'.tr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'માન્ય ફ્લેટ / ઘર નંબર દાખલ કરો (દા.ત. 101, A-101):'.tr,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _unitC,
                                        keyboardType: TextInputType.text,
                                        textCapitalization: TextCapitalization.characters,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: '${"ફ્લેટ / ઘર નંબર (Flat / Unit No.)".tr} *',
                                          labelStyle: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
                                          hintText: 'દા.ત. 101'.tr,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.only(left: 12, right: 10),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.meeting_room_rounded, size: 20, color: Color(0xFF0D9488)),
                                            ),
                                          ),
                                          prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 46),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() => _selectedUnit = val.trim());
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Security & Login Information Notice
              _buildSecurityInfoCard(),

              const SizedBox(height: 28),

              // 4. Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeroBanner() {
    final (title, subtitle, icon, badge) = switch (_selectedRole) {
      'sub_admin' => (
        "કમિટી સબ-એડમિન એકાઉન્ટ".tr,
        "કમિટી સભ્યને સોસાયટી મેનેજમેન્ટ, વિઝિટર ઓડિટ અને કમ્પ્લેઇન્ટ્સ હેન્ડલ કરવાના અધિકારો મળશે.".tr,
        Icons.admin_panel_settings_rounded,
        "કમિટી સ્ટાફ".tr,
      ),
      'watchman' => (
        "ગેટ સિક્યોરિટી વોચમેન".tr,
        "વોચમેન એપથી ગેટ એન્ટ્રી, ગાર્ડ પેટ્રોલિંગ અને વિઝિટર્સની રીઅલ-ટાઇમ તપાસ કરી શકશે.".tr,
        Icons.security_rounded,
        "સિક્યોરિટી સ્ટાફ".tr,
      ),
      _ => (
        "સોસાયટી મેમ્બર એકાઉન્ટ".tr,
        "ફ્લેટ મેમ્બર એપથી મુલાકાતીઓને અગાઉથી મંજૂરી આપી શકશે અને મેન્ટેનન્સ બિલ ચૂકવી શકશે.".tr,
        Icons.apartment_rounded,
        "ફ્લેટ ધારક".tr,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _currentRoleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _currentRoleColor.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String step,
    required String title,
    required IconData icon,
    Color? accentColor,
  }) {
    final color = accentColor ?? _currentRoleColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
          ),
          child: Text(
            step,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String role,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    final isSelected = _selectedRole == role;
    final primaryColor = gradient.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedRole = role);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? gradient
                            : [Colors.grey.shade400, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      color: isSelected ? primaryColor : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: isPassword && _obscurePassword,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentRoleColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: _currentRoleColor),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 46),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _currentRoleColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _currentRoleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield_outlined, size: 18, color: _currentRoleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "લોગિન એકાઉન્ટ માહિતી".tr,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "એકાઉન્ટ બન્યા પછી આ યુઝરને તેમનો ઈમેલ અને પાસવર્ડ આપીને Building Guard એપમાં લોગિન કરવા કહો.".tr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSubmitting
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : _currentRoleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSubmitting
            ? null
            : [
                BoxShadow(
                  color: _currentRoleColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _submitForm();
              },
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 21),
        label: Text(
          _isSubmitting ? 'યુઝર એકાઉન્ટ બની રહ્યું છે...'.tr : 'યુઝર રજીસ્ટર કરો'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
