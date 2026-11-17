# Lexair Download — investigación de motores

**Fecha:** 17 de noviembre de 2026  
**Estado:** investigación documental; no es una prueba de rendimiento ni una certificación jurídica. No se han ejecutado benchmarks, ni se ha probado la compatibilidad real de cada motor con los servicios elegidos. Ningún candidato garantiza descargar todos los vídeos o plataformas.

## 1. Qué significa «motor»

El problema se divide en funciones distintas:

1. **Descubrimiento:** búsqueda, tendencias y navegación. Un descargador no necesariamente ofrece estas funciones.
2. **Extractor:** analiza una fuente compatible y devuelve metadatos, pistas, formatos o manifiestos accesibles.
3. **Transferencia:** descarga bytes, hace streaming, controla la cola, errores y reanudación.
4. **Procesamiento:** une pistas separadas, convierte formatos y gestiona metadatos.
5. **Reproducción:** decodifica y presenta audio y vídeo.

Comparar una herramienta de cada categoría como si fueran equivalentes daría una conclusión errónea. La velocidad final depende del servidor, red, límite de la fuente y CPU; la descarga segmentada no es automáticamente más rápida.

## 2. Matriz de candidatos

| Candidato | Categoría | Fortalezas | Riesgos y límites | Licencia y distribución |
|---|---|---|---|---|
| **Motor propio Dart** con `dart:io` o Dio | Transferencia HTTP(S), cola e integración | Encaja con Flutter y Drift, control del producto, arquitectura portable y privacidad ajustable. | Hay que implementar y probar Range, recuperación, control de concurrencia, validación de red y almacenamiento. No reconoce por sí solo vídeos de plataformas. | Código propio; Dio declara MIT. Los componentes elegidos necesitan inventario. |
| **yt-dlp** | Extractores multimedia y descargas | Muchos extractores, variantes, HLS/DASH, salidas legibles por máquina, compatibilidad con FFmpeg y actualizaciones. | Las plataformas cambian; errores y restricciones, dependencia de mantenimiento y sistema de procesos. Es independiente del descubrimiento visual y de los permisos. Su binario Windows no es una solución Android. Para capacidad completa de YouTube, upstream indica `yt-dlp-ejs` más runtime JS compatible. | Fuente principal Unlicense. **Atención:** upstream indica que la mayoría de ejecutables empaquetados con PyInstaller incluyen código GPLv3+ y que el conjunto se distribuye bajo GPLv3+. Auditar exactamente el artefacto y dependencias; no inferir obligaciones del ejecutable a partir de la licencia del repositorio. |
| **aria2** | Transferencia multi-protocolo | HTTP(S), FTP/SFTP, descargas segmentadas, pausas, reintentos, límites, BitTorrent/Metalink y RPC. | No es extractor general de vídeos ni buscador. RPC exige autenticación, aislamiento y evitar exponer un servicio a páginas web. Empaquetado Android y políticas de tienda requieren estudio. | Proyecto distribuido bajo GPL; revisar archivos y excepciones exactas del binario y sus obligaciones. No asumir que un proceso separado resuelve por sí solo toda la cuestión legal. |
| **libcurl** | Biblioteca nativa de red | Transferencias paralelas con interfaz multi, red madura, control detallado. | No incluye cola persistente, exploración ni extractores: habría que desarrollarlos. FFI, binarios y actualizaciones de seguridad añaden trabajo en Windows/Android. | Licencia curl permisiva; verificar licencias de dependencias TLS concretas. |
| **gallery-dl** | Extracción de galerías e imágenes | Útil para colecciones y sitios compatibles, con capacidad multimedia adicional. | No reemplaza un buscador universal ni el motor de archivos; requiere mantener extractores y empaquetar Python u otro modo de distribución. | GPL-2.0 según proyecto; revisar condiciones de la versión y distribución. |
| **Streamlink** | Streams, especialmente directos | Plugins para fuentes de streaming y conexión a reproductores; candidato para fase de emisiones. | Especialización en streams, no sustituye una cola universal ni garantiza grabación de cualquier servicio. Python/bibliotecas y control del proceso requieren evaluación. | BSD simplificada según documentación; comprobar dependencias y binarios concretos. |
| **Lux** | Extractor y descargador Go | CLI/biblioteca y soporte declarado para varias plataformas; Go puede facilitar ciertos binarios. | La tabla de sitios no demuestra compatibilidad actual. La página de releases consultada muestra v0.24.1 de mayo de 2024: requiere comprobar mantenimiento y probar antes de adoptar. | MIT según repositorio; revisar dependencias y artefactos. |
| **FFmpeg / ffprobe** | Muxing, conversión, inspección | Combina pistas, convierte formatos y analiza medios. | No es un buscador de plataformas ni un sustituto del gestor de cola. Las opciones y códecs disponibles varían según el build; procesar medios no confiables tiene riesgos. | LGPL o GPL según componentes y flags; los builds no libres pueden no ser redistribuibles. Revisar cada binario exacto, notices y código fuente correspondiente. |
| **Media Kit/libmpv** | Reproductor | Audio/vídeo local en el prototipo, integración Flutter. | No es motor de descarga. Compatibilidad depende de bibliotecas/códecs y DRM; aún sin prueba real en Windows del proyecto. | Wrapper MIT; licencias de libmpv, FFmpeg y dependencias nativas se auditan por separado. |

Fuentes: [yt-dlp](https://github.com/yt-dlp/yt-dlp/), [aria2](https://aria2.github.io/manual/en/html/README.html), [aria2 repositorio](https://github.com/aria2/aria2), [libcurl multi](https://curl.se/libcurl/c/libcurl-multi.html), [gallery-dl](https://github.com/mikf/gallery-dl), [Streamlink](https://streamlink.github.io/), [Lux](https://github.com/iawia002/lux), [Lux releases](https://github.com/iawia002/lux/releases), [FFmpeg legal](https://ffmpeg.org/legal.html), [Dio](https://pub.dev/packages/dio), [Media Kit](https://pub.dev/packages/media_kit).

## 3. Tres estrategias

### A. Motor totalmente propio

Desarrollar transferencia, extractores, procesamiento y reproducción. **Viabilidad:** posible por módulos, pero crear y mantener extractores para numerosas plataformas, codecs y protocolos supone un trabajo continuado alto. Los cambios externos pueden romperlos. No se recomienda reimplementar el ecosistema multimedia completo como primer paso.

### B. Solo motores externos

Integrar herramientas existentes para todo. **Viabilidad:** prototipo más rápido, pero se pierde control uniforme de estados, aislamiento, integración Android y políticas de seguridad; las dependencias, binarios y términos exigen mantenimiento. No reduce a cero el coste de producto.

### C. Arquitectura híbrida — recomendada

- **Lexair Engine propio:** cola persistente, estados, prioridades, almacenamiento, controles y transferencias HTTP(S) directas.
- **Contratos de proveedores:** descubrimiento, extractor, transferencia y procesamiento son interfaces independientes. Activar un adaptador solo tras revisar condiciones y soporte.
- **Adaptadores externos opcionales:** evaluar `yt-dlp` para fuentes autorizadas, y `gallery-dl` o Streamlink solo si aportan valor medido. No instalar herramientas redundantes por defecto.
- **FFmpeg** solo cuando el trabajo precise unir o convertir, con un build cuya licencia y procedencia estén verificadas.
- **Media Kit** para reproducción local, con auditoría nativa y pruebas por códec.

Crear un motor de transferencias propio **no implica** crear desde cero los extractores de todas las plataformas ni evitar restricciones. Tampoco convierte la descarga de medios procedentes de YouTube API en una operación autorizada: revisar los términos aplicables al producto completo.

## 4. Diseño del motor propio

### Módulos propuestos

- `download_core`: entidad `DownloadJob`, estados, transiciones, política de reintentos, contrato de transferencia y eventos.
- `download_engine`: coordinador de concurrencia y adaptador HTTP. No acoplar a widgets.
- `storage_core`: persistencia Drift de tareas, ruta temporal, progreso y validadores, con migraciones.
- `security_core`: validación estricta, política de destinos, rutas, límites y protección frente a conexiones o redirecciones no autorizadas.
- `source_adapters`: interfaz de análisis y adaptadores por proveedor; sin permitir que un plugin modifique el núcleo arbitrariamente.
- `media_processing`: contrato para procesador y adaptador FFmpeg opcional.

### Flujo directo HTTP

1. Validar URL, destino, límites y conectividad; resolver solo destinos permitidos.
2. Consultar metadatos cuando sea posible, sin tratar HTML como vídeo por defecto. No confiar solo en nombre o MIME.
3. Crear trabajo persistente y archivo temporal exclusivo; transmitir por bloques sin cargar todo en memoria.
4. Reanudar solo si la respuesta real y sus validadores permiten hacerlo: `Range`/`Content-Range`, `If-Range` con ETag fuerte o fecha aplicable. Si el servidor devuelve `200` en lugar de `206`, no anexar ciegamente; si devuelve `416`, reevaluar tamaño y estado.
5. Controlar los saltos de redirección, la IP realmente conectada y la protección DNS rebinding en **todas** las conexiones. La política debe cubrir también solicitudes internas de herramientas auxiliares; si no se puede imponer, no activar el adaptador.
6. Verificar tamaño y SHA-256. El hash solo acredita integridad contra un valor esperado de fuente confiable; no prueba ausencia de malware. Evitar sobrescrituras y advertir sobre ejecutables.
7. Finalizar con movimiento seguro a la ruta elegida, registrar estado y errores recuperables. Reconciliar temporal y BD tras reinicio.

### Android

La cola lógica y dominio pueden compartirse, pero la ejecución en segundo plano, notificaciones y almacenamiento requieren integración Android. Evaluar trabajo de transferencia iniciado por el usuario o WorkManager según duración y restricciones de cada versión; no asumir que un proceso de Windows funcionará en Android. Google advierte de riesgos del `DownloadManager` del sistema y describe alternativas.

Referencias: [HTTP Range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Range_requests), [If-Range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/If-Range), [Android tareas de transferencia](https://developer.android.com/develop/background-work/background-tasks/data-transfer-options), [Android seguridad DownloadManager](https://developer.android.com/privacy-and-security/risks/unsafe-download-manager).

## 5. Plan de pruebas comparativas antes de decidir

No se ha elegido un ganador por rendimiento todavía. Crear un servidor de pruebas local aislado, con datos generados y una política de red inyectable solo para test. Comparar motor Dart, aria2 y libcurl con la misma infraestructura, controlando:

- Archivos 1 MB, 100 MB y 1 GB, red local y emulación de latencia/pérdida.
- Una y varias descargas simultáneas; memoria, CPU, tiempo, tamaño de distribución y número de conexiones.
- Rango correcto, servidor que ignora Range, 416, cambio de ETag, redirecciones y cortes de conexión.
- Pausa, cancelación, reinicio del proceso, reanudación y hash final.
- URL bloqueada, redirección a red privada, DNS rebinding simulado, rutas maliciosas y límites de tamaño.
- Windows real y Android real por separado; pruebas sin plataformas externas en CI.

Para extractores, usar fixtures simuladas en CI y pruebas manuales con contenido de prueba autorizado y condiciones revisadas. Publicar una matriz de compatibilidad verificable con fecha; no medir «número de sitios en README» como tasa real de éxito.

## 6. Advertencia sobre la versión anterior

La versión anterior de Lexair empaquetó `yt-dlp.exe` descargado automáticamente sin fijar versión ni validar hash. Antes de volver a distribuirla se debe inventariar el binario exacto, comprobar sus licencias y obligaciones y cambiar el proceso a descargas firmadas/verificadas. No se ha verificado que el paquete antiguo cumpla todas esas condiciones. La nueva foundation todavía no es una release Windows.

## 7. Límites de la investigación

Esta evaluación compara candidatos representativos, no todos los motores existentes. No se ha auditado el código de SnapTube, no se conoce su implementación interna y no se ha probado ningún servicio de terceros. Las políticas, bibliotecas y condiciones pueden cambiar. Las decisiones de distribución y obligaciones GPL/LGPL necesitan revisión jurídica específica.
