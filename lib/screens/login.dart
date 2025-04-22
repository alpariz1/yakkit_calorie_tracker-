import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yakkit_calorie_tracker/main.dart'; // MainScreen'in bulunduğu dosya
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    // Emulator kullanıyorsanız 10.0.2.2, gerçek cihazda backend IP'nizi kullanın.
    final url = Uri.parse("http://10.0.2.2:8000/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": _emailController.text.trim(), // OAuth2 form'da "username" olarak email gönderiliyor
        "password": _passwordController.text.trim(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["access_token"];
      // JWT token'ı güvenli depolamaya kaydediyoruz.
      await storage.write(key: "jwt_token", value: token);

      // Kullanıcı bilgilerini çekmek için /userinfo endpoint'ine istek gönderiyoruz.
      final userInfoResponse = await http.get(
        Uri.parse("http://10.0.2.2:8000/userinfo"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (userInfoResponse.statusCode == 200) {
        final userInfo = jsonDecode(userInfoResponse.body);
        final username = userInfo["username"];
        await storage.write(key: "username", value: username);
      } else {
        // Eğer /userinfo isteğinde hata alırsanız varsayılan değeri yazabilirsiniz.
        await storage.write(key: "username", value: "Kullanıcı adı bulunamadı");
      }

      setState(() {
        _isLoading = false;
      });

      // Başarılı giriş sonrası MainScreen'e yönlendiriyoruz.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş başarısız, bilgilerinizi kontrol edin.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value == null || value.isEmpty ? "Email giriniz" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Şifre"),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? "Şifre giriniz" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Giriş Yap"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text("Hesabınız yok mu? Kayıt Olun"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
