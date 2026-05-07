import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/society_service.dart';
import '../widgets/premium_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Cloud Functions v2 `sendMemberPush` નું રીજન — [GCP Console] → Functions માં ચેક કરો (ઘણી વખત `us-central1`).
const String _kSendMemberPushRegion = 'us-central1';

class _MemberPushResult {
  const _MemberPushResult._({
    this.sentDirect = false,
    this.noToken = false,
    this.failureMessage,
  });

  final bool sentDirect;
  final bool noToken;
  final String? failureMessage;

  static const direct = _MemberPushResult._(sentDirect: true);
  static const noTokenResult = _MemberPushResult._(noToken: true);

  static _MemberPushResult failed(String msg) =>
      _MemberPushResult._(failureMessage: msg);
}

class WatchmanScreen extends StatefulWidget {
  const WatchmanScreen({super.key});

  @override
  State<WatchmanScreen> createState() => _WatchmanScreenState();
}

class _WatchmanScreenState extends State<WatchmanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _searchController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _selectedBlock;
  String _searchQuery = "";
  String _historyStatusFilter = 'all';
  String _historyTimeFilter = 'today';
  UserModel? _selectedMember;
  List<UserModel> _filteredMembers = [];
  bool _isUploading = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _processedIds = []; // જે એન્ટ્રીનો અવાજ આવી ગયો હોય તેની યાદી
  List<QueryDocumentSnapshot> _preApprovedResults = [];

  void _playAlertSound() async {
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
    });
  }

  Future<DocumentSnapshot> _loadSocietyConfigDoc() async {
    final sid = SocietyService.instance.societyId;
    final modern = await FirebaseFirestore.instance
        .collection('society_settings')
        .doc(sid)
        .get();
    if (modern.exists) return modern;
    if (sid == SocietyService.kDefaultSocietyId) {
      return FirebaseFirestore.instance
          .collection('settings')
          .doc('society_config')
          .get();
    }
    return modern;
  }

  // ૧. વિઝિટરનો ફોટો પાડવો
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  // ૨. બ્લોક મુજબ મેમ્બર્સ મેળવવા
  Future<void> _fetchMembersByBlock(String blockName) async {
    setState(() => _isUploading = true);
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'member')
        .where('blockName', isEqualTo: blockName)
        .get();

    setState(() {
      _filteredMembers = snapshot.docs
          .where(
            (doc) => SocietyService.instance.documentBelongsToCurrentTenant(
              doc.data() as Map<String, dynamic>?,
            ),
          )
          .map(
            (doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      _selectedMember = null;
      _isUploading = false;
    });
  }

  // મહેમાન પ્રી-એપ્રુવ્ડ છે કે નહીં તે ચેક કરવા માટે
  Future<void> _checkPreApproval(String name) async {
    if (name.length < 3) {
      setState(() => _preApprovedResults = []);
      return;
    }

    var snapshot = await FirebaseFirestore.instance
        .collection('pre_approvals')
        .where('guestName', isEqualTo: name.trim())
        .where('status', isEqualTo: 'pre-approved')
        .get();

    final matched = snapshot.docs
        .where(
          (d) => SocietyService.instance.documentBelongsToCurrentTenant(
            d.data() as Map<String, dynamic>?,
          ),
        )
        .toList();

    setState(() {
      _preApprovedResults = matched;
    });

    if (matched.length == 1) {
      _selectPreApprovedGuest(matched.first);
    }
  }

  // ગેસ્ટ સિલેક્ટ કરવાનું ફંક્શન
  void _selectPreApprovedGuest(DocumentSnapshot doc) async {
    var data = doc.data() as Map<String, dynamic>;
    String memberId = data['memberId'];

    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .get();
    UserModel member = UserModel.fromMap(
      userDoc.data() as Map<String, dynamic>,
      userDoc.id,
    );

    setState(() {
      _selectedBlock = member.blockName;
      _selectedMember = member;
      _purposeController.text = "Pre-Approved Guest";
      _nameController.text = data['guestName']; // સાચું નામ સેટ કરો
      _preApprovedResults = []; // લિસ્ટ ક્લિયર કરો
    });

    _showSnackBar("${member.name} ના મહેમાન મળ્યા!", Colors.blue);
  }

  // ૩. એન્ટ્રી સબમિટ અને નોટિફિકેશન ટ્રિગર
  Future<void> _submitEntry() async {
    if (_image == null ||
        _selectedMember == null ||
        _nameController.text.isEmpty) {
      _showSnackBar('કૃપા કરીને બધી વિગત અને ફોટો ભરો', Colors.orange);
      return;
    }

    setState(() => _isUploading = true);
    try {
      // સ્ટોરેજમાં ફોટો અપલોડ
      String fileName = 'visitors/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // TaskSnapshot uploadTask =
      //     await FirebaseStorage.instance.ref(fileName).putFile(_image!);
      String photoUrl = "";
      // String photoUrl = await uploadTask.ref.getDownloadURL();

      bool isPreApproved = _purposeController.text == "Pre-Approved Guest";
      final guestName = _nameController.text.trim();
      final memberUid = _selectedMember!.uid;

      await FirebaseFirestore.instance.collection('visitors').add({
        'name': guestName,
        'phone': _phoneController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'watchmanId': FirebaseAuth.instance.currentUser!.uid,
        'photoUrl': photoUrl,
        'memberId': memberUid,
        'memberName': _selectedMember!.name,
        'blockName': _selectedBlock,
        'unitNumber': _selectedMember!.unitNumber,
        'status': isPreApproved ? 'approved' : 'pending',
        'entryTime': FieldValue.serverTimestamp(),
        'societyId': SocietyService.instance.societyId,
      });

      final push = await _notifyMemberPush(
        memberUid: memberUid,
        title: 'નવા મુલાકાતી (Gate Alert)',
        body: '$guestName તમને મળવા આવ્યા છે.',
        type: 'visitor_alert',
      );

      _clearForm();
      if (!mounted) return;
      _showSnackBar(
        'એન્ટ્રી સફળ. ${_lineForMemberPush(push)}',
        _colorForMemberPush(push),
      );
      _tabController.animateTo(1); // હિસ્ટ્રી ટેબ પર લઈ જાઓ
    } catch (e) {
      _showSnackBar('ભૂલ આવી: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ૪. ઇમરજન્સી SOS એલર્ટ (એડમિનને જાણ કરવા)
  Future<void> _sendSOS() async {
    bool confirm = await _showConfirmDialog(
      "SOS એલર્ટ!",
      "શું તમે એડમિનને મદદ માટે જાણ કરવા માંગો છો?",
    );
    if (!confirm) return;

    try {
      final app = await ensureDefaultFirebaseApp();
      final functions = FirebaseFunctions.instanceFor(
        app: app,
        region: _kSendMemberPushRegion,
      );
      final callable = functions.httpsCallable(
        'sendTopicAlertPush',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      await callable.call<Map<String, dynamic>>({
        'topicKind': 'admins',
        'title': '🚨 ઇમરજન્સી એલર્ટ (GATE)',
        'body': 'ગેટ પર વોચમેનને મદદની જરૂર છે!',
        'type': 'sos',
      });
      if (!mounted) return;
      _showSnackBar('એડમિનને SOS પુશ મોકલાયો.', Colors.red);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        _showSnackBar(
          'SOS નિષ્ફળ (${e.code}): ${e.message ?? ""}',
          Colors.deepOrange,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('SOS ભૂલ: $e', Colors.red);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _purposeController.clear();
    setState(() {
      _image = null;
      _selectedMember = null;
      _selectedBlock = null;
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _lineForMemberPush(_MemberPushResult r) {
    if (r.sentDirect) return 'મેમ્બરને પુશ મોકલાયો.';
    if (r.noToken) {
      return 'મેમ્બર પાસે ફોન ટોકન નથી — એક વાર એપ ખોલવા કહો.';
    }
    return r.failureMessage ?? 'પુશ મોકલાઈ શક્યો નહીં.';
  }

  Color _colorForMemberPush(_MemberPushResult r) {
    if (r.failureMessage != null) return Colors.red;
    if (r.noToken) return Colors.deepOrange;
    return Colors.green;
  }

  /// સીધું FCM `sendMemberPush` — Firestore ટ્રિગર / પોલ પર નિર્ભર નથી.
  Future<_MemberPushResult> _notifyMemberPush({
    required String memberUid,
    required String title,
    required String body,
    required String type,
  }) async {
    final app = await ensureDefaultFirebaseApp();
    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: _kSendMemberPushRegion,
    );
    final callable = functions.httpsCallable(
      'sendMemberPush',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
    );

    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 5),
    ];

    Object? lastError;
    for (var i = 0; i < delays.length; i++) {
      if (delays[i] > Duration.zero) {
        await Future<void>.delayed(delays[i]);
      }
      try {
        final result = await callable.call<Map<String, dynamic>>({
          'memberUid': memberUid,
          'title': title,
          'body': body,
          'type': type,
        });
        final data = result.data;
        if (data['ok'] == true) return _MemberPushResult.direct;
        if (data['reason'] == 'no_token') {
          return _MemberPushResult.noTokenResult;
        }
        lastError = data['reason'] ?? data;
        continue;
      } on FirebaseFunctionsException catch (e) {
        lastError = e;
        if (i == delays.length - 1) {
          return _MemberPushResult.failed(
            kDebugMode
                ? '${e.code}: ${e.message}'
                : 'સર્વર ભૂલ — ઇન્ટરનેટ/ફંક્શન તપાસો (${e.code})',
          );
        }
      } catch (e) {
        lastError = e;
        if (i == delays.length - 1) {
          return _MemberPushResult.failed(
            kDebugMode ? e.toString() : 'પુશ મોકલાઈ શક્યો નહીં.',
          );
        }
      }
    }
    return _MemberPushResult.failed(
      kDebugMode ? '$lastError' : 'પુશ મોકલાઈ શક્યો નહીં.',
    );
  }

  void _openContactsAndStaffSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'ઈમરજન્સી કોન્ટેક્ટ્સ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: _loadSocietyConfigDoc(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Text('હજી એડમિને નંબરો ઉમેર્યા નથી.');
                }
                final rawData = snap.data!.data();
                if (rawData == null) {
                  return const Text('હજી એડમિને નંબરો ઉમેર્યા નથી.');
                }
                final settingsMap = Map<String, dynamic>.from(rawData as Map);
                final raw = settingsMap['emergencyContacts'];
                if (raw is! List) {
                  return const Text('હજી એડમિને નંબરો ઉમેર્યા નથી.');
                }
                final emergList = raw;
                if (emergList.isEmpty) {
                  return const Text('હજી એડમિને નંબરો ઉમેર્યા નથી.');
                }
                return Column(
                  children: emergList.map<Widget>((e) {
                    if (e is! Map) return const SizedBox.shrink();
                    final m = Map<String, dynamic>.from(e as Map);
                    final name = '${m['name'] ?? ''}';
                    final phone = '${m['phone'] ?? ''}';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone, color: Colors.red),
                      title: Text(name),
                      subtitle: Text(phone),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            const Text(
              'મેમ્બર્સનો કાયમી સ્ટાફ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('daily_staff')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs
                    .where(
                      (d) => SocietyService.instance
                          .documentBelongsToCurrentTenant(
                            d.data() as Map<String, dynamic>?,
                          ),
                    )
                    .toList();
                if (docs.isEmpty) {
                  return const Text('કોઈ સ્ટાફ નોંધાયો નથી.');
                }
                return Column(
                  children: docs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.badge_outlined),
                      title: Text('${m['staffName'] ?? ''}'),
                      subtitle: Text(
                        '${m['staffRole'] ?? ''}\n📱 ${m['staffPhone'] ?? ''}',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ના"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("હા"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("સોસાયટી ગેટ કંટ્રોલ"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: "નવી એન્ટ્રી"),
            Tab(icon: Icon(Icons.history), text: "આજની હિસ્ટ્રી"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_phone),
            tooltip: 'ઈમરજન્સી અને કાયમી સ્ટાફ',
            onPressed: _openContactsAndStaffSheet,
          ),
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade300,
            ),
            onPressed: _sendSOS,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withValues(alpha: 0.06),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                _buildWatchmanSummaryCard(),
                Expanded(child: _buildEntryForm()),
              ],
            ),
            _buildVisitorHistory(),
          ],
        ),
      ),
    );
  }

  // --- UI: વિઝિટર એન્ટ્રી ફોર્મ ---
  Widget _buildEntryForm() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
              ),
              child: _image == null
                  ? const Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.indigo,
                    )
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // એલાઇનમેન્ટ બરાબર રાખવા
            children: [
              // ૧. ટેક્સ્ટ ફિલ્ડ - આ રોમાં વધુ જગ્યા રોકશે
              Expanded(
                flex: 3, // ૩ ભાગ આ રોકશે
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      onChanged: (value) {
                        if (value.length >= 3) {
                          _checkPreApproval(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "વિઝિટરનું નામ",
                        hintText: "નામ ટાઈપ કરો...",
                        prefixIcon: Icon(Icons.person, color: cs.primary),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                      ),
                    ),

                    // જો સર્ચ રિઝલ્ટ મળ્યા હોય તો નાનું લિસ્ટ બતાવવા માટે (Optional)
                    if (_preApprovedResults.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "⚠️ ${_preApprovedResults.length} પ્રી-એપ્રુવ્ડ મહેમાન મળ્યા",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10), // બે વિજેટ વચ્ચે ગેપ
              // ૨. QR સ્કેનર બટન - આ નાનું આઈકન બટન તરીકે વધારે સારું લાગશે
              Expanded(
                flex: 1, // ૧ ભાગ આ રોકશે
                child: Container(
                  height: 58, // TextField ની હાઈટ જેટલું રાખ્યું છે
                  child: ElevatedButton(
                    onPressed: _openQRScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      // આઈકન બરાબર સેટ કરવા
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 28),
                        Text("સ્કેન", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // TextField ની નીચે આ કોડ મૂકો
          if (_preApprovedResults.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                itemCount: _preApprovedResults.length,
                itemBuilder: (context, index) {
                  var data =
                      _preApprovedResults[index].data() as Map<String, dynamic>;
                  return ListTile(
                    tileColor: Colors.blue[50],
                    leading: const Icon(Icons.verified, color: Colors.blue),
                    title: Text("${data['guestName']} (Pre-Approved)"),
                    subtitle: Text("મેમ્બર ID: ${data['memberId']}"),
                    // તમે અહીં મેમ્બરનું નામ પણ લાવી શકો
                    onTap: () =>
                        _selectPreApprovedGuest(_preApprovedResults[index]),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "મોબાઈલ નંબર",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeController,
            decoration: const InputDecoration(
              labelText: "કારણ (Guest, Delivery)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Block & Member Dropdowns
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blocks').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final blockDocs = snap.data!.docs
                  .where(
                    (d) =>
                        SocietyService.instance.documentBelongsToCurrentTenant(
                          d.data() as Map<String, dynamic>?,
                        ),
                  )
                  .toList();
              if (blockDocs.isEmpty) {
                return const Text('આ સોસાયટી માટે કોઈ બ્લોક નથી.');
              }
              return DropdownButtonFormField<String>(
                value: _selectedBlock,
                hint: const Text("બ્લોક પસંદ કરો"),
                items: blockDocs
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d['name'] ?? d.id}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedBlock = v);
                  _fetchMembersByBlock(v!);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              );
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<UserModel>(
            value: _selectedMember,
            hint: const Text("કોને મળવું છે?"),
            // 👇 જો લિસ્ટ લોડ થઈ રહ્યું હોય તો ખાલી લિસ્ટ બતાવો
            items: _filteredMembers.isEmpty
                ? []
                : _filteredMembers
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text("${m.name} (${m.unitNumber})"),
                        ),
                      )
                      .toList(),
            onChanged: (v) => setState(() => _selectedMember = v),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 30),
          _isUploading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "એન્ટ્રી કરો અને મેમ્બરને જાણ કરો",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWatchmanSummaryCard() {
    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('visitors')
          .where(
            'entryTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('entryTime', descending: true)
          .limit(250)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.hasData
            ? snap.data!.docs.where((d) {
                return SocietyService.instance.documentBelongsToCurrentTenant(
                  d.data() as Map<String, dynamic>?,
                );
              }).toList()
            : <QueryDocumentSnapshot>[];
        final total = docs.length;
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final checkedOut = docs
            .where((d) => d['status'] == 'checked_out')
            .length;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              _summaryTile('Today', total, Colors.indigo),
              _summaryTile('Pending', pending, Colors.orange),
              _summaryTile('In', approved, Colors.green),
              _summaryTile('Out', checkedOut, Colors.blueGrey),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryTile(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  DateTime _watchmanCutoffDate() {
    final now = DateTime.now();
    if (_historyTimeFilter == 'today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (_historyTimeFilter == '7d') {
      return now.subtract(const Duration(days: 7));
    }
    return now.subtract(const Duration(days: 30));
  }

  Widget _buildHistoryTimeFilterRow() {
    final options = <(String, String)>[
      ('today', 'Today'),
      ('7d', '7 Days'),
      ('30d', '30 Days'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: options.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: _historyTimeFilter == item.$1,
              onSelected: (_) => setState(() => _historyTimeFilter = item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWatchmanHistoryGraph() {
    final cutoff = _watchmanCutoffDate();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('visitors')
          .where(
            'entryTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
          )
          .orderBy('entryTime', descending: true)
          .limit(400)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.hasData
            ? snap.data!.docs.where((d) {
                final m = d.data() as Map<String, dynamic>?;
                if (!SocietyService.instance.documentBelongsToCurrentTenant(
                  m,
                )) {
                  return false;
                }
                final ts = m?['entryTime'];
                if (ts is! Timestamp) return false;
                return ts.toDate().isAfter(cutoff);
              }).toList()
            : <QueryDocumentSnapshot>[];
        final pending = docs.where((d) => d['status'] == 'pending').length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final rejected = docs.where((d) => d['status'] == 'rejected').length;
        final out = docs.where((d) => d['status'] == 'checked_out').length;
        final maxVal = [
          pending,
          approved,
          rejected,
          out,
          1,
        ].reduce((a, b) => a > b ? a : b);
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _graphBar('Pending', pending, maxVal, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(child: _graphBar('In', approved, maxVal, Colors.green)),
              const SizedBox(width: 8),
              Expanded(
                child: _graphBar('Rejected', rejected, maxVal, Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(child: _graphBar('Out', out, maxVal, Colors.blueGrey)),
            ],
          ),
        );
      },
    );
  }

  Widget _graphBar(String label, int count, int maxCount, Color color) {
    final ratio = (count / maxCount).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 66,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 12 + (52 * ratio),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // --- UI: આજની હિસ્ટ્રી ---

  Widget _buildVisitorHistory() {
    return Column(
      children: [
        // 🔍 સર્ચ બાર UI
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "નામ અથવા ફ્લેટ નંબરથી શોધો...",
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ), // જો Container માં હોવ તો
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _statusChip('all', 'All'),
              _statusChip('pending', 'Pending'),
              _statusChip('approved', 'In'),
              _statusChip('rejected', 'Rejected'),
              _statusChip('checked_out', 'Out'),
            ],
          ),
        ),
        _buildHistoryTimeFilterRow(),
        _buildWatchmanHistoryGraph(),
        const SizedBox(height: 6),

        // 📜 ફિલ્ટર કરેલું લિસ્ટ
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('visitors')
                .where(
                  'entryTime',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 30)),
                  ),
                )
                .orderBy('entryTime', descending: true)
                .limit(250)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('હિસ્ટ્રી ભૂલ: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tenantDocs = snap.data!.docs
                  .where(
                    (doc) =>
                        SocietyService.instance.documentBelongsToCurrentTenant(
                          doc.data() as Map<String, dynamic>?,
                        ),
                  )
                  .toList();

              var filteredDocs = tenantDocs.where((doc) {
                final m = doc.data() as Map<String, dynamic>;
                String name = (m['name'] ?? '').toString().toLowerCase();
                String unit = (m['unitNumber'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    unit.contains(_searchQuery);
              }).toList();
              final cutoff = _watchmanCutoffDate();
              filteredDocs = filteredDocs.where((doc) {
                final ts = (doc.data() as Map<String, dynamic>)['entryTime'];
                if (ts is! Timestamp) return false;
                return ts.toDate().isAfter(cutoff);
              }).toList();
              if (_historyStatusFilter != 'all') {
                filteredDocs = filteredDocs
                    .where((d) => (d['status'] ?? '') == _historyStatusFilter)
                    .toList();
              }

              if (filteredDocs.isEmpty) {
                return const PremiumEmptyState(
                  message: "કોઈ મહેમાન મળ્યા નથી.",
                  icon: Icons.person_search_rounded,
                );
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, i) {
                  var d = filteredDocs[i];
                  String status = d['status'] ?? 'pending';

                  Color statusColor;
                  String statusText;
                  IconData statusIcon;

                  // સ્ટેટસ કલર લોજિક
                  if (status == 'approved') {
                    statusColor = Colors.green;
                    statusText = "અંદર છે";
                    statusIcon = Icons.door_front_door;
                  } else if (status == 'rejected') {
                    statusColor = Colors.red;
                    statusText = "ના પાડી છે";
                    statusIcon = Icons.cancel;
                  } else if (status == 'checked_out') {
                    statusColor = Colors.grey;
                    statusText = "બહાર ગયા";
                    statusIcon = Icons.exit_to_app;
                  } else {
                    statusColor = Colors.orange;
                    statusText = "રાહ જુઓ";
                    statusIcon = Icons.hourglass_empty;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              d['photoUrl'] != null && d['photoUrl'].isNotEmpty
                              ? NetworkImage(d['photoUrl'])
                              : null,
                          child: d['photoUrl'] == null || d['photoUrl'].isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          d['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ઘર: ${d['blockName']}-${d['unitNumber']}\nહેતુ: ${d['purpose']}",
                            ),
                            if (status == 'checked_out' &&
                                d['exitTime'] != null)
                              Text(
                                "Out: ${DateFormat('hh:mm a').format((d['exitTime'] as Timestamp).toDate())}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        // trailing માં ફેરફાર કરીને ઓવરફ્લો સોલ્વ કર્યો
                        trailing: SizedBox(
                          width: 100, // ફિક્સ વિડ્થ આપી જેથી ઓવરફ્લો ન થાય
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (status == 'approved')
                                // જો અંદર હોય તો 'OUT' બટન બતાવો
                                SizedBox(
                                  height: 35,
                                  width: 80,
                                  child: ElevatedButton(
                                    onPressed: () => _checkOutVisitor(d.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "OUT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                // બાકીના સ્ટેટસ માટે માત્ર આઇકન અને ટેક્સ્ટ
                                Column(
                                  children: [
                                    Icon(
                                      statusIcon,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _historyStatusFilter == value,
        onSelected: (_) => setState(() => _historyStatusFilter = value),
      ),
    );
  }

  // Check-out કરવાનું ફંક્શન
  Future<void> _checkOutVisitor(String docId) async {
    final ref = FirebaseFirestore.instance.collection('visitors').doc(docId);
    final snap = await ref.get();
    final m = snap.data();
    final memberUid = m?['memberId'] as String?;
    final rawName = m?['name'] as String?;
    final guestName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'મહેમાન';

    await ref.update({
      'status': 'checked_out',
      'exitTime': FieldValue.serverTimestamp(),
    });

    if (memberUid != null && memberUid.isNotEmpty) {
      final push = await _notifyMemberPush(
        memberUid: memberUid,
        title: 'મહેમાન બહાર ગયા 🚪',
        body: '$guestName સોસાયટીની બહાર નીકળી ગયા છે.',
        type: 'visitor_checked_out',
      );
      if (!mounted) return;
      _showSnackBar(
        'મહેમાન ચેક-આઉટ થઈ ગયા છે. ${_lineForMemberPush(push)}',
        _colorForMemberPush(push),
      );
    } else {
      _showSnackBar("મહેમાન ચેક-આઉટ થઈ ગયા છે", Colors.blue);
    }
  }

  // ૧. સ્કેનર ખોલવાનું ફંક્શન
  void _openQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) async {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              String? code = barcodes.first.rawValue;
              if (code != null) {
                Navigator.pop(context); // સ્કેનર બંધ કરો
                _processQRCode(code); // ડેટા પ્રોસેસ કરો
              }
            }
          },
        ),
      ),
    );
  }

  // ૨. QR ડેટા પ્રોસેસ કરવાનું લોજિક
  Future<void> _processQRCode(String preApproveId) async {
    setState(() => _isUploading = true);

    try {
      var doc = await FirebaseFirestore.instance
          .collection('pre_approvals')
          .doc(preApproveId)
          .get();

      if (doc.exists && doc.data()!['status'] == 'pre-approved') {
        var data = doc.data()!;
        if (!SocietyService.instance.documentBelongsToCurrentTenant(
          Map<String, dynamic>.from(data as Map),
        )) {
          _showSnackBar('આ QR આ સોસાયટી માટે માન્ય નથી.', Colors.orange);
          return;
        }

        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['memberId'])
            .get();
        UserModel member = UserModel.fromMap(userDoc.data()!, userDoc.id);

        await _fetchMembersByBlock(member.blockName!);

        setState(() {
          _nameController.text = data['guestName'] ?? ""; // નામ ઓટો-ફિલ
          _phoneController.text =
              data['guestPhone'] ?? ""; // 🔥 આ લાઈનથી મોબાઈલ નંબર ઓટો-ફિલ થશે

          _selectedBlock = member.blockName;
          _selectedMember = _filteredMembers.firstWhere(
            (m) => m.uid == member.uid,
            orElse: () => member,
          );
          _purposeController.text = "Pre-Approved Guest";
        });

        _showSnackBar("QR સ્કેન સફળ!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("ભૂલ આવી: $e", Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }
}

/*
without setup



// ૧. સ્ટેટમાં આ વેરિયેબલ ઉમેરો
Set<String> _notifiedVisitorIds = {};

// ૨. હિસ્ટ્રી ટેબમાં StreamBuilder ની અંદર:
builder: (context, snap) {
  if (snap.hasData) {
    for (var doc in snap.data!.docs) {
      String status = doc['status'] ?? 'pending';
      String id = doc.id;

      // જો સ્ટેટસ બદલાયું હોય (pending નથી) અને આપણે હજુ આનો અવાજ નથી વગાડ્યો
      if (status != 'pending' && !_notifiedVisitorIds.contains(id)) {

        // અવાજ વગાડવા માટેનું લોજિક
        _playStatusSound(status);

        // આ આઈડીને સેટમાં ઉમેરી દો જેથી બીજી વાર અવાજ ન આવે
        _notifiedVisitorIds.add(id);
      }
    }
  }
  // ... તમારો બાકીનો લિસ્ટ કોડ
}

// ૩. અવાજ વગાડવાનું ફંક્શન
void _playStatusSound(String status) {
  // તમે અહીં હમણાં માટે સિમ્પલ Vibration અથવા અવાજ મૂકી શકો
  // જો તમે audioplayers પેકેજ વાપરો તો:
  // AudioPlayer().play(AssetSource(status == 'approved' ? 'success.mp3' : 'error.mp3'));

  print("સ્ટેટસ બદલાયું: $status - વોચમેનને એલર્ટ આપો!");
}
 */
