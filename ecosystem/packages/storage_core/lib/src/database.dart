import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [AppSettings])
class LexairDatabase extends _$LexairDatabase {
  LexairDatabase(super.executor);
  LexairDatabase.open() : super(driftDatabase(name: 'lexair'));

  @override
  int get schemaVersion => 3;

  static const queueSchema = """
    CREATE TABLE download_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      directory TEXT NOT NULL,
      filename TEXT NOT NULL,
      max_bytes INTEGER NOT NULL CHECK(max_bytes > 0),
      expected_sha256 TEXT,
      state TEXT NOT NULL CHECK(state IN ('queued','running','completed','failed','interrupted','cancelled')),
      created_at INTEGER NOT NULL
    )
  """;

  static const checkpointSchema = """
    CREATE TABLE download_checkpoints (
      queue_id INTEGER PRIMARY KEY REFERENCES download_queue(id) ON DELETE CASCADE,
      partial_path TEXT NOT NULL, etag TEXT NOT NULL, total_bytes INTEGER NOT NULL,
      partial_bytes INTEGER NOT NULL, partial_sha256 TEXT NOT NULL
    )
  """;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async { await m.createAll(); await customStatement(queueSchema); await customStatement(checkpointSchema); },
    onUpgrade: (m, from, to) async {
      if (from < 2) await customStatement(queueSchema);
      if (from < 3) await customStatement(checkpointSchema);
    },
  );

  Future<String?> readSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }
}
