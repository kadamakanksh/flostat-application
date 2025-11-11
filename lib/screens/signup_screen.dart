// signup_screen.dart
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool loading = false;

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => loading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // ✅ Pass confirmPassword as well
    final success = await authProvider.signup(
      firstName,
      lastName,
      email,
      password,
      confirmPassword,
    );

    setState(() => loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Successful! Please login.")));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Failed! Try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "First Name"),
                      onSaved: (val) => firstName = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Last Name"),
                      onSaved: (val) => lastName = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => email = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      onSaved: (val) => password = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Confirm Password"),
                      obscureText: true,
                      onSaved: (val) => confirmPassword = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signup,
                      child: const Text("Sign Up"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
