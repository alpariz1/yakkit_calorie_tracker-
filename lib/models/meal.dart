import 'food_item.dart';

class Meal {
  final String name;
  int totalCalories;
  List<FoodItem> items;

  Meal({required this.name, this.totalCalories = 0, List<FoodItem>? items})
      : items = items ?? [];

  void addFoodItem(FoodItem item) {
    items.add(item);
    totalCalories += item.calories;
  }
}
