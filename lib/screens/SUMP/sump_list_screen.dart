// lib/screens/SUMP/sump_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';
import 'sump_full_screen.dart';

class SumpListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> sumps;
  final String? blockName;

  const SumpListScreen({super.key, required this.sumps, this.blockName});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    
    final updatedSumps = sumps.map((sump) {
      return deviceProvider.devices.firstWhere(
        (d) => d['device_id'] == sump['device_id'],
        orElse: () => sump,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(blockName != null ? "Sumps - $blockName" : "Sumps"),
        backgroundColor: Colors.teal,
      ),
      body: updatedSumps.isEmpty
          ? const Center(child: Text("No sumps available in this block"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: updatedSumps.length,
              itemBuilder: (context, index) {
                final sump = updatedSumps[index];
                final String sumpName = sump['device_name'] ?? "Sump";
                final int currentLevel = int.tryParse(sump['status'].toString()) ?? 0;
                final int minThreshold = int.tryParse(sump["min_threshold"]?.toString() ?? "0") ?? 0;
                final int maxThreshold = int.tryParse(sump["max_threshold"]?.toString() ?? "100") ?? 100;

                Color sumpColor = Colors.teal;
                if (currentLevel <= minThreshold) {
                  sumpColor = Colors.red;
                } else if (currentLevel >= maxThreshold) {
                  sumpColor = Colors.orange;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sumpName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SumpFullScreen(deviceId: sump['device_id'].toString()),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade300),
                              ),
                              FractionallySizedBox(
                                widthFactor: (currentLevel / 100).clamp(0.0, 1.0),
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: sumpColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Min: $minThreshold%"),
                            Text("Current: $currentLevel%"),
                            Text("Max: $maxThreshold%"),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
