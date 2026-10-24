import 'package:flutter/material.dart';
import '../../services/super_admin_service.dart';
import '../../models/super_admin_models.dart';
import '../../widgets/admin_credentials_modal.dart';
import '../../services/localization_service.dart';
import '../../l10n/app_strings.dart';

class SuperAdminCreateAdminScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const SuperAdminCreateAdminScreen({super.key, this.onSuccess});

  @override
  State<SuperAdminCreateAdminScreen> createState() => _SuperAdminCreateAdminScreenState();
}

class _SuperAdminCreateAdminScreenState extends State<SuperAdminCreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'Super@123');

  bool _obscurePass = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final pass = _passCtrl.text.trim();

      await SuperAdminService.instance.createSuperAdmin(
        name: name,
        email: email,
        phone: phone,
        password: pass,
      );

      widget.onSuccess?.call();

      if (!mounted) return;

      await AdminCredentialsModal.show(
        context,
        result: OnboardSocietyResult(
          societyId: 'global_master',
          adminUid: 'superadmin_${DateTime.now().millisecondsSinceEpoch}',
          societyName: 'MyBuildingGuard Global Platform',
          architectureType: 'Global Enterprise Master',
          city: 'હેડક્વાર્ટર'.tr,
          adminName: name,
          adminEmail: email,
          adminPassword: pass,
          adminPhone: phone,
        ),
      );

      if (mounted) navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('એરર આવી: $e'.tr),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFF59E0B);
    const darkBg = Color(0xFF070B14);
    const cardBg = Color(0xFF111827);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          surface: cardBg,
        ),
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
        children: [
          // Ambient Glow Effect (Royal Gold top right)
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, accentColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSecurityNotice(accentColor),
                          const SizedBox(height: 20),

                          _buildSectionTitle('વ્યક્તિગત & સિક્યોરિટી વિગતો'.tr, Icons.badge_rounded, accentColor),
                          const SizedBox(height: 12),

                          _buildInputField(
                            controller: _nameCtrl,
                            label: 'પૂરું નામ (Full Name)'.tr,
                            hint: 'દા.ત. રાજેશભાઈ પટેલ'.tr,
                            icon: Icons.person_rounded,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'કૃપા કરીને પૂરું નામ દાખલ કરો'.tr;
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildInputField(
                            controller: _phoneCtrl,
                            label: 'મોબાઈલ નંબર (Phone Number)'.tr,
                            hint: 'દા.ત. 9876543210'.tr,
                            icon: Icons.phone_iphone_rounded,
                            keyboardType: TextInputType.phone,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'કૃપા કરીને ફોન નંબર દાખલ કરો'.tr;
                              if (v.trim().length < 10) return 'માન્ય 10 અંકનો નંબર દાખલ કરો'.tr;
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildInputField(
                            controller: _emailCtrl,
                            label: 'ઓફિશિયલ ઈમેલ આઈડી (Email)'.tr,
                            hint: 'superadmin@domain.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'કૃપા કરીને ઈમેલ દાખલ કરો'.tr;
                              if (!v.contains('@') || !v.contains('.')) return 'માન્ય ઈમેલ આઈડી દાખલ કરો'.tr;
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildPasswordField(accentColor, cardBg),
                          const SizedBox(height: 24),

                          _buildPrivilegeSummary(accentColor, cardBg),
                          const SizedBox(height: 32),

                          _buildSubmitButton(accentColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'નવા કો-સુપર એડમિન'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'MASTER ACCESS',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Super Admin Command Center • સત્તા સોંપણી'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const LanguageSwitchButton(isDark: true),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'સંપૂર્ણ કમાન્ડ અધિકાર ચેતવણી'.tr,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'કો-સુપર એડમિન પાસે તમામ સોસાયટીઓ, આર્થિક હિસાબો, સભ્યો અને ગ્લોબલ કિલ-સ્વિચનું પૂર્ણ નિયંત્રણ હશે. માત્ર વિશ્વાસુ વ્યક્તિને જ આ રોલ આપો.'.tr,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
          cursorColor: accentColor,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: cardBg,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 12),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(Color accentColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'સુરક્ષા પાસવર્ડ (Password)'.tr,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
          cursorColor: accentColor,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'કૃપા કરીને પાસવર્ડ દાખલ કરો'.tr;
            if (v.trim().length < 6) return 'ઓછામાં ઓછા ૬ અક્ષરનો પાસવર્ડ જરૂરી છે'.tr;
            return null;
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: cardBg,
            hintText: 'મજબૂત પાસવર્ડ સેટ કરો...'.tr,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 12),
              child: Icon(Icons.lock_rounded, color: accentColor, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivilegeSummary(Color accentColor, Color cardBg) {
    final permissions = [
      'તમામ સોસાયટી પરિસરો અને ગેટ પાસવર્ડ્સનું સંચાલન'.tr,
      'પ્લેટફોર્મ ફાઇનાન્સ, કમિશન અને કલેક્શન ઑડિટ'.tr,
      'ગ્લોબલ સિસ્ટમ પુશ બ્રોડકાસ્ટ મોકલવાનો અધિકાર'.tr,
      'ડિફોલ્ટ લોગિન ક્રેડેન્શિયલ્સ સાથે સીધો એડમિન એક્સેસ'.tr,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rtl_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'મળવાપાત્ર માસ્ટર પરમિશન્સ'.tr,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...permissions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

    Widget _buildSubmitButton(Color accentColor) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'સુપર એડમિન સત્તા આપો'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
