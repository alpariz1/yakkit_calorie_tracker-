import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserInfo {
  final int dailyCalories;
  final double height;
  final double weight;
  final String birthDate; // ISO formatında

  UserInfo({
    required this.dailyCalories,
    required this.height,
    required this.weight,
    required this.birthDate,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // daily_calories değerini önce string'e çevirip, virgül varsa noktaya çeviriyoruz.
    final dailyCalStr = json['daily_calories']?.toString().replaceAll(',', '.');
    final dailyCalories = double.tryParse(dailyCalStr ?? "")?.toInt() ?? 0;

    // height ve weight alanlarını da benzer şekilde işleyebilirsiniz, eğer benzer durum varsa.
    final heightStr = json['height']?.toString().replaceAll(',', '.');
    final weightStr = json['weight']?.toString().replaceAll(',', '.');

    return UserInfo(
      dailyCalories: dailyCalories,
      height: double.tryParse(heightStr ?? "") ?? 0,
      weight: double.tryParse(weightStr ?? "") ?? 0,
      birthDate: json['birth_date'] as String? ?? "",
    );
  }

}

class UserService {
  static const String baseUrl = "http://10.0.2.2:8000";
  static const storage = FlutterSecureStorage();

  static Future<UserInfo> getUserInfo() async {
    String? token = await storage.read(key: "jwt_token");
    if (token == null) {
      throw Exception("JWT token bulunamadı.");
    }

    final url = Uri.parse("$baseUrl/userinfo");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserInfo.fromJson(data);
    } else {
      throw Exception("Kullanıcı bilgileri yüklenemedi: ${response.statusCode}");
    }
  }
}

