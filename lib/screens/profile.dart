import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart'; // Giriş ekranının bulunduğu dosya

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = const FlutterSecureStorage();
  String username = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Güvenli depolamadan kullanıcı adını okuyoruz.
  Future<void> _loadUsername() async {
    String? storedUsername = await storage.read(key: "username");
    setState(() {
      username = storedUsername ?? "Kullanıcı adı bulunamadı";
    });
  }

  // Çıkış yapınca tüm saklı verileri temizleyip giriş ekranına yönlendiriyoruz.
  Future<void> _logout() async {
    await storage.deleteAll();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: Center(
        child: Text(
          "Hoşgeldin, $username",
          style: const TextStyle(fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        tooltip: "Çıkış Yap",
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }
}
