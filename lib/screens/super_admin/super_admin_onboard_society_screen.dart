import 'package:flutter/material.dart';
import '../../services/super_admin_service.dart';
import '../../models/super_admin_models.dart';
import '../../widgets/admin_credentials_modal.dart';

class SuperAdminOnboardSocietyScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const SuperAdminOnboardSocietyScreen({super.key, this.onSuccess});

  @override
  State<SuperAdminOnboardSocietyScreen> createState() => _SuperAdminOnboardSocietyScreenState();
}

class _SuperAdminOnboardSocietyScreenState extends State<SuperAdminOnboardSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _socNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'સુરત');
  final _adminNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'Admin@123');
  final _unitsCtrl = TextEditingController();

  String _selectedArch = 'Commercial';
  bool _obscurePass = true;
  bool _isSubmitting = false;
  bool _sendCredentialsToAdmin = true;

  final List<Map<String, dynamic>> _archTypes = [
    {
      'id': 'Commercial',
      'title': 'કોમર્શિયલ મોલ',
      'subtitle': 'ઓફિસ, દુકાનો અને મોલ',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'id': 'Wing',
      'title': 'રેસિડેન્શિયલ ટાવર',
      'subtitle': 'હાઇરાઇઝ ફ્લેટ્સ અને એપાર્ટમેન્ટ',
      'icon': Icons.apartment_rounded,
    },
    {
      'id': 'Street',
      'title': 'બંગલો / સોસાયટી',
      'subtitle': 'રો-હાઉસ, ટેનામેન્ટ્સ અને પ્લોટ',
      'icon': Icons.home_work_rounded,
    },
    {
      'id': 'Mixed',
      'title': 'મિક્સ્ડ પરિસર',
      'subtitle': 'રેસિડેન્શિયલ + શોપ્સ કોમ્પ્લેક્સ',
      'icon': Icons.location_city_rounded,
    },
  ];

  @override
  void dispose() {
    _socNameCtrl.dispose();
    _cityCtrl.dispose();
    _adminNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final socName = _socNameCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final adminName = _adminNameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();
      final totalUnits = int.tryParse(_unitsCtrl.text.trim());

      final OnboardSocietyResult result = await SuperAdminService.instance.onboardNewSociety(
        societyName: socName,
        architectureType: _selectedArch,
        city: city,
        adminName: adminName,
        adminPhone: phone,
        adminEmail: email,
        adminPassword: pass,
        totalUnits: totalUnits,
      );

      widget.onSuccess?.call();

      if (!mounted) return;

      if (_sendCredentialsToAdmin) {
        // ઓનબોર્ડ થયા બાદ તુરંત ઈમેલ & WhatsApp ક્રેડેન્શિયલ્સ ડિસ્પેચ મોડલ ખોલવું
        await AdminCredentialsModal.show(context, result: result);
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "'$socName' સફળતાપૂર્વક ઓનબોર્ડ થઈ ગયું છે!",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (mounted) navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('ઓનબોર્ડિંગ એરર: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF14B8A6);
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
          // Ambient Glow
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickSetupBanner(accentColor),
                          const SizedBox(height: 20),

                          _buildSectionHeader('૧. પરિસરની મુખ્ય વિગતો', Icons.apartment_rounded, accentColor),
                          const SizedBox(height: 12),

                          _buildInputField(
                            controller: _socNameCtrl,
                            label: 'સોસાયટી / મોલ / સંકુલનું નામ',
                            hint: 'દા.ત. સિલ્વર હાઇટ્સ રેસિડેન્સી',
                            icon: Icons.business_rounded,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'સોસાયટીનું નામ દાખલ કરવું જરૂરી છે';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildInputField(
                                  controller: _cityCtrl,
                                  label: 'શહેર / જિલ્લો',
                                  hint: 'દા.ત. સુરત',
                                  icon: Icons.location_on_rounded,
                                  accentColor: accentColor,
                                  cardBg: cardBg,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'શહેર દાખલ કરો';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildInputField(
                                  controller: _unitsCtrl,
                                  label: 'અંદાજિત એકમો (Units)',
                                  hint: 'દા.ત. 120',
                                  icon: Icons.tag_rounded,
                                  keyboardType: TextInputType.number,
                                  accentColor: accentColor,
                                  cardBg: cardBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildArchSelector(accentColor, cardBg),
                          const SizedBox(height: 24),

                          _buildSectionHeader('૨. પ્રથમ એડમિન / સેક્રેટરી એકાઉન્ટ', Icons.admin_panel_settings_rounded, accentColor),
                          const SizedBox(height: 12),

                          _buildInputField(
                            controller: _adminNameCtrl,
                            label: 'સેક્રેટરી / એડમિનનું પૂરું નામ',
                            hint: 'દા.ત. મહેશભાઈ શાહ',
                            icon: Icons.badge_rounded,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'એડમિનનું નામ દાખલ કરો';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildInputField(
                            controller: _phoneCtrl,
                            label: 'મોબાઈલ નંબર (Phone)',
                            hint: 'દા.ત. 98250 12345',
                            icon: Icons.phone_iphone_rounded,
                            keyboardType: TextInputType.phone,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'મોબાઈલ નંબર દાખલ કરો';
                              if (v.trim().length < 10) return 'માન્ય 10 અંકનો નંબર દાખલ કરો';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildInputField(
                            controller: _emailCtrl,
                            label: 'એડમિન ઈમેલ આઈડી (Email)',
                            hint: 'admin@society.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'ઈમેલ આઈડી દાખલ કરો';
                              if (!v.contains('@')) return 'માન્ય ઈમેલ આઈડી આપો';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildPasswordField(accentColor, cardBg),
                          const SizedBox(height: 18),

                          _buildSendCredentialsToggleCard(accentColor, cardBg),
                          const SizedBox(height: 28),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'નવી સોસાયટી ઓનબોર્ડ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '1-CLICK SETUP',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'પરિસર રજીસ્ટ્રેશન અને પ્રથમ એડમિન ક્રિએશન',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupBanner(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bolt_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ઇન્સ્ટન્ટ ક્લાઉડ સિંક',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'ઓનબોર્ડ થતાં જ સોસાયટી લાઈવ થઈ જશે અને એડમિન આપેલા પાસવર્ડથી સીધા લોગિન થઈ શકશે.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildArchSelector(Color accentColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'પરિસર આર્કિટેક્ચર પ્રકાર (Architecture Type)',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _archTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final arch = _archTypes[index];
            final isSelected = _selectedArch == arch['id'];

            return GestureDetector(
              onTap: () => setState(() => _selectedArch = arch['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withValues(alpha: 0.15) : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        arch['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.white60,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            arch['title'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            arch['subtitle'] as String,
                            style: TextStyle(
                              color: isSelected ? accentColor : Colors.white38,
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        const Text(
          'પ્રારંભિક એડમિન પાસવર્ડ (Default Password)',
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
            if (v == null || v.trim().isEmpty) return 'પાસવર્ડ આપવો જરૂરી છે';
            if (v.trim().length < 6) return 'ઓછામાં ઓછા ૬ અક્ષર જરૂરી';
            return null;
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: cardBg,
            hintText: 'ડિફોલ્ટ પાસવર્ડ દાખલ કરો...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 14, right: 12),
              child: Icon(Icons.key_rounded, color: accentColor, size: 20),
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

  Widget _buildSendCredentialsToggleCard(Color accentColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _sendCredentialsToAdmin
              ? accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _sendCredentialsToAdmin
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: _sendCredentialsToAdmin ? accentColor : Colors.white54,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'એડમિનને લૉગિન વિગતો મોકલો',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ઓનબોર્ડ થતાં જ ઈમેલ & WhatsApp પર ક્રેડેન્શિયલ્સ ડિસ્પેચ કરો',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _sendCredentialsToAdmin,
            activeTrackColor: accentColor,
            onChanged: (val) => setState(() => _sendCredentialsToAdmin = val),
          ),
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
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'સોસાયટી ઓનબોર્ડ & એડમિન બનાવો',
                        style: TextStyle(
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
