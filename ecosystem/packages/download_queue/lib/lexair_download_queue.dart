import 'dart:io';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

/// One process/worker per database. No automatic background service.
class DownloadQueueWorker {
  DownloadQueueWorker(this.store, this.engine, {ResumeEngine? resumeEngine,
      CheckpointCapture? capture, PausableCapture? pausableCapture}) : pausableCapture = pausableCapture ?? PausableCapture(), resumeEngine = resumeEngine ?? ResumeEngine(),
      capture = capture ?? CheckpointCapture();
  final DownloadQueueStore store;
  final LexairDownloadEngine engine;
  final ResumeEngine resumeEngine;
  final CheckpointCapture capture;
  final PausableCapture pausableCapture;
  bool _busy = false;

  /// Explicit, experimental checkpoint after a fixed byte count, not a pause button.
  Future<bool> checkpointNext({required Directory privateRoot, required int afterBytes}) async {
    if (_busy) throw StateError('El trabajador ya está ocupado');
    _busy = true;
    try {
      final entry = await store.claimNext();
      if (entry == null) return false;
      try {
        if (await QueueCheckpointStore(store.db).get(entry.id) != null) {
          throw StateError('Ya existe un checkpoint');
        }
        final partial = await capture.capture(url: Uri.parse(entry.url), privateRoot: privateRoot,
          stopAfterBytes: afterBytes, maxBytes: entry.maxBytes);
        final cp = partial.checkpoint;
        await QueueCheckpointStore(store.db).saveInterrupted(entry.id, QueueCheckpoint(
          path: partial.file.path, etag: cp.etag, totalBytes: cp.totalBytes,
          partialBytes: cp.partialBytes, sha256: cp.partialSha256));
      } catch (_) {
        await store.fail(entry.id);
      }
      return true;
    } finally { _busy = false; }
  }

  /// Opt-in cooperative pause for an initial or resumed transfer.
  Future<bool> runNextPausable({required Directory privateRoot, required PauseRequest pause,
      void Function(int bytes, int total)? onProgress}) async {
    if (_busy) throw StateError('El trabajador ya está ocupado');
    _busy = true;
    try {
      final entry = await store.claimNext();
      if (entry == null) return false;
      try {
        final checkpoints = QueueCheckpointStore(store.db);
        final saved = await checkpoints.get(entry.id);
        LexairDownloadEngine.validateFilename(entry.filename);
        if (entry.expectedSha256 != null &&
            !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(entry.expectedSha256!)) {
          throw const FormatException('SHA-256 inválido');
        }
        if (saved != null) {
          final partial = File(saved.path);
          final prior = ResumeCheckpoint(url: Uri.parse(entry.url), etag: saved.etag,
            totalBytes: saved.totalBytes, partialBytes: saved.partialBytes, partialSha256: saved.sha256);
          final outcome = await resumeEngine.resumeWithPause(checkpoint: prior, partial: partial,
            maxBytes: entry.maxBytes, expectedSha256: entry.expectedSha256, pause: pause, onProgress: onProgress);
          final updated = outcome.checkpoint;
          if (updated != null) {
            await checkpoints.replaceInterrupted(entry.id, saved, QueueCheckpoint(path: saved.path,
              etag: updated.etag, totalBytes: updated.totalBytes,
              partialBytes: updated.partialBytes, sha256: updated.partialSha256));
          } else {
            await publishCompletedPartial(partial: partial, destination: Directory(entry.directory),
              filename: entry.filename, expectedBytes: saved.totalBytes, expectedHash: outcome.sha256);
            if (!await store.complete(entry.id)) throw StateError('Estado no actualizado');
          }
          return true;
        }
        final result = await pausableCapture.transfer(url: Uri.parse(entry.url),
          privateRoot: privateRoot, maxBytes: entry.maxBytes, pause: pause, onProgress: onProgress);
        final cp = result.checkpoint;
        if (cp != null) {
          await QueueCheckpointStore(store.db).saveInterrupted(entry.id, QueueCheckpoint(
            path: result.file.path, etag: cp.etag, totalBytes: cp.totalBytes,
            partialBytes: cp.partialBytes, sha256: cp.partialSha256));
        } else {
          if (entry.expectedSha256 != null && result.sha256 != entry.expectedSha256!.toLowerCase()) {
            throw StateError('SHA-256 no coincide');
          }
          await publishCompletedPartial(partial: result.file, destination: Directory(entry.directory),
            filename: entry.filename, expectedBytes: result.totalBytes, expectedHash: result.sha256);
          if (!await store.complete(entry.id)) throw StateError('Estado no actualizado');
        }
      } catch (_) {
        await store.fail(entry.id);
      }
      return true;
    } finally { _busy = false; }
  }

  /// Processes one queued item, optionally using its saved checkpoint.
  Future<bool> runNext({Future<void> Function()? onClaim}) async {
    if (_busy) throw StateError('El trabajador ya está ocupado');
    _busy = true;
    try {
      final entry = await store.claimNext();
      if (entry == null) return false;
      await onClaim?.call();
      try {
        final saved = await QueueCheckpointStore(store.db).get(entry.id);
        if (saved == null) {
          await engine.download(url: Uri.parse(entry.url), directory: Directory(entry.directory),
            filename: entry.filename, maxBytes: entry.maxBytes, expectedSha256: entry.expectedSha256);
        } else {
          final partial = File(saved.path);
          final cp = ResumeCheckpoint(url: Uri.parse(entry.url), etag: saved.etag,
            totalBytes: saved.totalBytes, partialBytes: saved.partialBytes, partialSha256: saved.sha256);
          final hash = await resumeEngine.resume(checkpoint: cp, partial: partial,
            maxBytes: entry.maxBytes, expectedSha256: entry.expectedSha256);
          await publishCompletedPartial(partial: partial, destination: Directory(entry.directory),
            filename: entry.filename, expectedBytes: saved.totalBytes, expectedHash: hash);
        }
      } catch (_) {
        await store.fail(entry.id);
        return true;
      }
      if (!await store.complete(entry.id)) throw StateError('No se pudo registrar la descarga');
      return true;
    } finally { _busy = false; }
  }
}
