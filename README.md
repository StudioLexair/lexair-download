# Lexair Download · Studio Lexair

Aplicación Flutter para Windows que utiliza yt-dlp para descargar vídeo y audio de sitios compatibles, solo cuando el usuario tiene derechos o permiso. No elude DRM. La disponibilidad, formatos y reglas varían según el sitio; no promete descargar cualquier archivo o de cualquier plataforma.

## Uso
Descarga el ZIP de Releases, extráelo por completo y abre `lexair_downloader.exe`. Pega el enlace, elige vídeo o audio, una carpeta y pulsa Descargar. Mantén `yt-dlp.exe` junto a la aplicación. El modo vídeo elige un único archivo con vídeo y audio cuando está disponible. Audio descarga el formato original, no necesariamente MP3. No se utiliza FFmpeg; no siempre es posible obtener la resolución máxima. No hay reproductor integrado todavía.

## Extensión experimental
El ZIP de extensión incluye instrucciones para cargarla manualmente en Chrome o Edge. Busca enlaces directos visibles en la pestaña actual solo al pulsar el botón; permite copiarlos manualmente a Lexair. No detecta todos los medios ni enlaces blob y no evita DRM. No está publicada en tiendas ni se conecta automáticamente a la aplicación.

## Desarrollo
Instala Flutter estable y Visual Studio con herramientas de C++ de escritorio:
```
flutter create --platforms=windows --project-name lexair_downloader .
```
Copia `assets/app_icon.ico` a `windows/runner/resources/app_icon.ico`, y ejecuta:
```
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build windows --release
```
Para probar descargas coloca `yt-dlp.exe` junto al ejecutable compilado. GitHub Actions compila el ZIP y al subir una etiqueta `v*` publica una Release. Descarga yt-dlp desde su publicación oficial en tiempo de compilación. Para producción conviene fijar una versión y verificar su hash.

## Página web
GitHub Pages despliega `site/` e incluye el ZIP de la última Release en `downloads/` durante el despliegue. Los botones descargan el archivo desde el mismo sitio y avisan si no está disponible. Un flujo posterior a la compilación actualiza el ZIP publicado. El dominio `studiolexair.ddns.net` necesita configuración DNS y de hosting.
