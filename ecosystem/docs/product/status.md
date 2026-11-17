# Estado del producto

## Fase 0
Inspección: entorno Linux, Flutter/Dart instalados temporalmente para comprobación; no hay toolchain de compilación Windows nativa. La compilación final de Windows debe hacerse en Windows mediante CI o un equipo local. Licencias preliminares documentadas; auditoría completa de bibliotecas nativas pendiente.

## Fase 1 — en curso
Se han creado la navegación de escritorio, tema y almacenamiento Drift, con pruebas. Todos los módulos que no existen se marcan pendientes. No se ha conectado esta base con la aplicación de descargas anterior. No publicar hasta superar pruebas y obtener autorización.

## Pendiente
Motor de descargas, recuperación, análisis de enlaces, biblioteca, reproductor, Android, comunicaciones nativas, despliegue Cloudflare y migraciones futuras. La web modular está basada en el contenido de la versión anterior; debe revisarse antes de lanzamiento para no confundir sus capacidades con las de la nueva foundation.

## Plataformas objetivo
Studio Lexair ha priorizado YouTube, TikTok, Instagram, Facebook y X. Véase `plataformas.md` para el orden y los requisitos previos; ninguna está implementada aún en la nueva foundation.

## Prototipo de exploración y reproductor
Interfaz de selección de plataforma y búsqueda sin datos falsos; búsqueda/tendencias aún sin backend. Reproductor local basado en Media Kit/libmpv en desarrollo; distribución Windows y licencias de bibliotecas nativas pendientes de verificación. Véase `docs/architecture/media-player.md`.

## Lexair Engine · primera entrega
Paquete Dart `packages/download_engine` creado y probado con servidor local de pruebas; no está conectado a la aplicación. No es una release. Ver pruebas y limitaciones en `docs/testing/engine-resultados.md` y `docs/architecture/lexair-engine-fase-2.md`.
