import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:test/test.dart';

/// Only test code connects to loopback. Production does not export this adapter.
class FixtureSource implements DownloadSource {
  FixtureSource(this.port);
  final int port;
  final client = HttpClient();
  @override
  Future<DownloadResponse> open(Uri url) async {
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port${url.path}'));
    final res = await req.close();
    return DownloadResponse(stream: res, length: res.contentLength < 0 ? null : res.contentLength,
      contentType: res.headers.contentType);
  }
  @override
  void close() => client.close(force: true);
}

void main() {
  late HttpServer server;
  late Directory output;
  late LexairDownloadEngine engine;
  final bytes = utf8.encode('Lexair: contenido de prueba');
  setUp(() async {
    output = await Directory.systemTemp.createTemp('lexair-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.headers.contentType = req.uri.path == '/html'
          ? ContentType.html : ContentType.binary;
      req.response.contentLength = bytes.length;
      req.response.add(bytes);
      await req.response.close();
    });
    engine = LexairDownloadEngine(sourceFactory: () => FixtureSource(server.port));
  });
  tearDown(() async { await server.close(force: true); await output.delete(recursive: true); });
  Uri url([String p = '/file']) => Uri.parse('https://example.com$p');

  test('descarga por streaming y verifica SHA-256', () async {
    final phases = <DownloadPhase>[];
    final expected = sha256.convert(bytes).toString();
    final result = await engine.download(url: url(), directory: output, filename: 'archivo.bin',
      expectedSha256: expected, onProgress: (value) => phases.add(value.phase));
    expect(await result.file.readAsBytes(), bytes);
    expect(result.sha256, expected);
    expect(result.bytes, bytes.length);
    expect(phases, containsAllInOrder([DownloadPhase.connecting, DownloadPhase.downloading,
      DownloadPhase.verifying, DownloadPhase.completed]));
  });
  test('no sobrescribe un archivo existente', () async {
    final existing = File('${output.path}/archivo.bin'); await existing.writeAsString('original');
    await expectLater(engine.download(url: url(), directory: output, filename: 'archivo.bin'), throwsA(isA<FileSystemException>()));
    expect(await existing.readAsString(), 'original');
  });
  test('rechaza SHA incorrecto sin dejar archivo final', () async {
    await expectLater(engine.download(url: url(), directory: output, filename: 'archivo.bin', expectedSha256: '0' * 64), throwsStateError);
    expect(await File('${output.path}/archivo.bin').exists(), isFalse);
  });
  test('rechaza páginas HTML y límite de tamaño', () async {
    await expectLater(engine.download(url: url('/html'), directory: output, filename: 'archivo.bin'), throwsStateError);
    await expectLater(engine.download(url: url(), directory: output, filename: 'archivo.bin', maxBytes: 4), throwsStateError);
  });
  test('rechaza nombres peligrosos y redes locales', () async {
    for (final name in ['../bad', 'CON', 'prueba.', 'foo/bar']) {
      await expectLater(engine.download(url: url(), directory: output, filename: name), throwsFormatException);
    }
    await expectLater(engine.download(url: Uri.parse('http://127.0.0.1:80/'), directory: output, filename: 'a'), throwsFormatException);
  });
  test('cancela antes de iniciar', () async {
    final c = DownloadCancellation()..cancel();
    await expectLater(engine.download(url: url(), directory: output, filename: 'a', cancellation: c), throwsA(isA<DownloadCancelled>()));
    expect(await File('${output.path}/a').exists(), isFalse);
  });
}
