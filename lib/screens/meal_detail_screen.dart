import 'package:flutter/material.dart';
import 'package:yakkit_calorie_tracker/models/meal_entry.dart'; // MealEntry modelini import edin

class MealDetailScreen extends StatelessWidget {
  final String mealName;
  final List<MealEntry> entries;

  const MealDetailScreen({
    Key? key,
    required this.mealName,
    required this.entries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Eğer hiç kayıt yoksa bilgilendirici bir mesaj gösterelim
    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("$mealName Detay"),
        ),
        body: const Center(
          child: Text(
            "Bu öğün için henüz bir kayıt yok.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Kayıtlar varsa listeyi gösterelim
    return Scaffold(
      appBar: AppBar(
        title: Text("$mealName Detay"), // Sayfa başlığı: "Kahvaltı Detay" gibi
      ),
      body: ListView.builder(
        itemCount: entries.length, // Listedeki eleman sayısı
        itemBuilder: (context, index) {
          final entry = entries[index]; // Mevcut öğün kaydı (MealEntry)

          // Her bir liste öğesini Card içine alalım
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Kartlar arasına boşluk
            elevation: 1.0, // Kartın hafif gölgesi
            child: ListTile( // Kartın içine ListTile koyarak içeriği düzenleyelim
              title: Text(entry.foodItem.name), // Yiyecek adını göster
              trailing: Text("${entry.foodItem.calories} kcal"), // Kalori miktarını göster
              // İsteğe bağlı: Buraya tıklama eventi ekleyerek yiyecek detayını gösterebilir veya silme/düzenleme ikonları ekleyebilirsiniz.
              // onTap: () { /* Detay göster veya düzenle */ },
            ),
          );
        },
      ),
    );
  }
}