import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';

class ProgressScreen extends StatefulWidget {
  final AppDatabase database;

  const ProgressScreen({super.key, required this.database});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _caloriesController = TextEditingController(text: '2000');
  final _proteinController = TextEditingController(text: '100');
  final _carbsController = TextEditingController(text: '250');
  final _fatController = TextEditingController(text: '65');

  bool _loading = true;
  bool _saving = false;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await widget.database.getNutritionGoals();

      if (!mounted) return;

      if (goals != null) {
        _caloriesController.text = _formatValue(goals.calories);
        _proteinController.text = _formatValue(goals.protein);
        _carbsController.text = _formatValue(goals.carbohydrates);
        _fatController.text = _formatValue(goals.fat);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load goals: $error')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String? _validateValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a target';
    }

    final number = double.tryParse(value.trim());

    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a number greater than zero';
    }

    return null;
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.database.saveNutritionGoals(
        calories: double.parse(_caloriesController.text.trim()),
        protein: double.parse(_proteinController.text.trim()),
        carbohydrates: double.parse(_carbsController.text.trim()),
        fat: double.parse(_fatController.text.trim()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrition goals saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save goals: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _changeDate(int days) {
    final newDate = DateUtils.dateOnly(_selectedDate.add(Duration(days: days)));

    final today = DateUtils.dateOnly(DateTime.now());

    if (newDate.isAfter(today)) return;

    setState(() => _selectedDate = newDate);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select progress date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateUtils.dateOnly(picked);
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<DiaryEntry>>(
      stream: widget.database.watchEntriesForDay(_selectedDate),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <DiaryEntry>[];

        final calories = entries.fold<double>(
          0,
          (sum, entry) => sum + entry.calories,
        );

        final protein = entries.fold<double>(
          0,
          (sum, entry) => sum + entry.protein,
        );

        final carbs = entries.fold<double>(
          0,
          (sum, entry) => sum + entry.carbohydrates,
        );

        final fat = entries.fold<double>(0, (sum, entry) => sum + entry.fat);

        final goals = _readCurrentGoals();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202820),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See how your daily nutrition compares with your goals.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildDateSelector(),

                  const SizedBox(height: 24),

                  if (snapshot.hasError)
                    Text('Could not load diary: ${snapshot.error}')
                  else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _buildCaloriesCard(calories, goals.calories),

                    const SizedBox(height: 20),

                    const Text(
                      'Macronutrients',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202820),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildMacroCard(
                      title: 'Protein',
                      consumed: protein,
                      target: goals.protein,
                      unit: 'g',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.protein,
                    ),

                    const SizedBox(height: 12),

                    _buildMacroCard(
                      title: 'Carbohydrates',
                      consumed: carbs,
                      target: goals.carbohydrates,
                      unit: 'g',
                      icon: Icons.grain_rounded,
                      color: AppColors.carbs,
                    ),

                    const SizedBox(height: 12),

                    _buildMacroCard(
                      title: 'Fat',
                      consumed: fat,
                      target: goals.fat,
                      unit: 'g',
                      icon: Icons.water_drop_rounded,
                      color: AppColors.fat,
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      'Daily nutrition goals',
                      'You can change these targets anytime.',
                    ),

                    const SizedBox(height: 18),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildGoalField(
                            title: 'Daily calories',
                            subtitle: 'Your daily energy target',
                            unit: 'kcal',
                            icon: Icons.local_fire_department_rounded,
                            controller: _caloriesController,
                          ),
                          const SizedBox(height: 14),
                          _buildGoalField(
                            title: 'Protein',
                            subtitle: 'Daily protein target',
                            unit: 'g',
                            icon: Icons.fitness_center_rounded,
                            controller: _proteinController,
                          ),
                          const SizedBox(height: 14),
                          _buildGoalField(
                            title: 'Carbohydrates',
                            subtitle: 'Daily carbohydrate target',
                            unit: 'g',
                            icon: Icons.grain_rounded,
                            controller: _carbsController,
                          ),
                          const SizedBox(height: 14),
                          _buildGoalField(
                            title: 'Fat',
                            subtitle: 'Daily fat target',
                            unit: 'g',
                            icon: Icons.water_drop_rounded,
                            controller: _fatController,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveGoals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save nutrition goals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

  _NutritionTargets _readCurrentGoals() {
    return _NutritionTargets(
      calories: double.tryParse(_caloriesController.text) ?? 2000,
      protein: double.tryParse(_proteinController.text) ?? 100,
      carbohydrates: double.tryParse(_carbsController.text) ?? 250,
      fat: double.tryParse(_fatController.text) ?? 65,
    );
  }

  Widget _buildDateSelector() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
      _selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      isToday
                          ? 'Today'
                          : isYesterday
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
            onPressed: isToday ? null : () => _changeDate(1),
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
    );
  }

  Widget _buildCaloriesCard(double consumed, double target) {
    final progress = (consumed / target).clamp(0.0, 1.0);
    final remaining = (target - consumed).clamp(0.0, double.infinity);
    final exceeded = consumed > target;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                consumed.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7, left: 7),
                child: Text(
                  '/ ${target.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exceeded
                ? '${(consumed - target).toStringAsFixed(0)} kcal above your target'
                : '${remaining.toStringAsFixed(0)} kcal remaining',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required double consumed,
    required double target,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final progress = (consumed / target).clamp(0.0, 1.0);
    final remaining = (target - consumed).clamp(0.0, double.infinity);
    final exceeded = consumed > target;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFECEFE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202820),
                  ),
                ),
              ),
              Text(
                '${consumed.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF202820),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            exceeded
                ? '${(consumed - target).toStringAsFixed(1)} $unit above target'
                : '${remaining.toStringAsFixed(1)} $unit remaining',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF202820),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildGoalField({
    required String title,
    required String subtitle,
    required String unit,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFE9)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.primary, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202820),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 94,
            child: TextFormField(
              controller: controller,
              validator: _validateValue,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                suffixText: unit,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorStyle: const TextStyle(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTargets {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;

  const _NutritionTargets({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
  });
}
