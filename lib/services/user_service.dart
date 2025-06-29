
/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

// ... (UserInfo and FriendRequest classes remain the same as provided by the user)
class UserInfo {
  final int id;
  final String username;
  final String email;
  final double height;
  final double weight;
  final String birthDate; // ISO format
  final String goal;
  final int age;
  final int dailyCalories;
  final String? profileImageBase64;  // base64-encoded image, if any

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.goal,
    required this.age,
    required this.dailyCalories,
    this.profileImageBase64,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    String normalizeNumber(dynamic value) =>
        value?.toString().replaceAll(',', '.') ?? '0';

    return UserInfo(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      height: double.tryParse(normalizeNumber(json['height'])) ?? 0,
      weight: double.tryParse(normalizeNumber(json['weight'])) ?? 0,
      birthDate: json['birth_date'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      age: int.tryParse(normalizeNumber(json['age'])) ?? 0,
      dailyCalories:
      double.tryParse(normalizeNumber(json['daily_calories']))?.toInt() ?? 0,
      profileImageBase64: json['profile_image'] as String?,
    );
  }
}
/// Model: arkadaşlık isteği (istek atan, istek id’si vs.)
class FriendRequest {
  final int id;
  final int fromUserId;
  final String fromUsername;
  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
  });
  factory FriendRequest.fromJson(Map<String,dynamic> json) => FriendRequest(
    id: json['id'],
    fromUserId: json['from_user_id'],
    fromUsername: json['from_username'],
  );
}


/// Service to interact with the backend's user endpoints.
class UserService {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Fetches the current user's profile data from /userinfo.
  static Future<UserInfo> getUserInfo() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // Token yoksa, kullanıcı giriş yapmamış demektir. Özel bir exception fırlatılabilir.
      throw Exception('Authentication required: JWT token not found.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserInfo.fromJson(data);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Yetkilendirme hatası durumunda tokenı temizle ve hata fırlat
      await clearStorage();
      throw Exception('Authentication failed: ${response.statusCode}. Please log in again.');
    }
    else {
      throw Exception('Kullanıcı bilgileri yüklenemedi: ${response.statusCode}');
    }
  }

  /// Uploads a new profile photo for the given user.
  static Future<void> uploadPhoto(int userId, XFile image) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');

    final uri = Uri.parse('$_baseUrl/users/$userId/upload-photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      print('Fotoğraf başarıyla yüklendi.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed during photo upload: ${response.statusCode}. Please log in again.');
    } else {
      final responseBody = await response.stream.bytesToString();
      print('Fotoğraf yükleme hatası: ${response.statusCode}. Detay: $responseBody');
      throw Exception('Fotoğraf yüklenemedi: ${response.statusCode}');
    }
  }

  /// Arkadaş listesini getirir.
  static Future<List<UserInfo>> getFriends() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/friends'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserInfo.fromJson(e as Map<String, dynamic>)).toList(); // Tip belirtildi
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while fetching friends: ${response.statusCode}. Please log in again.');
    }
    else {
      throw Exception('Arkadaş listesi yüklenemedi: ${response.statusCode}');
    }
  }
  /// Sends a friend‐request (doesn't immediately make you “friends”)
  static Future<void> sendFriendRequest(int toUserId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');

    final response = await http.post(
      Uri.parse('$_baseUrl/users/me/friend-requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'to_user_id': toUserId}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Arkadaşlık isteği gönderildi.');
    }
    else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while sending friend request: ${response.statusCode}. Please log in again.');
    }
    else {
      throw Exception('Arkadaşlık isteği gönderilemedi: ${response.statusCode}');
    }
  }

  /// Belirtilen userId'yi arkadaş olarak ekler. (Sanırım bu kabul etme endpointi, isim kontrolü yapın)
  static Future<void> addFriend(int friendId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');
    final response = await http.post(
      Uri.parse('$_baseUrl/users/me/friends/$friendId'), // Endpoint doğru mu kontrol edin
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Body gönderilmiyor ama content type olabilir.
      },
      // Body boş olabilir veya kabul isteği ID'si gibi bir şey içerebilir. Backend'e göre ayarlayın.
    );
    if (response.statusCode == 200) {
      print('Arkadaş başarıyla eklendi.');
    }
    else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while adding friend: ${response.statusCode}. Please log in again.');
    }
    else {
      throw Exception('Arkadaş eklenemedi: ${response.statusCode}');
    }
  }

  /// Belirtilen userId'yi arkadaş listesinden çıkarır.
  static Future<void> removeFriend(int friendId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/me/friends/$friendId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 204) {
      print('Arkadaş başarıyla silindi.');
    }
    else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while removing friend: ${response.statusCode}. Please log in again.');
    }
    else {
      throw Exception('Arkadaş silinemedi: ${response.statusCode}');
    }
  }

  static Future<UserInfo?> findUserByUsername(String username) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');
    final response = await http.get(
      Uri.parse('$_baseUrl/users/search?username=$username'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      return UserInfo.fromJson(list.first as Map<String,dynamic>);
    }
    else if (response.statusCode == 401 || response.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while searching user: ${response.statusCode}. Please log in again.');
    }
    else {
      // Arama sonucu yoksa 200 boş list dönebilir, hata ise farklı status code olur
      print('Kullanıcı arama hatası: ${response.statusCode}');
      return null; // Arama hatasında null veya hata fırlatılabilir
    }
  }

  /// 2) Arkadaş ekleme (id ile) -> Bu metod sanırım addFriend ile aynı işi yapıyor, kontrol edin ve fazlalığı kaldırın.
  // static Future<void> addFriendById(int friendId) =>
  //     http.post(
  //       Uri.parse('$_baseUrl/users/me/friends/$friendId'),
  //       headers: {'Authorization':'Bearer ${_storage.read(key:_tokenKey)}'}, // await eksik
  //     ).then((res){
  //       if (res.statusCode != 200) throw Exception('Arkadaş eklenemedi');
  //     });
  // Eğer bu metod addFriend metodundan farklı bir iş yapıyorsa (örn: isteği kabul etme),
  // ismi daha açıklayıcı olmalı ve implementasyonu kontrol edilmelidir.
  // headers içindeki await (_storage.read) de düzeltilmeli.
  // Düzeltilmiş hali (addFriend ile aynı işi yaptığı varsayılarak silindi):

  /// 3) Arkadaş isteklerini getirir
  static Future<List<FriendRequest>> getFriendRequests() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');
    final res = await http.get(
      Uri.parse('$_baseUrl/users/me/friend-requests'),
      headers: {'Authorization':'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e)=>FriendRequest.fromJson(e as Map<String,dynamic>)).toList(); // Tip belirtildi
    }
    else if (res.statusCode == 401 || res.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while fetching friend requests: ${res.statusCode}. Please log in again.');
    }
    else {
      throw Exception('İstekler yüklenemedi: ${res.statusCode}');
    }
  }

  /// 4) İsteğe yanıt ver (kabul/ret)
  static Future<void> respondFriendRequest(int requestId, bool accept) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Authentication required: JWT token not found.');

    final res = await http.post(
      Uri.parse('$_baseUrl/users/me/friend-requests/$requestId/respond'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'accept': accept}),
    );

    if (res.statusCode == 200) {
      print('Arkadaşlık isteğine yanıt verildi.');
    }
    else if (res.statusCode == 401 || res.statusCode == 403) {
      await clearStorage();
      throw Exception('Authentication failed while responding to friend request: ${res.statusCode}. Please log in again.');
    }
    else {
      throw Exception('İşlem başarısız: ${res.statusCode}');
    }
  }

  /// Clears all stored credentials (token, etc.).
  static Future<void> clearStorage() async {
    print("Clearing storage (token).");
    await _storage.deleteAll();
  }

  /// Logs out the user by clearing storage.
  static Future<void> logout() async {
    await clearStorage();
    // Ek logout işlemleri (varsa) buraya eklenebilir
    print("User logged out.");
  }
}*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Model: User information returned from /userinfo
class UserInfo {
  final int id;
  final String username;
  final String email;
  final double height;
  final double weight;
  final String birthDate;
  final String goal;
  final int age;
  final int dailyCalories;
  final String? profileImageBase64;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.goal,
    required this.age,
    required this.dailyCalories,
    this.profileImageBase64,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    String normalize(dynamic v) => v?.toString().replaceAll(',', '.') ?? '0';
    return UserInfo(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      height: double.tryParse(normalize(json['height'])) ?? 0,
      weight: double.tryParse(normalize(json['weight'])) ?? 0,
      birthDate: json['birth_date'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      age: int.tryParse(normalize(json['age'])) ?? 0,
      dailyCalories: double.tryParse(normalize(json['daily_calories']))?.toInt() ?? 0,
      profileImageBase64: json['profile_image'] as String?,
    );
  }
}

/// Model: Friend request returned from /friend-requests
class FriendRequest {
  final int id;
  final int fromUserId;
  final String fromUsername;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int,
      fromUserId: json['from_user_id'] as int,
      fromUsername: json['from_username'] as String,
    );
  }
}

class UserService {
  //static const String baseUrl         = 'http://10.0.2.2:8000';
  //static const String baseUrl         = 'http://192.168.43.171:8000';
  //static const String baseUrl         = 'https://cc8e-176-227-2-12.ngrok-free.app';
  static const String baseUrl         = 'https://api.yakkit.shop';
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static final   _storage             = FlutterSecureStorage();

  /// Logs in the user, stores access and refresh tokens
  static Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _storage.write(key: accessTokenKey,  value: data['access_token'] as String);
      await _storage.write(key: refreshTokenKey, value: data['refresh_token'] as String);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  /// Clears stored tokens
  static Future<void> logout() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }

  /// Refreshes access and refresh tokens
  static Future<void> _refreshTokens() async {
    final refresh = await _storage.read(key: refreshTokenKey);
    if (refresh == null) throw Exception('No refresh token. Please log in again.');
    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refresh}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _storage.write(key: accessTokenKey,  value: data['access_token'] as String);
      await _storage.write(key: refreshTokenKey, value: data['refresh_token'] as String);
    } else {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }
  }

  /// Helper for authenticated requests: retries once after refresh
  static Future<http.Response> _authRequest(
      Future<http.Response> Function(String token) fn) async {
    String? token = await _storage.read(key: accessTokenKey);
    if (token == null) throw Exception('Authentication required.');
    http.Response res = await fn(token);
    if (res.statusCode == 401) {
      await _refreshTokens();
      token = await _storage.read(key: accessTokenKey);
      if (token == null) throw Exception('Session expired.');
      res = await fn(token);
    }
    return res;
  }

  /// Fetches UserInfo
  static Future<UserInfo> getUserInfo() async {
    final res = await _authRequest((token) {
      return http.get(
        Uri.parse('$baseUrl/userinfo'),
        headers: {'Authorization': 'Bearer $token'},
      );
    });
    if (res.statusCode == 200) {
      return UserInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load user info.');
  }

  /// Retrieves friends list
  static Future<List<UserInfo>> getFriends() async {
    final res = await _authRequest((token) {
      return http.get(
        Uri.parse('$baseUrl/users/me/friends'),
        headers: {'Authorization': 'Bearer $token'},
      );
    });
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => UserInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load friends.');
  }

  /// Sends a friend request
  static Future<void> sendFriendRequest(int toUserId) async {
    final res = await _authRequest((token) {
      return http.post(
        Uri.parse('$baseUrl/users/me/friend-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json'
        },
        body: jsonEncode({'to_user_id': toUserId}),
      );
    });
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to send friend request.');
    }
  }

  /// Retrieves pending friend requests
  static Future<List<FriendRequest>> getFriendRequests() async {
    final res = await _authRequest((token) {
      return http.get(
        Uri.parse('$baseUrl/users/me/friend-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
    });
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load friend requests.');
  }

  /// Responds to a friend request
  static Future<void> respondFriendRequest(int requestId, bool accept) async {
    final res = await _authRequest((token) {
      return http.post(
        Uri.parse('$baseUrl/users/me/friend-requests/$requestId/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json'
        },
        body: jsonEncode({'accept': accept}),
      );
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to respond to friend request.');
    }
  }
  /// Clears all secure storage data
  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }
  /// Finds a user by username
  static Future<UserInfo> findUserByUsername(String username) async {
    final res = await _authRequest((token) {
      return http.get(
        Uri.parse('$baseUrl/users/find?username=$username'),
        headers: {'Authorization': 'Bearer $token'},
      );
    });

    if (res.statusCode == 200) {
      return UserInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw Exception('User not found.');
    }

    throw Exception('Failed to find user by username.');
  }
  static Future<http.Response> sendAuthenticatedRequest(
      String method, // 'GET', 'POST', 'PUT' vb.
      Uri uri,
      { Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) async {
    String? token = await _storage.read(key: accessTokenKey);
    if (token == null) throw Exception('Authentication required.');

    // İstek gönderme fonksiyonu
    Future<http.Response> sendRequest(String currentToken) {
      final Map<String, String> authHeaders = {
        'Authorization': 'Bearer $currentToken',
        ...?headers, // Mevcut başlıklara ekle
      };

      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(uri, headers: authHeaders);
        case 'POST':
          return http.post(uri, headers: authHeaders, body: body, encoding: encoding);
        case 'PUT':
          return http.put(uri, headers: authHeaders, body: body, encoding: encoding);
        case 'DELETE':
          return http.delete(uri, headers: authHeaders, body: body, encoding: encoding);
      // Diğer metodlar buraya eklenebilir (PATCH vb.)
        default:
          throw UnsupportedError('HTTP method $method not supported by sendAuthenticatedRequest.');
      }
    }

    http.Response res = await sendRequest(token);

    // Eğer 401 (Unauthorized) alırsak, token'ı yenile ve bir kez daha dene
    if (res.statusCode == 401) {
      try {
        await _refreshTokens();
        token = await _storage.read(key: accessTokenKey);
        if (token == null) {
          // Yenileme sonrası token hala yoksa, login gerekli
          throw Exception('Session expired. Please log in again.');
        }
        // Yenilenen token ile isteği tekrar gönder
        res = await sendRequest(token);

        // Eğer ikinci deneme de 401 değilse (başarılı veya başka bir hata), sonucu döndür
        if (res.statusCode != 401) {
          return res;
        } else {
          // İkinci deneme de 401 ise, hala bir sorun var
          throw Exception('Session expired after refresh. Please log in again.');
        }
      } catch (e) {
        // Token yenileme sırasında hata olursa veya ikinci deneme 401 ise
        await logout(); // Güvenlik için tokenları temizle
        rethrow; // Hatayı fırlat
      }
    }

    // 401 dışında bir status code ise doğrudan sonucu döndür
    return res;
  }
  /// Uploads profile photo
  static Future<void> uploadPhoto(int userId, XFile image) async {
    final token = await _storage.read(key: accessTokenKey);
    if (token == null) throw Exception('Authentication required.');
    //inal req = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/$userId/upload-photo'));
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/$userId/upload-photo'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final resp = await req.send();
    if (resp.statusCode != 200) {
      throw Exception('Failed to upload photo.');
    }
  }
}
