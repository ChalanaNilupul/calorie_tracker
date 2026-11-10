import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';

class DashboardScreen extends StatelessWidget {
  final AppDatabase database;
  final VoidCallback onOpenDiary;
  final VoidCallback onEditGoals;

  const DashboardScreen({
    super.key,
    required this.database,
    required this.onOpenDiary,
    required this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    return StreamBuilder<NutritionGoal?>(
      stream: database.watchNutritionGoals(),
      builder: (context, goalSnapshot) {
        final goals = goalSnapshot.data;

        final calorieGoal = goals?.calories ?? 2000.0;
        final proteinGoal = goals?.protein ?? 100.0;
        final carbsGoal = goals?.carbohydrates ?? 250.0;
        final fatGoal = goals?.fat ?? 65.0;

        return StreamBuilder<List<DiaryEntry>>(
          stream: database.watchEntriesForDay(today),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? <DiaryEntry>[];

            final calories = _total(entries, (entry) => entry.calories);
            final protein = _total(entries, (entry) => entry.protein);
            final carbs = _total(entries, (entry) => entry.carbohydrates);
            final fat = _total(entries, (entry) => entry.fat);

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 115),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),

                      const SizedBox(height: 28),

                      _buildCalorieCard(calories: calories, goal: calorieGoal),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: _MacroCard(
                              icon: Icons.grain_rounded,
                              amount: _remaining(carbsGoal, carbs),
                              label: 'Carbs left',
                              color: AppColors.carbs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MacroCard(
                              icon: Icons.fitness_center_rounded,
                              amount: _remaining(proteinGoal, protein),
                              label: 'Protein left',
                              color: AppColors.protein,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MacroCard(
                              icon: Icons.water_drop_rounded,
                              amount: _remaining(fatGoal, fat),
                              label: 'Fat left',
                              color: AppColors.fat,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Today's meals",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onOpenDiary,
                            child: const Text('See all'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Could not load today’s meals.'),
                        )
                      else if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        _buildMealCard(
                          meal: 'Breakfast',
                          icon: Icons.free_breakfast_rounded,
                          color: AppColors.carbs,
                          entries: _mealEntries(entries, 'Breakfast'),
                        ),
                        const SizedBox(height: 12),
                        _buildMealCard(
                          meal: 'Lunch',
                          icon: Icons.lunch_dining_rounded,
                          color: AppColors.primary,
                          entries: _mealEntries(entries, 'Lunch'),
                        ),
                        const SizedBox(height: 12),
                        _buildMealCard(
                          meal: 'Dinner',
                          icon: Icons.dinner_dining_rounded,
                          color: AppColors.fat,
                          entries: _mealEntries(entries, 'Dinner'),
                        ),
                        const SizedBox(height: 12),
                        _buildMealCard(
                          meal: 'Snacks',
                          icon: Icons.cookie_rounded,
                          color: AppColors.protein,
                          entries: _mealEntries(entries, 'Snacks'),
                        ),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: onOpenDiary,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Add food to diary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static double _total(
    List<DiaryEntry> entries,
    double Function(DiaryEntry) selector,
  ) {
    return entries.fold<double>(0, (total, entry) => total + selector(entry));
  }

  static double _remaining(double goal, double consumed) {
    return (goal - consumed).clamp(0.0, double.infinity);
  }

  static List<DiaryEntry> _mealEntries(List<DiaryEntry> entries, String meal) {
    return entries.where((entry) => entry.mealType == meal).toList();
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'Good morning!'
        : hour < 17
        ? 'Good afternoon!'
        : 'Good evening!';

    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFD3E9DC),
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Your daily nutrition',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _roundButton(Icons.calendar_month_rounded),
        const SizedBox(width: 8),
        _roundButton(Icons.notifications_none_rounded),
      ],
    );
  }

  static Widget _roundButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 21),
    );
  }

  Widget _buildCalorieCard({required double calories, required double goal}) {
    final remaining = _remaining(goal, calories);
    final progress = (calories / goal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daily calories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEditGoals,
                child: const Text('Edit goal'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CalorieGauge(
            consumed: calories,
            goal: goal,
            remaining: remaining,
            progress: progress,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${calories.toStringAsFixed(0)} kcal consumed',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${goal.toStringAsFixed(0)} kcal goal',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String meal,
    required IconData icon,
    required Color color,
    required List<DiaryEntry> entries,
  }) {
    final calories = _total(entries, (entry) => entry.calories);

    final description = entries.isEmpty
        ? 'No meals added yet'
        : entries.length == 1
        ? entries.first.foodName
        : '${entries.first.foodName} + ${entries.length - 1} more';

    return _MealCard(
      icon: icon,
      meal: meal,
      description: description,
      calories: '${calories.toStringAsFixed(0)} kcal',
      color: color,
      hasEntries: entries.isNotEmpty,
      onTap: onOpenDiary,
    );
  }
}

class _CalorieGauge extends StatelessWidget {
  final double consumed;
  final double goal;
  final double remaining;
  final double progress;

  const _CalorieGauge({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GaugePainter(progress: progress)),
          ),
          Positioned(
            top: 76,
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.carbs,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  remaining.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  consumed > goal ? 'Calories over goal' : 'Calories remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 20;
    const startAngle = 3.141592653589793;
    const totalAngle = 3.141592653589793;

    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.width * 0.39;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < segments; i++) {
      final segmentProgress = (i + 0.5) / segments;
      final isFilled = segmentProgress <= progress;

      final paint = Paint()
        ..color = isFilled ? AppColors.primary : const Color(0xFFEAF3ED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;

      final segmentAngle = totalAngle / segments;
      const gap = 0.045;

      canvas.drawArc(
        rect,
        startAngle + (i * segmentAngle) + gap,
        segmentAngle - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MacroCard extends StatelessWidget {
  final IconData icon;
  final double amount;
  final String label;
  final Color color;

  const _MacroCard({
    required this.icon,
    required this.amount,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 9),
          Text(
            '${amount.toStringAsFixed(0)}g',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final IconData icon;
  final String meal;
  final String description;
  final String calories;
  final Color color;
  final bool hasEntries;
  final VoidCallback onTap;

  const _MealCard({
    required this.icon,
    required this.meal,
    required this.description,
    required this.calories,
    required this.color,
    required this.hasEntries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              calories,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
