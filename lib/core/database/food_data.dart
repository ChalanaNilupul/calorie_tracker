import '../nutrition/food_item.dart';
import '../nutrition/nutrition_values.dart';

const String sriLankanStudy =
    'Opatha et al. (2025) - Sri Lankan Food Composition Database';

const String studyReference = 'https://doi.org/10.1016/j.jfca.2025.107230';

final List<FoodItem> initialFoods = [
  const FoodItem(
    id: 'rice_white_kekulu_boiled',
    name: 'White Kekulu Rice',
    category: 'Rice',
    preparation: FoodPreparation.cooked,
    nutritionPer100g: NutritionValues(
      calories: 116,
      protein: 3.19,
      carbohydrates: 24.73,
      fat: 0.49,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'rice_red_kekulu_boiled',
    name: 'Red Kekulu Rice',
    category: 'Rice',
    preparation: FoodPreparation.cooked,
    nutritionPer100g: NutritionValues(
      calories: 121,
      protein: 2.85,
      carbohydrates: 25.61,
      fat: 0.70,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'rice_white_nadu_boiled',
    name: 'White Nadu Rice',
    category: 'Rice',
    preparation: FoodPreparation.cooked,
    nutritionPer100g: NutritionValues(
      calories: 131,
      protein: 2.78,
      carbohydrates: 28.71,
      fat: 0.53,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'rice_samba_boiled',
    name: 'Samba Rice',
    category: 'Rice',
    preparation: FoodPreparation.cooked,
    nutritionPer100g: NutritionValues(
      calories: 131,
      protein: 2.43,
      carbohydrates: 28.20,
      fat: 0.87,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'chicken_curry',
    name: 'Chicken Curry',
    category: 'Curry',
    preparation: FoodPreparation.readyToEat,
    nutritionPer100g: NutritionValues(
      calories: 123.82,
      protein: 15.29,
      carbohydrates: 3.03,
      fat: 4.78,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'dhal_curry_thick',
    name: 'Thick Dhal Curry',
    category: 'Curry',
    preparation: FoodPreparation.readyToEat,
    nutritionPer100g: NutritionValues(
      calories: 129.43,
      protein: 7.51,
      carbohydrates: 16.49,
      fat: 2.36,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
  const FoodItem(
    id: 'dhal_curry_watery',
    name: 'Watery Dhal Curry',
    category: 'Curry',
    preparation: FoodPreparation.readyToEat,
    nutritionPer100g: NutritionValues(
      calories: 93.77,
      protein: 5.17,
      carbohydrates: 11.42,
      fat: 2.20,
    ),
    sourceName: sriLankanStudy,
    sourceReference: studyReference,
  ),
];
