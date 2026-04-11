import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'admin_complaints_screen.dart';
import 'architecture_preview.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  bool _isSetupComplete = false;
  String _societyName = "";
  String _architectureType = "Wing";

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  void _checkSetupStatus() async {
    var doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('society_config')
        .get();
    if (mounted) {
      setState(() {
        if (doc.exists) {
          _isSetupComplete = doc.data()?['isSetupComplete'] ?? false;
          _societyName = doc.data()?['societyName'] ?? "";
          _architectureType = doc.data()?['architectureType'] ?? "Wing";
        }
        _isLoading = false;
      });
    }
  }

  // --- વેલિડેશન હેલ્પર ---
  bool _isValidEmail(String email) {
    return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isSetupComplete ? _buildMainDashboard() : _buildSetupWizard();
  }

  // ==========================================
  // ૧. INITIAL SETUP WIZARD (With Validation)
  // ==========================================
// સેટઅપ સ્ક્રીન માટેના વેરીએબલ્સ (વર્ગની ઉપર અથવા State માં જાહેર કરો)
  List<Map<String, dynamic>> tempBlocks = [];

  Widget _buildSetupWizard() {
    final sNameC = TextEditingController();
    final bNameC = TextEditingController();
    final v1C = TextEditingController();
    final v2C = TextEditingController();
    String wizardType = 'Wing';

    return Scaffold(
      appBar: AppBar(
          title: const Text("સોસાયટી સેટઅપ"),
          backgroundColor: Colors.redAccent),
      body: StatefulBuilder(builder: (context, setWizardState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Warning Message ---
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 40),
                    SizedBox(width: 15),
                    Expanded(
                        child: Text(
                            "ચેતવણી: આર્કિટેક્ચર પ્રકાર કાયમી રહેશે. ઓછામાં ઓછી એક વિંગ/શેરી ઉમેરવી ફરજિયાત છે.",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                  controller: sNameC,
                  decoration: const InputDecoration(
                      labelText: "સોસાયટીનું નામ",
                      border: OutlineInputBorder())),
              const SizedBox(height: 15),

              // જો લિસ્ટમાં બ્લોક્સ ઉમેરાઈ ગયા હોય તો ટાઈપ લોક કરી દેવો જેથી ડેટા મિક્સ ન થાય
              DropdownButtonFormField<String>(
                value: wizardType,
                items: const [
                  DropdownMenuItem(
                      value: 'Wing', child: Text("વિંગ સિસ્ટમ (A, B, C...)")),
                  DropdownMenuItem(
                      value: 'Street', child: Text("શેરી સિસ્ટમ (1, 2, 3...)")),
                ],
                onChanged: tempBlocks.isEmpty
                    ? (v) => setWizardState(() => wizardType = v!)
                    : null,
                decoration: InputDecoration(
                    labelText: "આર્કિટેક્ચર પ્રકાર",
                    border: const OutlineInputBorder(),
                    helperText: tempBlocks.isNotEmpty
                        ? "બ્લોક ઉમેર્યા પછી પ્રકાર બદલી શકાશે નહીં"
                        : null),
              ),

              const Divider(height: 40, thickness: 2),
              const Text("બ્લોક ઉમેરો (વિંગ અથવા શેરી)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              // --- બ્લોક ઇનપુટ સેક્શન ---
              TextField(
                  controller: bNameC,
                  decoration: InputDecoration(
                      labelText: wizardType == 'Wing'
                          ? "વિંગ નામ (e.g. A)"
                          : "શેરી નંબર",
                      border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: v1C,
                          decoration: InputDecoration(
                              labelText: wizardType == 'Wing'
                                  ? "કુલ માળ"
                                  : "શરૂઆત નંબર",
                              border: const OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: v2C,
                          decoration: InputDecoration(
                              labelText: wizardType == 'Wing'
                                  ? "માળ દીઠ ઘર"
                                  : "છેલ્લો નંબર",
                              border: const OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 15),

              // --- બ્લોક લિસ્ટમાં ઉમેરવાનું બટન ---
              ElevatedButton.icon(
                onPressed: () {
                  if (bNameC.text.isEmpty ||
                      v1C.text.isEmpty ||
                      v2C.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("બ્લોકની બધી વિગતો ભરો!")));
                    return;
                  }

                  String bID =
                      "${wizardType.substring(0, 1)}-${bNameC.text.trim().toUpperCase()}";

                  // ડુપ્લીકેટ ચેક (ટેમ્પરરી લિસ્ટમાં)
                  if (tempBlocks.any((b) => b['id'] == bID)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("આ બ્લોક લિસ્ટમાં પહેલેથી છે!")));
                    return;
                  }

                  setWizardState(() {
                    tempBlocks.add({
                      'id': bID,
                      'name': bNameC.text.trim().toUpperCase(),
                      'v1': int.parse(v1C.text),
                      'v2': int.parse(v2C.text),
                    });
                    bNameC.clear();
                    v1C.clear();
                    v2C.clear();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("લિસ્ટમાં બ્લોક ઉમેરો"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white),
              ),

              const SizedBox(height: 20),

              // --- ઉમેરેલા બ્લોક્સનું લિસ્ટ બતાવવું ---
              if (tempBlocks.isNotEmpty) ...[
                const Text("ઉમેરેલા બ્લોક્સ:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tempBlocks.length,
                  itemBuilder: (context, index) {
                    final b = tempBlocks[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(b['name'][0])),
                        title: Text("${wizardType}: ${b['name']}"),
                        subtitle: Text(wizardType == 'Wing'
                            ? "${b['v1']} માળ, ${b['v2']} ઘર/માળ"
                            : "નંબર: ${b['v1']} થી ${b['v2']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setWizardState(() => tempBlocks.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 30),

              // --- ફાઈનલ સબમિટ બટન ---
              ElevatedButton(
                onPressed: () {
                  if (sNameC.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("સોસાયટીનું નામ લખો!")));
                  } else if (tempBlocks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("ઓછામાં ઓછો એક બ્લોક ઉમેરો!")));
                  } else {
                    _executeFinalInitialSetup(sNameC.text, wizardType);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 60),
                    foregroundColor: Colors.white),
                child: const Text("ફાઈનલ સેટઅપ પૂર્ણ કરો",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // --- Preview Button ---
              ElevatedButton(
                onPressed: () {
                  if (tempBlocks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("પહેલા કોઈ બ્લોક ઉમેરો!")));
                    return;
                  }
                  // નવી સ્ક્રીન પર નેવિગેટ કરવું
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArchitecturePreviewScreen(
                        tempBlocks: tempBlocks,
                        architectureType:
                        wizardType, // અહિયાં તમારો wizardType વેરીએબલ આપવો
                      ),
                    ),
                  );
                },
                child: const Text("આર્કિટેક્ચર પ્રિવ્યુ (New Page)"),
              )
            ],
          ),
        );
      }),
    );
  }

  // ૧. પ્રિવ્યુ ડાયલોગ બોક્સ
  void _showPreviewDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.domain, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("સોસાયટી પ્રિવ્યુ",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(type == 'Wing' ? "બિલ્ડિંગ સ્ટ્રક્ચર" : "પ્લોટ લેઆઉટ",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: tempBlocks.isEmpty
              ? const Center(child: Text("કોઈ ડેટા નથી"))
              : ListView.builder(
            itemCount: tempBlocks.length,
            itemBuilder: (context, index) {
              final b = tempBlocks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    // બ્લોક હેડર
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${type}: ${b['name']}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              type == 'Wing'
                                  ? "${b['v1']} માળ"
                                  : "${b['v2'] - b['v1'] + 1} ઘરો",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    // વિઝ્યુઅલ લેઆઉટ
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: type == 'Wing'
                          ? _buildWingLayout(b)
                          : _buildStreetLayout(b),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("સમજાઈ ગયું",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

// ૧. વિંગ માટે બિલ્ડિંગ જેવું વર્ટિકલ લેઆઉટ
  Widget _buildWingLayout(Map<String, dynamic> b) {
    return Column(
      children: List.generate(b['v1'], (fIndex) {
        int floorNo = b['v1'] - fIndex; // ઉપરથી નીચે (e.g. 5, 4, 3, 2, 1)
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // માળનો નંબર
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text("${floorNo}F",
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
              ),
              const SizedBox(width: 8),
              // તે માળના ઘર
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(b['v2'], (uIndex) {
                      String uID =
                          "$floorNo${(uIndex + 1).toString().padLeft(2, '0')}";
                      return _unitTile(uID);
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

// ૨. શેરી માટે પ્લોટ જેવું ગ્રીડ લેઆઉટ
  Widget _buildStreetLayout(Map<String, dynamic> b) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate((b['v2'] - b['v1'] + 1), (index) {
        String uID = (b['v1'] + index).toString();
        return _unitTile(uID);
      }),
    );
  }

// ૩. કોમન યુનિટ ટાઈલ (સુંદર લુક માટે)
  Widget _unitTile(String id) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.blueAccent.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4)
          ]),
      child: Column(
        children: [
          const Icon(Icons.home_outlined, size: 14, color: Colors.blueAccent),
          const SizedBox(height: 2),
          Text(id,
              style:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

// ૨. યુનિટ્સના પ્રિવ્યુ બોક્સ જનરેટ કરવા (નાના ચોરસ બોક્સ)
  List<Widget> _generatePreviewUnits(Map<String, dynamic> block, String type) {
    List<Widget> units = [];
    if (type == 'Wing') {
      // વિંગ માટે માળ મુજબ ઘર
      for (int f = 1; f <= block['v1']; f++) {
        for (int u = 1; u <= block['v2']; u++) {
          String uID = "$f${u.toString().padLeft(2, '0')}";
          units.add(_unitBox(uID));
        }
      }
    } else {
      // સ્ટ્રીટ માટે રેન્જ મુજબ ઘર
      for (int i = block['v1']; i <= block['v2']; i++) {
        units.add(_unitBox(i.toString()));
      }
    }
    return units;
  }

// ૩. યુનિટનું સુંદર બોક્સ UI
  Widget _unitBox(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

// --- ફાઈનલ સેટઅપ એક્ઝિક્યુટ કરવાનું લોજિક ---
  Future<void> _executeFinalInitialSetup(String sName, String type) async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // ૧. સોસાયટી કોન્ફિગ
      batch.set(
          FirebaseFirestore.instance
              .collection('settings')
              .doc('society_config'),
          {
            'societyName': sName,
            'architectureType': type,
            'isSetupComplete': true,
            'totalBlocks': tempBlocks.length,
          });

      // ૨. બધા ટેમ્પરરી બ્લોક્સ અને તેના યુનિટ્સ જનરેટ કરવા
      for (var b in tempBlocks) {
        String bID = b['id'];
        batch.set(FirebaseFirestore.instance.collection('blocks').doc(bID), {
          'name': bID,
          'type': type,
        });

        // યુનિટ્સ જનરેટ લોજિક
        if (type == 'Wing') {
          for (int f = 1; f <= b['v1']; f++) {
            for (int u = 1; u <= b['v2']; u++) {
              String uID = "$f${u.toString().padLeft(2, '0')}";
              batch.set(
                  FirebaseFirestore.instance
                      .collection('units')
                      .doc("$bID-$uID"),
                  {
                    'blockName': bID,
                    'unitNumber': uID,
                    'floorNo': f,
                    'isOccupied': false
                  });
            }
          }
        } else {
          for (int i = b['v1']; i <= b['v2']; i++) {
            batch.set(
                FirebaseFirestore.instance.collection('units').doc("$bID-$i"), {
              'blockName': bID,
              'unitNumber': i.toString(),
              'floorNo': 0,
              'isOccupied': false
            });
          }
        }
      }

      await batch.commit();
      tempBlocks.clear(); // સેટઅપ પત્યા પછી લિસ્ટ ખાલી કરો
      _checkSetupStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ==========================================
  // ૨. MAIN DASHBOARD
  // ==========================================
  Widget _buildMainDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_societyName),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        "મેમ્બર્સ", 'users', 'role', 'member', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        "વોચમેન", 'users', 'role', 'watchman', Colors.orange)),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatCard(
                "એડમિન લિસ્ટ", 'users', 'role', 'admin', Colors.indigo),
            const Divider(height: 40),

            const Text("ક્વિક એક્શન",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),

            // એક્શન બટન્સ
            _actionButton("આર્કિટેક્ચર પ્રિવ્યુ", Icons.grid_view_rounded,
                Colors.indigo, _navigateToPreview),
            _actionButton("નવી $_architectureType ઉમેરો", Icons.add_business,
                Colors.teal, _showAddBlockDialog),
            _actionButton(
                "યુઝર રજીસ્ટ્રેશન (Member/Admin/Watchman)",
                Icons.person_add,
                Colors.blueGrey,
                    () => _showAddUserDialog(context)),
            _actionButton("બધાને સૂચના મોકલો", Icons.campaign, Colors.orange,
                    () => _showNotificationDialog(context)),
            _actionButton("નોટિસ બોર્ડ પોસ્ટ", Icons.article, Colors.deepOrange,
                () => _showPublishNoticeDialog(context)),
            _actionButton("ફરિયાદ નિવારણ", Icons.report_problem, Colors.deepPurple,
                () => _openComplaints(context)),
            _actionButton("વિઝિટર રિપોર્ટ (મહિનો)", Icons.analytics, Colors.teal,
                () => _showVisitorReportDialog(context)),
            _actionButton("વોચમેન મેનેજ (બ્લૉક/ચાલુ)", Icons.security, Colors.brown,
                () => _showWatchmanManageDialog(context)),
            _actionButton("ઈમરજન્સી કોન્ટેક્ટ્સ", Icons.phone_in_talk, Colors.red.shade700,
                () => _showEmergencyContactsDialog(context)),

            const SizedBox(height: 30),
            const Text("તાજેતરના યુઝર્સ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(height: 300, child: _buildMemberList()),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _navigateToPreview() async {
    setState(() => _isLoading = true); // પ્રોસેસિંગ બતાવવા માટે

    try {
      // Firestore માંથી બધા બ્લોક્સ (Wings/Streets) મેળવો
      var snapshot =
      await FirebaseFirestore.instance.collection('blocks').get();

      List<Map<String, dynamic>> blocksData = [];

      for (var doc in snapshot.docs) {
        String bID = doc.id;

        // દરેક બ્લોકના યુનિટ્સની સંખ્યા મેળવો (ગણતરી માટે)
        var unitsSnapshot = await FirebaseFirestore.instance
            .collection('units')
            .where('blockName', isEqualTo: bID)
            .get();

        // આપણે પ્રિવ્યુ માટે v1 અને v2 ની જરૂર પડશે
        // અંદાજે ગણતરી: જો વિંગ હોય તો માળ અને ઘરની સંખ્યા
        // નોંધ: સેટઅપ વખતે આપણે આ ડેટા બ્લોક ડોક્યુમેન્ટમાં પણ સેવ કરી શકીએ છીએ

        int maxFloor = 0;
        int unitsPerFloor = 0;
        int minUnit = 9999;
        int maxUnit = 0;

        for (var uDoc in unitsSnapshot.docs) {
          int floor = uDoc.data()['floorNo'] ?? 0;
          int uNum = int.parse(uDoc.data()['unitNumber']);
          if (floor > maxFloor) maxFloor = floor;
          if (uNum > maxUnit) maxUnit = uNum;
          if (uNum < minUnit) minUnit = uNum;
        }

        // અંદાજિત units per floor
        if (maxFloor > 0) unitsPerFloor = unitsSnapshot.docs.length ~/ maxFloor;

        blocksData.add({
          'name': bID.split('-').last, // 'W-A' માંથી 'A' લેવા માટે
          'id': bID,
          'v1': _architectureType == 'Wing' ? maxFloor : minUnit,
          'v2': _architectureType == 'Wing' ? unitsPerFloor : maxUnit,
        });
      }

      if (!mounted) return;

      // નવી સ્ક્રીન પર જાવ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArchitecturePreviewScreen(
            tempBlocks: blocksData,
            architectureType: _architectureType,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // LOGIC & VALIDATED FUNCTIONS
  // ==========================================

  Future<void> _executeInitialSetup(
      String sName, String type, String bName, String v1, String v2) async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(
          FirebaseFirestore.instance
              .collection('settings')
              .doc('society_config'),
          {
            'societyName': sName,
            'architectureType': type,
            'isSetupComplete': true,
          });

      String bID = "${type.substring(0, 1)}-${bName.toUpperCase()}";
      batch.set(FirebaseFirestore.instance.collection('blocks').doc(bID),
          {'name': bID, 'type': type});
      _generateUnits(batch, bID, type, int.parse(v1), int.parse(v2));

      await batch.commit();
      _checkSetupStatus();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ભૂલ: $e")));
    }
  }

  void _generateUnits(
      WriteBatch batch, String bID, String type, int v1, int v2) {
    if (type == 'Wing') {
      for (int f = 1; f <= v1; f++) {
        for (int u = 1; u <= v2; u++) {
          String uID = "$f${u.toString().padLeft(2, '0')}";
          batch.set(
              FirebaseFirestore.instance.collection('units').doc("$bID-$uID"),
              {'blockName': bID, 'unitNumber': uID, 'isOccupied': false});
        }
      }
    } else {
      for (int i = v1; i <= v2; i++) {
        batch.set(
            FirebaseFirestore.instance.collection('units').doc("$bID-$i"), {
          'blockName': bID,
          'unitNumber': i.toString(),
          'isOccupied': false
        });
      }
    }
  }

  // ==========================================
  // ૩. USER REGISTRATION LOGIC (With Role Selection)
  // ==========================================
  Future<void> _showAddUserDialog(BuildContext context) async {
    final nC = TextEditingController();
    final eC = TextEditingController();
    final pC = TextEditingController();
    final phoneC = TextEditingController();
    String selectedRole = 'member'; // Default Role
    String? sB;
    String? sU;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: const Text("નવું યુઝર રજીસ્ટ્રેશન"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // રોલ સિલેક્શન
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "યુઝર રોલ"),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text("મેમ્બર")),
                    DropdownMenuItem(value: 'admin', child: Text("બીજો એડમિન")),
                    DropdownMenuItem(value: 'watchman', child: Text("વોચમેન")),
                  ],
                  onChanged: (v) => setDS(() => selectedRole = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: nC,
                    decoration: const InputDecoration(labelText: "નામ")),
                TextField(
                    controller: eC,
                    decoration: const InputDecoration(labelText: "ઇમેઇલ"),
                    keyboardType: TextInputType.emailAddress),
                TextField(
                    controller: pC,
                    decoration: const InputDecoration(labelText: "પાસવર્ડ"),
                    obscureText: true),
                if (selectedRole == 'member')
                  TextField(
                    controller: phoneC,
                    decoration: const InputDecoration(
                        labelText: "કોન્ટેક્ટ નંબર (વૈકલ્પિક)"),
                    keyboardType: TextInputType.phone),

                // જો રોલ 'member' હોય તો જ બ્લોક અને યુનિટ બતાવવા
                if (selectedRole == 'member') ...[
                  const Divider(height: 30),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('blocks')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        hint: const Text("બ્લોક પસંદ કરો"),
                        items: snap.data!.docs
                            .map((d) => DropdownMenuItem(
                            value: d.id, child: Text(d['name'])))
                            .toList(),
                        onChanged: (v) => setDS(() {
                          sB = v;
                          sU = null;
                        }),
                      );
                    },
                  ),
                  // યુનિટ પસંદ કરવાનું ડ્રોપડાઉન
                  if (sB != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('units')
                          .where('blockName', isEqualTo: sB)
                          .where('isOccupied', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();

                        // બધા યુનિટ્સનું લિસ્ટ બનાવો
                        var unitDocs = snap.data!.docs;

                        // 🔥 મહત્વનું: જો લિસ્ટમાં હાલની પસંદ કરેલી વેલ્યુ (sU) ન હોય,
                        // તો sU ને null કરી દો જેથી એરર ન આવે.
                        bool valueExists = unitDocs
                            .any((d) => d.get('unitNumber').toString() == sU);
                        if (!valueExists) {
                          sU = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: sU,
                          // આ વેલ્યુ items લિસ્ટમાં હોવી જ જોઈએ
                          hint: const Text("ઘર પસંદ કરો"),
                          items: unitDocs.map((d) {
                            String val = d.get('unitNumber').toString();
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                          onChanged: (v) => setDS(() => sU = v),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  if (nC.text.isEmpty || eC.text.isEmpty || pC.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("બધી વિગતો ભરો!")));
                    return;
                  }
                  if (selectedRole == 'member' && (sB == null || sU == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("બ્લોક અને ઘર પસંદ કરો!")));
                    return;
                  }

                  _createNewUser(
                      context,
                      eC.text.trim(),
                      pC.text.trim(),
                      nC.text.trim(),
                      selectedRole,
                      sB,
                      sU,
                      phone: selectedRole == 'member'
                          ? phoneC.text.trim()
                          : null);
                },
                child: const Text("Create User")),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewUser(BuildContext context, String email, String pass,
      String name, String role, String? block, String? unit,
      {String? phone}) async {
    try {
      // સેકન્ડરી એપ જેથી એડમિન પોતે લોગઆઉટ ન થઈ જાય
      FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'TempApp', options: Firebase.app().options);
      UserCredential res = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: pass);

      Map<String, dynamic> userData = {
        'uid': res.user!.uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // જો મેમ્બર હોય તો જ આ વિગતો ઉમેરવી
      if (role == 'member') {
        userData['unitNumber'] = unit;
        userData['blockName'] = block;
        if (phone != null && phone.isNotEmpty) {
          userData['phone'] = phone;
        }

        // યુનિટને Occupied માર્ક કરો
        await FirebaseFirestore.instance
            .collection('units')
            .doc("$block-$unit")
            .update({'isOccupied': true, 'memberId': res.user!.uid});
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(res.user!.uid)
          .set(userData);

      await tempApp.delete();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$role સફળતાપૂર્વક ઉમેરાયો!"),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ભૂલ: $e"), backgroundColor: Colors.red));
    }
  }

  void _showAddBlockDialog() {
    final nameC = TextEditingController();
    final v1C = TextEditingController();
    final v2C = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("નવી $_architectureType ઉમેરો"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "નામ (e.g. B)"),
              textCapitalization:
              TextCapitalization.characters, // હંમેશા કેપિટલ લેટર
            ),
            TextField(
                controller: v1C,
                decoration: InputDecoration(
                    labelText: _architectureType == 'Wing' ? "માળ" : "શરૂઆત"),
                keyboardType: TextInputType.number),
            TextField(
                controller: v2C,
                decoration: InputDecoration(
                    labelText:
                    _architectureType == 'Wing' ? "ઘર દીઠ માળ" : "અંત"),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("રદ કરો")),
          ElevatedButton(
              onPressed: () async {
                // ૧. ફિલ્ડ ખાલી છે કે નહીં તેનું વેલિડેશન
                if (nameC.text.trim().isEmpty ||
                    v1C.text.isEmpty ||
                    v2C.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("બધી વિગતો ભરો!"),
                      backgroundColor: Colors.orange));
                  return;
                }

                String bID =
                    "${_architectureType.substring(0, 1)}-${nameC.text.trim().toUpperCase()}";

                // ૨. ડુપ્લીકેટ બ્લોક ચેક લોજિક
                var existingBlock = await FirebaseFirestore.instance
                    .collection('blocks')
                    .doc(bID)
                    .get();

                if (existingBlock.exists) {
                  // જો બ્લોક પહેલેથી હોય તો વોર્નિંગ આપવી
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "ભૂલ: આ $bID નામની $_architectureType પહેલેથી જ છે!"),
                        backgroundColor: Colors.red),
                  );
                } else {
                  // જો બ્લોક નવો હોય તો જ પ્રોસેસ કરવી
                  WriteBatch batch = FirebaseFirestore.instance.batch();
                  batch.set(
                      FirebaseFirestore.instance.collection('blocks').doc(bID),
                      {'name': bID, 'type': _architectureType});
                  _generateUnits(batch, bID, _architectureType,
                      int.parse(v1C.text), int.parse(v2C.text));

                  await batch.commit();
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("સફળતાપૂર્વક ઉમેરાયું!"),
                      backgroundColor: Colors.green));
                }
              },
              child: const Text("ઉમેરો")),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String coll, String? f, String? v, Color c) {
    Query q = FirebaseFirestore.instance.collection(coll);
    if (f != null) q = q.where(f, isEqualTo: v);
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        int count = snap.hasData ? snap.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(15),
          decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            Text(count.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold))
          ]),
        );
      },
    );
  }

  Widget _buildMemberList() {
    return StreamBuilder<QuerySnapshot>(
      // માત્ર 'member' રોલ ધરાવતા યુઝર્સ જ બતાવશે
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'member')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("કોઈ મેમ્બર્સ મળ્યા નથી."));
        }

        var docs = snap.data!.docs;

        return ListView.builder(
          shrinkWrap: true, // જો આ લિસ્ટ કોઈ Column ની અંદર હોય તો આ જરૂરી છે
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;

            // ડેટા મેળવવો
            String mId = d['uid'] ?? "";
            String mName = d['name'] ?? "No Name";
            String mBlock = d['blockName'] ?? "";
            String mUnit = d['unitNumber'] ?? "";
            String mPhone = d['phone'] ?? "";
            String mEmail = d['email'] ?? "";

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(mName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(mName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "બ્લોક: $mBlock | ઘર: $mUnit\n$mEmail${mPhone.isNotEmpty ? '\n📱 $mPhone' : ''}"),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'transfer') {
                      // અહિયાં mId અને mName પાસ કર્યા છે
                      _confirmTransfer(mId, mName);
                    }
                    if (value == 'notify') {
                      _showNotificationDialog(context,
                          targetUID: mId, targetName: mName);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'transfer',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text("પ્રમુખ પદ સોંપો",
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notify',
                      child: Row(
                        children: [
                          Icon(Icons.message, color: Colors.blue),
                          SizedBox(width: 10),
                          Text("સૂચના મોકલો"),
                        ],
                      ),
                    ),

// onSelected માં:
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationDialog(BuildContext context,
      {String? targetUID, String? targetName}) async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    bool isAll = targetUID == null; // જો UID ન હોય તો બધા માટે

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAll ? "બધાને સૂચના મોકલો" : "$targetName ને સૂચના મોકલો"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "વિષય (Title)")),
            const SizedBox(height: 10),
            TextField(
                controller: bodyC,
                decoration: const InputDecoration(labelText: "સૂચના (Message)"),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("રદ કરો")),
          ElevatedButton(
            onPressed: () {
              if (titleC.text.isNotEmpty && bodyC.text.isNotEmpty) {
                _sendPushNotification(
                  title: titleC.text,
                  body: bodyC.text,
                  targetUID: targetUID, // null હશે તો બધાને જશે
                );
                Navigator.pop(context);
              }
            },
            child: const Text("મોકલો"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPushNotification(
      {required String title, required String body, String? targetUID}) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'targetUID': targetUID ?? 'ALL', // 'ALL' એટલે બધા માટે
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("સૂચના સફળતાપૂર્વક મોકલવામાં આવી!"),
          backgroundColor: Colors.green));
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  void _openComplaints(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()),
    );
  }

  Future<void> _showPublishNoticeDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    bool sendPush = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('નોટિસ બોર્ડ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleC,
                    decoration: const InputDecoration(labelText: 'શીર્ષક')),
                TextField(
                    controller: bodyC,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'સંદેશ')),
                CheckboxListTile(
                  value: sendPush,
                  onChanged: (v) => setS(() => sendPush = v ?? true),
                  title: const Text('બધાને પુશ નોટિફિકેશન'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('રદ')),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                await FirebaseFirestore.instance.collection('notices').add({
                  'title': titleC.text.trim(),
                  'body': bodyC.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'authorId': FirebaseAuth.instance.currentUser!.uid,
                });
                if (sendPush) {
                  final b = bodyC.text.trim();
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'title': titleC.text.trim(),
                    'body': b.isEmpty ? 'નવી નોટિસ' : b,
                    'targetUID': 'ALL',
                    'type': 'notice',
                    'senderId': FirebaseAuth.instance.currentUser!.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('નોટિસ પ્રકાશિત!'),
                      backgroundColor: Colors.green));
                }
              },
              child: const Text('પ્રકાશિત કરો'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVisitorReportDialog(BuildContext context) async {
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final snap = await FirebaseFirestore.instance
        .collection('visitors')
        .where('entryTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    int total = snap.docs.length;
    int approved =
        snap.docs.where((d) => d['status'] == 'approved').length;
    int pending = snap.docs.where((d) => d['status'] == 'pending').length;
    int rejected =
        snap.docs.where((d) => d['status'] == 'rejected').length;
    int out =
        snap.docs.where((d) => d['status'] == 'checked_out').length;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'વિઝિટર રિપોર્ટ — ${start.year}-${start.month.toString().padLeft(2, '0')}'),
        content: Text(
            'કુલ એન્ટ્રી: $total\nમંજૂર: $approved\nપેન્ડિંગ: $pending\nનકાર્યું: $rejected\nચેક-આઉટ: $out'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('બંધ કરો')),
        ],
      ),
    );
  }

  Future<void> _showWatchmanManageDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('વોચમેન મેનેજમેન્ટ'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'watchman')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Text('કોઈ વોચમેન નથી.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final m = d.data() as Map<String, dynamic>;
                  final active = m['isActive'] != false;
                  final name = m['name'] ?? d.id;
                  return SwitchListTile(
                    title: Text('$name'),
                    subtitle: Text('${m['email'] ?? ''}'),
                    value: active,
                    onChanged: (v) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(d.id)
                          .update({'isActive': v});
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('બંધ')),
        ],
      ),
    );
  }

  Future<void> _showEmergencyContactsDialog(BuildContext context) async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('society_config')
        .get();
    final List<Map<String, dynamic>> contacts = [];
    if (doc.exists) {
      final raw = doc.data()?['emergencyContacts'];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            contacts.add({
              'name': '${e['name'] ?? ''}',
              'phone': '${e['phone'] ?? ''}',
            });
          }
        }
      }
    }

    if (!context.mounted) return;

    final nameC = TextEditingController();
    final phoneC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('ઈમરજન્સી કોન્ટેક્ટ્સ'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                        labelText: 'નામ (દા.ત. ફાયર / લિફ્ટ)')),
                TextField(
                    controller: phoneC,
                    decoration: const InputDecoration(labelText: 'નંબર'),
                    keyboardType: TextInputType.phone),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (nameC.text.trim().isEmpty ||
                          phoneC.text.trim().isEmpty) {
                        return;
                      }
                      setS(() {
                        contacts.add({
                          'name': nameC.text.trim(),
                          'phone': phoneC.text.trim(),
                        });
                        nameC.clear();
                        phoneC.clear();
                      });
                    },
                    child: const Text('લિસ્ટમાં ઉમેરો'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      return ListTile(
                        title: Text(c['name'] ?? ''),
                        subtitle: Text(c['phone'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setS(() => contacts.removeAt(i)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('રદ')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('settings')
                    .doc('society_config')
                    .set(
                  {'emergencyContacts': contacts},
                  SetOptions(merge: true),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('સાચવો'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTransfer(String newAdminId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ચેતવણી!"),
        content: Text(
            "શું તમે ખરેખર $name ને સોસાયટીના નવા પ્રમુખ બનાવવા માંગો છો? આ કર્યા પછી તમારી એડમિન સત્તા જતી રહેશે."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ના"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _transferOwnership(newAdminId);
            },
            child: const Text("હા, સોંપો"),
          ),
        ],
      ),
    );
  }

  Future<void> _transferOwnership(String newAdminId) async {
    // હાલના લોગ-ઈન થયેલ એડમિનની UID
    String currentAdminId = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _isLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // ૧. નવા વ્યક્તિને એડમિન બનાવો
      DocumentReference newAdminRef =
      FirebaseFirestore.instance.collection('users').doc(newAdminId);
      batch.update(newAdminRef, {'role': 'admin'});

      // ૨. જૂના (પોતાના) રોલને મેમ્બર બનાવી દો
      DocumentReference oldAdminRef =
      FirebaseFirestore.instance.collection('users').doc(currentAdminId);
      batch.update(oldAdminRef, {'role': 'member'});

      await batch.commit();

      if (!mounted) return;

      // સફળતાનો મેસેજ અને લોગઆઉટ (કારણ કે હવે તમે એડમિન નથી)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("માલિકી સફળતાપૂર્વક બદલાઈ ગઈ છે!"),
          backgroundColor: Colors.green));

      // એડમિન પેનલમાંથી બહાર કાઢીને લોગિન પર મોકલી દેવા
      FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ભૂલ આવી: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
/*
have aana par work start karvu che ==> ૧. એડમિન (Admin) પેનલ માટે:
વોચમેન મેનેજમેન્ટ: એડમિન પોતે વોચમેનનું આઈડી બનાવી શકે અને તેને એક્સેસ આપી શકે કે હટાવી શકે.
બ્લોક/યુનિટ મેનેજમેન્ટ: નવી વિંગ (A, B, C) કે નવા ફ્લેટ નંબરો એડમિન પોતે એપમાંથી જ ઉમેરી શકે (અત્યારે કદાચ તમે મેન્યુઅલી Firestore માં નાખ્યા હશે).
એનાલિટિક્સ: આખા મહિનામાં કુલ કેટલા વિઝિટર્સ આવ્યા, કયા ફ્લેટમાં સૌથી વધુ મહેમાન આવે છે તેનો રિપોર્ટ.
૨. મેમ્બર (Member) માટે:
Daily Help (કામવાળા ભાઈ/બહેન): મેમ્બર પોતાના ઘરે આવતા કાયમી માણસો (કચરા-પોતું કરનાર, ડ્રાઈવર) ની એન્ટ્રી કરી શકે, જેથી વોચમેન તેમને ઓળખે અને દર વખતે પૂછવું ન પડે.
Complaint Box: સોસાયટીમાં કોઈ લાઈટ બગડી હોય કે નળ ટપકતો હોય તો મેમ્બર ફોટો પાડીને એડમિનને ફરિયાદ કરી શકે.
Notice Board: એડમિન કોઈ મેસેજ મૂકે (દા.ત. "કાલે પાણી નહીં આવે") તો મેમ્બરને નોટિફિકેશન મળે.
૩. વોચમેન (Watchman) માટે:
Attendance: વોચમેન પોતાની હાજરી (In/Out) એપમાંથી જ પૂરી શકે.
Emergency Contact: સોસાયટીના ઈમરજન્સી નંબરો (એમ્બ્યુલન્સ, ફાયર, પોલીસ, લિફ્ટ રીપેર કરનાર) નું લિસ્ટ વોચમેન પાસે રેડી હોવું જોઈએ.
૪. સિક્યુરિટી અને ટેકનિકલ (સીસ્ટમ વાઈડ):
FCM Notifications (Most Important): વોચમેન એન્ટ્રી કરે ત્યારે મેમ્બરને મોબાઈલમાં ઉપર નોટિફિકેશન આવવું જ જોઈએ (ભલે એપ બંધ હોય). આના માટે Firebase Cloud Messaging સેટ કરવું પડશે.
Image Storage Cleanup: દર મહિને જૂના વિઝિટર્સના ફોટા ઓટોમેટિક ડિલીટ થાય એવું લોજિક (નહીંતર Firebase નું સ્ટોરેજ ભરાઈ જશે).
 */
/*
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>
 */



