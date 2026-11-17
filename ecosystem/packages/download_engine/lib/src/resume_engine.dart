import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'address_policy.dart';
import 'http_source.dart';
import 'range_source.dart';
import 'pause_request.dart';

/// Must come from a trusted record of the original response and partial file.
class ResumeCheckpoint {
  const ResumeCheckpoint({required this.url, required this.etag,
    required this.totalBytes, required this.partialBytes, required this.partialSha256});
  final Uri url;
  final String etag;
  final int totalBytes, partialBytes;
  final String partialSha256;
}

class ResumeOutcome {
  const ResumeOutcome(this.sha256, this.checkpoint);
  final String sha256;
  /// Non-null if paused, otherwise the full file was completed.
  final ResumeCheckpoint? checkpoint;
}

/// Experimental primitive: completes a verified partial file, but does not publish it.
class ResumeEngine {
  ResumeEngine({RangeSource Function()? sourceFactory})
      : _sourceFactory = sourceFactory ?? PublicHttpSource.new;
  final RangeSource Function() _sourceFactory;

  Future<String> resume({required ResumeCheckpoint checkpoint, required File partial,
      required int maxBytes, String? expectedSha256}) async {
    final outcome = await resumeWithPause(checkpoint: checkpoint, partial: partial,
      maxBytes: maxBytes, expectedSha256: expectedSha256, pause: PauseRequest());
    return outcome.sha256;
  }

  Future<ResumeOutcome> resumeWithPause({required ResumeCheckpoint checkpoint,
      required File partial, required int maxBytes, required PauseRequest pause,
      String? expectedSha256, void Function(int bytes, int total)? onProgress}) async {
    final c = checkpoint;
    AddressPolicy.validateUri(c.url);
    if (!isStrongEtag(c.etag) || c.partialBytes <= 0 ||
        c.totalBytes <= c.partialBytes || c.totalBytes > maxBytes ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(c.partialSha256) ||
        (expectedSha256 != null && !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(expectedSha256))) {
      throw const FormatException('Punto de reanudación inválido');
    }
    if (await FileSystemEntity.type(partial.path, followLinks: false) != FileSystemEntityType.file ||
        await partial.length() != c.partialBytes ||
        (await sha256.bind(partial.openRead()).first).toString() != c.partialSha256.toLowerCase()) {
      throw StateError('Archivo parcial modificado o inexistente');
    }
    final source = _sourceFactory();
    Directory? scratch;
    try {
      final response = await source.openRange(c.url, c.partialBytes, c.etag);
      if (response.total != c.totalBytes || response.length != c.totalBytes - c.partialBytes) {
        throw StateError('El tamaño del recurso ha cambiado');
      }
      scratch = await Directory.systemTemp.createTemp('lexair-range-');
      final suffix = File(path.join(scratch.path, 'suffix'));
      final sink = suffix.openWrite();
      var received = 0;
      var stopped = false;
      try {
        await for (final chunk in response.stream) {
          if (chunk.isEmpty) continue;
          received += chunk.length;
          if (received > response.length) throw StateError('Rango demasiado largo');
          sink.add(chunk);
          onProgress?.call(c.partialBytes + received, c.totalBytes);
          if (pause.isRequested && received < response.length) { stopped = true; break; }
        }
        await sink.flush();
      } finally { await sink.close(); }
      if (!stopped && received != response.length) throw StateError('Rango incompleto');
      // Hash both sections before changing the original partial file.
      final fullDigest = await sha256.bind(Stream<List<int>>.multi((controller) async {
        try {
          await for (final chunk in partial.openRead()) { controller.add(chunk); }
          await for (final chunk in suffix.openRead()) { controller.add(chunk); }
          controller.close();
        } catch (e, st) { controller.addError(e, st); controller.close(); }
      })).first;
      final hash = fullDigest.toString();
      if (!stopped && expectedSha256 != null && hash != expectedSha256.toLowerCase()) {
        throw StateError('SHA-256 no coincide');
      }
      final out = partial.openWrite(mode: FileMode.append);
      try { await out.addStream(suffix.openRead()); await out.flush(); }
      finally { await out.close(); }
      return ResumeOutcome(hash, stopped ? ResumeCheckpoint(url: c.url, etag: c.etag,
        totalBytes: c.totalBytes, partialBytes: c.partialBytes + received, partialSha256: hash) : null);
    } finally {
      source.close();
      if (scratch != null && await scratch.exists()) await scratch.delete(recursive: true);
    }
  }
}
