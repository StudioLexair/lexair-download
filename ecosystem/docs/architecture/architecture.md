# Arquitectura técnica inicial — Lexair Download

## Alcance y estado
Fundación en desarrollo, separada del descargador anterior. No es una actualización compatible ni una release. El código anterior permanece en `lexair-downloader`. No hay motor, analizador, biblioteca ni reproducción funcionales en esta fundación. Android, extensión nativa y servicios de sincronización quedan para fases posteriores. No se despliega nada automáticamente.

## Capas y dependencias
- `apps/desktop`: presentación, navegación GoRouter y composición con Riverpod. Las pantallas no ejecutarán descargas.
- `packages/design_system`: temas Material 3 y, al crecer, componentes reutilizables.
- `packages/storage_core`: SQLite mediante Drift; abre la base local y almacena la preferencia de tema. Esquema v1; al añadir tablas se requieren migraciones y pruebas de actualización.
- `apps/web`: frontend Vite modular (HTML, CSS y módulos JS), separado de la app Flutter. Compila a archivos estáticos; usar Cloudflare Pages no implica que la fuente sea monolítica ni requiere fingir un backend. El contenido heredado debe revisarse contra las funciones reales antes de publicarse. No hay paquetes vacíos para funciones futuras.

Los futuros paquetes `security_core`, `link_analyzer`, `download_engine`, `media_core`, `media_library` e `integration_protocol` se crearán cuando exista código y pruebas. En el dominio estarán entidades y contratos; la infraestructura implementará adaptadores, persistencia, red y archivos. Los casos de uso dependen de contratos, no de widgets ni proveedores concretos. El analizador tendrá un adaptador HTTP para recursos directos; contenido HTML no se tratará como archivo sin determinación explícita.

## Fases siguientes y límites
1. Terminar y verificar la foundation en Windows con CI y pruebas de migración. Mantener compatibilidad con escritorio.
2. Implementar por incrementos el motor de HTTP directo con cola persistente, cancelación y luego reanudación condicionada a Range/ETag. Cada incremento tendrá pruebas locales y sin servicios externos. No iniciar este trabajo hasta verificar la base.
3. Motor y analizador: validar la URL y sus redirecciones, verificar conexiones efectivas contra IPs públicas con tratamiento de DNS rebinding y proxies, bloquear rangos privados/especiales IPv4 e IPv6, y limitar tamaño, tiempo y conexiones. Para pruebas locales, inyectar transporte o política de prueba que no llegue a producción.
4. Evaluar media_kit y bibliotecas nativas antes de distribuir: la licencia MIT del wrapper no determina por sí sola la licencia de libmpv, FFmpeg, códecs y sus configuraciones de compilación. Comparar contra video_player y plataforma nativa; documentar notices y obligaciones antes de elegir binarios.
5. Extensión TypeScript y Native Messaging con protocolo versionado, IDs autorizados, validación y límites; sin servidor local abierto. La extensión actual antigua es separada y no implementa este protocolo.

## Dependencias y licencias investigadas
- Riverpod: MIT; estado y pruebas desacopladas.
- GoRouter: BSD-3-Clause; rutas declarativas.
- Drift y drift_flutter: MIT; SQLite tipado y migraciones versionadas.
- Media Kit: wrapper MIT; plataforma nativa con vídeo/audio para Windows, Android y Linux. Requiere auditoría de bibliotecas nativas, códecs y licencias de los binarios concretos antes de distribuir.
- video_player: BSD-3-Clause, soporta Android y web pero no Windows/Linux de forma oficial; un complemento de Windows existe por separado. Alternativa sujeta a revisión.

Fuentes: https://pub.dev/packages/flutter_riverpod, https://pub.dev/packages/go_router, https://pub.dev/packages/drift, https://pub.dev/packages/drift_flutter, https://pub.dev/packages/media_kit, https://pub.dev/packages/video_player, https://pub.dev/packages/video_player_win.
