import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';
import '/providers/org_provider.dart';
import 'valve_full_screen.dart';

class ValveListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> valves;
  final String? blockName;

  const ValveListScreen({super.key, required this.valves, this.blockName});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        // Map original valves with latest deviceProvider status
        final updatedValves = valves.map((valve) {
          return deviceProvider.devices.firstWhere(
            (d) => d['device_id'].toString() == valve['device_id'].toString(),
            orElse: () => valve,
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(blockName != null ? "Valves - $blockName" : "Valves"),
            backgroundColor: Colors.purple,
          ),
          body: updatedValves.isEmpty
              ? const Center(child: Text("No valves available in this block"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: updatedValves.length,
                  itemBuilder: (context, index) {
                    final valve = updatedValves[index];
                    final String valveName = valve['device_name'] ?? "Valve";
                    final String status =
                        valve['status']?.toString().toUpperCase() ?? 'CLOSE';
                    final bool isOpen = status == 'OPEN';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ValveFullScreen(
                                  deviceId: valve['device_id'].toString()),
                            ),
                          );
                          // Refresh devices when returning from valve detail screen
                          final orgProvider = Provider.of<OrgProvider>(context, listen: false);
                          if (orgProvider.selectedOrgId != null) {
                            await deviceProvider.fetchDevices(orgProvider.selectedOrgId!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isOpen ? Icons.toggle_on : Icons.toggle_off,
                                  size: 40,
                                  color: isOpen ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(valveName,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Status: ${isOpen ? 'OPEN' : 'CLOSE'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isOpen ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isOpen ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isOpen ? "OPEN" : "CLOSE",
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
      },
    );
  }
}
