import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'dashboard.dart';
import 'register.dart';
import 'user.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String get url => '$baseUrl/login';
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User> save(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    debugPrint('Login response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      if (res.body.trim().isEmpty || res.body.trim() == 'null') {
        throw Exception('Email ou mot de passe incorrect');
      }
      final decoded = jsonDecode(res.body);
      if (decoded == null || decoded is! Map<String, dynamic>) {
        throw Exception('Email ou mot de passe incorrect');
      }
      return User.fromMap(decoded);
    } else {
      throw Exception('Failed to login (${res.statusCode})');
    }
  }

  Future<void> handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final u = await save(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      debugPrint('Connecté : ${u.email} (${u.role})');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(user: u)),
      );
    } catch (e) {
      debugPrint('Login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
            style: const TextStyle(fontSize: 16.0),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
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
      style: GoogleFonts.roboto(fontSize: 22, color: Colors.purple),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String emptyMessage,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return emptyMessage;
        return null;
      },
      style: TextStyle(fontSize: 22, color: Colors.blueGrey.shade700),
      decoration: const InputDecoration(
        errorStyle: TextStyle(fontSize: 16, color: Colors.black),
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 340,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDE5C4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.oswald(
                            fontWeight: FontWeight.w700,
                            fontSize: 50,
                            color: Colors.black45,
                          ),
                        ),
                        _label('Email'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _emailController,
                          emptyMessage: 'Email is Empty',
                        ),
                        const SizedBox(height: 24),
                        _label('Password'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _passwordController,
                          emptyMessage: 'Password is Empty',
                          obscure: true,
                        ),
                        const SizedBox(height: 30),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Register()),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Dont have Account ?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(233, 65, 82, 1),
                        shape: const CircleBorder(),
                      ),
                      onPressed: _loading ? null : handleSignIn,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(
                        Icons.arrow_forward,
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
    );
  }
}