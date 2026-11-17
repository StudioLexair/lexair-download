import 'dart:convert';
import 'dart:io';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:test/test.dart';

class FakeSource implements DownloadSource {
  FakeSource(this.tag, {this.length = 16});
  final String? tag;
  final int? length;
  bool closed = false;
  @override
  Future<DownloadResponse> open(Uri url) async => DownloadResponse(
    stream: Stream.value(utf8.encode('0123456789abcdef')), length: length,
    contentType: ContentType.binary, etag: tag);
  @override
  void close() => closed = true;
}

void main() {
  late Directory root;
  setUp(() async => root = await Directory.systemTemp.createTemp('capture-test-'));
  tearDown(() async => root.delete(recursive: true));
  test('corta exactamente dentro de un chunk y obtiene metadatos', () async {
    final source = FakeSource('"v1"');
    final result = await CheckpointCapture(sourceFactory: () => source).capture(
      url: Uri.parse('https://example.com/file'), privateRoot: root, stopAfterBytes: 6, maxBytes: 20);
    expect(await result.file.readAsString(), '012345');
    expect(result.checkpoint.totalBytes, 16);
    expect(result.checkpoint.partialBytes, 6);
    expect(source.closed, isTrue);
  });
  for (final tag in [null, 'W/"v1"']) {
    test('rechaza ETag ausente o débil: $tag', () async {
      final source = FakeSource(tag);
      await expectLater(CheckpointCapture(sourceFactory: () => source).capture(
        url: Uri.parse('https://example.com/file'), privateRoot: root,
        stopAfterBytes: 6, maxBytes: 20), throwsStateError);
      expect(await root.list().toList(), isEmpty);
      expect(source.closed, isTrue);
    });
  }
}
