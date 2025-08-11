import 'package:flutter/material.dart';
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

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // ตัวอย่าง: login logic ที่คุณสามารถเชื่อมกับ backend ได้
    setState(() => _isLoading = true);

    // สำหรับตอนนี้แค่จำลองว่า login สำเร็จ
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
      );

      // TODO: ไปยังหน้า home/dashboard ที่ใช้ตรวจ Evil Twin
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                validator: (value) =>
                    value == null || !value.contains('@') ? 'กรุณากรอกอีเมลที่ถูกต้อง' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'รหัสผ่านสั้นเกินไป' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('เข้าสู่ระบบ'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("ยังไม่มีบัญชี? สมัครสมาชิก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
