
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Debug amaçlı string byte kontrolü için eklendi
import 'dart:async';
// Gerekli modeller ve servisler
import 'package:yakkit_calorie_tracker/models/food_item.dart'; // FoodItem artık id içermeli
import 'package:yakkit_calorie_tracker/models/meal_entry.dart';
import 'package:yakkit_calorie_tracker/services/food_data_service.dart';
import 'package:yakkit_calorie_tracker/services/user_service.dart'; // logout metodu eklendi
import 'package:yakkit_calorie_tracker/screens/login.dart'; // Login sayfasına yönlendirme için
import 'package:yakkit_calorie_tracker/screens/add_meal.dart';

// Yeni oluşturduğumuz detay sayfasını import edin
import 'package:yakkit_calorie_tracker/screens/meal_detail_screen.dart';

// UserInfo sınıfının UserService dosyasında tanımlı olduğunu varsayıyoruz
// MealEntry sınıfının models/meal_entry.dart dosyasında tanımlı olduğunu varsayıyoruz
// FoodItem sınıfının models/food_item.dart dosyasında id alanı dahil tanımlı olduğunu varsayıyoruz


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Seçili tarih state'i, başlangıçta bugünün tarihi
  DateTime _selectedDate = DateTime.now();
  // Seçili tarihe ait backend'den çekilen öğün kayıtları
  List<MealEntry> todayEntries = [];
  // Kayıtların backend'den yüklenme durumu
  bool _isLoadingEntries = true;
  // Streak bilgisini tutacak state değişkenleri

  int _streakCount = 0; // Backend'den gelecek streak sayısı

  bool _hasEntryToday = false; // Backend'den gelecek, bugün giriş yapılmış mı?

  bool _isLoadingStreak = true; // Streak bilgisinin yüklenme durumu


  // Uygulamada tanımlı öğün isimleri.
  // Karakter kodlama sorununu önlemek için Türkçe karakter içermeyen isimler kullanıldı.
  // Backend veritabanındaki meal_name değerleri de bu isimlerle tam eşleşmelidir.
  final List<String> mealNames = [
    "Kahvalti",   // "Kahvaltı" yerine
    "Ogle Yemegi",// "Öğle Yemeği" yerine
    "Aksam Yemegi", // "Akşam Yemeği" yerine
    "Atistirmalik",// "Atıştırmalık" yerine
  ];

  // Kullanıcı bilgilerini asenkron olarak yüklemek için Future
  late Future<UserInfo> _userInfoFuture;
  // Son eklenen yiyecekler listesi (UI ipucu için kullanılır, kalıcı veri değildir)
  final List<FoodItem> recentlyAdded = [];

  @override
  void initState() {
    super.initState();
    // Widget oluşturulduğunda kullanıcı bilgisini ve ilk olarak bugünün kayıtlarını yükle
    _userInfoFuture = UserService.getUserInfo();
    _loadEntriesFor(_selectedDate);
    _loadStreakFor(_selectedDate);
  }
  Future<void> _loadStreakFor(DateTime date) async {

    if (!mounted) return;

    setState(() => _isLoadingStreak = true); // Yükleme durumu başladı

    final dateString = DateFormat('yyyy-MM-dd').format(date); // Tarihi backend formatına çevir

    try {

      // FoodDataService'deki yeni metodu çağırın

      final streakData = await FoodDataService.getStreakForDate(dateString);

      if (!mounted) return; // setState öncesi tekrar kontrol

      setState(() {

        _streakCount = streakData['streak_count'] as int; // Gelen int değeri ata

        _hasEntryToday = streakData['has_entry_today'] as bool; // Gelen bool değeri ata

        _isLoadingStreak = false; // Yükleme bitti

      });

    } catch (e) {

      if (!mounted) return; // setState öncesi tekrar kontrol

      setState(() {

        _isLoadingStreak = false; // Hata durumunda da yükleme bitti

        // Hata durumunda streak'i sıfırlayabilir veya bir hata durumu gösterebilirsiniz

        _streakCount = 0;

        _hasEntryToday = false;

      });

      print("Failed to load streak: $e"); // Hatayı logla

      // Kullanıcıya streak yüklenirken hata oluştuğuna dair bilgi gösterebilirsiniz (opsiyonel)

    }

  }
  // Belirtilen tarih için öğün kayıtlarını backend'den yükler
  Future<void> _loadEntriesFor(DateTime date) async {
    // Widget hala mounted durumda mı kontrol et (asenkron işlemler için iyi pratik)
    if (!mounted) return;
    setState(() => _isLoadingEntries = true); // Yükleme durumu başladı
    final dateString = DateFormat('yyyy-MM-dd').format(date); // Tarihi backend formatına çevir (örn: "2023-10-27")
    try {
      final entries = await FoodDataService.getMealsForDate(dateString);
      if (!mounted) return; // setState öncesi tekrar kontrol
      setState(() {
        todayEntries = entries; // Yüklenen kayıtları state'e ata
        _isLoadingEntries = false; // Yükleme bitti
      });

      // Debug amaçlı string kontrol kodu (backend karakter kodlama sorununu teşhis etmek için kullanılır)
      // Eğer backend karakter kodlama sorunu çözülmediyse veya şüphelendiğiniz bir durum varsa bu kısmı aktif edin.
      // print("--- Debugging Meal Names ---");
      // print("Yerel mealNames listesi:");
      // for (var name in mealNames) {
      //   print("'$name' bytes: ${utf8.encode(name)}");
      // }
      // print("\nBackend'den gelen öğün isimleri (todayEntries):");
      // if (todayEntries.isEmpty) {
      //   print("Bugün için kayıt bulunamadı.");
      // } else {
      //   for (var entry in todayEntries) {
      //     print("entry.mealName: '${entry.mealName}' bytes: ${utf8.encode(entry.mealName)}");
      //     if (!mealNames.contains(entry.mealName)) {
      //        print("  UYARI: Bu backend öğün adı, yerel mealNames listesinde YOK.");
      //     }
      //   }
      // }
      // print("--- Debugging Meal Names SON ---");


    } catch (e) {
      if (!mounted) return; // setState öncesi tekrar kontrol
      setState(() => _isLoadingEntries = false); // Hata durumunda da yükleme bitti
      // Kullanıcıya hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öğünler yüklenirken hata oluştu: ${e.toString()}')),
      );
      // Eğer hata yetkilendirme ile ilgiliyse logout yap ve login'e yönlendir
      // UserService içindeki hata mesajına göre kontrol yapıyoruz
      if (e.toString().contains('Authentication')) {
        _handleAuthError(); // Yetkilendirme hatasını işleyen metod
      }
    }
  }

  // Yiyecek ekleme işlemi: Seçilen öğüne (index ile belirlenen) belirtilen yiyeceği ekler
  Future<void> addFoodToMeal(int mealIndex, FoodItem foodItem) async {
    final mealName = mealNames[mealIndex]; // Seçilen öğün adını local listeden al (artık Türkçe karakter içermiyor)
    try {
      // Backend'e yeni MealEntry ekle. mealName olarak local listeden alınan string gönderilir.
      await FoodDataService.addMealEntry(_selectedDate, mealName, foodItem.id);

      // Başarıyla eklendikten sonra UI'yı backend'deki güncel durumla senkronize etmek için kayıtları yeniden çek.
      await _loadEntriesFor(_selectedDate);
      await _loadStreakFor(_selectedDate);
      // Son eklenenler listesini güncelle (Sadece UI ipucu için, kalıcı değil)
      if (!mounted) return; // setState öncesi kontrol
      setState(() {
        recentlyAdded.insert(0, foodItem); // Listebaşına ekle
        if (recentlyAdded.length > 5) recentlyAdded.removeLast(); // Listeyi 5 ile sınırla
      });

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${foodItem.name} ${mealName} öğününe eklendi.')),
      );

    } catch (e) {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yiyecek eklenirken hata oluştu: ${e.toString()}')),
      );
      // Yetkilendirme hatası ise logout yap
      if (e.toString().contains('Authentication')) { // UserService'deki hata mesajına göre kontrol
        _handleAuthError(); // Yetkilendirme hatasını işleyen metod
      }
    }
  }

  // Belirli bir öğün adına ait toplam kaloriyi, şu anda yüklenmiş olan todayEntries listesinden hesaplar
  int calculateMealTotal(String mealName) {
    // todayEntries listesini, entry'nin mealName'i verilen mealName ile tam eşleşenler için filtrele
    // Backend'den gelen entry.mealName stringi artık Türkçe karakter içermeyen stringlerle eşleşmelidir.
    return todayEntries
        .where((entry) => entry.mealName == mealName)
        .fold(0, (sum, e) => sum + e.foodItem.calories); // Filtrelenmiş öğelerin kalorilerini topla
  }

  // Seçili tarihi biçimlendirilmiş string olarak döndürür (örn: "dd/MM/yyyy")
  String getFormattedDate() {
    return DateFormat("dd/MM/yyyy").format(_selectedDate);
  }

  // Tarih seçiciyi gösterir ve seçilen tarihi günceller
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Başlangıç tarihi olarak mevcut seçili tarih
      firstDate: DateTime(2000), // Seçilebilecek en eski tarih (örnek)
      lastDate: DateTime.now(), // Seçilebilecek en son tarih (bugün)
    );
    // Kullanıcı bir tarih seçtiyse ve bu tarih mevcut seçili tarihten farklıysa
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return; // setState öncesi kontrol
      setState(() => _selectedDate = picked); // Seçili tarihi state'de güncelle
      _loadEntriesFor(picked);
      _loadStreakFor(picked);// Yeni tarih için kayıtları backend'den yükle
    }
  }

  // Yetkilendirme hatası durumunda kullanıcıyı logout yapıp login sayfasına yönlendiren metod
  void _handleAuthError() async {
    await UserService.logout(); // UserService içindeki logout metodunu çağırarak token'ı sil
    if (!mounted) return; // Yönlendirme öncesi kontrol
    // Login sayfasına yönlendir (ve geri dönüşü engellemek için pushReplacement kullan)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // Ana build metodu: UI'yı oluşturur
  @override
  Widget build(BuildContext context) {
    // Tüm öğün kayıtlarının toplam kalorisini hesapla (Özet kartı için)
    // Bu hesaplama, todayEntries state'i her güncellendiğinde otomatik olarak yeniden yapılır.
    final totalCalories = todayEntries.fold(0, (sum, e) => sum + e.foodItem.calories);

    return Scaffold(
      // home.dart dosyanızdaki build metodu içindeki AppBar widget'ı
      appBar: AppBar(
        title: Text(getFormattedDate()), // Seçili tarihi başlıkta göster (sol üstte yer alacak)
        // leading: IconButton kısmı buradan kaldırılacak veya yorum satırı yapılacak
        // leading: IconButton( // Takvim ikonu buradaydı
        //   icon: const Icon(Icons.calendar_today),
        //   onPressed: _pickDate,
        //   tooltip: 'Tarih Seç',
        // ),
        actions: [
          // Takvim ikonunu sağdaki actions listesine geri taşımanız gerekiyor
          IconButton( // <-- Takvim ikonu buraya taşınacak
            icon: const Icon(Icons.calendar_today), // Takvim ikonu
            onPressed: _pickDate, // İkona basıldığında _pickDate metodunu çağır
            tooltip: 'Tarih Seç', // İkon üzerine gelindiğinde görünecek ipucu metni
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isLoadingStreak
                ? SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : GestureDetector(
              onTap: () {
                //   burada streak detay sayfasına yönlendirme eklenebilir.
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 28,
                    color: _hasEntryToday ? Colors.orange : Colors.grey,
                  ),
                  if (_streakCount > 0)
                    Positioned(
                      top: 4, right: 4,
                      child: Text(
                        '$_streakCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Buraya başka sağ üst ikonlar eklenebilir (örneğin profil, ayarlar vb.)
        ],
      ),

      body: FutureBuilder<UserInfo>(
        future: _userInfoFuture, // Kullanıcı bilgisi yükleniyor mu?
        builder: (context, snapshot) {
          // Kullanıcı bilgisi bekleniyorsa bir yükleme göstergesi göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Kullanıcı bilgisi yüklenirken hata oluşursa (örn: token geçersizse)
          if (snapshot.hasError) {
            print("UserInfo Future Error: ${snapshot.error}"); // Hata detayını logla
            // Yetkilendirme hatası durumunda özel bir hata widget'ı göster
            return _buildAuthErrorWidget(snapshot.error.toString());
          }
          // Kullanıcı bilgisi başarıyla yüklendiyse
          if (snapshot.hasData) {
            final userInfo = snapshot.data!;
            final dailyGoal = userInfo.dailyCalories; // Kullanıcının günlük kalori hedefi
            final remaining = dailyGoal - totalCalories; // Kalan kalori miktarı

            // UI içeriğini oluşturan Column
            return SingleChildScrollView( // İçerik ekranı aşarsa kaydırılabilir yap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // İçeriği sola hizala
                children: [
                  // Kalori Özet Kartı
                  _buildSummaryCard(totalCalories, dailyGoal, remaining),
                  // "Beslenme" Bölümü Başlığı
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Beslenme", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  // Öğünlerin listelendiği Kart (artık detayları gizliyor)
                  _buildMealsCard(),
                  // İsteğe bağlı olarak son eklenenleri ana ekranda göstermek isterseniz buraya ekleyebilirsiniz.
                  // Şu an sadece diyalog içinde gösteriliyor.
                ],
              ),
            );
          }
          // Future null ise veya beklenmedik bir durum olursa boş bir widget döndür
          return const SizedBox();
        },
      ),
    );
  }

  // Yetkilendirme hatası durumunda gösterilecek UI widget'ı
  Widget _buildAuthErrorWidget(String errorMessage) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min, // İçeriği kadar yer kapla
      mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
      children: [
        const Icon(Icons.error, color: Colors.red, size: 60), // Hata ikonu
        const SizedBox(height: 16), // Boşluk
        Text(
          'Kullanıcı bilgileri yüklenemedi: ${errorMessage}', // Hata mesajını göster
          textAlign: TextAlign.center, // Metni ortala
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 12), // Boşluk
        const Text(
          'Lütfen giriş yapın',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12), // Boşluk
        // Giriş Yap butonu
        ElevatedButton(
          onPressed: _handleAuthError, // Butona basıldığında yetkilendirme hatası işleyiciyi çağır
          child: const Text('Giriş Yap'),
        ),
      ],
    ),
  );

  // Kalori özet kartını oluşturan widget
  Widget _buildSummaryCard(int total, int goal, int remaining) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Yuvarlak köşeler
      elevation: 3, // Gölge
      margin: const EdgeInsets.all(16), // Dış boşluk
      child: Padding(
        padding: const EdgeInsets.all(16.0), // İç boşluk
        child: Column(
          children: [
            const Text("Özet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Başlık
            const SizedBox(height: 10), // Boşluk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Elemanları eşit aralıklarla yay
              children: [
                // Alınan Kalori sütunu
                _buildSummaryColumn(total, "Alınan Kalori"),
                // Günlük Hedef sütunu
                _buildSummaryColumn(goal, "Günlük Hedef"),
                // Kalan Kalori sütunu (pozitif/negatif renklendirme ile)
                _buildSummaryColumn(remaining, "Kalan Kalori", valueColor: remaining >= 0 ? Colors.blueAccent : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Özet kartındaki tek bir kalori bilgisini (değer ve label) gösteren yardımcı widget
  Column _buildSummaryColumn(int value, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          "$value", // Kalori değeri
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor, // Belirtilen renk veya varsayılan metin rengi
          ),
        ),
        Text(label), // Açıklama (Label)
      ],
    );
  }

  // Öğünleri listeleyen ana kart widget'ı (detayları artık gizliyor)
  Widget _buildMealsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Yuvarlak köşeler
      elevation: 3, // Gölge
      margin: const EdgeInsets.all(16), // Dış boşluk
      child: _isLoadingEntries // Kayıtlar yükleniyorsa yükleme indicatoru göster
          ? const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      )
          : Column( // Yükleme bittiyse öğün listesini oluştur
        // mealNames listesindeki her bir öğün adı için bir satır oluştur
        children: List.generate(mealNames.length, (index) {
          final name = mealNames[index]; // Öğün adını local listeden al

          // Her bir öğün için bir satır oluştur (tıklanabilir olacak)
          // Öğün detayları artık doğrudan burada listelenmeyecek
          return _mealRow(index, name);
        }),
      ),
    );
  }

  // Tek bir öğün başlığı satırını (isim, toplam kalori, ekleme butonu) oluşturan widget
  // Bu widget artık tıklanabilir olacak ve detay sayfasına yönlendirecek.
  Widget _mealRow(int mealIndex, String mealName) {
    // Bu öğün adına ait toplam kaloriyi hesapla
    final total = calculateMealTotal(mealName);

    // InkWell veya GestureDetector kullanarak satırı tıklanabilir yap
    return InkWell(
      // ripple efekti için InkWell tercih edilebilir
      onTap: () {
        // Tıklanan öğüne ait kayıtları filtrele
        final entriesForMeal = todayEntries
            .where((entry) => entry.mealName == mealName)
            .toList();

        // Yeni sayfaya navigasyon yap ve mealName ile filtered entries'i pass et
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailScreen(
              mealName: mealName,
              entries: entriesForMeal,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // İç boşluk
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Öğün adı sola, kalori/ikon sağa
          children: [
            Text(mealName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Öğün adını kalın yaz
            Row(
              children: [
                Text("$total kcal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Hesaplanan toplam kaloriyi göster
                const SizedBox(width: 10), // Kalori ile ikon arasına boşluk
                // Yiyecek ekleme butonu (bu buton hala tıklanabilir olmalı)
                // IconButton'ı InkWell'in dışına taşırsak sadece butona tıklama çalışır.
                // İçine koyarsak hem satıra hem butona tıklama çalışabilir.
                // Burada IconButton'ın kendi tıklanma özelliğini korumak istediğimiz için
                // onu da Row içine, Text'lerin yanına koyuyoruz.
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () async {
                    // 1) AddMealPage’ten seçilen FoodItem’ı await ile yakala
                    final   selected = await Navigator.push<FoodItem>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMealPage(mealIndex: mealIndex,recentlyAdded: recentlyAdded, ),
                      ),
                    );

                    // 2) Eğer kullanıcı bir şey seçtiyse, addFoodToMeal ile ekle ve bekle
                    if (selected != null) {
                      await addFoodToMeal(mealIndex, selected);
                      // Burada addFoodToMeal zaten _loadEntriesFor ve setState
                      // çağırıyor; bu sayede hem todayEntries hem de özet ekran
                      // (toplam ve kalan kalori) güncel veriye göre yeniden render edilir.
                    }
                  },
                  tooltip: 'Yiyecek Ekle', // İkon üzerine gelindiğinde görünecek ipucu metni
                  // İpucu: IconButton'ın kendi padding'i vardır, Row'daki boşluk ile ayarlanabilir.
                  padding: EdgeInsets.zero, // İsteğe bağlı: varsayılan padding'i kaldırmak için
                  constraints: BoxConstraints(), // İsteğe bağlı: varsayılan boyut kısıtlamalarını kaldırmak için
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Backend'den arama yaparak yiyecek seçimi diyalogunu gösteren fonksiyon
  void showFoodSelectionDialog(int mealIndex) {
    // Diyalog içinde state yönetimi için StatefulBuilder kullanıyoruz
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = ''; // Arama sorgusu state'i (diyalog için yerel)
        Timer? _debounce;
        List<FoodItem> searchResults = []; // Arama sonuçları state'i (diyalog için yerel)
        bool isLoadingSearch = false; // Arama yükleme durumu state'i (diyalog için yerel)

        return StatefulBuilder( // Diyalog içindeki UI'ı güncellemek için
          builder: (context, setStateDialog) { // Dialogun kendi setState metodu
            return AlertDialog(
              title: const Text("Yiyecek Seç"), // Diyalog başlığı
              content: SizedBox(
                width: double.maxFinite, // Diyaloğun genişliğini maksimum yapmaya çalış
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Sütunun yüksekliğini içeriği kadar yap
                  children: [
                    // Arama Metin Alanı
                TextField(
                decoration: const InputDecoration(
                labelText: "Ara",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                ),
                onChanged: (value) {
                  searchQuery = value;

                  // 2a) Önceki timer’ı iptal et
                  _debounce?.cancel();

                  // 2b) Yeni bir timer başlat
                  _debounce = Timer(const Duration(milliseconds: 300), () async {
                    // 2c) Minimum 2 karakter kontrolü
                    if (searchQuery.length < 2) {
                      if (!context.mounted) return;
                      setStateDialog(() {
                        searchResults = [];
                        isLoadingSearch = false;
                      });
                      return;
                    }

                    // 2d) Yükleme durumunu göster
                    if (!context.mounted) return;
                    setStateDialog(() {
                      isLoadingSearch = true;
                    });

                    try {
                      // 2e) Backend’e prefix–matching sorgusu gönder (pizza% gibi)
                      final results = await FoodDataService().searchFoodItems(searchQuery);
                      if (!context.mounted) return;
                      setStateDialog(() {
                        searchResults = results;
                      });
                    } catch (e) {
                      print("Search error: $e");
                      if (!context.mounted) return;
                      setStateDialog(() {
                        searchResults = [];
                      });
                    } finally {
                      if (!context.mounted) return;
                      setStateDialog(() {
                        isLoadingSearch = false;
                      });
                    }
                  });
                },
              ),
                    const SizedBox(height: 10), // Boşluk
                    // Arama yükleniyorsa yükleme indicatoru göster, yoksa sonuçları listele
                    if (isLoadingSearch)
                      const Center(child: CircularProgressIndicator())
                    else
                    // Arama sonuçlarını listelemek için Expanded kullan
                      Expanded( // Arama sonuçları listesinin yüksekliğini ayarlar ve taşmayı engeller
                        child: searchResults.isNotEmpty
                            ? ListView.builder( // Sonuçlar varsa liste oluştur
                          shrinkWrap: true, // İçeriği kadar yer kapla
                          // physics: const ClampingScrollPhysics(), // Expanded içinde gerekmeyebilir
                          itemCount: searchResults.length, // Sonuç sayısı kadar öğe
                          itemBuilder: (context, index) {
                            final item = searchResults[index]; // Listedeki FoodItem nesnesi
                            return ListTile( // Her FoodItem için bir liste öğesi
                              title: Text(item.name), // Yiyecek adı
                              trailing: Text("${item.calories} kcal"), // Kalori miktarı
                              onTap: () { // Öğeye tıklandığında
                                addFoodToMeal(mealIndex, item); // Seçilen yiyeceği ilgili öğüne ekle
                                Navigator.pop(context); // Diyalogu kapat
                              },
                            );
                          },
                        )
                            : const Center(child: Text("Sonuç bulunamadı")), // Sonuç yoksa mesaj göster
                      ),
                    const SizedBox(height: 10), // Boşluk
                    // Eğer son eklenen yiyecekler varsa listesini göster
                    if (recentlyAdded.isNotEmpty) ...[
                      const Divider(), // Ayırıcı çizgi
                      const Text("Son Eklenenler", style: TextStyle(fontWeight: FontWeight.bold)), // Başlık
                      SizedBox( // Son eklenenler listesi için sabit yükseklik (kaydırılabilir)
                        height: recentlyAdded.length * 50.0, // Listedeki öğe sayısına göre dinamik yükseklik (yaklaşık)
                        // height: 150.0, // Sabit bir yükseklik de verebilirsiniz
                        child: ListView.builder( // Son eklenenleri listele
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: recentlyAdded.length, // Son eklenen sayısı
                          itemBuilder: (context, index) {
                            final item = recentlyAdded[index]; // recentlyAdded listesindeki FoodItem
                            return ListTile( // Her FoodItem için bir liste öğesi
                              title: Text(item.name), // Yiyecek adı
                              trailing: Text("${item.calories} kcal"), // Kalori miktarı
                              onTap: () { // Öğeye tıklandığında
                                addFoodToMeal(mealIndex, item); // Seçilen yiyeceği ekle
                                Navigator.pop(context); // Diyalogu kapat
                              },
                            );
                          },
                        ),
                      ),
                    ],
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