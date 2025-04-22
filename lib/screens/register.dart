import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _heightController   = TextEditingController();
  final TextEditingController _weightController   = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Flutter Secure Storage
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;

  // Dropdown seçenekleri ve seçilen hedef
  final List<String> _goals = ['Kilo Vermek', 'Kas Yapmak'];
  String? _selectedGoal;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    //   127.0.0.1  yerine  10.0.2.2
    final url = Uri.parse("http://10.0.2.2:8000/register");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text.trim(),
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "height": double.tryParse(_heightController.text.trim()),
        "weight": double.tryParse(_weightController.text.trim()),
        "goal": _selectedGoal,
        "birth_date": _birthDateController.text.trim() // Beklenen format: YYYY-MM-DD
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data["access_token"];
      await storage.write(key: "jwt_token", value: token);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarısız, bilgilerinizi kontrol edin.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) => value == null || value.isEmpty ? "Email giriniz" : null,
                ),
                const SizedBox(height: 10),
                // Kullanıcı Adı
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Kullanıcı Adı"),
                  validator: (value) => value == null || value.isEmpty ? "Kullanıcı adı giriniz" : null,
                ),
                const SizedBox(height: 10),
                // Şifre
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Şifre"),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? "Şifre giriniz" : null,
                ),
                const SizedBox(height: 10),
                // Boy
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(labelText: "Boy (cm)"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? "Boy bilgisi giriniz" : null,
                ),
                const SizedBox(height: 10),
                // Kilo
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: "Kilo (kg)"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? "Kilo bilgisi giriniz" : null,
                ),
                const SizedBox(height: 10),
                // Hedef Seçimi (Dropdown)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Hedef",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedGoal,
                  items: _goals.map((goal) {
                    return DropdownMenuItem<String>(
                      value: goal,
                      child: Text(goal),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Hedef seçiniz";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Doğum Tarihi
                TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: "Doğum Tarihi",
                    hintText: "YYYY-MM-DD",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true, // Manuel girişe izin vermiyor.
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(), // Varsayılan başlangıç tarihi
                      firstDate: DateTime(1900), // Seçilebilecek en eski tarih
                      lastDate: DateTime.now(), // Gelecekteki tarihlere izin vermez
                    );
                    if (pickedDate != null) {
                      // Tarihi uygun formata çeviriyoruz
                      String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      setState(() {
                        _birthDateController.text = formattedDate;
                      });
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Doğum tarihi giriniz" : null,
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Kayıt Ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
