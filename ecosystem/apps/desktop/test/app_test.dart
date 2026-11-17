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
      overrides: [databaseProvider.overrideWithValue(database)],
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
    expect(find.textContaining('Módulo pendiente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await database.close();
  });
}
