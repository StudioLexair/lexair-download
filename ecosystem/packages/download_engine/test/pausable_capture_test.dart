import 'dart:io';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:test/test.dart';

class ChunkSource implements DownloadSource {
  ChunkSource(this.chunks, {this.length = 6, this.etag = '"v1"'});
  final List<List<int>> chunks;
  final int length;
  final String? etag;
  bool closed = false;
  @override
  Future<DownloadResponse> open(Uri url) async => DownloadResponse(
    stream: Stream.fromIterable(chunks), length: length, contentType: ContentType.binary, etag: etag);
  @override
  void close() => closed = true;
}

void main() {
  late Directory root;
  final url = Uri.parse('https://example.com/file');
  setUp(() async => root = await Directory.systemTemp.createTemp('pause-test-'));
  tearDown(() async => root.delete(recursive: true));
  test('pausa durante flujo guarda solo los chunks recibidos', () async {
    final source = ChunkSource([[1,2,3],[4,5,6]]);
    final signal = PauseRequest();
    final result = await PausableCapture(sourceFactory: () => source).transfer(url: url,
      privateRoot: root, maxBytes: 6, pause: signal, onProgress: (n, _) => signal.request());
    expect(result.bytes, 3); expect(result.checkpoint?.partialBytes, 3);
    expect(await result.file.readAsBytes(), [1,2,3]); expect(source.closed, isTrue);
  });
  test('pausa solicitada en último chunk completa en lugar de checkpoint inválido', () async {
    final signal = PauseRequest();
    final result = await PausableCapture(sourceFactory: () => ChunkSource([[1,2,3,4,5,6]])).transfer(
      url: url, privateRoot: root, maxBytes: 6, pause: signal, onProgress: (bytes, total) => signal.request());
    expect(result.checkpoint, isNull); expect(result.bytes, 6);
  });
  test('respuesta corta falla y elimina temporal', () async {
    final source = ChunkSource([[1,2,3]]);
    await expectLater(PausableCapture(sourceFactory: () => source).transfer(url: url,
      privateRoot: root, maxBytes: 6, pause: PauseRequest()), throwsStateError);
    expect(await root.list().toList(), isEmpty); expect(source.closed, isTrue);
  });
  test('sin ETag fuerte no se inicia transferencia pausable', () async {
    final source = ChunkSource([[1,2,3]], etag: 'W/"v1"');
    await expectLater(PausableCapture(sourceFactory: () => source).transfer(url: url,
      privateRoot: root, maxBytes: 6, pause: PauseRequest()), throwsStateError);
    expect(await root.list().toList(), isEmpty);
  });
}
