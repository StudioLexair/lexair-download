import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_download_engine/src/range_source.dart' show openRangeResponse;
import 'package:lexair_download_queue/lexair_download_queue.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class LocalSource implements DownloadSource {
  LocalSource(this.port);
  final int port;
  final HttpClient client = HttpClient();
  @override
  Future<DownloadResponse> open(Uri url) async {
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port${url.path}'));
    final response = await req.close();
    return DownloadResponse(stream: response, length: response.contentLength < 0 ? null : response.contentLength,
      contentType: response.headers.contentType, etag: response.headers.value('etag'));
  }
  @override
  void close() => client.close(force: true);
}

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
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('lexair-queue-test-'));
  tearDown(() async => dir.delete(recursive: true));

  test('migra v1 y conserva ajustes; persiste y recupera interrumpidas', () async {
    final file = File('${dir.path}/db.sqlite');
    final old = sqlite.sqlite3.open(file.path);
    old.execute('CREATE TABLE app_settings (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
    old.execute("INSERT INTO app_settings VALUES ('theme', 'dark')");
    old.execute('PRAGMA user_version = 1');
    old.close();
    var db = LexairDatabase(NativeDatabase(file));
    var store = DownloadQueueStore(db);
    expect(await db.readSetting('theme'), 'dark');
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'x');
    expect((await store.claimNext())?.id, id);
    await db.close();
    db = LexairDatabase(NativeDatabase(file));
    store = DownloadQueueStore(db);
    expect((await store.list()).single.state, QueueState.running);
    expect(await store.recoverInterrupted(), 1);
    expect((await store.list()).single.state, QueueState.interrupted);
    expect(await store.retry(id), isTrue);
    expect((await store.claimNext())?.id, id);
    expect(await store.complete(id), isTrue);
    expect(await store.retry(id), isFalse);
    await db.close();
  });

  test('FIFO, cancelación pendiente y transiciones condicionadas', () async {
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    Future<int> add(String name) => store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: name);
    final a = await add('a'), b = await add('b'), c = await add('c');
    expect(await store.cancelQueued(b), isTrue);
    expect((await store.claimNext())?.id, a);
    expect(await store.cancelQueued(a), isFalse);
    expect(await store.fail(a), isTrue);
    expect((await store.claimNext())?.id, c);
    expect(await store.complete(c), isTrue);
    expect(await store.claimNext(), isNull);
    expect((await store.list()).map((e) => e.state), [QueueState.failed, QueueState.cancelled, QueueState.completed]);
    await db.close();
  });

  test('trabajador descarga archivo real y registra fallo sin sobrescribir', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async { req.response.headers.contentType = ContentType.binary;
      req.response.add(utf8.encode('lexair')); await req.response.close(); });
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    final worker = DownloadQueueWorker(store, LexairDownloadEngine(sourceFactory: () => LocalSource(server.port)));
    for (var i = 0; i < 2; i++) {
      await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'file.bin');
    }
    expect(await worker.runNext(), isTrue);
    expect(await File('${dir.path}/file.bin').readAsString(), 'lexair');
    expect(await worker.runNext(), isTrue);
    expect(await worker.runNext(), isFalse);
    expect((await store.list()).map((e) => e.state), [QueueState.completed, QueueState.failed]);
    expect(await File('${dir.path}/file.bin').readAsString(), 'lexair');
    await db.close(); await server.close(force: true);
  });
  test('checkpoint real, base reabierta y descarga reanudada', () async {
    final body = utf8.encode('0123456789abcdef');
    final ranges = <String?>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final range = req.headers.value('range'); ranges.add(range);
      req.response.headers.set('etag', '"v1"');
      req.response.headers.contentType = ContentType.binary;
      if (range == null) {
        req.response.contentLength = body.length; req.response.add(body);
      } else {
        expect(range, 'bytes=6-'); expect(req.headers.value('if-range'), '"v1"');
        req.response.statusCode = 206; req.response.headers.set('content-range', 'bytes 6-15/16');
        req.response.contentLength = 10; req.response.add(body.sublist(6));
      }
      await req.response.close();
    });
    final dbfile = File('${dir.path}/queue.sqlite');
    var db = LexairDatabase(NativeDatabase(dbfile));
    var store = DownloadQueueStore(db);
    DownloadQueueWorker worker() => DownloadQueueWorker(store, LexairDownloadEngine(),
      capture: CheckpointCapture(sourceFactory: () => LocalSource(server.port)),
      resumeEngine: ResumeEngine(sourceFactory: () => LocalRangeSource(server.port)));
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path,
      filename: 'file.bin', maxBytes: 100);
    expect(await worker().checkpointNext(privateRoot: dir, afterBytes: 6), isTrue);
    expect((await store.list()).single.state, QueueState.interrupted);
    final cp = await QueueCheckpointStore(db).get(id);
    expect(cp, isNotNull); expect(await File(cp!.path).readAsString(), '012345');
    await db.close();
    db = LexairDatabase(NativeDatabase(dbfile)); store = DownloadQueueStore(db);
    expect(await store.retry(id), isTrue);
    expect(await worker().runNext(), isTrue);
    expect((await store.list()).single.state, QueueState.completed);
    expect(await File('${dir.path}/file.bin').readAsBytes(), body);
    expect(ranges, [null, 'bytes=6-']);
    await db.close(); await server.close(force: true);
  });

  test('migración desde v2 añade checkpoint conservando tareas', () async {
    final file = File('${dir.path}/v2.sqlite');
    final old = sqlite.sqlite3.open(file.path);
    old.execute('CREATE TABLE app_settings (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
    old.execute(LexairDatabase.queueSchema);
    old.execute("INSERT INTO download_queue (url,directory,filename,max_bytes,state,created_at) VALUES ('https://example.com','/tmp','a',100,'queued',0)");
    old.execute('PRAGMA user_version=2'); old.close();
    final db = LexairDatabase(NativeDatabase(file));
    expect((await DownloadQueueStore(db).list()).single.filename, 'a');
    expect(await QueueCheckpointStore(db).get(1), isNull);
    await db.close();
  });

  test('parcial alterado tras guardar no se publica', () async {
    final body = utf8.encode('0123456789abcdef');
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async { requests++; req.response.headers.set('etag', '"v1"');
      req.response.headers.contentType = ContentType.binary;
      req.response.contentLength = body.length; req.response.add(body); await req.response.close(); });
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    final worker = DownloadQueueWorker(store, LexairDownloadEngine(),
      capture: CheckpointCapture(sourceFactory: () => LocalSource(server.port)),
      resumeEngine: ResumeEngine(sourceFactory: () => LocalRangeSource(server.port)));
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'out');
    await worker.checkpointNext(privateRoot: dir, afterBytes: 6);
    final cp = (await QueueCheckpointStore(db).get(id))!;
    await File(cp.path).writeAsString('XXXXXX');
    await store.retry(id); await worker.runNext();
    expect((await store.list()).single.state, QueueState.failed);
    expect(await File('${dir.path}/out').exists(), isFalse);
    expect(requests, 1);
    await db.close(); await server.close(force: true);
  });

  test('pausa solicitada durante descarga, proceso terminado y reanudación', () async {
    final body = utf8.encode('0123456789abcdef');
    final release = Completer<void>();
    final ranges = <String?>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final range = req.headers.value('range'); ranges.add(range);
      req.response.headers.set('etag', '"v1"'); req.response.headers.contentType = ContentType.binary;
      if (range == null) {
        req.response.bufferOutput = false; req.response.contentLength = body.length;
        req.response.add(body.sublist(0, 6)); await req.response.flush();
        await release.future;
        try { req.response.add(body.sublist(6)); await req.response.close(); } catch (_) {}
      } else {
        expect(range, 'bytes=6-'); req.response.statusCode = 206;
        req.response.headers.set('content-range', 'bytes 6-15/16');
        req.response.contentLength = 10; req.response.add(body.sublist(6));
        await req.response.close();
      }
    });
    final file = File('${dir.path}/abrupt.sqlite');
    var db = LexairDatabase(NativeDatabase(file));
    var store = DownloadQueueStore(db);
    DownloadQueueWorker worker() => DownloadQueueWorker(store, LexairDownloadEngine(),
      pausableCapture: PausableCapture(sourceFactory: () => LocalSource(server.port)),
      resumeEngine: ResumeEngine(sourceFactory: () => LocalRangeSource(server.port)));
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'out');
    final pause = PauseRequest();
    await worker().runNextPausable(privateRoot: dir, pause: pause, onProgress: (received, total) {
      pause.request(); if (!release.isCompleted) release.complete();
    });
    expect((await store.list()).single.state, QueueState.interrupted);
    expect((await QueueCheckpointStore(db).get(id))?.partialBytes, 6);
    await db.close();
    // Simulates a separate process dying after claiming a persisted checkpoint.
    final script = "import sqlite3,sys,time; c=sqlite3.connect(sys.argv[1]); "
      "c.execute(\"update download_queue set state='running' where id=?\",(int(sys.argv[2]),)); "
      "c.commit(); print('ready',flush=True); time.sleep(60)";
    final process = await Process.start('python3', ['-u', '-c', script, file.path, '$id']);
    expect(await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).first, 'ready');
    expect(process.kill(ProcessSignal.sigkill), isTrue); await process.exitCode;
    db = LexairDatabase(NativeDatabase(file)); store = DownloadQueueStore(db);
    expect((await store.list()).single.state, QueueState.running);
    expect(await store.recoverInterrupted(), 1);
    expect(await store.retry(id), isTrue); await worker().runNext();
    expect((await store.list()).single.state, QueueState.completed);
    expect(await File('${dir.path}/out').readAsBytes(), body);
    expect(ranges, [null, 'bytes=6-']);
    await db.close(); await server.close(force: true);
  }, skip: !Platform.isLinux);

  test('transferencia pausable sin solicitud llega a completa', () async {
    final body = utf8.encode('0123456789abcdef');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async { req.response.headers.set('etag', '"v1"');
      req.response.headers.contentType = ContentType.binary; req.response.bufferOutput = false; req.response.contentLength = body.length;
      req.response.add(body); await req.response.close(); });
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db);
    final worker = DownloadQueueWorker(store, LexairDownloadEngine(),
      pausableCapture: PausableCapture(sourceFactory: () => LocalSource(server.port)));
    await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'out');
    await worker.runNextPausable(privateRoot: dir, pause: PauseRequest());
    expect((await store.list()).single.state, QueueState.completed);
    expect(await File('${dir.path}/out').readAsBytes(), body);
    await db.close(); await server.close(force: true);
  });

  test('pausar una reanudación, persistir nuevo checkpoint y completar', () async {
    final body = utf8.encode('0123456789abcdef');
    final release = Completer<void>();
    final ranges = <String?>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final range = req.headers.value('range'); ranges.add(range);
      req.response.bufferOutput = false;
      req.response.headers.set('etag', '"v1"');
      req.response.headers.contentType = ContentType.binary;
      if (range == null) {
        req.response.contentLength = body.length; req.response.add(body); await req.response.close();
      } else {
        final offset = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)![1]!);
        req.response.statusCode = 206;
        req.response.headers.set('content-range', 'bytes $offset-15/16');
        req.response.contentLength = 16 - offset;
        if (offset == 4) {
          req.response.add(body.sublist(4, 8)); await req.response.flush(); await release.future;
          try { req.response.add(body.sublist(8)); await req.response.close(); } catch (_) {}
        } else { req.response.add(body.sublist(offset)); await req.response.close(); }
      }
    });
    final dbfile = File('${dir.path}/twice.sqlite');
    var db = LexairDatabase(NativeDatabase(dbfile));
    var store = DownloadQueueStore(db);
    DownloadQueueWorker worker() => DownloadQueueWorker(store, LexairDownloadEngine(),
      capture: CheckpointCapture(sourceFactory: () => LocalSource(server.port)),
      resumeEngine: ResumeEngine(sourceFactory: () => LocalRangeSource(server.port)));
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'out');
    await worker().checkpointNext(privateRoot: dir, afterBytes: 4);
    final before = (await QueueCheckpointStore(db).get(id))!;
    expect(before.partialBytes, 4);
    await store.retry(id);
    final pause = PauseRequest();
    await worker().runNextPausable(privateRoot: dir, pause: pause, onProgress: (received, total) {
      expect(received, 8); pause.request(); if (!release.isCompleted) release.complete();
    });
    expect((await store.list()).single.state, QueueState.interrupted);
    final after = (await QueueCheckpointStore(db).get(id))!;
    expect(after.partialBytes, 8); expect(after.sha256, isNot(before.sha256));
    expect(await File(after.path).readAsString(), '01234567');
    await db.close(); db = LexairDatabase(NativeDatabase(dbfile)); store = DownloadQueueStore(db);
    expect(await store.retry(id), isTrue); await worker().runNext();
    expect((await store.list()).single.state, QueueState.completed);
    expect(await File('${dir.path}/out').readAsBytes(), body);
    expect(ranges, [null, 'bytes=4-', 'bytes=8-']);
    await db.close(); await server.close(force: true);
  });

  test('actualización condicional de checkpoint revierte al detectar cambios', () async {
    final db = LexairDatabase(NativeDatabase.memory());
    final store = DownloadQueueStore(db); final checkpoints = QueueCheckpointStore(db);
    final id = await store.enqueue(url: Uri.parse('https://example.com/file'), directory: dir.path, filename: 'out');
    await store.claimNext();
    const first = QueueCheckpoint(path: 'a', etag: '"x"', totalBytes: 10, partialBytes: 2, sha256: 'old');
    const stale = QueueCheckpoint(path: 'a', etag: '"x"', totalBytes: 10, partialBytes: 3, sha256: 'stale');
    const next = QueueCheckpoint(path: 'a', etag: '"x"', totalBytes: 10, partialBytes: 4, sha256: 'next');
    await checkpoints.saveInterrupted(id, first); await store.retry(id); await store.claimNext();
    await expectLater(checkpoints.replaceInterrupted(id, stale, next), throwsStateError);
    expect((await store.list()).single.state, QueueState.running);
    expect((await checkpoints.get(id))!.sha256, 'old');
    await db.close();
  });

}
