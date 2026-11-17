import 'dart:io';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'address_policy.dart';
import 'http_source.dart';
import 'models.dart';
import 'source.dart';

class LexairDownloadEngine {
  /// Injection is for trusted app code and deterministic tests, never web input.
  LexairDownloadEngine({DownloadSource Function()? sourceFactory})
      : _sourceFactory = sourceFactory ?? PublicHttpSource.new;
  final DownloadSource Function() _sourceFactory;

  Future<DownloadResult> download({
    required Uri url,
    required Directory directory,
    required String filename,
    int maxBytes = 1024 * 1024 * 1024,
    String? expectedSha256,
    DownloadCancellation? cancellation,
    void Function(DownloadProgress)? onProgress,
  }) async {
    AddressPolicy.validateUri(url);
    validateFilename(filename);
    if (maxBytes <= 0) throw ArgumentError('maxBytes debe ser positivo');
    if (expectedSha256 != null && !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(expectedSha256)) {
      throw const FormatException('SHA-256 no válido');
    }
    if (!await directory.exists()) throw FileSystemException('Carpeta inexistente', directory.path);
    final cancel = cancellation ?? DownloadCancellation();
    cancel.throwIfCancelled();
    final tempDir = await Directory.systemTemp.createTemp('lexair-download-');
    final temp = File(path.join(tempDir.path, 'transfer.part'));
    final output = File(path.join(directory.path, filename));
    DownloadSource? source;
    var outputCreated = false;
    try {
      source = _sourceFactory();
      onProgress?.call(const DownloadProgress(DownloadPhase.connecting, 0, null));
      final response = await source.open(url);
      cancel.throwIfCancelled();
      if (response.length != null && response.length! > maxBytes) throw StateError('Archivo demasiado grande');
      if (response.contentType?.mimeType == 'text/html') throw StateError('La URL devuelve una página HTML, no un archivo directo');
      final sink = temp.openWrite();
      final digestOutput = AccumulatorSink<Digest>();
      final digest = sha256.startChunkedConversion(digestOutput);
      var received = 0;
      try {
        await for (final bytes in response.stream) {
          cancel.throwIfCancelled();
          received += bytes.length;
          if (received > maxBytes) throw StateError('Archivo demasiado grande');
          digest.add(bytes);
          sink.add(bytes);
          onProgress?.call(DownloadProgress(DownloadPhase.downloading, received, response.length));
        }
        await sink.flush();
      } finally {
        digest.close();
        await sink.close();
      }
      cancel.throwIfCancelled();
      if (response.length != null && received != response.length) throw StateError('Descarga incompleta');
      onProgress?.call(DownloadProgress(DownloadPhase.verifying, received, response.length));
      final hash = digestOutput.events.single.toString();
      if (expectedSha256 != null && hash != expectedSha256.toLowerCase()) throw StateError('SHA-256 no coincide');
      // The destination directory must be trusted; exclusive create prevents ordinary overwrites.
      await output.create(exclusive: true);
      outputCreated = true;
      final finalSink = output.openWrite();
      try { await finalSink.addStream(temp.openRead()); } finally { await finalSink.close(); }
      cancel.throwIfCancelled();
      onProgress?.call(DownloadProgress(DownloadPhase.completed, received, response.length));
      return DownloadResult(output, received, hash);
    } catch (_) {
      if (outputCreated && await output.exists()) await output.delete();
      rethrow;
    } finally {
      source?.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    }
  }

  static void validateFilename(String name) {
    if (name.isEmpty || name == '.' || name == '..' || name.length > 200 ||
        name.contains(RegExp(r'[\\/:*?"<>|\x00-\x1f]')) || name.endsWith('.') || name.endsWith(' ') ||
        RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.|$)', caseSensitive: false).hasMatch(name)) {
      throw const FormatException('Nombre de archivo no válido');
    }
  }
}
