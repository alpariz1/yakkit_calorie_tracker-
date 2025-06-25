import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yakkit_calorie_tracker/services/user_service.dart';
import 'package:yakkit_calorie_tracker/services/food_classifier_service.dart';

import 'package:yakkit_calorie_tracker/models/meal_entry.dart';

class PhotoPage extends StatefulWidget {
  final VoidCallback onDone;
  const PhotoPage({Key? key, required this.onDone}) : super(key: key);

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  XFile? _pickedImage;
  bool _isAnalyzing = false;
  final List<String> mealNames = [
    "Kahvalti",
    "Ogle Yemegi",
    "Aksam Yemegi",
    "Atistirmalik",
  ];
  String? _selectedMeal;

  @override
  void initState() {
    super.initState();
    _selectedMeal = mealNames.first;
  }

  Future<PermissionStatus> _getPermission(ImageSource source) async {
    if (source == ImageSource.camera) return Permission.camera.request();
    if (Platform.isIOS) return Permission.photos.request();
    var info = await DeviceInfoPlugin().androidInfo;
    return (info.version.sdkInt >= 33)
        ? Permission.photos.request()
        : Permission.storage.request();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    var status = await _getPermission(source);
    if (!mounted || !status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İzin verilmedi')),
      );
      return;
    }
    final image = await ImagePicker().pickImage(source: source, maxWidth: 800);
    if (!mounted || image == null) return;
    setState(() {
      _pickedImage = image;
      _isAnalyzing = true;
    });

    try {
      final token = await const FlutterSecureStorage()
          .read(key: UserService.accessTokenKey);
      if (!mounted || token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetkilendirme hatası')),
        );
        return;
      }
      final MealEntry entry = await MealPhotoService.uploadAndLogMeal(
        image: image,
        mealName: _selectedMeal!,
        date: DateTime.now(),
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entry.foodItem.name} eklendi: ${entry.foodItem.calories} kcal',
          ),
        ),
      );
      widget.onDone();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: \$e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotoğraf Ekle')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 60, color: Colors.grey)
                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            if (_pickedImage != null)
              const Text(
                'Öğününüzün Fotoğrafı',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 16),
            if (_isAnalyzing) const CircularProgressIndicator(),
            if (_isAnalyzing) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedMeal,
                items: mealNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMeal = val),
                decoration: InputDecoration(
                  labelText: "Öğün Tipi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera ile Çek'),
              onPressed: () => _pickAndAnalyze(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Galeriden Seç'),
              onPressed: () => _pickAndAnalyze(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
