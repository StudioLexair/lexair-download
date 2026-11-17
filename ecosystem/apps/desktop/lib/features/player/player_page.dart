import 'dart:async';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'player_controls.dart';
import 'player_session.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  PlayerSession? session;
  StreamSubscription<String>? errors;
  String? filename;
  String? error;

  @override
  void initState() {
    super.initState();
    try {
      final created = PlayerSession();
      session = created;
      errors = created.player.stream.error.listen((message) {
        if (mounted) setState(() => error = 'No se pudo reproducir el archivo: $message');
      });
    } catch (e) {
      error = 'El motor multimedia no está disponible: $e';
    }
  }

  Future<void> chooseFile() async {
    try {
      final file = await openFile(confirmButtonText: 'Abrir en Lexair');
      if (file == null || !mounted) return;
      setState(() { filename = file.name; error = null; });
      await session!.openFile(file.path);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo abrir el archivo: $e');
    }
  }

  Future<void> chooseSubtitles() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Subtítulos', extensions: ['srt', 'vtt', 'ass', 'ssa']),
        ],
        confirmButtonText: 'Cargar subtítulos',
      );
      if (file == null || !mounted) return;
      await session!.loadSubtitles(file.path);
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudieron cargar los subtítulos: $e');
    }
  }

  @override
  void dispose() {
    unawaited(errors?.cancel());
    if (session != null) unawaited(session!.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = session;
    if (active == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(error ?? 'No se pudo iniciar el motor multimedia.'),
      ));
    }
    return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TU ESPACIO MULTIMEDIA', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('Reproductor', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Tus archivos locales, en un solo lugar.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 25),
        ClipRRect(borderRadius: BorderRadius.circular(18), child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: Colors.black, child: Stack(alignment: Alignment.center, children: [
            Video(controller: active.video, controls: MaterialDesktopVideoControls),
            if (filename == null) const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
              SizedBox(height: 12), Text('Elige un archivo para empezar', style: TextStyle(color: Colors.white70)),
            ]),
          ])),
        )),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Text(filename ?? 'Ningún archivo abierto', overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          FilledButton.icon(onPressed: chooseFile, icon: const Icon(Icons.folder_open), label: const Text('Abrir archivo')),
        ]),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: filename == null ? null : chooseSubtitles,
          icon: const Icon(Icons.subtitles_outlined),
          label: const Text('Cargar subtítulos'),
        ),
        const SizedBox(height: 14),
        PlayerControls(session: active, enabled: filename != null),
        const SizedBox(height: 20),
        Text('Compatibilidad según el contenedor, el códec y las bibliotecas disponibles. Los archivos protegidos por DRM no son compatibles.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ]),
    )),
  );
  }
}
