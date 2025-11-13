import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../utils/constant.dart';
import 'auth_provider.dart';

class DeviceProvider with ChangeNotifier {
  final AuthProvider authProvider;
  DeviceProvider({required this.authProvider});

  // ==================== DEVICE DATA ====================
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> get devices => _devices;

  bool _loading = false;
  bool get isLoading => _loading;

  String? selectedOrgId;

  // ==================== BLOCK DATA ====================
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> get blocks => _blocks;

  // ==================== PARENT DEVICES ====================
  List<Map<String, dynamic>> _parentDevices = [];
  List<Map<String, dynamic>> get parentDevices => _parentDevices;

  // ==========================================================
  // -------------------- FETCH DEVICES -----------------------
  // ==========================================================
  Future<void> fetchDevices(String orgId) async {
    selectedOrgId = orgId;
    _loading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.getOrgAllDevice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({'org_id': orgId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _devices = List<Map<String, dynamic>>.from(data['devices'] ?? []);

        // Flatten block_id if it's a nested list
        for (var device in _devices) {
          var blockId = device['block_id'];
          if (blockId is List && blockId.isNotEmpty) {
            while (blockId is List && blockId.isNotEmpty) {
              blockId = blockId[0];
            }
            device['block_id'] = blockId?.toString();
          }
        }

        debugPrint("=== FETCH DEVICES ===");
        debugPrint("Total: ${_devices.length}");
      } else {
        debugPrint("❌ Failed to fetch devices: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error fetching devices: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // -------------------- FETCH BLOCKS ------------------------
  // ==========================================================
  Future<void> fetchBlocks(String orgId) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.getBlocksOfOrgId),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({'org_id': orgId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _blocks = List<Map<String, dynamic>>.from(data['blocks'] ?? []);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch blocks: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error fetching blocks: $e");
    }
  }

  // ==========================================================
  // -------------------- FETCH PARENT DEVICES ----------------
  // ==========================================================
  Future<void> fetchParentDevices(String orgId) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.getDeviceParents),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({'org_id': orgId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _parentDevices =
            List<Map<String, dynamic>>.from(data['devices'] ?? []);
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch parent devices: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error fetching parent devices: $e");
    }
  }

  // ==========================================================
  // -------------------- CREATE BLOCK ------------------------
  // ==========================================================
  Future<void> createBlock(String orgId, String blockName) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.createBlock),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({'org_id': orgId, 'block_name': blockName}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Block created successfully");
        await fetchBlocks(orgId);
      } else {
        debugPrint("❌ Failed to create block: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error creating block: $e");
    }
  }

  // ==========================================================
  // -------------------- CREATE DEVICE -----------------------
  // ==========================================================
  Future<void> createDevice(String orgId, String deviceName, String deviceType,
      String blockId, String? parentDeviceId) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.createDevice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({
          'org_id': orgId,
          'block_id': blockId,
          'device_name': deviceName,
          'device_type': deviceType,
          'parent_device_id': parentDeviceId ?? ''
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Device created successfully");
        await fetchDevices(orgId);
      } else {
        debugPrint("❌ Failed to create device: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error creating device: $e");
    }
  }

  // ==========================================================
  // -------------------- UPDATE DEVICE -----------------------
  // ==========================================================
  Future<void> updateDevice(String orgId, String deviceId, String deviceName,
      String blockId, String? parentDeviceId,
      {String? deviceType}) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.put(
        Uri.parse(DeviceEndpoints.updateDevice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({
          'org_id': orgId,
          'device_id': deviceId,
          'block_id': blockId,
          'device_name': deviceName,
          'device_type': deviceType,
          'parent_device_id': parentDeviceId ?? ''
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Device updated successfully");
        await fetchDevices(orgId);
      } else {
        debugPrint("❌ Failed to update device: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error updating device: $e");
    }
  }

  // ==========================================================
  // -------------------- DELETE DEVICE -----------------------
  // ==========================================================
  Future<void> deleteDevice(String orgId, String deviceId) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.delete(
        Uri.parse(DeviceEndpoints.deleteDevice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({'org_id': orgId, 'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Device deleted successfully");
        await fetchDevices(orgId);
      } else {
        debugPrint("❌ Failed to delete device: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error deleting device: $e");
    }
  }

  // -------------------- UPDATE DEVICE FROM MQTT --------------------
  void updateDeviceFromMqtt(Map<String, dynamic> mqttData) {
    final deviceId = mqttData['device_id'];
    if (deviceId == null) return;

    final index = _devices.indexWhere((d) => d['device_id'] == deviceId);
    if (index != -1) {
      _devices[index] = {..._devices[index], ...mqttData};
    } else {
      _devices.add(mqttData);
    }

    notifyListeners();
  }

  // ==========================================================
  // -------------------- TOGGLE PUMP -------------------------
  // ==========================================================
  Future<bool> togglePump(String deviceId, bool turnOn) async {
    if (authProvider.token == null) return false;
    final newStatus = turnOn ? 'ON' : 'OFF';
    return await updateDeviceStatusOnServer(deviceId, 'pump', newStatus);
  }

  // ==========================================================
  // -------------------- TOGGLE VALVE ------------------------
  // ==========================================================
  Future<bool> toggleValve(String deviceId, String currentStatus) async {
    if (authProvider.token == null) return false;
    final newStatus = currentStatus.toUpperCase() == 'OPEN' ? 'CLOSE' : 'OPEN';
    return await updateDeviceStatusOnServer(deviceId, 'valve', newStatus);
  }

  // ==========================================================
  // -------------------- CHECK TANK THRESHOLDS ---------------
  // ==========================================================
  void checkTankThresholds() {
    for (var device in _devices) {
      if (device['device_type'] == 'tank' &&
          device.containsKey('max_threshold') &&
          device.containsKey('min_threshold') &&
          device.containsKey('current_level')) {
        final current = device['current_level'];
        if (current > device['max_threshold'] ||
            current < device['min_threshold']) {
          debugPrint(
              "⚠️ Tank ${device['device_name']} level out of threshold!");
        }
      }
    }
  }

  // ==========================================================
  // -------------------- UPDATE AUTH -------------------------
  // ==========================================================
  void updateAuthProvider(AuthProvider newAuth) {
    authProvider.token = newAuth.token;
    notifyListeners();
  }

  // ==========================================================
  // -------------------- BLOCK MODES -------------------------
  // ==========================================================
  Map<String, String> _blockModes = {};
  Map<String, String> get blockModes => _blockModes;

  Future<void> fetchBlockModes(String orgId) async {
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(DeviceEndpoints.getBlockMode),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({'org_id': orgId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _blockModes = {};
        if (data['blocks'] != null) {
          for (var block in data['blocks']) {
            _blockModes[block['block_id']] = block['mode'];
          }
        }
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch block modes: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error fetching block modes: $e");
    }
  }

  Future<void> changeBlockMode(String blockId, String mode) async {
    if (authProvider.token == null || selectedOrgId == null) return;

    try {
      final response = await http.put(
        Uri.parse(DeviceEndpoints.changeBlockMode),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({
          'org_id': selectedOrgId,
          'block_id': blockId,
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        _blockModes[blockId] = mode;
        notifyListeners();
        debugPrint("✅ Block mode changed successfully");
      } else {
        debugPrint("❌ Failed to change block mode: ${response.body}");
      }
    } catch (e) {
      debugPrint("🚨 Error changing block mode: $e");
    }
  }

  // ==========================================================
  // -------------------- VALVE THRESHOLDS --------------------
  // ==========================================================
  Map<String, Map<String, int>> blockValveThresholds = {};

  void setValveThreshold(String blockId, int min, int max) {
    blockValveThresholds[blockId] = {'min': min, 'max': max};
    notifyListeners();
  }

  Map<String, int> getValveThreshold(String blockId) {
    return blockValveThresholds[blockId] ?? {'min': 0, 'max': 100};
  }

  // ==========================================================
  // -------------------- SELECT BLOCK ------------------------
  // ==========================================================
  String? selectedBlockId;
  void selectBlock(String blockId) {
    selectedBlockId = blockId;
    notifyListeners();
  }

  // ✅ NEW HELPER METHODS
  Future<void> fetchAllData(String orgId) async {
    await Future.wait([
      fetchDevices(orgId),
      fetchBlocks(orgId),
      fetchParentDevices(orgId),
      fetchBlockModes(orgId),
    ]);
  }

  // ==========================================================
  // -------------------- UPDATE DEVICE STATUS ------------------------
  // ✅ Unified method for pump, valve, tank updates via API only
  // ==========================================================
  Future<bool> updateDeviceStatusOnServer(
      String deviceId, String deviceType, String newStatus) async {
    if (authProvider.token == null || selectedOrgId == null) return false;

    try {
      final response = await http.put(
        Uri.parse(DeviceEndpoints.updateDeviceStatus),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}'
        },
        body: jsonEncode({
          'org_id': selectedOrgId,
          'device_id': deviceId,
          'device_type': deviceType,
          'status': newStatus,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Refresh devices from server
        await fetchDevices(selectedOrgId!);
        debugPrint(
            "✅ Device $deviceId status updated successfully → $newStatus");
        return true;
      } else {
        debugPrint("❌ Failed to update device $deviceId: ${response.body}");
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("🚨 Exception updating device $deviceId: $e");
      debugPrint("🚨 StackTrace: $stackTrace");
      return false;
    }
  }
}
