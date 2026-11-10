import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker/core/nutrition/nutrition_values.dart';
import 'package:calorie_tracker/core/nutrition/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator', () {
    const cookedRice = NutritionValues(
      calories: 130,
      protein: 2.7,
      carbohydrates: 28,
      fat: 0.3,
    );

    test('calculates nutrition for 200g of rice', () {
      final result = NutritionCalculator.calculate(
        per100g: cookedRice,
        weightInGrams: 200,
      );

      expect(result.calories, 260);
      expect(result.protein, 5.4);
      expect(result.carbohydrates, 56);
      expect(result.fat, 0.6);
    });

    test('calculates nutrition for 50g of rice', () {
      final result = NutritionCalculator.calculate(
        per100g: cookedRice,
        weightInGrams: 50,
      );

      expect(result.calories, 65);
      expect(result.protein, 1.35);
      expect(result.carbohydrates, 14);
      expect(result.fat, 0.15);
    });

    test('returns zero nutrition for zero grams', () {
      final result = NutritionCalculator.calculate(
        per100g: cookedRice,
        weightInGrams: 0,
      );

      expect(result.calories, 0);
      expect(result.protein, 0);
      expect(result.carbohydrates, 0);
      expect(result.fat, 0);
    });

    test('rejects negative food weight', () {
      expect(
        () => NutritionCalculator.calculate(
          per100g: cookedRice,
          weightInGrams: -100,
        ),
        throwsArgumentError,
      );
    });
  });
}
