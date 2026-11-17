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
        const Text('Experimental · Una tarea a la vez. Se inicia manualmente. La pausa y el progreso aún no están disponibles en esta interfaz.'),
        const SizedBox(height: 8),
        const Text('Tras una interrupción, comprueba el destino antes de reintentar. No se sobrescriben archivos existentes.'),
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
