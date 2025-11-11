// lib/screens/TANK/tank_list_screen.dart

import 'package:flutter/material.dart';
import 'tank_full_screen.dart';

class TankListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tanks;
  final String? blockName;

  const TankListScreen({super.key, required this.tanks, this.blockName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blockName != null ? "Tanks - $blockName" : "Tanks"),
        backgroundColor: Colors.blue,
      ),
      body: tanks.isEmpty
          ? const Center(child: Text("No tanks available in this block"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tanks.length,
              itemBuilder: (context, index) {
                final tank = tanks[index];
                final String tankName = tank['device_name'] ?? "Tank";
                final int currentLevel =
                    int.tryParse(tank['status'].toString()) ?? 0;

                final int minThreshold = tank["min_threshold"] is int
                    ? tank["min_threshold"]
                    : int.tryParse(tank["min_threshold"]?.toString() ?? "0") ?? 0;

                final int maxThreshold = tank["max_threshold"] is int
                    ? tank["max_threshold"]
                    : int.tryParse(tank["max_threshold"]?.toString() ?? "100") ?? 100;

                // Color logic
                Color tankColor = Colors.blue;
                if (currentLevel <= minThreshold) {
                  tankColor = Colors.red;
                } else if (currentLevel >= maxThreshold) {
                  tankColor = Colors.orange;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tankName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // ✅ Make only the progress bar clickable
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TankFullScreen(
                                  deviceId: tank['device_id'].toString(),
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor:
                                    (currentLevel / 100).clamp(0.0, 1.0),
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: tankColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Min: $minThreshold"),
                            Text("Current: $currentLevel%"),
                            Text("Max: $maxThreshold"),
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
