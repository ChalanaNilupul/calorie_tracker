import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DataClassName('DiaryEntry')
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get foodId => text()();
  TextColumn get foodName => text()();
  TextColumn get foodCategory => text()();
  TextColumn get preparation => text()();

  TextColumn get mealType => text()();
  DateTimeColumn get loggedAt => dateTime()();

  RealColumn get weightInGrams => real()();

  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbohydrates => real()();
  RealColumn get fat => real()();

  TextColumn get sourceName => text()();
  TextColumn get sourceReference => text().nullable()();
}

@DataClassName('NutritionGoal')
class NutritionGoals extends Table {
  IntColumn get id => integer()();

  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbohydrates => real()();
  RealColumn get fat => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DiaryEntries, NutritionGoals])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'nutritrack',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(nutritionGoals);
      }
    },
  );

  // Diary methods

  Future<int> addDiaryEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insert(entry);
  }

  Stream<List<DiaryEntry>> watchEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return (select(diaryEntries)
          ..where(
            (entry) =>
                entry.loggedAt.isBiggerOrEqualValue(start) &
                entry.loggedAt.isSmallerThanValue(end),
          )
          ..orderBy([(entry) => OrderingTerm.desc(entry.loggedAt)]))
        .watch();
  }

  Future<bool> updateDiaryEntry(int id, DiaryEntriesCompanion entry) {
    return (update(diaryEntries)..where((row) => row.id.equals(id)))
        .write(entry)
        .then((updatedRows) => updatedRows > 0);
  }

  Future<int> deleteDiaryEntry(int id) {
    return (delete(diaryEntries)..where((row) => row.id.equals(id))).go();
  }

  // Nutrition goal methods

  Future<NutritionGoal?> getNutritionGoals() {
    return (select(
      nutritionGoals,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
  }

  Stream<NutritionGoal?> watchNutritionGoals() {
    return (select(nutritionGoals)..where((row) => row.id.equals(1)))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<void> saveNutritionGoals({
    required double calories,
    required double protein,
    required double carbohydrates,
    required double fat,
  }) async {
    await into(nutritionGoals).insertOnConflictUpdate(
      NutritionGoalsCompanion.insert(
        id: const Value(1),
        calories: calories,
        protein: protein,
        carbohydrates: carbohydrates,
        fat: fat,
      ),
    );
  }
}
