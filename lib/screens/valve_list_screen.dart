import 'package:flutter/material.dart';

class ValveListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> valves;
  final String? blockName;

  const ValveListScreen({super.key, required this.valves, this.blockName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blockName != null ? "Valves - $blockName" : "Valves"),
        backgroundColor: Colors.green,
      ),
      body: valves.isEmpty
          ? const Center(child: Text("No valves available in this block"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: valves.length,
              itemBuilder: (context, index) {
                final valve = valves[index];
                final String valveName = valve['device_name'] ?? "Valve";
                final String status = valve['status']?.toString() ?? "unknown";
                final bool isOpen = status.toLowerCase() == "open" || status == "1";

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          isOpen ? Icons.toggle_on : Icons.toggle_off,
                          size: 40,
                          color: isOpen ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valveName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Status: ${isOpen ? 'Open' : 'Closed'}",
                                style: TextStyle(
                                  color: isOpen ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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