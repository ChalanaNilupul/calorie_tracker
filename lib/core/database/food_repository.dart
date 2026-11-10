import '../nutrition/food_item.dart';
import 'food_data.dart';

class FoodRepository {
  final List<FoodItem> _foods;

  FoodRepository({List<FoodItem>? foods})
    : _foods = List.unmodifiable(foods ?? initialFoods);

  List<FoodItem> get allFoods => _foods;

  FoodItem? getById(String id) {
    for (final food in _foods) {
      if (food.id == id) {
        return food;
      }
    }

    return null;
  }

  List<FoodItem> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return allFoods;
    }

    return _foods.where((food) {
      final name = food.name.toLowerCase();
      final category = food.category.toLowerCase();
      final sinhala = food.sinhalaName?.toLowerCase() ?? '';
      final tamil = food.tamilName?.toLowerCase() ?? '';

      return name.contains(normalizedQuery) ||
          category.contains(normalizedQuery) ||
          sinhala.contains(normalizedQuery) ||
          tamil.contains(normalizedQuery);
    }).toList();
  }

  List<FoodItem> getByCategory(String category) {
    return _foods
        .where((food) => food.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<FoodItem> getByPreparation(FoodPreparation preparation) {
    return _foods.where((food) => food.preparation == preparation).toList();
  }
}
