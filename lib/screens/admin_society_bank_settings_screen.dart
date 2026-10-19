import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/maintenance_service.dart';

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
  final _signatoryTitleController = TextEditingController(text: 'સોસાયટી પ્રમુખ / ચેરમેન');
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
      _signatoryTitleController.text = settings['signatoryTitle']?.toString() ?? 'સોસાયટી પ્રમુખ / ચેરમેન';
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
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('સોસાયટી બેંક & ડિજિટલ સહી સેટિંગ્સ સફળતાપૂર્વક સાચવવામાં આવ્યા!'),
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
          content: Text('સેવ કરવામાં ભૂલ: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        title: const Text(
          'સોસાયટી બેંક & UPI સેટિંગ્સ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🏦 અધિકૃત બેંક ખાતું',
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
                      payeeText.isNotEmpty ? payeeText : 'સોસાયટી મેન્ટેનન્સ એકાઉન્ટ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      upiText.isNotEmpty ? upiText : 'example@upi',
                      style: const TextStyle(
                        color: Color(0xFF5EEAD4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
                            const Text(
                              'માસિક મેન્ટેનન્સ',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${amtText.isNotEmpty ? amtText : '1500'} / મહિનો',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'છેલ્લી તારીખ',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'દર મહિનાની ${_dueDayController.text.trim()} તારીખ',
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'બેંક & UPI વિગતો',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'મેમ્બર્સ આ UPI ID પર સીધું મેન્ટેનન્સ જમા કરશે',
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
                        labelText: 'સોસાયટી UPI ID (VPA) *',
                        hintText: 'દા.ત. shantivan@sbi અથવા 9876543210@paytm',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF4338CA), size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'UPI ID દાખલ કરવો ફરજિયાત છે';
                        if (!v.contains('@')) return 'સાચો UPI ID દાખલ કરો (દા.ત. name@bank)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _payeeController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        labelText: 'ખાતાધારકનું નામ (Payee Name)',
                        hintText: 'દા.ત. શાંતિવન સોસાયટી મેન્ટેનન્સ',
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
                              labelText: 'ડિફૉલ્ટ માસિક રકમ',
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
                              labelText: 'છેલ્લી તારીખ (Day)',
                              hintText: 'દા.ત. 10',
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
                                      const Text(
                                        'લાઈવ UPI QR ચકાસણી',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'આ QR કોડ દરેક મેમ્બરના મેન્ટેનન્સ પેજ પર ઓટોમેટિક દેખાશે જેથી સીધું પેમેન્ટ કરી શકાય.',
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'અધિકૃત ડિજિટલ સહી & સ્ટેમ્પ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'PDF મેન્ટેનન્સ રસીદ પર આ અસલ સહી અને સીલ છપાશે',
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
                        labelText: 'અધિકૃત વ્યક્તિનું પૂરું નામ',
                        hintText: 'દા.ત. શ્રી હિતેશભાઈ પટેલ',
                        prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0D9488), size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _signatoryTitleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        labelText: 'હોદ્દો / ડેઝિગ્રેશન',
                        hintText: 'દા.ત. સોસાયટી પ્રમુખ / ચેરમેન',
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
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                                      SizedBox(width: 5),
                                      Text(
                                        'સહી સેટ થયેલી છે (Active)',
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
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 15),
                                          SizedBox(width: 4),
                                          Text(
                                            'સહી હટાવો',
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
                                      'હજુ સુધી કોઈ સહી ઉમેરેલ નથી',
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
                                      hasSignature ? 'સહી ફરી દોરો' : 'સહી દોરો',
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
                                      hasSignature ? 'ફોટો બદલો' : 'ફોટો અપલોડ',
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
                _isSaving ? 'સાચવી રહ્યા છીએ...' : 'સેટિંગ્સ સાચવો (Save Settings)',
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
            content: Text('ફોટો પસંદ કરવામાં ભૂલ: $e'),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'અધિકૃત સહી દોરો (Signature)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'બોક્સમાં તમારી સહી આંગળીથી દોરો',
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
                    const Positioned(
                      left: 20,
                      bottom: 16,
                      child: Text(
                        '✕ સહી અહીં કરો (Sign here)',
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
                    label: const Text('સાફ કરો'),
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
                    label: const Text('સહી સાચવો'),
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
