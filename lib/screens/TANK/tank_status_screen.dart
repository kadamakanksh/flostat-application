import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';

class TankStatusScreen extends StatelessWidget {
  const TankStatusScreen({super.key});

  Color getColor(int value) {
    if (value < 20) return Colors.red;
    if (value < 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final tanks = deviceProvider.devices
        .where((d) => d['device_type'] == 'tank')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tank Status"),
        backgroundColor: Colors.blue,
      ),

      body: tanks.isEmpty
          ? const Center(child: Text("No tanks found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tanks.length,
              itemBuilder: (context, index) {
                final tank = tanks[index];
                final name = tank['device_name'] ?? "Unnamed Tank";
                final level = tank['current_level'] ?? 0;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // ✅ Horizontal Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: level / 100,
                            minHeight: 15,
                            color: getColor(level),
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ✅ Percentage
                        Text(
                          "$level%",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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
