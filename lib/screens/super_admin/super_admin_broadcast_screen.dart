import 'package:flutter/material.dart';
import '../../services/super_admin_service.dart';

class SuperAdminBroadcastScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const SuperAdminBroadcastScreen({super.key, this.onSuccess});

  @override
  State<SuperAdminBroadcastScreen> createState() => _SuperAdminBroadcastScreenState();
}

class _SuperAdminBroadcastScreenState extends State<SuperAdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  String _selectedTarget = 'all';
  String _selectedPriority = 'normal';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _targetOptions = [
    {
      'id': 'all',
      'title': 'તમામ યુઝર્સ (All Users)',
      'subtitle': 'બધા પરિસરોના સભ્યો, દુકાનદારો & એડમિન્સ',
      'icon': Icons.groups_rounded,
    },
    {
      'id': 'admins_only',
      'title': 'માત્ર એડમિનો (Admins Only)',
      'subtitle': 'તમામ સોસાયટી કમિટી & સેક્રેટરીઓ',
      'icon': Icons.admin_panel_settings_rounded,
    },
    {
      'id': 'commercial',
      'title': 'માત્ર કોમર્શિયલ સંકુલો',
      'subtitle': 'શોપિંગ મોલ અને બિઝનેસ હબના યુઝર્સ',
      'icon': Icons.storefront_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await SuperAdminService.instance.sendGlobalBroadcast(
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        targetCategory: _selectedTarget,
        priority: _selectedPriority,
      );

      widget.onSuccess?.call();

      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ સફળતાપૂર્વક મોકલાઈ ગયું!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );

      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text('બ્રોડકાસ્ટ મોકલવામાં ભૂલ: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF38BDF8);
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
          // Ambient Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
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
                          _buildNoticeBanner(accentColor),
                          const SizedBox(height: 22),

                          _buildSectionTitle('કોને મોકલવું? (Target Audience)', Icons.hub_rounded, accentColor),
                          const SizedBox(height: 12),
                          _buildTargetAudienceSelector(accentColor),
                          const SizedBox(height: 22),

                          _buildSectionTitle('સૂચનાની વિગત (Notice Details)', Icons.edit_note_rounded, accentColor),
                          const SizedBox(height: 12),

                          _buildInputField(
                            controller: _titleCtrl,
                            label: 'સૂચના શીર્ષક (Notice Title)',
                            hint: 'દા.ત. સિસ્ટમ મેઈન્ટેનન્સ અથવા અગત્યની જાહેરાત',
                            icon: Icons.title_rounded,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'કૃપા કરીને સૂચના શીર્ષક દાખલ કરો';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _buildInputField(
                            controller: _msgCtrl,
                            label: 'સંદેશો / નોટિસ વિગત (Message Body)',
                            hint: 'બધા યુઝર્સ સુધી પહોંચાડવાનો સંદેશો અહીં વિગતવાર લખો...',
                            icon: Icons.article_rounded,
                            accentColor: accentColor,
                            cardBg: cardBg,
                            maxLines: 4,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'કૃપા કરીને સંદેશો દાખલ કરો';
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          _buildSectionTitle('પ્રાથમિકતા (Priority)', Icons.bolt_rounded, accentColor),
                          const SizedBox(height: 12),
                          _buildPrioritySelector(accentColor),
                          const SizedBox(height: 24),

                          _buildSectionTitle('લાઈવ નોટિફિકેશન પ્રીવ્યૂ (Live Preview)', Icons.visibility_rounded, accentColor),
                          const SizedBox(height: 12),
                          _buildLivePreviewCard(accentColor),
                          const SizedBox(height: 30),

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ',
                      style: const TextStyle(
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
                        'LIVE PUSH',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'તમામ સોસાયટી અને સભ્યો સુધી ઓફિશિયલ નોટિસ મોકલો',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'સુપર એડમિન સેન્ટ્રલ બ્રોડકાસ્ટ સુવિધા',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 3),
                Text(
                  'આ બ્રોડકાસ્ટ પસંદ કરેલા વર્ગના તમામ યુઝર્સને તાત્કાલિક એપ્લિકેશન નોટિફિકેશન તથા એલર્ટ સ્વરૂપે પ્રાપ્ત થશે.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
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
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAudienceSelector(Color accentColor) {
    return Column(
      children: _targetOptions.map((opt) {
        final isSelected = _selectedTarget == opt['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => setState(() => _selectedTarget = opt['id']),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.12) : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? accentColor : Colors.white60,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['title'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt['subtitle'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white60 : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: accentColor, size: 20)
                  else
                    Icon(Icons.radio_button_unchecked_rounded, color: Colors.white24, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector(Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: _buildPriorityChip(
            id: 'normal',
            label: 'સામાન્ય (Normal)',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPriorityChip(
            id: 'urgent',
            label: 'તાકીદનું (Urgent)',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPriority == id;
    return InkWell(
      onTap: () => setState(() => _selectedPriority = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.16) : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(Color accentColor) {
    final title = _titleCtrl.text.trim().isEmpty ? 'સૂચના શીર્ષક અહીં દેખાશે' : _titleCtrl.text.trim();
    final message = _msgCtrl.text.trim().isEmpty
        ? 'તમે જે સંદેશો ટાઇપ કરશો તેનું પ્રીવ્યૂ યુઝર્સના ફોનમાં આ રીતે નજરે પડશે...'
        : _msgCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'BUILDING GUARD • SYSTEM BROADCAST',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'હમણાં જ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedTarget == 'all'
                      ? '👥 તમામ યુઝર્સ'
                      : (_selectedTarget == 'admins_only' ? '🛡️ માત્ર એડમિન્સ' : '🛍️ કોમર્શિયલ'),
                  style: TextStyle(color: accentColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (_selectedPriority == 'urgent') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚠️ URGENT',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    int maxLines = 1,
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
          maxLines: maxLines,
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

  Widget _buildSubmitButton(Color accentColor) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            const Color(0xFF0284C7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ગ્લોબલ બ્રોડકાસ્ટ મોકલો',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
