import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/org_provider.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId =
          Provider.of<OrgProvider>(context, listen: false).selectedOrgId;
      if (orgId != null) {
        final deviceProvider =
            Provider.of<DeviceProvider>(context, listen: false);
        deviceProvider.fetchDevices(orgId);
        deviceProvider.fetchBlocks(orgId);
        deviceProvider.fetchParentDevices(orgId);
        deviceProvider.fetchBlockModes(orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final orgProvider = Provider.of<OrgProvider>(context);
    final orgId = orgProvider.selectedOrgId;

    if (orgId == null) {
      return const Scaffold(
        body: Center(child: Text("⚠️ Please select an organization first.")),
      );
    }

    final blocks = deviceProvider.blocks;
    final selectedBlock = deviceProvider.selectedBlockId;

    return Scaffold(
      appBar: AppBar(title: const Text("Device Management")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: blocks.isEmpty
                      ? const Text("No blocks found. Please create a block.")
                      : DropdownButtonFormField<String>(
                          value: selectedBlock == "" ? null : selectedBlock,
                          decoration:
                              const InputDecoration(labelText: "Selected Block"),
                          isExpanded: true,
                          items: blocks
                              .map((b) => DropdownMenuItem(
                                    value: b['block_id'].toString(),
                                    child: Text(b['block_name'] ?? "Unnamed Block"),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            deviceProvider.selectBlock(val ?? "");
                            if (val != null && val.isNotEmpty) {
                              deviceProvider.fetchParentDevices(orgId);
                            }
                          },
                        ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      _showCreateDeviceDialog(context, deviceProvider, orgId),
                  label: const Text("Add Device"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: () =>
                      _showCreateBlockDialog(context, deviceProvider, orgId),
                  label: const Text("Add Block"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: deviceProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final devices = deviceProvider.devices;

                        if (devices.isEmpty) {
                          return const Center(child: Text("No devices found"));
                        }

                        if (isWide) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 18,
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent),
                              columns: const [
                                DataColumn(label: Text("Device Name")),
                                DataColumn(label: Text("Device ID")),
                                DataColumn(label: Text("Device Type")),
                                DataColumn(label: Text("Created By")),
                                DataColumn(label: Text("Block ID")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Options")),
                              ],
                              rows: devices.map((device) {
                                return DataRow(cells: [
                                  DataCell(Text(device['device_name'] ?? "")),
                                  DataCell(Text(device['device_id']?.toString() ?? "N/A")),
                                  DataCell(Text(device['device_type'] ?? "")),
                                  DataCell(Text(device['created_by'] ?? "N/A")),
                                  DataCell(Text(device['block_id'] ?? "N/A")),
                                  DataCell(Text(device['status'] ?? "N/A")),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showEditDeviceDialog(
                                            context,
                                            deviceProvider,
                                            orgId,
                                            device,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Delete Device"),
                                              content: const Text("Are you sure you want to delete this device?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;

                                          try {
                                            await deviceProvider.deleteDevice(
                                                orgId,
                                                device['device_id'].toString());
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Device deleted ✅")),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Failed to delete device: $e")),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(device['device_name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("Device ID: ${device['device_id'] ?? 'N/A'}"),
                                    Text("Type: ${device['device_type'] ?? 'N/A'}"),
                                    Text("Created By: ${device['created_by'] ?? 'N/A'}"),
                                    Text("Block: ${device['block_id'] ?? 'N/A'}"),
                                    Text("Status: ${device['status'] ?? 'N/A'}"),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.edit, size: 18),
                                          label: const Text("Edit"),
                                          onPressed: () {
                                            _showEditDeviceDialog(
                                              context,
                                              deviceProvider,
                                              orgId,
                                              device,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text("Delete"),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text("Delete Device"),
                                                content: const Text("Are you sure you want to delete this device?"),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                                ],
                                              ),
                                            );
                                            if (confirm != true) return;

                                            try {
                                              await deviceProvider.deleteDevice(
                                                  orgId,
                                                  device['device_id'].toString());
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Device deleted ✅")),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Failed to delete: $e")),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBlockDialog(
      BuildContext context, DeviceProvider provider, String orgId) {
    final TextEditingController blockController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Block"),
        content: TextField(
          controller: blockController,
          decoration: const InputDecoration(labelText: "Block Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (blockController.text.isNotEmpty) {
                await provider.createBlock(orgId, blockController.text);
                await provider.fetchBlocks(orgId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showCreateDeviceDialog(
      BuildContext context, DeviceProvider provider, String orgId) {
    String? selectedType;

    final currentBlock = provider.selectedBlockId;
    if (currentBlock == null || currentBlock.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Select Block First"),
          content: const Text("Please select a block from the top dropdown before creating a device."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Create Device (only type)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Device will be created in the selected block."),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Device Type"),
                items: ["pump", "tank", "sump", "valve"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a device type")),
                  );
                  return;
                }

                final deviceName = selectedType!;
                await provider.createDevice(orgId, deviceName, selectedType!, currentBlock, null);
                await provider.fetchDevices(orgId);

                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Device of type $selectedType created")),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDeviceDialog(BuildContext context, DeviceProvider provider,
      String orgId, Map<String, dynamic> device) {
    final TextEditingController nameController =
        TextEditingController(text: device['device_name'] ?? "");
    String? selectedBlock = device['block_id']?.toString();
    String? selectedParent = device['parent_device_id']?.toString();
    final String deviceType = (device['device_type'] ?? '').toString().toLowerCase();

    showDialog(
      context: context,
      builder: (_) => FutureBuilder(
        future: Future.wait([
          provider.fetchBlocks(orgId),
          provider.fetchDevices(orgId),
          provider.fetchParentDevices(orgId),
        ]),
        builder: (context, snapshot) {
          return StatefulBuilder(
            builder: (context, setState) {
              final allDevices = provider.devices;
              List<Map<String, dynamic>> parentOptions = [];

              if (deviceType == 'sump') {
                parentOptions = [];
              } else if (deviceType == 'pump') {
                parentOptions = allDevices
                    .where((d) => 
                      (d['device_type'] ?? '').toString().toLowerCase() == 'sump' &&
                      d['block_id']?.toString() == selectedBlock)
                    .cast<Map<String, dynamic>>()
                    .toList();
              } else if (deviceType == 'tank') {
                parentOptions = allDevices
                    .where((d) {
                      final t = (d['device_type'] ?? '').toString().toLowerCase();
                      return (t == 'valve' || t == 'pump') &&
                             d['block_id']?.toString() == selectedBlock;
                    })
                    .cast<Map<String, dynamic>>()
                    .toList();
              } else if (deviceType == 'valve') {
                parentOptions = allDevices
                    .where((d) => 
                      (d['device_type'] ?? '').toString().toLowerCase() == 'pump' &&
                      d['block_id']?.toString() == selectedBlock)
                    .cast<Map<String, dynamic>>()
                    .toList();
              }

              return AlertDialog(
                title: const Text("Edit Device"),
                content: snapshot.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: deviceType.toUpperCase(),
                              readOnly: true,
                              decoration: const InputDecoration(labelText: "Device Type"),
                            ),
                            const SizedBox(height: 12),

                            provider.blocks.isEmpty
                                ? const Text("No blocks available. Create a block first.")
                                : DropdownButtonFormField<String>(
                                    decoration:
                                        const InputDecoration(labelText: "Select Block"),
                                    value: selectedBlock,
                                    items: provider.blocks
                                        .map((b) => DropdownMenuItem(
                                              value: b['block_id'].toString(),
                                              child: Text(b['block_name'] ?? ""),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedBlock = val;
                                        selectedParent = null;
                                      });
                                    },
                                  ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: nameController,
                              decoration:
                                  const InputDecoration(labelText: "Device Name"),
                            ),
                            const SizedBox(height: 12),

                            if (deviceType != 'sump') ...[
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                decoration:
                                    const InputDecoration(labelText: "Parent Device (optional)"),
                                value: selectedParent,
                                items: parentOptions
                                    .where((d) => d['device_id'].toString() != device['device_id'].toString())
                                    .map((d) => DropdownMenuItem(
                                          value: d['device_id'].toString(),
                                          child: Text(d['device_name'] ?? "Unnamed Device"),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(() => selectedParent = val),
                              ),
                            ],
                          ],
                        ),
                      ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedBlock == null || "$selectedBlock".trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a block")),
                        );
                        return;
                      }

                      await provider.updateDevice(
                        orgId,
                        device['device_id'].toString(),
                        nameController.text,
                        selectedBlock!,
                        selectedParent,
                      );
                      if (context.mounted) Navigator.pop(context);
                      await provider.fetchDevices(orgId);
                    },
                    child: const Text("Update"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
