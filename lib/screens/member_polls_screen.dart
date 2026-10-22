import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/poll_model.dart';
import '../models/user_model.dart';
import '../services/society_poll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:building_guard/core/app_firestore.dart';

class MemberPollsScreen extends StatefulWidget {
  const MemberPollsScreen({super.key});

  @override
  State<MemberPollsScreen> createState() => _MemberPollsScreenState();
}

class _MemberPollsScreenState extends State<MemberPollsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocietyPollService _pollService = SocietyPollService.instance;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  // Track selected option per poll before submission: Map<pollId, optionId>
  final Map<String, String> _selectedOptionMap = {};
  // Track submitting state per poll: Set<pollId>
  final Set<String> _submittingPollIds = {};

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
              'સોસાયટી નિર્ણય મતદાન',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'આપનો કિંમતી મત સોસાયટીના વિકાસ માટે',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          tabs: const [
            Tab(text: '🗳️ સક્રિય પોલ (Active)'),
            Tab(text: '📜 ભૂતકાળના નિર્ણયો (Past)'),
          ],
        ),
      ),
      body: StreamBuilder<List<PollModel>>(
        stream: _pollService.getPollsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPolls = snapshot.data ?? [];
          final memberBlock = _currentUser?.blockName ?? _currentUser?.subGroup ?? '';

          // Filter by member's scope
          final eligiblePolls = allPolls.where((p) {
            if (p.targetScope == 'all') return true;
            if (memberBlock.isNotEmpty && p.targetScope == memberBlock) return true;
            return false;
          }).toList();

          final activePolls = eligiblePolls.where((p) => p.isLive).toList();
          final closedPolls = eligiblePolls.where((p) => !p.isLive).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPollList(activePolls, currentUid, isActiveTab: true),
              _buildPollList(closedPolls, currentUid, isActiveTab: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPollList(List<PollModel> polls, String currentUid, {required bool isActiveTab}) {
    if (polls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isActiveTab ? Icons.how_to_vote_outlined : Icons.history_edu_outlined,
                  size: 44,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isActiveTab ? 'અત્યારે કોઈ નવું મતદાન ચાલુ નથી.' : 'કોઈ અગાઉના નિર્ણયો નોંધાયેલા નથી.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActiveTab
                    ? 'જ્યારે પણ કમિટી તરફથી નવો નિર્ણય લેવાનો હશે ત્યારે અહીં પોલ જોવા મળશે.'
                    : 'સમાપ્ત થયેલા પોલ્સ અહીં સંગ્રહિત થશે.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: polls.length,
      itemBuilder: (context, idx) {
        return _buildMemberPollCard(polls[idx], currentUid);
      },
    );
  }

  Widget _buildMemberPollCard(PollModel poll, String currentUid) {
    final dateFormat = DateFormat('dd/MM/yyyy • hh:mm a');
    final hasVoted = poll.hasUserVoted(currentUid) ||
        (_memberFlatDisplay.isNotEmpty && poll.hasFlatVoted(_memberFlatDisplay));
    final isSubmitting = _submittingPollIds.contains(poll.id);
    final totalVotes = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasVoted ? const Color(0xFFE2E8F0) : const Color(0xFF0F766E).withValues(alpha: 0.4),
          width: hasVoted ? 1.0 : 1.5,
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                            : (poll.isLive ? Icons.pending_rounded : Icons.lock_clock_rounded),
                        size: 13,
                        color: hasVoted
                            ? const Color(0xFF16A34A)
                            : (poll.isLive ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasVoted
                            ? 'આપે મત આપી દીધો છે'
                            : (poll.isLive ? 'મતદાન બાકી છે' : 'મતદાન પૂર્ણ થયું'),
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
                if (poll.targetScope != 'all') ...[
                  const SizedBox(width: 8),
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
                ],
                const Spacer(),
                Text(
                  poll.isLive
                      ? 'અંતિમ: ${DateFormat('dd/MM').format(poll.endDate)}'
                      : 'સમાપ્ત',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

            if (poll.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                poll.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
              ),
            ],
            const SizedBox(height: 16),

            // IF USER HAS ALREADY VOTED (OR POLL IS CLOSED): SHOW LIVE RESULTS
            if (hasVoted || !poll.isLive) ...[
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

              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'કુલ મતદાન: $totalVotes સભ્યો',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                  ),
                  Text(
                    'સમાપ્તિ: ${dateFormat.format(poll.endDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),

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
                  child: Text(
                    'ઠરાવ: ${poll.resolutionSummary}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                  ),
                ),
              ],
            ]

            // IF USER HAS NOT VOTED YET AND POLL IS ACTIVE: SHOW VOTING CHOICES
            else ...[
              const Text(
                'આપનો વિકલ્પ પસંદ કરો:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              ...poll.options.map((opt) {
                final isSelected = _selectedOptionMap[poll.id] == opt.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOptionMap[poll.id] = opt.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Submit Vote Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedOptionMap[poll.id] == null || isSubmitting
                      ? null
                      : () async {
                          final selectedOptId = _selectedOptionMap[poll.id]!;
                          setState(() => _submittingPollIds.add(poll.id));

                          try {
                            HapticFeedback.mediumImpact();
                            await _pollService.castVote(
                              pollId: poll.id,
                              optionId: selectedOptId,
                              flatDisplay: _memberFlatDisplay,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 આપનો મત સફળતાપૂર્વક નોંધાઈ ગયો છે! આભાર.'),
                                  backgroundColor: Color(0xFF059669),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _submittingPollIds.remove(poll.id));
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.how_to_vote_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'મત નોંધાઈ રહ્યો છે...' : 'મત આપો (Submit Vote)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
