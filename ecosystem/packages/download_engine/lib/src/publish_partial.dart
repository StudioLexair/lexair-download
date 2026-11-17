import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'download_engine.dart';

/// Copies only a complete, verified private file; destination must be trusted.
Future<void> publishCompletedPartial({required File partial, required Directory destination,
    required String filename, required int expectedBytes, required String expectedHash}) async {
  LexairDownloadEngine.validateFilename(filename);
  if (!await destination.exists() ||
      await FileSystemEntity.type(partial.path, followLinks: false) != FileSystemEntityType.file ||
      await partial.length() != expectedBytes ||
      (await sha256.bind(partial.openRead()).first).toString() != expectedHash) {
    throw StateError('Archivo completo no verificable');
  }
  final output = File(path.join(destination.path, filename));
  var created = false;
  try {
    await output.create(exclusive: true);
    created = true;
    final sink = output.openWrite();
    try { await sink.addStream(partial.openRead()); await sink.flush(); }
    finally { await sink.close(); }
  } catch (_) {
    if (created && await output.exists()) await output.delete();
    rethrow;
  }
}
