import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yakkit_calorie_tracker/models/food_item.dart';
import 'package:yakkit_calorie_tracker/models/meal.dart';
class FoodDataService {
  static const String baseUrl = "http://10.0.2.2:8000";

  // Tüm yiyecek verilerini yükleyen metot (varsa)
  Future<List<FoodItem>> loadFoodData() async {
    final response = await http.get(Uri.parse("$baseUrl/fooditems"));
    //
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception("Veriler yüklenemedi: ${response.statusCode}");
    }
  }

  // Yeni: Arama sorgusuna göre yiyecek verilerini yükleyen metot.
  Future<List<FoodItem>> searchFoodItems(String query) async {
    final response = await http.get(Uri.parse("$baseUrl/fooditems/search?query=$query"));
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception("Arama sonuçları yüklenemedi: ${response.statusCode}");
    }
  }

  /// Yemek verisinin güncel tarih ile backend'e güncellenmesi.
  static Future<void> updateMealWithFood({
    required Meal meal,
    required String date,
  }) async {
    final url = Uri.parse("$baseUrl/update_meal");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "meal_name": meal.name,
        "date": date,
        "total_calories": meal.totalCalories,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Meal güncellemesi başarısız: ${response.statusCode}");
    }
  }
}
