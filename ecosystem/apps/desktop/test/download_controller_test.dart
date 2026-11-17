import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_desktop/features/downloads/queue_controller.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_download_queue/lexair_download_queue.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

class Fixture implements DownloadSource {
  Fixture(this.port);
  final int port;
  final client = HttpClient();
  @override
  Future<DownloadResponse> open(Uri url) async {
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/file'));
    final response = await req.close();
    return DownloadResponse(stream: response, length: response.contentLength, contentType: response.headers.contentType);
  }
  @override
  void close() => client.close(force: true);
}

void main() {
  test('cola integrada transfiere bytes, persiste y rechaza red local', () async {
    final dir = await Directory.systemTemp.createTemp('lexair-ui-test-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async { final bytes = utf8.encode('archivo real');
      req.response.headers.contentType = ContentType.binary; req.response.contentLength = bytes.length;
      req.response.add(bytes); await req.response.close(); });
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    final engine = LexairDownloadEngine(sourceFactory: () => Fixture(server.port));
    final controller = QueueController(store, DownloadQueueWorker(store, engine));
    await controller.initialize();
    expect(await controller.enqueue(url: 'http://127.0.0.1/file', filename: 'a', folder: dir.path), isFalse);
    expect(await controller.enqueue(url: 'https://example.com/file', filename: '../a', folder: dir.path), isFalse);
    expect(await controller.enqueue(url: 'https://example.com/file', filename: 'a.bin', folder: dir.path), isTrue);
    expect(controller.entries.single.state, QueueState.queued);
    var observedRunning = false;
    controller.addListener(() { if (controller.entries.any((e) => e.state == QueueState.running)) observedRunning = true; });
    await controller.runNext();
    expect(observedRunning, isTrue);
    expect(controller.entries.single.state, QueueState.completed);
    expect(await File('${dir.path}/a.bin').readAsString(), 'archivo real');
    controller.dispose(); await db.close(); await server.close(force: true); await dir.delete(recursive: true);
  });
}
