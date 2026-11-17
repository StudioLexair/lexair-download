# Plataformas prioritarias

Prioridad elegida por Studio Lexair: YouTube, TikTok, Instagram, Facebook y X. Son objetivos de compatibilidad, no garantías de funcionamiento universal. La foundation actual aún no incluye análisis ni descargas de ninguna de ellas.

## Estrategia
1. Verificar la foundation y la compilación Windows antes de iniciar el motor.
2. Diseñar contratos de análisis y variantes independientes del motor, con resultados tipados: disponible, no compatible, requiere acceso o protegido.
3. Implementar primero el adaptador HTTP/HTTPS para archivos directos, con política de seguridad de red y pruebas deterministas locales.
4. Evaluar y aislar una integración yt-dlp para las cinco plataformas, con análisis de metadatos y formatos reales, sin asumir que todos los enlaces son compatibles. La aplicación presentará opciones solamente cuando el motor las proporcione. Contemplar licencias, empaquetado, actualizaciones y verificación de binarios.
5. Añadir pruebas unitarias con adaptadores y procesos simulados; las pruebas automáticas no dependerán de servicios externos. Antes de anunciar soporte, verificar manualmente cada plataforma y documentar limitaciones.

## Restricciones técnicas y seguridad
- Los enlaces y redirecciones requieren validación; no presumir que un nombre de dominio permitido implica que la conexión final es segura. Evaluar cómo aplicar la política SSRF a las peticiones internas de herramientas externas antes de habilitarlas.
- Las páginas privadas, sesiones y credenciales no se extraerán ni reutilizarán automáticamente. Sin evasión de DRM ni controles de acceso.
- Las plataformas cambian y pueden restringir formatos, metadatos y disponibilidad; no prometer todas las publicaciones ni todas las resoluciones.
- No se realizarán publicaciones ni despliegues sin autorización.
