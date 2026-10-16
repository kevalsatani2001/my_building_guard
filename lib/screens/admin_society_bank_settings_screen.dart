import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('સોસાયટી બેંક & UPI સેટિંગ્સ સફળતાપૂર્વક સાચવવામાં આવ્યા!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સેવ કરવામાં ભૂલ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final upiText = _upiIdController.text.trim();
    final payeeText = _payeeController.text.trim();
    final amtText = _defaultAmtController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'સોસાયટી બેંક & UPI સેટિંગ્સ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Live FinTech Credit/Bank Card Preview
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E1B4B),
                    Color(0xFF4338CA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.35),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '🏦 અધિકૃત બેંક ખાતું',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.contactless_rounded, color: Colors.white70, size: 28),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    payeeText.isNotEmpty ? payeeText : 'સોસાયટી મેન્ટેનન્સ એકાઉન્ટ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    upiText.isNotEmpty ? upiText : 'example@upi',
                    style: TextStyle(
                      color: Colors.tealAccent.shade100,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'માસિક રકમ',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          Text(
                            '₹ ${amtText.isNotEmpty ? amtText : '1500'} / મહિનો',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

            // Form Fields
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'બેંક એકાઉન્ટ વિગતો',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'મેમ્બર્સ સીધા આ UPI ID પર ગૂગલ પે, ફોનપે કે પેટીએમ થી મેન્ટેનન્સ જમા કરાવી શકશે.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _upiIdController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'સોસાયટી UPI ID (VPA) *',
                        hintText: 'દા.ત. shantivan@sbi અથવા 9876543210@paytm',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF4338CA)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'UPI ID દાખલ કરવો ફરજિયાત છે';
                        if (!v.contains('@')) return 'સાચો UPI ID દાખલ કરો (દા.ત. name@bank)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _payeeController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'ખાતાધારકનું નામ (Payee Name)',
                        hintText: 'દા.ત. શાંતિવન સોસાયટી મેન્ટેનન્સ',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF4338CA)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _defaultAmtController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'ડિફૉલ્ટ માસિક રકમ',
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                            decoration: InputDecoration(
                              labelText: 'છેલ્લી તારીખ (Day)',
                              hintText: 'દા.ત. 10',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Test QR Code Generator Section
                    if (upiText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: QrImageView(
                                data: 'upi://pay?pa=$upiText&pn=${Uri.encodeComponent(payeeText)}',
                                version: QrVersions.auto,
                                size: 80,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'QR ટેસ્ટ ચકાસણી',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'આ QR મેમ્બરના મેન્ટેનન્સ પેજ પર ઓટોમેટિક દેખાશે.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          _isSaving ? 'સાચવી રહ્યા છીએ...' : 'સેટિંગ્સ સાચવો',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
