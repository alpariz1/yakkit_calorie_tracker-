class FoodItem {
  final String name;
  final int calories;

  FoodItem({required this.name, required this.calories});

  // CSV satırından FoodItem oluşturmak için (mevcut)
  factory FoodItem.fromCsv(List<String> csvRow) {
    return FoodItem(
      name: csvRow[0],
      calories: double.tryParse(csvRow[1])?.round() ?? 0,
    );
  }

  // JSON'dan FoodItem oluşturmak için
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Backend'de ürün adı "product_name" olarak geliyor olabilir.
    return FoodItem(
      name: json['product_name'] as String,
      // Eğer kalori alanı farklı ise onu da backend'den çekin. Örnek:
      calories: (json['energy_kcal_100g'] as num?)?.round() ?? 0,
    );
  }
}
