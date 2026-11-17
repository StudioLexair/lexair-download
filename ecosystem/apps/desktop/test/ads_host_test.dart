import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexair_desktop/app/providers.dart';
import 'package:lexair_desktop/features/ads/ad_api.dart';
import 'package:lexair_desktop/features/ads/ad_controller.dart';
import 'package:lexair_desktop/features/ads/ad_host.dart';
import 'package:lexair_desktop/features/ads/ad_store.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

void main() {
  testWidgets('un formulario activo cancela el anuncio antes de mostrarse', (tester) async {
    final db = LexairDatabase(NativeDatabase.memory());
    var requests = 0;
    final client = MockClient((req) async { requests++; return http.Response(jsonEncode({'ok':true,
      'floating': {'id':'11111111-1111-4111-8111-111111111111', 'title':'No interrumpir',
      'media_url':'https://example.com/image.png', 'target_url':'https://example.com/',
      'media_type':'image','placement':'corner','delay_seconds':2,'frequency_mode':'once','max_views_per_session':1},
      'inline':null}), 200); });
    await tester.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db),
      adControllerProvider.overrideWith((ref) => AdController(AdStore(db), AdApi(client)))],
      child: const MaterialApp(home: Scaffold(body: AdHost(child: TextField())))));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 50));
    expect(requests, 1);
    await tester.tap(find.byType(TextField)); await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('No interrumpir'), findsNothing);
    expect(await db.readSetting('seen_11111111-1111-4111-8111-111111111111'), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); client.close(); await db.close();
  });
}
