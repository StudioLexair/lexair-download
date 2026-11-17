import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';

final databaseProvider = Provider<LexairDatabase>((ref) {
  final database = LexairDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final themeProvider = AsyncNotifierProvider<ThemePreference, ThemeMode>(
  ThemePreference.new,
);

class ThemePreference extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final saved = await ref.read(databaseProvider).readSetting('theme');
    return saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(databaseProvider).writeSetting(
        'theme', mode == ThemeMode.light ? 'light' : 'dark',
      );
      return mode;
    });
  }
}
