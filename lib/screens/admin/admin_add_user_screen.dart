import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_app_guard.dart';
import '../../services/society_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "યુઝર રજીસ્ટ્રેશન".tr,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "સોસાયટી મેમ્બર, વોચમેન અથવા એડમિન એડ કરો".tr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguageSwitchButton()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Role Selection Header
              Text(
                "૧. યુઝર રોલ પસંદ કરો".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      label: 'મેમ્બર'.tr,
                      role: 'member',
                      subtitle: 'ફ્લેટ ધારક'.tr,
                      icon: Icons.apartment_rounded,
                      gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleCard(
                      label: 'સબ-એડમિન'.tr,
                      role: 'sub_admin',
                      subtitle: 'કમિટી સભ્ય'.tr,
                      icon: Icons.shield_rounded,
                      gradient: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleCard(
                      label: 'વોચમેન'.tr,
                      role: 'watchman',
                      subtitle: 'ગેટ સ્ટાફ'.tr,
                      icon: Icons.security_rounded,
                      gradient: [const Color(0xFF10B981), const Color(0xFF047857)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Personal Information Card
              Text(
                "૨. વ્યક્તિગત વિગતો".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameC,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'પૂરું નામ (Full Name) *'.tr,
                        hintText: 'દા.ત. રમેશભાઈ પટેલ'.tr,
                        prefixIcon: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF4338CA)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneC,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'મોબાઈલ નંબર (Mobile Number)'.tr,
                        hintText: 'દા.ત. 9876543210'.tr,
                        prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF4338CA)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'ઈમેલ આઈડી (Email / Login ID) *'.tr,
                        hintText: 'દા.ત. user@gmail.com'.tr,
                        prefixIcon: const Icon(Icons.email_rounded, size: 20, color: Color(0xFF4338CA)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordC,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'પાસવર્ડ (Login Password) *'.tr,
                        hintText: 'ઓછામાં ઓછા 6 અક્ષર'.tr,
                        prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: Color(0xFF4338CA)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Conditional: Flat/Unit Selection for Members
              if (_selectedRole == 'member') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home_work_rounded, color: Color(0xFF0D9488), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "૩. બ્લોક & ફ્લેટ / ઘર નંબરની વિગતો".tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
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
                              // 1. Block Selector / Input
                              if (hasBlocks) ...[
                                DropdownButtonFormField<String>(
                                  key: ValueKey('block_$_selectedBlock'),
                                  initialValue: (_selectedBlock != null &&
                                          sortedBlockKeys.contains(SocietyService.instance.normalizeBlockName(_selectedBlock!)))
                                      ? SocietyService.instance.normalizeBlockName(_selectedBlock!)
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'બ્લોક / વિંગ / ફ્લોર *'.tr,
                                    hintText: 'બ્લોક પસંદ કરો'.tr,
                                    prefixIcon: const Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF0D9488)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
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
                                  decoration: InputDecoration(
                                    labelText: 'બ્લોક / વિંગ નામ (Block / Wing) *'.tr,
                                    hintText: 'દા.ત. A, B, વિંગ-1'.tr,
                                    prefixIcon: const Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF0D9488)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
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

                              // 2. Flat / Unit Number Selection (Strictly Registered Units)
                              if (matchingUnits.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0D9488)),
                                    const SizedBox(width: 5),
                                    Text(
                                      "રજિસ્ટર્ડ ફ્લેટ લિસ્ટમાંથી પસંદ કરો:".tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
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
                                  decoration: InputDecoration(
                                    labelText: 'ફ્લેટ / ઘર નંબર (Flat / Unit No.) *'.tr,
                                    hintText: 'માન્ય ફ્લેટ નંબર પસંદ કરો'.tr,
                                    prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20, color: Color(0xFF0D9488)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
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
                                          Text(
                                            'ફ્લેટ $num'.tr,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOccupied ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isOccupied ? const Color(0xFFFCD34D) : const Color(0xFFA7F3D0),
                                              ),
                                            ),
                                            child: Text(
                                              isOccupied ? '$count સભ્ય'.tr : 'ખાલી'.tr,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isOccupied ? const Color(0xFF92400E) : const Color(0xFF065F46),
                                              ),
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
                              ] else if (_selectedBlock == null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'કૃપા કરીને પહેલા ઉપરથી બ્લોક / વિંગ પસંદ કરો.'.tr,
                                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'આ બ્લોકમાં અગાઉથી કોઈ ફ્લેટ ડેટાબેઝમાં નોંધાયેલ નથી.'.tr,
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF92400E)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'માન્ય ફ્લેટ / ઘર નંબર દાખલ કરો (દા.ત. 101, A-101):'.tr,
                                        style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _unitC,
                                        keyboardType: TextInputType.text,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: InputDecoration(
                                          labelText: 'ફ્લેટ / ઘર નંબર *'.tr,
                                          hintText: 'દા.ત. 101'.tr,
                                          prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20, color: Color(0xFF0D9488)),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
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

              const SizedBox(height: 16),

              const SizedBox(height: 32),

              // 5. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "યુઝર રજીસ્ટર કરો".tr,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? gradient.first : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected ? gradient : [Colors.grey.shade400, Colors.grey.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: isSelected ? gradient.first : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
