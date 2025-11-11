import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/org_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/edit_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  final String orgId; // Passed from org or dashboard

  const UserManagementScreen({super.key, required this.orgId});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch users for this organization when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false)
          .fetchUsers(widget.orgId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          orgProvider.selectedOrgName != null
              ? "Users in ${orgProvider.selectedOrgName}"
              : "User Management",
        ),
        backgroundColor: Colors.blue,
      ),
      drawer: const CustomDrawer(),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => userProvider.fetchUsers(widget.orgId),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header with Add Button ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Users in this Organization",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add User"),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (_) =>
                                    AddUserDialog(orgId: widget.orgId),
                              );
                              if (result == true) {
                                userProvider.fetchUsers(widget.orgId);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- User List ---
                    Expanded(
                      child: userProvider.users.isEmpty
                          ? const Center(
                              child: Text(
                                "No users found.",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: userProvider.users.length,
                              itemBuilder: (context, index) {
                                final user = userProvider.users[index];
                                final userEmail = user['email'] ?? 'Unknown';
                                final userRole = user['role'] ?? 'N/A';
                                final userStatus =
                                    user['status'] ?? 'unknown';

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      userEmail,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      "Role: $userRole\nStatus: $userStatus",
                                    ),

                                    // 🔹 Trailing widget: Accept / Accepted / PopupMenu
                                    trailing: userStatus == 'pending'
                                        ? ElevatedButton(
                                            onPressed: () async {
                                              final success =
                                                  await userProvider.acceptInvite(
                                                email: userEmail,
                                                orgId: widget.orgId,
                                              );

                                              if (success) {
                                                setState(() {
                                                  // Update status locally for immediate UI feedback
                                                  user['status'] = 'active';
                                                });

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "✅ Invite accepted successfully"),
                                                  ),
                                                );

                                                // Optional: Fetch updated users from backend
                                                await userProvider.fetchUsers(widget.orgId);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "❌ Failed to accept invite"),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                            ),
                                            child: const Text("Accept"),
                                          )
                                        : userStatus == 'active'
                                            ? const Text(
                                                "Accepted",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : PopupMenuButton<String>(
                                                onSelected: (value) async {
                                                  if (value == 'edit') {
                                                    final result =
                                                        await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          EditUserDialog(
                                                        orgId: widget.orgId,
                                                        userEmail: userEmail,
                                                        currentRole: userRole,
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      userProvider.fetchUsers(
                                                          widget.orgId);
                                                    }
                                                  } else if (value == 'delete') {
                                                    final confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Remove User"),
                                                        content: const Text(
                                                            "Are you sure you want to remove this user?"),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child: const Text(
                                                                "Cancel"),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            child: const Text(
                                                              "Remove",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (confirm == true) {
                                                      await userProvider
                                                          .removeUser(
                                                        orgId: widget.orgId,
                                                        email: userEmail,
                                                      );
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => const [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text("Edit Role"),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text("Remove"),
                                                  ),
                                                ],
                                              ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
