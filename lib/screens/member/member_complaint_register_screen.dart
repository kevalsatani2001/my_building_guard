import 'dart:io';
import 'package:building_guard/core/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/complaints/complaints_bloc.dart';
import '../../models/complaint_model.dart';
import '../../services/society_service.dart';
import '../../widgets/premium_app_bar.dart';

class MemberComplaintRegisterScreen extends StatefulWidget {
  final String memberName;
  final String memberFlat;
  final String? initialCategory;
  final String? initialTitle;
  final String? initialDesc;

  const MemberComplaintRegisterScreen({
    super.key,
    this.memberName = '',
    this.memberFlat = '',
    this.initialCategory,
    this.initialTitle,
    this.initialDesc,
  });

  @override
  State<MemberComplaintRegisterScreen> createState() => _MemberComplaintRegisterScreenState();
}

class _MemberComplaintRegisterScreenState extends State<MemberComplaintRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();

  String _selectedCategory = 'પાણી પુરવઠો'.tr;
  bool _isUrgent = false;
  bool _isSubmitting = false;
  XFile? _pickedImage;

  String _resolvedName = '';
  String _resolvedFlat = '';

  final List<(String, IconData, Color)> _categories = [
    ('પાણી પુરવઠો'.tr, Icons.water_drop_rounded, Color(0xFF0284C7)),
    ('લાઈટ / વીજળી'.tr, Icons.bolt_rounded, Color(0xFFD97706)),
    ('લિફ્ટ સમસ્યા'.tr, Icons.elevator_rounded, Color(0xFF4F46E5)),
    ('સફાઈ / કચરો'.tr, Icons.cleaning_services_rounded, Color(0xFF0D9488)),
    ('પાર્કિંગ વિવાદ'.tr, Icons.local_parking_rounded, Color(0xFF7C3AED)),
    ('સિક્યોરિટી'.tr, Icons.shield_rounded, Color(0xFFDC2626)),
    ('અન્ય સામાન્ય'.tr, Icons.more_horiz_rounded, Color(0xFF64748B)),
  ];

  (IconData, Color) _getCategoryMeta(String category) {
    final lower = category.toLowerCase();
    if (category.contains('પાણી') || lower.contains('water')) {
      return (Icons.water_drop_rounded, const Color(0xFF0284C7));
    } else if (category.contains('લાઈટ') || category.contains('વીજળી') || lower.contains('bolt') || lower.contains('electric')) {
      return (Icons.bolt_rounded, const Color(0xFFD97706));
    } else if (category.contains('લિફ્ટ') || lower.contains('lift') || lower.contains('elevator')) {
      return (Icons.elevator_rounded, const Color(0xFF4F46E5));
    } else if (category.contains('સફાઈ') || category.contains('કચરો') || lower.contains('clean')) {
      return (Icons.cleaning_services_rounded, const Color(0xFF0D9488));
    } else if (category.contains('પાર્કિંગ') || lower.contains('parking')) {
      return (Icons.local_parking_rounded, const Color(0xFF7C3AED));
    } else if (category.contains('સિક્યોરિટી') || lower.contains('security')) {
      return (Icons.shield_rounded, const Color(0xFFDC2626));
    }
    return (Icons.report_problem_rounded, const Color(0xFF64748B));
  }

  @override
  void initState() {
    super.initState();
    _resolvedName = widget.memberName;
    _resolvedFlat = widget.memberFlat;

    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialTitle != null) {
      _titleC.text = widget.initialTitle!;
    }
    if (widget.initialDesc != null) {
      _descC.text = widget.initialDesc!;
    }

    if (_resolvedName.isEmpty || _resolvedFlat.isEmpty) {
      _loadMemberDetails();
    }

    final societyId = SocietyService.instance.societyId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    context.read<ComplaintsBloc>().add(
          ComplaintsSubscriptionRequested(
            societyId: societyId,
            memberId: uid,
          ),
        );
  }

  Future<void> _loadMemberDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await AppFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        if (mounted) {
          setState(() {
            if (_resolvedName.isEmpty) {
              _resolvedName = (d['name'] ?? d['fullName'] ?? 'મેમ્બર'.tr).toString();
            }
            if (_resolvedFlat.isEmpty) {
              final b = (d['block'] ?? d['wing'] ?? '').toString();
              final f = (d['flatNumber'] ?? d['houseNumber'] ?? '').toString();
              _resolvedFlat = b.isNotEmpty ? '$b-$f' : f;
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, imageQuality: 75);
      if (photo != null) {
        setState(() => _pickedImage = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ફોટો પસંદ કરવામાં ભૂલ: $e'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

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
        'memberName': _resolvedName.isNotEmpty ? _resolvedName : 'મેમ્બર'.tr,
        'memberFlat': _resolvedFlat,
        'isUrgent': _isUrgent,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'societyId': SocietyService.instance.societyId,
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ફરિયાદ સફળતાપૂર્વક નોંધાઈ ગઈ છે!'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ભૂલ આવી: $e'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePreviewDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 260,
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                },
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PremiumAppBar(
        title: 'સોસાયટી ફરિયાદ નિવારણ'.tr,
        subtitle: 'સમસ્યા નોંધાવો & સ્ટેટસ ટ્રેક કરો'.tr,
        icon: Icons.support_agent_rounded,
        accentColor: Color(0xFF6D28D9),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. HERO BANNER WITH 3D ILLUSTRATION ASSET (Text on left, 3D on right)
            _buildHeroBanner(),

            // 2. MAIN FORM CARD
            _buildFormCard(),

            const SizedBox(height: 24),

            // 3. PAST COMPLAINTS SECTION
            _buildPastComplaints(currentUserId),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Hero Image (3D Character on far right, clean gradient on left)
            Image.asset(
              'assets/images/complaint_hero.jpg',
              height: 165,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Text strictly constrained to the left portion so it NEVER covers the 3D artwork
            Container(
              height: 165,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.support_agent_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'સોસાયટી સપોર્ટ ડેસ્ક'.tr,
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'સમસ્યા કે ફરિયાદ નોંધો'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'કમિટી અને એડમિન દ્વારા ત્વરિત નિરાકરણ કરવામાં આવશે.'.tr,
                          style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, height: 1.35, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 9,
                    child: SizedBox(), // Untouched space for the 3D illustration!
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Section Header
            Row(
              children: [
                Icon(Icons.category_rounded, size: 18, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text(
                  'સમસ્યાનો પ્રકાર પસંદ કરો:'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Premium Category Wrap Chips
            Wrap(
              spacing: 8,
              runSpacing: 9,
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c.$1;
                final color = c.$3;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = c.$1);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            c.$2,
                            size: 13,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.$1,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? color : const Color(0xFF334155),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, size: 14, color: color),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Subject TextField
            TextFormField(
              controller: _titleC,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'વિષય / ટૂંકી વિગત *'.tr,
                hintText: 'દા.ત. ૩જા માળે લાઈટ બંધ છે / સ્લોટ સમસ્યા'.tr,
                labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                floatingLabelStyle: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                prefixIcon: Container(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.short_text_rounded, color: Color(0xFF7C3AED), size: 18),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'કૃપા કરીને વિષય લખો'.tr : null,
            ),

            const SizedBox(height: 16),

            // Description TextField
            TextFormField(
              controller: _descC,
              maxLines: 4,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'સંપૂર્ણ વિગત (Description)'.tr,
                hintText: 'સમસ્યા વિશે વિગતવાર લખો જેથી કમિટી સરળતાથી ઝડપી ઉકેલ લાવી શકે...'.tr,
                labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                floatingLabelStyle: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // PHOTO ATTACHMENT CARD (COMPLETELY PREVENTS ANY OVERFLOW)
            _buildPhotoAttachmentSection(),

            const SizedBox(height: 18),

            // URGENT TOGGLE CARD
            _buildUrgentToggleCard(),

            const SizedBox(height: 22),

            // SUBMIT BUTTON WITH GRADIENT & SHADOW
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitComplaint,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isSubmitting ? 'ફરિયાદ મોકલાઈ રહી છે...'.tr : 'ફરિયાદ સબમિટ કરો'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoAttachmentSection() {
    final hasPhoto = _pickedImage != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasPhoto ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
          width: hasPhoto ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_camera_rounded, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'સમસ્યાનો ફોટો (વૈકલ્પિક)'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
              if (hasPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '૧ ફોટો પસંદ થયો'.tr,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Two Action Buttons Side-by-Side (Zero Overflow)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 17, color: Color(0xFF7C3AED)),
                  label: Text('કેમેરાથી લો'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF7C3AED))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    backgroundColor: const Color(0xFFF5F3FF),
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 17, color: Color(0xFF0284C7)),
                  label: Text('ગેલેરીમાંથી પસંદ'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0284C7))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    backgroundColor: const Color(0xFFF0F9FF),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          // Photo Preview Card if picked
          if (hasPhoto) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_pickedImage!.path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _pickedImage = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgentToggleCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: _isUrgent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
              size: 22,
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
                      'તાત્કાલિક ધ્યાન જરૂરી (Urgent)'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                    ),
                    if (_isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ઇમરજન્સી'.tr, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'જો પાણી લીકેજ, મેઈન લાઈન કે લિફ્ટ બ્રેકડાઉન હોય તો ચાલુ કરો.'.tr,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch(
            value: _isUrgent,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFDC2626),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _isUrgent = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPastComplaints(String currentUserId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Text(
                'મારી અગાઉની ફરિયાદો'.tr,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text(
                'રીયલટાઇમ સ્ટેટસ'.tr,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          BlocBuilder<ComplaintsBloc, ComplaintsState>(
            builder: (context, state) {
              if (state is ComplaintsLoading || state is ComplaintsInitial) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
              }

              final complaints = (state is ComplaintsLoaded) ? state.complaints : <ComplaintModel>[];
              if (complaints.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: complaints.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = complaints[index];
                  final desc = c.description;
                  final category = c.category;
                  final photoUrl = c.photoUrl;
                  final status = c.status;
                  final dateStr = DateFormat('dd MMM, hh:mm a').format(c.createdAt);

                  // Clean title: remove [category] prefix if already embedded
                  String cleanTitle = c.title;
                  if (category.isNotEmpty && cleanTitle.startsWith('[$category]')) {
                    cleanTitle = cleanTitle.substring('[$category]'.length).trim();
                  } else if (category.isNotEmpty && cleanTitle.startsWith('[$category ]')) {
                    cleanTitle = cleanTitle.substring('[$category ]'.length).trim();
                  } else if (cleanTitle.startsWith('[')) {
                    final closeBracket = cleanTitle.indexOf(']');
                    if (closeBracket != -1 && closeBracket < 30) {
                      cleanTitle = cleanTitle.substring(closeBracket + 1).trim();
                    }
                  }
                  if (cleanTitle.isEmpty) cleanTitle = c.title;

                  final catMeta = _getCategoryMeta(category);
                  final catIcon = catMeta.$1;
                  final catColor = catMeta.$2;

                  Color statusColor = const Color(0xFFD97706);
                  Color statusBg = const Color(0xFFFFFBEB);
                  Color statusBorder = const Color(0xFFFDE68A);
                  IconData statusIcon = Icons.hourglass_top_rounded;
                  String statusLabel = 'પેન્ડિંગ'.tr;

                  if (status == 'resolved' || status == 'completed') {
                    statusColor = const Color(0xFF16A34A);
                    statusBg = const Color(0xFFF0FDF4);
                    statusBorder = const Color(0xFFBBF7D0);
                    statusIcon = Icons.check_circle_rounded;
                    statusLabel = 'ઉકેલાઈ ગયેલ'.tr;
                  } else if (status == 'in_progress') {
                    statusColor = const Color(0xFF0284C7);
                    statusBg = const Color(0xFFF0F9FF);
                    statusBorder = const Color(0xFFBAE6FD);
                    statusIcon = Icons.engineering_rounded;
                    statusLabel = 'કામ ચાલુ છે'.tr;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Category Avatar + Category Pill + Urgent Badge + Status Pill
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      catColor.withValues(alpha: 0.18),
                                      catColor.withValues(alpha: 0.06),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(catIcon, size: 18, color: catColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (category.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: catColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: catColor,
                                          ),
                                        ),
                                      ),
                                    if (c.isUrgent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.flash_on_rounded, size: 11, color: Color(0xFFDC2626)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'ઇમરજન્સી'.tr,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 12, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Clean Subject Title
                          Text(
                            cleanTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),

                          // Description in bubble if not empty
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Text(
                                desc,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${'ઉકેલ નોંધ: '.tr}${c.resolutionNotes}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Bottom Footer: Date & Photo Button
                          Row(
                            children: [
                              if (dateStr.isNotEmpty) ...[
                                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 5),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (photoUrl.isNotEmpty) ...[
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _showImagePreviewDialog(photoUrl);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFDDD6FE)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.image_rounded, size: 14, color: Color(0xFF7C3AED)),
                                          const SizedBox(width: 5),
                                          Text(
                                            'ફોટો જુઓ'.tr,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/complaint_empty.jpg',
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'કોઈ પેન્ડિંગ ફરિયાદ નથી!'.tr,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'તમારી સોસાયટી શાંતિપૂર્ણ અને સુવ્યવસ્થિત છે.\nજો કોઈ પ્રશ્ન જણાય તો ઉપરથી સરળતાથી નોંધાવો.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }
}
