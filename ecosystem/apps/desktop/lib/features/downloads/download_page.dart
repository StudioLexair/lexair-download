import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'queue_controller.dart';

final chooseDownloadFolderProvider = Provider<Future<String?> Function()>((ref) =>
  () => getDirectoryPath(confirmButtonText: 'Elegir carpeta'));

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});
  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final url = TextEditingController(), filename = TextEditingController();
  String? folder;
  bool submitting = false;
  @override
  void dispose() { url.dispose(); filename.dispose(); super.dispose(); }

  Future<void> chooseFolder() async {
    try {
      final path = await ref.read(chooseDownloadFolderProvider)();
      if (path != null && mounted) setState(() => folder = path);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo seleccionar la carpeta.')));
    }
  }
  Future<void> enqueue() async {
    if (folder == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una carpeta primero.'))); return;
    }
    final dangerous = RegExp(r'\.(exe|msi|bat|cmd|ps1|scr|com|vbs|js|jar|sh)$', caseSensitive: false).hasMatch(filename.text);
    if (dangerous) {
      final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Archivo ejecutable o script'),
        content: const Text('Puede contener código peligroso. Descárgalo solo si confías en el origen; no se ejecutará automáticamente.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Entiendo el riesgo'))],
      ));
      if (accepted != true || !mounted) return;
    }
    setState(() => submitting = true);
    final success = await ref.read(queueControllerProvider).enqueue(url: url.text, filename: filename.text, folder: folder!);
    if (!mounted) return;
    setState(() => submitting = false);
    if (success) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añadido a la cola.'))); context.go('/cola'); }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueControllerProvider);
    return SingleChildScrollView(padding: const EdgeInsets.all(36), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Descarga directa experimental', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text('Solo archivos HTTP/HTTPS directos autorizados. No extrae vídeos de YouTube ni de otras redes. Sin redirecciones; máximo 1 GiB.'),
        const SizedBox(height: 12),
        const Text('Prototipo sin auditoría completa: usa una carpeta de confianza. No ejecutes archivos de origen desconocido.'),
        const SizedBox(height: 24),
        TextField(key: const Key('download-url'), controller: url, decoration: const InputDecoration(labelText: 'URL directa del archivo', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(key: const Key('download-name'), controller: filename, decoration: const InputDecoration(labelText: 'Nombre del archivo', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: submitting ? null : chooseFolder, icon: const Icon(Icons.folder_open), label: const Text('Elegir carpeta')),
        const SizedBox(height: 8), Text(folder ?? 'Ninguna carpeta seleccionada'),
        if (queue.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(queue.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: queue.ready && !queue.busy && !submitting ? enqueue : null,
          icon: const Icon(Icons.playlist_add), label: const Text('Añadir a la cola')),
        const SizedBox(height: 8),
        const Text('La URL se guarda en la base local, incluidos sus parámetros. No pegues enlaces con secretos.'),
      ]),
    )));
  }
}
