import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/friends.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:yakkit_calorie_tracker/services/user_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:yakkit_calorie_tracker/services/notification_service.dart';
import 'screens/photo_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = const FlutterSecureStorage();
  String? token = await storage.read(key: UserService.accessTokenKey);
  // Zaman dilimi desteğini başlat
  tz.initializeTimeZones(); // Timezone verilerini yükle
  try {
    // Cihazın yerel zaman dilimini flutter_native_timezone paketini kullanarak al
    final String localTimeZoneName = await FlutterTimezone.getLocalTimezone();
    // tz paketine bu zaman dilimini "yerel" olarak ayarla
    tz.setLocalLocation(tz.getLocation(localTimeZoneName));
  } catch (e) {
    // Zaman dilimi alınamazsa veya başka bir hata olursa
    print('Yerel zaman dilimi alınamadı: $e');
    // Genellikle UTC gibi varsayılan bir zaman dilimine düşmek iyi bir pratiktir.
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // === Eğer bildirim izni istiyorsanız buraya eklemelisiniz ===
  await NotificationService.initialize(); // NotificationService'i başlattığınız varsayıldı
  // // Android 13+ izni için (Platform kontrolü ile birlikte)
  // if (Platform.isAndroid) { // dart:io importu gerekli
  await NotificationService.requestAndroid13Permissions(); // NotificationService'deki metodunuz
  // }
  //

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yakkit Calorie Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Eğer kullanıcı giriş yapmışsa ana ekran (MainScreen), aksi halde giriş ekranı (LoginPage) açılır.
      home: isLoggedIn ? const MainScreen() : const LoginPage(),
    );
  }
}

/// MainScreen: HomePage, ProfilePage ve FriendsPage arasında geçiş yapar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1) HomePage'i initialPage olarak ayarlıyoruz
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1; // 0: Photo, 1: Home, 2: Profile, 3: Friends
  void _goToHomePage() {
        _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() {
          _currentPage = index;
        }),
        children:   [
          PhotoPage(onDone: _goToHomePage),    // index 0
          HomePage(),     // index 1
          ProfilePage(),  // index 2
          FriendsPage(),  // index 3
        ],
      ),

      // 2) Alt çubuğu yalnızca _currentPage 1–3 arasında gösteriyoruz
      bottomNavigationBar: (_currentPage == 0)
          ? null
          : BottomNavigationBar(
        // 3) currentIndex'i _currentPage-1 ile kaydırıyoruz
        currentIndex: _currentPage - 1,
        onTap: (barIndex) {
          final pageIndex = barIndex + 1; // barIndex 0->1,1->2,2->3
          _pageController.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentPage = pageIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Günlük"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Arkadaşlar"),
        ],
      ),
    );
  }
}
