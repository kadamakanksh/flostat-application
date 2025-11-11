import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/org_provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_endpoints.dart';
import 'dashboard_screen_Extended.dart';
import 'login_screen.dart';

class OrgSelectionScreen extends StatefulWidget {
  const OrgSelectionScreen({super.key});

  @override
  State<OrgSelectionScreen> createState() => _OrgSelectionScreenState();
}

class _OrgSelectionScreenState extends State<OrgSelectionScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orgs = [];

  @override
  void initState() {
    super.initState();
    _fetchUserOrgs();
  }

  /// 🔹 Fetch all organizations created by the logged-in user
  Future<void> _fetchUserOrgs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    setState(() => _loading = true);

    try {
      final response = await http.get(
        Uri.parse(UserEndpoints.getAllOrgsOfUser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          _orgs = List<Map<String, dynamic>>.from(data);
        } else if (data['orgs'] != null) {
          _orgs = List<Map<String, dynamic>>.from(data['orgs']);
        }

        // 🔸 If no organization exists, open create dialog automatically
        if (_orgs.isEmpty) {
          Future.delayed(const Duration(milliseconds: 400), () {
            _showCreateOrgDialog();
          });
        }
      } else {
        debugPrint("❌ Failed to fetch orgs: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching orgs: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🔹 Create new organization
  Future<void> _createOrg(String name, String description, String location) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(OrgEndpoints.createOrg),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'orgName': name,
          'orgDesc': description,
          'location': location,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Organization created successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Organization created successfully!")),
        );
        _fetchUserOrgs(); // Refresh org list
      } else {
        debugPrint("❌ Failed to create org: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create organization: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error creating org: $e");
    }
  }

  /// 🔹 Dialog to input new org details
  void _showCreateOrgDialog() {
    final orgNameCtrl = TextEditingController();
    final orgDescCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Create Organization"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orgNameCtrl,
                decoration: const InputDecoration(labelText: "Organization Name"),
              ),
              TextField(
                controller: orgDescCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: "Location"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (orgNameCtrl.text.isNotEmpty && orgDescCtrl.text.isNotEmpty) {
                _createOrg(orgNameCtrl.text.trim(), orgDescCtrl.text.trim(), locCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = Provider.of<OrgProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Organization"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Back to Login",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _orgs.isEmpty
                      ? const Center(child: Text("No organizations found"))
                      : ListView.builder(
                          itemCount: _orgs.length,
                          itemBuilder: (_, index) {
                            final org = _orgs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(org['orgName'] ?? "Unnamed Organization"),
                                subtitle: Text(org['orgDesc'] ?? ""),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                                onTap: () {
                                  orgProvider.selectOrg(
                                    org['_id'] ?? org['org_id'] ?? '',
                                    org['orgName'] ?? '',
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DashboardScreenExtended()),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                if (_orgs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Create New Organization"),
                      onPressed: _showCreateOrgDialog,
                    ),
                  ),
              ],
            ),
    );
  }
}
