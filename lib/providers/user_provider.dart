// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../config/api_endpoints.dart';

// class UserProvider with ChangeNotifier {
//   List<dynamic> _users = [];
//   bool _isLoading = false;

//   List<dynamic> get users => _users;
//   bool get isLoading => _isLoading;

//   // -------------------- GET TOKEN --------------------
//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString("auth_token");
//   }

//   // ====================================================
//   // -------------------- FETCH USERS -------------------
//   // ====================================================
//   Future<void> fetchUsers(String orgId) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final token = await _getToken();
//       if (token == null) {
//         debugPrint("⚠️ Token not found");
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }

//       final url = OrgEndpoints.getAllUsersForOrg.replaceFirst(":org_id", orgId);
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         _users = data is List ? data : (data['users'] ?? []);
//         debugPrint("✅ Users fetched successfully (${_users.length})");
//       } else {
//         debugPrint("❌ Failed to fetch users: ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error fetching users: $e");
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   // ====================================================
//   // -------------------- INVITE USER -------------------
//   // ====================================================
//   Future<bool> inviteUser({
//     required String orgId,
//     required String email,
//     required String role,
//   }) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         debugPrint("⚠️ Token not found, cannot invite user.");
//         return false;
//       }

//       final response = await http.post(
//         Uri.parse(UserEndpoints.inviteUser),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           "email": email.trim(),
//           "org_id": orgId.trim(),
//           "role": role.trim(),
//         }),
//       );

//       debugPrint("📩 inviteUser response: ${response.body}");

//       final data = jsonDecode(response.body);
//       if (data['success'] == true) {
//         await fetchUsers(orgId);
//         debugPrint("✅ User invited successfully");
//         return true;
//       } else {
//         debugPrint("❌ Failed to invite user: ${data['message']}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error inviting user: $e");
//       return false;
//     }
//   }


//   // ====================================================
//   // -------------------- ACCEPT INVITE -----------------
//   // ====================================================
//   Future<bool> acceptInvite({
//     required String orgId,
//     required String email,
//   }) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         debugPrint("⚠️ Token not found, cannot accept invite.");
//         return false;
//       }

//       final response = await http.post(
//         Uri.parse(UserEndpoints.acceptInvite),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           "orgId": orgId,
//           "email": email,
//         }),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         debugPrint("✅ Invite accepted successfully");
//         await fetchUsers(orgId);
//         return true;
//       } else {
//         debugPrint("❌ Failed to accept invite: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error accepting invite: $e");
//       return false;
//     }
//   }

//   // ====================================================
//   // -------------------- UPDATE ACCESS -----------------
//   // ====================================================
//   Future<bool> updateAccess({
//     required String orgId,
//     required String email,
//     required String newRole,
//   }) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         debugPrint("⚠️ Token not found, cannot update access.");
//         return false;
//       }

//       final response = await http.put(
//         Uri.parse(UserEndpoints.updateAccess),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           "orgId": orgId,
//           "email": email,
//           "role": newRole,
//         }),
//       );

//       if (response.statusCode == 200) {
//         debugPrint("✅ User access updated successfully");
//         await fetchUsers(orgId);
//         return true;
//       } else {
//         debugPrint("❌ Failed to update access: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error updating access: $e");
//       return false;
//     }
//   }

//   // ====================================================
//   // -------------------- REMOVE USER -------------------
//   // ====================================================
//   Future<bool> removeUser({
//     required String orgId,
//     required String email,
//   }) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         debugPrint("⚠️ Token not found, cannot remove user.");
//         return false;
//       }

//       final response = await http.delete(
//         Uri.parse(UserEndpoints.removeUser),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           "orgId": orgId,
//           "email": email,
//         }),
//       );

//       if (response.statusCode == 200) {
//         _users.removeWhere((user) => user['email'] == email);
//         notifyListeners();
//         debugPrint("✅ User removed successfully");
//         return true;
//       } else {
//         debugPrint("❌ Failed to remove user: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error removing user: $e");
//       return false;
//     }
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';

class UserProvider with ChangeNotifier {
  List<dynamic> _users = [];
  bool _isLoading = false;

  List<dynamic> get users => _users;
  bool get isLoading => _isLoading;

  // -------------------- GET TOKEN --------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // ====================================================
  // -------------------- FETCH USERS -------------------
  // ====================================================
  Future<void> fetchUsers(String orgId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ Token not found");
        _isLoading = false;
        notifyListeners();
        return;
      }

      final url = OrgEndpoints.getAllUsersForOrg.replaceFirst(":org_id", orgId);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _users = data is List ? data : (data['users'] ?? []);
        debugPrint("✅ Users fetched successfully (${_users.length})");
      } else {
        debugPrint("❌ Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching users: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ====================================================
  // -------------------- INVITE USER -------------------
  // ====================================================
  Future<bool> inviteUser({
    required String orgId,
    required String email,
    required String role,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ Token not found, cannot invite user.");
        return false;
      }

      // 🔹 Changed: backend expected `org_id` (snake_case), not `orgId`
      final body = {
        "email": email.trim(),
        "org_id": orgId.trim(), // 🔹 Fixed key name
        "role": role.trim(),
      };

      debugPrint("📤 Inviting user with: $body"); // ✅ Added debug clarity

      final response = await http.post(
        Uri.parse(UserEndpoints.inviteUser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // ✅ Added detailed debug
      debugPrint("📩 inviteUser response (${response.statusCode}): ${response.body}");

      final data = jsonDecode(response.body);

      // ✅ Now checks success + status code
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchUsers(orgId);
        debugPrint("✅ User invited successfully");
        return true;
      } else {
        debugPrint("❌ Failed to invite user: ${data['message'] ?? response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error inviting user: $e");
      return false;
    }
  }

  // ====================================================
  // -------------------- ACCEPT INVITE -----------------
  // ====================================================
  Future<bool> acceptInvite({
    required String orgId,
    required String email,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ Token not found, cannot accept invite.");
        return false;
      }

      // 🔹 Changed: same key convention fix (`org_id` instead of `orgId`)
      final body = {
        "org_id": orgId.trim(), // 🔹 Fixed naming
        "email": email.trim(),
      };

      debugPrint("📤 Accepting invite with: $body"); // ✅ Added debug log

      final response = await http.put(
        Uri.parse(UserEndpoints.acceptInvite),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // ✅ Better visibility of server response
      debugPrint("📩 acceptInvite response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUsers(orgId);
        debugPrint("✅ Invite accepted successfully");
        return true;
      } else {
        debugPrint("❌ Failed to accept invite: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error accepting invite: $e");
      return false;
    }
  }

  // ====================================================
  // -------------------- UPDATE ACCESS -----------------
  // ====================================================
  Future<bool> updateAccess({
    required String orgId,
    required String email,
    required String newRole,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ Token not found, cannot update access.");
        return false;
      }

      // 🔹 Consistent key style
      final body = {
        "org_id": orgId.trim(), // 🔹 Consistent naming
        "email": email.trim(),
        "role": newRole.trim(),
      };

      debugPrint("📤 Updating access with: $body"); // ✅ Debug clarity

      final response = await http.put(
        Uri.parse(UserEndpoints.updateAccess),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint("📩 updateAccess response: ${response.body}");

      if (response.statusCode == 200) {
        await fetchUsers(orgId);
        debugPrint("✅ User access updated successfully");
        return true;
      } else {
        debugPrint("❌ Failed to update access: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error updating access: $e");
      return false;
    }
  }

  // ====================================================
  // -------------------- REMOVE USER -------------------
  // ====================================================
  Future<bool> removeUser({
    required String orgId,
    required String email,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ Token not found, cannot remove user.");
        return false;
      }

      // 🔹 Consistent `org_id` usage
      final body = {
        "org_id": orgId.trim(), // 🔹 Changed key
        "email": email.trim(),
      };

      debugPrint("📤 Removing user with: $body"); // ✅ Added debug log

      final response = await http.delete(
        Uri.parse(UserEndpoints.removeUser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint("📩 removeUser response: ${response.body}");

      if (response.statusCode == 200) {
        _users.removeWhere((user) => user['email'] == email);
        notifyListeners();
        debugPrint("✅ User removed successfully");
        return true;
      } else {
        debugPrint("❌ Failed to remove user: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error removing user: $e");
      return false;
    }
  }
}

