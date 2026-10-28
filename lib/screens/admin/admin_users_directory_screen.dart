import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/society_service.dart';
import 'admin_add_user_screen.dart';
import '../../widgets/premium_app_bar.dart';

class AdminUsersDirectoryScreen extends StatefulWidget {
  final String initialRole; // 'all', 'member', 'watchman', 'admin'

  const AdminUsersDirectoryScreen({
    super.key,
    this.initialRole = 'all',
  });

  @override
  State<AdminUsersDirectoryScreen> createState() => _AdminUsersDirectoryScreenState();
}

class _AdminUsersDirectoryScreenState extends State<AdminUsersDirectoryScreen> {
  late String _selectedRole;
  final _searchC = TextEditingController();
  String _searchQuery = '';

  late final Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    final sid = SocietyService.instance.societyId;
    _usersStream = AppFirestore.instance
        .collection('users')
        .where('societyId', isEqualTo: sid)
        .snapshots();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteUser(String docId, String userName) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'યુઝર ડિલીટ કરવો છે?'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'શું તમે ખરેખર "$userName" નું એકાઉન્ટ સોસાયટીમાંથી કાઢી નાખવા માંગો છો?'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('રદ કરો'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('હા, કાઢી નાખો'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

    if (confirm != true) return;

    try {
      await AppFirestore.instance.collection('users').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName સફળતાપૂર્વક કાઢી નાખવામાં આવ્યા.'.tr),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ભૂલ આવી: $e'.tr),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: "સોસાયટી સભ્યો & સ્ટાફ".tr,
        subtitle: "મેમ્બર, વોચમેન અને એડમિન ડિરેક્ટરી".tr,
        icon: Icons.people_alt_rounded,
        accentColor: const Color(0xFF4338CA),
        actions: [
          PremiumAppBarAction(
            icon: Icons.person_add_rounded,
            color: const Color(0xFF4338CA),
            backgroundColor: const Color(0xFFEEF2FF),
            tooltip: 'નવો યુઝર ઉમેરો'.tr,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAddUserScreen(
                    initialRole: _selectedRole == 'all' ? 'member' : _selectedRole,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];
          final countAll = allDocs.length;
          final countMember = allDocs.where((d) => ((d.data() as Map<String, dynamic>?)?['role'] ?? 'member') == 'member').length;
          final countWatchman = allDocs.where((d) => ((d.data() as Map<String, dynamic>?)?['role'] ?? '') == 'watchman').length;
          final countAdmin = allDocs.where((d) => ((d.data() as Map<String, dynamic>?)?['role'] ?? '') == 'admin').length;

          // Filter by selected role and search query in-memory
          final filteredDocs = allDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final role = (d['role'] ?? 'member').toString();
            if (_selectedRole != 'all' && role != _selectedRole) return false;

            if (_searchQuery.isEmpty) return true;
            final name = (d['name'] ?? '').toString().toLowerCase();
            final phone = (d['phone'] ?? '').toString().toLowerCase();
            final email = (d['email'] ?? '').toString().toLowerCase();
            final block = (d['blockName'] ?? '').toString().toLowerCase();
            final unit = (d['unitNumber'] ?? '').toString().toLowerCase();
            final flat = '$block-$unit'.toLowerCase();

            return name.contains(_searchQuery) ||
                phone.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                block.contains(_searchQuery) ||
                unit.contains(_searchQuery) ||
                flat.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Search and Filters Sticky Section (ALWAYS visible, never reloads)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchC,
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'નામ, ફોન, વિંગ અથવા ફ્લેટ નંબરથી શોધો...'.tr,
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchC.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'બધા ($countAll)'.tr, Icons.groups_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip('member', 'મેમ્બર્સ ($countMember)'.tr, Icons.home_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip('watchman', 'વોચમેન ($countWatchman)'.tr, Icons.security_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip('admin', 'એડમિન ($countAdmin)'.tr, Icons.admin_panel_settings_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // User List Section (only this inner list updates)
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting && allDocs.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('ડેટા લોડ કરવામાં ભૂલ: ${snapshot.error}'.tr),
                      );
                    }

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_search_rounded, size: 50, color: Color(0xFF4338CA)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'કોઈ યુઝર મળ્યા નથી'.tr,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'તમારા સર્ચ સાથે મેળ ખાતું કોઈ પરિણામ નથી.'.tr
                                  : 'આ કેટેગરીમાં હજી કોઈ નોંધણી થયેલ નથી.'.tr,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final d = doc.data() as Map<String, dynamic>;
                        return _buildUserCard(doc.id, d);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddUserScreen(
                initialRole: _selectedRole == 'all' ? 'member' : _selectedRole,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('નવો યુઝર'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String docId, Map<String, dynamic> d) {
    final name = (d['name'] ?? 'અનામી'.tr).toString();
    final role = (d['role'] ?? 'member').toString();
    final phone = (d['phone'] ?? '').toString();
    final email = (d['email'] ?? '').toString();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString();
    final hasLocation = cleanBlock.isNotEmpty || unit.isNotEmpty;

    Color badgeColor;
    String roleName;
    IconData roleIcon;
    List<Color> avatarGradient;

    if (role == 'admin') {
      badgeColor = const Color(0xFF7C3AED);
      avatarGradient = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      roleName = 'એડમિન'.tr;
      roleIcon = Icons.admin_panel_settings_rounded;
    } else if (role == 'watchman') {
      badgeColor = const Color(0xFF0D9488);
      avatarGradient = const [Color(0xFF14B8A6), Color(0xFF0F766E)];
      roleName = 'વોચમેન'.tr;
      roleIcon = Icons.security_rounded;
    } else {
      badgeColor = const Color(0xFF4338CA);
      avatarGradient = const [Color(0xFF4F46E5), Color(0xFF3730A3)];
      roleName = 'મેમ્બર'.tr;
      roleIcon = Icons.home_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showUserDetailsSheet(docId, d),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: avatarGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(roleIcon, size: 11, color: badgeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      roleName,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (hasLocation) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF475569)),
                                  const SizedBox(width: 4),
                                  Text(
                                    unit.isNotEmpty ? '$cleanBlock • $unit' : cleanBlock,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.mail_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (phone.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _makeCall(phone),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'મોબાઇલ નંબર નોંધાયેલ નથી'.tr,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: () => _deleteUser(docId, name),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetailsSheet(String docId, Map<String, dynamic> d) {
    final name = (d['name'] ?? 'અનામી'.tr).toString();
    final role = (d['role'] ?? 'member').toString();
    final phone = (d['phone'] ?? '').toString();
    final email = (d['email'] ?? '').toString();
    final rawBlock = (d['blockName'] ?? '').toString();
    final cleanBlock = rawBlock.contains('_') ? rawBlock.split('_').last : rawBlock;
    final unit = (d['unitNumber'] ?? '').toString();
    final uid = (d['uid'] ?? docId).toString();

    DateTime? createdDate;
    if (d['createdAt'] != null && d['createdAt'] is Timestamp) {
      createdDate = (d['createdAt'] as Timestamp).toDate();
    }

    Color badgeColor;
    String roleName;
    IconData roleIcon;
    List<Color> avatarGradient;

    if (role == 'admin') {
      badgeColor = const Color(0xFF7C3AED);
      avatarGradient = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      roleName = 'સોસાયટી એડમિન'.tr;
      roleIcon = Icons.admin_panel_settings_rounded;
    } else if (role == 'watchman') {
      badgeColor = const Color(0xFF0D9488);
      avatarGradient = const [Color(0xFF14B8A6), Color(0xFF0F766E)];
      roleName = 'ગેટ વોચમેન'.tr;
      roleIcon = Icons.security_rounded;
    } else {
      badgeColor = const Color(0xFF4338CA);
      avatarGradient = const [Color(0xFF4F46E5), Color(0xFF3730A3)];
      roleName = 'સોસાયટી મેમ્બર'.tr;
      roleIcon = Icons.home_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Header Profile Card
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: avatarGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 12, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              roleName,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            Text(
              'સભ્યની વિગતો'.tr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),

            _detailRow(
              icon: Icons.apartment_rounded,
              label: 'બ્લોક & ફ્લેટ નંબર'.tr,
              value: cleanBlock.isNotEmpty || unit.isNotEmpty
                  ? '$cleanBlock • $unit'
                  : 'કોઈ ફ્લેટ એસાઇન નથી'.tr,
              color: const Color(0xFF4338CA),
            ),
            _detailRow(
              icon: Icons.phone_rounded,
              label: 'મોબાઇલ નંબર'.tr,
              value: phone.isNotEmpty ? phone : 'નોંધાયેલ નથી'.tr,
              color: const Color(0xFF059669),
            ),
            _detailRow(
              icon: Icons.email_rounded,
              label: 'ઇમેઇલ એડ્રેસ'.tr,
              value: email.isNotEmpty ? email : 'નોંધાયેલ નથી'.tr,
              color: const Color(0xFF2563EB),
            ),
            if (createdDate != null)
              _detailRow(
                icon: Icons.calendar_today_rounded,
                label: 'રજીસ્ટ્રેશન તારીખ'.tr,
                value: DateFormat('dd MMM yyyy, hh:mm a').format(createdDate),
                color: const Color(0xFFD97706),
              ),
            _detailRow(
              icon: Icons.verified_user_rounded,
              label: 'એકાઉન્ટ સ્ટેટસ'.tr,
              value: 'સક્રિય (Active & Verified)'.tr,
              color: const Color(0xFF047857),
            ),
            _detailRow(
              icon: Icons.fingerprint_rounded,
              label: 'યુઝર આઈડી'.tr,
              value: uid,
              color: const Color(0xFF64748B),
              isCopyable: true,
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _makeCall(phone);
                      },
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: Text('કૉલ કરો'.tr, style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteUser(docId, name);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: Text(
                      'ડિલીટ કરો'.tr,
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCopyable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF94A3B8)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'કૉપિ કરો'.tr,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('આઈડી કૉપિ થઈ ગયું!'.tr), duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
    );
  }
}
