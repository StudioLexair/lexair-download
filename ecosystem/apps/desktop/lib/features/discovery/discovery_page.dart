import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'platforms.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});
  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final search = TextEditingController();
  var platform = DiscoveryPlatform.youtube;
  String? submittedQuery;

  @override
  void dispose() { search.dispose(); super.dispose(); }

  void submit() {
    final text = search.text.trim();
    setState(() => submittedQuery = text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DESCUBRE SIN LÍMITES', style: TextStyle(
                color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Tu espacio para descubrir.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ])),
            OutlinedButton.icon(onPressed: () => context.go('/reproductor'),
              icon: const Icon(Icons.play_circle_outline), label: const Text('Abrir reproductor')),
          ]),
          const SizedBox(height: 30),
          TextField(controller: search, onSubmitted: (_) => submit(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Busca vídeos, creadores y más',
              filled: true, fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixIcon: IconButton(onPressed: submit, tooltip: 'Buscar', icon: const Icon(Icons.arrow_forward)),
            )),
          const SizedBox(height: 25),
          Wrap(spacing: 9, runSpacing: 9, children: [
            for (final item in DiscoveryPlatform.values)
              ChoiceChip(label: Text(item.label), selected: platform == item,
                onSelected: (_) => setState(() { platform = item; submittedQuery = null; })),
          ]),
          const SizedBox(height: 38),
          Text(submittedQuery == null ? 'Tendencias en ${platform.label}' : 'Resultados en ${platform.label}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(submittedQuery == null
            ? 'Explora lo que está pasando en la plataforma seleccionada.'
            : 'Búsqueda: $submittedQuery', style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 22),
          Container(width: double.infinity, padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant.withValues(alpha: .35))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.travel_explore, size: 30, color: colors.primary),
              const SizedBox(height: 18),
              Text('Integración de ${platform.label} pendiente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Aún no hay resultados ni tendencias reales conectados. No mostramos contenido inventado.',
                style: TextStyle(color: colors.onSurfaceVariant)),
            ])),
          const SizedBox(height: 30),
          Text('También en Lexair', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Card(child: ListTile(contentPadding: const EdgeInsets.all(14),
            leading: Icon(Icons.movie_filter_outlined, color: colors.primary),
            title: const Text('Reproductor local'),
            subtitle: const Text('Abre y reproduce un archivo de tu dispositivo.'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => context.go('/reproductor'))),
        ]),
      )),
    );
  }
}
