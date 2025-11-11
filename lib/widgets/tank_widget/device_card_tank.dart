// lib/widgets/device_card_tank.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';
import '/providers/org_provider.dart';
import '/screens/TANK/tank_full_screen.dart'; // ✅ NEW IMPORT

class TankCard extends StatelessWidget {
  final Map<String, dynamic> device;
  const TankCard({super.key, required this.device});

  int _parsePercent(dynamic status) {
    if (status == null) return 0;
    if (status is int) return status.clamp(0, 100);
    if (status is double) return status.round().clamp(0, 100);
    if (status is String) {
      final n = int.tryParse(status);
      if (n != null) return n.clamp(0, 100);
      return 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    final String deviceName = device['device_name'] ?? 'Unnamed Tank';
    final String deviceId = device['device_id']?.toString() ?? '';
    final dynamic rawStatus = device['status'];
    final int percent = _parsePercent(rawStatus);

    final int maxThreshold = (device['max_threshold'] is int)
        ? device['max_threshold']
        : (int.tryParse(device['max_threshold']?.toString() ?? '') ?? 100);

    final int minThreshold = (device['min_threshold'] is int)
        ? device['min_threshold']
        : (int.tryParse(device['min_threshold']?.toString() ?? '') ?? 0);

    Color color;
    if (percent <= minThreshold) {
      color = Colors.red;
    } else if (percent >= maxThreshold) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    String blockName = '';
    final blockId = device['block_id'];
    if (blockId != null) {
      final blocks = deviceProvider.blocks;
      final match = blocks.firstWhere(
        (b) =>
            (b['block_id'] == blockId) ||
            (b['_id'] == blockId) ||
            (b['block_id']?.toString() == blockId.toString()),
        orElse: () => {},
      );
      if (match.isNotEmpty) blockName = match['block_name'] ?? '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        // ✅ UPDATED: OPEN FULL SCREEN TANK UI
        onTap: () {
          if (deviceId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TankFullScreen(deviceId: deviceId),
              ),
            );
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      deviceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$percent%",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  if (blockName.isNotEmpty) ...[
                    Icon(Icons.business_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        blockName,
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.fingerprint, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      deviceId.isNotEmpty ? deviceId : 'N/A',
                      style: const TextStyle(color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Min: $minThreshold", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      Text("Max: $maxThreshold", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TankList extends StatelessWidget {
  const TankList({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final selectedBlock = deviceProvider.selectedBlockId;

    final List<Map<String, dynamic>> tanks = deviceProvider.devices
        .where((d) =>
            (d['device_type']?.toString().toLowerCase() == 'tank'))
        .where((d) => selectedBlock == null || selectedBlock == "" ? true : d['block_id'] == selectedBlock)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    if (tanks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text("No tanks found for selected block.")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tanks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return TankCard(device: tanks[index]);
      },
    );
  }
}
