# Compatibilidad multimedia y códecs

Se utiliza `media_kit`, `media_kit_video` y `media_kit_libs_video` para incluir el conjunto de bibliotecas de vídeo y audio que distribuye Media Kit. Media Kit declara compatibilidad con una amplia variedad de contenedores y formatos, entre ellos MP4/MOV, Matroska/WebM y MP3, pero una extensión de archivo no garantiza que sus flujos internos se puedan decodificar. Un reproductor no puede prometer todos los códecs existentes o futuros, archivos corruptos, DRM o decodificadores propietarios sin verificar.

## Verificación necesaria antes de distribuir
- Inspeccionar los binarios libmpv/FFmpeg que se empaquetan exactamente en Windows; registrar versión, compilación, decodificadores y demultiplexores realmente disponibles.
- Crear un conjunto de pruebas con archivos de licencia adecuada, con MP4/H.264/AAC, MP4/H.265, MKV, WebM/VP9/Opus, AV1, MP3, FLAC, WAV, AAC y otros. Comprobar imagen, sonido, búsqueda y subtítulos, además de archivos dañados. No afirmar que funcionan hasta ejecutarlas en Windows.
- Revisar los avisos y licencias de todos los componentes nativos específicos, sus dependencias y las condiciones de distribución. La licencia del wrapper no basta.
- Si faltan códecs, evaluar binarios alternativos y sus condiciones antes de añadirlos. No descargar ni ejecutar DLL no verificadas.

La integración de subtítulos externos SRT/VTT/ASS/SSA se ha añadido al prototipo; requiere prueba real de reproducción.
