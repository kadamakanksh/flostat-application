
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AddUserDialog extends StatefulWidget {
  final String orgId;
  const AddUserDialog({super.key, required this.orgId});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'guest';
  bool _isLoading = false;

  // ✅ Kept available roles consistent with your backend
  final List<String> roles = ['guest', 'admin', 'root'];

  @override
  Widget build(BuildContext context) {
    // ✅ Using Provider to access the UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return AlertDialog(
      title: const Text("Invite User"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Email input field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "User Email",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter email";
                }
                if (!value.contains('@')) {
                  return "Enter a valid email";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 🔹 Role dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(),
              ),
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedRole = val!);
              },
            ),
          ],
        ),
      ),
      actions: [
        // ✅ Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),

        // ✅ Invite button with loading state
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  // 🔹 Calls updated inviteUser() (which uses correct org_id format)
                  final success = await userProvider.inviteUser(
                    orgId: widget.orgId,
                    email: _emailController.text.trim(),
                    role: _selectedRole,
                  );

                  setState(() => _isLoading = false);

                  if (success) {
                    // ✅ Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ User invited successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // 🔹 Changed: pop and return true to refresh user list automatically
                    Navigator.pop(context, true); // ✅ ensures UI refresh on parent
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("❌ Failed to invite user"),
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
              : const Text("Invite"),
        ),
      ],
    );
  }
}
