import 'package:drift/drift.dart';
import 'database.dart';

class QueueCheckpoint {
  const QueueCheckpoint({required this.path, required this.etag, required this.totalBytes,
    required this.partialBytes, required this.sha256});
  final String path, etag, sha256;
  final int totalBytes, partialBytes;
  factory QueueCheckpoint.fromRow(QueryRow row) => QueueCheckpoint(
    path: row.read<String>('partial_path'), etag: row.read<String>('etag'),
    totalBytes: row.read<int>('total_bytes'), partialBytes: row.read<int>('partial_bytes'),
    sha256: row.read<String>('partial_sha256'));
}

class QueueCheckpointStore {
  QueueCheckpointStore(this.db);
  final LexairDatabase db;

  Future<QueueCheckpoint?> get(int id) async {
    final row = await db.customSelect('SELECT * FROM download_checkpoints WHERE queue_id = ?',
      variables: [Variable.withInt(id)]).getSingleOrNull();
    return row == null ? null : QueueCheckpoint.fromRow(row);
  }

  /// Metadata and state commit together; caller must flush the partial first.
  Future<void> saveInterrupted(int id, QueueCheckpoint cp) => db.transaction(() async {
    final count = await db.customUpdate(
      "UPDATE download_queue SET state = 'interrupted' WHERE id = ? AND state = 'running'",
      variables: [Variable.withInt(id)]);
    if (count != 1) throw StateError('La tarea no está activa');
    await db.customInsert('''INSERT INTO download_checkpoints
      (queue_id,partial_path,etag,total_bytes,partial_bytes,partial_sha256)
      VALUES (?,?,?,?,?,?)''', variables: [Variable.withInt(id), Variable.withString(cp.path),
      Variable.withString(cp.etag), Variable.withInt(cp.totalBytes),
      Variable.withInt(cp.partialBytes), Variable.withString(cp.sha256)]);
  });
  /// Compare the previous record before committing updated metadata and state.
  Future<void> replaceInterrupted(int id, QueueCheckpoint previous, QueueCheckpoint next) => db.transaction(() async {
    final stateCount = await db.customUpdate(
      "UPDATE download_queue SET state = 'interrupted' WHERE id = ? AND state = 'running'",
      variables: [Variable.withInt(id)]);
    if (stateCount != 1) throw StateError('La tarea no está activa');
    final changed = await db.customUpdate('''UPDATE download_checkpoints SET
      partial_path = ?, etag = ?, total_bytes = ?, partial_bytes = ?, partial_sha256 = ?
      WHERE queue_id = ? AND partial_path = ? AND etag = ? AND total_bytes = ?
        AND partial_bytes = ? AND partial_sha256 = ?''', variables: [
      Variable.withString(next.path), Variable.withString(next.etag), Variable.withInt(next.totalBytes),
      Variable.withInt(next.partialBytes), Variable.withString(next.sha256), Variable.withInt(id),
      Variable.withString(previous.path), Variable.withString(previous.etag), Variable.withInt(previous.totalBytes),
      Variable.withInt(previous.partialBytes), Variable.withString(previous.sha256),
    ]);
    if (changed != 1) throw StateError('Checkpoint modificado');
  });

}
