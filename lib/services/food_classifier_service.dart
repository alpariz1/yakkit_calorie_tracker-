import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:yakkit_calorie_tracker/services/food_data_service.dart';
import 'package:yakkit_calorie_tracker/models/meal_entry.dart';

class FoodClassifierService {
  //static const _url = 'http://10.0.2.2:8001/classify';
  //static const _url = 'http://192.168.43.171:8001/classify';
  static const _url = 'https://77f1-176-227-2-12.ngrok-free.app/classify';
  //static const _url = 'http://10.0.2.2/classify';

  /// Sunucuya resmi gönderir, dönen JSON'dan sınıf ve kalori bilgilerini döndürür.
  static Future<Map<String, dynamic>> classifyImage(XFile image) async {
    final request = http.MultipartRequest('POST', Uri.parse(_url))
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Kalori analizi başarısız: ${response.statusCode}');
    }

    final body = await response.stream.bytesToString();
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
class MealPhotoService {
  // 1) classify+log endpoint URL’i
  //static const _url = 'http://10.0.2.2:8000/users/me/meals/photo';
  //static const _url = 'http://192.168.43.171:8000/users/me/meals/photo';
  static const _url = 'https://cc8e-176-227-2-12.ngrok-free.app/users/me/meals/photo';
  /// Fotoğrafı, seçilen mealName ve date ile gönderip anında MealEntry al.
  static Future<MealEntry> uploadAndLogMeal({
    required XFile image,
    required String mealName,
    required DateTime date,
    required String token,
  }) async {
    final uri = Uri.parse(_url)
        .replace(queryParameters: {
      'meal_name': mealName,
      'date': date.toIso8601String().substring(0,10),
    });
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('image', image.path));
    final res = await req.send();
    if (res.statusCode != 200) throw Exception('Fotoğrafla ekleme başarısız');
    final body = await res.stream.bytesToString();
    final Map<String,dynamic> json = jsonDecode(body);
    return MealEntry.fromJson(jsonDecode(body));
  }
}
