import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/patrol_model.dart';
import '../services/guard_patrol_service.dart';

class WatchmanPatrolScreen extends StatefulWidget {
  final String societyId;
  final String guardUid;
  final String guardName;
  final String guardPhone;

  const WatchmanPatrolScreen({
    super.key,
    required this.societyId,
    required this.guardUid,
    required this.guardName,
    required this.guardPhone,
  });

  @override
  State<WatchmanPatrolScreen> createState() => _WatchmanPatrolScreenState();
}

class _WatchmanPatrolScreenState extends State<WatchmanPatrolScreen> {
  final GuardPatrolService _service = GuardPatrolService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Midnight obsidian night palette
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'રાત્રિ સુરક્ષા પેટ્રોલિંગ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'ચેકપોઇન્ટ QR સ્કેન અને રાઉન્ડ મેનેજર',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<PatrolShiftSession?>(
        stream: _service.streamActiveSession(widget.societyId, widget.guardUid),
        builder: (context, sessionSnap) {
          if (sessionSnap.connectionState == ConnectionState.waiting || _isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          final activeSession = sessionSnap.data;

          return StreamBuilder<List<PatrolCheckpoint>>(
            stream: _service.streamCheckpoints(widget.societyId),
            builder: (context, cpSnap) {
              final checkpoints = cpSnap.data ?? [];

              if (activeSession == null) {
                return _buildNoActiveSessionView(checkpoints);
              }

              return _buildActivePatrolSessionView(activeSession, checkpoints);
            },
          );
        },
      ),
    );
  }

  // ================= VIEW 1: NO ACTIVE ROUND (START ROUND VIEW) =================

  Widget _buildNoActiveSessionView(List<PatrolCheckpoint> checkpoints) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 64,
              color: Color(0xFF818CF8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'નવો પેટ્રોલિંગ રાઉન્ડ શરૂ કરો',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'સોસાયટીમાં કુલ ${checkpoints.length} સુરક્ષા ચેકપોઇન્ટ્સ સેટ કરેલ છે. પેટ્રોલિંગ શરૂ કરવા માટે નીચે આપેલ બટન દબાવો.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 32),

          // Start round button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: checkpoints.isEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('સોસાયટી એડમિન દ્વારા હજુ ચેકપોઇન્ટ્સ ઉમેરેલ નથી!'),
                        ),
                      );
                    }
                  : () => _showStartRoundModal(checkpoints.length),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'પેટ્રોલિંગ રાઉન્ડ શરૂ કરો',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartRoundModal(int totalCheckpoints) {
    int selectedRound = 1;
    final rounds = [
      {'num': 1, 'label': 'રાઉન્ડ ૧ (૧૧:૦૦ PM - ૧૨:૩૦ AM)'},
      {'num': 2, 'label': 'રાઉન્ડ ૨ (૦૧:૦૦ AM - ૦૨:૩૦ AM)'},
      {'num': 3, 'label': 'રાઉન્ડ ૩ (૦૩:૦૦ AM - ૦૪:૩૦ AM)'},
      {'num': 4, 'label': 'રાઉન્ડ ૪ (૦૫:૦૦ AM - ૦૬:૩૦ AM)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'રાઉન્ડ પસંદ કરો:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...rounds.map((r) {
                    final numVal = r['num'] as int;
                    final isSel = selectedRound == numVal;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFF6366F1) : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSel
                              ? const Color(0xFF6366F1)
                              : Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            '$numVal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          r['label'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isSel
                            ? const Icon(Icons.check_circle, color: Color(0xFF818CF8))
                            : null,
                        onTap: () => setModalState(() => selectedRound = numVal),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);

                        final rItem = rounds.firstWhere((e) => e['num'] == selectedRound);
                        await _service.startPatrolRound(
                          societyId: widget.societyId,
                          guardUid: widget.guardUid,
                          guardName: widget.guardName,
                          guardPhone: widget.guardPhone,
                          roundNumber: selectedRound,
                          roundLabel: rItem['label'] as String,
                          totalCheckpoints: totalCheckpoints,
                        );

                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text(
                        'શરૂ કરો',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= VIEW 2: ACTIVE PATROL SESSION =================

  Widget _buildActivePatrolSessionView(
    PatrolShiftSession session,
    List<PatrolCheckpoint> checkpoints,
  ) {
    final scannedCodes = session.scanLogs.map((l) => l.checkpointCode).toSet();
    final isDone = session.scannedCount >= session.totalCheckpoints;

    return Column(
      children: [
        // Top HUD card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDone ? const Color(0xFF10B981) : const Color(0xFF6366F1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: Color(0xFF818CF8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        session.roundLabel.isNotEmpty
                            ? session.roundLabel
                            : 'રાઉન્ડ ${session.roundNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDone ? '૧૦૦% પૂર્ણ' : 'પ્રગતિમાં',
                      style: TextStyle(
                        color: isDone ? const Color(0xFF34D399) : const Color(0xFF60A5FA),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ચેકપોઇન્ટ સ્કેન: ${session.scannedCount} / ${session.totalCheckpoints}',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${session.progressPercent}% પૂર્ણ',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: session.progressRatio,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Checkpoint checklist title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Text(
                'પેટ્રોલિંગ ચેકપોઇન્ટ્સ યાદી:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'બાકી: ${(session.totalCheckpoints - session.scannedCount).clamp(0, 99)}',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Checkpoints checklist
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: checkpoints.length,
            itemBuilder: (context, index) {
              final cp = checkpoints[index];
              final isScanned = scannedCodes.contains(cp.code);
              final scanLog = isScanned
                  ? session.scanLogs.firstWhere((l) => l.checkpointCode == cp.code)
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isScanned
                      ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isScanned
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isScanned
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isScanned ? Icons.check : Icons.location_on_outlined,
                        size: 16,
                        color: isScanned ? Colors.white : const Color(0xFF94A3B8),
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
                                cp.code,
                                style: TextStyle(
                                  color: isScanned
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF818CF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cp.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isScanned
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cp.location,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                          if (scanLog != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'સ્કેન સમય: ${DateFormat('hh:mm a').format(scanLog.scannedAt)}',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Action Bar (Scan Button & Finish Button)
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _openScanner(session),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: const Text(
                    'QR સ્કેન કરો',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _confirmCompleteRound(session),
                  child: Text(
                    isDone ? 'પૂર્ણ કરો ✅' : 'સમાપ્ત',
                    style: TextStyle(
                      color: isDone ? const Color(0xFF34D399) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= QR SCANNER & INCIDENT LOGGING =================

  void _openScanner(PatrolShiftSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PatrolScannerSheet(
        societyId: widget.societyId,
        sessionId: session.id,
        guardUid: widget.guardUid,
        guardName: widget.guardName,
        onScanSuccess: (msg) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  void _confirmCompleteRound(PatrolShiftSession session) {
    final remaining = session.totalCheckpoints - session.scannedCount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('પેટ્રોલિંગ રાઉન્ડ પૂર્ણ કરવો છે?', style: TextStyle(color: Colors.white)),
        content: Text(
          remaining > 0
              ? 'હજુ $remaining ચેકપોઇન્ટ્સ સ્કેન કરવાના બાકી છે. શું તમે ખરેખર રાઉન્ડ અત્યારે જ પૂર્ણ કરવા માંગો છો?'
              : 'બધા ચેકપોઇન્ટ્સ સફળતાપૂર્વક સ્કેન થઈ ગયા છે. રાઉન્ડ પૂર્ણ કરવો છે?',
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ના, ચાલુ રાખો', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.completePatrolRound(
                societyId: widget.societyId,
                sessionId: session.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('પેટ્રોલિંગ રાઉન્ડ સફળતાપૂર્વક પૂર્ણ થયો! 🎉'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('હા, પૂર્ણ કરો'),
          ),
        ],
      ),
    );
  }
}

// ================= MODAL SCANNER COMPONENT =================

class _PatrolScannerSheet extends StatefulWidget {
  final String societyId;
  final String sessionId;
  final String guardUid;
  final String guardName;
  final Function(String) onScanSuccess;

  const _PatrolScannerSheet({
    required this.societyId,
    required this.sessionId,
    required this.guardUid,
    required this.guardName,
    required this.onScanSuccess,
  });

  @override
  State<_PatrolScannerSheet> createState() => _PatrolScannerSheetState();
}

class _PatrolScannerSheetState extends State<_PatrolScannerSheet> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      cameraResolution: const Size(1280, 720),
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    setState(() => _hasScanned = true);

    // Prompt optional incident note
    final note = await _showIncidentNoteDialog();

    final result = await GuardPatrolService().scanCheckpoint(
      societyId: widget.societyId,
      sessionId: widget.sessionId,
      qrPayload: raw,
      incidentNote: note,
      guardUid: widget.guardUid,
      guardName: widget.guardName,
    );

    if (mounted) {
      if (result['success'] == true) {
        widget.onScanSuccess(result['message'] as String);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        setState(() => _hasScanned = false);
      }
    }
  }

  Future<String?> _showIncidentNoteDialog() async {
    final noteCtrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF818CF8)),
            SizedBox(width: 8),
            Text('ચેકપોઇન્ટ નિરીક્ષણ', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'શું આ ચેકપોઇન્ટ પર બધું સલામત અને સામાન્ય છે?',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'કોઈ સમસ્યા / નોંધ? (વૈકલ્પિક)',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'દા.ત. લાઈટ બંધ છે, દરવાજો ખુલ્લો હતો...',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('બધું બરાબર છે ✅', style: TextStyle(color: Color(0xFF34D399))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            child: const Text('નોંધ સાથે સાચવો'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ચેકપોઇન્ટ QR સ્કેનર',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'દિવાલ પર લગાવેલ QR કોડ સામે કેમેરા રાખો',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: _isTorchOn
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white,
                  ),
                  onPressed: () {
                    _controller.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleBarcode,
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF6366F1), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
