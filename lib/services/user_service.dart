import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';

class UserService {
  // 🔐 Get token from local storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 🧾 Common headers for all requests
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ 1. Get all users in an organization
  static Future<List<dynamic>> getAllUsersForOrg(String orgId) async {
    final headers = await _headers();
    final url = Uri.parse(UserEndpoints.getAllOrgsOfUser.replaceAll(':org_id', orgId));

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception("Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching users: $e");
    }
  }

  // 👤 2. Invite new user to organization
  static Future<bool> inviteUser(String orgId, String email, String role) async {
    final headers = await _headers();
    final url = Uri.parse(UserEndpoints.inviteUser);

    final body = jsonEncode({
      "org_id": orgId,
      "email": email,
      "role": role,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to invite user: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error inviting user: $e");
    }
  }

  // ✏️ 3. Update user access / role
  static Future<bool> updateUserAccess(String userId, String newRole) async {
    final headers = await _headers();
    final url = Uri.parse(UserEndpoints.updateAccess);

    final body = jsonEncode({
      "user_id": userId,
      "role": newRole,
    });

    try {
      final response = await http.put(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to update access: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating user access: $e");
    }
  }

  // ❌ 4. Remove user from org
  static Future<bool> removeUser(String userId, String orgId) async {
    final headers = await _headers();
    final url = Uri.parse(UserEndpoints.removeUser);

    final body = jsonEncode({
      "user_id": userId,
      "org_id": orgId,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to remove user: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error removing user: $e");
    }
  }

  // 📨 5. Accept user invite
  static Future<bool> acceptInvite(String inviteId) async {
    final headers = await _headers();
    final url = Uri.parse(UserEndpoints.acceptInvite);

    final body = jsonEncode({"invite_id": inviteId});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to accept invite: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error accepting invite: $e");
    }
  }
}
