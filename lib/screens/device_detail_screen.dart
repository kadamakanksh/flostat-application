import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final String deviceName = device['device_name'] ?? "Unnamed Device";
    final String deviceType = device['device_type'] ?? "Unknown";
    final String deviceId = device['device_id'] ?? "";
    final String status = device['status'] ?? "off";
    final String? token = authProvider.token;

    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Device Type: $deviceType", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(
              "Current Status: ${status.toUpperCase()}",
              style: TextStyle(color: status == "on" ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (deviceType.toLowerCase() == "pump")
              ElevatedButton.icon(
                icon: Icon(status == "on" ? Icons.power_off : Icons.power),
                label: Text(status == "on" ? "Turn OFF" : "Turn ON"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == "on" ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: token == null
                    ? null
                    : () async {
                        final newStatus = status != "on";
                        await deviceProvider.togglePump(deviceId, newStatus);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Pump turned ${newStatus ? 'ON' : 'OFF'}")),
                        );
                      },
              ),
          ],
        ),
      ),
    );
  }
}
