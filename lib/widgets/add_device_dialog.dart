// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/device_provider.dart';
// import '../providers/org_provider.dart';

// /// ======================================================
// /// ADD / UPDATE DEVICE DIALOG (No Original Features Removed)
// /// ======================================================
// class AddDeviceDialog extends StatefulWidget {
//   final Map<String, dynamic>? device; // null → create, non-null → update
//   const AddDeviceDialog({super.key, this.device});

//   @override
//   State<AddDeviceDialog> createState() => _AddDeviceDialogState();
// }

// class _AddDeviceDialogState extends State<AddDeviceDialog> {
//   final TextEditingController nameController = TextEditingController();
//   String? selectedType;
//   String? selectedBlock;
//   String? selectedParent;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ Pre-fill data if editing an existing device
//     if (widget.device != null) {
//       nameController.text = widget.device!['device_name'] ?? '';
//       selectedType = widget.device!['device_type'];
//       selectedBlock = widget.device!['block_id']?.toString();
//       selectedParent = widget.device!['parent_device_id']?.toString();
//     }

//     // ✅ Fetch required data after UI build
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final orgId =
//           Provider.of<OrgProvider>(context, listen: false).selectedOrgId;
//       if (orgId != null) {
//         final deviceProvider =
//             Provider.of<DeviceProvider>(context, listen: false);
//         await deviceProvider.fetchBlocks(orgId);
//         await deviceProvider.fetchDevices(orgId);
//         await deviceProvider.fetchParentDevices(orgId);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final deviceProvider = Provider.of<DeviceProvider>(context);
//     final orgProvider = Provider.of<OrgProvider>(context);
//     final orgId = orgProvider.selectedOrgId;

//     if (orgId == null) {
//       return const AlertDialog(
//         content: Text("Please select an organization first ⚠️"),
//       );
//     }

//     final isUpdating = widget.device != null;

//     return Dialog(
//       insetPadding: const EdgeInsets.all(16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // ------------------- Header -------------------
//             Text(
//               isUpdating ? "Update Device" : "Add New Device",
//               style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                     color: Colors.blueAccent,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 20),

//             // ------------------- Device Name -------------------
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(
//                 labelText: "Device Name",
//                 prefixIcon: const Icon(Icons.device_hub_outlined),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // ------------------- Device Type -------------------
//             DropdownButtonFormField<String>(
//               value: selectedType,
//               decoration: InputDecoration(
//                 labelText: "Device Type",
//                 prefixIcon: const Icon(Icons.category_outlined),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               items: ["pump", "tank", "sump", "valve"]
//                   .map((e) =>
//                       DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
//                   .toList(),
//               onChanged: (val) => setState(() => selectedType = val),
//             ),
//             const SizedBox(height: 16),

//             // ------------------- Select Block -------------------
//             DropdownButtonFormField<String>(
//               value: selectedBlock,
//               decoration: InputDecoration(
//                 labelText: "Select Block",
//                 prefixIcon: const Icon(Icons.business_outlined),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               items: deviceProvider.blocks
//                   .map((b) => DropdownMenuItem(
//                         value: b['block_id'].toString(),
//                         child: Text(b['block_name'] ?? "Unnamed Block"),
//                       ))
//                   .toList(),
//               onChanged: (val) => setState(() => selectedBlock = val),
//             ),
//             const SizedBox(height: 16),

//             // ------------------- Parent Device -------------------
//             DropdownButtonFormField<String>(
//               value: selectedParent,
//               decoration: InputDecoration(
//                 labelText: "Parent Device (optional)",
//                 prefixIcon: const Icon(Icons.link_outlined),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               items: deviceProvider.devices
//                   .map((d) => DropdownMenuItem(
//                         value: d['device_id'].toString(),
//                         child: Text(d['device_name'] ?? "Unnamed Device"),
//                       ))
//                   .toList(),
//               onChanged: (val) => setState(() => selectedParent = val),
//             ),
//             const SizedBox(height: 24),

//             // ------------------- Buttons -------------------
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.grey[600],
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 10),
//                   ),
//                   icon: Icon(
//                       isUpdating ? Icons.save_as_outlined : Icons.add_circle),
//                   label: Text(isUpdating ? "Update" : "Create"),
//                   onPressed: () async {
//                     if (nameController.text.isEmpty ||
//                         selectedType == null ||
//                         selectedBlock == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text("Please fill all required fields")),
//                       );
//                       return;
//                     }

//                     if (isUpdating) {
//                       // ✅ Corrected parameter order and used named deviceType param
//                       await deviceProvider.updateDevice(
//                         orgId,
//                         widget.device!['device_id'].toString(),
//                         nameController.text,
//                         selectedBlock!, // blockId
//                         selectedParent, // parentDeviceId
//                         deviceType: selectedType!, // deviceType as named param
//                       );
//                     } else {
//                       await deviceProvider.createDevice(
//                         orgId,
//                         nameController.text,
//                         selectedType!,
//                         selectedBlock!,
//                         selectedParent,
//                       );
//                     }

//                     if (context.mounted) Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// lib/widgets/add_device_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/org_provider.dart';

/// Add / Update Device Dialog
/// - Create mode: ONLY choose device type (auto-generate name + pick block automatically)
/// - Edit mode: show non-editable device type, editable name, block selector, parent selector (filtered)
class AddDeviceDialog extends StatefulWidget {
  final Map<String, dynamic>? device; // null => create, non-null => edit
  const AddDeviceDialog({super.key, this.device});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController nameController = TextEditingController();
  String? selectedType;
  String? selectedBlock;
  String? selectedParent;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // If editing, prefill fields
    if (widget.device != null) {
      nameController.text = widget.device!['device_name'] ?? '';
      selectedType = widget.device!['device_type']?.toString();
      selectedBlock = widget.device!['block_id']?.toString();
      selectedParent = widget.device!['parent_device_id']?.toString();
    }

    // Fetch blocks/devices/parents after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final orgId = Provider.of<OrgProvider>(context, listen: false).selectedOrgId;
      if (orgId != null) {
        final dp = Provider.of<DeviceProvider>(context, listen: false);
        await dp.fetchBlocks(orgId);
        await dp.fetchDevices(orgId);
        await dp.fetchParentDevices(orgId);
        // ensure selectedBlock exists if none selected
        if (widget.device == null && dp.selectedBlockId != null && selectedBlock == null) {
          setState(() => selectedBlock = dp.selectedBlockId);
        } else if (widget.device == null && selectedBlock == null && dp.blocks.isNotEmpty) {
          setState(() => selectedBlock = dp.blocks.first['block_id']?.toString());
        }
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // Parent filter logic described by you:
  // sump  -> no parent (hide)
  // pump  -> only sump devices
  // tank  -> pump + valve devices
  // valve -> only pump devices
  List<Map<String, dynamic>> _filteredParents(DeviceProvider provider) {
    final type = (selectedType ?? '').toLowerCase();
    if (type == 'sump') return [];
    final blockIdFilter = selectedBlock;
    final all = provider.devices;
    var candidates = all.where((d) => blockIdFilter == null || d['block_id']?.toString() == blockIdFilter).toList();

    if (type == 'pump') {
      candidates = candidates.where((d) => (d['device_type'] ?? '').toString().toLowerCase() == 'sump').toList();
    } else if (type == 'tank') {
      candidates = candidates.where((d) {
        final t = (d['device_type'] ?? '').toString().toLowerCase();
        return t == 'pump' || t == 'valve';
      }).toList();
    } else if (type == 'valve') {
      candidates = candidates.where((d) => (d['device_type'] ?? '').toString().toLowerCase() == 'pump').toList();
    } else {
      candidates = [];
    }
    return List<Map<String, dynamic>>.from(candidates);
  }

  Future<void> _handleCreate(DeviceProvider provider, String orgId) async {
    setState(() => _loading = true);

    // choose block: priority -> provider.selectedBlockId -> first block in list
    String? blockId = provider.selectedBlockId ?? (provider.blocks.isNotEmpty ? provider.blocks.first['block_id']?.toString() : null);

    if (blockId == null || blockId.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create a Block first (Add Block)")),
      );
      return;
    }

    // auto-generate device name: TYPE_timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final genName = "${selectedType!.toUpperCase()}_$timestamp";

    try {
      await provider.createDevice(orgId, genName, selectedType!, blockId, null);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device created ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create device: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleUpdate(DeviceProvider provider, String orgId) async {
    setState(() => _loading = true);
    try {
      await provider.updateDevice(
        orgId,
        widget.device!['device_id'].toString(),
        nameController.text.trim(),
        selectedBlock ?? widget.device!['block_id'].toString(),
        selectedParent,
        deviceType: selectedType, // keep existing type on backend too
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device updated ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update device: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final orgId = Provider.of<OrgProvider>(context).selectedOrgId;
    final isUpdating = widget.device != null;

    if (orgId == null) {
      return const AlertDialog(content: Text("Please select an organization first ⚠️"));
    }

    // Build parent options based on selectedType & selectedBlock
    final parentOptions = _filteredParents(provider);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isUpdating ? "Update Device" : "Add New Device",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ---------- CREATE MODE: only device type ----------
            if (!isUpdating) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: "Device Type"),
                items: ["pump", "tank", "sump", "valve"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() {
                  selectedType = val;
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                "Device will be created in the currently selected Block (or first available block). If no block exists, you'll be asked to create one.",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 18),
            ],

            // ---------- EDIT MODE: show details (type non-editable) ----------
            if (isUpdating) ...[
              // Device Type (disabled)
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: "Device Type (locked)"),
                items: ["pump", "tank", "sump", "valve"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: null,
              ),
              const SizedBox(height: 12),

              // Select Block (if no blocks -> show message & create prompt)
              provider.blocks.isEmpty
                  ? Column(
                      children: [
                        const Text("No blocks available. Create a block first.", style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // user should open Device Management -> Add Block
                          },
                          child: const Text("Close"),
                        )
                      ],
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: selectedBlock,
                      decoration: const InputDecoration(labelText: "Select Block"),
                      items: provider.blocks
                          .map((b) => DropdownMenuItem(
                                value: b['block_id']?.toString(),
                                child: Text(b['block_name'] ?? "Unnamed Block"),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        selectedBlock = val;
                        // clear parent selection when block changes
                        selectedParent = null;
                      }),
                    ),
              const SizedBox(height: 12),

              // Device Name editable
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Device Name"),
              ),
              const SizedBox(height: 12),

              // Parent Device: hidden for sump, else show filtered options
              if ((selectedType ?? widget.device!['device_type']).toString().toLowerCase() != 'sump') ...[
                parentOptions.isEmpty
                    ? const Text("No valid parent devices available for this type.", style: TextStyle(fontSize: 13))
                    : DropdownButtonFormField<String>(
                        initialValue: selectedParent,
                        decoration: const InputDecoration(labelText: "Parent Device (optional)"),
                        items: parentOptions
                            .map((d) => DropdownMenuItem(
                                  value: d['device_id']?.toString(),
                                  child: Text(d['device_name'] ?? "Unnamed Device"),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedParent = val),
                      ),
                const SizedBox(height: 12),
              ],
            ],

            // ---------- ACTIONS ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!isUpdating) {
                            // Create flow: only device type selected
                            if (selectedType == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select device type")),
                              );
                              return;
                            }
                            await _handleCreate(provider, orgId);
                          } else {
                            // Update flow: validation
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Device name cannot be empty")),
                              );
                              return;
                            }
                            if (selectedBlock == null || selectedBlock!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select a block")),
                              );
                              return;
                            }
                            await _handleUpdate(provider, orgId);
                          }
                        },
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isUpdating ? "Update" : "Create"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



