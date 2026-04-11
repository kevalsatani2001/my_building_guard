import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WatchmanScreen extends StatefulWidget {
  const WatchmanScreen({super.key});

  @override
  _WatchmanScreenState createState() => _WatchmanScreenState();
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
  }

  // ૧. વિઝિટરનો ફોટો પાડવો
  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 40);
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
          .map((doc) =>
          UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
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

    setState(() {
      _preApprovedResults = snapshot.docs;
    });

    // જો માત્ર એક જ રિઝલ્ટ મળે તો ઓટો-ફિલ કરી દેવું
    if (snapshot.docs.length == 1) {
      _selectPreApprovedGuest(snapshot.docs.first);
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
    UserModel member =
    UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);

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
      // Firestore માં વિઝિટર એન્ટ્રી
      await FirebaseFirestore.instance.collection('visitors').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'watchmanId': FirebaseAuth.instance.currentUser!.uid,
        'photoUrl': photoUrl,
        'memberId': _selectedMember!.uid,
        'memberName': _selectedMember!.name,
        'blockName': _selectedBlock,
        'unitNumber': _selectedMember!.unitNumber,
        'status': isPreApproved ? 'approved' : 'pending',
        // 🔥 જો પ્રી-એપ્રુવ્ડ હોય તો સીધું approved
        'entryTime': FieldValue.serverTimestamp(),
      });

      // 🔥 Cloud Function માટે નોટિફિકેશન એન્ટ્રી
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': "નવા મુલાકાતી (Gate Alert)",
        'body': "${_nameController.text.trim()} તમને મળવા આવ્યા છે.",
        'targetUID': _selectedMember!.uid,
        'type': 'visitor_alert',
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar('એન્ટ્રી સફળ અને મેમ્બરને જાણ કરી!', Colors.green);
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
        "SOS એલર્ટ!", "શું તમે એડમિનને મદદ માટે જાણ કરવા માંગો છો?");
    if (!confirm) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': "🚨 ઇમરજન્સી એલર્ટ (GATE)",
      'body': "ગેટ પર વોચમેનને મદદની જરૂર છે!",
      'targetUID': 'ALL', // એડમિન ટોપિકમાં જશે
      'type': 'sos',
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _showSnackBar('એડમિનને જાણ કરી દેવામાં આવી છે!', Colors.red);
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
              future: FirebaseFirestore.instance
                  .collection('settings')
                  .doc('society_config')
                  .get(),
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
                  .limit(80)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
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
                          '${m['staffRole'] ?? ''}\n📱 ${m['staffPhone'] ?? ''}'),
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
              child: const Text("ના")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("હા")),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("સોસાયટી ગેટ કંટ્રોલ"),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: "નવી એન્ટ્રી"),
            Tab(icon: Icon(Icons.history), text: "આજની હિસ્ટ્રી")
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_phone),
            tooltip: 'ઈમરજન્સી અને કાયમી સ્ટાફ',
            onPressed: _openContactsAndStaffSheet,
          ),
          IconButton(
              icon:
              const Icon(Icons.warning_amber_rounded, color: Colors.yellow),
              onPressed: _sendSOS),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntryForm(),
          _buildVisitorHistory(),
        ],
      ),
    );
  }

  // --- UI: વિઝિટર એન્ટ્રી ફોર્મ ---
  Widget _buildEntryForm() {
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
                  border: Border.all(color: Colors.indigo)),
              child: _image == null
                  ? const Icon(Icons.add_a_photo,
                  size: 50, color: Colors.indigo)
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
                        prefixIcon:
                        const Icon(Icons.person, color: Colors.indigo),
                        suffixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.indigo),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: Colors.indigo, width: 2),
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
                              fontWeight: FontWeight.bold),
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
                  labelText: "મોબાઈલ નંબર", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                  labelText: "કારણ (Guest, Delivery)",
                  border: OutlineInputBorder())),
          const SizedBox(height: 20),

          // Block & Member Dropdowns
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blocks').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              // if (snap.hasData) {
              //   for (var doc in snap.data!.docs) {
              //     String status = doc['status'];
              //     String id = doc.id;
              //
              //     // જો સ્ટેટસ બદલાયું હોય અને આપણે હજુ સુધી આ એન્ટ્રી માટે અવાજ નથી વગાડ્યો
              //     if (status != 'pending' && !_processedIds.contains(id)) {
              //       _playAlertSound(); // અવાજ વગાડો
              //       _processedIds.add(id); // યાદીમાં ઉમેરી દો જેથી ફરી ફરી અવાજ ન આવે
              //     }
              //   }
              // }
              return DropdownButtonFormField<String>(
                value: _selectedBlock,
                hint: const Text("બ્લોક પસંદ કરો"),
                items: snap.data!.docs
                    .map((d) => DropdownMenuItem(
                    value: d['name'].toString(), child: Text(d['name'])))
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
                .map((m) => DropdownMenuItem(
                value: m, child: Text("${m.name} (${m.unitNumber})")))
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
                minimumSize: const Size(double.infinity, 50)),
            child: const Text("એન્ટ્રી કરો અને મેમ્બરને જાણ કરો",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
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
                  })
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

        // 📜 ફિલ્ટર કરેલું લિસ્ટ
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('visitors')
                .where('entryTime',
                isGreaterThanOrEqualTo: DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day))
                .orderBy('entryTime', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());

              // 🔥 અહીં સર્ચ ક્વેરી મુજબ ડેટા ફિલ્ટર થશે
              var filteredDocs = snap.data!.docs.where((doc) {
                String name = doc['name'].toString().toLowerCase();
                String unit = doc['unitNumber'].toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    unit.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text("કોઈ મહેમાન મળ્યા નથી."));
              }

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  var d = snap.data!.docs[i];
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
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                        title: Text(d['name'],
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "ઘર: ${d['blockName']}-${d['unitNumber']}\nહેતુ: ${d['purpose']}"),
                            if (status == 'checked_out' &&
                                d['exitTime'] != null)
                              Text(
                                "Out: ${DateFormat('hh:mm a').format((d['exitTime'] as Timestamp).toDate())}",
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
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
                                            borderRadius:
                                            BorderRadius.circular(8))),
                                    child: const Text("OUT",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ),
                                )
                              else
                              // બાકીના સ્ટેટસ માટે માત્ર આઇકન અને ટેક્સ્ટ
                                Column(
                                  children: [
                                    Icon(statusIcon,
                                        color: statusColor, size: 20),
                                    Text(statusText,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
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

  // Check-out કરવાનું ફંક્શન
  Future<void> _checkOutVisitor(String docId) async {
    await FirebaseFirestore.instance.collection('visitors').doc(docId).update({
      'status': 'checked_out',
      'exitTime': FieldValue.serverTimestamp(),
    });
    _showSnackBar("મહેમાન ચેક-આઉટ થઈ ગયા છે", Colors.blue);
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
