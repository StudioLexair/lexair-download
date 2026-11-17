import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:lexair_desktop/features/ads/ad_controller.dart';
import 'package:lexair_desktop/features/ads/ad_api.dart';
import 'package:lexair_desktop/features/ads/ad_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexair_desktop/app/app.dart';
import 'package:lexair_desktop/app/providers.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

void main() {
  testWidgets('muestra el inicio y sección pendiente', (tester) async {
    final database = LexairDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database), adControllerProvider.overrideWith((ref) => AdController(AdStore(database), AdApi(MockClient((_) async => http.Response('{\"ok\":true,\"floating\":null,\"inline\":null}', 200)))))],
      child: const LexairApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Tu espacio para descubrir.'), findsOneWidget);
    expect(find.text('Integración de YouTube pendiente'), findsOneWidget);
    await tester.tap(find.text('TikTok'));
    await tester.pumpAndSettle();
    expect(find.text('Integración de TikTok pendiente'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'música');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Resultados en TikTok'), findsOneWidget);
    expect(find.text('Búsqueda: música'), findsOneWidget);
    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(find.text('Descarga directa experimental'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await database.close();
  });
}
