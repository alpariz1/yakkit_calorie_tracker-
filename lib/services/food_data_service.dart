/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yakkit_calorie_tracker/models/food_item.dart';
import 'package:yakkit_calorie_tracker/models/meal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import 'package:yakkit_calorie_tracker/models/meal_entry.dart';

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
  // Yeni: Günün öğünlerini getir
  static Future<List<MealEntry>> getMealsForDate(String date) async {
    final token = await _storage.read(key: _tokenKey);
    final res = await http.get(
      Uri.parse('$baseUrl/users/me/meals?date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Meals load failed');
    final list = jsonDecode(res.body) as List;
    return list.map((j) => MealEntry.fromJson(j)).toList();
  }

  // Yeni: Öğün kaydı ekle
  static Future<void> addMealEntry(DateTime date, String mealName, int foodItemId) async {
    final token = await _storage.read(key: _tokenKey);
    final res = await http.post(
      Uri.parse('$baseUrl/users/me/meals'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'date': DateFormat('yyyy-MM-dd').format(date),
        'meal_name': mealName,
        'food_item_id': foodItemId,
      }),
    );
    if (res.statusCode != 201) throw Exception('Add meal failed');
  }
}
*//*
import 'dart:convert';
import 'package:http/http.dart' as http;
// Importların gereksiz tekrarları temizlendi
// import 'package:yakkit_calorie_tracker/models/food_item.dart';
// import 'package:yakkit_calorie_tracker/models/meal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';


class FoodDataService {
  static const String baseUrl = "http://10.0.2.2:8000";

  // FlutterSecureStorage örneği ve token anahtarı tanımlandı
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token'; // Güvenli saklama için bir anahtar

  // Tüm yiyecek verilerini yükleyen metot (varsa)
  Future<List<FoodItem>> loadFoodData() async {
    final token = await _storage.read(key: _tokenKey);
    // Headers tipini açıkça belirttik
    final Map<String, String> headers = token != null ? {'Authorization': 'Bearer $token'} : {};

    final response = await http.get(Uri.parse("$baseUrl/fooditems"), headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList(); // Tip belirttik
    } else {
      // Hata durumunda token kontrolü veya daha spesifik mesajlar eklenebilir
      throw Exception("Veriler yüklenemedi: ${response.statusCode}");
    }
  }
  // Yeni: Belirli bir tarih için kullanıcının streak bilgisini getirir
  /// Yeni yiyecek ekleme (backend /fooditems)
  Future<FoodItem> createFoodItem({
    required String name,
    double? calories100g,
    double? carbs100g,
    double? proteins100g,
    double? fat100g,
    double? fiber100g,
    double? sugars100g,
  }) async {
    final token = await _storage.read(key: _tokenKey);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'product_name': name,
      'energy_kcal_100g': calories100g,
      'carbohydrates_100g': carbs100g,
      'proteins_100g': proteins100g,
      'fat_100g': fat100g,
      'fiber_100g': fiber100g,
      'sugars_100g': sugars100g,
    });
    final res = await http.post(
      Uri.parse('$baseUrl/fooditems'),
      headers: headers,
      body: body,
    );
    if (res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return FoodItem.fromJson(decoded);
    } else {
      throw Exception('Yiyecek ekleme başarısız: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getStreakForDate(String date) async {

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {

      throw Exception("Yetkilendirme Hatası: Kullanıcı oturum açmamış.");

    }

    final Map<String, String> headers = {'Authorization': 'Bearer $token'};



    // Backend'deki yeni streak endpoint'inizi çağırın

    final res = await http.get(

      Uri.parse('$baseUrl/users/me/streak?target_date=$date'), // target_date query parametresi backend'deki isimle aynı olmalı

      headers: headers,

    );



    if (res.statusCode == 200) {

      // Backend'den {"streak_count": int, "has_entry_today": bool} formatında veri bekleniyor

      return jsonDecode(res.body) as Map<String, dynamic>;

    } else if (res.statusCode == 401 || res.statusCode == 403) {

      throw Exception('Yetkilendirme hatası: Lütfen tekrar giriş yapın.');

    } else {

      print("Failed to load streak: ${res.statusCode}");

      print("Response body: ${res.body}");

      throw Exception('Failed to load streak: ${res.statusCode}');

    }

  }
  // Yeni: Arama sorgusuna göre yiyecek verilerini yükleyen metot.
  Future<List<FoodItem>> searchFoodItems(String query) async {
    final token = await _storage.read(key: _tokenKey);
    // Headers tipini açıkça belirttik
    final Map<String, String> headers = token != null ? {'Authorization': 'Bearer $token'} : {};

    final response = await http.get(Uri.parse("$baseUrl/fooditems/search?query=$query"), headers: headers);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList(); // Tip belirttik
    } else {
      throw Exception("Arama sonuçları yüklenemedi: ${response.statusCode}");
    }
  }

  /// Yemek verisinin güncel tarih ile backend'e güncellenmesi.
  // Not: Bu metodun amacı ve backend endpoint'i (update_meal) yapınıza göre kontrol edilmeli.
  static Future<void> updateMealWithFood({
    // required Meal meal, // Eğer Meal sınıfı kullanılıyorsa kalsın
    required String date,
    // Gerekirse hangi MealEntry'nin güncellendiği bilgisi (id) eklenmeli
  }) async {
    final token = await _storage.read(key: _tokenKey);
    // Headers tipini açıkça belirttik
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      if (token != null) 'Authorization': 'Bearer $token', // Token varsa ekle
    };

    final url = Uri.parse("$baseUrl/update_meal"); // Bu endpoint backend'de ne yapıyor kontrol edin
    final response = await http.put(
      url,
      headers: headers,
      // Backend'in beklediği body formatına göre bu kısım ayarlanmalı
      body: jsonEncode({
        // "meal_name": meal.name, // Meal nesnesi kullanılıyorsa
        "date": date,
        // "total_calories": meal.totalCalories, // Meal nesnesi kullanılıyorsa
        // Eğer MealEntry güncelleniyorsa, entry'nin ID'si gibi bilgiler gerekebilir.
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Meal güncellemesi başarısız: ${response.statusCode}");
    }
  }
  // Yeni: Günün öğünlerini getir
  static Future<List<MealEntry>> getMealsForDate(String date) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception("Yetkilendirme Hatası: Kullanıcı oturum açmamış.");
    }
    // Headers tipini açıkça belirttik
    final Map<String, String> headers = {'Authorization': 'Bearer $token'};

    final res = await http.get(
      Uri.parse('$baseUrl/users/me/meals?date=$date'),
      headers: headers, // Tanımlanmış headers kullanıldı
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((j) => MealEntry.fromJson(j as Map<String, dynamic>)).toList();
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkilendirme hatası: Lütfen tekrar giriş yapın.');
    }
    else {
      throw Exception('Meals load failed: ${res.statusCode}');
    }
  }

  // Yeni: Öğün kaydı ekle
  static Future<void> addMealEntry(DateTime date, String mealName, int foodItemId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception("Yetkilendirme Hatası: Kullanıcı oturum açmamış.");
    }
    // Headers tipini açıkça belirttik
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    final res = await http.post(
      Uri.parse('$baseUrl/users/me/meals'),
      headers: headers, // Tanımlanmış headers kullanıldı
      body: jsonEncode({
        'date': DateFormat('yyyy-MM-dd').format(date),
        'meal_name': mealName,
        'food_item_id': foodItemId,
      }),
    );
    if (res.statusCode == 201) {
      print("Meal entry başarıyla eklendi.");
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkilendirme hatası: Lütfen tekrar giriş yapın.');
    }
    else {
      print("Add meal failed with status code: ${res.statusCode}");
      print("Response body: ${res.body}");
      throw Exception('Add meal failed: ${res.statusCode}');
    }
  }

  // Token kaydetme ve silme metotları
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}*/
// FoodDataService.dart dosyası

import 'dart:convert'; // JSON işlemleri için
import 'package:http/http.dart' as http; // HTTP istekleri için
import 'package:intl/intl.dart'; // Tarih formatlama için (addMealEntry'de kullanılıyor)

// Model importları (projenizdeki yollara göre doğru olduğundan emin olun)
import '../models/food_item.dart';
import '../models/meal_entry.dart';

// UserService importu (projenizdeki yola göre doğru olduğundan emin olun)
// UserService sınıfının, sendAuthenticatedRequest statik metodunu içerdiğini varsayıyoruz.
import 'user_service.dart';


class FoodDataService {
  // Base URL'i UserService'den alarak tutarlılık sağlıyoruz.
  static const String baseUrl = UserService.baseUrl;

  // === Artık burada FlutterSecureStorage veya token anahtarı TUTMUYORUZ ===
  // Token yönetimi ve güvenli saklama UserService'e aittir.
  // saveToken ve deleteToken metotları da burada OLMAYACAK, UserService'de olmalı.


  // === Kimlik Doğrulama Gerektiren Metotlar (UserService.sendAuthenticatedRequest Kullanılarak) ===

  /// Tüm yiyecek verilerini yükleyen metot.
  /// Eğer backend bu liste için kimlik doğrulama gerektiriyorsa bu metot kullanılır.
  Future<List<FoodItem>> loadFoodData() async {
    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı GET isteği gönderiyoruz.
    // Authorization header'ı UserService.sendAuthenticatedRequest tarafından otomatik eklenir.
    final response = await UserService.sendAuthenticatedRequest(
      'GET', // HTTP Metodu
      Uri.parse("$baseUrl/fooditems"), // URI
      // headers: {}, // Ekstra özel bir başlık gerekmiyorsa boş bırakılabilir
      // body: null, // GET isteği için body olmaz
    );

    // sendAuthenticatedRequest 401 hatalarını (Unauthorized) kendisi yönetir (token yenileme vs.).
    // Geri kalan başarılı veya diğer hata durumlarını burada işleriz.
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      // JSON listesini FoodItem nesnelerine dönüştürüyoruz. Güvenli tip dönüşümü 'as Map<String, dynamic>' yapıldı.
      return decoded.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      // 200 olmayan durumlar için hata fırlatıyoruz.
      print("Veriler yüklenemedi: ${response.statusCode}");
      print("Response body: ${response.body}"); // Hata durumunda response body'sini görmek faydalı
      throw Exception("Veriler yüklenemedi: ${response.statusCode}");
    }
  }

  /// Arama sorgusuna göre yiyecek verilerini yükleyen metot.
  /// Eğer backend arama için kimlik doğrulama gerektiriyorsa bu metot kullanılır.
  Future<List<FoodItem>> searchFoodItems(String query) async {
    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı GET isteği gönderiyoruz.
    final response = await UserService.sendAuthenticatedRequest(
      'GET', // HTTP Metodu
      Uri.parse("$baseUrl/fooditems/search?query=$query"), // URI (arama sorgusu dahil)
      // headers: {}, // Ekstra özel bir başlık gerekmiyorsa boş bırakılabilir
    );

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      // JSON listesini FoodItem nesnelerine dönüştürüyoruz. Güvenli tip dönüşümü yapıldı.
      return decoded.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      // sendAuthenticatedRequest 401 hatalarını yönetir. Diğer hataları işleriz.
      print("Arama sonuçları yüklenemedi: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception("Arama sonuçları yüklenemedi: ${response.statusCode}");
    }
  }

  /// Yeni yiyecek ekleme (backend /fooditems POST endpoint'ine)
  /// Kimlik doğrulama gerektirir.
  Future<FoodItem> createFoodItem({
    required String name,
    double? calories100g,
    double? carbs100g,
    double? proteins100g,
    double? fat100g,
    double? fiber100g,
    double? sugars100g,
  }) async {
    // Body JSON formatında gönderileceği için Content-Type header'ı gerekli.
    // Authorization header'ı UserService.sendAuthenticatedRequest tarafından eklenecek.
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'product_name': name,
      'energy_kcal_100g': calories100g,
      'carbohydrates_100g': carbs100g,
      'proteins_100g': proteins100g,
      'fat_100g': fat100g,
      'fiber_100g': fiber100g,
      'sugars_100g': sugars100g,
    });

    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı POST isteği gönderiyoruz.
    final res = await UserService.sendAuthenticatedRequest(
      'POST', // HTTP Metodu
      Uri.parse('$baseUrl/fooditems'), // URI
      headers: headers, // Headerları iletiyoruz
      body: body, // Body'yi iletiyoruz
    );

    // Backend'in başarılı ekleme için 201 Created döndürdüğünü varsayıyoruz.
    if (res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>; // Güvenli tip dönüşümü
      return FoodItem.fromJson(decoded);
    } else {
      // sendAuthenticatedRequest 401'i yönetir. Diğer hataları işleriz.
      print("Yiyecek ekleme başarısız: ${res.statusCode}");
      print("Response body: ${res.body}");
      throw Exception('Yiyecek ekleme başarısız: ${res.statusCode}');
    }
  }


  /// Belirli bir tarih için kullanıcının streak bilgisini getirir.
  /// Kimlik doğrulama gerektirir.
  static Future<Map<String, dynamic>> getStreakForDate(String date) async {
    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı GET isteği gönderiyoruz.
    final res = await UserService.sendAuthenticatedRequest(
      'GET', // HTTP Metodu
      Uri.parse('$baseUrl/users/me/streak?target_date=$date'), // URI (tarih query parametresi olarak)
      // headers: {}, // Ekstra özel bir başlık gerekmiyorsa boş bırakılabilir
    );

    if (res.statusCode == 200) {
      // Backend'den {"streak_count": int, "has_entry_today": bool} formatında veri bekleniyor.
      final decoded = jsonDecode(res.body);
      // JSON'dan Map'e güvenli tip dönüşümü yapıldı.
      return decoded as Map<String, dynamic>;
    } else {
      // sendAuthenticatedRequest 401'i yönetir. Diğer hataları işleriz.
      print("Failed to load streak: ${res.statusCode}");
      print("Response body: ${res.body}");
      throw Exception('Failed to load streak: ${res.statusCode}');
    }
  }

  /// Yemek verisinin güncel tarih ile backend'e güncellenmesi.
  /// Kimlik doğrulama gerektirir.
  /// NOT: Bu metodun backend endpoint'i "$baseUrl/update_meal" ve beklediği body formatı
  /// projenizin backend yapısına göre kontrol edilmeli ve aşağıdaki body formatı
  /// buna göre AYARLANMALIDIR. Aşağıdaki sadece bir varsayımdır.
  static Future<void> updateMealWithFood({
    // Eğer backend'e Meal modeli göndermeniz gerekiyorsa bu parametreyi ekleyin
    // required Meal meal,
    required String date,
    // Eğer tek bir MealEntry'i ID ile güncelliyorsanız ID parametresini ekleyin
    // int? mealEntryId,
  }) async {
    // Body JSON formatında gönderileceği için Content-Type header'ı gerekli.
    final headers = {"Content-Type": "application/json"};

    final url = Uri.parse("$baseUrl/update_meal"); // Backend'deki endpoint adresiniz
    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı PUT isteği gönderiyoruz.
    final response = await UserService.sendAuthenticatedRequest(
      'PUT', // HTTP Metodu
      url, // URI
      headers: headers, // Headerları iletiyoruz
      // Backend'in beklediği body formatına göre bu kısım ayarlanmalı
      body: jsonEncode({ // Body
        // "meal_name": meal.name, // Eğer Meal nesnesi kullanılıyorsa
        "date": date,
        // "total_calories": meal.totalCalories, // Eğer Meal nesnesi kullanılıyorsa
        // Eğer MealEntry güncelleniyorsa, entry'nin ID'si gibi bilgiler gerekebilir.
        // "meal_entry_id": mealEntryId,
        // ... backend'in beklediği diğer alanlar
      }),
    );

    // Backend'in başarılı güncelleme için 200 OK döndürdüğünü varsayıyoruz.
    if (response.statusCode != 200) {
      // sendAuthenticatedRequest 401'i yönetir. Diğer hataları işleriz.
      print("Meal güncellemesi başarısız: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception("Meal güncellemesi başarısız: ${response.statusCode}");
    }
  }

  /// Günün öğünlerini getirir.
  /// Kimlik doğrulama gerektirir.
  static Future<List<MealEntry>> getMealsForDate(String date) async {
    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı GET isteği gönderiyoruz.
    final res = await UserService.sendAuthenticatedRequest(
      'GET', // HTTP Metodu
      Uri.parse('$baseUrl/users/me/meals?date=$date'), // URI (tarih query parametresi olarak)
      // headers: {}, // Ekstra özel bir başlık gerekmiyorsa boş bırakılabilir
    );

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List; // Güvenli tip dönüşümü
      // JSON listesini MealEntry nesnelerine dönüştürüyoruz. Güvenli tip dönüşümü yapıldı.
      return list.map((j) => MealEntry.fromJson(j as Map<String, dynamic>)).toList();
    } else {
      // sendAuthenticatedRequest 401'i yönetir. Diğer hataları işleriz.
      print('Meals load failed: ${res.statusCode}');
      print("Response body: ${res.body}");
      throw Exception('Meals load failed: ${res.statusCode}');
    }
  }

  /// Yeni bir öğün kaydı ekler.
  /// Kimlik doğrulama gerektirir.
  static Future<void> addMealEntry(DateTime date, String mealName, int foodItemId) async {
    // Body JSON formatında gönderileceği için Content-Type header'ı gerekli.
    final headers = {
      'Content-Type': 'application/json'
    };

    // UserService'in yardımcı metodunu kullanarak kimlik doğrulamalı POST isteği gönderiyoruz.
    final res = await UserService.sendAuthenticatedRequest(
      'POST', // HTTP Metodu
      Uri.parse('$baseUrl/users/me/meals'), // URI
      headers: headers, // Headerları iletiyoruz
      body: jsonEncode({ // Body (backend'in beklediği formatta)
        'date': DateFormat('yyyy-MM-dd').format(date), // Tarihi "YYYY-MM-DD" formatında gönderiyoruz
        'meal_name': mealName,
        'food_item_id': foodItemId,
      }),
    );

    // Backend'in başarılı ekleme için 201 Created döndürdüğünü varsayıyoruz.
    if (res.statusCode == 201) {
      print("Meal entry başarıyla eklendi.");
      // Başarılı işlem sonrası backend'den dönen response body'de veri varsa burada işlenebilir.
      // final decodedResponse = jsonDecode(res.body);
    } else {
      // sendAuthenticatedRequest 401'i yönetir. Diğer hataları işleriz.
      print("Add meal failed with status code: ${res.statusCode}");
      print("Response body: ${res.body}");
      throw Exception('Add meal failed: ${res.statusCode}');
    }
  }

// === Token kaydetme ve silme metotları ARTIK BURADA DEĞİL, UserService'dedir ===
// static Future<void> saveToken(String token) async { ... }
// static Future<void> deleteToken() async { ... }
}