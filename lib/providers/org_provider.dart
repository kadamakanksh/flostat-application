import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';

class OrgProvider with ChangeNotifier {
  String? selectedOrgId;
  String? selectedOrgName;
  String? token;
  List<Map<String, dynamic>> orgList = [];

  // ✅ Added helper for Device Management
  String? getSelectedOrgId() => selectedOrgId;

  // -------------------- Load Org from Storage --------------------
  Future<void> loadSelectedOrg() async {
    final prefs = await SharedPreferences.getInstance();
    selectedOrgId = prefs.getString("selected_org_id");
    selectedOrgName = prefs.getString("selected_org_name");
    notifyListeners();
  }

  // -------------------- Save Org Selection --------------------
  Future<void> selectOrg(String orgId, String orgName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selected_org_id", orgId);
    await prefs.setString("selected_org_name", orgName);
    selectedOrgId = orgId;
    selectedOrgName = orgName;
    notifyListeners();
  }

  // -------------------- Clear Org --------------------
  void clearOrg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("selected_org_id");
    await prefs.remove("selected_org_name");
    selectedOrgId = null;
    selectedOrgName = null;
    notifyListeners();
  }

  // -------------------- Set Token --------------------
  void setToken(String userToken) {
    token = userToken;
    notifyListeners();
  }

  // -------------------- Fetch Organizations --------------------
  Future<void> fetchOrganizations() async {
    if (token == null) return;

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
        final data = json.decode(response.body);
        if (data is List) {
          orgList = List<Map<String, dynamic>>.from(data);
        } else if (data['organizations'] != null) {
          orgList = List<Map<String, dynamic>>.from(data['organizations']);
        }
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch organizations: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching organizations: $e");
    }
  }

  // -------------------- Create Organization --------------------
  Future<bool> createOrganization(
      String orgName, String orgDesc, String location) async {
    if (token == null) return false;

    final url = Uri.parse(OrgEndpoints.createOrg);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "orgName": orgName,
          "orgDesc": orgDesc,
          "location": location,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrganizations();
        return true;
      } else {
        debugPrint("❌ Failed to create organization: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error creating organization: $e");
      return false;
    }
  }
}
