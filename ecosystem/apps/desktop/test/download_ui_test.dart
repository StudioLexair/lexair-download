import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_desktop/app/app.dart';
import 'package:lexair_desktop/app/providers.dart';
import 'package:lexair_desktop/features/downloads/download_page.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

void main() {
  testWidgets('avisa antes de encolar ejecutables y cancelar no crea tarea', (tester) async {
    final dir = Directory.systemTemp.createTempSync('lexair-widget-');
    final db = LexairDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(overrides: [
      databaseProvider.overrideWithValue(db), chooseDownloadFolderProvider.overrideWithValue(() async => dir.path),
    ], child: const LexairApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descargar')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('download-url')), 'https://example.com/file');
    await tester.enterText(find.byKey(const Key('download-name')), 'test.exe');
    await tester.tap(find.text('Elegir carpeta')); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Añadir a la cola'));
    await tester.tap(find.text('Añadir a la cola')); await tester.pumpAndSettle();
    expect(find.text('Archivo ejecutable o script'), findsOneWidget);
    await tester.tap(find.text('Cancelar').last); await tester.pumpAndSettle();
    expect(await DownloadQueueStore(db).list(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink()); await db.close(); dir.deleteSync(recursive: true);
  });
}
