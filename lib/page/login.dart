import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_app/model/request/userLoginRequest.dart';
import 'package:wifi_app/page/scanwifi.dart';
import 'package:wifi_app/page/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final loginRequest = UserLoginRequest(
      email: _emailController.text,
      passwords: _passwordController.text,
    );

    final url = Uri.parse('http://10.0.2.2:3000/api/login');  // <-- แก้ตรงนี้

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: userLoginRequestToJson(loginRequest),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ScanPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เข้าสู่ระบบล้มเหลว: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เข้าสู่ระบบ")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'รูปแบบอีเมลไม่ถูกต้อง' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? 'รหัสผ่านสั้นเกินไป' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: const Text('เข้าสู่ระบบ')),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text("ยังไม่มีบัญชี? สมัครสมาชิก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
