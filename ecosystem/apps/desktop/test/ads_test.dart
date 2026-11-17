import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexair_desktop/features/ads/ad_api.dart';
import 'package:lexair_desktop/features/ads/ad_controller.dart';
import 'package:lexair_desktop/features/ads/ad_model.dart';
import 'package:lexair_desktop/features/ads/ad_store.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

Map<String, dynamic> data({String id = '11111111-1111-4111-8111-111111111111', String place = 'corner',
    String mode = 'cooldown'}) => {
  'id': id, 'title': 'Anuncio', 'media_type': 'image', 'media_url': 'https://example.com/image.png',
  'target_url': '/planes', 'placement': place, 'position': 'bottom-right', 'delay_seconds': 0,
  'cooldown_hours': 2, 'max_views_per_session': 2, 'auto_hide_seconds': 0, 'frequency_mode': mode,
};

Future<void> waitUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i++) { if (condition()) return; await Future<void>.delayed(const Duration(milliseconds: 10)); }
  throw StateError('Timeout esperando el anuncio');
}

void main() {
  test('valida HTTPS y rechaza URLs peligrosas o ambiguas', () {
    for (final value in ['http://bad.test', 'javascript:alert(1)', '//bad.test/x', '/\\bad.test/x', 'https://user@host.test/x']) {
      expect(adHttpsUrl(value, allowRelative: true), isNull, reason: value);
    }
    expect(adHttpsUrl('/planes', allowRelative: true).toString(), 'https://studiolexair.ddns.net/planes');
    expect(AdItem.parse({...data(), 'media_url': 'http://bad.test/x'}), isNull);
    expect(AdItem.parse({...data(), 'target_url': 'javascript:alert(1)'}), isNull);
  });
  test('visitor persistente y reglas locales once, cooldown y clic', () async {
    final dir = await Directory.systemTemp.createTemp('ads-store-');
    final file = File('${dir.path}/settings.sqlite');
    var db = LexairDatabase(NativeDatabase(file)); var store = AdStore(db);
    final visitor = await store.visitor();
    expect(visitor, matches(RegExp(r'^v-[0-9a-f-]{36}$')));
    final ad = AdItem.parse(data(mode: 'once'))!; final now = DateTime.now();
    expect(await store.eligible(ad, now, 0), isTrue);
    await store.seen(ad, now); await db.close();
    db = LexairDatabase(NativeDatabase(file)); store = AdStore(db);
    expect(await store.visitor(), visitor);
    expect(await store.eligible(ad, now.add(const Duration(days: 999)), 0), isFalse);
    final other = AdItem.parse(data(id: '22222222-2222-4222-8222-222222222222'))!;
    await store.dismissed(other, now);
    expect(await store.eligible(other, now.add(const Duration(hours: 1)), 0), isFalse);
    expect(await store.eligible(other, now.add(const Duration(hours: 3)), 0), isTrue);
    await store.clicked(other);
    expect(await store.eligible(other, now.add(const Duration(days: 1)), 0), isFalse);
    await db.close(); await dir.delete(recursive: true);
  });
  test('feed y cola persistente de eventos reintentan sin red y envían visitante', () async {
    final db = LexairDatabase(NativeDatabase.memory()); final store = AdStore(db);
    var fail = true; final events = <Map<String, dynamic>>[]; var gets = 0;
    final client = MockClient((req) async {
      if (req.method == 'GET') {
        gets++; expect(req.url.queryParameters['project'], 'lexairdownload');
        expect(req.url.queryParameters['path'], '/');
        expect(req.url.queryParameters['visitor'], startsWith('v-'));
        return http.Response(jsonEncode({'ok':true, 'floating':data(), 'inline':null}), 200);
      }
      if (fail) return http.Response('', 503);
      events.add(jsonDecode(req.body) as Map<String, dynamic>); return http.Response('{}', 200);
    });
    final controller = AdController(store, AdApi(client)); controller.enter('/');
    await waitUntil(() => controller.floating != null);
    await controller.click(controller.floating!);
    expect((await store.pending()).map((e) => e['event']), containsAll(['impression', 'click']));
    fail = false; await controller.flush();
    expect(await store.pending(), isEmpty);
    expect(events.map((e) => e['event']), containsAllInOrder(['impression', 'click']));
    final visitor = await store.visitor();
    expect(events.every((e) => e['project'] == 'lexairdownload' && e['visitor_id'] == visitor), isTrue);
    expect(gets, 1); controller.dispose(); client.close(); await db.close();
  });
  test('filtra rutas excluidas, inválidas y respuestas vacías sin bloquear', () async {
    final db = LexairDatabase(NativeDatabase.memory()); final store = AdStore(db);
    final client = MockClient((req) async => http.Response(jsonEncode({'ok':true,
      'floating': {...data(), 'exclude_paths': ['/']}, 'inline': {...data(place: 'inline'), 'target_url':'http://unsafe'}}), 200));
    final controller = AdController(store, AdApi(client)); controller.enter('/');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(controller.floating, isNull); expect(controller.inline, isNull);
    controller.dispose(); client.close(); await db.close();
  });
  test('respeta retardo y autocierre sin bloquear la interfaz', () async {
    final db = LexairDatabase(NativeDatabase.memory()); final store = AdStore(db);
    final client = MockClient((req) async => req.method == 'GET'
      ? http.Response(jsonEncode({'ok':true, 'floating': {...data(), 'delay_seconds':1, 'auto_hide_seconds':1}, 'inline': null}), 200)
      : http.Response('{}', 200));
    final controller = AdController(store, AdApi(client)); controller.enter('/');
    await Future<void>.delayed(const Duration(milliseconds: 100)); expect(controller.floating, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 1050)); expect(controller.floating, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 1050)); expect(controller.floating, isNull);
    expect(await store.eligible(AdItem.parse(data())!, DateTime.now(), 0), isFalse);
    controller.dispose(); client.close(); await db.close();
  });

  test('rutas sensibles se bloquean aunque el feed no las excluya', () async {
    final db = LexairDatabase(NativeDatabase.memory()); var gets = 0;
    final client = MockClient((req) async { gets++; return http.Response('{}', 200); });
    final c = AdController(AdStore(db), AdApi(client));
    for (final p in ['/admin', '/login', '/pago/1', '/checkout', '/editor']) { c.enter(p); }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(gets, 0); expect(c.floating, isNull); c.dispose(); client.close(); await db.close();
  });
  test('outbox sobrevive cierre de SQLite y se reintenta', () async {
    final dir = await Directory.systemTemp.createTemp('ads-outbox-'); final file = File('${dir.path}/db');
    var db = LexairDatabase(NativeDatabase(file)); var store = AdStore(db);
    final visitor = await store.visitor();
    await store.savePending([{'ad_id': data()['id'], 'event':'click', 'visitor_id':visitor, 'project':adProject}]);
    await db.close(); db = LexairDatabase(NativeDatabase(file)); store = AdStore(db);
    var calls = 0;
    final client = MockClient((req) async { calls++; expect(req.method, 'POST');
      expect((jsonDecode(req.body) as Map)['visitor_id'], visitor); return http.Response('{}', 200); });
    final controller = AdController(store, AdApi(client)); await controller.flush();
    expect(calls, 1); expect(await store.pending(), isEmpty);
    controller.dispose(); client.close(); await db.close(); await dir.delete(recursive: true);
  });

  test('como máximo un flotante y un inline, sin duplicar ID', () async {
    final db = LexairDatabase(NativeDatabase.memory()); final store = AdStore(db);
    final inline = data(id:'22222222-2222-4222-8222-222222222222', place:'inline');
    final client = MockClient((req) async => req.method == 'GET'
      ? http.Response(jsonEncode({'ok':true, 'floating':data(), 'inline':inline}), 200) : http.Response('{}', 200));
    final c = AdController(store, AdApi(client)); c.enter('/');
    await waitUntil(() => c.floating != null && c.inline != null);
    expect(c.floating!.id, isNot(c.inline!.id));
    await c.flush(); c.dispose(); client.close(); await db.close();
  });

}
