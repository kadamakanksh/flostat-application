
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/org_provider.dart';
import '../widgets/add_device_dialog.dart';

class DeviceCard extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late TextEditingController thresholdMinController;
  late TextEditingController thresholdMaxController;
  late TextEditingController currentLevelController;

  @override
  void initState() {
    super.initState();
    final device = widget.device;
    thresholdMinController =
        TextEditingController(text: device['min_threshold']?.toString() ?? "0");
    thresholdMaxController =
        TextEditingController(text: device['max_threshold']?.toString() ?? "100");
    currentLevelController =
        TextEditingController(text: device['current_level']?.toString() ?? "0");
  }

  @override
  void dispose() {
    thresholdMinController.dispose();
    thresholdMaxController.dispose();
    currentLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    final device = widget.device;
    final orgId = orgProvider.selectedOrgId ?? "";
    final blockId = device['block_id']?.toString() ?? "";
    final deviceId = device['device_id']?.toString() ?? "";
    final deviceName = device['device_name']?.toString() ?? "Unknown";
    final deviceType = device['device_type']?.toString() ?? "N/A";
    final status = device['status']?.toString() ?? "off";
    final createdBy = device['created_by']?.toString() ?? "N/A";
    final valveThresholds = deviceProvider.getValveThreshold(blockId);

    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 420;

    return Card(
      elevation: 5,
      color: Colors.white,
      margin: EdgeInsets.symmetric(
        vertical: width * 0.02,
        horizontal: width * 0.03,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Row (Device Name + Menu) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Added Device ID & Created By below name
                      Text("Device ID: $deviceId",
                          style: TextStyle(fontSize: width * 0.028, color: Colors.black54)),
                      Text("Created By: $createdBy",
                          style: TextStyle(fontSize: width * 0.028, color: Colors.black54)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // show AddDeviceDialog for edit (pre-filled)
                      showDialog(
                        context: context,
                        builder: (_) => AddDeviceDialog(device: device),
                      );
                    } else if (value == 'delete') {
                      await deviceProvider.deleteDevice(orgId, deviceId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Device deleted ✅")),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --- Device Info ---
            Text("Type: $deviceType"),
            if (device['parent_device_name'] != null)
              Text("Parent: ${device['parent_device_name']}"),
            const SizedBox(height: 10),

            // --- Pump Section ---
            if (deviceType.toLowerCase() == 'pump')
              Row(
                children: [
                  Text("Status: $status"),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await deviceProvider.togglePump(
                        deviceId,
                        status != 'on',
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? "Pump toggled successfully ✅"
                              : "Failed to toggle pump ❌"),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status == 'on' ? Colors.redAccent : Colors.green,
                    ),
                    child: Text(
                      status == 'on' ? "Turn OFF" : "Turn ON",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

            // --- Tank Section ---
            if (deviceType.toLowerCase() == 'tank') ...[
              const SizedBox(height: 10),
              Text("Current Level: ${device['current_level'] ?? 0}"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: thresholdMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Min Threshold"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: thresholdMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Max Threshold"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 80,
                      maxWidth: isSmall ? 120 : 140,
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await deviceProvider.updateDevice(
                          orgId,
                          deviceId,
                          deviceName,
                          blockId,
                          device['parent_device_id']?.toString(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tank updated successfully ✅")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Update"),
                    ),
                  ),
                ],
              ),
            ],

            // --- Valve Section ---
            if (deviceType.toLowerCase() == 'valve') ...[
              const SizedBox(height: 10),
              Text("Current: ${device['current_level'] ?? 0}%"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Open", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text("Close", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: valveThresholds['min']?.toString() ?? "0",
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Min Threshold"),
                      onChanged: (val) {
                        final minVal = int.tryParse(val) ?? 0;
                        deviceProvider.setValveThreshold(
                          blockId,
                          minVal,
                          valveThresholds['max'] ?? 100,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: valveThresholds['max']?.toString() ?? "100",
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Max Threshold"),
                      onChanged: (val) {
                        final maxVal = int.tryParse(val) ?? 100;
                        deviceProvider.setValveThreshold(
                          blockId,
                          valveThresholds['min'] ?? 0,
                          maxVal,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],

            // --- Sump Section ---
            if (deviceType.toLowerCase() == 'sump') ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // make the text label and field flexible to avoid overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Current Level: ${device['current_level'] ?? 0}"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: currentLevelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Set Level"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 80,
                      maxWidth: isSmall ? 110 : 140,
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await deviceProvider.updateDevice(
                          orgId,
                          deviceId,
                          deviceName,
                          blockId,
                          device['parent_device_id']?.toString(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Sump updated successfully ✅")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      child: const Text("Update"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}



