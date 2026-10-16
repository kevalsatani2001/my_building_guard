import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_app_guard.dart';
import '../services/society_service.dart';
import 'premium_ui.dart';

/// Helper to count members currently assigned to a unit
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

bool _isValidEmail(String email) {
  return RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(email);
}

String _normalizeSocietyId(String input) {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.isEmpty) return SocietyService.kDefaultSocietyId;
  return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
}

/// Dialogs for User Management, Watchman Management, and Visitor Reports.
class AdminUserManageDialog {
  /// Opens dialog to register a new User (Member, Watchman, or Co-Admin)
  static Future<void> showAddUserDialog(BuildContext context) async {
    final nC = TextEditingController();
    final eC = TextEditingController();
    final pC = TextEditingController();
    final phoneC = TextEditingController();
    final societyCodeC = TextEditingController();
    final uC = TextEditingController();
    String selectedRole = 'member';
    bool createSeparateSociety = false;
    bool obscurePassword = true;
    bool isSubmitting = false;
    String? sB;
    String? sU;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            title: PremiumDialogHeader(
              title: "નવું યુઝર રજીસ્ટ્રેશન",
              subtitle: "મેમ્બર, વોચમેન કે એડમિન એકાઉન્ટ બનાવો",
              icon: Icons.person_add_alt_1_rounded,
              accentColor: cs.primary,
              onClose: isSubmitting ? null : () => Navigator.pop(ctx),
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Role Selector Cards
                    const Text(
                      'યુઝર રોલ પસંદ કરો:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRoleCard(
                          label: 'મેમ્બર',
                          role: 'member',
                          icon: Icons.apartment_rounded,
                          selected: selectedRole == 'member',
                          onTap: () => setDS(() => selectedRole = 'member'),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleCard(
                          label: 'વોચમેન',
                          role: 'watchman',
                          icon: Icons.security_rounded,
                          selected: selectedRole == 'watchman',
                          onTap: () => setDS(() => selectedRole = 'watchman'),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleCard(
                          label: 'એડમિન',
                          role: 'admin',
                          icon: Icons.admin_panel_settings_rounded,
                          selected: selectedRole == 'admin',
                          onTap: () => setDS(() => selectedRole = 'admin'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (selectedRole == 'admin') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "આ એડમિનને અલગ સોસાયટી આપો",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                "ON કરશો તો આ યુઝર નવી/અલગ society manage કરશે",
                                style: TextStyle(fontSize: 11),
                              ),
                              value: createSeparateSociety,
                              onChanged: (v) => setDS(() => createSeparateSociety = v),
                            ),
                            if (createSeparateSociety) ...[
                              const SizedBox(height: 6),
                              TextField(
                                controller: societyCodeC,
                                decoration: InputDecoration(
                                  labelText: "સોસાયટી કોડ (Society Code)",
                                  hintText: "દા.ત. shiv-residency",
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Full Name
                    TextField(
                      controller: nC,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "પૂરું નામ *",
                        hintText: "દા.ત. રમેશભાઈ પટેલ",
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email
                    TextField(
                      controller: eC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "ઇમેઇલ એડ્રેસ *",
                        hintText: "દા.ત. ramesh@gmail.com",
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password with visibility toggle
                    TextField(
                      controller: pC,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "પાસવર્ડ *",
                        hintText: "ઓછામાં ઓછા ૬ અક્ષર",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => setDS(() => obscurePassword = !obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Phone (for member)
                    if (selectedRole == 'member') ...[
                      TextField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "મોબાઈલ નંબર (વૈકલ્પિક)",
                          hintText: "૧૦ અંકનો નંબર",
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Block & Unit selector in card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_city_rounded, size: 16, color: Colors.teal),
                                SizedBox(width: 6),
                                Text(
                                  "બ્લોક & ઘરની વિગત પસંદ કરો *",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: AppFirestore.instance
                                  .collection('blocks')
                                  .where(
                                    'societyId',
                                    isEqualTo: SocietyService.instance.societyId,
                                  )
                                  .snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) return const LinearProgressIndicator();
                                return DropdownButtonFormField<String>(
                                  key: ValueKey('dialog_block_$sB'),
                                  initialValue: sB,
                                  decoration: InputDecoration(
                                    labelText: "વિંગ / બ્લોક",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  hint: const Text("બ્લોક પસંદ કરો"),
                                  items: snap.data!.docs
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text('${d['name']}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setDS(() {
                                    sB = v;
                                    sU = null;
                                  }),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            if (sB != null) ...[
                              StreamBuilder<QuerySnapshot>(
                                stream: AppFirestore.instance
                                    .collection('units')
                                    .where(
                                      'societyId',
                                      isEqualTo: SocietyService.instance.societyId,
                                    )
                                    .snapshots(),
                                builder: (context, snap) {
                                  final cleanB = SocietyService.instance.logicalBlockName(sB!);
                                  final unitDocs = snap.hasData
                                      ? snap.data!.docs.where((d) {
                                          final data = d.data() as Map<String, dynamic>;
                                          final b = (data['blockName'] ?? '').toString();
                                          return b == sB || b == cleanB || d.id.startsWith('$sB-') || d.id.startsWith('$cleanB-');
                                        }).toList()
                                      : <QueryDocumentSnapshot>[];

                                  if (unitDocs.isEmpty) {
                                    return TextField(
                                      controller: uC,
                                      decoration: InputDecoration(
                                        labelText: "ઘર / ફ્લેટ નંબર *",
                                        hintText: "દા.ત. 101, A-202",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      onChanged: (v) => sU = v.trim(),
                                    );
                                  }

                                  bool valueExists = unitDocs.any(
                                    (d) => d.get('unitNumber').toString() == sU,
                                  );
                                  if (!valueExists) {
                                    sU = null;
                                  }

                                  return DropdownButtonFormField<String>(
                                    key: ValueKey('dialog_unit_$sU'),
                                    initialValue: sU,
                                    decoration: InputDecoration(
                                      labelText: "ઘર / ફ્લેટ નંબર *",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    hint: const Text("ઘર પસંદ કરો"),
                                    items: unitDocs.map((d) {
                                      String val = d.get('unitNumber').toString();
                                      final cnt = _unitMemberCount(
                                        d.data() as Map<String, dynamic>?,
                                      );
                                      final label = cnt > 0 ? '$val ($cnt મેમ્બર)' : val;
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(label),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      setDS(() {
                                        sU = v;
                                        uC.text = v ?? '';
                                      });
                                    },
                                  );
                                },
                              ),
                            ] else ...[
                              TextField(
                                controller: uC,
                                decoration: InputDecoration(
                                  labelText: "ઘર / ફ્લેટ નંબર *",
                                  hintText: "પહેલા બ્લોક પસંદ કરો અથવા સીધો ફ્લેટ નંબર લખો",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (v) => sU = v.trim(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text("રદ કરો"),
              ),
              FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nC.text.trim().isEmpty || eC.text.trim().isEmpty || pC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("કૃપા કરીને બધી જરૂરી વિગતો ભરો!")),
                          );
                          return;
                        }
                        if (!_isValidEmail(eC.text.trim())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("માન્ય ઇમેઇલ એડ્રેસ દાખલ કરો!")),
                          );
                          return;
                        }
                        if (pC.text.trim().length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ!")),
                          );
                          return;
                        }
                        final effectiveU = uC.text.trim().isNotEmpty ? uC.text.trim() : sU;
                        if (selectedRole == 'member' && (sB == null || effectiveU == null || effectiveU.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("કૃપા કરીને બ્લોક અને ઘર નંબર પસંદ/લખો!")),
                          );
                          return;
                        }
                        if (selectedRole == 'admin' &&
                            createSeparateSociety &&
                            societyCodeC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("અલગ સોસાયટી માટે સોસાયટી કોડ આપો!")),
                          );
                          return;
                        }

                        setDS(() => isSubmitting = true);

                        await _createNewUser(
                          context,
                          ctx,
                          eC.text.trim(),
                          pC.text.trim(),
                          nC.text.trim(),
                          selectedRole,
                          sB,
                          effectiveU,
                          phone: selectedRole == 'member' ? phoneC.text.trim() : null,
                          societyIdOverride:
                              selectedRole == 'admin' && createSeparateSociety
                                  ? _normalizeSocietyId(societyCodeC.text)
                                  : null,
                        );

                        if (ctx.mounted) {
                          setDS(() => isSubmitting = false);
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(isSubmitting ? "નોંધાઈ રહ્યું છે..." : "એકાઉન્ટ બનાવો"),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildRoleCard({
    required String label,
    required String role,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.teal.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.teal.shade800 : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.teal.shade900 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _createNewUser(
    BuildContext parentContext,
    BuildContext dialogContext,
    String email,
    String pass,
    String name,
    String role,
    String? block,
    String? unit, {
    String? phone,
    String? societyIdOverride,
  }) async {
    try {
      final defaultApp = await ensureDefaultFirebaseApp();
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
        options: defaultApp.options,
      );
      UserCredential res = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: pass);

      Map<String, dynamic> userData = {
        'uid': res.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'societyId':
            (societyIdOverride != null && societyIdOverride.trim().isNotEmpty)
                ? societyIdOverride.trim()
                : SocietyService.instance.societyId,
      };

      if (role == 'member') {
        userData['unitNumber'] = unit;
        userData['blockName'] = block;
        if (phone != null && phone.isNotEmpty) {
          userData['phone'] = phone;
        }

        final unitDocId = '$block-$unit';
        final unitRef = AppFirestore.instance
            .collection('units')
            .doc(unitDocId);
        await AppFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(unitRef);
          final memberIds = <String>{res.user!.uid};
          String? primaryMemberId;
          if (snap.exists) {
            final d = snap.data()!;
            final old = d['memberId'];
            if (old is String && old.isNotEmpty) {
              memberIds.add(old);
              primaryMemberId = old;
            }
            final arr = d['memberIds'];
            if (arr is List) {
              for (final x in arr) {
                if (x is String && x.isNotEmpty) memberIds.add(x);
              }
            }
          }
          if (primaryMemberId == null) {
            final others = memberIds
                .where((id) => id != res.user!.uid)
                .toList();
            primaryMemberId = others.isNotEmpty ? others.first : res.user!.uid;
          }
          tx.set(unitRef, {
            'isOccupied': true,
            'memberIds': memberIds.toList(),
            'memberId': primaryMemberId,
            'societyId': SocietyService.instance.societyId,
            'blockName': block,
            'unitNumber': unit,
          }, SetOptions(merge: true));
        });
      }

      await AppFirestore.instance
          .collection('users')
          .doc(res.user!.uid)
          .set(userData);

      await tempApp.delete();
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text("$role સફળતાપૂર્વક ઉમેરાયો!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text("ભૂલ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Dialog for managing watchmen accounts (active/inactive status)
class AdminWatchmanManageDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: PremiumDialogHeader(
          title: 'વોચમેન મેનેજમેન્ટ',
          subtitle: 'સુરક્ષા ગેટ સ્ટાફ અને એક્ટિવ સ્ટેટસ',
          icon: Icons.security_rounded,
          accentColor: Colors.indigo,
          onClose: () => Navigator.pop(ctx),
        ),
        content: SizedBox(
          width: 380,
          height: 360,
          child: StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
                .collection('users')
                .where(
                  'societyId',
                  isEqualTo: SocietyService.instance.societyId,
                )
                .where('role', isEqualTo: 'watchman')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return PremiumEmptyState(
                  message: 'કોઈ વોચમેન નોંધાયેલ નથી.',
                  icon: Icons.shield_outlined,
                  actionLabel: '+ નવો વોચમેન ઉમેરો',
                  onAction: () {
                    Navigator.pop(ctx);
                    AdminUserManageDialog.showAddUserDialog(context);
                  },
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final m = d.data() as Map<String, dynamic>;
                  final active = m['isActive'] != false;
                  final name = (m['name'] ?? d.id).toString();
                  final email = (m['email'] ?? '').toString();

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? Colors.indigo.shade100 : Colors.grey.shade300,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: active ? Colors.indigo.shade50 : Colors.grey.shade200,
                            foregroundColor: active ? Colors.indigo.shade800 : Colors.grey.shade600,
                            child: const Icon(Icons.security_rounded, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: active ? Colors.green.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: active ? Colors.green.shade300 : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: Text(
                                        active ? 'ફરજ પર' : 'નિષ્ક્રિય',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: active ? Colors.green.shade800 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Switch(
                            value: active,
                            activeThumbColor: Colors.indigo,
                            onChanged: (v) {
                              AppFirestore.instance
                                  .collection('users')
                                  .doc(d.id)
                                  .update({'isActive': v});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              AdminUserManageDialog.showAddUserDialog(context);
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text('નવો વોચમેન'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('બંધ કરો'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for monthly visitor report summary
class AdminVisitorReportDialog {
  static Future<void> show(BuildContext context) async {
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final snap = await AppFirestore.instance
        .collection('visitors')
        .where('entryTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .limit(2000)
        .get();

    final docs = snap.docs
        .where(
          (d) => SocietyService.instance.documentBelongsToCurrentTenant(
            d.data(),
          ),
        )
        .toList();

    int total = docs.length;
    int approved = docs.where((d) => d['status'] == 'approved').length;
    int pending = docs.where((d) => d['status'] == 'pending').length;
    int rejected = docs.where((d) => d['status'] == 'rejected').length;
    int out = docs.where((d) => d['status'] == 'checked_out').length;

    final monthNames = [
      'જાન્યુઆરી', 'ફેબ્રુઆરી', 'માર્ચ', 'એપ્રિલ', 'મે', 'જૂન',
      'જુલાઈ', 'ઓગસ્ટ', 'સપ્ટેમ્બર', 'ઓક્ટોબર', 'નવેમ્બર', 'ડિસેમ્બર'
    ];
    final monthLabel = '${monthNames[start.month - 1]} ${start.year}';

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: PremiumDialogHeader(
          title: 'વિઝિટર રિપોર્ટ',
          subtitle: '$monthLabel — મુલાકાતી વિશ્લેષણ',
          icon: Icons.analytics_rounded,
          accentColor: Colors.teal,
          onClose: () => Navigator.pop(ctx),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade800, Colors.teal.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'કુલ નોંધાયેલ મુલાકાતીઓ',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$total',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2x2 Metric Grid
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        title: 'મંજૂર (Approved)',
                        value: '$approved',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        subtitle: total > 0 ? '${((approved / total) * 100).toStringAsFixed(0)}% મંજૂરી' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PremiumStatCard(
                        title: 'પેન્ડિંગ (Pending)',
                        value: '$pending',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.amber.shade800,
                        subtitle: 'ચકાસણી હેઠળ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        title: 'નકાર્યું (Rejected)',
                        value: '$rejected',
                        icon: Icons.cancel_rounded,
                        color: Colors.red.shade700,
                        subtitle: 'પ્રવેશ રોકેલ',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PremiumStatCard(
                        title: 'ચેક-આઉટ થયેલ',
                        value: '$out',
                        icon: Icons.exit_to_app_rounded,
                        color: Colors.purple.shade700,
                        subtitle: 'પરત ગયા',
                      ),
                    ),
                  ],
                ),

                if (total > 0) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'સ્ટેટસ પ્રમાણ વિશ્લેષણ:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          if (approved > 0)
                            Expanded(
                              flex: approved,
                              child: Container(color: Colors.green.shade600),
                            ),
                          if (pending > 0)
                            Expanded(
                              flex: pending,
                              child: Container(color: Colors.amber.shade600),
                            ),
                          if (rejected > 0)
                            Expanded(
                              flex: rejected,
                              child: Container(color: Colors.red.shade600),
                            ),
                          if (out > 0)
                            Expanded(
                              flex: out,
                              child: Container(color: Colors.purple.shade600),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('સમજાઈ ગયું (બંધ કરો)'),
          ),
        ],
      ),
    );
  }
}
