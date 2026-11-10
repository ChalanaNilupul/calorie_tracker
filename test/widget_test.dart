import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker/app/app.dart';
import 'package:calorie_tracker/core/database/app_database.dart';

void main() {
  testWidgets('NutriTrack app loads successfully', (WidgetTester tester) async {
    final database = AppDatabase.forTesting();

    try {
      await tester.pumpWidget(NutriTrackApp(database: database));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Diary'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await database.close();
    }
  });
}
