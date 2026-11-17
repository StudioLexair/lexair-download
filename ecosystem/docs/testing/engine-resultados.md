# Verificación de Lexair Engine

Fecha: 17 de noviembre de 2026.

## Ejecutado en Linux, Dart 3.14.0
- `dart analyze`: sin problemas.
- `dart test`: 13 pruebas aprobadas.
- Transferencia real contra servidor HTTP local mediante fuente de prueba: streaming, SHA-256, no sobrescritura, límites, HTML y cancelación previa.
- Servidor HTTPS local con certificado autofirmado de prueba: conexión mediante la misma primitiva TLS fijada usada por producción, confianza explícita con hostname correcto, rechazo de certificado no confiable y rechazo de hostname incorrecto.
- Respuesta 302: el cliente común la rechaza y el servidor confirma que no se solicitó el destino. Todavía no se admiten redirecciones.
- Política de DNS: lista vacía y mezcla de direcciones públicas y privadas rechazadas mediante prueba unitaria.

## Alcance y pendientes
Las pruebas HTTPS usan una fábrica de conexión de prueba que dirige al servidor local e instala una CA de prueba: no invocan de extremo a extremo la fuente pública, cuya política prohíbe localhost y puertos arbitrarios. No se ha probado SNI de forma independiente, DNS rebinding en una red real, redes públicas, servidores externos, Windows, Android ni ataques exhaustivos. El certificado y clave incluidos son públicos y exclusivos de pruebas.

No hay cola persistente, pausa, reanudación, recuperación tras cierre, seguimiento seguro de redirecciones, múltiples conexiones, reintentos ni integración UI. La CI Windows/Linux no se ha ejecutado. El destino de archivos sigue requiriendo un directorio de confianza; la publicación final no es atómica. No usar con enlaces externos hasta una revisión de seguridad más amplia. No se ha desplegado esta versión.

## Cola persistente (17 de noviembre de 2026)
En Linux con Flutter 3.50: `flutter analyze` sin incidencias para `download_queue` y `storage_core`; 3 pruebas de cola y 1 prueba existente de almacenamiento aprobadas. Se verificó migración SQLite real v1→v2 con conservación de ajustes; cierre y reapertura de la base; recuperación y reintento manual; FIFO, cancelación pendiente y transiciones; y una transferencia de archivo real al servidor local con fuente de prueba, seguida de rechazo al intentar sobrescribir. También se repitieron análisis y 13 pruebas del motor, todos correctos. No se probó terminación forzada del proceso, Windows, red pública ni multiinstancia. Ver límites en `docs/architecture/cola-persistente.md`.

## Primitiva de reanudación experimental (17 de noviembre de 2026)
En Linux, Dart 3.14: análisis limpio y 24 pruebas de motor aprobadas (11 nuevas). Las nuevas emplean servidor HTTP local y fuente de prueba que llama el mismo procesador de rangos, no la conexión de red pública integral. Se comprueban 206 válido y SHA-256 completo, rechazos 200, 416, redirección, ETag cambiado, Content-Range erróneo, codificación inesperada, cuerpo corto, parcial modificado, hash final incorrecto, ETag débil y límite insuficiente. Se verifica que los rechazos no modifican el parcial en estos casos. Pruebas existentes de cola: análisis limpio y 3 aprobadas. No se ha probado fallo de proceso durante escritura, red pública ni Windows. Ver `docs/architecture/reanudacion-experimental.md` para restricciones y trabajo pendiente.

## Cola con checkpoints experimentales (17 de noviembre de 2026)
En Linux: `dart analyze` limpio y 27 pruebas del motor aprobadas; `flutter analyze` limpio y 6 pruebas de cola aprobadas. La prueba integrada usa servidor local y fuentes de red de prueba: captura parcial real, cierra/reabre SQLite, reencola, solicita 206 y publica el resultado. Se comprobaron migraciones v1→v3 y v2→v3, y que un parcial alterado no se publica. Se comprueba rechazo de ETag ausente/débil. No se han simulado cortes reales de proceso, pérdidas de energía ni probado Windows/red pública; la prueba no usa el adaptador público completo. Ver riesgos y límites en `docs/architecture/checkpoints-cola.md`.

## Pausa cooperativa (17 de noviembre de 2026)
Linux y Dart 3.14/Flutter 3.50: análisis limpios; 31 pruebas del motor y 8 de cola aprobadas. Las nuevas cubren pausa al recibir un chunk, solicitud al último chunk, respuesta corta, ETag débil y transferencia que termina sin pausa. Prueba integrada con servidor HTTP local y adaptadores de prueba: solicita pausa durante transferencia, guarda checkpoint, cierra SQLite, un proceso Python independiente marca la tarea running y se termina con SIGKILL tras confirmar el commit; al reabrir se recupera el estado, se reencola y se completa mediante 206. Esta prueba NO mata el proceso Dart en plena escritura y no demuestra durabilidad ante corte eléctrico, ni prueba Windows o red pública. No se han probado todas las ventanas de interrupción; los riesgos previos siguen aplicando.

## Pausa durante reanudación (17 de noviembre de 2026)
En Linux: análisis limpios y 35 pruebas del motor y 10 de cola aprobadas. La prueba integrada inicia checkpoint a 4 bytes, reanuda por 206, solicita pausa a 8 bytes, verifica el nuevo hash y checkpoint, cierra/reabre SQLite y completa desde el offset 8; se usa servidor local con adaptadores de prueba. Se comprobó la reversión transaccional si cambia el checkpoint anterior, y pruebas del motor cubren pausa, final al último chunk, hash incorrecto y cuerpo excesivo. No se ha interrumpido el proceso Dart durante la adición o commit, ni se ha probado Windows, corte de energía o fuente pública integral. Continúan las restricciones documentadas.

## Interfaz de descarga directa (17 de noviembre de 2026)
En Linux: `flutter analyze --no-fatal-infos` sin errores ni advertencias, con 13 avisos informativos de deprecación del import Material; 3 pruebas de app aprobadas, incluidas navegación, aviso de ejecutable y cancelación, y controlador con servidor HTTP local y adaptador de prueba. Se ejecutaron 35 pruebas de motor y 10 de cola. CI en GitHub para commit 0dae033: compilación Windows, pruebas app, motor y cola en Windows; motor y cola también en Linux; build web, todos aprobados. No se ha probado la fuente pública contra servidores externos ni se ha ejecutado interactivamente la app en un equipo Windows; no constituye auditoría de seguridad.

## UI: progreso y pausa cooperativa (17 de noviembre de 2026)
Linux: 5 pruebas de aplicación aprobadas, incluyendo control de modo pausa y controlador con servidor HTTP local/adaptadores de prueba: mostrar progreso, solicitar pausa, guardar checkpoint y reanudar con Range. Analizador sin errores ni advertencias, con 13 avisos informativos de Material deprecado; regresión: 35 pruebas motor y 10 cola correctas. Sin pruebas contra la fuente pública completa, sin prueba interactiva en Windows ni simulación de cortes en las ventanas de escritura y commit. Ver `docs/architecture/ui-descarga-experimental.md`.

## Integración de anuncios nativa (17 de noviembre de 2026)
Linux Flutter 3.50: `flutter analyze --no-fatal-infos` sin errores/advertencias, con avisos informativos de Material deprecado; 14 pruebas de app aprobadas. Incluye validación de URLs, visitante persistente, frecuencia, supresión en formulario/rutas sensibles, un flotante y un inline, retardo/autocierre y reintento de outbox tras reapertura. `flutter build bundle --target-platform linux-x64` completado. HTTP, eventos y contenido de pruebas son simulados; no se han enviado eventos reales ni probado reproducción vídeo o UI en Windows.
