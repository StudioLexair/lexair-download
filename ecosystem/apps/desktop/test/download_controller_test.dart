import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_desktop/features/downloads/queue_controller.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_download_engine/src/range_source.dart' show openRangeResponse;
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
    return DownloadResponse(stream: response, length: response.contentLength, contentType: response.headers.contentType, etag: response.headers.value('etag'));
  }
  @override
  void close() => client.close(force: true);
}

class RangeFixture implements RangeSource {
  RangeFixture(this.port);
  final int port;
  final client = HttpClient()..autoUncompress = false;
  @override
  Future<RangeResponse> openRange(Uri url, int offset, String etag) => openRangeResponse(
    client, Uri.parse('http://127.0.0.1:$port/file'), offset, etag);
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
    var observedRunning = false, observedProgress = false;
    controller.addListener(() {
      if (controller.entries.any((e) => e.state == QueueState.running)) observedRunning = true;
      if (controller.bytesReceived > 0) observedProgress = true;
    });
    await controller.runNext();
    expect(observedRunning, isTrue); expect(observedProgress, isTrue);
    expect(controller.entries.single.state, QueueState.completed);
    expect(await File('${dir.path}/a.bin').readAsString(), 'archivo real');
    controller.dispose(); await db.close(); await server.close(force: true); await dir.delete(recursive: true);
  });
  test('controlador solicita pausa, guarda checkpoint y reanuda', () async {
    final dir = await Directory.systemTemp.createTemp('lexair-pause-ui-');
    final body = utf8.encode('0123456789abcdef');
    final release = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.bufferOutput = false;
      req.response.headers.contentType = ContentType.binary; req.response.headers.set('etag', '"v1"');
      final range = req.headers.value('range');
      if (range == null) {
        req.response.contentLength = body.length; req.response.add(body.sublist(0,6));
        await req.response.flush(); await release.future;
        try { req.response.add(body.sublist(6)); await req.response.close(); } catch (_) {}
      } else {
        expect(range, 'bytes=6-'); req.response.statusCode = 206;
        req.response.headers.set('content-range', 'bytes 6-15/16');
        req.response.contentLength = 10; req.response.add(body.sublist(6)); await req.response.close();
      }
    });
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    final worker = DownloadQueueWorker(store, LexairDownloadEngine(),
      pausableCapture: PausableCapture(sourceFactory: () => Fixture(server.port)),
      resumeEngine: ResumeEngine(sourceFactory: () => RangeFixture(server.port)));
    final controller = QueueController(store, worker, partialRoot: () async => dir);
    await controller.initialize();
    await controller.enqueue(url: 'https://example.com/file', filename: 'out', folder: dir.path);
    controller.setPausable(true);
    var requested = false;
    controller.addListener(() {
      if (!requested && controller.bytesReceived >= 6 && controller.canPause) {
        requested = true; controller.requestPause(); release.complete();
      }
    });
    await controller.runNext();
    expect(requested, isTrue); expect(controller.entries.single.state, QueueState.interrupted);
    expect((await QueueCheckpointStore(db).get(controller.entries.single.id))!.partialBytes, 6);
    await controller.retry(controller.entries.single.id);
    await controller.runNext();
    expect(controller.entries.single.state, QueueState.completed);
    expect(await File('${dir.path}/out').readAsBytes(), body);
    controller.dispose(); await db.close(); await server.close(force: true); await dir.delete(recursive: true);
  });

}
