# Lexair Download — nueva foundation

Monorepositorio modular en desarrollo, separado del producto anterior. Incluye base Flutter de escritorio, paquetes de diseño y persistencia, web modular Vite y documentación. Incluye un motor HTTP directo y cola experimentales, aún no conectados a la interfaz; no reemplaza todavía la versión anterior.

## Verificación Flutter
Con Flutter estable instalado:
```sh
cd packages/storage_core
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
cd ../../apps/desktop
flutter create --platforms=windows --project-name lexair_desktop .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build windows --release
```
En Windows, copia `app_icon.ico` a `windows/runner/resources/app_icon.ico` antes de compilar. Compilación Windows requiere Windows y Visual Studio con herramientas C++.

## Web
```
cd apps/web
npm ci
npm run build
```
Salida `dist/` compatible con Cloudflare Pages. Los botones muestran error si los ZIP no se colocan en `public/downloads/` antes de compilar. No hay despliegue automatizado ni recursos de descarga incluidos en esta foundation. La web heredada debe revisarse antes de publicarse.

Ver `docs/architecture/architecture.md` y `docs/product/status.md`. No se incluye licencia del proyecto: está pendiente de decisión de Studio Lexair.

## Prototipo multimedia
La nueva interfaz incluye selección de plataformas sin resultados simulados y un reproductor local basado en Media Kit. El soporte real depende de los códecs y bibliotecas nativas disponibles; aún no se garantiza compatibilidad universal. Antes de distribuir, auditar las licencias de mpv, FFmpeg, códecs y binarios concretos. Véase `docs/architecture/media-player.md`.

## Lexair Engine — primer incremento experimental
`packages/download_engine` contiene una biblioteca Dart en desarrollo para archivos HTTP directos. No está conectada a la interfaz y requiere auditoría de seguridad y pruebas TLS/Windows antes de usarse con enlaces externos. Detalles y límites: `docs/architecture/lexair-engine-fase-2.md`.
