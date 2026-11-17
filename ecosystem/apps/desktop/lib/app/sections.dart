import 'package:flutter/material.dart';

class AppSection {
  const AppSection(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const sections = <AppSection>[
  AppSection('/', 'Inicio', Icons.dashboard_outlined),
  AppSection('/descargar', 'Descargar', Icons.download_outlined),
  AppSection('/explorador', 'Explorador de enlaces', Icons.link),
  AppSection('/videos', 'Vídeos', Icons.movie_outlined),
  AppSection('/musica', 'Música', Icons.music_note_outlined),
  AppSection('/imagenes', 'Imágenes', Icons.image_outlined),
  AppSection('/documentos', 'Documentos', Icons.description_outlined),
  AppSection('/archivos', 'Archivos', Icons.folder_outlined),
  AppSection('/reproductor', 'Reproductor', Icons.play_circle_outline),
  AppSection('/biblioteca', 'Biblioteca', Icons.collections_bookmark_outlined),
  AppSection('/cola', 'Cola', Icons.queue_outlined),
  AppSection('/historial', 'Historial', Icons.history),
  AppSection('/extensiones', 'Extensiones', Icons.extension_outlined),
  AppSection('/configuracion', 'Configuración', Icons.settings_outlined),
  AppSection('/acerca', 'Acerca de', Icons.info_outline),
];
