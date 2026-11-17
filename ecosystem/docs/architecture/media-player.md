# Investigación y diseño: reproductor y exploración

## Decisión de prototipo
Media Kit + libmpv es candidato para Flutter desktop: documenta audio, vídeo, playlists, aceleración y soporte Windows, Android y Linux. El paquete Dart es MIT, pero esa licencia no determina las licencias ni opciones de compilación de las dependencias nativas. Antes de publicar una distribución hay que identificar binarios concretos, licencias de mpv/FFmpeg/códecs, avisos, fuente correspondiente y requisitos de redistribución. Alternativa: video_player con complemento de Windows, con cobertura distinta según plataforma.

## Entrega de desarrollo
Reproducción local mediante selección de archivos, vídeo/audio con motor Media Kit, play/pause, stop, búsqueda temporal, volumen, velocidad y controles de vídeo de Media Kit que ofrecen pantalla completa. No se ha demostrado compatibilidad con todos los formatos; depende de contenedores, códecs y binarios. La primera versión no incluye subtítulos externos, listas, historial, ni conexiones de búsqueda. La pantalla completa mediante Media Kit y la reproducción aún necesitan pruebas funcionales en Windows. Audio/video remoto no está habilitado en esta interfaz. La pantalla dispone el motor bajo `PlayerSession`, no ejecuta procesos directamente.

## Exploración
Selector de YouTube, TikTok, Instagram, Facebook y X y formulario de búsqueda. No hay fuente conectada: no se inventan resultados ni tendencias. Para YouTube, estudiar la API Data (`search.list` y `videos.list`/`mostPopular`, sujetos a términos y cuotas) y viabilidad legal de presentar y reproducir contenido. Las demás plataformas requieren verificar permisos, APIs y capacidades reales por plataforma. No usar credenciales embebidas.

Fuentes: https://pub.dev/packages/media_kit ; https://pub.dev/packages/video_player ; https://developers.google.com/youtube/v3/docs/search/list ; https://developers.google.com/youtube/v3/docs/videos/list
