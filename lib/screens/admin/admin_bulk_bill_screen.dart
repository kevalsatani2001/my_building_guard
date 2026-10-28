import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/maintenance_service.dart';
import '../../services/society_service.dart';
import '../../models/premise_type.dart';
import '../../core/app_firestore.dart';
import '../../l10n/app_strings.dart';
import '../../services/localization_service.dart';

class AdminBulkBillScreen extends StatefulWidget {
  final String initialMonth;
  final String? architectureType;

  const AdminBulkBillScreen({
    super.key,
    required this.initialMonth,
    this.architectureType,
  });

  @override
  State<AdminBulkBillScreen> createState() => _AdminBulkBillScreenState();
}

class _AdminBulkBillScreenState extends State<AdminBulkBillScreen> {
  final MaintenanceService _service = MaintenanceService.instance;
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

  late String _selectedMonth;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _festivalTitleController;
  late TextEditingController _festivalAmtController;

  // પરિસર પ્રકાર (કોઈ મેન્યુઅલ સ્વિચિંગ નથી - સોસાયટી આર્કિટેક્ચર મુજબ ઓટોમેટેડ)
  late String _premiseType; // 'Commercial', 'Mixed', 'Wing', 'Street'
  String _billingMode = 'sqft'; // 'sqft' (ચોરસ ફૂટ મુજબ) અથવા 'fixed' (ફિક્સ દર)
  late TextEditingController _ratePerSqFtController;
  String _targetCategory = 'all'; // 'all', 'commercial', 'residential'
  String _targetBlock = 'all'; // 'all' અથવા ચોક્કસ બ્લોક ID
  List<String> _availableBlocks = [];

  // મિક્સ્ડ મોડ સ્પ્લિટ રેટ
  bool _useDifferentiatedRates = false;
  late TextEditingController _commercialRateController;
  late TextEditingController _residentialRateController;

  // ૧૮% GST ટેક્સ ઓપ્શન (કોમર્શિયલ અને મિક્સ્ડ માટે)
  bool _applyGst = false;
  late TextEditingController _gstinController;

  // તહેવાર / વિશેષ ફાળો
  bool _addFestivalCharge = false;
  late DateTime _dueDate;
  bool _isLoading = false;

  // લાઇવ યુનિટ્સ ડેટાબેઝ કાઉન્ટ્સ
  int _totalUnitsCount = 0;
  int _commercialUnitsCount = 0;
  int _residentialUnitsCount = 0;
  double _totalSqFt = 0.0;
  List<Map<String, dynamic>> _allUnits = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _premiseType = _normalizeArchType(widget.architectureType ?? SocietyService.instance.architectureType);

    _titleController = TextEditingController(
      text: '${_formatMonthDisplay(_selectedMonth)} મેન્ટેનન્સ'.tr,
    );
    _amountController = TextEditingController(text: '1500');
    _ratePerSqFtController = TextEditingController(text: '5.0');
    _commercialRateController = TextEditingController(text: '2500');
    _residentialRateController = TextEditingController(text: '1500');
    _gstinController = TextEditingController();
    _festivalTitleController = TextEditingController(
      text: _defaultFestivalTitle(),
    );
    _festivalAmtController = TextEditingController(text: '500');

    // આર્કિટેક્ચર મુજબ ડિફોલ્ટ સેટિંગ્સ
    _configureForPremise();

    // બુદ્ધિશાળી Due Date સેટિંગ: વર્તમાન તારીખથી આગળની તારીખ ડિફોલ્ટ રાખવી
    _calculateSmartDueDate();

    _loadInitialSettings();
    _fetchUnitsAndBlocks();

    _amountController.addListener(_onFieldChanged);
    _ratePerSqFtController.addListener(_onFieldChanged);
    _commercialRateController.addListener(_onFieldChanged);
    _residentialRateController.addListener(_onFieldChanged);
    _festivalAmtController.addListener(_onFieldChanged);
  }

  void _calculateSmartDueDate() {
    final parts = _selectedMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? DateTime.now().month;
    final now = DateTime.now();

    final lastDayOfMonth = DateTime(year, month + 1, 0);
    DateTime defaultDueDate = DateTime(year, month, 10);

    // જો 10 તારીખ પહેલેથી જ વીતી ગઈ હોય તો મહિનાનો અંત અથવા આજથી 10 દિવસ પછી રાખો
    if (defaultDueDate.isBefore(now)) {
      if (lastDayOfMonth.isAfter(now)) {
        defaultDueDate = lastDayOfMonth;
      } else {
        defaultDueDate = now.add(const Duration(days: 10));
      }
    }
    _dueDate = defaultDueDate;
  }

  String _normalizeArchType(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'commercial' || s == 'shopping' || s == 'mall' || s == 'market') {
      return 'Commercial';
    }
    if (s == 'mixed') {
      return 'Mixed';
    }
    if (s == 'street' || s == 'rowhouse' || s == 'tenement' || s == 'bungalow') {
      return 'Street';
    }
    return 'Wing';
  }

  void _configureForPremise() {
    if (_premiseType == 'Commercial') {
      _billingMode = 'sqft';
      _targetCategory = 'commercial';
      _useDifferentiatedRates = false;
      _titleController.text = '${_formatMonthDisplay(_selectedMonth)} શોપ મેન્ટેનન્સ'.tr;
    } else if (_premiseType == 'Mixed') {
      _billingMode = 'fixed';
      _targetCategory = 'all';
      _useDifferentiatedRates = true;
      _titleController.text = '${_formatMonthDisplay(_selectedMonth)} મેન્ટેનન્સ'.tr;
    } else if (_premiseType == 'Street') {
      _billingMode = 'fixed';
      _targetCategory = 'residential';
      _useDifferentiatedRates = false;
      _applyGst = false;
      _titleController.text = '${_formatMonthDisplay(_selectedMonth)} સોસાયટી મેન્ટેનન્સ'.tr;
    } else {
      // Wing / Flat
      _billingMode = 'fixed';
      _targetCategory = 'residential';
      _useDifferentiatedRates = false;
      _applyGst = false;
      _titleController.text = '${_formatMonthDisplay(_selectedMonth)} મેન્ટેનન્સ'.tr;
    }
  }

  String _defaultFestivalTitle() {
    if (_premiseType == 'Commercial') {
      return 'દિવાળી ડેકોરેશન / સુરક્ષા ફાળો'.tr;
    } else if (_premiseType == 'Street') {
      return 'સોસાયટી ઉત્સવ / વિકાસ ફાળો'.tr;
    }
    return 'ગણેશ મહોત્સવ / નવરાત્રિ ફાળો'.tr;
  }

  String get _targetUnitSingular {
    switch (_premiseType) {
      case 'Commercial':
        return 'દુકાન'.tr;
      case 'Street':
        return 'મકાન'.tr;
      case 'Mixed':
        return 'એકમ'.tr;
      default:
        return 'ફ્લેટ'.tr;
    }
  }

  String get _targetUnitPlural {
    switch (_premiseType) {
      case 'Commercial':
        return 'દુકાનો'.tr;
      case 'Street':
        return 'મકાનો'.tr;
      case 'Mixed':
        return 'એકમો'.tr;
      default:
        return 'ફ્લેટ્સ'.tr;
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChanged);
    _ratePerSqFtController.removeListener(_onFieldChanged);
    _commercialRateController.removeListener(_onFieldChanged);
    _residentialRateController.removeListener(_onFieldChanged);
    _festivalAmtController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _amountController.dispose();
    _ratePerSqFtController.dispose();
    _commercialRateController.dispose();
    _residentialRateController.dispose();
    _gstinController.dispose();
    _festivalTitleController.dispose();
    _festivalAmtController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSettings() async {
    try {
      final sid = SocietyService.instance.societyId;
      var doc = await SocietyService.instance
          .societySettingsDoc(AppFirestore.instance)
          .get();
      if (!doc.exists && sid == SocietyService.kDefaultSocietyId) {
        doc = await AppFirestore.instance
            .collection('settings')
            .doc('society_config')
            .get();
      }

      if (doc.exists) {
        final d = doc.data();
        final rawArch = d?['architectureType']?.toString();
        if (rawArch != null && rawArch.trim().isNotEmpty) {
          final normalized = _normalizeArchType(rawArch);
          if (normalized != _premiseType) {
            _premiseType = normalized;
            SocietyService.instance.setArchitectureType(_premiseType);
            _configureForPremise();
          }
        }
      }

      final settings = await _service.getPaymentSettings();
      final defaultAmt = (settings['defaultAmount'] as num?)?.toDouble() ?? 1500.0;
      final gstin = (settings['gstin'] ?? '').toString();

      if (!mounted) return;
      setState(() {
        if (_premiseType != 'Commercial') {
          _amountController.text = defaultAmt.toStringAsFixed(0);
        }
        if (gstin.isNotEmpty) {
          _gstinController.text = gstin;
          if (_premiseType == 'Commercial' || _premiseType == 'Mixed') {
            _applyGst = true;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchUnitsAndBlocks() async {
    try {
      final sid = SocietyService.instance.societyId;

      // ૧. બ્લોક્સ લાવો
      final bSnap = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: sid)
          .get();
      final bList = bSnap.docs.map((d) {
        final bData = d.data();
        return (bData['name'] ?? (d.id.contains('-') ? d.id.split('-').last : d.id)).toString();
      }).toSet().toList();

      // ૨. યુનિટ્સ લાવો
      final uSnap = await AppFirestore.instance
          .collection('units')
          .where('societyId', isEqualTo: sid)
          .get();

      final units = <Map<String, dynamic>>[];
      int commCount = 0;
      int resCount = 0;
      double totalSqFt = 0.0;

      for (final doc in uSnap.docs) {
        final d = doc.data();
        final unitType = (d['unitType'] ?? 'flat').toString().toLowerCase();
        final cat = (d['category'] ?? '').toString().toLowerCase();
        final sqft = (d['areaSqFt'] as num?)?.toDouble() ?? 0.0;
        final isComm = unitType == 'shop' ||
            unitType == 'office' ||
            unitType == 'showroom' ||
            unitType == 'godown' ||
            cat == 'commercial';

        if (isComm) {
          commCount++;
        } else {
          resCount++;
        }
        totalSqFt += sqft;

        units.add({
          'block': (d['blockName'] ?? '').toString(),
          'unit': (d['unitNumber'] ?? '').toString(),
          'unitType': unitType,
          'areaSqFt': sqft,
          'isCommercial': isComm,
        });
      }

      if (mounted) {
        setState(() {
          _availableBlocks = bList;
          _allUnits = units;
          _totalUnitsCount = units.length;
          _commercialUnitsCount = commCount;
          _residentialUnitsCount = resCount;
          _totalSqFt = totalSqFt;
        });
      }
    } catch (_) {}
  }

  String _formatMonthDisplay(String yyyyMm) {
    try {
      final parts = yyyyMm.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      return DateFormat('MMMM yyyy').format(d);
    } catch (_) {
      return yyyyMm;
    }
  }

  void _changeMonth(int offset) {
    try {
      final parts = _selectedMonth.split('-');
      var year = int.parse(parts[0]);
      var month = int.parse(parts[1]) + offset;

      if (month > 12) {
        month = 1;
        year++;
      } else if (month < 1) {
        month = 12;
        year--;
      }

      final newMonth = '$year-${month.toString().padLeft(2, '0')}';
      setState(() {
        _selectedMonth = newMonth;
        final suffix = _premiseType == 'Commercial'
            ? 'શોપ મેન્ટેનન્સ'.tr
            : (_premiseType == 'Street' ? 'સોસાયટી મેન્ટેનન્સ'.tr : 'મેન્ટેનન્સ'.tr);
        _titleController.text = '${_formatMonthDisplay(newMonth)} $suffix';
        _calculateSmartDueDate();
      });
    } catch (_) {}
  }

  int get _targetedUnitsCount {
    if (_allUnits.isEmpty) return _totalUnitsCount;
    return _allUnits.where((u) {
      if (_premiseType == 'Commercial') {
        // કોમર્શિયલમાં હંમેશા શોપ્સ/ઓફિસ ટાર્ગેટ
      } else if (_premiseType == 'Mixed') {
        if (_targetCategory == 'commercial' && u['isCommercial'] != true) return false;
        if (_targetCategory == 'residential' && u['isCommercial'] == true) return false;
      }
      if (_targetBlock != 'all') {
        final b = u['block'].toString();
        if (b != _targetBlock && SocietyService.instance.logicalBlockName(b) != _targetBlock) {
          return false;
        }
      }
      return true;
    }).length;
  }

  double get _baseAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;
  double get _sqftRate => double.tryParse(_ratePerSqFtController.text.trim()) ?? 0.0;
  double get _commRate => double.tryParse(_commercialRateController.text.trim()) ?? 0.0;
  double get _resRate => double.tryParse(_residentialRateController.text.trim()) ?? 0.0;
  double get _festivalAmount =>
      _addFestivalCharge ? (double.tryParse(_festivalAmtController.text.trim()) ?? 0.0) : 0.0;

  double get _displayRatePerUnit {
    if (_premiseType == 'Commercial') {
      if (_billingMode == 'sqft') {
        return 400 * _sqftRate; // અંદાજિત 400 Sq.Ft સ્ટાન્ડર્ડ શોપ
      }
      return _baseAmount;
    }
    if (_premiseType == 'Mixed') {
      if (_targetCategory == 'commercial') {
        return _commRate > 0 ? _commRate : 2500;
      }
      if (_targetCategory == 'residential') {
        return _resRate > 0 ? _resRate : 1500;
      }
      return _resRate > 0 ? _resRate : _baseAmount;
    }
    return _baseAmount;
  }

  double get _gstAmountPerUnit {
    if (!_applyGst) return 0.0;
    if (_premiseType == 'Commercial') {
      return (_displayRatePerUnit * 18.0) / 100.0;
    }
    if (_premiseType == 'Mixed') {
      if (_targetCategory == 'residential') return 0.0;
      final shopBase = _commRate > 0 ? _commRate : 2500.0;
      return (shopBase * 18.0) / 100.0;
    }
    return 0.0;
  }

  double get _totalPayablePerUnit => _displayRatePerUnit + _gstAmountPerUnit + _festivalAmount;

  double get _projectedTotalRevenue {
    final count = _targetedUnitsCount > 0 ? _targetedUnitsCount : 1;
    if (_premiseType == 'Commercial') {
      if (_billingMode == 'sqft' && _totalSqFt > 0) {
        final baseRevenue = _totalSqFt * _sqftRate;
        final gst = _applyGst ? (baseRevenue * 18.0) / 100.0 : 0.0;
        final fest = _addFestivalCharge ? (_festivalAmount * count) : 0.0;
        return baseRevenue + gst + fest;
      }
      return _totalPayablePerUnit * count;
    }
    if (_premiseType == 'Mixed' && _useDifferentiatedRates) {
      final cCount = _commercialUnitsCount > 0 ? _commercialUnitsCount : 0;
      final rCount = _residentialUnitsCount > 0 ? _residentialUnitsCount : 0;
      double revenue = 0.0;
      if (_targetCategory == 'all' || _targetCategory == 'commercial') {
        final cBase = (_commRate > 0 ? _commRate : 2500.0) * cCount;
        final cGst = _applyGst ? (cBase * 18.0) / 100.0 : 0.0;
        revenue += cBase + cGst;
      }
      if (_targetCategory == 'all' || _targetCategory == 'residential') {
        final rBase = (_resRate > 0 ? _resRate : 1500.0) * rCount;
        revenue += rBase;
      }
      if (_addFestivalCharge) revenue += _festivalAmount * count;
      return revenue > 0 ? revenue : _totalPayablePerUnit * count;
    }
    return _totalPayablePerUnit * count;
  }

  Future<void> _generateBills() async {
    final title = _titleController.text.trim();

    if (_premiseType == 'Commercial' && _billingMode == 'sqft') {
      if (_sqftRate <= 0) {
        _showToast('કૃપા કરીને માન્ય ચોરસ ફૂટ (Sq.Ft) દર દાખલ કરો.'.tr, Colors.orange);
        return;
      }
    } else if (_premiseType == 'Mixed' && _useDifferentiatedRates) {
      if (_commRate <= 0 || _resRate <= 0) {
        _showToast('કૃપા કરીને દુકાન અને ફ્લેટ બંને માટે માન્ય રકમ દાખલ કરો.'.tr, Colors.orange);
        return;
      }
    } else {
      if (_baseAmount <= 0) {
        _showToast('કૃપા કરીને માન્ય રકમ દાખલ કરો.'.tr, Colors.orange);
        return;
      }
    }

    if (title.isEmpty) {
      _showToast('કૃપા કરીને બિલનું શીર્ષક લખો.'.tr, Colors.orange);
      return;
    }

    final festAmt = _festivalAmount;
    final festName = _addFestivalCharge ? _festivalTitleController.text.trim() : '';

    setState(() => _isLoading = true);

    try {
      final result = await _service.generateBulkBills(
        billingMonth: _selectedMonth,
        billTitle: title,
        amount: _baseAmount,
        dueDate: _dueDate,
        festivalCharge: festAmt,
        festivalName: festName,
        billingMode: _billingMode,
        ratePerSqFt: _sqftRate,
        targetCategory: _targetCategory,
        targetBlock: _targetBlock,
        gstRate: _applyGst ? 18.0 : 0.0,
        gstin: _gstinController.text.trim(),
        commercialRate: _useDifferentiatedRates ? _commRate : 0.0,
        residentialRate: _useDifferentiatedRates ? _resRate : 0.0,
      );

      if (!mounted) return;
      _showSuccessDialog(result['created'] ?? 0, result['skipped'] ?? 0);
    } catch (e) {
      if (mounted) {
        _showToast('બિલ જનરેશનમાં ભૂલ: $e'.tr, Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showSuccessDialog(int created, int skipped) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 52),
            ),
            const SizedBox(height: 18),
            Text(
              "બલ્ક બિલ સફળ!".tr,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              "કુલ $created નવા બિલ સફળતાપૂર્વક જનરેટ થયા છે.".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            if (skipped > 0) ...[
              const SizedBox(height: 6),
              Text(
                "($skipped એકમોના બિલ અગાઉથી બનેલા હોવાથી સ્કિપ થયા)".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: Text("મેન્ટેનન્સ હિસાબ જુઓ".tr, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocab = PremiseVocabulary.fromString(_premiseType);
    final isComm = _premiseType == 'Commercial';
    final isMixed = _premiseType == 'Mixed';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ૧. ૩D હીરો સ્લીવર હેડર
              _buildHeroSliverHeader(vocab, isComm, isMixed),

              // ૨. ફોર્મ કન્ટેન્ટ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // કાર્ડ ૧: પરિસર ઓળખ અને સ્કોપ
                      _buildPremiseIdentityCard(vocab),
                      const SizedBox(height: 16),

                      // કાર્ડ ૨: બિલિંગ ચક્ર અને મહિનો
                      _buildBillingCycleCard(),
                      const SizedBox(height: 16),

                      // કાર્ડ ૩: આર્કિટેક્ચર-વિશિષ્ટ દર અને અદ્યતન કેલ્ક્યુલેટર
                      _buildBillingRateCard(vocab),
                      const SizedBox(height: 16),

                      // કાર્ડ ૪: ૧૮% GST ટેક્સ ઓપ્શન (કોમર્શિયલ/મિક્સ્ડ માટે)
                      if (isComm || isMixed) ...[
                        _buildGstTaxCard(),
                        const SizedBox(height: 16),
                      ],

                      // કાર્ડ ૫: ચૂકવણી છેલ્લી તારીખ (Due Date - 100% Overflow Proof)
                      _buildDueDateCard(),
                      const SizedBox(height: 16),

                      // કાર્ડ ૬: તહેવાર / વિશેષ ફાળો
                      _buildFestivalCard(vocab),
                      const SizedBox(height: 18),

                      // કાર્ડ ૭: લાઇવ ડિજિટલ ઇનવોઇસ પ્રીવ્યૂ (Mini Receipt)
                      _buildLiveInvoicePreview(vocab),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ૩. સ્ટીકી બોટમ બાર (Fixed: Never overflows, responsive button text)
          _buildStickyBottomBar(vocab),
        ],
      ),
    );
  }

  Widget _buildHeroSliverHeader(PremiseVocabulary vocab, bool isComm, bool isMixed) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Center(child: LanguageSwitchButton(isDark: true)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/billing_hero.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    const Color(0xFF0F172A).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 5),
                        Text(
                          "${vocab.premiseBadge} બિલિંગ ડેસ્ક".tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (isComm
                        ? "શોપિંગ મોલ બિલિંગ ડેસ્ક".tr
                        : isMixed
                            ? "મિક્સ્ડ કોમ્પ્લેક્સ બિલિંગ ડેસ્ક".tr
                            : (_premiseType == 'Street'
                                ? "સોસાયટી / બંગલો બિલિંગ ડેસ્ક".tr
                                : "રેસિડેન્શિયલ ફ્લેટ બિલિંગ ડેસ્ક".tr)).tr,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isComm
                        ? "દરેક દુકાન / ઓફિસ માટે એરિયા (Sq.Ft) દર & ૧૮% GST ઇન્વોઇસિંગ".tr
                        : isMixed
                            ? "દુકાનો અને ફ્લેટ્સ માટે ડ્યુઅલ સ્પ્લિટ રેટ બિલિંગ એન્જિન".tr
                            : (_premiseType == 'Street'
                                ? "શેરી અને પ્લોટ વાઇઝ બંગલો સોસાયટી મેન્ટેનન્સ બિલિંગ".tr
                                : "સોસાયટી અને ટાવરના તમામ ફ્લેટ્સ માટે ઓટોમેટેડ માસિક બિલિંગ".tr),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
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

  // કાર્ડ ૧: પરિસર ઓળખ અને સ્કોપ
  Widget _buildPremiseIdentityCard(PremiseVocabulary vocab) {
    final isComm = _premiseType == 'Commercial';
    final isMixed = _premiseType == 'Mixed';
    final isStreet = _premiseType == 'Street';

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: isComm
                      ? Icons.storefront_rounded
                      : isMixed
                          ? Icons.apartment_rounded
                          : (isStreet ? Icons.home_work_rounded : Icons.domain_rounded),
                  title: "૧. પરિસર વિગતો અને સ્કોપ".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "કુલ: $_totalUnitsCount $_targetUnitPlural".tr,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // પરિસર આર્કિટેક્ચર સ્ટેટસ બેનર
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F766E).withValues(alpha: 0.08),
                  const Color(0xFF0D9488).withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    isComm
                        ? Icons.shopping_bag_rounded
                        : isMixed
                            ? Icons.business_rounded
                            : (isStreet ? Icons.holiday_village_rounded : Icons.apartment_rounded),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vocab.premiseBadge,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF0F766E)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isComm
                            ? "દરેક શોપ/ઓફિસ માટે કાર્પેટ એરિયા (Sq.Ft) આધારિત કોમર્શિયલ બિલિંગ".tr
                            : isMixed
                                ? "શોપ્સ માટે કોમર્શિયલ દર અને ફ્લેટ્સ માટે રેસિડેન્શિયલ દર".tr
                                : (isStreet
                                    ? "શેરી નં. મુજબ બંગલા / રો-હાઉસ સોસાયટી બિલિંગ".tr
                                    : "ટાવર અને વિંગ્સના તમામ ફ્લેટ્સ માટે નિયમિત બિલિંગ".tr),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // આંકડાકીય હાઇલાઇટ્સ (Stats)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatBadge(
                icon: Icons.tag_rounded,
                label: "કુલ એકમો".tr,
                value: "$_totalUnitsCount",
              ),
              if (isComm && _totalSqFt > 0)
                _buildStatBadge(
                  icon: Icons.square_foot_rounded,
                  label: "કુલ એરિયા".tr,
                  value: "${_totalSqFt.toStringAsFixed(0)} Sq.Ft",
                ),
              if (isMixed) ...[
                _buildStatBadge(
                  icon: Icons.storefront_rounded,
                  label: "દુકાનો".tr,
                  value: "$_commercialUnitsCount",
                ),
                _buildStatBadge(
                  icon: Icons.meeting_room_rounded,
                  label: "ફ્લેટ્સ".tr,
                  value: "$_residentialUnitsCount",
                ),
              ],
              if (!isComm && !isMixed && _availableBlocks.isNotEmpty)
                _buildStatBadge(
                  icon: Icons.layers_rounded,
                  label: vocab.blockShortLabel,
                  value: "${_availableBlocks.length}",
                ),
            ],
          ),

          // મિક્સ્ડ મોડમાં લક્ષ્ય પસંદગી
          if (isMixed) ...[
            const SizedBox(height: 14),
            Text(
              "બિલિંગ લક્ષ્ય (કોના માટે બિલ બનાવવું છે?):".tr,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildScopeSegmentChip(
                    label: "બધા ($_totalUnitsCount)".tr,
                    value: 'all',
                    icon: Icons.select_all_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScopeSegmentChip(
                    label: "દુકાનો ($_commercialUnitsCount)".tr,
                    value: 'commercial',
                    icon: Icons.storefront_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScopeSegmentChip(
                    label: "ફ્લેટ્સ ($_residentialUnitsCount)".tr,
                    value: 'residential',
                    icon: Icons.meeting_room_rounded,
                  ),
                ),
              ],
            ),
          ],

          // બ્લોક / વિંગ / ફ્લોર ફિલ્ટર
          if (_availableBlocks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 18, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ચોક્કસ ${vocab.blockLabel}:".tr,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _targetBlock,
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E), fontSize: 13),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text("તમામ ${vocab.blockLabel}".tr),
                      ),
                      ..._availableBlocks.map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text("${vocab.blockShortLabel} $b"),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _targetBlock = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // કાર્ડ ૨: બિલિંગ ચક્ર અને મહિનો
  Widget _buildBillingCycleCard() {
    final monthDisp = _formatMonthDisplay(_selectedMonth);
    final titleSuggestions = _premiseType == 'Commercial'
        ? [
            '$monthDisp શોપ મેન્ટેનન્સ'.tr,
            'ત્રિમાસિક મેન્ટેનન્સ'.tr,
            'વાર્ષિક કોમર્શિયલ મેન્ટેનન્સ'.tr,
          ]
        : (_premiseType == 'Street'
            ? [
                '$monthDisp સોસાયટી મેન્ટેનન્સ'.tr,
                'ત્રિમાસિક મેન્ટેનન્સ'.tr,
                'વાર્ષિક મેન્ટેનન્સ'.tr,
              ]
            : [
                '$monthDisp મેન્ટેનન્સ'.tr,
                'ત્રિમાસિક મેન્ટેનન્સ'.tr,
                'વાર્ષિક મેન્ટેનન્સ'.tr,
              ]);

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeaderIconTitle(
            icon: Icons.calendar_month_rounded,
            title: "૨. બિલિંગ ચક્ર અને મહિનો".tr,
          ),
          const SizedBox(height: 14),

          // મહિનો નેવિગેટર
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: Color(0xFF0F766E)),
                  onPressed: () => _changeMonth(-1),
                ),
                Column(
                  children: [
                    Text(
                      monthDisp,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "બિલિંગ કોડ: $_selectedMonth".tr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF0F766E)),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // બિલનું શીર્ષક
          TextField(
            controller: _titleController,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'બિલનું શીર્ષક (Title)'.tr,
              hintText: 'દા.ત. $monthDisp મેન્ટેનન્સ'.tr,
              prefixIcon: _inputIcon(Icons.title_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // હાઇ-કોન્ટ્રાસ્ટ પ્રીમિયમ શીર્ષક ચિપ્સ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: titleSuggestions.map((title) {
              return _buildPremiumSelectableChip(
                label: title,
                isSelected: _titleController.text == title,
                onTap: () => setState(() => _titleController.text = title),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // કાર્ડ ૩: આર્કિટેક્ચર મુજબ દર અને ગણતરી પદ્ધતિ
  Widget _buildBillingRateCard(PremiseVocabulary vocab) {
    if (_premiseType == 'Commercial') {
      return _buildCommercialRateCard();
    } else if (_premiseType == 'Mixed') {
      return _buildMixedSplitRateCard();
    } else if (_premiseType == 'Street') {
      return _buildStreetRateCard();
    } else {
      return _buildWingFlatRateCard();
    }
  }

  // ૩-A: શોપિંગ મોલ / કોમર્શિયલ દર કાર્ડ
  Widget _buildCommercialRateCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: Icons.currency_rupee_rounded,
                  title: "૩. કોમર્શિયલ દર ગણતરી".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "લક્ષ્ય: $_targetedUnitsCount દુકાનો".tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // સેગમેન્ટેડ ટેબ સ્વિચર
          _buildSegmentedCalculationBar(
            options: [
              {'mode': 'sqft', 'icon': Icons.straighten_rounded, 'title': 'ચોરસ ફૂટ (Sq.Ft) દર'.tr, 'sub': 'દુકાન એરિયા મુજબ'.tr},
              {'mode': 'fixed', 'icon': Icons.store_rounded, 'title': 'ફિક્સ શોપ દર'.tr, 'sub': 'દરેક માટે સમાન રકમ'.tr},
            ],
            selectedMode: _billingMode,
            onChanged: (mode) => setState(() => _billingMode = mode),
          ),
          const SizedBox(height: 16),

          if (_billingMode == 'sqft') ...[
            // Big Luxury Interactive Rate Display Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "પ્રતિ ચોરસ ફૂટ (Sq.Ft) માસિક દર".tr,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("₹ / Sq.Ft", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F766E))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuickStepButton(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          final current = double.tryParse(_ratePerSqFtController.text) ?? 5.0;
                          if (current > 0.5) {
                            setState(() => _ratePerSqFtController.text = (current - 0.5).toStringAsFixed(1));
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ratePerSqFtController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0F766E), letterSpacing: -0.5),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF0F766E)),
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildQuickStepButton(
                        icon: Icons.add_rounded,
                        onTap: () {
                          final current = double.tryParse(_ratePerSqFtController.text) ?? 5.0;
                          setState(() => _ratePerSqFtController.text = (current + 0.5).toStringAsFixed(1));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ઝડપી Sq.Ft રેટ ચિપ્સ
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [2.5, 3.5, 4.5, 5.0, 6.0, 8.0, 10.0, 12.0].map((rate) {
                return _buildSqFtChip(rate);
              }).toList(),
            ),
            const SizedBox(height: 12),

            // લાઇવ ગણતરી કાર્ડ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.08),
                    const Color(0xFF0D9488).withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calculate_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "લાઇવ ગણતરી ઉદાહરણ (400 Sq.Ft દુકાન):".tr,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "400 Sq.Ft × ₹ ${_sqftRate.toStringAsFixed(rateHasFraction(_sqftRate) ? 2 : 1)} = ${_currency.format((400 * _sqftRate).toInt())} / મહિનો".tr,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ફિક્સ શોપ દર
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E)),
              decoration: InputDecoration(
                labelText: 'નિયમિત રકમ (પ્રતિ દુકાન / ઓફિસ)'.tr,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 0.0,
                    child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E))),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAmountChip(1500),
                _buildAmountChip(2000),
                _buildAmountChip(2500),
                _buildAmountChip(3000),
                _buildAmountChip(5000),
                _buildAmountChip(10000),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool rateHasFraction(double val) => val.truncateToDouble() != val;

  // ૩-B: મિક્સ્ડ સંકુલ સ્પ્લિટ રેટ કાર્ડ
  Widget _buildMixedSplitRateCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: Icons.call_split_rounded,
                  title: "૩. સ્પ્લિટ રેટ ગણતરી".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "લક્ષ્ય: $_targetedUnitsCount એકમ".tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ૧. દુકાન દર (Commercial Shop Rate)
          if (_targetCategory == 'all' || _targetCategory == 'commercial') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "દુકાન દર (પ્રતિ $_targetUnitSingular)".tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commercialRateController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F766E)),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          widthFactor: 0.0,
                          child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F766E))),
                        ),
                      ),
                      hintText: 'દા.ત. 2500'.tr,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [2000.0, 2500.0, 3000.0, 4000.0].map((amt) {
                      final isSelected = _commRate == amt;
                      return _buildPremiumSelectableChip(
                        label: "₹ ${amt.toInt()}",
                        isSelected: isSelected,
                        onTap: () => setState(() => _commercialRateController.text = amt.toInt().toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ૨. ફ્લેટ દર (Residential Flat Rate)
          if (_targetCategory == 'all' || _targetCategory == 'residential') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.meeting_room_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "રેસિડેન્શિયલ ફ્લેટ દર (પ્રતિ ફ્લેટ)".tr,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _residentialRateController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2563EB)),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          widthFactor: 0.0,
                          child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2563EB))),
                        ),
                      ),
                      hintText: 'દા.ત. 1500'.tr,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1000.0, 1500.0, 2000.0, 2500.0].map((amt) {
                      final isSelected = _resRate == amt;
                      return _buildPremiumSelectableChip(
                        label: "₹ ${amt.toInt()}",
                        isSelected: isSelected,
                        onTap: () => setState(() => _residentialRateController.text = amt.toInt().toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ૩-C: રેસિડેન્શિયલ ફ્લેટ દર કાર્ડ
  Widget _buildWingFlatRateCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: Icons.currency_rupee_rounded,
                  title: "૩. ફ્લેટ મેન્ટેનન્સ રકમ".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "લક્ષ્ય: $_targetedUnitsCount ફ્લેટ્સ".tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E)),
            decoration: InputDecoration(
              labelText: 'નિયમિત રકમ (પ્રતિ ફ્લેટ)'.tr,
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 0.0,
                  child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E))),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAmountChip(1000),
              _buildAmountChip(1200),
              _buildAmountChip(1500),
              _buildAmountChip(2000),
              _buildAmountChip(2500),
              _buildAmountChip(3000),
              _buildAmountChip(5000),
            ],
          ),
        ],
      ),
    );
  }

  // ૩-D: રો-હાઉસ / સોસાયટી દર કાર્ડ
  Widget _buildStreetRateCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: Icons.currency_rupee_rounded,
                  title: "૩. સોસાયટી મેન્ટેનન્સ રકમ".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "લક્ષ્ય: $_targetedUnitsCount મકાનો".tr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E)),
            decoration: InputDecoration(
              labelText: 'નિયમિત રકમ (પ્રતિ મકાન / પ્લોટ)'.tr,
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 0.0,
                  child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F766E))),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAmountChip(500),
              _buildAmountChip(800),
              _buildAmountChip(1000),
              _buildAmountChip(1500),
              _buildAmountChip(2000),
              _buildAmountChip(2500),
            ],
          ),
        ],
      ),
    );
  }

  // કાર્ડ ૪: ૧૮% GST ટેક્સ મોડ્યુલ
  Widget _buildGstTaxCard() {
    return _cardContainer(
      borderColor: _applyGst ? const Color(0xFF2563EB).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "૧૮% GST ટેક્સ ઇનવોઇસ ઉમેરો".tr,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      _premiseType == 'Mixed'
                          ? "કોમર્શિયલ શોપ્સ માટે 9% CGST + 9% SGST (ફ્લેટ્સ કરમુક્ત)".tr
                          : "દુકાનો / ઑફિસો માટે 9% CGST + 9% SGST".tr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _applyGst,
                activeTrackColor: const Color(0xFF0F766E),
                onChanged: (val) => setState(() => _applyGst = val),
              ),
            ],
          ),
          if (_applyGst) ...[
            const Divider(height: 22),
            TextField(
              controller: _gstinController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'સોસાયટી / મોલ GSTIN નંબર'.tr,
                hintText: 'દા.ત. 24AAAAA0000A1Z5'.tr,
                prefixIcon: _inputIcon(Icons.badge_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildGstPill("કરપાત્ર રકમ: ${_currency.format(_displayRatePerUnit.toInt())}".tr),
                _buildGstPill("CGST (9%): ${_currency.format(((_displayRatePerUnit * 9) / 100).toInt())}"),
                _buildGstPill("SGST (9%): ${_currency.format(((_displayRatePerUnit * 9) / 100).toInt())}"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGstPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
    );
  }

  // કાર્ડ ૫: છેલ્લી ચૂકવણી તારીખ (Due Date - 100% Overflow Proof)
  Widget _buildDueDateCard() {
    final daysRemaining = _dueDate.difference(DateTime.now()).inDays;
    final isPast = daysRemaining < 0;

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _cardHeaderIconTitle(
                  icon: Icons.event_available_rounded,
                  title: "૪. છેલ્લી તારીખ (Due Date)".tr,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.red.withValues(alpha: 0.1)
                      : const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPast ? "મુદત વીતી ગઈ છે".tr : "બાકી: $daysRemaining દિવસ".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPast ? Colors.red.shade700 : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMMM yyyy').format(_dueDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "તારીખ બદલવા માટે ટેપ કરો".tr,
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFF0F766E), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // સ્માર્ટ ડ્યુ ડેટ પ્રીસેટ ચિપ્સ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDueDatePresetChip("+૭ દિવસ".tr, 7),
              _buildDueDatePresetChip("+૧૦ દિવસ".tr, 10),
              _buildDueDatePresetChip("+૧૫ દિવસ".tr, 15),
              _buildDueDateMonthEndChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueDatePresetChip(String label, int daysToAdd) {
    return InkWell(
      onTap: () {
        setState(() {
          _dueDate = DateTime.now().add(Duration(days: daysToAdd));
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _buildDueDateMonthEndChip() {
    return InkWell(
      onTap: () {
        final parts = _selectedMonth.split('-');
        final year = int.tryParse(parts[0]) ?? DateTime.now().year;
        final month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? DateTime.now().month;
        setState(() {
          _dueDate = DateTime(year, month + 1, 0);
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          "મહિનાનો અંત".tr,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }

  // કાર્ડ ૬: તહેવાર / વિશેષ ફાળો
  Widget _buildFestivalCard(PremiseVocabulary vocab) {
    return _cardContainer(
      borderColor: _addFestivalCharge
          ? const Color(0xFFD97706).withValues(alpha: 0.5)
          : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.celebration_rounded, size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _premiseType == 'Commercial'
                          ? "૫. વિશેષ સુરક્ષા / ડેકોરેશન ફાળો".tr
                          : "૫. તહેવાર / વિશેષ ફાળો ઉમેરો".tr,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      "મેન્ટેનન્સ રસીદમાં ઉત્સવ/વિશેષ ફાળો અલગથી ઉમેરવા માટે".tr,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _addFestivalCharge,
                activeTrackColor: const Color(0xFFD97706),
                onChanged: (val) => setState(() => _addFestivalCharge = val),
              ),
            ],
          ),

          if (_addFestivalCharge) ...[
            const Divider(height: 24),
            TextField(
              controller: _festivalTitleController,
              decoration: InputDecoration(
                labelText: 'ફાળો / પ્રસંગનું નામ'.tr,
                hintText: _defaultFestivalTitle(),
                prefixIcon: _inputIcon(Icons.festival_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFestivalTitleChip(_defaultFestivalTitle()),
                _buildFestivalTitleChip('ગણેશ મહોત્સવ ફાળો'.tr),
                _buildFestivalTitleChip('દિવાળી લાઈટિંગ ફાળો'.tr),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _festivalAmtController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFD97706)),
              decoration: InputDecoration(
                labelText: 'ફાળો રકમ (પ્રતિ $_targetUnitSingular)'.tr,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 0.0,
                    child: Text("₹", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFD97706))),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFestAmountChip(250),
                _buildFestAmountChip(500),
                _buildFestAmountChip(1000),
                _buildFestAmountChip(1500),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // કાર્ડ ૭: લાઇવ ડિજિટલ ઇનવોઇસ પ્રીવ્યૂ (Live Mini Receipt)
  Widget _buildLiveInvoicePreview(PremiseVocabulary vocab) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.receipt_rounded, size: 20, color: Color(0xFF14B8A6)),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "ડિજિટલ ઇનવોઇસ પ્રીવ્યૂ".tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _premiseType == 'Commercial'
                      ? (_billingMode == 'sqft' ? "Sq.Ft બેઝ્ડ રસીદ".tr : "શોપ ફિક્સ રસીદ".tr)
                      : (_premiseType == 'Mixed'
                          ? "હાઇબ્રિડ સ્પ્લિટ રસીદ".tr
                          : "માસિક ડિજિટલ રસીદ".tr),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 22),

          // નિયમિત દર
          _receiptRow(
            _premiseType == 'Commercial' && _billingMode == 'sqft'
                ? "નિયમિત દર (દા.ત. 400 Sq.Ft × ₹ ${_sqftRate.toStringAsFixed(rateHasFraction(_sqftRate) ? 2 : 1)}):".tr
                : "નિયમિત માસિક મેન્ટેનન્સ:".tr,
            _currency.format(_displayRatePerUnit.toInt()),
          ),

          // GST જો ચાલુ હોય
          if (_applyGst) ...[
            const SizedBox(height: 6),
            _receiptRow(
              "૧૮% GST (9% CGST + 9% SGST):".tr,
              "+ ${_currency.format(_gstAmountPerUnit.toInt())}",
              isHighlight: true,
            ),
          ],

          // તહેવાર ફાળો
          if (_addFestivalCharge) ...[
            const SizedBox(height: 6),
            _receiptRow(
              "${_festivalTitleController.text.trim().isEmpty ? 'તહેવાર ફાળો' : _festivalTitleController.text.trim()}:".tr,
              "+ ${_currency.format(_festivalAmount.toInt())}",
              isHighlight: true,
            ),
          ],
          const Divider(color: Colors.white24, height: 22),

          Row(
            children: [
              Expanded(
                child: Text(
                  "કુલ રકમ (પ્રતિ $_targetUnitSingular):".tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currency.format(_totalPayablePerUnit.toInt()),
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // અંદાજિત કલેક્શન
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "અંદાજિત કુલ કલેક્શન ($_targetedUnitsCount $_targetUnitPlural):".tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currency.format(_projectedTotalRevenue.toInt()),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // સ્ટીકી બોટમ બાર (100% Overflow Proof + FittedBox)
  Widget _buildStickyBottomBar(PremiseVocabulary vocab) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "પ્રતિ $_targetUnitSingular:".tr,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _currency.format(_totalPayablePerUnit.toInt()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F766E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateBills,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 20, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$_targetedUnitsCount $_targetUnitPlural માટે જનરેટ કરો".tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Colors.white,
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
        ),
      ),
    );
  }

  // Helper widgets for aesthetics
  Widget _cardContainer({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeaderIconTitle({required IconData icon, required String title}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedCalculationBar({
    required List<Map<String, dynamic>> options,
    required String selectedMode,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedMode == opt['mode'];
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(opt['mode'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)])
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 15,
                          color: isSelected ? Colors.white : const Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt['title'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['sub'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStepButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0F766E)),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0F766E)),
          const SizedBox(width: 5),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSegmentChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _targetCategory == value;
    return InkWell(
      onTap: () => setState(() => _targetCategory = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.amber.shade300 : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Colors.amber.shade300 : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(double amount) {
    final isSelected = _baseAmount == amount;
    return _buildPremiumSelectableChip(
      label: _currency.format(amount.toInt()),
      isSelected: isSelected,
      onTap: () => setState(() => _amountController.text = amount.toInt().toString()),
    );
  }

  Widget _buildSqFtChip(double rate) {
    final isSelected = (_sqftRate - rate).abs() < 0.01;
    final rateLabel = rate.truncateToDouble() == rate ? rate.toInt().toString() : rate.toStringAsFixed(1);
    return _buildPremiumSelectableChip(
      label: "₹ $rateLabel / SqFt",
      isSelected: isSelected,
      onTap: () => setState(() => _ratePerSqFtController.text = rate.toString()),
    );
  }

  Widget _buildFestivalTitleChip(String label) {
    final isSelected = _festivalTitleController.text == label;
    return InkWell(
      onTap: () => setState(() => _festivalTitleController.text = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : Colors.amber.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF78350F),
          ),
        ),
      ),
    );
  }

  Widget _buildFestAmountChip(double amount) {
    final isSelected = _festivalAmount == amount;
    return InkWell(
      onTap: () => setState(() => _festivalAmtController.text = amount.toInt().toString()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : Colors.amber.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          _currency.format(amount.toInt()),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF78350F),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Widget _inputIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
    );
  }
}
