import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexair_download_engine/lexair_download_engine.dart';
import 'package:lexair_download_queue/lexair_download_queue.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';
import '../../app/providers.dart';

final queueControllerProvider = ChangeNotifierProvider<QueueController>((ref) {
  final store = DownloadQueueStore(ref.watch(databaseProvider));
  return QueueController(store, DownloadQueueWorker(store, LexairDownloadEngine()))..initialize();
});

class QueueController extends ChangeNotifier {
  QueueController(this.store, this.worker);
  final DownloadQueueStore store;
  final DownloadQueueWorker worker;
  List<QueueEntry> entries = [];
  bool ready = false, busy = false, _disposed = false;
  String? error;
  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> initialize() async {
    try {
      await store.recoverInterrupted();
      entries = await store.list(); ready = true;
    } catch (_) { error = 'No se pudo abrir la cola.'; }
    _notify();
  }

  Future<bool> enqueue({required String url, required String filename, required String folder}) async {
    if (!ready || busy) return false;
    try {
      final uri = Uri.parse(url.trim());
      AddressPolicy.validateUri(uri);
      LexairDownloadEngine.validateFilename(filename);
      if (!await Directory(folder).exists()) throw const FormatException('Carpeta inexistente');
      await store.enqueue(url: uri, directory: folder, filename: filename);
      entries = await store.list(); error = null; _notify(); return true;
    } catch (_) { error = 'Revisa la URL directa, el nombre y la carpeta seleccionada.'; _notify(); return false; }
  }

  Future<void> refresh() async { entries = await store.list(); _notify(); }
  Future<void> runNext() async {
    if (!ready || busy) return;
    busy = true; error = null; _notify();
    try { await worker.runNext(onClaim: refresh); await refresh(); }
    catch (_) { error = 'No se pudo procesar la cola. Revisa su estado.'; }
    finally { busy = false; _notify(); }
  }
  Future<void> retry(int id) async => _update(() => store.retry(id));
  Future<void> cancel(int id) async => _update(() => store.cancelQueued(id));
  Future<void> _update(Future<bool> Function() action) async {
    if (!ready || busy) return;
    try { if (!await action()) error = 'No se pudo actualizar la tarea.'; await refresh(); }
    catch (_) { error = 'No se pudo actualizar la tarea.'; _notify(); }
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
