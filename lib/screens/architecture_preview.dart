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
    return Scaffold(
      appBar: AppBar(
        title: const Text("સોસાયટી આર્કિટેક્ચર પ્રિવ્યુ"),
      ),
      body: tempBlocks.isEmpty
          ? const PremiumEmptyState(
              message: "કોઈ ડેટા ઉપલબ્ધ નથી.",
              icon: Icons.grid_view_rounded,
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tempBlocks.length,
        itemBuilder: (context, index) {
          final b = tempBlocks[index];
          return _buildBlockCard(context, b);
        },
      ),
    );
  }

  // દરેક બ્લોક (વિંગ/શેરી) માટેનું કાર્ડ
  Widget _buildBlockCard(BuildContext context, Map<String, dynamic> b) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apartment, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      "${architectureType}: ${b['name']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Text(
                  architectureType == 'Wing' ? "${b['v1']} Floors" : "Plots",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          // બોડી સેક્શન
          Padding(
            padding: const EdgeInsets.all(15),
            child: architectureType == 'Wing'
                ? _buildWingLayout(b)
                : _buildStreetLayout(b),
          ),
        ],
      ),
    );
  }

  // વિંગ લેઆઉટ (માળ મુજબ)
  Widget _buildWingLayout(Map<String, dynamic> b) {
    return Column(
      children: List.generate(b['v1'], (fIndex) {
        int floorNo = b['v1'] - fIndex; // 5, 4, 3...
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 45,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "${floorNo}F",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(b['v2'], (uIndex) {
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
  Widget _buildStreetLayout(Map<String, dynamic> b) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate((b['v2'] - b['v1'] + 1), (index) {
        String uID = (b['v1'] + index).toString();
        return _unitTile(uID);
      }),
    );
  }

  // યુનિટ ટાઈલ UI
  Widget _unitTile(String id) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.home_outlined, size: 18, color: Colors.blueAccent),
          const SizedBox(height: 5),
          Text(
            id,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}