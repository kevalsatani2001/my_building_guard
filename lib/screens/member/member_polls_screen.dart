import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/poll_model.dart';
import '../../models/user_model.dart';
import '../../services/society_poll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/polls/polls_bloc.dart';
import '../../services/society_service.dart';
import '../../services/localization_service.dart';
import '../../l10n/app_strings.dart';

class MemberPollsScreen extends StatefulWidget {
  const MemberPollsScreen({super.key});

  @override
  State<MemberPollsScreen> createState() => _MemberPollsScreenState();
}

class _MemberPollsScreenState extends State<MemberPollsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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
    if (mounted) {
      setState(() => _isLoadingUser = false);
      context.read<PollsBloc>().add(
            PollsSubscriptionRequested(
              societyId: SocietyService.instance.societyId,
            ),
          );
    }
  }

  String get _memberFlatDisplay {
    if (_currentUser == null) return '';
    final block = _currentUser!.blockName ?? _currentUser!.subGroup ?? '';
    final unit = _currentUser!.unitNumber ?? '';
    if (block.isNotEmpty && unit.isNotEmpty) return '$block-$unit';
    return unit.isNotEmpty ? unit : block;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
      );
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 14,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('polls_title'),
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              AppStrings.get('polls_subtitle'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: LanguageSwitchButton(),
          ),
        ],
      ),
      body: BlocBuilder<PollsBloc, PollsState>(
        builder: (context, state) {
          if (state is PollsLoading || state is PollsInitial) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
          }

          final allPolls = (state is PollsLoaded) ? state.polls : <PollModel>[];
          final memberBlock = _currentUser?.blockName ?? _currentUser?.subGroup ?? '';

          // Filter by member's scope
          final eligiblePolls = allPolls.where((p) {
            if (p.targetScope == 'all') return true;
            if (memberBlock.isNotEmpty && p.targetScope == memberBlock) return true;
            return false;
          }).toList();

          final activePolls = eligiblePolls.where((p) => p.isLive).toList();
          final closedPolls = eligiblePolls.where((p) => !p.isLive).toList();

          return Column(
            children: [
              // Hero Banner with 3D Illustration Asset
              _buildHeroHeader(activeCount: activePolls.length, totalCount: eligiblePolls.length),

              // Segmented Capsule TabBar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.how_to_vote_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('${'active_polls_capsule'.tr} (${activePolls.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_edu_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('${'past_decisions_capsule'.tr} (${closedPolls.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPollsTabList(activePolls, currentUid, isActiveTab: true),
                    _buildPollsTabList(closedPolls, currentUid, isActiveTab: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO HEADER BANNER WITH 3D ASSET
  // ---------------------------------------------------------------------------
  Widget _buildHeroHeader({required int activeCount, required int totalCount}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Asset Box
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/polling_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.how_to_vote_rounded,
                  color: Color(0xFF2DD4BF),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 11, color: Color(0xFF2DD4BF)),
                          SizedBox(width: 4),
                          Text(
                            'ડિજિટલ લોકશાહી'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_memberFlatDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _memberFlatDisplay,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'સોસાયટી નિર્ણયોમાં આપનો અવાજ'.tr,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeCount > 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      activeCount > 0
                          ? '$activeCount ${activeCount > 1 ? 'new_polls_available'.tr : 'new_poll_available'.tr}'
                          : 'there_are_currently_no_active_polls'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activeCount > 0 ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB CONTENT BUILDER
  // ---------------------------------------------------------------------------
  Widget _buildPollsTabList(List<PollModel> polls, String currentUid, {required bool isActiveTab}) {
    if (polls.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/images/polling_hero.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      isActiveTab ? Icons.how_to_vote_outlined : Icons.history_edu_outlined,
                      size: 42,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isActiveTab ? 'અત્યારે કોઈ નવું મતદાન ચાલુ નથી.'.tr : 'કોઈ અગાઉના નિર્ણયો નોંધાયેલા નથી.'.tr,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActiveTab
                    ? 'જ્યારે પણ કમિટી તરફથી સોસાયટીના ખર્ચ, સુવિધા કે નિયમો અંગે નવો નિર્ણય લેવાશે ત્યારે આપ અહીંથી મત આપી શકશો.'.tr
                    : 'સમાપ્ત થયેલા તમામ પોલ અને પસાર થયેલા ઠરાવો અહીં સંગ્રહિત થશે.'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: polls.length,
      itemBuilder: (context, idx) {
        final poll = polls[idx];
        return _MemberPollCardItem(
          key: ValueKey(poll.id),
          poll: poll,
          currentUid: currentUid,
          memberFlatDisplay: _memberFlatDisplay,
        );
      },
    );
  }
}

// =============================================================================
// ISOLATED ULTRA-PREMIUM MEMBER POLL CARD WIDGET
// Prevents entire screen / list reload on option selection or vote submission!
// =============================================================================
class _MemberPollCardItem extends StatefulWidget {
  final PollModel poll;
  final String currentUid;
  final String memberFlatDisplay;

  const _MemberPollCardItem({
    super.key,
    required this.poll,
    required this.currentUid,
    required this.memberFlatDisplay,
  });

  @override
  State<_MemberPollCardItem> createState() => _MemberPollCardItemState();
}

class _MemberPollCardItemState extends State<_MemberPollCardItem> {
  final SocietyPollService _pollService = SocietyPollService.instance;
  String? _selectedOptionId;
  bool _isSubmitting = false;
  String? _userVotedOptionId;
  bool _hasLocalVoted = false;

  @override
  void initState() {
    super.initState();
    _checkUserVote();
  }

  @override
  void didUpdateWidget(covariant _MemberPollCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.id != widget.poll.id) {
      _selectedOptionId = null;
      _isSubmitting = false;
      _userVotedOptionId = null;
      _hasLocalVoted = false;
      _checkUserVote();
    }
  }

  void _checkUserVote() {
    final poll = widget.poll;
    final hasVoted = poll.hasUserVoted(widget.currentUid) ||
        (widget.memberFlatDisplay.isNotEmpty && poll.hasFlatVoted(widget.memberFlatDisplay));
    if (hasVoted) {
      _pollService.getUserVotedOptionId(poll.id).then((optId) {
        if (mounted && optId != null) {
          setState(() {
            _userVotedOptionId = optId;
          });
        }
      });
    }
  }

  Future<void> _submitVote() async {
    if (_selectedOptionId == null || _isSubmitting) return;
    final chosenOptId = _selectedOptionId!;

    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.mediumImpact();
      context.read<PollsBloc>().add(
            PollCastVoteRequested(
              pollId: widget.poll.id,
              optionId: chosenOptId,
              flatDisplay: widget.memberFlatDisplay,
            ),
          );

      if (mounted) {
        setState(() {
          _hasLocalVoted = true;
          _userVotedOptionId = chosenOptId;
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 આપનો મત સફળતાપૂર્વક નોંધાઈ ગયો છે! આભાર.'.tr),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ક્ષતિ: $e'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final hasVoted = _hasLocalVoted ||
        poll.hasUserVoted(widget.currentUid) ||
        (widget.memberFlatDisplay.isNotEmpty && poll.hasFlatVoted(widget.memberFlatDisplay));
    final totalVotes = poll.totalVotes;

    // Find max voted option for highlight trophy
    int maxVotes = 0;
    for (final opt in poll.options) {
      if (opt.votesCount > maxVotes) maxVotes = opt.votesCount;
    }

    // Days remaining calculation
    final now = DateTime.now();
    final remaining = poll.endDate.difference(now);
    final isExpired = remaining.isNegative;

    String deadlineText;
    if (isExpired || !poll.isLive) {
      deadlineText = "મતદાન પૂર્ણ".tr;
    } else if (remaining.inDays > 0) {
      deadlineText = "${'remaining'.tr}: ${remaining.inDays} ${'days_label'.tr}";
    } else if (remaining.inHours > 0) {
      deadlineText = "${'remaining'.tr}: ${remaining.inHours} ${'hours_label'.tr}";
    } else {
      deadlineText = "અંતિમ ઘડીઓ".tr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasVoted ? const Color(0xFFE2E8F0) : const Color(0xFF0F766E).withValues(alpha: 0.35),
          width: hasVoted ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status & Badges Strip (Wrap to prevent screen width overflow)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Vote Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: hasVoted
                        ? const Color(0xFFDCFCE7)
                        : (poll.isLive ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasVoted
                          ? const Color(0xFF86EFAC)
                          : (poll.isLive ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasVoted
                            ? Icons.check_circle_rounded
                            : (poll.isLive ? Icons.hourglass_top_rounded : Icons.lock_clock_rounded),
                        size: 13,
                        color: hasVoted
                            ? const Color(0xFF16A34A)
                            : (poll.isLive ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        hasVoted
                            ? 'આપે મત આપી દીધો છે'.tr
                            : (poll.isLive ? 'મતદાન બાકી છે'.tr : 'મતદાન પૂર્ણ થયું'.tr),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasVoted
                              ? const Color(0xFF16A34A)
                              : (poll.isLive ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scope Tag (Wing / All)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: poll.targetScope == 'all' ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: poll.targetScope == 'all' ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Text(
                    poll.targetScope == 'all' ? 'સમગ્ર સોસાયટી'.tr : 'વિંગ ${poll.targetScope}'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: poll.targetScope == 'all' ? const Color(0xFF475569) : const Color(0xFF4338CA),
                    ),
                  ),
                ),

                // Deadline pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired || !poll.isLive ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isExpired || !poll.isLive ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11.5,
                        color: isExpired || !poll.isLive ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        deadlineText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isExpired || !poll.isLive ? const Color(0xFF64748B) : const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Poll Title (Question)
            Text(
              poll.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),

            // Poll Description / Budget Callout (e.g. "15000" in screenshot)
            if (poll.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poll.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // =================================================================
            // CASE 1: IF USER HAS ALREADY VOTED (OR POLL IS CLOSED): LIVE RESULTS
            // =================================================================
            if (hasVoted || !poll.isLive) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, size: 16, color: Color(0xFF0F766E)),
                      SizedBox(width: 6),
                      Text(
                        'મતદાન પરિણામ:'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${'total_label'.tr} $totalVotes ${'votes_label'.tr}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...poll.options.map((opt) {
                final pct = totalVotes > 0 ? ((opt.votesCount / totalVotes) * 100).toInt() : 0;
                final frac = totalVotes > 0 ? (opt.votesCount / totalVotes) : 0.0;
                final isMyVote = opt.id == _userVotedOptionId;
                final isLeading = maxVotes > 0 && opt.votesCount == maxVotes;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMyVote ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMyVote ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: isMyVote ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  opt.text.tr,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isMyVote ? FontWeight.w900 : FontWeight.w700,
                                    color: isMyVote ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (isMyVote)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'આપનો મત'.tr,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (isLeading && totalVotes > 0)
                                  const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFEAB308)),
                              ],
                            ),
                          ),
                          Text(
                            '${opt.votesCount} ($pct%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isMyVote ? const Color(0xFF059669) : const Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Gradient progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Container(
                              height: 9,
                              color: const Color(0xFFE2E8F0),
                            ),
                            FractionallySizedBox(
                              widthFactor: frac,
                              child: Container(
                                height: 9,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isMyVote
                                        ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                        : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(height: 18, color: Color(0xFFF1F5F9)),

              // Timestamp footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    poll.isLive ? 'મતદાન પ્રક્રિયા ચાલુ છે'.tr : 'મતદાન પૂર્ણ થયેલ છે'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: poll.isLive ? const Color(0xFF059669) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${'deadline_label'.tr}: ${dateFormat.format(poll.endDate)}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              // Resolution if available
              if (poll.resolutionSummary != null && poll.resolutionSummary!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'સોસાયટી સત્તાવાર ઠરાવ:'.tr,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              poll.resolutionSummary!,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]

            // =================================================================
            // CASE 2: IF USER HAS NOT VOTED YET: INTERACTIVE DECISION CARDS
            // =================================================================
            else ...[
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF0F766E)),
                  SizedBox(width: 6),
                  Text(
                    'આપનો વિકલ્પ પસંદ કરો:'.tr,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '(૧ મત પ્રતિ ફ્લેટ)'.tr,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Options
              ...poll.options.map((opt) {
                final isSelected = _selectedOptionId == opt.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedOptionId = opt.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Custom Animated Radio Icon
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Option Text
                            Expanded(
                              child: Text(
                                opt.text.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),

              // Elevated Gradient Submit Vote Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedOptionId == null || _isSubmitting
                      ? null
                      : () => _submitVote(),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.how_to_vote_rounded, size: 18),
                  label: Text(
                    _isSubmitting
                        ? 'મત નોંધાઈ રહ્યો છે...'.tr
                        : (_selectedOptionId == null
                            ? 'પહેલાં વિકલ્પ પસંદ કરો'.tr
                            : 'મત આપો (Submit Vote)'.tr),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: _selectedOptionId != null ? 3 : 0,
                    shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 13.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
