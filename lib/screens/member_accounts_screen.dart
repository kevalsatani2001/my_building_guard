import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/society_expense_model.dart';
import '../services/society_accounts_service.dart';
import '../services/society_accounts_pdf_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_app_bar.dart';

class MemberAccountsScreen extends StatefulWidget {
  const MemberAccountsScreen({super.key});

  @override
  State<MemberAccountsScreen> createState() => _MemberAccountsScreenState();
}

class _MemberAccountsScreenState extends State<MemberAccountsScreen> {
  final SocietyAccountsService _accountsService = SocietyAccountsService.instance;
  final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
  final dateFmt = DateFormat('dd MMM yyyy');

  String _selectedCategoryKey = 'all';
  SocietyFinancialSummary _summary = SocietyFinancialSummary.empty();
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final s = await _accountsService.calculateFinancialSummary();
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
        title: 'સોસાયટી હિસાબ & ફંડ',
        subtitle: 'પારદર્શક તિજોરી બચત & ખર્ચ વિગત',
        actions: [
          PremiumAppBarAction(
            icon: Icons.picture_as_pdf_rounded,
            tooltip: 'PDF હિસાબ જુઓ',
            color: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFCCFBF1),
            onTap: _openPdfStatement,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPdfStatement,
        icon: const Icon(Icons.download_rounded, size: 20),
        label: const Text(
          'હિસાબ સ્ટેટમેન્ટ PDF',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SocietyExpense>>(
        stream: _accountsService.streamExpenses(),
        builder: (context, snapshot) {
          final allExpenses = snapshot.data ?? [];
          final filteredExpenses = _selectedCategoryKey == 'all'
              ? allExpenses
              : allExpenses.where((e) => e.categoryKey == _selectedCategoryKey).toList();

          return RefreshIndicator(
            onRefresh: () async => await _loadSummary(),
            color: const Color(0xFF0F766E),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              children: [
                // ૧. Treasury Balance Hero Banner
                _buildTreasuryHeroBanner(),
                const SizedBox(height: 16),

                // ૨. Category Expense Distribution Carousel / Grid
                _buildCategoryDistributionSection(),
                const SizedBox(height: 18),

                // ૩. Filter Header & Category Filter Chips
                _buildFilterHeader(allExpenses.length),
                const SizedBox(height: 10),
                _buildFilterChips(allExpenses),
                const SizedBox(height: 14),

                // ૪. Detailed Expense Ledger
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
            ),
          );
        },
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
            Positioned.fill(
              child: Image.asset(
                'assets/images/accounts_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF042F2E)),
              ),
            ),
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
                            Icon(Icons.verified_user_rounded, color: Color(0xFF5EEAD4), size: 14),
                            SizedBox(width: 6),
                            Text(
                              "સોસાયટી જાહેર નાણાકીય હિસાબ",
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
                    "સોસાયટીની કુલ બચત (Treasury Fund)",
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
                  const SizedBox(height: 14),
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
                                    "કુલ મેન્ટેનન્સ જમા",
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

  Widget _buildCategoryDistributionSection() {
    if (_summary.categoryTotals.isEmpty) return const SizedBox.shrink();

    final sorted = _summary.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart_rounded, size: 16, color: Color(0xFF0F766E)),
            SizedBox(width: 6),
            Text(
              "મુખ્ય ખર્ચાઓની વહેંચણી (Where Money Goes)",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: sorted.take(6).map((entry) {
              final cat = SocietyExpenseCategory.fromKey(entry.key);
              final percent = _summary.totalExpenses > 0
                  ? ((entry.value / _summary.totalExpenses) * 100).toStringAsFixed(0)
                  : '0';

              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, size: 16, color: cat.color),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "$percent%",
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat.titleGujarati,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFmt.format(entry.value),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader(int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF475569)),
            SizedBox(width: 6),
            Text(
              "વિગતવાર ખર્ચ યાદી (Ledger)",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        Text(
          "$totalCount ખર્ચાઓ",
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<SocietyExpense> allExpenses) {
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
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
            Text(
              "- ${currencyFmt.format(exp.amount)}",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
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
            "કોઈ ખર્ચ નોંધાયેલ નથી",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdfStatement() async {
    final expenses = await _accountsService.streamExpenses().first;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocietyAccountsPdfPreviewScreen(
          summary: _summary,
          expenses: expenses,
          societyName: SocietyService.instance.currentSocietyName,
          societyCode: SocietyService.instance.currentSocietyId,
        ),
      ),
    );
  }
}
