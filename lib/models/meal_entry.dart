import 'food_item.dart';

class MealEntry {
  final int id;
  final String date;
  final String mealName;
  final FoodItem foodItem;

  MealEntry({
    required this.id,
    required this.date,
    required this.mealName,
    required this.foodItem,
  });

  // JSON'dan MealEntry oluşturmak için factory metot
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen JSON anahtarlarının FoodItem'daki gibi farklı
    // olma ihtimaline karşı bu alanların backend'deki karşılıklarını
    // kontrol etmek gerekebilir. Varsayılan olarak yaygın isimler kullanılmıştır.
    return MealEntry(
      id: json['id'] as int, // 'id' anahtarı bekleniyor
      date: json['date'] as String, // 'date' anahtarı bekleniyor
      mealName: json['meal_name'] as String, // 'meal_name' anahtarı bekleniyor
      // food_item alanı için gelen JSON nesnesini FoodItem.fromJson'a iletiyoruz.
      // FoodItem.fromJson kendi içindeki backend anahtarlarını (product_name, energy_kcal_100g vb.) yönetecektir.
      foodItem: FoodItem.fromJson(json['food_item'] as Map<String, dynamic>), // 'food_item' anahtarı altında FoodItem JSON'u bekleniyor
    );
  }

  // MealEntry nesnesini JSON formatına dönüştürmek için metot
  Map<String, dynamic> toJson() {
    // Backend'e gönderirken kullanılacak anahtarlar.
    return {
      'id': id,
      'date': date,
      'meal_name': mealName,
      // FoodItem nesnesini toJson metodunu kullanarak JSON'a dönüştürüyoruz.
      'food_item': foodItem.toJson(), // foodItem'ın toJson metodu çağırılır
    };
  }
}