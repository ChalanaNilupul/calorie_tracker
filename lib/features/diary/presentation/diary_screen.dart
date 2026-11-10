import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/food_repository.dart';
import '../../../core/nutrition/food_item.dart';
import '../../../core/nutrition/nutrition_calculator.dart';

class DiaryScreen extends StatefulWidget {
  final AppDatabase database;

  const DiaryScreen({super.key, required this.database});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final FoodRepository _repository = FoodRepository();
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  bool get _isSelectedDateToday =>
      DateUtils.isSameDay(_selectedDate, DateTime.now());

  static const List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    final newDate = DateUtils.dateOnly(_selectedDate.add(Duration(days: days)));

    final today = DateUtils.dateOnly(DateTime.now());

    if (newDate.isAfter(today)) return;

    setState(() {
      _selectedDate = newDate;
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select diary date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateUtils.dateOnly(picked);
    });
  }

  // Open a separate food-search bottom sheet.
  Future<void> _openFoodSearch() async {
    _searchController.clear();

    final selectedFood = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final foods = _repository.search(query);

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Add food',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Search for a food to add to your diary',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setSheetState(() {
                        query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search rice, dhal, chicken...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '${foods.length} foods available',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: foods.isEmpty
                        ? const Center(
                            child: Text(
                              'No foods found. Try another search.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: foods.length,
                            itemBuilder: (context, index) {
                              final food = foods[index];

                              return _FoodCard(
                                food: food,
                                onTap: () {
                                  Navigator.pop(sheetContext, food);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedFood == null) return;

    await _selectFood(selectedFood);
  }

  // Select quantity and meal type.
  Future<void> _selectFood(FoodItem food) async {
    final controller = TextEditingController(text: '100');

    String selectedMealType = 'Breakfast';

    final result = await showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final weight = double.tryParse(controller.text) ?? 0;

            final nutrition = NutritionCalculator.calculate(
              per100g: food.nutritionPer100g,
              weightInGrams: weight > 0 ? weight : 0,
            );

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${food.category} • ${_preparationLabel(food.preparation)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Enter food weight',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Weight in grams',
                        suffixText: 'grams',
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Select meal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _mealTypes
                          .map(
                            (meal) => DropdownMenuItem(
                              value: meal,
                              child: Text(meal),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedMealType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${nutrition.calories.toStringAsFixed(1)} kcal',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),

                          const Text(
                            'Estimated nutrition for this quantity',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NutritionValue(
                                label: 'Protein',
                                value: nutrition.protein,
                                color: AppColors.protein,
                              ),
                              _NutritionValue(
                                label: 'Carbs',
                                value: nutrition.carbohydrates,
                                color: AppColors.carbs,
                              ),
                              _NutritionValue(
                                label: 'Fat',
                                value: nutrition.fat,
                                color: AppColors.fat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: weight > 0
                            ? () {
                                Navigator.pop(context, (
                                  weight,
                                  selectedMealType,
                                ));
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add to diary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) return;

    final grams = result.$1;
    final mealType = result.$2;

    final nutrition = NutritionCalculator.calculate(
      per100g: food.nutritionPer100g,
      weightInGrams: grams,
    );

    try {
      await widget.database.addDiaryEntry(
        DiaryEntriesCompanion.insert(
          foodId: food.id,
          foodName: food.name,
          foodCategory: food.category,
          preparation: food.preparation.name,
          mealType: mealType,
          loggedAt: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            DateTime.now().hour,
            DateTime.now().minute,
            DateTime.now().second,
          ),
          weightInGrams: grams,
          calories: nutrition.calories,
          protein: nutrition.protein,
          carbohydrates: nutrition.carbohydrates,
          fat: nutrition.fat,
          sourceName: food.sourceName,
          sourceReference: Value(food.sourceReference),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food.name} added to $mealType'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save food: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Edit an existing diary entry.
  Future<void> _editEntry(DiaryEntry entry) async {
    final controller = TextEditingController(
      text: entry.weightInGrams.toString(),
    );

    String selectedMealType = entry.mealType;

    final result = await showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final grams = double.tryParse(controller.text) ?? 0;
            final multiplier = grams > 0 && entry.weightInGrams > 0
                ? grams / entry.weightInGrams
                : 0.0;

            final calories = entry.calories * multiplier;
            final protein = entry.protein * multiplier;
            final carbs = entry.carbohydrates * multiplier;
            final fat = entry.fat * multiplier;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit ${entry.foodName}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      'Quantity (grams)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'grams',
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Meal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _mealTypes.map((meal) {
                        return DropdownMenuItem(value: meal, child: Text(meal));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedMealType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${calories.toStringAsFixed(1)} kcal',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NutritionValue(
                                label: 'Protein',
                                value: protein,
                                color: AppColors.protein,
                              ),
                              _NutritionValue(
                                label: 'Carbs',
                                value: carbs,
                                color: AppColors.carbs,
                              ),
                              _NutritionValue(
                                label: 'Fat',
                                value: fat,
                                color: AppColors.fat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: grams > 0 && entry.weightInGrams > 0
                            ? () {
                                Navigator.pop(sheetContext, (
                                  grams,
                                  selectedMealType,
                                ));
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) return;

    final grams = result.$1;
    final mealType = result.$2;
    final multiplier = grams / entry.weightInGrams;

    try {
      final updated = await widget.database.updateDiaryEntry(
        entry.id,
        DiaryEntriesCompanion(
          weightInGrams: Value(grams),
          mealType: Value(mealType),
          calories: Value(entry.calories * multiplier),
          protein: Value(entry.protein * multiplier),
          carbohydrates: Value(entry.carbohydrates * multiplier),
          fat: Value(entry.fat * multiplier),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? '${entry.foodName} updated successfully'
                : 'Entry not found',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update food: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Delete a saved diary entry.
  Future<void> _deleteEntry(int id) async {
    try {
      await widget.database.deleteDiaryEntry(id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete entry: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _preparationLabel(FoodPreparation preparation) {
    switch (preparation) {
      case FoodPreparation.raw:
        return 'Raw';
      case FoodPreparation.cooked:
        return 'Cooked';
      case FoodPreparation.readyToEat:
        return 'Ready to eat';
      case FoodPreparation.dried:
        return 'Dried';
    }
  }

  // Build an individual meal section.
  Widget _buildMealSection(String meal, List<DiaryEntry> entries) {
    final mealCalories = entries.fold<double>(
      0,
      (total, entry) => total + entry.calories,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              Text(
                '${mealCalories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No foods added yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ...entries.map(
              (entry) => _DiaryFoodTile(
                entry: entry,
                onDelete: () => _deleteEntry(entry.id),
                onEdit: () => _editEntry(entry),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiaryEntry>>(
      stream: widget.database.watchEntriesForDay(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text('Could not load diary: ${snapshot.error}'),
            ),
          );
        }

        final loggedFoods = snapshot.data ?? <DiaryEntry>[];

        final totalCalories = loggedFoods.fold<double>(
          0,
          (total, entry) => total + entry.calories,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Food Diary',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Track what you eat throughout the day',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeDate(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),

                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Text(
                                    _isSelectedDateToday
                                        ? 'Today'
                                        : DateUtils.isSameDay(
                                            _selectedDate,
                                            DateTime.now().subtract(
                                              const Duration(days: 1),
                                            ),
                                          )
                                        ? 'Yesterday'
                                        : 'Selected date',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    MaterialLocalizations.of(context)
                                        .formatMediumDate(_selectedDate),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: _isSelectedDateToday
                              ? null
                              : () => _changeDate(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),

                        IconButton(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Daily calories.
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSelectedDateToday
                                    ? "Today's intake"
                                    : 'Daily intake',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Total calories consumed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          '${totalCalories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Add food button.
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _openFoodSearch,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add food',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isSelectedDateToday ? "Today's meals" : 'Meals',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      Text(
                        '${loggedFoods.length} foods',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    ..._mealTypes.map(
                      (meal) => _buildMealSection(
                        meal,
                        loggedFoods
                            .where((entry) => entry.mealType == meal)
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Food search result card.
class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _FoodCard({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceSoft,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        title: Text(
          food.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text('${food.category} • ${food.preparation.name}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${food.nutritionPer100g.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'per 100g',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Logged food tile.
class _DiaryFoodTile extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DiaryFoodTile({
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.weightInGrams.toStringAsFixed(0)} g',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Nutrition preview values.
class _NutritionValue extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _NutritionValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
