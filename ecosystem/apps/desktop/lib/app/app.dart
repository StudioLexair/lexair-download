import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexair_design_system/lexair_design_system.dart';
import 'providers.dart';
import 'router.dart';

class LexairApp extends ConsumerWidget {
  const LexairApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Lexair Download',
    theme: LexairTheme.create(Brightness.light),
    darkTheme: LexairTheme.create(Brightness.dark),
    themeMode: ref.watch(themeProvider).valueOrNull ?? ThemeMode.dark,
    routerConfig: ref.watch(routerProvider),
  );
}
