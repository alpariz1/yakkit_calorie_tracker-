// lib/services/notification_service.dart (Android Only)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // Platform.isAndroid için gerekli
// Removed iOS imports and settings

// --- Zaman Dilimi Notu ---
// Bu servis, bildirimleri zaman dilimini dikkate alarak planlamak için
// 'timezone' paketindeki 'tz.local' zaman dilimini kullanır.
// 'tz.local' nesnesinin, cihazın gerçek yerel zaman dilimine ayarlanması
// uygulamanın başlangıcında (genellikle main.dart dosyasında)
// 'flutter_native_timezone' paketi kullanılarak yapılmalıdır.
// Bu dosya doğrudan native zaman dilimi adını ALMAZ,
// main.dart'ta ayarlanmış olan 'tz.local'ı KULLANIR.


class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Bildirim servisini başlatır (Sadece Android). Genellikle main.dart'ta çağırılır.
  static Future<void> initialize({
    // Bildirime tıklandığında tetiklenen callback.
    Future<dynamic> Function(NotificationResponse notificationResponse)? onDidReceiveNotificationResponse,
    // Background'da tıklamalar için (gerekirse ve top-level fonksiyon olmalı):
    // Future<dynamic> Function(NotificationResponse notificationResponse)? onDidReceiveBackgroundNotificationResponse,
  }) async {
    // --- Android İçin Başlangıç Ayarları ---
    // '@mipmap/ic_launcher' projenizdeki uygulama ikonuna referans verir.
    const androidInitializeSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // InitializationSettings artık platforma özel nesneleri doğrudan alır
    const initializationSettings = InitializationSettings(
      android: androidInitializeSettings,
      // iOS, macOS, Linux ayarları kaldırıldı
    );

    // Plugin'i başlat ve bildirime tıklama callback'lerini ata
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
  }


  /// Android 13+ için runtime bildirim iznini ister.
  /// Sadece Android >= 13'te etkilidir.
  /// İzin verilirse true, reddedilirse false, izin penceresi gösterilemezse null döner.
  /// Android < 13'te her zaman true döner (izin gerekmediği için).
  static Future<bool?> requestAndroid13Permissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // requestPermission() yerine requestNotificationsPermission() kullanıyoruz
      // Bu API package versiyonuna göre değişebilir.
      return await androidImplementation?.requestNotificationsPermission(); // Veya paketinize uygun metod
    }
    return true; // Diğer platformlarda izin gerektirmez (iOS kısımları kaldırıldı)
  }


  /// Günlük tekrar eden bildirimleri planlar. (Sadece Android)
  /// initialize() ve izin istenmesinden SONRA çağrılmalıdır.
  static Future<void> scheduleDailyNotifications() async {
    // İsteğe bağlı: Planlamadan önce var olanları iptal et.
    // await cancelAllNotifications();

    // Sabah hatırlatması planla
    await _scheduleDaily(
      id: 1,
      title: "Yakkit Hatırlatma",
      body: "Bugün ne yedin?",
      hour: 18, minute: 41,
      payload: 'daily_reminder_10am',
    );

    // Akşam hatırlatması planla
    await _scheduleDaily(
      id: 2,
      title: "Yakkit Hatırlatma",
      body: "Bu akşam ne yediğini girmeyi unutma!",
      hour: 21, minute: 0,
      payload: 'daily_reminder_9pm',
    );

    print("Günlük hatırlatmalar planlandı.");
  }

  // Belirli bir saat/dakika için günlük bildirim planlayan yardımcı metot (Sadece Android).
  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour, required int minute,
    String? payload,
  }) async {
    // zonedSchedule, zaman dilimini dikkate alarak planlama yapar.
    // Burada kullanılan 'tz.local', main.dart'ta flutter_native_timezone ile
    // ayarlanmış olan yerel zaman dilimidir.
    await _plugin.zonedSchedule(
      id, title, body,
      _nextInstanceOf(hour, minute), // Bir sonraki gösterim zamanı (yerel tz)
      // --- Android Bildirim Detayları ---
      // IOSNotificationDetails kaldırıldı.
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel', 'Günlük Hatırlatmalar', // Kanal ID ve Adı
          channelDescription: 'Her gün planlanan hatırlatma bildirimleri', // Kanal Açıklaması
          importance: Importance.defaultImportance, priority: Priority.defaultPriority,
          // icon: '@mipmap/ic_launcher', // İsteğe bağlı küçük ikon
        ),
        // iOS detayları kaldırıldı
      ),
      // --- Yeni Planlama Modu ---
      // androidAllowWhileIdle kaldırıldı, yerine androidScheduleMode geldi
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Tam saatte ve cihaz boşta olsa bile ateşlensin
      // uiLocalNotificationDateInterpretation kaldırıldı, artık gerekli değil veya başka bir yerde ayarlanıyor
      matchDateTimeComponents: DateTimeComponents.time, // Günlük tekrar (saat/dakika eşleşince)
      payload: payload, // Tıklama callback'ine iletilir
    );
  }

  // Belirtilen saat ve dakikanın yerel zaman dilimindeki bir sonraki oluşumunu hesaplar.
  // tz.local'ın main.dart'ta ayarlanmış olması gerekir.
  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // === Bildirimleri İptal Etme Metotları ===

  /// Planlanmış tüm bildirimleri iptal eder.
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print("Tüm planlanmış bildirimler iptal edildi.");
  }

  /// Belirli bir ID'ye sahip planlanmış bildirimi iptal eder.
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    print("Planlanmış bildirim (ID: $id) iptal edildi.");
  }
}