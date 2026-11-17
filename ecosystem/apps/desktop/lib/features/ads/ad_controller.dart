import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../app/providers.dart';
import 'ad_api.dart';
import 'ad_model.dart';
import 'ad_store.dart';

final adControllerProvider = ChangeNotifierProvider<AdController>((ref) {
  final client = http.Client();
  final controller = AdController(AdStore(ref.watch(databaseProvider)), AdApi(client));
  ref.onDispose(client.close);
  return controller;
});

class AdController extends ChangeNotifier {
  AdController(this.store, this.api);
  final AdStore store;
  final AdApi api;
  AdItem? floating, inline;
  final _views = <String, int>{};
  final _timers = <Timer>[];
  Future<void> _outbox = Future.value();
  Timer? _retry;
  String? _visitor;
  Future<String>? _visitorFuture;
  int _generation = 0;
  bool _disposed = false;

  void enter(String path) {
    leave();
    final normalized = path.toLowerCase();
    if (['/admin', '/login', '/pago', '/checkout', '/editor', '/contrato']
        .any(normalized.startsWith)) return;
    final gen = _generation;
    unawaited(_load(path, gen));
  }
  void leave({bool notify = true}) {
    _generation++;
    for (final timer in _timers) { timer.cancel(); }
    _timers.clear(); floating = null; inline = null;
    if (!_disposed && notify) notifyListeners();
  }
  Future<void> _load(String path, int gen) async {
    try {
      final visitor = await (_visitorFuture ??= store.visitor());
      _visitor = visitor;
      unawaited(flush().catchError((_) {}));
      final data = await api.getFeed(visitor, path);
      if (_disposed || gen != _generation) return;
      final f = AdItem.parse(data['floating']), i = AdItem.parse(data['inline']);
      if (f != null && f.placement != 'inline' && !_excluded(path, f)) _schedule(f, gen);
      if (i != null && i.placement == 'inline' && i.id != f?.id && !_excluded(path, i)) _schedule(i, gen);
    } catch (_) { /* Ads never block the app. */ }
  }
  bool _excluded(String path, AdItem ad) => ad.excluded.any((p) => p.isNotEmpty && path.toLowerCase().startsWith(p.toLowerCase()));
  void _schedule(AdItem ad, int gen) {
    _timers.add(Timer(Duration(seconds: ad.delay), () => unawaited(_show(ad, gen))));
  }
  Future<void> _show(AdItem ad, int gen) async {
    try {
      if (_disposed || gen != _generation ||
          (ad.placement == 'inline' ? inline != null : floating != null)) return;
      final now = DateTime.now();
      if (!await store.eligible(ad, now, _views[ad.id] ?? 0) || _disposed || gen != _generation) return;
      await store.seen(ad, now);
      if (_disposed || gen != _generation) return;
      _views[ad.id] = (_views[ad.id] ?? 0) + 1;
      if (ad.placement == 'inline') { inline = ad; } else { floating = ad; }
      notifyListeners();
      unawaited(_record(ad, 'impression').catchError((_) {}));
      if (ad.autoHide > 0) _timers.add(Timer(Duration(seconds: ad.autoHide), () => unawaited(dismiss(ad))));
    } catch (_) { /* Persistence failure means no ad. */ }
  }
  Future<void> dismiss(AdItem ad) async {
    if (floating?.id != ad.id && inline?.id != ad.id) return;
    try { await store.dismissed(ad, DateTime.now()); } catch (_) {}
    if (_disposed) return;
    if (floating?.id == ad.id) floating = null;
    if (inline?.id == ad.id) inline = null;
    notifyListeners();
  }
  Future<void> click(AdItem ad) async {
    try { await store.clicked(ad); await _record(ad, 'click'); } catch (_) {}
    if (_disposed) return;
    if (floating?.id == ad.id) floating = null;
    if (inline?.id == ad.id) inline = null;
    notifyListeners();
  }
  Future<void> _record(AdItem ad, String event) {
    final visitor = _visitor;
    if (visitor == null) return Future.value();
    final task = _outbox.then((_) async {
      final list = await store.pending();
      list.add({'ad_id': ad.id, 'event': event, 'visitor_id': visitor, 'project': adProject});
      await store.savePending(list);
    });
    _outbox = task.catchError((_) {});
    return task.then((_) => flush());
  }
  Future<void> flush() {
    final task = _outbox.then((_) async {
      final list = await store.pending();
      while (list.isNotEmpty && !_disposed) {
        try { await api.send(list.first); }
        catch (_) {
          _retry ??= Timer(const Duration(minutes: 1), () { _retry = null; unawaited(flush().catchError((_) {})); });
          return;
        }
        list.removeAt(0); await store.savePending(list);
      }
    });
    _outbox = task.catchError((_) {});
    return task;
  }
  @override
  void dispose() { _disposed = true; leave(); _retry?.cancel(); super.dispose(); }
}
