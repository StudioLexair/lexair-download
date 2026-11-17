import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

void main() {
  test('configuración se guarda y actualiza', () async {
    final db = LexairDatabase(NativeDatabase.memory());
    expect(await db.readSetting('theme'), isNull);
    await db.writeSetting('theme', 'dark');
    expect(await db.readSetting('theme'), 'dark');
    await db.writeSetting('theme', 'light');
    expect(await db.readSetting('theme'), 'light');
    await db.close();
  });
}
