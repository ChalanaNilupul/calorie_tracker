import 'nutrition_values.dart';

class NutritionCalculator {
  static NutritionValues calculate({
    required NutritionValues per100g,
    required double weightInGrams,
  }) {
    if (weightInGrams < 0) {
      throw ArgumentError('Food weight cannot be negative');
    }

    final multiplier = weightInGrams / 100;

    return NutritionValues(
      calories: per100g.calories * multiplier,
      protein: per100g.protein * multiplier,
      carbohydrates: per100g.carbohydrates * multiplier,
      fat: per100g.fat * multiplier,
    );
  }
}
