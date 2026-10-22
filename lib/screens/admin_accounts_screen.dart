import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:building_guard/core/app_firestore.dart';
import '../models/society_expense_model.dart';
import '../services/society_accounts_service.dart';
import '../services/society_accounts_pdf_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final SocietyAccountsService _accountsService = SocietyAccountsService.instance;
  final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
  final dateFmt = DateFormat('dd MMM yyyy');

  String _selectedCategoryKey = 'all';
  String _selectedBlockFilter = 'ALL';
  List<String> _availableBlocks = [];
  SocietyFinancialSummary _summary = SocietyFinancialSummary.empty();
  bool _isLoadingSummary = true;
  int _selectedViewTab = 0; // 0: તારીખવાર ખાતાવહી (Passbook Ledger), 1: ખર્ચ કેટેગરી (Expenses)

  @override
  void initState() {
    super.initState();
    _loadBlocks();
    _loadSummary();
  }

  Future<void> _loadBlocks() async {
    try {
      final snap = await AppFirestore.instance
          .collection('blocks')
          .where('societyId', isEqualTo: SocietyService.instance.societyId)
          .get();
      final blocks = <String>{};
      for (final doc in snap.docs) {
        final raw = (doc.data()['name'] ?? '').toString();
        final clean = SocietyService.instance.logicalBlockName(raw);
        if (clean.isNotEmpty) blocks.add(clean);
      }
      final sorted = blocks.toList()..sort();
      if (mounted) {
        setState(() {
          _availableBlocks = sorted;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final s = await _accountsService.calculateFinancialSummary(
        blockFilter: _selectedBlockFilter,
      );
      if (mounted) {
        setState(() {
          _summary = s;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: 'સોસાયટી હિસાબ & ખર્ચ',
        subtitle: 'તિજોરી ફંડ, આવક & ખર્ચ વ્યવસ્થાપન',
        actions: [
          PremiumAppBarAction(
            icon: Icons.picture_as_pdf_rounded,
            tooltip: 'ઓફિશિયલ PDF હિસાબ',
            color: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFCCFBF1),
            onTap: _openPdfStatement,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'નવો ખર્ચ ઉમેરો',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<List<SocietyExpense>>(
        stream: _accountsService.streamExpenses(blockFilter: _selectedBlockFilter),
        builder: (context, snapshot) {
          final allExpenses = snapshot.data ?? [];
          final filteredExpenses = _selectedCategoryKey == 'all'
              ? allExpenses
              : allExpenses.where((e) => e.categoryKey == _selectedCategoryKey).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await _loadSummary();
            },
            color: const Color(0xFF0F766E),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              children: [
                // ૦. Block / Wing Filter Chips
                if (_availableBlocks.isNotEmpty) ...[
                  _buildBlockFilterChips(),
                  const SizedBox(height: 14),
                ],

                // ૧. 3D Luxury Hero Banner: Net Savings Fund & Live Income/Expense
                _buildTreasuryHeroBanner(),
                const SizedBox(height: 16),

                // ૨. Quick Action Buttons: Export PDF & Add Expense
                _buildActionButtonsRow(allExpenses),
                const SizedBox(height: 16),

                // ૩. Segmented Tab Switch: Passbook Ledger vs Expense Categories
                _buildViewToggle(),
                const SizedBox(height: 16),

                // ૪. Content based on Selected Tab
                if (_selectedViewTab == 0) ...[
                  _buildPassbookLedgerSection(),
                ] else ...[
                  // Filter Header & Category Filter Chips
                  _buildCategoryFilterHeader(allExpenses),
                  const SizedBox(height: 10),
                  _buildCategoryFilterChips(allExpenses),
                  const SizedBox(height: 16),

                  // Expense Ledger Entries
                  if (snapshot.connectionState == ConnectionState.waiting && allExpenses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                      ),
                    )
                  else if (filteredExpenses.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredExpenses.map((expense) => _buildExpenseCard(expense)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockFilterChips() {
    final vocab = SocietyService.instance.vocabulary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            avatar: Icon(
              Icons.domain_rounded,
              size: 15,
              color: _selectedBlockFilter == 'ALL' ? Colors.white : const Color(0xFF0F766E),
            ),
            label: const Text('સમગ્ર પરિસર (All)'),
            selected: _selectedBlockFilter == 'ALL',
            selectedColor: const Color(0xFF0F766E),
            labelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _selectedBlockFilter == 'ALL' ? Colors.white : const Color(0xFF334155),
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: _selectedBlockFilter == 'ALL' ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            ),
            onSelected: (val) {
              if (val) {
                setState(() => _selectedBlockFilter = 'ALL');
                _loadSummary();
              }
            },
          ),
          const SizedBox(width: 8),
          ..._availableBlocks.map((b) {
            final isSelected = _selectedBlockFilter == b;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.apartment_rounded,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF0F766E),
                ),
                label: Text('${vocab.blockShortLabel} $b'),
                selected: isSelected,
                selectedColor: const Color(0xFF0F766E),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedBlockFilter = b);
                    _loadSummary();
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTreasuryHeroBanner() {
    final savings = _summary.currentSavings;
    final isPositive = savings >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Hero Image Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/accounts_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF042F2E)),
              ),
            ),
            // Glassmorphic Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF042F2E).withValues(alpha: 0.88),
                      const Color(0xFF0F766E).withValues(alpha: 0.85),
                      const Color(0xFF0F172A).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_rounded, color: Color(0xFF5EEAD4), size: 14),
                            SizedBox(width: 6),
                            Text(
                              "સોસાયટી તિજોરી ફંડ & બચત",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingSummary)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "વર્તમાન ચોખ્ખી બચત (Current Balance)",
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFmt.format(savings),
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF34D399)),
                                  SizedBox(width: 4),
                                  Text(
                                    "કુલ જમા આવક",
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currencyFmt.format(_summary.totalIncome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFFF87171)),
                                  SizedBox(width: 4),
                                  Text(
                                    "કુલ થયેલ ખર્ચ",
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currencyFmt.format(_summary.totalExpenses),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildActionButtonsRow(List<SocietyExpense> allExpenses) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _showAddExpenseDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "નવો ખર્ચ નોંધો",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: _openPdfStatement,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F766E), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "હિસાબ સ્ટેટમેન્ટ PDF",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterHeader(List<SocietyExpense> allExpenses) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.tune_rounded, size: 16, color: Color(0xFF475569)),
            SizedBox(width: 6),
            Text(
              "કેટેગરી મુજબ ખર્ચ ફિલ્ટર",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        Text(
          "${allExpenses.length} ખર્ચાઓ",
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChips(List<SocietyExpense> allExpenses) {
    final categories = [
      ('all', 'બધા ખર્ચ', Icons.grid_view_rounded, const Color(0xFF0F172A), const Color(0xFFF1F5F9), allExpenses.length),
      ...SocietyExpenseCategory.all.map((c) {
        final count = allExpenses.where((e) => e.categoryKey == c.key).length;
        return (c.key, c.titleGujarati, c.icon, c.color, c.color.withValues(alpha: 0.1), count);
      }),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategoryKey == cat.$1;
          final key = cat.$1;
          final label = cat.$2;
          final icon = cat.$3;
          final color = cat.$4;
          final lightBg = cat.$5;
          final count = cat.$6;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategoryKey = key);
                },
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: isSelected ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.22) : lightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseCard(SocietyExpense exp) {
    final cat = exp.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExpenseDetailsSheet(exp),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 22),
                ),
                const SizedBox(width: 12),
                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (exp.paidTo.isNotEmpty) ...[
                            Text(
                              exp.paidTo,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const Text(" • ", style: TextStyle(color: Color(0xFF94A3B8))),
                          ],
                          Text(
                            dateFmt.format(exp.expenseDate),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Payment Mode Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exp.paymentModeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "- ${currencyFmt.format(exp.amount)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          const Text(
            "કોઈ ખર્ચ મળ્યો નથી",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          const Text(
            "વોચમેન પગાર, સફાઈ ખર્ચ, લાઈટ બિલ કે અન્ય ખર્ચ નોંધવા માટે નીચે આપેલ બટન દબાવો.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // --- Add Expense Dialog / Sheet ---
  void _showAddExpenseDialog() {
    final titleC = TextEditingController();
    final amountC = TextEditingController();
    final payeeC = TextEditingController();
    final notesC = TextEditingController();
    String selectedCategory = 'watchman_salary';
    String selectedPaymentMode = 'cash';
    String selectedScope = 'common';
    String selectedTargetBlock = _availableBlocks.isNotEmpty ? _availableBlocks.first : 'A';
    DateTime selectedDate = DateTime.now();

    final presets = [
      ('વોચમેન પગાર', 'watchman_salary'),
      ('સફાઈ કર્મચારી પગાર', 'cleaning_staff'),
      ('કોમન લાઈટ બિલ', 'electricity_common'),
      ('લિફ્ટ AMC સર્વિસ', 'lift_amc'),
      ('પાણી મોટર / બોરવેલ', 'water_borewell'),
      ('તહેવાર ઉજવણી ખર્ચ', 'festival_celebration'),
      ('સોસાયટી રિપેરિંગ', 'repairs_maintenance'),
      ('બગીચો / માળી', 'gardening'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.add_card_rounded, color: Color(0xFF0F766E), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "સોસાયટી નવો ખર્ચ નોંધો",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Presets Quick Select
                const Text("ઝડપી પસંદગી (Presets):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presets.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(p.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          backgroundColor: selectedCategory == p.$2 ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
                          side: BorderSide(color: selectedCategory == p.$2 ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
                          onPressed: () {
                            setDlgState(() {
                              titleC.text = p.$1;
                              selectedCategory = p.$2;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "ખર્ચ કેટેગરી (Category)",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: SocietyExpenseCategory.all.map((c) {
                    return DropdownMenuItem(
                      value: c.key,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 16, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.titleGujarati, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Title
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: "ખર્ચ શીર્ષક (Title)",
                    hintText: "દા.ત. ઓક્ટોબર વોચમેન પગાર",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "રકમ (Amount ₹)",
                    prefixText: "₹ ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Paid To Payee Name
                TextField(
                  controller: payeeC,
                  decoration: const InputDecoration(
                    labelText: "કોને ચૂકવ્યા? (Payee Name)",
                    hintText: "દા.ત. રમેશભાઈ વોચમેન, ટોરેન્ટ પાવર, ઓટીસ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Mode Selector
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMode,
                        decoration: const InputDecoration(
                          labelText: "ચુકવણી મોડ",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('રોકડ (Cash)')),
                          DropdownMenuItem(value: 'upi', child: Text('UPI / QR')),
                          DropdownMenuItem(value: 'bank_transfer', child: Text('બેંક ટ્રાન્સફર')),
                          DropdownMenuItem(value: 'cheque', child: Text('ચેક (Cheque)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedPaymentMode = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setDlgState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "તારીખ (Date)",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "વિશેષ નોંધ (Optional Notes)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Scope selector (Common vs Block-specific)
                const Text(
                  "ખર્ચ કાર્યક્ષેત્ર (Scope):",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.domain_rounded, size: 14),
                        label: const Text('સમગ્ર પરિસર (કોમન)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: selectedScope == 'common',
                        selectedColor: const Color(0xFFCCFBF1),
                        onSelected: (val) {
                          if (val) setDlgState(() => selectedScope = 'common');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.apartment_rounded, size: 14),
                        label: const Text('ચોક્કસ વિંગ/શેરી', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: selectedScope == 'wing',
                        selectedColor: const Color(0xFFCCFBF1),
                        onSelected: (val) {
                          if (val) setDlgState(() => selectedScope = 'wing');
                        },
                      ),
                    ),
                  ],
                ),
                if (selectedScope == 'wing' && _availableBlocks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _availableBlocks.contains(selectedTargetBlock) ? selectedTargetBlock : _availableBlocks.first,
                    decoration: const InputDecoration(
                      labelText: "કઈ વિંગ / શેરીનો ખર્ચ છે?",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _availableBlocks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedTargetBlock = val);
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      "ખર્ચ સફળતાપૂર્વક સાચવો",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: () async {
                      final title = titleC.text.trim();
                      final amt = double.tryParse(amountC.text.trim()) ?? 0;
                      final payee = payeeC.text.trim();

                      if (title.isEmpty || amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('કૃપા કરીને માન્ય શીર્ષક અને રકમ દાખલ કરો')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);

                      try {
                        await _accountsService.recordExpense(
                          title: title,
                          categoryKey: selectedCategory,
                          amount: amt,
                          expenseDate: selectedDate,
                          paidTo: payee,
                          paymentMode: selectedPaymentMode,
                          notes: notesC.text.trim(),
                          scope: selectedScope,
                          targetBlock: selectedScope == 'common' ? 'ALL' : selectedTargetBlock,
                        );
                        await _loadSummary();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('ખર્ચ સફળતાપૂર્વક ઉમેરાઈ ગયો!'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('ભૂલ: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Expense Details & Delete Sheet ---
  void _showExpenseDetailsSheet(SocietyExpense exp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exp.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
                Text(
                  currencyFmt.format(exp.amount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${exp.category.titleGujarati} (${exp.category.titleEnglish})",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: exp.category.color),
            ),
            const Divider(height: 24),
            _buildDetailRow("ચુકવણી તારીખ:", dateFmt.format(exp.expenseDate)),
            _buildDetailRow("કોને ચૂકવ્યા:", exp.paidTo.isNotEmpty ? exp.paidTo : '-'),
            _buildDetailRow("ચુકવણી મોડ:", exp.paymentModeLabel),
            if (exp.notes.isNotEmpty) _buildDetailRow("નોંધ:", exp.notes),
            _buildDetailRow("નોંધણી કરનાર:", exp.recordedBy.isNotEmpty ? exp.recordedBy : 'Admin'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("ખર્ચ કાઢી નાખો", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('ખર્ચ કાઢી નાખવાની ખાતરી'),
                          content: Text('શું તમે ખરેખર "${exp.title}" (${currencyFmt.format(exp.amount)}) નો હિસાબ રદ કરવા માંગો છો?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('રદ')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('હા, કાઢી નાખો'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _accountsService.deleteExpense(exp.id);
                        await _loadSummary();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedViewTab = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedViewTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: _selectedViewTab == 0 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'તારીખવાર ખાતાવહી',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedViewTab == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedViewTab == 0 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                    if (_summary.ledgerEntries.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _selectedViewTab == 0 ? const Color(0xFFCCFBF1) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_summary.ledgerEntries.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedViewTab == 0 ? const Color(0xFF0F766E) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedViewTab = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedViewTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 16,
                      color: _selectedViewTab == 1 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ખર્ચ કેટેગરી',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedViewTab == 1 ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedViewTab == 1 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassbookLedgerSection() {
    if (_isLoadingSummary && _summary.ledgerEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    if (_summary.ledgerEntries.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0F766E), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'કોઈ નાણાકીય એન્ટ્રી ઉપલબ્ધ નથી',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'જ્યારે સભ્યો મેન્ટેનન્સ જમા કરશે અથવા એડમિન ખર્ચ નોંધશે, ત્યારે તારીખવાર સંપૂર્ણ પાસબુક અહીં દેખાશે.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // Display in reverse chronological order (latest date first) for easy app viewing
    final reversedList = _summary.ledgerEntries.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passbook Header Bar with Opening vs Closing Balance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('શરૂઆતની સિલક', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text('₹ 0', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                ],
              ),
              Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('કુલ જમા / ખર્ચ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '+${currencyFmt.format(_summary.totalIncome)} / -${currencyFmt.format(_summary.totalExpenses)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('વર્તમાન આખર સિલક', style: TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    currencyFmt.format(_summary.currentSavings),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _summary.currentSavings >= 0 ? const Color(0xFF047857) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'પાસબુક એન્ટ્રીઓ (${reversedList.length})',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const Text(
              'નવીનતમ તારીખ પ્રથમ',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...reversedList.map((entry) => _buildPassbookEntryCard(entry)),
      ],
    );
  }

  Widget _buildPassbookEntryCard(SocietyLedgerEntry entry) {
    final isCredit = entry.isCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCredit ? const Color(0xFFA7F3D0).withValues(alpha: 0.6) : const Color(0xFFFECACA).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            size: 14,
                            color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFmt.format(entry.date),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.paymentMode,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${isCredit ? "+" : "-"} ${currencyFmt.format(entry.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (entry.subtitle.isNotEmpty && entry.subtitle != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    entry.categoryLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          // Running Balance bar on that exact date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                top: BorderSide(color: const Color(0xFFDCFCE7).withValues(alpha: 0.8)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                const Text(
                  'તે તારીખે તિજોરી સિલક (Balance):',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  currencyFmt.format(entry.runningBalance),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: entry.runningBalance >= 0 ? const Color(0xFF047857) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdfStatement() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0F766E)),
                ),
                SizedBox(width: 16),
                Text('હિસાબ & પાસબુક લોડ થઈ રહી છે...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final freshSummary = await _accountsService.calculateFinancialSummary(
        blockFilter: _selectedBlockFilter,
      );
      final expenses = await _accountsService.streamExpenses(
        blockFilter: _selectedBlockFilter,
      ).first;
      if (mounted) Navigator.pop(context); // close loader
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SocietyAccountsPdfPreviewScreen(
            summary: freshSummary,
            expenses: expenses,
            societyName: SocietyService.instance.currentSocietyName,
            societyCode: SocietyService.instance.currentSocietyId,
            blockFilter: _selectedBlockFilter,
          ),
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }
}
