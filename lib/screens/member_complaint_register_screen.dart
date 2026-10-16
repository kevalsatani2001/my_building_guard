import 'dart:io';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/society_service.dart';

class MemberComplaintRegisterScreen extends StatefulWidget {
  final String memberName;
  final String memberFlat;

  const MemberComplaintRegisterScreen({
    super.key,
    this.memberName = '',
    this.memberFlat = '',
  });

  @override
  State<MemberComplaintRegisterScreen> createState() => _MemberComplaintRegisterScreenState();
}

class _MemberComplaintRegisterScreenState extends State<MemberComplaintRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();

  String _selectedCategory = 'પાણી પુરવઠો';
  bool _isUrgent = false;
  bool _isSubmitting = false;
  XFile? _pickedImage;

  final List<(String, IconData, Color)> _categories = [
    ('પાણી પુરવઠો', Icons.water_drop_rounded, Colors.blue),
    ('લાઈટ / વીજળી', Icons.bolt_rounded, Colors.amber),
    ('લિફ્ટ સમસ્યા', Icons.elevator_rounded, Colors.indigo),
    ('સફાઈ / કચરો', Icons.cleaning_services_rounded, Colors.teal),
    ('પાર્કિંગ વિવાદ', Icons.local_parking_rounded, Colors.purple),
    ('સિક્યોરિટી', Icons.security_rounded, Colors.red),
    ('અન્ય સામાન્ય', Icons.chat_bubble_outline_rounded, Colors.grey),
  ];

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, imageQuality: 70);
      if (photo != null) {
        setState(() => _pickedImage = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ફોટો લેવામાં ભૂલ: $e')),
      );
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isSubmitting = true);

    try {
      String photoUrl = '';
      if (_pickedImage != null) {
        final path = 'complaints/$currentUserId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadTask = await FirebaseStorage.instance.ref(path).putFile(File(_pickedImage!.path));
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      final fullTitle = '[$_selectedCategory] ${_titleC.text.trim()}';

      await AppFirestore.instance.collection('complaints').add({
        'title': fullTitle,
        'category': _selectedCategory,
        'description': _descC.text.trim(),
        'photoUrl': photoUrl,
        'memberId': currentUserId,
        'memberName': widget.memberName.isNotEmpty ? widget.memberName : 'મેમ્બર',
        'memberFlat': widget.memberFlat,
        'isUrgent': _isUrgent,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'societyId': SocietyService.instance.societyId,
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ફરિયાદ સફળતાપૂર્વક નોંધાઈ ગઈ છે.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ભૂલ આવી: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ફરિયાદ નોંધણી',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Modern Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'સમસ્યા કે ફરિયાદ નોંધો',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'સોસાયટી કમિટી/એડમિન દ્વારા તુરંત નિરાકરણ કરવામાં આવશે.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'સમસ્યાનો પ્રકાર પસંદ કરો:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final isSelected = _selectedCategory == c.$1;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.$2, size: 14, color: isSelected ? Colors.white : c.$3),
                              const SizedBox(width: 6),
                              Text(c.$1),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: const Color(0xFFF8FAFC),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (_) => setState(() => _selectedCategory = c.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleC,
                      decoration: InputDecoration(
                        labelText: 'વિષય / ટૂંકી વિગત *',
                        hintText: 'દા.ત. ૩જા માળે લાઈટ બંધ છે',
                        prefixIcon: const Icon(Icons.short_text_rounded, color: Color(0xFF7C3AED)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'કૃપા કરીને વિષય લખો' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descC,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'સંપૂર્ણ વિગત (Description)',
                        hintText: 'સમસ્યા વિશે વિગતે જણાવો જેથી કમિટી સરળતાથી ઉકેલ લાવી શકે...',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo attachment preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_camera_rounded, size: 20, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 8),
                              const Text(
                                'સમસ્યાનો ફોટો (વૈકલ્પિક)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                label: const Text('કેમેરો'),
                              ),
                              TextButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 16),
                                label: const Text('ગેલેરી'),
                              ),
                            ],
                          ),
                          if (_pickedImage != null) ...[
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_pickedImage!.path),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                      onPressed: () => setState(() => _pickedImage = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgent Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'તાત્કાલિક ધ્યાન જરૂરી (Urgent)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'જો ગંભીર ઇમરજન્સી કે પાણી/લાઈટ નો તાત્કાલિક પ્રશ્ન હોય તો ચાલુ કરો.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: Colors.red,
                      value: _isUrgent,
                      onChanged: (v) => setState(() => _isUrgent = v),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'મોકલાઈ રહી છે...' : 'ફરિયાદ સબમિટ કરો',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildPastComplaints(currentUserId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPastComplaints(String currentUserId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'મારી અગાઉની ફરિયાદો',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.instance
                .collection('complaints')
                .where('memberId', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'કોઈ ફરિયાદ નોંધાયેલ નથી.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  final title = (d['title'] ?? '').toString();
                  final desc = (d['description'] ?? '').toString();
                  final status = (d['status'] ?? 'pending').toString();

                  Color statusColor = Colors.orange;
                  String statusLabel = 'પેન્ડિંગ';
                  if (status == 'resolved' || status == 'completed') {
                    statusColor = Colors.green;
                    statusLabel = 'ઉકેલાઈ ગયેલ';
                  } else if (status == 'in_progress') {
                    statusColor = Colors.blue;
                    statusLabel = 'કામ ચાલુ છે';
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          child: Icon(Icons.report_problem_rounded, color: statusColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
