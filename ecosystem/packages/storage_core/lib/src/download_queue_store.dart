import 'package:drift/drift.dart';
import 'database.dart';

enum QueueState { queued, running, completed, failed, interrupted, cancelled }

class QueueEntry {
  const QueueEntry({required this.id, required this.url, required this.directory,
    required this.filename, required this.maxBytes, required this.expectedSha256,
    required this.state});
  final int id;
  final String url, directory, filename;
  final int maxBytes;
  final String? expectedSha256;
  final QueueState state;
  factory QueueEntry.fromRow(QueryRow row) => QueueEntry(
    id: row.read<int>('id'), url: row.read<String>('url'),
    directory: row.read<String>('directory'), filename: row.read<String>('filename'),
    maxBytes: row.read<int>('max_bytes'), expectedSha256: row.readNullable<String>('expected_sha256'),
    state: QueueState.values.byName(row.read<String>('state')),
  );
}

/// Durable metadata only. Use one app process/worker per database.
class DownloadQueueStore {
  DownloadQueueStore(this.db);
  final LexairDatabase db;

  Future<int> enqueue({required Uri url, required String directory,
    required String filename, int maxBytes = 1073741824, String? expectedSha256}) async {
    if (maxBytes <= 0 || directory.isEmpty || filename.isEmpty) {
      throw ArgumentError('Datos de tarea inválidos');
    }
    return db.customInsert('''INSERT INTO download_queue
      (url, directory, filename, max_bytes, expected_sha256, state, created_at)
      VALUES (?, ?, ?, ?, ?, 'queued', ?)''', variables: [
      Variable.withString(url.toString()), Variable.withString(directory),
      Variable.withString(filename), Variable.withInt(maxBytes),
      Variable<String>(expectedSha256), Variable.withInt(DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  Future<List<QueueEntry>> list() async => (await db.customSelect(
    'SELECT * FROM download_queue ORDER BY id').get()).map(QueueEntry.fromRow).toList();

  /// Atomically marks the oldest pending item as running.
  Future<QueueEntry?> claimNext() => db.transaction(() async {
    final rows = await db.customSelect(
      "SELECT * FROM download_queue WHERE state = 'queued' ORDER BY id LIMIT 1").get();
    if (rows.isEmpty) return null;
    final id = rows.single.read<int>('id');
    final count = await _transition(id, 'queued', 'running');
    if (count != 1) return null;
    final row = await db.customSelect('SELECT * FROM download_queue WHERE id = ?',
      variables: [Variable.withInt(id)]).getSingle();
    return QueueEntry.fromRow(row);
  });

  /// Call only once on startup, before starting a worker, with no other process active.
  Future<int> recoverInterrupted() => db.customUpdate(
    "UPDATE download_queue SET state = 'interrupted' WHERE state = 'running'");

  Future<bool> complete(int id) async => await _transition(id, 'running', 'completed') == 1;
  Future<bool> fail(int id) async => await _transition(id, 'running', 'failed') == 1;
  Future<bool> cancelQueued(int id) async => await _transition(id, 'queued', 'cancelled') == 1;
  /// Requeues a failed or interrupted item; the worker decides whether a checkpoint exists.
  Future<bool> retry(int id) async => await db.customUpdate(
    "UPDATE download_queue SET state = 'queued' WHERE id = ? AND state IN ('failed','interrupted')",
    variables: [Variable.withInt(id)]) == 1;

  Future<int> _transition(int id, String from, String to) => db.customUpdate(
    'UPDATE download_queue SET state = ? WHERE id = ? AND state = ?',
    variables: [Variable.withString(to), Variable.withInt(id), Variable.withString(from)]);
}
