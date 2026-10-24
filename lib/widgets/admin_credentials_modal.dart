import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/super_admin_models.dart';
import '../services/admin_credential_dispatcher_service.dart';
import '../services/super_admin_service.dart';
import 'package:building_guard/l10n/app_strings.dart';

class AdminCredentialsModal extends StatefulWidget {
  final OnboardSocietyResult result;

  const AdminCredentialsModal({
    super.key,
    required this.result,
  });

  static Future<void> show(
    BuildContext context, {
    required OnboardSocietyResult result,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminCredentialsModal(result: result),
    );
  }

  @override
  State<AdminCredentialsModal> createState() => _AdminCredentialsModalState();
}

class _AdminCredentialsModalState extends State<AdminCredentialsModal> {
  bool _revealPassword = false;
  bool _isDispatchingEmail = false;
  bool _isDispatchingWa = false;
  bool _isSendingReset = false;

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final dispatcher = AdminCredentialDispatcherService.instance;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF070B14), // Deep Midnight Obsidian
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header with Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "એડમિન લૉગિન ક્રેડેન્શિયલ્સ".tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "પરિસર સફળતાપૂર્વક ઓનબોર્ડ થઈ ગયું છે!".tr,
                          style: TextStyle(
                            color: const Color(0xFF34D399),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Overview Credentials Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.domain_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      label: "પરિસર / સોસાયટી".tr,
                      value: "${res.societyName} (${res.architectureType})",
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildInfoTile(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: "એડમિન નામ & શહેર".tr,
                      value: "${res.adminName} • ${res.city}",
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildCopyableTile(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      label: "લૉગિન ઈમેલ".tr,
                      value: res.adminEmail,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: res.adminEmail));
                        _showToast(context, '📧 ઈમેલ ક્લિપબોર્ડમાં કોપી થયો!'.tr);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildPasswordTile(
                      password: res.adminPassword,
                      onToggle: () => setState(() => _revealPassword = !_revealPassword),
                      isRevealed: _revealPassword,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: res.adminPassword));
                        _showToast(context, '🔑 પાસવર્ડ ક્લિપબોર્ડમાં કોપી થયો!'.tr);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 18),
                    _buildCopyableTile(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF34D399),
                      label: "રજીસ્ટર્ડ મોબાઇલ".tr,
                      value: res.adminPhone,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: res.adminPhone));
                        _showToast(context, '📱 મોબાઇલ ક્લિપબોર્ડમાં કોપી થયો!'.tr);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Auto-Role Detection Tip Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF2DD4BF), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "લૉગિન વખતે એડમિનને કોઈ રોલ સિલેક્ટ કરવાનો નથી — ફક્ત ઈમેલ/મોબાઇલ અને પાસવર્ડ નાખતાં જ સિસ્ટમ ઑટોમેટિક એડમિન રોલ ફેચ કરી લેશે.".tr,
                        style: TextStyle(
                          color: Color(0xFFCCFBF1),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Primary Dispatch Buttons: Email & WhatsApp
              Row(
                children: [
                  // Email Button
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isDispatchingEmail
                              ? null
                              : () async {
                                  setState(() => _isDispatchingEmail = true);
                                  try {
                                    final subject = dispatcher.buildEmailSubject(
                                      societyName: res.societyName,
                                    );
                                    final body = dispatcher.buildEmailBody(
                                      societyName: res.societyName,
                                      architectureType: res.architectureType,
                                      city: res.city,
                                      adminName: res.adminName,
                                      adminEmail: res.adminEmail,
                                      adminPassword: res.adminPassword,
                                      adminPhone: res.adminPhone,
                                    );

                                    final launched = await dispatcher.launchEmailClient(
                                      adminEmail: res.adminEmail,
                                      subject: subject,
                                      body: body,
                                    );

                                    if (context.mounted) {
                                      _showToast(
                                        context,
                                        launched
                                            ? '📧 ઈમેલ એપ ખુલી ગઈ છે! ડ્રાફ્ટ ચકાસી મોકલો.'.tr
                                            : '⚠️ ઈમેલ એપ ન ખુલી, વિગતો ક્લિપબોર્ડમાં કોપી કરી શકો છો.'.tr,
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isDispatchingEmail = false);
                                  }
                                },
                          child: Center(
                            child: _isDispatchingEmail
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "ઈમેલ મોકલો".tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // WhatsApp Button
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isDispatchingWa
                              ? null
                              : () async {
                                  setState(() => _isDispatchingWa = true);
                                  try {
                                    final waMsg = dispatcher.buildWhatsAppMessage(
                                      societyName: res.societyName,
                                      architectureType: res.architectureType,
                                      adminName: res.adminName,
                                      adminEmail: res.adminEmail,
                                      adminPassword: res.adminPassword,
                                      adminPhone: res.adminPhone,
                                    );

                                    final launched = await dispatcher.launchWhatsApp(
                                      phone: res.adminPhone,
                                      message: waMsg,
                                    );

                                    if (context.mounted) {
                                      _showToast(
                                        context,
                                        launched
                                            ? '💬 WhatsApp ચેટ ખુલી રહી છે...'.tr
                                            : '⚠️ WhatsApp ન ખુલી શક્યું.'.tr,
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isDispatchingWa = false);
                                  }
                                },
                          child: Center(
                            child: _isDispatchingWa
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "WhatsApp શેર".tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Secondary Row: Copy All & Native Share
              Row(
                children: [
                  // Copy Complete Letter
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 18),
                      label: Text(
                        "બધું કોપી કરો".tr,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        final body = dispatcher.buildEmailBody(
                          societyName: res.societyName,
                          architectureType: res.architectureType,
                          city: res.city,
                          adminName: res.adminName,
                          adminEmail: res.adminEmail,
                          adminPassword: res.adminPassword,
                          adminPhone: res.adminPhone,
                        );
                        Clipboard.setData(ClipboardData(text: body));
                        _showToast(context, '📋 સંપૂર્ણ ક્રેડેન્શિયલ્સ પત્ર કોપી થઈ ગયો!'.tr);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Native Share
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Color(0xFFF59E0B), size: 18),
                      label: Text(
                        "અન્ય એપમાં શેર".tr,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        final subject = dispatcher.buildEmailSubject(societyName: res.societyName);
                        final body = dispatcher.buildEmailBody(
                          societyName: res.societyName,
                          architectureType: res.architectureType,
                          city: res.city,
                          adminName: res.adminName,
                          adminEmail: res.adminEmail,
                          adminPassword: res.adminPassword,
                          adminPhone: res.adminPhone,
                        );
                        dispatcher.shareCredentials(text: body, subject: subject);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Password Reset Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSendingReset
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                        )
                      : const Icon(Icons.lock_reset_rounded, color: Color(0xFFF59E0B), size: 18),
                  label: Text(
                    "એડમિનના ઈમેલ પર પાસવર્ડ રીસેટ લિંક મોકલો".tr,
                    style: TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _isSendingReset
                      ? null
                      : () async {
                          setState(() => _isSendingReset = true);
                          try {
                            await SuperAdminService.instance.sendAdminPasswordResetEmail(res.adminEmail);
                            if (context.mounted) {
                              _showToast(context, '🔑 ${res.adminEmail} પર પાસવર્ડ રીસેટ લિંક મોકલી દેવાઈ!'.tr);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showToast(context, '⚠️ ભૂલ આવી: $e'.tr);
                            }
                          } finally {
                            if (mounted) setState(() => _isSendingReset = false);
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),

              // Dismiss Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "પૂર્ણ થયું (Done)".tr,
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'કોપી કરો'.tr,
          onPressed: onCopy,
        ),
      ],
    );
  }

  Widget _buildPasswordTile({
    required String password,
    required VoidCallback onToggle,
    required bool isRevealed,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "પ્રારંભિક પાસવર્ડ".tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                password.contains('••')
                    ? '(સુરક્ષા ખાતર એન્ક્રિપ્ટેડ)'.tr
                    : (isRevealed ? password : '••••••••'),
                style: TextStyle(
                  color: password.contains('••') ? const Color(0xFFF59E0B) : Colors.white,
                  fontSize: password.contains('••') ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: password.contains('••') ? 0.5 : 1.2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white60,
            size: 18,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: isRevealed ? 'છુપાવો'.tr : 'જોવો'.tr,
          onPressed: onToggle,
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'કોપી કરો'.tr,
          onPressed: onCopy,
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
