import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'address_policy.dart';
import 'http_source.dart';
import 'range_source.dart';
import 'pause_request.dart';
import 'resume_engine.dart';
import 'source.dart';

class PausableCaptureResult {
  const PausableCaptureResult({required this.file, required this.totalBytes,
    required this.bytes, required this.sha256, required this.checkpoint});
  final File file;
  final int totalBytes, bytes;
  final String sha256;
  /// Null means the entire response was received.
  final ResumeCheckpoint? checkpoint;
}

/// Streaming capture with explicit pause request; caller owns returned files.
class PausableCapture {
  PausableCapture({DownloadSource Function()? sourceFactory})
      : _sourceFactory = sourceFactory ?? PublicHttpSource.new;
  final DownloadSource Function() _sourceFactory;

  Future<PausableCaptureResult> transfer({required Uri url, required Directory privateRoot,
      required int maxBytes, required PauseRequest pause,
      void Function(int bytes, int total)? onProgress}) async {
    AddressPolicy.validateUri(url);
    if (maxBytes <= 0 || !await privateRoot.exists()) throw ArgumentError('Parámetros inválidos');
    final source = _sourceFactory();
    Directory? temp;
    try {
      final response = await source.open(url);
      final total = response.length;
      final etag = response.etag;
      if (total == null || total <= 0 || total > maxBytes || etag == null ||
          !isStrongEtag(etag) || response.contentType?.mimeType == 'text/html') {
        throw StateError('El recurso no permite pausa segura');
      }
      temp = await privateRoot.createTemp('lexair-part-');
      final file = File(path.join(temp.path, 'partial'));
      final output = file.openWrite();
      var received = 0;
      var stopped = false;
      try {
        await for (final chunk in response.stream) {
          if (chunk.isEmpty) continue;
          received += chunk.length;
          if (received > total || received > maxBytes) throw StateError('Tamaño inválido');
          output.add(chunk);
          onProgress?.call(received, total);
          if (pause.isRequested && received < total) { stopped = true; break; }
        }
        await output.flush();
      } finally { await output.close(); }
      if (!stopped && received != total) throw StateError('Respuesta inicial incompleta');
      final hash = (await sha256.bind(file.openRead()).first).toString();
      final result = PausableCaptureResult(file: file, totalBytes: total, bytes: received,
        sha256: hash, checkpoint: stopped ? ResumeCheckpoint(url: url, etag: etag,
          totalBytes: total, partialBytes: received, partialSha256: hash) : null);
      temp = null;
      return result;
    } finally {
      source.close();
      if (temp != null && await temp.exists()) await temp.delete(recursive: true);
    }
  }
}
