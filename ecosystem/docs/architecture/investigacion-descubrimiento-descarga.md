# Investigación: descubrimiento y descarga de contenido multimedia

Fecha: 17 de noviembre de 2026. Estado: investigación, no implementación.

## Hallazgos

Snaptube anuncia búsqueda o pegado de enlaces, selección de calidad y formato, reproducción y compatibilidad con múltiples servicios. Su documentación pública también describe navegación y funciones de navegador. No se ha auditado su código ni su tráfico: no sabemos cómo resuelve internamente cada plataforma, y no debe afirmarse que usa yt-dlp o un mecanismo concreto.

En términos generales, una aplicación de este tipo necesita módulos separados: (1) descubrimiento mediante API, sitio o proveedores permitidos; (2) identificación de la publicación; (3) adaptador capaz de identificar metadatos y variantes accesibles; (4) descarga HTTP o de segmentos; (5) ensamblado de audio y vídeo si están separados, por ejemplo mediante FFmpeg; y (6) reproducción y biblioteca. Algunos medios son archivos únicos, otros son HLS/DASH fragmentados. No todos los metadatos están siempre disponibles. Las fuentes cambian, y algunos vídeos son privados, están restringidos o usan DRM; no hay garantía de acceso universal.

`yt-dlp` es una herramienta existente que incluye numerosos extractores y selección de formatos. Es un candidato de investigación, no evidencia sobre el código de Snaptube. El proceso nativo debe estar aislado, no ejecutarse con argumentos de shell y seguir una política de seguridad consistente para conexiones, redirecciones, archivos y actualización. Se necesita verificar la licencia, la procedencia y las sumas de comprobación de sus binarios y los de FFmpeg, junto con sus dependencias y obligaciones de distribución. La selección conjunta de audio/vídeo y la conversión deben probarse antes de anunciarse.

## Descubrimiento: restricciones observadas

- YouTube Data API: puede devolver búsqueda pública y listas de vídeos populares compatibles con su API; no equivale necesariamente al feed personalizado de YouTube. Sus políticas para API clients restringen la descarga, almacenamiento y uso sin aprobación escrita de YouTube, además de scraping. Tener permiso del titular no elimina automáticamente esas restricciones contractuales. Diseño propuesto: navegación y reproducción conforme a sus políticas; descargas fuera de ese flujo solo cuando exista una vía autorizada y compatible con todos los términos aplicables.
- TikTok: Display API se centra en contenido del usuario que autoriza la app; la Research API tiene criterios de elegibilidad y no es una API general disponible para cualquier producto comercial. Requiere estudio de APIs y condiciones para un producto de Studio Lexair.
- Instagram: Meta documenta búsqueda por hashtag para cuentas profesionales y con aprobaciones, con límites concretos. Esto no equivale a búsqueda general o feed personalizado.
- Facebook y X: evaluar las APIs, permisos, restricciones de visualización, costes y disponibilidad de tendencias para el caso concreto. No asumir que ofrecen un feed público libre o acceso al recurso multimedia.

Separar proveedores de descubrimiento y descarga NO elimina las obligaciones aplicables al producto o a los datos de la API. Revisar documentación y condiciones completas antes de conectar fuentes.

## Propuesta incremental

1. Completar y probar foundation Windows y reproductor local, incluyendo licencias de medios.
2. Definir contratos `DiscoveryProvider`, `MediaMetadata`, `PlaybackProvider` y `DownloadProvider`, con resultados explícitos como no disponible, necesita autorización o protegido.
3. Implementar y probar motor de archivos directos autorizado con redirecciones seguras, persistencia e integridad.
4. Desarrollar YouTube en modo exploración conforme a sus condiciones y determinar si permite mostrar populares por región; probar estados de error y límites de cuota.
5. Evaluar integraciones de las otras plataformas una por una. Para cualquier ruta de descarga, comprobar derechos, condiciones y compatibilidad antes de integrar. No pasar credenciales de usuario al proceso de terceros sin consentimiento y diseño de seguridad.
6. Integración de formatos: pruebas locales reproducibles de archivos/segmentos y muxing; después pruebas manuales con contenido controlado y autorizado.

## Fuentes

- Snaptube, descripción del producto: https://origin.snaptube.com/es/snaptube/snaptube-music-and-video-download/
- Snaptube, condiciones y funciones de navegación: https://browser.snaptube.com/TermsOfService.htm
- yt-dlp, proyecto y documentación: https://github.com/yt-dlp/yt-dlp
- YouTube, políticas para servicios API: https://developers.google.com/youtube/terms/developer-policies
- YouTube, guía de cumplimiento: https://developers.google.com/youtube/terms/developer-policies-guide
- TikTok, Display API: https://developers.tiktok.com/doc/display-api-overview/
- TikTok, Research API: https://developers.tiktok.com/products/research-api/
- Meta, búsqueda por hashtag: https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-facebook-login/hashtag-search.md
