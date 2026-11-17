import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/shell.dart';
import '../features/discovery/discovery_page.dart';
import '../features/player/player_page.dart';
import '../features/downloads/download_page.dart';
import '../features/downloads/queue_page.dart';
import '../presentation/section_page.dart';
import 'sections.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        currentPath: state.uri.path, child: child,
      ),
      routes: [
        for (final section in sections)
          GoRoute(
            path: section.path,
            builder: (context, state) => switch (section.path) {
              '/' => const DiscoveryPage(),
              '/reproductor' => const PlayerPage(),
              '/descargar' => const DownloadPage(),
              '/cola' => const QueuePage(),
              _ => SectionPage(section: section),
            },
          ),
      ],
    ),
  ]);
  ref.onDispose(router.dispose);
  return router;
});
