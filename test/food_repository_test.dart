import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/core/database/food_repository.dart';
import 'package:calorie_tracker/core/nutrition/food_item.dart';

void main() {
  late FoodRepository repository;

  setUp(() {
    repository = FoodRepository();
  });

  test('loads initial food records', () {
    expect(repository.allFoods.length, 7);
  });

  test('searches food by name', () {
    final results = repository.search('chicken');

    expect(results.length, 1);
    expect(results.first.name, 'Chicken Curry');
  });

  test('searches food by category', () {
    final results = repository.search('rice');

    expect(results.length, 4);
  });

  test('gets food by ID', () {
    final food = repository.getById('rice_samba_boiled');

    expect(food, isNotNull);
    expect(food!.name, 'Samba Rice');
  });

  test('filters cooked foods', () {
    final results = repository.getByPreparation(FoodPreparation.cooked);

    expect(results.length, 4);
  });

  test('returns null for unknown food ID', () {
    expect(repository.getById('unknown'), isNull);
  });
}
