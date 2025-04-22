import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yakkit_calorie_tracker/models/meal.dart';
import 'package:yakkit_calorie_tracker/models/food_item.dart';
import 'package:yakkit_calorie_tracker/services/food_data_service.dart';
import 'package:yakkit_calorie_tracker/services/user_service.dart';
//import 'package:yakkit_calorie_tracker/models/user_info.dart';
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Öğünler (sabit, örnek)
  final List<Meal> meals = [
    Meal(name: "Kahvaltı"),
    Meal(name: "Öğle Yemeği"),
    Meal(name: "Akşam Yemeği"),
    Meal(name: "Atıştırmalık"),
  ];

  // Toplam alınan kalori ve son eklenen yiyecekler
  int totalCaloriesConsumed = 0;
  List<FoodItem> recentlyAdded = [];

  // Kullanıcı bilgilerini gelecekte yüklemek için Future
  late Future<UserInfo> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgilerini yalnızca bir kez yüklüyoruz.
    _userInfoFuture = UserService.getUserInfo();
  }

  // Seçilen öğüne yiyecek ekleme ve backend'e kaydetme işlemi
  void addFoodToMeal(int mealIndex, FoodItem foodItem) async {
    setState(() {
      meals[mealIndex].addFoodItem(foodItem);
      totalCaloriesConsumed += foodItem.calories;
      recentlyAdded.insert(0, foodItem);
      if (recentlyAdded.length > 5) {
        recentlyAdded = recentlyAdded.sublist(0, 5);
      }
    });
    String today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    await FoodDataService.updateMealWithFood(
      meal: meals[mealIndex],
      date: today,
    );
  }

  // Güncel tarihi biçimlendirme
  String getCurrentDate() {
    final now = DateTime.now();
    return DateFormat("dd/MM/yyyy").format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getCurrentDate()),
      ),
      body: FutureBuilder<UserInfo>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          // Bekleme durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hata durumunda
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          // Veriler geldiğinde
          if (snapshot.hasData) {
            final userInfo = snapshot.data!;
            final dailyCalorieGoal = userInfo.dailyCalories;
            final remainingCalories = dailyCalorieGoal - totalCaloriesConsumed;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Özet Kartı: Alınan, hedef ve kalan kaloriler
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text("Özet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text("$totalCaloriesConsumed", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text("Alınan Kalori"),
                                ],
                              ),
                              Column(
                                children: [
                                  Text("$dailyCalorieGoal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text("Günlük Hedef"),
                                ],
                              ),
                              Column(
                                children: [
                                  Text("$remainingCalories", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text("Kalan Kalori"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Beslenme Bölümü Başlığı
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Beslenme", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  // Öğünlerin listelendiği bölüm
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(meals.length, (index) => mealRow(index, meals[index])),
                    ),
                  ),
                  // (Gerekirse diğer bölümler eklenebilir)
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // Öğün satırı widget'ı
  Widget mealRow(int mealIndex, Meal meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(meal.name, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Text("${meal.totalCalories} kcal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => showFoodSelectionDialog(mealIndex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Backend'den arama yaparak yiyecek seçimi diyalogunu gösteren fonksiyon
  void showFoodSelectionDialog(int mealIndex) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        List<FoodItem> searchResults = [];
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Yiyecek Seç"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Ara",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) async {
                        searchQuery = value;
                        // Minimum karakter kontrolü ile backend aramasını tetikleyin
                        if (searchQuery.length >= 2) {
                          setStateDialog(() {
                            isLoading = true;
                          });
                          try {
                            searchResults = await FoodDataService().searchFoodItems(searchQuery);
                          } catch (e) {
                            searchResults = [];
                          }
                          setStateDialog(() {
                            isLoading = false;
                          });
                        } else {
                          setStateDialog(() {
                            searchResults = [];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        height: 200,
                        child: searchResults.isNotEmpty
                            ? ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final item = searchResults[index];
                            return ListTile(
                              title: Text(item.name),
                              trailing: Text("${item.calories} kcal"),
                              onTap: () {
                                addFoodToMeal(mealIndex, item);
                                Navigator.pop(context);
                              },
                            );
                          },
                        )
                            : const Center(child: Text("Sonuç bulunamadı")),
                      ),
                    const SizedBox(height: 10),
                    if (recentlyAdded.isNotEmpty)
                      Column(
                        children: [
                          const Divider(),
                          const Text("Son Eklenenler", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: recentlyAdded.length,
                              itemBuilder: (context, index) {
                                final item = recentlyAdded[index];
                                return ListTile(
                                  title: Text(item.name),
                                  trailing: Text("${item.calories} kcal"),
                                  onTap: () {
                                    addFoodToMeal(mealIndex, item);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
