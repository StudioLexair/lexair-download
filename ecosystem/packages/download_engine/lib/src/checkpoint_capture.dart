import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'address_policy.dart';
import 'http_source.dart';
import 'range_source.dart';
import 'resume_engine.dart';
import 'source.dart';

class CapturedPartial {
  const CapturedPartial(this.file, this.checkpoint);
  final File file;
  final ResumeCheckpoint checkpoint;
}

/// Deliberately stops after N bytes; a caller must durably save the returned metadata.
class CheckpointCapture {
  CheckpointCapture({DownloadSource Function()? sourceFactory})
      : _sourceFactory = sourceFactory ?? PublicHttpSource.new;
  final DownloadSource Function() _sourceFactory;

  Future<CapturedPartial> capture({required Uri url, required Directory privateRoot,
      required int stopAfterBytes, required int maxBytes}) async {
    AddressPolicy.validateUri(url);
    if (stopAfterBytes <= 0 || maxBytes <= 0 || !await privateRoot.exists()) {
      throw ArgumentError('Parámetros o carpeta privada inválidos');
    }
    final source = _sourceFactory();
    Directory? temporary;
    try {
      final response = await source.open(url);
      final total = response.length;
      final etag = response.etag;
      if (total == null || total > maxBytes || total <= stopAfterBytes ||
          etag == null || !isStrongEtag(etag) || response.contentType?.mimeType == 'text/html') {
        throw StateError('El recurso no permite crear checkpoint seguro');
      }
      temporary = await privateRoot.createTemp('lexair-part-');
      final file = File(path.join(temporary.path, 'partial'));
      final output = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          final take = (stopAfterBytes - received).clamp(0, chunk.length);
          output.add(chunk.sublist(0, take));
          received += take;
          if (received == stopAfterBytes) break;
        }
        await output.flush();
      } finally { await output.close(); }
      if (received != stopAfterBytes) throw StateError('Respuesta inicial incompleta');
      final digest = (await sha256.bind(file.openRead()).first).toString();
      final result = CapturedPartial(file, ResumeCheckpoint(url: url, etag: etag,
          totalBytes: total, partialBytes: received, partialSha256: digest));
      temporary = null; // Ownership transfers to the caller.
      return result;
    } finally {
      source.close();
      if (temporary != null && await temporary.exists()) await temporary.delete(recursive: true);
    }
  }
}
