import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:test/test.dart';

class RangeFixture implements RangeSource {
  RangeFixture(this.chunks);
  final List<List<int>> chunks;
  @override
  Future<RangeResponse> openRange(Uri url, int offset, String etag) async => RangeResponse(
    stream: Stream.fromIterable(chunks), total: 6, length: 6 - offset);
  @override
  void close() {}
}

void main() {
  late Directory dir;
  late File file;
  late ResumeCheckpoint checkpoint;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('resume-pause-');
    file = File('${dir.path}/part'); await file.writeAsBytes([1,2]);
    checkpoint = ResumeCheckpoint(url: Uri.parse('https://example.com/a'), etag: '"v1"',
      totalBytes: 6, partialBytes: 2, partialSha256: sha256.convert([1,2]).toString());
  });
  tearDown(() async => dir.delete(recursive: true));
  test('pausa parcial devuelve nuevo hash y posición', () async {
    final pause = PauseRequest();
    final result = await ResumeEngine(sourceFactory: () => RangeFixture([[3,4],[5,6]])).resumeWithPause(
      checkpoint: checkpoint, partial: file, maxBytes: 6, pause: pause,
      onProgress: (received, total) { expect(received, 4); pause.request(); });
    expect(result.checkpoint!.partialBytes, 4);
    expect(result.sha256, sha256.convert([1,2,3,4]).toString());
    expect(await file.readAsBytes(), [1,2,3,4]);
  });
  test('petición al último chunk termina y verifica hash final', () async {
    final pause = PauseRequest();
    final result = await ResumeEngine(sourceFactory: () => RangeFixture([[3,4,5,6]])).resumeWithPause(
      checkpoint: checkpoint, partial: file, maxBytes: 6, pause: pause,
      expectedSha256: sha256.convert([1,2,3,4,5,6]).toString(),
      onProgress: (received, total) => pause.request());
    expect(result.checkpoint, isNull);
    expect(await file.readAsBytes(), [1,2,3,4,5,6]);
  });
  test('hash final equivocado no modifica parcial', () async {
    await expectLater(ResumeEngine(sourceFactory: () => RangeFixture([[3,4,5,6]])).resumeWithPause(
      checkpoint: checkpoint, partial: file, maxBytes: 6, pause: PauseRequest(),
      expectedSha256: '0' * 64), throwsStateError);
    expect(await file.readAsBytes(), [1,2]);
  });
  test('flujo demasiado largo no modifica parcial', () async {
    await expectLater(ResumeEngine(sourceFactory: () => RangeFixture([[3,4,5,6,7]])).resumeWithPause(
      checkpoint: checkpoint, partial: file, maxBytes: 6, pause: PauseRequest()), throwsStateError);
    expect(await file.readAsBytes(), [1,2]);
  });
}
