/*import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yakkit_calorie_tracker/services/user_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserInfo> _userInfoFuture;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = UserService.getUserInfo();
  }

  Future<void> _logout() async {
    await UserService.clearStorage();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _pickImage(int userId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _pickedImage = image);
    _pickedImageBytes = await File(image.path).readAsBytes();
    setState(() {});

    await UserService.uploadPhoto(userId, image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<UserInfo>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Kullanıcı bilgileri bulunamadı'));
          }

          final info = snapshot.data!;
          Uint8List? serverImageBytes = info.profileImageBase64 != null
              ? base64Decode(info.profileImageBase64!)
              : null;
          final double startWeight = info.weight;
          const double targetWeight = 95;
          final double progress = (startWeight - targetWeight) / startWeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(info.id),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _pickedImageBytes != null
                                ? MemoryImage(_pickedImageBytes!)
                                : (serverImageBytes != null
                                ? MemoryImage(serverImageBytes)
                                : null),
                            child: (_pickedImageBytes == null &&
                                serverImageBytes == null)
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          info.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _infoChip('Yaş', info.age.toString()),
                            _infoChip('Hedef', info.goal),
                            _infoChip('Boy', '${info.height} cm'),
                            _infoChip('Kilo', '${info.weight} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'My Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${startWeight.toStringAsFixed(0)} kg'),
                            Text('${targetWeight.toStringAsFixed(0)} kg'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                        const SizedBox(height: 8),
                        const Text(
                          'Hedef kiloyu belirlemek için düzenle.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Yakkit with Friends'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        tooltip: 'Çıkış Yap',
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade200,
    );
  }
}*/
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yakkit_calorie_tracker/services/user_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserInfo> _userInfoFuture;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  double _targetWeight = 95; // Dinamik hedef kilo

  @override
  void initState() {
    super.initState();
    _userInfoFuture = UserService.getUserInfo();
  }

  Future<void> _logout() async {
    await UserService.clearStorage();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _pickImage(int userId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _pickedImage = image);
    _pickedImageBytes = await File(image.path).readAsBytes();
    setState(() {});

    await UserService.uploadPhoto(userId, image);
  }

  Future<void> _editTargetWeight() async {
    final controller = TextEditingController(text: _targetWeight.toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedef Kiloyu Güncelle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hedef kilo (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null) {
      final value = double.tryParse(result);
      if (value != null) {
        setState(() => _targetWeight = value);
        // İsteğe bağlı: yeni hedefi backend'e kaydet
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<UserInfo>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Kullanıcı bilgileri bulunamadı'));
          }

          final info = snapshot.data!;
          Uint8List? serverImageBytes = info.profileImageBase64 != null
              ? base64Decode(info.profileImageBase64!)
              : null;
          final double startWeight = info.weight;
          final double progress = (startWeight - _targetWeight) / startWeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(info.id),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _pickedImageBytes != null
                                ? MemoryImage(_pickedImageBytes!)
                                : (serverImageBytes != null
                                ? MemoryImage(serverImageBytes)
                                : null),
                            child: (_pickedImageBytes == null && serverImageBytes == null)
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          info.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _infoChip('Yaş', info.age.toString()),
                            _infoChip('Hedef', info.goal),
                            _infoChip('Boy', '${info.height} cm'),
                            _infoChip('Kilo', '${info.weight} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'My Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${startWeight.toStringAsFixed(0)} kg'),
                            Row(
                              children: [
                                Text('${_targetWeight.toStringAsFixed(0)} kg'),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: _editTargetWeight,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                        const SizedBox(height: 8),
                        const Text(
                          'Hedef kiloyu belirlemek için düzenle.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Yakkit with Friends'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        tooltip: 'Çıkış Yap',
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

