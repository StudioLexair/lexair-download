# Lexair Download · Studio Lexair

Aplicación Flutter para Windows que utiliza yt-dlp para descargar vídeos de sitios compatibles cuando el usuario tiene derechos o permiso. No elude DRM. La disponibilidad, formatos y reglas varían según el sitio.

## Uso
Descarga el ZIP de Releases, extráelo por completo y abre `lexair_downloader.exe`. Pega el enlace, elige una carpeta y pulsa Descargar. El ejecutable `yt-dlp.exe` debe permanecer junto a la aplicación. El paquete selecciona un único archivo con vídeo y audio cuando está disponible; no utiliza FFmpeg ni promete la resolución máxima de todas las fuentes.

## Desarrollo
Instala Flutter estable y las herramientas de escritorio de C++ de Visual Studio. Después:
```
flutter create --platforms=windows --project-name lexair_downloader .
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```
Para probar descargas coloca `yt-dlp.exe` junto al ejecutable compilado. El flujo de GitHub Actions genera el ZIP como artefacto; al subir una etiqueta `v*`, además publica una Release. Descarga yt-dlp de su publicación oficial en tiempo de compilación: revisa sus términos y versiones antes de distribuir. No se verifica una suma de comprobación fijada, por lo que conviene fijar una versión y verificar su hash antes de una distribución de producción.

## Página web
`site/index.html` es una página estática lista para desplegar en Cloudflare Pages. El dominio `studiolexair.ddns.net` requiere que se configure en Cloudflare Pages y que su proveedor DNS permita crear el registro apropiado; no se modifica automáticamente.
