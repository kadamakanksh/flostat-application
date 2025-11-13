// lib/screens/PUMP/pump_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';
import 'pump_full_screen.dart';

class PumpListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> pumps;
  final String? blockName;

  const PumpListScreen({super.key, required this.pumps, this.blockName});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    
    final updatedPumps = pumps.map((pump) {
      return deviceProvider.devices.firstWhere(
        (d) => d['device_id'] == pump['device_id'],
        orElse: () => pump,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(blockName != null ? "Pumps - $blockName" : "Pumps"),
        backgroundColor: Colors.blue,
      ),
      body: updatedPumps.isEmpty
          ? const Center(child: Text("No pumps available in this block"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: updatedPumps.length,
              itemBuilder: (context, index) {
                final pump = updatedPumps[index];
                final String pumpName = pump['device_name'] ?? "Pump";
                final String status = pump['status']?.toString().toUpperCase() ?? 'OFF';
                final bool isOn = status == 'ON';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PumpFullScreen(deviceId: pump['device_id'].toString()),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOn ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.invert_colors,
                              size: 40,
                              color: isOn ? Colors.blue : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pumpName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  "Status: ${isOn ? 'ON' : 'OFF'}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isOn ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isOn ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOn ? "ON" : "OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
