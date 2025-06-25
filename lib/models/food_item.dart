class FoodItem {
  final int id; // Add the id field
  final String name;
  final int calories;

  FoodItem({required this.id, required this.name, required this.calories});

  // CSV satırından FoodItem oluşturmak için (muhtemelen artık kullanılmıyor ama kalsın)
  // Factory constructor'ın ID'yi nasıl alacağı CSV formatına bağlı. CSV'de ID yoksa
  // bu constructor FoodItem nesnesi oluşturmak için eksik kalacaktır.
  // Eğer CSV hala kullanılıyorsa, CSV formatının ID'yi de içermesi veya
  // başka bir yerden ID sağlanması gerekir. Şimdilik mevcut haliyle bırakıyorum,
  // backend JSON'dan geldiği için fromJson daha önemli.
  factory FoodItem.fromCsv(List<String> csvRow) {
    // Eğer CSV'de ID yoksa, bu constructor tam bir FoodItem oluşturamaz.
    // CSV formatına göre bu kısım ayarlanmalı.
    // Örnek: eğer ID 0. sütunda, ad 1.de, kalori 2.de ise:
    // return FoodItem(
    //   id: int.tryParse(csvRow[0]) ?? 0,
    //   name: csvRow[1],
    //   calories: double.tryParse(csvRow[2])?.round() ?? 0,
    // );
    // Varsayılan olarak ID'yi 0 alıp devam edelim, ama bu CSV kullanımına bağlıdır.
    return FoodItem(
      id: 0, // CSV'de ID yoksa veya format farklıysa burası düzeltilmeli
      name: csvRow[0],
      calories: double.tryParse(csvRow[1])?.round() ?? 0,
    );
  }

  // JSON'dan FoodItem oluşturmak için (Backend'den alırken)
  // Backend JSON'unda 'id' anahtarının olduğunu varsayıyoruz.
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int? ?? 0, // Backend'den 'id'yi oku
      name: json['product_name'] as String? ?? '', // Backend'den 'product_name'i oku
      calories: (json['energy_kcal_100g'] as num?)?.round() ?? 0, // Backend'den enerji değerini oku
    );
  }

  // FoodItem nesnesini JSON'a dönüştürmek için (Backend'e gönderirken)
  // Genellikle bir FoodItem'ı tek başına backend'e göndermek yerine,
  // MealEntry içinde gönderilir veya sadece ID'si kullanılır.
  // Eğer backend FoodItem objesini bekliyorsa bu metot kullanılır.
  Map<String, dynamic> toJson() {
    return {
      'id': id, // ID'yi de JSON'a ekle
      'name': name,
      'calories': calories,
      // Eğer backend gönderirken 'product_name', 'energy_kcal_100g' bekliyorsa:
      // 'product_name': name,
      // 'energy_kcal_100g': calories,
    };
  }
}