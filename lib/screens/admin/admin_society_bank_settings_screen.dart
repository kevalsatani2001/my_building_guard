import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/maintenance_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/localization_service.dart';

class AdminSocietyBankSettingsScreen extends StatefulWidget {
  const AdminSocietyBankSettingsScreen({super.key});

  @override
  State<AdminSocietyBankSettingsScreen> createState() => _AdminSocietyBankSettingsScreenState();
}

class _AdminSocietyBankSettingsScreenState extends State<AdminSocietyBankSettingsScreen> {
  final _service = MaintenanceService.instance;
  final _formKey = GlobalKey<FormState>();

  final _upiIdController = TextEditingController();
  final _payeeController = TextEditingController();
  final _defaultAmtController = TextEditingController(text: '1500');
  final _dueDayController = TextEditingController(text: '10');
  final _signatoryNameController = TextEditingController();
  final _signatoryTitleController = TextEditingController(text: 'સોસાયટી પ્રમુખ / ચેરમેન'.tr);
  String? _signatureBase64;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getPaymentSettings();
      _upiIdController.text = settings['upiId']?.toString() ?? '';
      _payeeController.text = settings['upiPayeeName']?.toString() ?? '';
      _defaultAmtController.text = (settings['defaultAmount'] ?? 1500).toString();
      _dueDayController.text = (settings['dueDay'] ?? 10).toString();
      _signatoryNameController.text = settings['signatoryName']?.toString() ?? '';
      _signatoryTitleController.text = settings['signatoryTitle']?.toString() ?? 'સોસાયટી પ્રમુખ / ચેરમેન'.tr;
      _signatureBase64 = settings['signatureBase64']?.toString();
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _payeeController.dispose();
    _defaultAmtController.dispose();
    _dueDayController.dispose();
    _signatoryNameController.dispose();
    _signatoryTitleController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final upi = _upiIdController.text.trim();
    final payee = _payeeController.text.trim();
    final amt = double.tryParse(_defaultAmtController.text.trim()) ?? 1500;
    final day = int.tryParse(_dueDayController.text.trim()) ?? 10;

    setState(() => _isSaving = true);

    try {
      await _service.savePaymentSettings(
        upiId: upi,
        upiPayeeName: payee,
        defaultAmount: amt,
        dueDay: day,
        signatureBase64: _signatureBase64,
        signatoryName: _signatoryNameController.text.trim(),
        signatoryTitle: _signatoryTitleController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('સોસાયટી બેંક & ડિજિટલ સહી સેટિંગ્સ સફળતાપૂર્વક સાચવવામાં આવ્યા!'.tr),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('સેવ કરવામાં ભૂલ: $e'.tr),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// ૧. કડક UPI ID ફોર્મેટ વેલિડેશન (૧૦૦% ફ્રી)
  String? _validateUpiId(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'સોસાયટી UPI ID દાખલ કરવો ફરજિયાત છે'.tr;
    }
    final trimmed = v.trim();
    if (trimmed.contains(' ')) {
      return 'UPI ID માં સ્પેસ (ખાલી જગ્યા) ન હોવી જોઈએ'.tr;
    }
    if (!trimmed.contains('@')) {
      return 'સાચો UPI ID દાખલ કરો (દા.ત. yourname@bank જેમ કે @okhdfcbank, @sbi, @paytm)'.tr;
    }
    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'અમાન્ય UPI ID (માત્ર ૧ વાર @ હોવું જોઈએ)'.tr;
    }
    final prefix = parts[0];
    final handle = parts[1].toLowerCase();

    if (prefix.length < 2) {
      return 'UPI ID નું નામ બહુ નાનું છે (ઓછામાં ઓછા ૨ અક્ષર)'.tr;
    }
    if (handle.isEmpty) {
      return '@ પછી બેંક હેન્ડલ લખો (દા.ત. @sbi, @paytm, @okhdfcbank)'.tr;
    }
    if (handle == 'gmail.com' ||
        handle == 'yahoo.com' ||
        handle == 'outlook.com' ||
        handle == 'hotmail.com' ||
        handle == 'icloud.com') {
      return '⚠️ આ ઈમેલ ID છે! બેંક UPI ID લખો (દા.ત. @okhdfcbank, @sbi, @paytm)'.tr;
    }
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z0-9.\-_]{2,64}$');
    if (!upiRegex.hasMatch(trimmed)) {
      return 'અમાન્ય UPI ID ફોર્મેટ. અયોગ્ય ચિહ્નો હટાવો.'.tr;
    }
    return null;
  }

  /// જાણીતા UPI બેંક/PSP હેન્ડલની ઓળખ (Google Pay, PhonePe, Paytm, SBI, etc.)
  ({String name, IconData icon, Color color})? _detectUpiBank(String upi) {
    final trimmed = upi.trim().toLowerCase();
    if (!trimmed.contains('@')) return null;
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[1].isEmpty) return null;
    final handle = parts[1];

    if (handle.startsWith('okhdfc')) {
      return (name: 'HDFC Bank (Google Pay)', icon: Icons.account_balance_rounded, color: const Color(0xFF004C8F));
    } else if (handle.startsWith('okaxis')) {
      return (name: 'Axis Bank (Google Pay)', icon: Icons.account_balance_rounded, color: const Color(0xFF97144D));
    } else if (handle.startsWith('oksbi')) {
      return (name: 'SBI (Google Pay)', icon: Icons.account_balance_rounded, color: const Color(0xFF280071));
    } else if (handle.startsWith('okicici')) {
      return (name: 'ICICI Bank (Google Pay)', icon: Icons.account_balance_rounded, color: const Color(0xFFF37021));
    } else if (handle == 'paytm' || handle.startsWith('pt')) {
      return (name: 'Paytm Payments Bank', icon: Icons.payment_rounded, color: const Color(0xFF00B9F5));
    } else if (handle == 'ybl' || handle == 'ibl' || handle == 'axl') {
      return (name: 'PhonePe (${handle.toUpperCase()})', icon: Icons.phone_android_rounded, color: const Color(0xFF5F259F));
    } else if (handle == 'upi' || handle == 'bhimsbi') {
      return (name: 'BHIM UPI', icon: Icons.verified_user_rounded, color: const Color(0xFF00796B));
    } else if (handle == 'kotak') {
      return (name: 'Kotak Mahindra Bank', icon: Icons.account_balance_rounded, color: const Color(0xFFED1C24));
    } else if (handle == 'icici') {
      return (name: 'ICICI Bank', icon: Icons.account_balance_rounded, color: const Color(0xFFF37021));
    } else if (handle == 'sbi') {
      return (name: 'State Bank of India', icon: Icons.account_balance_rounded, color: const Color(0xFF280071));
    } else if (handle == 'barodampay' || handle == 'bob') {
      return (name: 'Bank of Baroda', icon: Icons.account_balance_rounded, color: const Color(0xFFF26522));
    } else if (handle == 'pnb') {
      return (name: 'Punjab National Bank', icon: Icons.account_balance_rounded, color: const Color(0xFFA21D21));
    } else if (handle == 'postbank' || handle == 'ippb') {
      return (name: 'India Post Payments Bank', icon: Icons.account_balance_rounded, color: const Color(0xFFB71C1C));
    }

    if (RegExp(r'^[a-zA-Z0-9.\-_]{2,64}$').hasMatch(handle)) {
      return (name: 'માન્ય UPI હેન્ડલ (@$handle)'.tr, icon: Icons.verified_rounded, color: const Color(0xFF0D9488));
    }
    return null;
  }

  /// ૨. વિકલ્પ ૨: "UPI એપમાં ચકાસો (Test VPA)" — ૧૦૦% ફ્રી લાઈવ બેંક નેમ ચેક
  Future<void> _testUpiInApp() async {
    final upi = _upiIdController.text.trim();
    final payee = _payeeController.text.trim();

    final validationError = _validateUpiId(upi);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(validationError)),
            ],
          ),
          backgroundColor: Colors.deepOrange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // UPI ID આપોઆપ ક્લિપબોર્ડમાં કૉપી કરી લેવો જેથી ગૂગલ પે / ફોનપે માં સીધું પેસ્ટ કરી શકાય
    await Clipboard.setData(ClipboardData(text: upi));
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'UPI એપમાં બેંક નામ ચકાસો'.tr,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: Color(0xFF0F766E), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upi,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'UPI ID ક્લિપબોર્ડમાં કૉપી થઈ ગયો છે'.tr,
                              style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: Color(0xFF0F766E), size: 18),
                    tooltip: 'કૉપી કરો'.tr,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upi));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('UPI ID કૉપી થઈ ગયો!'.tr),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            Text(
              '💡 બેંકમાં રજીસ્ટર્ડ સાચું નામ કેવી રીતે જોવું? (૧૦૦% ફ્રી)'.tr,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 8),
            Text(
              '૧. નીચે "UPI એપ ખોલો" દબાવતા Google Pay / PhonePe ખુલશે.\n'.tr +
              '૨. એપમાં "Pay UPI ID" અથવા Search બારમાં આ કૉપી કરેલ ID Paste કરો.\n'.tr +
              '૩. NPCI બેંક સર્વર સીધું જ રજીસ્ટર્ડ બેંક ખાતાધારકનું સાચું નામ (Verified Name) બતાવશે.\n'.tr +
              '૪. નામ ચકાસ્યા પછી પેમેન્ટ કરવાની જરૂર નથી — સીધા પાછા આવી અહીં સેવ કરી લો.'.tr,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('રદ કરો'.tr, style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text('UPI એપ ખોલો'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final effectivePayee = payee.isNotEmpty ? payee : 'Society Maintenance';
    final uri = Uri.parse(
      'upi://pay?pa=$upi&pn=${Uri.encodeComponent(effectivePayee)}&cu=INR&tn=Account%20Verification',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'તમારા ફોનમાં કોઈ UPI એપ (GPay/PhonePe/Paytm) ખૂલી શકી નહીં. નીચે રહેલા QR કોડને બીજા ફોનથી સ્કેન કરીને પણ ચકાસી શકો છો.'.tr,
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('UPI એપ ખોલવામાં ભૂલ: $e'.tr),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  InputDecoration _inputDeco({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4338CA)),
        ),
      );
    }

    final upiText = _upiIdController.text.trim();
    final payeeText = _payeeController.text.trim();
    final amtText = _defaultAmtController.text.trim();
    final hasSignature = _signatureBase64 != null && _signatureBase64!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'સોસાયટી બેંક & UPI સેટિંગ્સ'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguageSwitchButton()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LIVE FINTECH BANK CARD PREVIEW
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF3730A3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3730A3).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🏦 અધિકૃત બેંક ખાતું'.tr,
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.contactless_rounded, color: Colors.white70, size: 26),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      payeeText.isNotEmpty ? payeeText : 'સોસાયટી ખાતાધારકનું નામ'.tr,
                      style: TextStyle(
                        color: payeeText.isNotEmpty ? Colors.white : Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        fontStyle: payeeText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      upiText.isNotEmpty ? upiText : 'yourname@bank',
                      style: TextStyle(
                        color: upiText.isNotEmpty ? const Color(0xFF5EEAD4) : Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: upiText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'માસિક મેન્ટેનન્સ'.tr,
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${amtText.isNotEmpty ? amtText : '1500'} / મહિનો'.tr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'છેલ્લી તારીખ'.tr,
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'દર મહિનાની ${_dueDayController.text.trim()} તારીખ'.tr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. BANK & PAYMENT CONFIGURATION CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF4338CA), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'બેંક & UPI વિગતો'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'મેમ્બર્સ આ UPI ID પર સીધું મેન્ટેનન્સ જમા કરશે'.tr,
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _upiIdController,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDeco(
                        labelText: 'સોસાયટી UPI ID (VPA) *'.tr,
                        hintText: 'દા.ત. yourname@bank (જેમ કે @okhdfcbank, @sbi, @paytm)'.tr,
                        prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF4338CA), size: 20),
                      ),
                      validator: _validateUpiId,
                    ),

                    // ૧. લાઈવ ફોર્મેટ & બેંક ડિટેક્શન સ્ટેટસ બેજ
                    Builder(
                      builder: (context) {
                        if (upiText.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: Colors.blueGrey.shade400),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ઉદાહરણ ફોર્મેટ: societyname@bank, secretary@paytm, name@okhdfcbank'.tr,
                                    style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final validationErr = _validateUpiId(upiText);
                        if (validationErr != null) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 15, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    validationErr,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bankInfo = _detectUpiBank(upiText);
                        return Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '✓ માન્ય UPI ફોર્મેટ • ${bankInfo?.name ?? "માન્ય બેંક VPA"}'.tr,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // ૨. "UPI એપમાં ખાતું ચકાસો (Test VPA)" Action Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _testUpiInApp,
                        icon: const Icon(Icons.verified_outlined, size: 17, color: Color(0xFF0F766E)),
                        label: Text(
                          'UPI એપમાં ખાતું ચકાસો (Test VPA — ૧૦૦% ફ્રી)'.tr,
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                          side: const BorderSide(color: Color(0xFF14B8A6), width: 1.2),
                          backgroundColor: const Color(0xFFF0FDFA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _payeeController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        labelText: 'ખાતાધારકનું નામ (Payee Name)'.tr,
                        hintText: 'દા.ત. સોસાયટીનું નામ / ખાતાધારકનું નામ'.tr,
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF4338CA), size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _defaultAmtController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDeco(
                              labelText: 'ડિફૉલ્ટ માસિક રકમ'.tr,
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _dueDayController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: _inputDeco(
                              labelText: 'છેલ્લી તારીખ (Day)'.tr,
                              hintText: 'દા.ત. 10'.tr,
                              prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4338CA), size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (upiText.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: 'upi://pay?pa=$upiText&pn=${Uri.encodeComponent(payeeText)}',
                                version: QrVersions.auto,
                                size: 74,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'લાઈવ UPI QR ચકાસણી'.tr,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'આ QR કોડ દરેક મેમ્બરના મેન્ટેનન્સ પેજ પર ઓટોમેટિક દેખાશે જેથી સીધું પેમેન્ટ કરી શકાય.'.tr,
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. AUTHORIZED DIGITAL SIGNATURE & SEAL CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.draw_rounded, color: Color(0xFF0D9488), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'અધિકૃત ડિજિટલ સહી & સ્ટેમ્પ'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'PDF મેન્ટેનન્સ રસીદ પર આ અસલ સહી અને સીલ છપાશે'.tr,
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _signatoryNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        labelText: 'અધિકૃત વ્યક્તિનું પૂરું નામ'.tr,
                        hintText: 'દા.ત. શ્રી હિતેશભાઈ પટેલ'.tr,
                        prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0D9488), size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _signatoryTitleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        labelText: 'હોદ્દો / ડેઝિગ્રેશન'.tr,
                        hintText: 'દા.ત. સોસાયટી પ્રમુખ / ચેરમેન'.tr,
                        prefixIcon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF0D9488), size: 20),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SIGNATURE STUDIO CANVAS BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasSignature) ...[
                            // Header of Active Signature: Status Badge + Delete Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                                      SizedBox(width: 5),
                                      Text(
                                        'સહી સેટ થયેલી છે (Active)'.tr,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => _signatureBase64 = null),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 15),
                                          SizedBox(width: 4),
                                          Text(
                                            'સહી હટાવો'.tr,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Crisp Signature Preview Canvas
                            Container(
                              height: 100,
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.memory(
                                  base64Decode(_signatureBase64!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            // Placeholder Canvas when empty
                            Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.gesture_rounded, color: Colors.grey.shade400, size: 24),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'હજુ સુધી કોઈ સહી ઉમેરેલ નથી'.tr,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Action Buttons: Symmetrical 50-50 Row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: _openSignaturePad,
                                    icon: const Icon(Icons.draw_rounded, size: 17),
                                    label: Text(
                                      hasSignature ? 'સહી ફરી દોરો'.tr : 'સહી દોરો'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D9488),
                                      backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.05),
                                      side: const BorderSide(color: Color(0xFF0D9488), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: _pickSignatureImage,
                                    icon: const Icon(Icons.photo_library_outlined, size: 17),
                                    label: Text(
                                      hasSignature ? 'ફોટો બદલો'.tr : 'ફોટો અપલોડ'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4338CA),
                                      backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.05),
                                      side: const BorderSide(color: Color(0xFF4338CA), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // 4. STICKY BOTTOM SAVE ACTION BAR
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF312E81)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              label: Text(
                _isSaving ? 'સાચવી રહ્યા છીએ...'.tr : 'સેટિંગ્સ સાચવો (Save Settings)'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSignaturePad() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const SignatureDrawDialog(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _signatureBase64 = result;
      });
    }
  }

  Future<void> _pickSignatureImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 250,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _signatureBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ફોટો પસંદ કરવામાં ભૂલ: $e'.tr),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// સહી દોરવા માટે ઇન્ટરેક્ટિવ કેનવાસ ડાયલોગ
class SignatureDrawDialog extends StatefulWidget {
  const SignatureDrawDialog({super.key});

  @override
  State<SignatureDrawDialog> createState() => _SignatureDrawDialogState();
}

class _SignatureDrawDialogState extends State<SignatureDrawDialog> {
  final List<List<Offset>> _lines = [];
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.draw_rounded, color: Color(0xFF0D9488), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'અધિકૃત સહી દોરો (Signature)'.tr,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'બોક્સમાં તમારી સહી આંગળીથી દોરો'.tr,
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drawing Canvas Area with Background guideline
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Visual guideline for signing
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 36,
                      child: Container(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 16,
                      child: Text(
                        '✕ સહી અહીં કરો (Sign here)'.tr,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Gesture Detector with RepaintBoundary
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _lines.add([details.localPosition]);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          if (_lines.isNotEmpty) {
                            _lines.last.add(details.localPosition);
                          }
                        });
                      },
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: CustomPaint(
                          painter: _SignaturePainter(lines: _lines),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _lines.isEmpty ? null : () => setState(() => _lines.clear()),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('સાફ કરો'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _lines.isEmpty ? null : _saveSignature,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('સહી સાચવો'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSignature() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final base64String = base64Encode(byteData.buffer.asUint8List());
      if (mounted) {
        Navigator.pop(context, base64String);
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;

  _SignaturePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.length == 1) {
        canvas.drawCircle(line.first, 1.6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path();
        path.moveTo(line.first.dx, line.first.dy);
        for (int i = 1; i < line.length; i++) {
          path.lineTo(line[i].dx, line[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
