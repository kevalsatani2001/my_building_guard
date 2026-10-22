import 'package:building_guard/core/app_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firebase_app_guard.dart';
import '../services/notification_service.dart';
import '../services/session_guard_service.dart';
import '../services/society_service.dart';
import '../widgets/watchman_vehicle_lookup_sheet.dart';
import '../widgets/premium_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/amenity_model.dart';
import '../services/amenity_booking_service.dart';
import '../models/patrol_model.dart';
import '../services/guard_patrol_service.dart';
import 'watchman_patrol_screen.dart';

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
  String _quickFilterCategory = 'all';
  bool _isAllSociety = false;
  bool _allowMultipleFlats = false;
  List<UserModel> _selectedMembers = [];
  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];
  bool _isLoadingMembers = false;
  bool _isUploading = false;

  static const UserModel kAllMembersPseudo = UserModel(
    uid: '__all_society__',
    name: 'આખી સોસાયટી (All Society)',
    email: '',
    role: 'member',
    unitNumber: 'All Flats',
    blockName: 'All Blocks',
  );

  static const List<Map<String, dynamic>> _kQuickPartners = [
    {
      'name': 'Zomato',
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFFE23744),
      'label': 'Zomato Delivery',
      'category': 'food',
    },
    {
      'name': 'Swiggy',
      'icon': Icons.fastfood_rounded,
      'color': Color(0xFFFC8019),
      'label': 'Swiggy Delivery',
      'category': 'food',
    },
    {
      'name': 'Blinkit',
      'icon': Icons.electric_bolt_rounded,
      'color': Color(0xFFEAB308),
      'label': 'Blinkit Delivery',
      'category': 'food',
    },
    {
      'name': 'Zepto',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFF8B5CF6),
      'label': 'Zepto Delivery',
      'category': 'food',
    },
    {
      'name': 'Amazon',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFFFF9900),
      'label': 'Amazon Delivery',
      'category': 'parcel',
    },
    {
      'name': 'Flipkart',
      'icon': Icons.local_mall_rounded,
      'color': Color(0xFF2874F0),
      'label': 'Flipkart Delivery',
      'category': 'parcel',
    },
    {
      'name': 'કુરિયર',
      'icon': Icons.local_shipping_rounded,
      'color': Color(0xFF475569),
      'label': 'Courier / Parcel',
      'category': 'parcel',
    },
    {
      'name': 'કેબ / ટેક્સી',
      'icon': Icons.local_taxi_rounded,
      'color': Color(0xFF059669),
      'label': 'Ola / Uber Cab',
      'category': 'other',
    },
    {
      'name': 'સર્વિસ / રિપેર',
      'icon': Icons.handyman_rounded,
      'color': Color(0xFF6366F1),
      'label': 'Service / Repair',
      'category': 'other',
    },
    {
      'name': 'મહેમાન (Guest)',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF0284C7),
      'label': 'Guest Visit',
      'category': 'other',
    },
    {
      'name': 'માલ-સામાન / ટેમ્પો',
      'icon': Icons.local_shipping_rounded,
      'color': Color(0xFF0F766E),
      'label': 'Cargo / Goods Delivery',
      'category': 'cargo',
    },
    {
      'name': 'વેપારી / શોપ સ્ટાફ',
      'icon': Icons.store_rounded,
      'color': Color(0xFF7C3AED),
      'label': 'Merchant / Shop Staff',
      'category': 'commercial',
    },
  ];

  final List<Map<String, dynamic>> _customPartners = [];

  List<Map<String, dynamic>> get _allPartners => [..._kQuickPartners, ..._customPartners];

  Future<void> _loadCustomPartners() async {
    try {
      final sid = SocietyService.instance.societyId;
      final doc = await AppFirestore.instance.collection('society_settings').doc(sid).get();
      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['customVisitorCategories'];
        if (list is List) {
          _customPartners.clear();
          for (final item in list) {
            if (item is Map) {
              final name = (item['name'] ?? '').toString().trim();
              final label = (item['label'] ?? name).toString().trim();
              final cat = (item['category'] ?? 'other').toString().trim();
              final colorVal = item['color'];
              final color = colorVal is int ? Color(colorVal) : const Color(0xFF6366F1);
              if (name.isNotEmpty && !_kQuickPartners.any((p) => p['name'] == name)) {
                _customPartners.add({
                  'name': name,
                  'label': label.isNotEmpty ? label : name,
                  'category': cat,
                  'color': color,
                  'icon': Icons.label_important_rounded,
                  'isCustom': true,
                });
              }
            }
          }
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _showAddPartnerDialog() async {
    final nameCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    String selectedCategory = _quickFilterCategory == 'all' ? 'other' : _quickFilterCategory;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_business_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text('નવો વિઝિટર પ્રકાર / પાર્ટનર', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'પાર્ટનર અથવા વિઝિટરનું નામ *',
                    hintText: 'દા.ત. JioMart, દૂધવાળા, ગેસ સર્વિસ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'લેબલ / હેતુ (Purpose)',
                    hintText: 'દા.ત. JioMart Delivery',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'કેટેગરી પસંદ કરો:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('ફૂડ / ગ્રોસરી'),
                      selected: selectedCategory == 'food',
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedCategory = 'food');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('પાર્સલ'),
                      selected: selectedCategory == 'parcel',
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedCategory = 'parcel');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('સર્વિસ / અન્ય'),
                      selected: selectedCategory == 'other',
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedCategory = 'other');
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('રદ કરો'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, true);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                child: const Text('ઉમેરો'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final name = nameCtrl.text.trim();
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : (selectedCategory == 'food' || selectedCategory == 'parcel')
              ? "$name Delivery"
              : "$name Visit";

      final Color partnerColor = selectedCategory == 'food'
          ? const Color(0xFFEA580C)
          : (selectedCategory == 'parcel' ? const Color(0xFF2563EB) : const Color(0xFF0D9488));

      final newPartner = {
        'name': name,
        'label': label,
        'category': selectedCategory,
        'color': partnerColor,
        'icon': Icons.label_important_rounded,
        'isCustom': true,
      };

      setState(() {
        _customPartners.removeWhere((p) => p['name'] == name);
        _customPartners.add(newPartner);
        _purposeController.text = label;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = name;
        }
      });

      try {
        final sid = SocietyService.instance.societyId;
        await AppFirestore.instance.collection('society_settings').doc(sid).set({
          'customVisitorCategories': FieldValue.arrayUnion([
            {
              'name': name,
              'label': label,
              'category': selectedCategory,
              'color': partnerColor.toARGB32(),
            }
          ])
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _processedIds = []; // જે એન્ટ્રીનો અવાજ આવી ગયો હોય તેની યાદી
  List<QueryDocumentSnapshot> _preApprovedResults = [];

  void _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}
  }

  void _checkAndPlaySound(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final m = doc.data() as Map<String, dynamic>;
      final status = m['status'] ?? 'pending';
      if ((status == 'approved' || status == 'rejected') && !_processedIds.contains(doc.id)) {
        _processedIds.add(doc.id);
        _playAlertSound();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
      _loadAllSocietyMembers();
      _loadCustomPartners();
    });
  }

  Future<DocumentSnapshot> _loadSocietyConfigDoc() async {
    final sid = SocietyService.instance.societyId;
    final modern = await AppFirestore.instance
        .collection('society_settings')
        .doc(sid)
        .get();
    if (modern.exists) return modern;
    if (sid == SocietyService.kDefaultSocietyId) {
      return AppFirestore.instance
          .collection('settings')
          .doc('society_config')
          .get();
    }
    return modern;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (pickedFile != null && mounted) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Camera capture error: $e");
      if (mounted) {
        _showSnackBar(
          'કેમેરા શરૂ કરવામાં મુશ્કેલી આવી. કૃપા કરીને ફરી પ્રયાસ કરો.',
          Colors.orange,
        );
      }
    }
  }

  // સોસાયટીના તમામ મેમ્બર્સ લોડ કરવા
  Future<void> _loadAllSocietyMembers() async {
    if (!mounted) return;
    setState(() => _isLoadingMembers = true);
    try {
      final sid = SocietyService.instance.societyId;
      QuerySnapshot snapshot;
      try {
        snapshot = await AppFirestore.instance
            .collection('users')
            .where('societyId', isEqualTo: sid)
            .where('role', isEqualTo: 'member')
            .get();
      } catch (_) {
        snapshot = await AppFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'member')
            .get();
      }

      final members = snapshot.docs
          .where(
            (doc) => SocietyService.instance.documentBelongsToCurrentTenant(
              doc.data() as Map<String, dynamic>?,
            ),
          )
          .map(
            (doc) => UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      members.sort((a, b) {
        final bA = SocietyService.instance
            .logicalBlockName(a.blockName ?? '')
            .trim();
        final bB = SocietyService.instance
            .logicalBlockName(b.blockName ?? '')
            .trim();
        if (bA.toLowerCase() != bB.toLowerCase()) {
          return bA.compareTo(bB);
        }
        final uA = int.tryParse((a.unitNumber ?? '').trim()) ?? 0;
        final uB = int.tryParse((b.unitNumber ?? '').trim()) ?? 0;
        if (uA != 0 && uB != 0) return uA.compareTo(uB);
        return (a.unitNumber ?? '').compareTo(b.unitNumber ?? '');
      });

      if (!mounted) return;
      setState(() {
        _allMembers = members;
        _isLoadingMembers = false;
        _applyMemberFilter();
      });
    } catch (e) {
      debugPrint("Error loading members: $e");
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  void _applyMemberFilter() {
    final cleanBlock = (_selectedBlock != null &&
            _selectedBlock!.isNotEmpty &&
            _selectedBlock != '__all__')
        ? SocietyService.instance
            .logicalBlockName(_selectedBlock!)
            .trim()
            .toLowerCase()
        : null;

    setState(() {
      _filteredMembers = _allMembers.where((m) {
        if (cleanBlock != null && cleanBlock.isNotEmpty) {
          final mBlockRaw = (m.blockName ?? '').trim().toLowerCase();
          final mBlockClean = SocietyService.instance
              .logicalBlockName(m.blockName ?? '')
              .trim()
              .toLowerCase();
          if (mBlockRaw != cleanBlock && mBlockClean != cleanBlock) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  Future<void> _fetchMembersByBlock(String blockName) async {
    _selectedBlock = blockName;
    _applyMemberFilter();
  }

  // મહેમાન પ્રી-એપ્રુવ્ડ છે કે નહીં તે ચેક કરવા માટે
  Future<void> _checkPreApproval(String name) async {
    if (name.length < 3) {
      setState(() => _preApprovedResults = []);
      return;
    }

    var snapshot = await AppFirestore.instance
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

    var userDoc = await AppFirestore.instance
        .collection('users')
        .doc(memberId)
        .get();
    UserModel member = UserModel.fromMap(
      userDoc.data() as Map<String, dynamic>,
      userDoc.id,
    );

    if (!_allMembers.any((m) => m.uid == member.uid)) {
      _allMembers.add(member);
    }

    setState(() {
      _isAllSociety = false;
      _selectedBlock = member.blockName != null
          ? SocietyService.instance.logicalBlockName(member.blockName!)
          : null;
      _selectedMembers = [member];
      _purposeController.text = "Pre-Approved Guest";
      _nameController.text = data['guestName'] ?? '';
      _preApprovedResults = [];
      _applyMemberFilter();
    });

    _showSnackBar("${member.name} ના મહેમાન મળ્યા!", Colors.blue);
  }

  // ૩. એન્ટ્રી સબમિટ અને નોટિફિકેશન ટ્રિગર
  Future<void> _submitEntry() async {
    final isAllSociety = _isAllSociety;
    if (_image == null ||
        _nameController.text.trim().isEmpty ||
        (!isAllSociety && _selectedMembers.isEmpty)) {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar('કૃપા કરીને મુલાકાતીનું નામ દાખલ કરો.', Colors.orange);
      } else if (_image == null) {
        _showSnackBar('કૃપા કરીને મુલાકાતીનો ફોટો લો.', Colors.orange);
      } else {
        _showSnackBar('કૃપા કરીને મુલાકાત માટે ફ્લેટ પસંદ કરો.', Colors.orange);
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      // સ્ટોરેજમાં ફોટો અપલોડ
      String photoUrl = "";
      if (_image != null) {
        String fileName = 'visitors/${DateTime.now().millisecondsSinceEpoch}.jpg';
        try {
          final uploadTask =
              await FirebaseStorage.instance.ref(fileName).putFile(_image!);
          photoUrl = await uploadTask.ref.getDownloadURL();
        } catch (e) {
          debugPrint('Storage upload error: $e');
        }
      }

      final isAllSociety = _selectedMembers.first.uid == kAllMembersPseudo.uid;
      bool isPreApproved = _purposeController.text == "Pre-Approved Guest";
      final guestName = _nameController.text.trim();

      if (isAllSociety) {
        await AppFirestore.instance.collection('visitors').add({
          'name': guestName,
          'phone': _phoneController.text.trim(),
          'purpose': _purposeController.text.trim(),
          'watchmanId': FirebaseAuth.instance.currentUser!.uid,
          'photoUrl': photoUrl,
          'memberId': 'all_society',
          'memberName': 'આખી સોસાયટી (All Society)',
          'blockName': _selectedBlock ?? 'All',
          'unitNumber': 'All',
          'status': 'approved',
          'entryTime': FieldValue.serverTimestamp(),
          'societyId': SocietyService.instance.societyId,
        });

        _clearForm();
        if (!mounted) return;
        _showSnackBar(
          'એન્ટ્રી સફળ. આખી સોસાયટી માટે વિઝિટર એન્ટ્રી નોંધાઈ ગઈ છે.',
          Colors.green,
        );
        _tabController.animateTo(1);
      } else {
        // Multi-Flat or Single-Flat Visit
        final batch = AppFirestore.instance.batch();
        for (final m in _selectedMembers) {
          final docRef = AppFirestore.instance.collection('visitors').doc();
          batch.set(docRef, {
            'name': guestName,
            'phone': _phoneController.text.trim(),
            'purpose': _purposeController.text.trim(),
            'watchmanId': FirebaseAuth.instance.currentUser!.uid,
            'photoUrl': photoUrl,
            'memberId': m.uid,
            'memberName': m.name,
            'blockName': m.blockName ?? _selectedBlock ?? '',
            'unitNumber': m.unitNumber ?? '',
            'status': isPreApproved ? 'approved' : 'pending',
            'entryTime': FieldValue.serverTimestamp(),
            'societyId': SocietyService.instance.societyId,
            'multiFlatCount': _selectedMembers.length,
          });
        }
        await batch.commit();

        for (final m in _selectedMembers) {
          unawaited(_notifyMemberPush(
            memberUid: m.uid,
            title: 'નવા મુલાકાતી (Gate Alert)',
            body: '$guestName તમને મળવા આવ્યા છે.',
            type: 'visitor_alert',
          ));
        }

        _clearForm();
        if (!mounted) return;
        _showSnackBar(
          'એન્ટ્રી સફળ. ${_selectedMembers.length} ફ્લેટના સભ્યોને જાણ કરવામાં આવી છે.',
          Colors.green,
        );
        _tabController.animateTo(1);
      }
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
      _selectedBlock = null;
      _isAllSociety = false;
      _allowMultipleFlats = false;
      _selectedMembers.clear();
      _applyMemberFilter();
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.40,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.quick_contacts_dialer_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ડિરેક્ટરી & સોસાયટી સ્ટાફ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "ઇમરજન્સી હેલ્પલાઇન અને દૈનિક સ્ટાફ સંપર્ક",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF64748B),
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Content List
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        24 + (bottomPadding > 0 ? bottomPadding : 16),
                      ),
                      children: [
                        // Section 1: Emergency Contacts
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ઈમરજન્સી કોન્ટેક્ટ્સ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "તાત્કાલિક મદદ",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    FutureBuilder<DocumentSnapshot>(
                      future: _loadSocietyConfigDoc(),
                      builder: (context, snap) {
                        if (!snap.hasData || !snap.data!.exists) {
                          return _buildEmptyContactNotice(
                            icon: Icons.contact_phone_outlined,
                            title: 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયા નથી',
                            subtitle:
                                'એડમિન દ્વારા પોલીસ, ફાયર, એમ્બ્યુલન્સ અથવા સિક્યુરિટી હેલ્પલાઇન નંબર ઉમેરવામાં આવશે.',
                            isEmergency: true,
                          );
                        }
                        final rawData = snap.data!.data();
                        if (rawData == null) {
                          return _buildEmptyContactNotice(
                            icon: Icons.contact_phone_outlined,
                            title: 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયા નથી',
                            subtitle:
                                'એડમિન દ્વારા પોલીસ, ફાયર, એમ્બ્યુલન્સ અથવા સિક્યુરિટી હેલ્પલાઇન નંબર ઉમેરવામાં આવશે.',
                            isEmergency: true,
                          );
                        }
                        final settingsMap =
                            Map<String, dynamic>.from(rawData as Map);
                        final raw = settingsMap['emergencyContacts'];
                        if (raw is! List || raw.isEmpty) {
                          return _buildEmptyContactNotice(
                            icon: Icons.contact_phone_outlined,
                            title: 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયા નથી',
                            subtitle:
                                'એડમિન દ્વારા પોલીસ, ફાયર, એમ્બ્યુલન્સ અથવા સિક્યુરિટી હેલ્પલાઇન નંબર ઉમેરવામાં આવશે.',
                            isEmergency: true,
                          );
                        }
                        final emergList = raw;

                        return Column(
                          children: emergList.map<Widget>((e) {
                            if (e is! Map) return const SizedBox.shrink();
                            final m = Map<String, dynamic>.from(e);
                            final name = '${m['name'] ?? ''}';
                            final phone = '${m['phone'] ?? ''}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFECDD3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF991B1B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _callPhone(phone),
                                      icon: const Icon(
                                        Icons.call_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'કૉલ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Section 2: Daily Staff
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            size: 15,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'મેમ્બર્સનો કાયમી સ્ટાફ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "દૈનિક સ્ટાફ",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: AppFirestore.instance
                          .collection('daily_staff')
                          .orderBy('createdAt', descending: true)
                          .limit(100)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          );
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
                          return _buildEmptyContactNotice(
                            icon: Icons.badge_outlined,
                            title: 'કોઈ કાયમી સ્ટાફ નોંધાયો નથી',
                            subtitle:
                                'સોસાયટી મેઇડ, ડ્રાઇવર, સિક્યુરિટી કે માળીની નોંધણી સભ્યો દ્વારા ઉમેર્યા પછી અહીં જોવા મળશે.',
                            isEmergency: false,
                          );
                        }

                        return Column(
                          children: docs.map((d) {
                            final m = d.data() as Map<String, dynamic>;
                            final staffName = '${m['staffName'] ?? ''}';
                            final staffRole = '${m['staffRole'] ?? ''}';
                            final staffPhone = '${m['staffPhone'] ?? ''}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staffName,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (staffRole.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  staffRole,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            if (staffRole.isNotEmpty &&
                                                staffPhone.isNotEmpty)
                                              const SizedBox(width: 6),
                                            if (staffPhone.isNotEmpty)
                                              Text(
                                                staffPhone,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (staffPhone.isNotEmpty)
                                    IconButton(
                                      onPressed: () => _callPhone(staffPhone),
                                      icon: const Icon(
                                        Icons.call_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 20,
                                      ),
                                      splashRadius: 18,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildEmptyContactNotice({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEmergency,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isEmergency ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmergency
                  ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                  : const Color(0xFF4F46E5).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEmergency
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isEmergency
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isEmergency
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openVehicleLookupDialog() {
    WatchmanVehicleLookupSheet.show(
      context,
      onNotifyMemberPush: _notifyMemberPush,
      onShowSnackBar: _showSnackBar,
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFDC2626).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          content,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "⚠️ તમામ સોસાયટી એડમિનના ફોનમાં તાત્કાલિક સાયરન એલર્ટ વાગશે.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            "ના, રદ કરો",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.emergency_rounded, size: 16),
                          label: const Text(
                            "હા, SOS મોકલો",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            _buildPremiumHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEntryForm(),
                  _buildVisitorHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Ultra Pro Premium Header ---
  Widget _buildPremiumHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    final activeIndex = _tabController.index;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 6, 16, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A), // Deep Slate Navy
            Color(0xFF1E1B4B), // Rich Indigo Slate
            Color(0xFF312E81), // Royal Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single Compact Row: Title + Live Status Badge + Action Buttons
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ગેટ કન્ટ્રોલ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 10, color: Color(0xFF34D399)),
                        SizedBox(width: 3),
                        Text(
                          "LIVE",
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildHeaderCircleAction(
                icon: Icons.directions_car_filled_rounded,
                tooltip: 'વાહન સર્ચ (Vehicle Search)',
                onTap: _openVehicleLookupDialog,
              ),
              const SizedBox(width: 6),
              _buildHeaderCircleAction(
                icon: Icons.contact_phone_rounded,
                tooltip: 'ઈમરજન્સી & સ્ટાફ',
                onTap: _openContactsAndStaffSheet,
              ),
              const SizedBox(width: 6),
              _buildHeaderCircleAction(
                icon: Icons.warning_amber_rounded,
                tooltip: 'ઇમરજન્સી SOS એલર્ટ',
                color: const Color(0xFFF59E0B),
                onTap: _sendSOS,
              ),
              const SizedBox(width: 6),
              _buildHeaderCircleAction(
                icon: Icons.logout_rounded,
                tooltip: 'લોગઆઉટ',
                onTap: () async {
                  final confirm = await PremiumLogoutDialog.show(
                    context,
                    roleName: 'વોચમેન ગેટ સિસ્ટમ',
                  );
                  if (confirm) {
                    await SessionGuardService.instance.clearSession();
                    await FirebaseAuth.instance.signOut();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented Navigation Pill Tabs
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentedTabButton(
                    index: 0,
                    isActive: activeIndex == 0,
                    icon: Icons.person_add_rounded,
                    label: "નવી એન્ટ્રી (New Entry)",
                  ),
                ),
                Expanded(
                  child: _buildSegmentedTabButton(
                    index: 1,
                    isActive: activeIndex == 1,
                    icon: Icons.history_rounded,
                    label: "મુલાકાત હિસ્ટ્રી (Logs)",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCircleAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabButton({
    required int index,
    required bool isActive,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VIP EVENT BANNER (આજની ઇવેન્ટ્સ) ---
  Widget _buildTodayEventsBanner() {
    return StreamBuilder<List<AmenityBookingModel>>(
      stream: AmenityBookingService.instance.getTodayEventsStream(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const SizedBox.shrink();

        final event = events.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amberAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.celebration_rounded, color: Colors.amberAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'આજનો પ્રસંગ (Today Event)',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (event.eventPassCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'પાસકોડ: ${event.eventPassCode}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${event.amenityName} • ${event.purpose}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'આયોજક: ${event.memberName} (ફ્લેટ ${event.unitDisplay}) • ${event.slotName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _purposeController.text = '${event.amenityName} - ${event.purpose}';
                      _nameController.text = 'ઇવેન્ટ મહેમાન (Guest)';
                      _selectedBlock = SocietyService.instance.logicalBlockName(event.unitDisplay.split('-').first);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${event.amenityName} ના મહેમાન માટે ફોર્મ ઓટો-સેટ થઈ ગયું.'),
                        backgroundColor: const Color(0xFF0F766E),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on_rounded, size: 15, color: Colors.amberAccent),
                  label: const Text(
                    'ઇવેન્ટ મહેમાન ત્વરિત એન્ટ્રી (Quick Entry)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNightPatrolQuickBanner() {
    final sid = SocietyService.instance.societyId;
    final user = FirebaseAuth.instance.currentUser;
    final guardUid = user?.uid ?? '';
    final guardName = user?.displayName ?? 'સુરક્ષા ગાર્ડ';
    final guardPhone = user?.phoneNumber ?? '';

    return StreamBuilder<PatrolShiftSession?>(
      stream: GuardPatrolService().streamActiveSession(sid, guardUid),
      builder: (context, snapshot) {
        final active = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active != null
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WatchmanPatrolScreen(
                      societyId: sid,
                      guardUid: guardUid,
                      guardName: guardName,
                      guardPhone: guardPhone,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (active != null
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF818CF8))
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        active != null
                            ? Icons.radar_rounded
                            : Icons.shield_moon_rounded,
                        color: const Color(0xFF818CF8),
                        size: 24,
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
                                active != null
                                    ? '🚨 પેટ્રોલિંગ રાઉન્ડ ચાલુ છે'
                                    : 'રાત્રિ સુરક્ષા પેટ્રોલિંગ (Night Patrol)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (active != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${active.progressPercent}%',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            active != null
                                ? '${active.roundLabel}: ${active.scannedCount}/${active.totalCheckpoints} ચેકપોઇન્ટ્સ સ્કેન થયા'
                                : 'QR સ્કેન રાઉન્ડ શરૂ કરો અને ચેકપોઇન્ટ્સ ઓડિટ કરો',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF94A3B8),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI: વિઝિટર એન્ટ્રી ફોર્મ (Ultra Pro Premium & Spacious) ---
  Widget _buildEntryForm() {
    final isAllSocietyActive = _isAllSociety;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════
          // VIP EVENT BANNER (જો આજે વાડી/હોલમાં પ્રસંગ હોય)
          // ══════════════════════════════════════════════════
          _buildTodayEventsBanner(),

          // ══════════════════════════════════════════════════
          // NIGHT PATROL QUICK BANNER (રાત્રિ સુરક્ષા ઓડિટ)
          // ══════════════════════════════════════════════════
          _buildNightPatrolQuickBanner(),

          // ══════════════════════════════════════════════════
          // CARD 1: મુલાકાતી પ્રોફાઇલ (Visitor Profile)
          // ══════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "મુલાકાતીની વિગત (Visitor Details)",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Side-by-Side: Photo Avatar + Visitor Name Field with QR Scanner
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Avatar (Tap to capture / retake)
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: _image != null
                                  ? Colors.transparent
                                  : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _image != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFC7D2FE),
                                width: 1.5,
                              ),
                            ),
                            child: _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                      width: 58,
                                      height: 58,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 24,
                                        color: Color(0xFF4F46E5),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "ફોટો",
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (_image != null)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Visitor Name TextField with QR Scan inside suffix
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        onChanged: (value) {
                          if (value.length >= 3) {
                            _checkPreApproval(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "મુલાકાતીનું નામ *",
                          hintText: "નામ લખો...",
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_nameController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _nameController.clear();
                                      setState(() => _preApprovedResults = []);
                                    },
                                  ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _openQRScanner,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF59E0B),
                                            Color(0xFFD97706),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.qr_code_scanner_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            "QR",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF4F46E5),
                              width: 1.6,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Pre-Approved Guest Matches (if any)
                if (_preApprovedResults.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF60A5FA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${_preApprovedResults.length} પ્રી-એપ્રુવ્ડ મહેમાન મળ્યા (Tap to select)",
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._preApprovedResults.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return InkWell(
                            onTap: () => _selectPreApprovedGuest(doc),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF2563EB),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${data['guestName']} • Pre-Approved",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Mobile Number TextField
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "મોબાઇલ નંબર (Mobile No)",
                    hintText: "10 અંકનો મોબાઈલ નંબર દાખલ કરો...",
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF4F46E5),
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ⚡ Ultra Premium & Spacious 1-Tap Quick Fill Section
                _buildQuickFillSection(),

                const SizedBox(height: 14),

                // Purpose TextField with instant clear & clean styling
                TextField(
                  controller: _purposeController,
                  onChanged: (val) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: "મુલાકાતનું કારણ (Purpose)",
                    hintText: "દા.ત. ડિલિવરી, મહેમાન, સર્વિસ, કુરિયર...",
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF4F46E5),
                      size: 18,
                    ),
                    suffixIcon: _purposeController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              setState(() {
                                _purposeController.clear();
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF4F46E5),
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ══════════════════════════════════════════════════
          // CARD 2: મુલાકાતનું સ્થળ (Destination - Flat / Society)
          // ══════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header + Refresh button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "કોના ઘરે મુલાકાત છે? (Destination)",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            "ફ્લેટ અથવા આખી સોસાયટી પસંદ કરો",
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingMembers)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 19,
                          color: Color(0xFF4F46E5),
                        ),
                        tooltip: "સભ્યો ફરી લોડ કરો",
                        onPressed: _loadAllSocietyMembers,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destination Mode Switcher: [ 🏢 ફ્લેટ પસંદ કરો ] vs [ 🌐 આખી સોસાયટી ]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isAllSociety = false;
                              _selectedMembers.removeWhere(
                                  (m) => m.uid == kAllMembersPseudo.uid);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !isAllSocietyActive
                                  ? const Color(0xFF4F46E5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: !isAllSocietyActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.35),
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
                                  Icons.door_front_door_rounded,
                                  size: 16,
                                  color: !isAllSocietyActive
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "ફ્લેટ પસંદ કરો",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: !isAllSocietyActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: !isAllSocietyActive
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isAllSociety = true;
                              _selectedBlock = null;
                              _selectedMembers = [kAllMembersPseudo];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isAllSocietyActive
                                  ? const Color(0xFF059669)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: isAllSocietyActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF059669)
                                            .withValues(alpha: 0.35),
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
                                  Icons.public_rounded,
                                  size: 16,
                                  color: isAllSocietyActive
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "આખી સોસાયટી",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isAllSocietyActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isAllSocietyActive
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mode 1: All Society Active
                if (isAllSocietyActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFECFDF5),
                          const Color(0xFFD1FAE5).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "આખી સોસાયટી (બધા બ્લોક & ફ્લેટ)",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "સરકારી, સર્વે, સોસાયટી જનરલ મુલાકાતી માટે",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Mode 2: Individual Flat Selection (Spacious & Premium View)
                  StreamBuilder<QuerySnapshot>(
                    stream: AppFirestore.instance
                        .collection('blocks')
                        .snapshots(),
                    builder: (context, snap) {
                      final blockDocs = (snap.data?.docs ?? [])
                          .where(
                            (d) => SocietyService.instance
                                .documentBelongsToCurrentTenant(
                              d.data() as Map<String, dynamic>?,
                            ),
                          )
                          .toList();

                      final availableBlocks = <String>{};
                      for (final d in blockDocs) {
                        final raw = (d.data() as Map<String, dynamic>?)?['name']
                                ?.toString() ??
                            d.id;
                        final clean = SocietyService.instance
                            .logicalBlockName(raw)
                            .trim();
                        if (clean.isNotEmpty) availableBlocks.add(clean);
                      }
                      for (final m in _allMembers) {
                        final b = m.blockName?.trim();
                        if (b != null && b.isNotEmpty) {
                          availableBlocks.add(
                            SocietyService.instance.logicalBlockName(b),
                          );
                        }
                      }
                      final sortedBlocks = availableBlocks.toList()..sort();

                      final cleanSelected = _selectedBlock != null
                          ? SocietyService.instance
                              .logicalBlockName(_selectedBlock!)
                              .trim()
                          : null;
                      final isAllBlocks = (cleanSelected == null ||
                          cleanSelected.isEmpty ||
                          cleanSelected == '__all__');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1) Horizontal Block Filter Strip
                          Row(
                            children: [
                              const Icon(
                                Icons.domain_rounded,
                                size: 14,
                                color: Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "બ્લોક પસંદગી:",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const Spacer(),
                              if (!isAllBlocks)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedBlock = null;
                                      _applyMemberFilter();
                                    });
                                  },
                                  child: const Text(
                                    "બધા બ્લોક જુઓ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          SizedBox(
                            height: 34,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildBlockPill(
                                  '__all__',
                                  '🏢 બધા બ્લોક',
                                  isAllBlocks,
                                  () {
                                    setState(() {
                                      _selectedBlock = null;
                                      _applyMemberFilter();
                                    });
                                  },
                                ),
                                ...sortedBlocks.map(
                                  (b) => _buildBlockPill(
                                    b,
                                    'બ્લોક $b',
                                    cleanSelected == b,
                                    () {
                                      setState(() {
                                        _selectedBlock = b;
                                        _applyMemberFilter();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2) Flat Selection Trigger or Selected Flat Cards
                          if (_selectedMembers.isEmpty) ...[
                            // Trigger Card to open searchable sheet
                            InkWell(
                              onTap: () => _openFlatPickerSheet(sortedBlocks),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (cleanSelected != null &&
                                                    cleanSelected.isNotEmpty)
                                                ? "બ્લોક $cleanSelected નો ફ્લેટ પસંદ કરો *"
                                                : "ફ્લેટ પસંદ કરો (Search Flat) *",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isLoadingMembers
                                                ? "સભ્યો લોડ થઈ રહ્યા છે..."
                                                : (_filteredMembers.isEmpty
                                                    ? "આ બ્લોકમાં કોઈ ફ્લેટ નથી"
                                                    : "ટૅપ કરીને ફ્લેટ નંબર અથવા નામ શોધો..."),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _filteredMembers.isEmpty
                                                  ? Colors.red.shade600
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "શોધો",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Quick 1-tap flat suggestions row
                            if (_filteredMembers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    "ઝડપી પસંદગી:",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () =>
                                        _openFlatPickerSheet(sortedBlocks),
                                    child: const Text(
                                      "બધા જુઓ >",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 32,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _filteredMembers.length > 7
                                      ? 7
                                      : _filteredMembers.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (context, idx) {
                                    final m = _filteredMembers[idx];
                                    final b = (m.blockName != null &&
                                            m.blockName!.trim().isNotEmpty)
                                        ? SocietyService.instance
                                            .logicalBlockName(m.blockName!)
                                        : '';
                                    final u = (m.unitNumber != null &&
                                            m.unitNumber!.trim().isNotEmpty)
                                        ? m.unitNumber!
                                        : '';
                                    final label = b.isNotEmpty
                                        ? '$b-$u'
                                        : (u.isNotEmpty ? 'ફ્લેટ $u' : m.name);

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedMembers = [m];
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.home_rounded,
                                              size: 12,
                                              color: Color(0xFF4F46E5),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ] else ...[
                            // Executive Selected Flat Destination Cards
                            Row(
                              children: [
                                Text(
                                  _selectedMembers.length == 1
                                      ? "પસંદ કરેલ ફ્લેટ:"
                                      : "પસંદ કરેલ ફ્લેટ (${_selectedMembers.length}):",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _allowMultipleFlats = true;
                                    });
                                    _openFlatPickerSheet(sortedBlocks);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFC7D2FE),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          size: 13,
                                          color: Color(0xFF4F46E5),
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          "+ બીજો ફ્લેટ",
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedMembers.clear();
                                      _allowMultipleFlats = false;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      "બધા હટાવો",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Destination Cards
                            ..._selectedMembers.map((m) {
                              final b = (m.blockName != null &&
                                      m.blockName!.trim().isNotEmpty)
                                  ? SocietyService.instance
                                      .logicalBlockName(m.blockName!)
                                  : '';
                              final u = (m.unitNumber != null &&
                                      m.unitNumber!.trim().isNotEmpty)
                                  ? m.unitNumber!
                                  : '';
                              final badgeLabel = b.isNotEmpty
                                  ? '$b - $u'
                                  : (u.isNotEmpty ? 'ફ્લેટ $u' : 'ઘર');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF8FAFC),
                                      Color(0xFFEEF2FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFC7D2FE),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.name,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (m.phone != null &&
                                                    m.phone!.isNotEmpty)
                                                ? "📞 ${m.phone}"
                                                : "🏡 સોસાયટી રહેવાસી",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      splashRadius: 18,
                                      onPressed: () {
                                        setState(() {
                                          _selectedMembers.remove(m);
                                          if (_selectedMembers.isEmpty) {
                                            _allowMultipleFlats = false;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Multi-flat alert note if multiple selected
                            if (_selectedMembers.length > 1) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_rounded,
                                      size: 14,
                                      color: Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "મલ્ટિ-ફ્લેટ વિઝિટ: તમામ ${_selectedMembers.length} સભ્યોને એકસાથે ગેટ એલર્ટ નોટિફિકેશન જશે.",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFB45309),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════
          // PRIMARY SUBMIT ACTION BUTTON
          // ══════════════════════════════════════════════════
          _isUploading
              ? Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "એન્ટ્રી સેવ અને નોટિફિકેશન મોકલાઈ રહ્યું છે...",
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _submitEntry,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "એન્ટ્રી કરો અને મેમ્બરને જાણ કરો",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ⚡ ULTRA PRO 1-TAP QUICK FILL SECTION & HELPER WIDGETS
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuickFillSection() {
    final displayedPartners = _quickFilterCategory == 'all'
        ? _allPartners
        : _allPartners
            .where((p) => p['category'] == _quickFilterCategory)
            .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Amber Lightning Icon & Clear action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ઝડપી સિલેક્શન (1-Tap Quick Fill)",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      "એક જ ટૅપમાં ડિલિવરી કે મુલાકાત પ્રકાર સેટ કરો",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (_purposeController.text.isNotEmpty)
                InkWell(
                  onTap: () {
                    setState(() {
                      _purposeController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 3),
                        Text(
                          "સાફ કરો",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Category filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickCategoryTab(
                  id: 'all',
                  label: 'બધા (${_allPartners.length})',
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(width: 6),
                _buildQuickCategoryTab(
                  id: 'food',
                  label: 'ફૂડ & ગ્રોસરી',
                  icon: Icons.fastfood_rounded,
                ),
                const SizedBox(width: 6),
                _buildQuickCategoryTab(
                  id: 'parcel',
                  label: 'પાર્સલ & કુરિયર',
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(width: 6),
                _buildQuickCategoryTab(
                  id: 'other',
                  label: 'સર્વિસ & મુલાકાત',
                  icon: Icons.people_alt_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Spacious & Tactile Wrap Grid of Partner Chips
          Wrap(
            spacing: 8,
            runSpacing: 9,
            children: [
              ...displayedPartners
                  .map((partner) => _buildQuickPartnerChip(partner)),
              _buildAddPartnerChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPartnerChip() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddPartnerDialog,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFC7D2FE),
              width: 1.1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 13,
                color: Color(0xFF4F46E5),
              ),
              SizedBox(width: 4),
              Text(
                "+ નવો પ્રકાર",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCategoryTab({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _quickFilterCategory == id;
    return InkWell(
      onTap: () => setState(() => _quickFilterCategory = id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPartnerChip(Map<String, dynamic> partner) {
    final label = partner['label'] as String;
    final isSelected = _purposeController.text == label;
    final color = partner['color'] as Color;
    final name = partner['name'] as String;
    final icon = partner['icon'] as IconData;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _purposeController.clear();
            } else {
              _purposeController.text = label;
              if (_nameController.text.trim().isEmpty) {
                if (partner['category'] == 'food' ||
                    partner['category'] == 'parcel') {
                  _nameController.text = "$name Delivery";
                } else if (name.contains('કેબ')) {
                  _nameController.text = "કેબ ડ્રાઇવર (Cab)";
                } else if (name.contains('સર્વિસ')) {
                  _nameController.text = "સર્વિસ પર્સન (Service)";
                } else if (name.contains('મહેમાન')) {
                  _nameController.text = "મહેમાન (Guest)";
                }
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                name,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
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
      stream: AppFirestore.instance
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              _buildModernStatTile(
                title: 'આજે',
                subtitle: 'Today',
                count: total,
                icon: Icons.groups_rounded,
                baseColor: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFEEF2FF),
                isSelected: _historyStatusFilter == 'all' && _historyTimeFilter == 'today',
                onTap: () {
                  setState(() {
                    _historyStatusFilter = 'all';
                    _historyTimeFilter = 'today';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildModernStatTile(
                title: 'પેન્ડિંગ',
                subtitle: 'Pending',
                count: pending,
                icon: Icons.hourglass_top_rounded,
                baseColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
                isSelected: _historyStatusFilter == 'pending',
                onTap: () {
                  setState(() {
                    _historyStatusFilter =
                        _historyStatusFilter == 'pending' ? 'all' : 'pending';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildModernStatTile(
                title: 'અંદર',
                subtitle: 'Inside',
                count: approved,
                icon: Icons.login_rounded,
                baseColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                isSelected: _historyStatusFilter == 'approved',
                onTap: () {
                  setState(() {
                    _historyStatusFilter =
                        _historyStatusFilter == 'approved' ? 'all' : 'approved';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildModernStatTile(
                title: 'બહાર',
                subtitle: 'Out',
                count: checkedOut,
                icon: Icons.logout_rounded,
                baseColor: const Color(0xFF64748B),
                bgColor: const Color(0xFFF1F5F9),
                isSelected: _historyStatusFilter == 'checked_out',
                onTap: () {
                  setState(() {
                    _historyStatusFilter =
                        _historyStatusFilter == 'checked_out' ? 'all' : 'checked_out';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatTile({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color baseColor,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? baseColor : baseColor.withValues(alpha: 0.18),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: isSelected ? 0.16 : 0.05),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? baseColor : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : baseColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: baseColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? baseColor : Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      _showSnackBar('ફોન નંબર ઉપલબ્ધ નથી', Colors.orange);
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('કૉલ શરૂ કરી શકાયો નહીં', Colors.red);
      }
    } catch (e) {
      _showSnackBar('કૉલ શરૂ કરવામાં ભૂલ: $e', Colors.red);
    }
  }

  Widget _buildTimeFilterMenu() {
    final Map<String, String> shortLabels = {
      'today': 'આજે',
      '7d': '7 Days',
      '30d': '30 Days',
    };
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        initialValue: _historyTimeFilter,
        tooltip: 'સમયગાળો પસંદ કરો',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (val) {
          setState(() => _historyTimeFilter = val);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'today',
            child: Row(
              children: [
                Icon(Icons.today_rounded, size: 18, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'આજની એન્ટ્રી (Today)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: '7d',
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 18,
                  color: Color(0xFF4F46E5),
                ),
                SizedBox(width: 8),
                Text(
                  'છેલ્લા ૭ દિવસ (7 Days)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: '30d',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFF4F46E5),
                ),
                SizedBox(width: 8),
                Text(
                  'છેલ્લા ૩૦ દિવસ (30 Days)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 6),
              Text(
                shortLabels[_historyTimeFilter] ?? 'આજે',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: Color(0xFF4F46E5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryStatusPill({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _historyStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _historyStatusFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckOutConfirmation(String docId, String visitorName) async {
    final confirmed = await PremiumConfirmationDialog.show(
      context,
      title: 'ચેક-આઉટ કન્ફર્મેશન',
      message: '$visitorName સોસાયટીની બહાર નીકળી ગયા છે તે કન્ફર્મ કરો છો?',
      icon: Icons.output_rounded,
      gradientColors: const [Color(0xFF475569), Color(0xFF334155)],
      cancelText: 'ના, રદ કરો',
      confirmText: 'હા, બહાર ગયા (OUT)',
      confirmColor: const Color(0xFFDC2626),
      confirmGradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
      confirmIcon: Icons.check_circle_rounded,
      isDestructive: true,
    );
    if (confirmed == true) {
      _checkOutVisitor(docId);
    }
  }

  void _showVisitorDetailSheet(Map<String, dynamic> m, String docId) {
    final status = (m['status'] ?? 'pending').toString();
    final name = (m['name'] ?? 'મહેમાન').toString().trim();
    final phone = (m['phone'] ?? '').toString().trim();
    final block = (m['blockName'] ?? '').toString().trim();
    final unit = (m['unitNumber'] ?? '').toString().trim();
    final memberName = (m['memberName'] ?? '').toString().trim();
    final purpose = (m['purpose'] ?? 'મુલાકાત').toString().trim();
    final photoUrl = (m['photoUrl'] ?? '').toString().trim();
    final vehicle = (m['vehicleNumber'] ?? m['vehicle'] ?? '').toString().trim();
    final entryTime = m['entryTime'] is Timestamp
        ? (m['entryTime'] as Timestamp).toDate()
        : null;
    final exitTime = m['exitTime'] is Timestamp
        ? (m['exitTime'] as Timestamp).toDate()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(ctx).viewInsets.bottom +
                20 +
                (bottomPadding > 0 ? bottomPadding : 12),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'G',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          )
                        : null,
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
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'હેતુ: $purpose',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty)
                    IconButton.filledTonal(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: Color(0xFF059669),
                      ),
                      onPressed: () => _callPhone(phone),
                      tooltip: 'કૉલ કરો',
                    ),
                ],
              ),
              const Divider(height: 28),
              _detailRow(
                Icons.apartment_rounded,
                'ફ્લેટ / યુનિટ',
                '$block - $unit ${memberName.isNotEmpty ? "($memberName)" : ""}',
              ),
              if (phone.isNotEmpty)
                _detailRow(Icons.phone_android_rounded, 'મોબાઈલ નંબર', phone),
              if (vehicle.isNotEmpty)
                _detailRow(Icons.directions_car_rounded, 'વાહન નંબર', vehicle),
              if (entryTime != null)
                _detailRow(
                  Icons.login_rounded,
                  'એન્ટ્રી સમય',
                  DateFormat('dd MMM yyyy, hh:mm a').format(entryTime),
                ),
              if (exitTime != null)
                _detailRow(
                  Icons.logout_rounded,
                  'એક્ઝિટ સમય',
                  DateFormat('dd MMM yyyy, hh:mm a').format(exitTime),
                ),
              const SizedBox(height: 20),
              if (status == 'approved')
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCheckOutConfirmation(docId, name);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'મહેમાન બહાર ગયા (Mark Out)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final status = (d['status'] ?? 'pending').toString();
    final name = (d['name'] ?? 'મહેમાન').toString().trim();
    final block = (d['blockName'] ?? '').toString().trim();
    final unit = (d['unitNumber'] ?? '').toString().trim();
    final purpose = (d['purpose'] ?? 'મુલાકાત').toString().trim();
    final phone = (d['phone'] ?? '').toString().trim();
    final photoUrl = (d['photoUrl'] ?? '').toString().trim();
    final vehicle = (d['vehicleNumber'] ?? d['vehicle'] ?? '').toString().trim();
    final entryTime = d['entryTime'] is Timestamp
        ? (d['entryTime'] as Timestamp).toDate()
        : null;
    final exitTime = d['exitTime'] is Timestamp
        ? (d['exitTime'] as Timestamp).toDate()
        : null;

    Color accentColor;
    Color lightBg;
    String statusText;
    IconData statusIcon;

    if (status == 'approved') {
      accentColor = const Color(0xFF10B981);
      lightBg = const Color(0xFFECFDF5);
      statusText = "અંદર છે";
      statusIcon = Icons.door_front_door_rounded;
    } else if (status == 'rejected') {
      accentColor = const Color(0xFFEF4444);
      lightBg = const Color(0xFFFEF2F2);
      statusText = "ના પાડી";
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'checked_out') {
      accentColor = const Color(0xFF64748B);
      lightBg = const Color(0xFFF1F5F9);
      statusText = "બહાર ગયા";
      statusIcon = Icons.exit_to_app_rounded;
    } else {
      accentColor = const Color(0xFFF59E0B);
      lightBg = const Color(0xFFFFFBEB);
      statusText = "રાહ જુઓ";
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showVisitorDetailSheet(d, doc.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Avatar with status ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 2),
                      color: lightBg,
                    ),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: accentColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(statusIcon, size: 9, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Visitor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Flat Badge
                        if (block.isNotEmpty || unit.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.home_rounded,
                                  size: 11,
                                  color: Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$block-$unit',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Purpose Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            purpose,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                        // Vehicle Badge
                        if (vehicle.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_car_rounded,
                                  size: 11,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  vehicle,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11.5,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          entryTime != null
                              ? DateFormat('hh:mm a').format(entryTime)
                              : '--:--',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (status == 'checked_out' && exitTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.logout_rounded,
                            size: 11.5,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'બહાર: ${DateFormat('hh:mm a').format(exitTime)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Right Action / Status
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status == 'approved')
                    ElevatedButton.icon(
                      onPressed: () => _showCheckOutConfirmation(doc.id, name),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 1,
                        shadowColor: const Color(
                          0xFFDC2626,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(68, 32),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _callPhone(phone),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(width: 2),
                            Text(
                              'કૉલ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI: આજની હિસ્ટ્રી ---

  Widget _buildVisitorHistory() {
    return Column(
      children: [
        _buildWatchmanSummaryCard(),
        // 🔍 Modern Search Bar + Time Filter Dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "નામ, ફ્લેટ કે વાહન નંબર શોધો...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildTimeFilterMenu(),
            ],
          ),
        ),
        // 🏷️ Single Sleek Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              _buildHistoryStatusPill(
                value: 'all',
                label: 'બધા (All)',
                icon: Icons.grid_view_rounded,
                color: const Color(0xFF4F46E5),
              ),
              _buildHistoryStatusPill(
                value: 'pending',
                label: 'પેન્ડિંગ',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _buildHistoryStatusPill(
                value: 'approved',
                label: 'અંદર છે',
                icon: Icons.door_front_door_rounded,
                color: const Color(0xFF10B981),
              ),
              _buildHistoryStatusPill(
                value: 'rejected',
                label: 'ના પાડી',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
              ),
              _buildHistoryStatusPill(
                value: 'checked_out',
                label: 'બહાર ગયા',
                icon: Icons.logout_rounded,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 📜 StreamBuilder for Visitor List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('હિસ્ટ્રી લોડ કરવામાં ભૂલ: ${snap.error}'),
                  ),
                );
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

              _checkAndPlaySound(tenantDocs);

              var filteredDocs = tenantDocs.where((doc) {
                final m = doc.data() as Map<String, dynamic>;
                String name = (m['name'] ?? '').toString().toLowerCase();
                String unit = (m['unitNumber'] ?? '').toString().toLowerCase();
                String block = (m['blockName'] ?? '').toString().toLowerCase();
                String phone = (m['phone'] ?? '').toString().toLowerCase();
                String purpose = (m['purpose'] ?? '').toString().toLowerCase();
                String vehicle = (m['vehicleNumber'] ?? m['vehicle'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(_searchQuery) ||
                    unit.contains(_searchQuery) ||
                    block.contains(_searchQuery) ||
                    phone.contains(_searchQuery) ||
                    purpose.contains(_searchQuery) ||
                    vehicle.contains(_searchQuery);
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC7D2FE),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_search_rounded,
                            size: 40,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'સર્ચ મુજબ કોઈ મહેમાન મળ્યા નથી.'
                              : (_historyStatusFilter != 'all'
                                  ? 'પસંદ કરેલ ફિલ્ટરમાં કોઈ મહેમાન નથી.'
                                  : 'હાલ કોઈ મુલાકાતીની નોંધ નથી.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'સર્ચ અથવા સ્ટેટસ ફિલ્ટર બદલીને ફરી તપાસો.'
                              : 'નવી એન્ટ્રી ટેબમાંથી મુલાકાતી નોંધી શકાય છે.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isEmpty &&
                            _historyStatusFilter == 'all')
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              _tabController.animateTo(0);
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'નવી એન્ટ્રી નોંધો',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                itemCount: filteredDocs.length,
                itemBuilder: (context, i) {
                  return _buildVisitorCard(filteredDocs[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Check-out કરવાનું ફંક્શન
  Future<void> _checkOutVisitor(String docId) async {
    final ref = AppFirestore.instance.collection('visitors').doc(docId);
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QRScannerSheet(
        onScanned: (code) => _processQRCode(code),
        onManualEntry: _showManualEntryDialog,
      ),
    );
  }

  void _showManualEntryDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  color: Color(0xFF4F46E5),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'પાસ કોડ દાખલ કરો',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'મહેમાનના WhatsApp અથવા SMS માં આવેલો પ્રી-અપ્રૂવલ ID લખો',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'દા.ત. PASS-1234 અથવા ID',
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'રદ કરો',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final code = codeController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.pop(ctx);
                          _processQRCode(code);
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text(
                        'ચકાસો',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  // ૨. QR ડેટા પ્રોસેસ કરવાનું લોજિક
  Future<void> _processQRCode(String preApproveId) async {
    setState(() => _isUploading = true);

    try {
      var doc = await AppFirestore.instance
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

        var userDoc = await AppFirestore.instance
            .collection('users')
            .doc(data['memberId'])
            .get();
        UserModel member = UserModel.fromMap(userDoc.data()!, userDoc.id);

        await _fetchMembersByBlock(member.blockName!);

        setState(() {
          _isAllSociety = false;
          _allowMultipleFlats = false;
          _nameController.text = data['guestName'] ?? ""; // નામ ઓટો-ફિલ
          _phoneController.text =
              data['guestPhone'] ?? ""; // 🔥 આ લાઈનથી મોબાઈલ નંબર ઓટો-ફિલ થશે

          _selectedBlock = member.blockName;
          final matchedMember = _filteredMembers.firstWhere(
            (m) => m.uid == member.uid,
            orElse: () => member,
          );
          _selectedMembers = [matchedMember];
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

  Widget _buildBlockPill(
    String id,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  void _openFlatPickerSheet(List<String> sortedBlocks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _FlatPickerSheet(
          allMembers: _allMembers,
          sortedBlocks: sortedBlocks,
          initialBlock: _selectedBlock,
          initialSelectedMembers: List.from(_selectedMembers),
          initialAllowMultiple: _allowMultipleFlats,
          onFlatsSelected: (selectedList, isMultiple) {
            setState(() {
              _selectedMembers = selectedList;
              _allowMultipleFlats = isMultiple;
              if (selectedList.isNotEmpty && selectedList.first.blockName != null) {
                _selectedBlock = SocietyService.instance
                    .logicalBlockName(selectedList.first.blockName!);
                _applyMemberFilter();
              }
            });
          },
        );
      },
    );
  }
}

class _QRScannerSheet extends StatefulWidget {
  final ValueChanged<String> onScanned;
  final VoidCallback onManualEntry;

  const _QRScannerSheet({
    required this.onScanned,
    required this.onManualEntry,
  });

  @override
  State<_QRScannerSheet> createState() => _QRScannerSheetState();
}

class _QRScannerSheetState extends State<_QRScannerSheet>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _laserAnimation;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      cameraResolution: const Size(1280, 720),
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scanSize = 250.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectiveBottomSafe = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Midnight obsidian
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Top Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR કોડ સ્કેનર',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'મહેમાન પાસ અથવા પ્રી-અપ્રૂવ્ડ QR સ્કેન કરો',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Torch toggle button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _isTorchOn
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    icon: Icon(
                      _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color:
                          _isTorchOn ? const Color(0xFFFBBF24) : Colors.white,
                      size: 19,
                    ),
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                    tooltip: 'ટોર્ચ (Flash)',
                  ),
                  const SizedBox(width: 4),
                  // Camera switch button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    onPressed: () => _controller.switchCamera(),
                    tooltip: 'કેમેરા બદલો',
                  ),
                  const SizedBox(width: 4),
                  // Close button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Camera Area with Scanner Reticle Overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.videocam_off_rounded,
                                  size: 44,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'કેમેરા અથવા QR સ્કેનર શરૂ થઈ શક્યું નથી.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                error.errorDetails?.message ??
                                    'કૃપા કરીને કેમેરા પરમિશન આપો અથવા નીચેથી કોડ મેન્યુઅલી દાખલ કરો.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onManualEntry();
                                },
                                icon:
                                    const Icon(Icons.dialpad_rounded, size: 16),
                                label: const Text('મેન્યુઅલી કોડ દાખલ કરો'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onDetect: (capture) {
                      if (_hasScanned) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null && code.trim().isNotEmpty) {
                          _hasScanned = true;
                          _controller.stop();
                          Navigator.pop(context);
                          widget.onScanned(code.trim());
                        }
                      }
                    },
                  ),

                  // Cyberpunk Custom Painted Scanner Overlay
                  CustomPaint(
                    painter: _ScannerOverlayPainter(
                      scanWindowSize: scanSize,
                      borderRadius: 18,
                      cornerColor: const Color(0xFF6366F1),
                      cornerLength: 28,
                      cornerWidth: 4,
                    ),
                  ),

                  // Animated laser line inside scan window
                  Center(
                    child: SizedBox(
                      width: scanSize - 20,
                      height: scanSize,
                      child: AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              Positioned(
                                top: scanSize * _laserAnimation.value,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF818CF8),
                                        Color(0xFF38BDF8),
                                        Color(0xFF818CF8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.7),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Instruction badge below scan cutout
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.center_focus_strong_rounded,
                              size: 14,
                              color: Color(0xFF38BDF8),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'કેમેરા સામે ચોરસમાં QR કોડ રાખો',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Deck
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                14,
                18,
                16 + effectiveBottomSafe,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Slate 800
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onManualEntry();
                      },
                      icon: const Icon(
                        Icons.keyboard_alt_outlined,
                        size: 18,
                        color: Color(0xFF818CF8),
                      ),
                      label: const Text(
                        'સ્કેન નથી થતું? મેન્યુઅલી કોડ લખો',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '🔒 સભ્યો દ્વારા બનાવેલ ડિજિટલ ગેસ્ટ પાસ QR સ્કેન કરો',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanWindowSize;
  final double borderRadius;
  final Color cornerColor;
  final double cornerLength;
  final double cornerWidth;

  _ScannerOverlayPainter({
    required this.scanWindowSize,
    this.borderRadius = 18,
    this.cornerColor = const Color(0xFF6366F1),
    this.cornerLength = 28,
    this.cornerWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - scanWindowSize) / 2;
    final double top = (size.height - scanWindowSize) / 2;
    final Rect scanRect =
        Rect.fromLTWH(left, top, scanWindowSize, scanWindowSize);

    // Darkened background outside scan cutout
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)));
    final Path overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = borderRadius;
    final cl = cornerLength;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cl)
        ..lineTo(left, top + r)
        ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
        ..lineTo(left + cl, top),
      cornerPaint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWindowSize - cl, top)
        ..lineTo(left + scanWindowSize - r, top)
        ..arcToPoint(Offset(left + scanWindowSize, top + r),
            radius: Radius.circular(r))
        ..lineTo(left + scanWindowSize, top + cl),
      cornerPaint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanWindowSize - cl)
        ..lineTo(left, top + scanWindowSize - r)
        ..arcToPoint(Offset(left + r, top + scanWindowSize),
            radius: Radius.circular(r))
        ..lineTo(left + cl, top + scanWindowSize),
      cornerPaint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWindowSize - cl, top + scanWindowSize)
        ..lineTo(left + scanWindowSize - r, top + scanWindowSize)
        ..arcToPoint(Offset(left + scanWindowSize, top + scanWindowSize - r),
            radius: Radius.circular(r))
        ..lineTo(left + scanWindowSize, top + scanWindowSize - cl),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlatPickerSheet extends StatefulWidget {
  final List<UserModel> allMembers;
  final List<String> sortedBlocks;
  final String? initialBlock;
  final List<UserModel> initialSelectedMembers;
  final bool initialAllowMultiple;
  final void Function(List<UserModel> selected, bool isMultiple) onFlatsSelected;

  const _FlatPickerSheet({
    required this.allMembers,
    required this.sortedBlocks,
    required this.initialBlock,
    required this.initialSelectedMembers,
    required this.initialAllowMultiple,
    required this.onFlatsSelected,
  });

  @override
  State<_FlatPickerSheet> createState() => _FlatPickerSheetState();
}

class _FlatPickerSheetState extends State<_FlatPickerSheet> {
  late String _activeBlock;
  late List<UserModel> _selectedList;
  late bool _isMultiple;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final init = widget.initialBlock != null
        ? SocietyService.instance.logicalBlockName(widget.initialBlock!).trim()
        : null;
    _activeBlock = (init != null &&
            init.isNotEmpty &&
            widget.sortedBlocks.contains(init))
        ? init
        : '__all__';
    _selectedList = List.from(widget.initialSelectedMembers);
    _isMultiple = widget.initialAllowMultiple;
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredList {
    return widget.allMembers.where((m) {
      if (_activeBlock != '__all__') {
        final cleanActive = SocietyService.instance
            .logicalBlockName(_activeBlock)
            .trim()
            .toLowerCase();
        final mBlock = SocietyService.instance
            .logicalBlockName(m.blockName ?? '')
            .trim()
            .toLowerCase();
        if (mBlock != cleanActive) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final unit = (m.unitNumber ?? '').toLowerCase();
        final block = (m.blockName ?? '').toLowerCase();
        final name = m.name.toLowerCase();
        final phone = (m.phone ?? '').toLowerCase();
        if (!unit.contains(_searchQuery) &&
            !block.contains(_searchQuery) &&
            !name.contains(_searchQuery) &&
            !phone.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _onMemberTapped(UserModel member) {
    if (!_isMultiple) {
      widget.onFlatsSelected([member], false);
      Navigator.pop(context);
    } else {
      setState(() {
        final exists = _selectedList.any((m) => m.uid == member.uid);
        if (exists) {
          _selectedList.removeWhere((m) => m.uid == member.uid);
        } else {
          _selectedList.add(member);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectiveBottomSafe = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.domain_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ફ્લેટ પસંદ કરો",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "નામ અથવા ફ્લેટ નંબરથી શોધો",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Multi-select toggle button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isMultiple = !_isMultiple;
                        if (!_isMultiple && _selectedList.length > 1) {
                          _selectedList = [_selectedList.first];
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isMultiple
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isMultiple
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMultiple
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 15,
                            color: _isMultiple
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "મલ્ટિ-ફ્લેટ",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _isMultiple
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF64748B),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "ફ્લેટ નં. (દા.ત. 101) અથવા સભ્યનું નામ...",
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                          color: const Color(0xFF64748B),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Block Filter Pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSheetBlockPill(
                    id: '__all__',
                    label: '🏢 બધા બ્લોક',
                    isSelected: _activeBlock == '__all__',
                    onTap: () => setState(() => _activeBlock = '__all__'),
                  ),
                  ...widget.sortedBlocks.map(
                    (b) => _buildSheetBlockPill(
                      id: b,
                      label: 'બ્લોક $b',
                      isSelected: _activeBlock == b,
                      onTap: () => setState(() => _activeBlock = b),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Count summary bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    "${filtered.length} ફ્લેટ ઉપલબ્ધ",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedList.isNotEmpty)
                    Text(
                      "${_selectedList.length} પસંદ કરેલ",
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Flat List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          24.0,
                          24.0,
                          24.0 + effectiveBottomSafe,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "કોઈ ફ્લેટ મળ્યો નથી",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                   ? "'$_searchQuery' માટે કોઈ પરિણામ મળ્યું નથી."
                                  : "આ બ્લોકમાં કોઈ ફ્લેટ ઉપલબ્ધ નથી.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        (_isMultiple || _selectedList.isNotEmpty)
                            ? 14
                            : (24 + effectiveBottomSafe),
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = filtered[index];
                        final isSelected =
                            _selectedList.any((s) => s.uid == m.uid);

                        final blockName = (m.blockName != null &&
                                m.blockName!.trim().isNotEmpty)
                            ? SocietyService.instance
                                .logicalBlockName(m.blockName!)
                            : '';
                        final unit = (m.unitNumber != null &&
                                m.unitNumber!.trim().isNotEmpty)
                            ? m.unitNumber!
                            : '';
                        final fullFlatLabel = blockName.isNotEmpty
                            ? '$blockName - $unit'
                            : (unit.isNotEmpty ? 'ફ્લેટ $unit' : 'ઘર');

                        return InkWell(
                          onTap: () => _onMemberTapped(m),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Block & Unit badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    fullFlatLabel,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Member Name & Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF312E81)
                                              : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            (m.phone != null &&
                                                    m.phone!.isNotEmpty)
                                                ? m.phone!
                                                : "રહેવાસી",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Selection indicator
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Confirmation Bar
            if (_isMultiple || _selectedList.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  14 + effectiveBottomSafe,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Row(
                    children: [
                      if (_selectedList.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedList.clear()),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "સાફ કરો",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          widget.onFlatsSelected(_selectedList, _isMultiple);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _selectedList.isEmpty
                              ? "બંધ કરો"
                              : "પસંદગી સાચવો (${_selectedList.length})",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetBlockPill({
    required String id,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

