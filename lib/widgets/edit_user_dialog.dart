import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class EditUserDialog extends StatefulWidget {
  final String orgId;
  final String userEmail; // changed from userId → userEmail
  final String currentRole;

  const EditUserDialog({
    super.key,
    required this.orgId,
    required this.userEmail,
    required this.currentRole,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  String? _selectedRole;
  bool _isLoading = false;

  final List<String> roles = ['guest', 'admin', 'root'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return AlertDialog(
      title: const Text(
        "Edit User Role",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: DropdownButtonFormField<String>(
        initialValue: _selectedRole,
        decoration: const InputDecoration(
          labelText: "Select New Role",
          border: OutlineInputBorder(),
        ),
        items: roles
            .map(
              (role) => DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _selectedRole = val!),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_selectedRole == null ||
                      _selectedRole == widget.currentRole) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Please select a different role."),
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  final success = await userProvider.updateAccess(
                    orgId: widget.orgId,
                    email: widget.userEmail, // fixed name to match provider
                    newRole: _selectedRole!,
                  );

                  setState(() => _isLoading = false);

                  if (!mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Role updated successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("❌ Failed to update role."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Update"),
        ),
      ],
    );
  }
}

