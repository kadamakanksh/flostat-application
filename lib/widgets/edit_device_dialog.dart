import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';

class EditDeviceDialog extends StatefulWidget {
  final Map<String, dynamic> device;
  final String orgId;

  const EditDeviceDialog({super.key, required this.device, required this.orgId});

  @override
  State<EditDeviceDialog> createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedBlock;
  String? _selectedParent;
  List<dynamic> _blocks = [];
  List<dynamic> _availableParents = [];
  int _step = 1;
  bool _loading = false;
  bool _loadingBlocks = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device['name'] ?? '');
    _selectedBlock = widget.device['blockId']?.toString();
    _fetchBlocks();
  }

  Future<void> _fetchBlocks() async {
    setState(() => _loadingBlocks = true);

    if (widget.orgId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final url = Uri.parse(DeviceEndpoints.getBlocksOfOrgId);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"orgId": widget.orgId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _blocks = data;
        // Reset block if previously selected block is no longer valid
        if (_selectedBlock != null &&
            !_blocks.any((b) => b['_id'] == _selectedBlock)) {
          _selectedBlock = null;
        }
        _loadingBlocks = false;
      });
    } else {
      debugPrint("❌ Failed to load blocks: ${response.body}");
      setState(() => _loadingBlocks = false);
    }
  }

  Future<void> _loadParentDevices() async {
    if (_selectedBlock == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final url = Uri.parse(DeviceEndpoints.getOrgAllDevice);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"orgId": widget.orgId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> devicesInBlock =
          data.where((d) => d['blockId'] == _selectedBlock).toList();

      String currentType = (widget.device['deviceType'] ?? '').toLowerCase();
      List<dynamic> filtered = [];

      if (currentType == 'valve') {
        filtered = devicesInBlock
            .where((d) => d['deviceType'].toLowerCase() == 'pump')
            .toList();
      } else if (currentType == 'tank') {
        filtered = devicesInBlock
            .where((d) =>
                d['deviceType'].toLowerCase() == 'pump' ||
                d['deviceType'].toLowerCase() == 'valve')
            .toList();
      } else if (currentType == 'pump') {
        filtered = devicesInBlock
            .where((d) => d['deviceType'].toLowerCase() == 'sump')
            .toList();
      }

      setState(() {
        _availableParents = filtered;
        _selectedParent = widget.device['parentId']?.toString();
      });
    } else {
      debugPrint("❌ Failed to load devices: ${response.body}");
    }
  }

  Future<void> _updateDevice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final url = Uri.parse(DeviceEndpoints.updateDevice);
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "deviceId": widget.device['_id'],
        "name": _nameController.text.trim(),
        "blockId": _selectedBlock,
        "parentId": _selectedParent,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Device updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Device"),
      content: SizedBox(
        width: 400,
        child: _step == 1
            ? _loadingBlocks
                ? const Center(child: CircularProgressIndicator())
                : _blocks.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "No blocks available. Please create a block first.",
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              // Reload blocks in case user created one
                              await _fetchBlocks();
                            },
                            child: const Text("Reload Blocks"),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBlock,
                              decoration: const InputDecoration(
                                  labelText: "Select Block"),
                              items: _blocks.map<DropdownMenuItem<String>>((b) {
                                return DropdownMenuItem(
                                  value: b['_id'],
                                  child: Text(b['blockName']),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() {
                                _selectedBlock = val;
                                _selectedParent = null;
                              }),
                              validator: (val) =>
                                  val == null ? "Select block" : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: "Device Name"),
                              validator: (val) => val == null || val.isEmpty
                                  ? "Enter device name"
                                  : null,
                            ),
                          ],
                        ),
                      )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_availableParents.isEmpty)
                    const Text("No parent devices available for this type."),
                  if (_availableParents.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedParent,
                      decoration: const InputDecoration(
                          labelText: "Select Parent Device (optional)"),
                      items: _availableParents.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem(
                          value: p['_id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedParent = val),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_step == 1) {
              if (_formKey.currentState!.validate()) {
                _loadParentDevices();
                setState(() => _step = 2);
              }
            } else {
              _updateDevice();
            }
          },
          child: Text(_step == 1 ? "Next" : _loading ? "Updating..." : "Update Device"),
        ),
        if (_step == 2)
          TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text("Back"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
