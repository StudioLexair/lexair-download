import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/sections.dart';

class SectionPage extends ConsumerWidget {
  const SectionPage({super.key, required this.section});
  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STUDIO LEXAIR  /  LEXAIR DOWNLOAD',
          style: TextStyle(color: colors.primary, letterSpacing: 1.2, fontSize: 11)),
        const SizedBox(height: 20),
        Text(section.label, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        if (section.path == '/') ...[
          Text('Un solo lugar para tu contenido digital.',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('Fundación inicial. El motor de descargas, la biblioteca y el reproductor aún no están implementados.'),
        ] else if (section.path == '/configuracion') ...[
          const Text('Apariencia'), const SizedBox(height: 12),
          ref.watch(themeProvider).when(
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('No se pudo leer la configuración: $error'),
            data: (mode) => SwitchListTile(
              title: const Text('Tema claro'),
              subtitle: const Text('Preferencia guardada en este dispositivo'),
              value: mode == ThemeMode.light,
              onChanged: (value) => ref.read(themeProvider.notifier)
                  .setTheme(value ? ThemeMode.light : ThemeMode.dark),
            ),
          ),
        ] else if (section.path == '/acerca') ...[
          const Text('Lexair Download · Studio Lexair'),
          const SizedBox(height: 8),
          const Text('Fundación de desarrollo · No es una versión estable.'),
        ] else ...[
          Card(child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(children: [
              Icon(section.icon, size: 36, color: colors.primary),
              const SizedBox(width: 20),
              const Expanded(child: Text('Módulo pendiente de implementación. Esta sección aún no realiza operaciones.')),
            ]),
          )),
        ],
      ]),
    );
  }
}
