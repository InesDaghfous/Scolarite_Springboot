import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'user.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String get url => '$baseUrl/register';
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<User> register(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    debugPrint('Register: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return User.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('Failed to register (${res.statusCode})');
    }
  }

  Future<void> handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final u = await register(
        _emailController.text.trim(),
        _passwordController.text,
      );
      debugPrint('Registered: ${u.email}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created for ${u.email}!',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context); // retour à la page Login
    } catch (e) {
      debugPrint('Register error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration failed. This email may already be in use.',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Align(
        alignment: Alignment.topLeft,
        child: Text(
          text,
          style: GoogleFonts.roboto(fontSize: 20, color: Colors.deepPurple),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String emptyMessage,
    bool obscure = false,
    String? Function(String?)? extraValidator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return emptyMessage;
        return extraValidator?.call(value);
      },
      style: TextStyle(fontSize: 20, color: Colors.blueGrey.shade700),
      decoration: const InputDecoration(
        errorStyle: TextStyle(fontSize: 14, color: Colors.black87),
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8D5F5), Color(0xFFD5E8F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 340,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5D9E8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Register',
                            style: GoogleFonts.oswald(
                              fontWeight: FontWeight.w700,
                              fontSize: 46,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _label('Email'),
                          const SizedBox(height: 6),
                          _field(
                            controller: _emailController,
                            emptyMessage: 'Email is required',
                            keyboardType: TextInputType.emailAddress,
                            extraValidator: (v) {
                              if (!v!.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password
                          _label('Password'),
                          const SizedBox(height: 6),
                          _field(
                            controller: _passwordController,
                            emptyMessage: 'Password is required',
                            obscure: true,
                            extraValidator: (v) {
                              if (v!.length < 4) {
                                return 'At least 4 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password
                          _label('Confirm Password'),
                          const SizedBox(height: 6),
                          _field(
                            controller: _confirmController,
                            emptyMessage: 'Please confirm your password',
                            obscure: true,
                            extraValidator: (v) {
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Already have account
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: const CircleBorder(),
                        ),
                        onPressed: _loading ? null : handleRegister,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}