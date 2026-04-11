import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visitor_model.dart';
import '../services/notification_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.ensureTokenRegistered());
    });
  }

  // ૧. સ્ટેટસ અપડેટ ફંક્શન (watchmanId ડોક પર રહે — Cloud Function થી વોચમેનને નોટિફિકેશન)
  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('visitors').doc(docId).update({
      'status': status,
      'actionTime': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? 'મંજૂરી મોકલી.' : 'નકાર મોકલ્યો.'),
        ),
      );
    }
  }

  // ૨. Pre-Approve Guest માટે ડાયલોગ
  void _showPreApproveDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController =
    TextEditingController(); // નંબર માટે કંટ્રોલર

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("મહેમાનની પૂર્વ-મંજૂરી"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // કન્ટેન્ટ જેટલી જ જગ્યા રોકશે
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "મહેમાનનું નામ લખો",
                labelText: "નામ",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10), // બે ફિલ્ડ વચ્ચે જગ્યા
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              // નંબર માટેનું કીબોર્ડ ખુલશે
              decoration: const InputDecoration(
                hintText: "મહેમાનનો મોબાઈલ નંબર લખો",
                labelText: "મોબાઈલ નંબર",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("રદ કરો"),
          ),
          ElevatedButton(
            onPressed: () async {
              // નામ અને નંબર બંને હોવા જોઈએ (Validation)
              if (nameController.text.isNotEmpty &&
                  phoneController.text.length >= 10) {
                try {
                  // ૧. Firestore માં ડેટા સેવ કરો
                  DocumentReference docRef = await FirebaseFirestore.instance
                      .collection('pre_approvals')
                      .add({
                    'guestName': nameController.text.trim(),
                    'guestPhone': phoneController.text.trim(),
                    // 🔥 હવે નંબર સેવ થશે
                    'memberId': currentUserId,
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'pre-approved',
                  });

                  Navigator.pop(context); // ડાયલોગ બંધ કરો

                  // ૨. હવે જનરેટ થયેલી ID નો QR બતાવો
                  _showQRCodeDialog(docRef.id, nameController.text.trim());
                } catch (e) {
                  print("Error saving pre-approval: $e");
                }
              } else {
                // જો વિગત અધૂરી હોય તો
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("કૃપા કરીને નામ અને ૧૦ આંકડાનો નંબર લખો")),
                );
              }
            },
            child: const Text("મંજૂર કરો અને QR મેળવો"),
          )
        ],
      ),
    );
  }

  Future<void> _shareQrCode(String guestName) async {
    try {
      // વિજેટને ઈમેજમાં કન્વર્ટ કરો
      RenderRepaintBoundary boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // કામચલાઉ ફાઈલ સેવ કરો
      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/guest_qr.png').create();
      await file.writeAsBytes(pngBytes);

      // શેર કરો
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "આ સોસાયટી એન્ટ્રી QR Code છે $guestName માટે.",
      );
    } catch (e) {
      print("શેર કરવામાં ભૂલ આવી: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("માય સોસાયટી",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: Column(
        children: [
          // --- ૧. Notice Board Section ---
          _buildNoticeBoard(),

          // --- ૨. Quick Actions (Pre-Approve) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showPreApproveDialog,
              icon: const Icon(Icons.verified_user, color: Colors.white),
              label: const Text("મહેમાનને અગાઉથી મંજૂરી આપો",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showComplaintDialog,
                    icon: const Icon(Icons.report_problem),
                    label: const Text('ફરિયાદ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAddStaffDialog,
                    icon: const Icon(Icons.badge),
                    label: const Text('કાયમી સ્ટાફ'),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text("તાજેતરના મુલાકાતીઓ",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),

          // --- ૩. Visitor History List ---
          Expanded(child: _buildVisitorList()),
        ],
      ),
    );
  }

  // નોટિસ બોર્ડ વિજેટ
  Widget _buildNoticeBoard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox();
        var notice = snapshot.data!.docs.first;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[700]!]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.campaign, color: Colors.white),
                SizedBox(width: 8),
                Text("મહત્વની સૂચના",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 8),
              Text(notice['title'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              if ((notice['body'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  notice['body'].toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showComplaintDialog() async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    XFile? picked;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('ફરિયાદ નોંધો'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleC,
                    decoration: const InputDecoration(labelText: 'વિષય')),
                TextField(
                    controller: descC,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'વિગત')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final p = ImagePicker();
                        final x = await p.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 60);
                        if (x != null) setS(() => picked = x);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('ફોટો'),
                    ),
                    if (picked != null)
                      Expanded(
                        child: Text(
                          picked!.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
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
                String photoUrl = '';
                if (picked != null) {
                  final path =
                      'complaints/$currentUserId/${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await FirebaseStorage.instance
                      .ref(path)
                      .putFile(File(picked!.path));
                  photoUrl = await FirebaseStorage.instance
                      .ref(path)
                      .getDownloadURL();
                }
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .get();
                final memberName =
                    userDoc.data()?['name'] ?? userDoc.data()?['email'] ?? '';
                await FirebaseFirestore.instance.collection('complaints').add({
                  'title': titleC.text.trim(),
                  'description': descC.text.trim(),
                  'photoUrl': photoUrl,
                  'memberId': currentUserId,
                  'memberName': memberName,
                  'status': 'pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ફરિયાદ મોકલાઈ.')));
                }
              },
              child: const Text('મોકલો'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStaffDialog() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final roleC = TextEditingController(text: 'કામવાળા / ડ્રાઈવર');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('કાયમી સ્ટાફ ઉમેરો'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'નામ')),
            TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'મોબાઈલ')),
            TextField(
                controller: roleC,
                decoration: const InputDecoration(labelText: 'નોકરી / ભૂમિકા')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('રદ')),
          ElevatedButton(
            onPressed: () async {
              if (nameC.text.trim().isEmpty || phoneC.text.trim().isEmpty) {
                return;
              }
              await FirebaseFirestore.instance.collection('daily_staff').add({
                'memberId': currentUserId,
                'staffName': nameC.text.trim(),
                'staffPhone': phoneC.text.trim(),
                'staffRole': roleC.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('સ્ટાફ ઉમેરાયો.')));
              }
            },
            child: const Text('સાચવો'),
          ),
        ],
      ),
    );
  }

  // વિઝિટર લિસ્ટ વિજેટ
  Widget _buildVisitorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('visitors')
          .where('memberId', isEqualTo: currentUserId)
          .orderBy('entryTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Center(child: Text("કોઈ ડેટા નથી"));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var visitor =
            VisitorModel.fromFirestore(snapshot.data!.docs[index]);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ]),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: visitor.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: visitor.photoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.person),
                        )
                      : const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.person, size: 40),
                        ),
                ),
                title: Text(visitor.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // બધું ડાબી બાજુથી શરૂ થાય તે માટે
                  children: [
                    // જૂનું હેતુ અને સમયનું ટેક્સ્ટ
                    Text(
                      "${visitor.purpose}\n${visitor.entryTime != null ? DateFormat('jm').format(visitor.entryTime!) : ''}",
                    ),

                    // 🔥 અહીં નવું 'Checked Out' સમયનું લોજિક
                    if (visitor.status == 'checked_out' && visitor.exitTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0), // થોડી જગ્યા રાખવા માટે
                        child: Text(
                          "બહાર ગયા: ${DateFormat('hh:mm a').format(visitor.exitTime!)}",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: _buildStatusAction(visitor),
              ),
            );
          },
        );
      },
    );
  }

// આ ફંક્શનને ડાયલોગમાં અથવા નવી સ્ક્રીન પર બતાવી શકાય
  void _showQRCodeDialog(String preApproveId, String guestName) {
    showDialog(
      context: context,
      barrierDismissible: false, // યુઝર બહાર ક્લિક કરીને બંધ ન કરી શકે
      builder: (context) => AlertDialog(
        title: Text("$guestName નો QR Code"),
        content: SingleChildScrollView( // સ્કીન નાની હોય તો સ્ક્રોલ થઈ શકે
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "આ QR મહેમાનને WhatsApp પર શેર કરો.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 🔥 RepaintBoundary ને ફિક્સ સાઈઝ આપવા માટે SizedBox વાપર્યું
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                    width: 200, // ફિક્સ પહોળાઈ
                    height: 200, // ફિક્સ ઉંચાઈ
                    child: QrImageView(
                      data: preApproveId,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 🔥 શેર બટન
          ElevatedButton.icon(
            onPressed: () => _shareQrCode(guestName),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text("WhatsApp પર શેર કરો", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 45), // બટન આખું દેખાય
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("બંધ કરો"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(VisitorModel visitor) {
    if (visitor.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon:
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              onPressed: () => _updateStatus(visitor.id, 'approved')),
          IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: () => _updateStatus(visitor.id, 'rejected')),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: visitor.status == 'approved' ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        visitor.status == 'approved' ? "મંજૂર" : "અસ્વીકાર",
        style: TextStyle(
            color: visitor.status == 'approved'
                ? Colors.green[700]
                : Colors.red[700],
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
