import 'nutrition_values.dart';

enum FoodPreparation { raw, cooked, readyToEat, dried }

class FoodItem {
  final String id;
  final String name;
  final String? sinhalaName;
  final String? tamilName;
  final String category;

  final FoodPreparation preparation;

  // Nutrition values per 100g of edible food.
  final NutritionValues nutritionPer100g;

  // Where the nutrition information came from.
  final String sourceName;
  final String? sourceReference;

  const FoodItem({
    required this.id,
    required this.name,
    this.sinhalaName,
    this.tamilName,
    required this.category,
    required this.preparation,
    required this.nutritionPer100g,
    required this.sourceName,
    this.sourceReference,
  });
}
