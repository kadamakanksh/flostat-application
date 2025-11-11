import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';

class AuthProvider with ChangeNotifier {
  String? token;
  String? email;
  String? firstName;
  String? lastName;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  // ✅ Added for Device Management use
  String? getToken() => token;

  // -------------------- LOGIN --------------------
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      this.email = email;
      firstName = data['user']['firstName'];
      lastName = data['user']['lastName'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", token!);

      print("✅ Token after login: $token");
      notifyListeners();
      return true;
    } else {
      print("❌ Login failed: ${response.body}");
      return false;
    }
  }

  // -------------------- SIGN UP --------------------
  Future<bool> signup(
      String firstName, String lastName, String email, String password,String confirmPassword) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.signUp),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "conformPassword": confirmPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Signup successful");
      return true;
    } else {
      print("❌ Signup failed: ${response.body}");
      return false;
    }
  }

  // -------------------- RESET PASSWORD --------------------
  Future<bool> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(AuthEndpoints.sendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error in password reset: $e");
      return false;
    }
  }

  // -------------------- LOAD TOKEN --------------------
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token");
    if (token != null) print("✅ Loaded token: $token");
    notifyListeners();
  }

  // -------------------- LOGOUT --------------------
  Future<void> logout() async {
    token = null;
    email = null;
    firstName = null;
    lastName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    notifyListeners();
  }

  // -------------------- GET USER ORGS --------------------
  Future<List<dynamic>> getUserOrganizations() async {
    if (token == null) return [];

    final url = Uri.parse(UserEndpoints.getAllOrgsOfUser);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data['organizations'] != null) {
          return data['organizations'];
        }
      } else {
        print("❌ Failed to load orgs: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching orgs: $e");
    }

    return [];
  }
}
