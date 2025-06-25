// lib/models/user_info.dart
/*class UserInfo {
  final String username;
  final double height;
  final double weight;
  final String birthDate;    // ISO formatında, örn "1990-05-12"
  final String goal;
  final int age;
  final double dailyCalories;

  UserInfo({
    required this.username,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.goal,
    required this.age,
    required this.dailyCalories,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username:      json['username'] as String,
      height:        (json['height'] as num).toDouble(),
      weight:        (json['weight'] as num).toDouble(),
      birthDate:     json['birth_date'] as String,
      goal:          json['goal'] as String,
      age:           json['age'] as int,
      dailyCalories: (json['daily_calories'] as num).toDouble(),
    );
  }
}
*/