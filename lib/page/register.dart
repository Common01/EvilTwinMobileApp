import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_app/model/request/userRegisterRequest.dart';
import 'package:wifi_app/page/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = UserRegisterRequest(
      username: _usernameController.text,
      email: _emailController.text,
      passwords: _passwordController.text,
    );

    final url = Uri.parse('http://localhost:3000/api/register'); // เปลี่ยนเป็น IP จริงเวลาใช้งาน

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: userRegisterRequestToJson(user),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สมัครสมาชิกสำเร็จ')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สมัครไม่สำเร็จ: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลงทะเบียน")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'รูปแบบอีเมลไม่ถูกต้อง' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('สมัครสมาชิก'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text("มีบัญชีอยู่แล้ว? เข้าสู่ระบบ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
