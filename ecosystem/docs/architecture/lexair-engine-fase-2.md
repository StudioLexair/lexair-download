# Lexair Engine: primer incremento

Estado: prototipo de biblioteca Dart, no integrado en la interfaz ni publicado. El objetivo es iniciar descargas directas HTTP(S); NO analiza páginas, YouTube, TikTok ni otras plataformas y no anuncia compatibilidad con ellas.

## Incluye
Contrato de fuente, transferencia por bloques a un temporal, límite de tamaño, progreso, SHA-256 (opcionalmente comparar con un hash esperado), nombres de archivo validados, creación exclusiva del destino y cancelación cooperativa. Un adaptador HTTP intenta limitar conexiones a IPv4 pública mediante resolución validada y conexión fijada, sin proxy ni redirecciones, y establece TLS explícitamente para HTTPS conservando el nombre del host. Requiere revisión de seguridad y pruebas de integración TLS reales.

## Limitaciones intencionadas
No cola persistente, pausa, reanudación, reintentos, fragmentación, UI, ni Android. La cancelación solo se comprueba durante el flujo; no es instantánea mientras se espera la conexión o el siguiente bloque (existen timeouts). HTTPS y HTTP solo puertos 443 y 80; sin IPv6 ni redirecciones; no se admiten páginas HTML. Se descarga a temporal del sistema, de modo que requiere espacio adicional; el paso final copia a destino y no es atómico ante caída del proceso. La carpeta de destino debe ser de confianza: todavía no hay protección completa contra cambios concurrentes de enlaces simbólicos ni particiones/dispositivos especiales. Un hash no demuestra ausencia de malware. No se usa el motor con URL de usuarios hasta completar auditoría.

El adaptador inyectable es una frontera de confianza para código propio; nunca aceptar implementaciones ni ajustes de red desde contenido remoto. Los tests usan un servidor localhost mediante adaptador de prueba que NO se incluye en producción. La política de direcciones es conservadora pero debe contrastarse con los registros IANA completos; no constituye una garantía absoluta contra SSRF. Falta verificar HTTPS, SNI, certificados, proxy, DNS mixto y cambios de dirección mediante pruebas controladas. Comprobar además seguridad de conexión de cualquier futuro adaptador/FFmpeg/yt-dlp.

## Pasos siguientes
1. Auditar conectividad HTTPS/TLS, clasificación de IP y destinos, límites y rutas. Agregar tests de integración con un servidor TLS controlado.
2. Migración Drift versionada, persistencia de cola y recuperación tras reinicio.
3. Pausa/reanudación con Range/If-Range y pruebas de 200/206/416, seguido de reintentos limitados y cancelación inmediata.
4. Conectar a la interfaz solo cuando pase las pruebas de seguridad, incluida Windows real.

Fuentes: https://api.dart.dev/dart-io/HttpClient/connectionFactory.html , https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Range_requests , https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html .

## Avance: validación de transporte HTTPS
Se extrajo la conexión fijada como primitiva interna; producción mantiene validación IPv4, DNS completo, conexión a la IP validada y hostname original para TLS, sin proxy ni redirecciones. El cliente rechaza respuestas distintas de 200 sin drenar un cuerpo potencialmente ilimitado; el propietario debe cerrar el cliente. Las pruebas locales de TLS y redirección usan dicha primitiva y un certificado de prueba, no relajan la política de la fuente pública. Ver `docs/testing/engine-resultados.md` para resultados y limitaciones. Cola persistente y reanudación aún pendientes.
