import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poll_model.dart';
import '../models/user_model.dart';
import '../services/society_poll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';

class AdminPollsScreen extends StatefulWidget {
  const AdminPollsScreen({super.key});

  @override
  State<AdminPollsScreen> createState() => _AdminPollsScreenState();
}

class _AdminPollsScreenState extends State<AdminPollsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocietyPollService _pollService = SocietyPollService.instance;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await AppFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!, uid);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoadingUser = false);
  }

  String? get _userRestrictedBlock {
    if (_currentUser != null && _currentUser!.isWingAdmin && !_currentUser!.isSuperAdmin) {
      return _currentUser!.blockName ?? _currentUser!.subGroup;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'સોસાયટી ડિજિટલ પોલિંગ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'પારદર્શક નિર્ણય & મતદાન કેન્દ્ર',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_vote_rounded, size: 17),
                      SizedBox(width: 8),
                      Text('સક્રિય પોલ (Active)'),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 17),
                      SizedBox(width: 8),
                      Text('પૂર્ણ / બંધ (Closed)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showCreatePollDialog,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_task_rounded, size: 20),
          label: const Text(
            'નવો પોલ બનાવો',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
        ),
      ),
      body: StreamBuilder<List<PollModel>>(
        stream: _pollService.getPollsStream(blockScope: _userRestrictedBlock),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('ભૂલ આવી: ${snapshot.error}'));
          }

          final allPolls = snapshot.data ?? [];
          final activePolls = allPolls.where((p) => p.isLive).toList();
          final closedPolls = allPolls.where((p) => !p.isLive).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPollList(activePolls, isActiveTab: true),
              _buildPollList(closedPolls, isActiveTab: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPollList(List<PollModel> polls, {required bool isActiveTab}) {
    if (polls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isActiveTab ? Icons.how_to_vote_rounded : Icons.inventory_2_rounded,
                  size: 46,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isActiveTab ? 'હજુ કોઈ સક્રિય પોલ ચાલુ નથી' : 'કોઈ પૂર્ણ થયેલો પોલ નથી',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActiveTab
                    ? 'સોસાયટી કલરકામ, સુરક્ષા કે આયોજન જેવા મહત્વના વિષયો પર સભ્યો પાસેથી ડિજિટલ અભિપ્રાય મેળવવા પોલ શરૂ કરો.'
                    : 'અગાઉ પૂર્ણ થયેલા પોલ અને કમિટીના નિર્ણયો અહીં સંગ્રહિત થશે.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
              if (isActiveTab) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _showCreatePollDialog,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('નવો પોલ બનાવો', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
      itemCount: polls.length,
      itemBuilder: (context, idx) {
        return _buildPollCard(polls[idx]);
      },
    );
  }

  Widget _buildPollCard(PollModel poll) {
    final dateFormat = DateFormat('dd/MM/yyyy • hh:mm a');
    final totalVotes = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: poll.isLive ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: poll.isLive ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges & Actions Menu
            Row(
              children: [
                // Live status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: poll.isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: poll.isLive ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: poll.isLive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        poll.isLive ? 'ચાલુ મતદાન' : 'પૂર્ણ / બંધ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: poll.isLive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Scope badge
                if (poll.targetScope != 'all')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'વિંગ ${poll.targetScope}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                    ),
                  ),

                // Anonymous badge
                if (poll.isAnonymous)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 11, color: Color(0xFFEA580C)),
                        SizedBox(width: 3),
                        Text(
                          'ગુપ્ત મત',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Admin Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'close') {
                      _showClosePollDialog(poll);
                    } else if (val == 'voters') {
                      _showVotersSheet(poll);
                    } else if (val == 'delete') {
                      _confirmDeletePoll(poll);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (poll.isLive)
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Text('મતદાન બંધ કરો'),
                          ],
                        ),
                      ),
                    if (!poll.isAnonymous)
                      const PopupMenuItem(
                        value: 'voters',
                        child: Row(
                          children: [
                            Icon(Icons.groups_rounded, size: 16, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text('મતદારોનું લિસ્ટ'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ડીલીટ કરો', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              poll.title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),

            // Description
            if (poll.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                poll.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Voting Options & Progress Bars
            ...poll.options.map((opt) {
              final pct = totalVotes > 0 ? ((opt.votesCount / totalVotes) * 100).toInt() : 0;
              final frac = totalVotes > 0 ? (opt.votesCount / totalVotes) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            opt.text,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Text(
                          '${opt.votesCount} મત ($pct%)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          poll.isLive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 18, color: Color(0xFFF1F5F9)),

            // Footer (Total Votes & Due Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_rounded, size: 15, color: Color(0xFF0F766E)),
                    const SizedBox(width: 5),
                    Text(
                      'કુલ મતદાન: $totalVotes સભ્યો',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  poll.isLive
                      ? 'અંતિમ: ${dateFormat.format(poll.endDate)}'
                      : 'સમાપ્ત: ${DateFormat('dd/MM/yyyy').format(poll.endDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: poll.isLive ? const Color(0xFFD97706) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            // Resolution remark if present
            if (poll.resolutionSummary != null && poll.resolutionSummary!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ઠરાવ: ${poll.resolutionSummary}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreatePollDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final optionCtrls = [
      TextEditingController(text: 'હા, સંમત છીએ (Yes)'),
      TextEditingController(text: 'ના, અત્યારે જરૂર નથી (No)'),
    ];
    String scope = 'ALL';
    DateTime endDate = DateTime.now().add(const Duration(days: 3));
    bool isAnon = false;
    String eligibility = 'all_members';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'નવો નિર્ણય પોલ બનાવો',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'સભ્યોના ડિજિટલ મતદાન દ્વારા પારદર્શક નિર્ણય',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'પોલ પ્રશ્ન / મુખ્ય વિષય *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'દા.ત. સોસાયટી કલરકામ અને વોટરપ્રૂફિંગ કરાવવું?',
                            prefixIcon: const Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFF0F766E)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        const Text(
                          'વિગત / સમજૂતી (વૈકલ્પિક)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'અંદાજિત ખર્ચ, એજન્ડા કે કોટેશનની વિગત લખો...',
                            prefixIcon: const Icon(Icons.notes_rounded, size: 20, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Options section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'મતદાન વિકલ્પો (Options) *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${optionCtrls.length} વિકલ્પો',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                            if (optionCtrls.length < 5)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0F766E),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    optionCtrls.add(TextEditingController());
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                label: const Text('વિકલ્પ ઉમેરો', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ...List.generate(optionCtrls.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: optionCtrls[i],
                                    decoration: InputDecoration(
                                      hintText: 'વિકલ્પ ${i + 1} (દા.ત. હા / ના)',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ),
                                ),
                                if (optionCtrls.length > 2)
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 17),
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        optionCtrls[i].dispose();
                                        optionCtrls.removeAt(i);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Target Scope
                        if (_userRestrictedBlock == null) ...[
                          const Text(
                            'કોના માટે લાગુ છે? (Target Scope)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: scope,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.groups_rounded, size: 20, color: Color(0xFF0F766E)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('સમગ્ર સોસાયટી (All Society)')),
                              DropdownMenuItem(value: 'A', child: Text('માત્ર વિંગ A')),
                              DropdownMenuItem(value: 'B', child: Text('માત્ર વિંગ B')),
                              DropdownMenuItem(value: 'C', child: Text('માત્ર વિંગ C')),
                            ],
                            onChanged: (v) => setDialogState(() => scope = v ?? 'all'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // End Date Picker
                        const Text(
                          'મતદાન સમાપ્તિ તારીખ & સમય *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                endDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('dd/MM/yyyy (સાંજે ૧૧:૫૯)').format(endDate),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Anonymous Voting Switch Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAnon ? const Color(0xFF0F766E).withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.security_rounded,
                                size: 18,
                                color: isAnon ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                              ),
                            ),
                            title: const Text('ગુપ્ત મતદાન (Anonymous Voting)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            subtitle: const Text('મતદારોનું નામ જાહેર નહીં થાય, માત્ર ટકાવારી દેખાશે', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            value: isAnon,
                            activeThumbColor: const Color(0xFF0F766E),
                            onChanged: (v) => setDialogState(() => isAnon = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final opts = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                        if (title.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('કૃપા કરીને પોલ વિષય લખો.')),
                          );
                          return;
                        }
                        if (opts.length < 2) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('ઓછામાં ઓછા ૨ વિકલ્પો લખવા જરૂરી છે.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        try {
                          await _pollService.createPoll(
                            title: title,
                            description: descCtrl.text.trim(),
                            optionTexts: opts,
                            endDate: endDate,
                            targetScope: scope,
                            voterEligibility: eligibility,
                            isAnonymous: isAnon,
                            createdByName: _currentUser?.name ?? 'Admin',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('નિર્ણય પોલ સફળતાપૂર્વક શરૂ થયો! 🗳️'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ભૂલ આવી: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'મતદાન શરૂ કરો (Publish Poll)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- પોલ બંધ કરવાનો ડાયલોગ ---
  void _showClosePollDialog(PollModel poll) {
    final remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('મતદાન બંધ કરવું છે?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'શું આપ આ પોલનું મતદાન અત્યારે બંધ કરીને આખરી નિર્ણય જાહેર કરવા માંગો છો?',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(
                labelText: 'આખરી ઠરાવ / નિર્ણય નોંધ (વૈકલ્પિક)',
                hintText: 'દા.ત. ૭૨% બહુમતીથી કલરકામ મંજૂર થયું.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pollService.closePoll(
                pollId: poll.id,
                resolutionSummary: remarkCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('પોલ બંધ કરવામાં આવ્યો છે.')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            child: const Text('હા, બંધ કરો'),
          ),
        ],
      ),
    );
  }

  // --- મતદારોનું લિસ્ટ શીટ ---
  void _showVotersSheet(PollModel poll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  const Text('મતદાન કરનાર સભ્યોનું લિસ્ટ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder(
                stream: _pollService.getPollVotersStream(poll.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('હજુ કોઈ મત પડ્યો નથી.'));

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final flat = (d['flatDisplay'] ?? '').toString();
                      final optId = (d['optionId'] ?? '').toString();
                      final option = poll.options.firstWhere(
                        (o) => o.id == optId,
                        orElse: () => const PollOption(id: '', text: 'અજ્ઞાત વિકલ્પ'),
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF0F766E), size: 18),
                        ),
                        title: Text('ફ્લેટ: ${flat.isNotEmpty ? flat : 'સભ્ય'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('પસંદ કરેલ: ${option.text}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E))),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePoll(PollModel poll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('પોલ ડીલીટ કરવો છે?'),
        content: const Text('આ પોલ અને તેનો تمام મતદાન રેકોર્ડ કાયમ માટે દૂર થઈ જશે.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('રદ કરો')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ડીલીટ કરો'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _pollService.deletePoll(poll.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('પોલ ડીલીટ કરવામાં આવ્યો.')),
        );
      }
    }
  }
}
