import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/org_provider.dart';
import '../screens/dashboard_screen_Extended.dart';
import '../screens/login_screen.dart';
import '../screens/device_management_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/SUPPORT/customer_support_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    // ✅ Fetch org details from OrgProvider
    final orgId = orgProvider.selectedOrgId;
    final orgName = orgProvider.selectedOrgName ?? "No organization selected";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  "Org: $orgName",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreenExtended()),
              );
            },
          ),

          // Device Management
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text("Device Management"),
            onTap: () {
              if (orgId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an organization first")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
              );
            },
          ),

          // User Management
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text("User Management"),
            onTap: () {
              if (orgId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an organization first")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserManagementScreen(orgId: orgId),
                ),
              );
            },
          ),

          // Customer Support
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Customer Support"),
            onTap: () {
              if (orgId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an organization first")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerSupportScreen()),
              );
            },
          ),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              await authProvider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
