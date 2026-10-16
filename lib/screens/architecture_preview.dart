import 'package:flutter/material.dart';
import '../widgets/premium_ui.dart';

class ArchitecturePreviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tempBlocks;
  final String architectureType;

  const ArchitecturePreviewScreen({
    super.key,
    required this.tempBlocks,
    required this.architectureType,
  });

  @override
  Widget build(BuildContext context) {
    int totalUnits = 0;
    for (final b in tempBlocks) {
      final v1 = (b['v1'] as num?)?.toInt() ?? 0;
      final v2 = (b['v2'] as num?)?.toInt() ?? 0;
      if (architectureType == 'Wing') {
        totalUnits += (v1 * v2);
      } else {
        totalUnits += (v2 >= v1 ? (v2 - v1 + 1) : 0);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("સોસાયટી આર્કિટેક્ચર પ્રિવ્યુ"),
        elevation: 0,
      ),
      body: tempBlocks.isEmpty
          ? const PremiumEmptyState(
              message: "કોઈ આર્કિટેક્ચર ડેટા ઉપલબ્ધ નથી.",
              icon: Icons.grid_view_rounded,
            )
          : Column(
              children: [
                // Top Summary Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: PremiumStatCard(
                          title: 'કુલ $architectureType',
                          value: '${tempBlocks.length}',
                          icon: Icons.apartment_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumStatCard(
                          title: 'કુલ ઘર / એકમો',
                          value: '$totalUnits',
                          icon: Icons.holiday_village_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Block List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tempBlocks.length,
                    itemBuilder: (context, index) {
                      final b = tempBlocks[index];
                      return _buildBlockCard(context, b);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // દરેક બ્લોક (વિંગ/શેરી) માટેનું કાર્ડ
  Widget _buildBlockCard(BuildContext context, Map<String, dynamic> b) {
    final cs = Theme.of(context).colorScheme;
    final v1 = (b['v1'] as num?)?.toInt() ?? 0;
    final v2 = (b['v2'] as num?)?.toInt() ?? 0;
    final blockUnits = architectureType == 'Wing' ? (v1 * v2) : (v2 >= v1 ? (v2 - v1 + 1) : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // હેડર સેક્શન
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.domain_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$architectureType ${b['name']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    architectureType == 'Wing' ? "$v1 માળ • $blockUnits ઘર" : "$blockUnits પ્લોટ્સ",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // બોડી સેક્શન
          Padding(
            padding: const EdgeInsets.all(14),
            child: architectureType == 'Wing'
                ? _buildWingLayout(b, v1, v2)
                : _buildStreetLayout(b, v1, v2),
          ),
        ],
      ),
    );
  }

  // વિંગ લેઆઉટ (માળ મુજબ)
  Widget _buildWingLayout(Map<String, dynamic> b, int v1, int v2) {
    return Column(
      children: List.generate(v1, (fIndex) {
        int floorNo = v1 - fIndex; // ટોપ ફ્લોર થી ગ્રાઉન્ડ
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Text(
                  "${floorNo}F",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.teal.shade900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(v2, (uIndex) {
                      String uID = "$floorNo${(uIndex + 1).toString().padLeft(2, '0')}";
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

  // શેરી લેઆઉટ (ગ્રીડ મુજબ)
  Widget _buildStreetLayout(Map<String, dynamic> b, int v1, int v2) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate((v2 >= v1 ? (v2 - v1 + 1) : 0), (index) {
        String uID = (v1 + index).toString();
        return _unitTile(uID);
      }),
    );
  }

  // યુનિટ ટાઈલ UI
  Widget _unitTile(String id) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_outlined, size: 16, color: Colors.teal.shade700),
          const SizedBox(height: 4),
          Text(
            id,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}