import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
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

        // Normalize pending status to proper defaults
        _normalizeDeviceStatus();

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

  // -------------------- NORMALIZE DEVICE STATUS --------------------
  Map<String, String> _localStatusCache = {};
  
  void _normalizeDeviceStatus() {
    for (var device in _devices) {
      final deviceId = device['device_id']?.toString();
      final status = device['status']?.toString().toLowerCase();
      
      // Check if we have a cached local status for this device
      if (deviceId != null && _localStatusCache.containsKey(deviceId)) {
        device['status'] = _localStatusCache[deviceId];
        continue;
      }
      
      if (status == null || status == 'pending' || status.isEmpty) {
        final deviceType = device['device_type']?.toString().toLowerCase() ?? '';
        device['status'] = {
          'pump': 'OFF',
          'valve': 'CLOSE',
          'tank': 'NORMAL',
          'sump': 'NORMAL',
        }[deviceType] ?? 'NORMAL';
        
        if (deviceType == 'tank' || deviceType == 'sump') {
          device['current_level'] = device['current_level'] ?? 0;
        }
      }
    }
  }

  // ==========================================================
  // -------------------- TOGGLE PUMP -------------------------
  // ==========================================================
  Future<bool> togglePump(String deviceId, bool turnOn) async {
    if (authProvider.token == null) return false;
    final newStatus = turnOn ? 'ON' : 'OFF';
    final success = await updateDeviceStatusOnServer(deviceId, 'pump', newStatus);
    if (success) {
      _localStatusCache[deviceId] = newStatus;
    }
    return success;
  }

  // ==========================================================
  // -------------------- TOGGLE VALVE ------------------------
  // ==========================================================
  Future<bool> toggleValve(String deviceId, String currentStatus) async {
    if (authProvider.token == null) return false;
    
    // Normalize current status and determine new status
    final normalizedCurrentStatus = currentStatus.trim().toUpperCase();
    final newStatus = normalizedCurrentStatus == 'OPEN' ? 'CLOSE' : 'OPEN';
    
    debugPrint("🔄 Toggling valve $deviceId: $normalizedCurrentStatus → $newStatus");
    
    final success = await updateDeviceStatusOnServer(deviceId, 'valve', newStatus);
    
    if (success) {
      // Cache the new status locally
      _localStatusCache[deviceId] = newStatus;
      
      // Update connected devices status
      _updateConnectedDevicesStatus(deviceId, newStatus);
      
      debugPrint("✅ Valve $deviceId toggled successfully to $newStatus");
    } else {
      debugPrint("❌ Failed to toggle valve $deviceId");
    }
    
    return success;
  }
  
  // Update connected devices when valve status changes
  void _updateConnectedDevicesStatus(String valveId, String valveStatus) {
    debugPrint("🔗 Updating connected devices for valve: $valveId, status: $valveStatus");
    
    // Find connected devices (children of this valve)
    final connectedDevices = _devices.where((d) => d['parent_id']?.toString() == valveId).toList();
    
    debugPrint("🔗 Found ${connectedDevices.length} connected devices");
    
    for (var device in connectedDevices) {
      final deviceId = device['device_id']?.toString();
      final deviceType = device['device_type']?.toString().toLowerCase();
      final deviceName = device['device_name'] ?? 'Unknown';
      
      debugPrint("🔗 Processing: $deviceName (type: $deviceType, id: $deviceId)");
      
      if (deviceId != null) {
        if (valveStatus == 'OPEN') {
          // Valve opened - turn connected devices ON
          if (deviceType == 'pump') {
            _localStatusCache[deviceId] = 'ON';
            device['status'] = 'ON';
            debugPrint("✅ Auto-turned ON: $deviceName (pump)");
          } else if (deviceType == 'tank' || deviceType == 'sump') {
            _localStatusCache[deviceId] = 'FILLING';
            device['status'] = 'FILLING';
            debugPrint("✅ Auto-status: $deviceName (FILLING)");
          }
        } else {
          // Valve closed - turn connected devices OFF
          if (deviceType == 'pump') {
            _localStatusCache[deviceId] = 'OFF';
            device['status'] = 'OFF';
            debugPrint("✅ Auto-turned OFF: $deviceName (pump)");
          } else if (deviceType == 'tank' || deviceType == 'sump') {
            _localStatusCache[deviceId] = 'NORMAL';
            device['status'] = 'NORMAL';
            debugPrint("✅ Auto-status: $deviceName (NORMAL)");
          }
        }
      }
    }
    
    debugPrint("🔗 Status cache after update: $_localStatusCache");
    notifyListeners();
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
