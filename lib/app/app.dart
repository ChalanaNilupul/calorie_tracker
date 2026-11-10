import 'dart:async';

import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/diary/presentation/diary_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class NutriTrackApp extends StatefulWidget {
  final AppDatabase? database;

  const NutriTrackApp({super.key, this.database});

  @override
  State<NutriTrackApp> createState() => _NutriTrackAppState();
}

class _NutriTrackAppState extends State<NutriTrackApp> {
  late final AppDatabase _database;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();

    _ownsDatabase = widget.database == null;
    _database = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriTrack',
      theme: AppTheme.light,
      home: MainNavigation(database: _database),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final AppDatabase database;

  const MainNavigation({super.key, required this.database});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        database: widget.database,
        onOpenDiary: () {
          setState(() => selectedIndex = 1);
        },
        onEditGoals: () {
          setState(() => selectedIndex = 2);
        },
      ),
      DiaryScreen(database: widget.database),
      ProgressScreen(database: widget.database),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.navigation,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                    _navItem(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Diary',
                      index: 1,
                    ),
                    _navItem(
                      icon: Icons.insights_rounded,
                      label: 'Progress',
                      index: 2,
                    ),
                    _navItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() => selectedIndex = 1);
              },
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => selectedIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
