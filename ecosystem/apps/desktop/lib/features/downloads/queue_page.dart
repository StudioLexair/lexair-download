import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexair_storage_core/lexair_storage_core.dart';
import 'queue_controller.dart';

String _label(QueueState state) => switch (state) {
  QueueState.queued => 'Pendiente', QueueState.running => 'En curso',
  QueueState.completed => 'Completada', QueueState.failed => 'Fallida',
  QueueState.interrupted => 'Interrumpida', QueueState.cancelled => 'Cancelada',
};

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueControllerProvider);
    return SingleChildScrollView(padding: const EdgeInsets.all(36), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cola de descargas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        const Text('Experimental · Una tarea a la vez, iniciada manualmente. El modo con pausa requiere tamaño conocido y ETag fuerte; si el servidor no los ofrece, la tarea fallará.'),
        const SizedBox(height: 8),
        const Text('Tras una pausa, pulsa Reintentar y luego Iniciar siguiente. Una interrupción inesperada puede requerir revisión manual. No se sobrescriben archivos.'),
        const SizedBox(height: 12),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Modo con pausa experimental'),
          subtitle: const Text('Guarda parciales en la carpeta de datos de la aplicación; no se borran automáticamente.'),
          value: queue.pausable, onChanged: queue.busy ? null : (value) => ref.read(queueControllerProvider).setPausable(value)),
        if (queue.busy) ...[
          LinearProgressIndicator(value: queue.totalBytes != null && queue.totalBytes! > 0
            ? (queue.bytesReceived / queue.totalBytes!).clamp(0.0, 1.0) : null),
          const SizedBox(height: 8),
          Text(queue.totalBytes == null ? '${queue.bytesReceived} bytes recibidos'
            : '${queue.bytesReceived} / ${queue.totalBytes} bytes'),
          if (queue.pausable) TextButton.icon(onPressed: queue.canPause ? () => ref.read(queueControllerProvider).requestPause() : null,
            icon: const Icon(Icons.pause), label: Text(queue.pauseRequested ? 'Pausa solicitada…' : 'Pausar')),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: queue.ready && !queue.busy && queue.entries.any((e) => e.state == QueueState.queued)
            ? () => ref.read(queueControllerProvider).runNext() : null,
          icon: const Icon(Icons.play_arrow), label: Text(queue.busy ? 'Procesando…' : 'Iniciar siguiente')),
        if (queue.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(queue.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        if (!queue.ready && queue.error == null) const CircularProgressIndicator(),
        if (queue.ready && queue.entries.isEmpty) const Text('La cola está vacía.'),
        for (final entry in queue.entries) Card(child: ListTile(
          key: ValueKey('queue-${entry.id}'),
          title: Text(entry.filename),
          subtitle: Text('${_label(entry.state)} · ${entry.directory}'),
          trailing: entry.state == QueueState.queued
            ? TextButton(onPressed: queue.busy ? null : () => ref.read(queueControllerProvider).cancel(entry.id), child: const Text('Cancelar'))
            : (entry.state == QueueState.failed || entry.state == QueueState.interrupted)
              ? TextButton(onPressed: queue.busy ? null : () => ref.read(queueControllerProvider).retry(entry.id), child: const Text('Reintentar'))
              : null,
        )),
        if (queue.entries.any((e) => e.state == QueueState.failed))
          const Padding(padding: EdgeInsets.only(top: 12), child: Text('Una tarea falló. El prototipo aún no muestra detalles del error.')),
      ]),
    )));
  }
}
