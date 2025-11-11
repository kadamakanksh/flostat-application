// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class AwsMqttService {
//   final String baseUrl;

//   AwsMqttService({required this.baseUrl});

//   // 1. Get MQTT topics for your org/device
//   Future<List<String>> getTopics(String orgId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/device/getDeviceWithStatus/$orgId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       // assuming backend returns list of topics
//       return List<String>.from(data['topics'] ?? []);
//     } else {
//       throw Exception('Failed to fetch topics');
//     }
//   }

//   // 2. Get device/block status
//   Future<Map<String, dynamic>> getDeviceStatus(String orgId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/device/getDeviceWithStatus/$orgId'),
//       headers: {'Content-Type': 'application/json'},
//     );
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Failed to fetch device status');
//     }
//   }

//   // 3. Publish command to device/block
//   Future<void> updateDeviceStatus(String deviceId, Map<String, dynamic> payload) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/device/updateDeviceStatus'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'deviceId': deviceId,
//         ...payload,
//       }),
//     );

//     if (response.statusCode != 200) {
//       throw Exception('Failed to update device status');
//     }
//   }
// }
// lib/services/aws_mqtt_service.dart
// lib/services/aws_mqtt_service.dart
// lib/services/aws_mqtt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AwsMqttService {
  final String baseUrl;
  AwsMqttService({required this.baseUrl});

  // ✅ Get blocks by Org ID
  Future<List<Map<String, dynamic>>> getBlocksOfOrg(String orgId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/device/block/getBlocksOfOrgId?orgId=$orgId'),
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      if (jsonData['blocks'] != null) {
        print("✅ Blocks fetched successfully");
        return List<Map<String, dynamic>>.from(jsonData['blocks']);
      } else {
        print("⚠️ No blocks found in response");
        return [];
      }
    } else {
      print("❌ Error fetching blocks: ${res.statusCode} ${res.body}");
      throw Exception('Failed to fetch blocks');
    }
  }

  // ✅ Create block
  Future<Map<String, dynamic>> createBlock(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/device/block/createBlock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      print("✅ Block created successfully");
      return jsonDecode(res.body)['block'];
    } else {
      print("❌ Error creating block: ${res.statusCode} ${res.body}");
      throw Exception('Failed to create block');
    }
  }

  // ✅ Create device under block
  Future<Map<String, dynamic>> createDevice(
      String blockId, String name, String type) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/device/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'blockId': blockId, 'name': name, 'type': type}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      print("✅ Device created successfully");
      return jsonDecode(res.body);
    } else {
      print("❌ Error creating device: ${res.statusCode} ${res.body}");
      throw Exception('Failed to create device');
    }
  }

  // ✅ Update device ON/OFF
  Future<void> updateDeviceStatus(String deviceId, bool status) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/device/updateDeviceStatus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId, 'status': status ? 'ON' : 'OFF'}),
    );

    print(res.statusCode == 200
        ? "✅ Device status updated"
        : "❌ Failed to update device status: ${res.body}");
  }

  // ✅ Publish command to device
  Future<void> publishDeviceCommand({
    required String orgId,
    required String deviceId,
    required String status,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/device/updateDeviceStatus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'orgId': orgId, 'deviceId': deviceId, 'status': status}),
    );

    if (res.statusCode == 200) {
      print("✅ Device command published");
    } else {
      print("❌ Failed to publish device command: ${res.statusCode} ${res.body}");
    }
  }

  // ✅ Get devices under a block
  Future<List<dynamic>> getDevicesOfBlock(String blockId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/device/getDeviceParents?blockId=$blockId'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print("✅ Devices fetched for block: $blockId");
      return data;
    } else {
      print("❌ Error fetching devices: ${res.statusCode} ${res.body}");
      return [];
    }
  }

  // ✅ Logout user
  Future<void> logoutApi() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
    );

    print(res.statusCode == 200
        ? "✅ Logout successful"
        : "❌ Logout failed: ${res.statusCode} ${res.body}");
  }
}
