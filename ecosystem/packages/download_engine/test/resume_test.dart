import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_download_engine/src/range_source.dart';
import 'package:test/test.dart';

class LocalRangeSource implements RangeSource {
  LocalRangeSource(this.port);
  final int port;
  final client = HttpClient()..autoUncompress = false;
  @override
  Future<RangeResponse> openRange(Uri url, int offset, String etag) => openRangeResponse(
    client, Uri.parse('http://127.0.0.1:$port${url.path}'), offset, etag);
  @override
  void close() => client.close(force: true);
}

void main() {
  final full = utf8.encode('0123456789abcdef');
  final prefix = full.sublist(0, 6);
  late Directory dir;
  late File partial;
  late HttpServer server;
  late ResumeEngine engine;
  late ResumeCheckpoint cp;
  var requests = 0;
  setUp(() async {
    requests = 0;
    dir = await Directory.systemTemp.createTemp('lexair-resume-test-');
    partial = File('${dir.path}/partial');
    await partial.writeAsBytes(prefix);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests++;
      final mode = req.uri.path;
      expect(req.headers.value('range'), 'bytes=6-');
      expect(req.headers.value('if-range'), '"v1"');
      expect(req.headers.value('accept-encoding'), 'identity');
      if (mode == '/redirect') {
        req.response.statusCode = 302; req.response.headers.set('location', '/ok');
      } else if (mode == '/full') {
        req.response.statusCode = 200; req.response.add(full);
      } else if (mode == '/unsatisfiable') {
        req.response.statusCode = 416; req.response.headers.set('content-range', 'bytes */16');
      } else {
        req.response.statusCode = 206;
        req.response.headers.set('etag', mode == '/changed' ? '"v2"' : '"v1"');
        req.response.headers.set('content-range', mode == '/bad-range' ? 'bytes 5-15/16' : 'bytes 6-15/16');
        if (mode == '/compressed') req.response.headers.set('content-encoding', 'gzip');
        req.response.headers.contentType = ContentType.binary;
        req.response.add(mode == '/short' ? full.sublist(6, 12) : full.sublist(6));
      }
      await req.response.close();
    });
    engine = ResumeEngine(sourceFactory: () => LocalRangeSource(server.port));
    cp = ResumeCheckpoint(url: Uri.parse('https://example.com/ok'), etag: '"v1"',
      totalBytes: full.length, partialBytes: prefix.length, partialSha256: sha256.convert(prefix).toString());
  });
  tearDown(() async { await server.close(force: true); await dir.delete(recursive: true); });
  ResumeCheckpoint mode(String name) => ResumeCheckpoint(url: Uri.parse('https://example.com/$name'),
    etag: cp.etag, totalBytes: cp.totalBytes, partialBytes: cp.partialBytes, partialSha256: cp.partialSha256);

  test('reanuda 206 real y verifica SHA-256 completo', () async {
    final hash = await engine.resume(checkpoint: cp, partial: partial, maxBytes: 100,
      expectedSha256: sha256.convert(full).toString());
    expect(await partial.readAsBytes(), full);
    expect(hash, sha256.convert(full).toString());
    expect(requests, 1);
  });
  for (final name in ['full', 'unsatisfiable', 'redirect', 'changed', 'bad-range', 'compressed', 'short']) {
    test('rechaza $name sin modificar el parcial', () async {
      await expectLater(engine.resume(checkpoint: mode(name), partial: partial, maxBytes: 100), throwsA(anything));
      expect(await partial.readAsBytes(), prefix);
      expect(requests, 1);
    });
  }
  test('rechaza parcial alterado antes de la red', () async {
    await partial.writeAsString('abcdef');
    await expectLater(engine.resume(checkpoint: cp, partial: partial, maxBytes: 100), throwsStateError);
    expect(requests, 0);
  });
  test('rechaza hash final incorrecto sin modificar parcial', () async {
    await expectLater(engine.resume(checkpoint: cp, partial: partial, maxBytes: 100, expectedSha256: '0' * 64), throwsStateError);
    expect(await partial.readAsBytes(), prefix);
  });
  test('rechaza ETag débil y límite insuficiente antes de red', () async {
    final weak = ResumeCheckpoint(url: cp.url, etag: 'W/"v1"', totalBytes: 16,
      partialBytes: 6, partialSha256: cp.partialSha256);
    await expectLater(engine.resume(checkpoint: weak, partial: partial, maxBytes: 100), throwsFormatException);
    await expectLater(engine.resume(checkpoint: cp, partial: partial, maxBytes: 15), throwsFormatException);
    expect(requests, 0);
  });
}
