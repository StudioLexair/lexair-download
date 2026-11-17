import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

void main() => runApp(const LexairApp());

class LexairApp extends StatelessWidget {
  const LexairApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Lexair Download',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8b7bff), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xff10111b)),
    home: const DownloadPage(),
  );
}

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});
  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final url = TextEditingController();
  String? folder;
  String quality = 'Mejor disponible';
  String status = 'Listo para descargar';
  String log = '';
  Process? process;
  bool busy = false;

  @override
  void dispose() { url.dispose(); super.dispose(); }

  Future<void> download() async {
    final uri = Uri.tryParse(url.text.trim());
    if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
      setState(() => status = 'Introduce una URL HTTP o HTTPS válida.'); return;
    }
    if (folder == null) { setState(() => status = 'Selecciona una carpeta de destino.'); return; }
    final tool = File(p.join(p.dirname(Platform.resolvedExecutable), 'yt-dlp.exe'));
    if (!await tool.exists()) { setState(() => status = 'No se encuentra yt-dlp.exe junto a la aplicación. Descarga el paquete completo.'); return; }
    final format = quality == 'Hasta 720p' ? 'best[height<=720]/best' : 'best';
    setState(() { busy = true; status = 'Iniciando descarga…'; log = ''; });
    try {
      final child = await Process.start(tool.path, [
        '--newline', '--no-playlist', '--no-overwrites', '--windows-filenames',
        '-f', format, '-P', folder!, '-o', '%(title).180B [%(id)s].%(ext)s', '--', uri.toString(),
      ], runInShell: false);
      process = child;
      void append(String line) { if (!mounted) return; setState(() { log = '$log$line\n'; if (log.length > 12000) log = log.substring(log.length - 12000); if (line.startsWith('[download]')) status = line; }); }
      final out = child.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach(append);
      final err = child.stderr.transform(utf8.decoder).transform(const LineSplitter()).forEach(append);
      final code = await child.exitCode;
      await Future.wait([out, err]);
      if (mounted) setState(() => status = code == 0 ? 'Descarga terminada. Revisa la carpeta elegida.' : 'La descarga terminó con error (código $code). Consulta el registro.');
    } catch (e) { if (mounted) setState(() => status = 'No se pudo iniciar la descarga: $e'); }
    finally { process = null; if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: SingleChildScrollView(
      padding: const EdgeInsets.all(32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.play_circle_fill_rounded, color: Color(0xffa69aff), size: 38), SizedBox(width: 12), Text('LEXAIR DOWNLOAD', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1.5)), Spacer(), Text('STUDIO LEXAIR', style: TextStyle(color: Colors.white54, letterSpacing: 2))]),
        const SizedBox(height: 40), const Text('Tus vídeos,\na tu manera.', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, height: 1.1)),
        const SizedBox(height: 12), const Text('Descarga contenido autorizado de sitios compatibles.', style: TextStyle(color: Colors.white60, fontSize: 16)),
        const SizedBox(height: 32),
        TextField(controller: url, enabled: !busy, decoration: const InputDecoration(labelText: 'Enlace del vídeo', hintText: 'https://...', prefixIcon: Icon(Icons.link), border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: busy ? null : () async { final selected = await getDirectoryPath(); if (selected != null && mounted) setState(() => folder = selected); }, icon: const Icon(Icons.folder_open), label: Text(folder ?? 'Elegir carpeta', maxLines: 1, overflow: TextOverflow.ellipsis))), const SizedBox(width: 12), DropdownButton<String>(value: quality, onChanged: busy ? null : (value) => setState(() => quality = value!), items: const [DropdownMenuItem(value: 'Mejor disponible', child: Text('Mejor disponible')), DropdownMenuItem(value: 'Hasta 720p', child: Text('Hasta 720p'))])]),
        const SizedBox(height: 20), SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: busy ? null : download, icon: const Icon(Icons.download), label: Text(busy ? 'Descargando…' : 'Descargar vídeo'))),
        const SizedBox(height: 20), Text(status), if (busy) ...[const SizedBox(height: 10), const LinearProgressIndicator()],
        const SizedBox(height: 20), if (log.isNotEmpty) Container(width: double.infinity, constraints: const BoxConstraints(maxHeight: 180), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)), child: SingleChildScrollView(reverse: true, child: SelectableText(log, style: const TextStyle(fontSize: 12, color: Colors.white70)))),
        const SizedBox(height: 30), const Text('Usa esta herramienta solo con contenido propio o con permiso. No admite contenido protegido por DRM. La compatibilidad depende de cada sitio.', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ])))));
}
