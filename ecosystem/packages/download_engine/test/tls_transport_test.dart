import 'dart:convert';
import 'dart:io';
import 'package:lexair_download_engine/src/http_source.dart';
import 'package:lexair_download_engine/src/pinned_connection.dart';
import 'package:test/test.dart';

void main() {
  final cert = File('test/fixtures/tls-cert.pem').readAsBytesSync();
  final key = File('test/fixtures/tls-key.pem').readAsBytesSync();
  late HttpServer server;
  var visits = 0;
  setUp(() async {
    visits = 0;
    final serverContext = SecurityContext()
      ..useCertificateChainBytes(cert)
      ..usePrivateKeyBytes(key);
    server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, serverContext);
    server.listen((request) async {
      visits++;
      if (request.uri.path == '/redirect') {
        request.response.statusCode = 302;
        request.response.headers.set(HttpHeaders.locationHeader, '/secret');
      } else {
        request.response.headers.contentType = ContentType.binary;
        request.response.write('secure fixture');
      }
      await request.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  HttpClient client({required bool trust}) {
    final context = SecurityContext(withTrustedRoots: false);
    if (trust) context.setTrustedCertificatesBytes(cert);
    final client = HttpClient()
      ..findProxy = ((_) => 'DIRECT')
      ..connectionFactory = ((uri, proxyHost, proxyPort) => connectPinned(
        address: InternetAddress.loopbackIPv4, port: server.port, secure: true,
        hostname: uri.host, securityContext: context));
    return client;
  }

  test('HTTPS real, certificado confiable y host correcto', () async {
    final c = client(trust: true);
    try {
      final response = await openDirectResponse(c, Uri.parse('https://lexair-test.invalid:${server.port}/file'));
      expect(await utf8.decoder.bind(response.stream).join(), 'secure fixture');
      expect(visits, 1);
    } finally { c.close(force: true); }
  });
  test('rechaza certificado no confiable', () async {
    final c = client(trust: false);
    try {
      await expectLater(openDirectResponse(c, Uri.parse('https://lexair-test.invalid:${server.port}/file')),
        throwsA(isA<HandshakeException>()));
      expect(visits, 0);
    } finally { c.close(force: true); }
  });
  test('rechaza certificado para otro dominio', () async {
    final c = client(trust: true);
    try {
      await expectLater(openDirectResponse(c, Uri.parse('https://wrong-test.invalid:${server.port}/file')),
        throwsA(isA<HandshakeException>()));
      expect(visits, 0);
    } finally { c.close(force: true); }
  });
  test('no sigue una redirección recibida', () async {
    final c = client(trust: true);
    try {
      await expectLater(openDirectResponse(c, Uri.parse('https://lexair-test.invalid:${server.port}/redirect')),
        throwsA(isA<HttpException>()));
      expect(visits, 1);
    } finally { c.close(force: true); }
  });
}
