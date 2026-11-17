# Integración experimental de descarga directa

La sección Descargar encola una URL directa HTTP/HTTPS, nombre y carpeta elegida. La sección Cola muestra estados persistentes, permite iniciar una tarea FIFO, cancelar tareas pendientes y reencolar tareas fallidas o interrumpidas. El controlador recupera estados running como interrupted al abrirse, y permanece activo al cambiar de página. Motor y cola conservan las políticas de seguridad existentes. Se advierte antes de encolar nombres con extensión ejecutable frecuente, sin pretender detectar todo código ejecutable.

La UI no implementa pausa, cancelación activa, progreso, diagnóstico específico ni procesamiento automático. No descarga páginas de plataformas, no resuelve redirecciones ni extrae vídeos/audio, y limita a 1 GiB. Solo un proceso/instancia por base. URLs, incluso parámetros, se guardan en texto claro; la UI lo advierte. La ubicación destino debe ser confiable. No ejecutar archivos desconocidos.

**Prototipo no apto para producción**: siguen pendientes auditoría SSRF, protección frente a carreras y enlaces simbólicos, publicación atómica, recuperación frente a caída, limpieza de parciales, verificación de funcionamiento en Windows y revisión de licencias. No se ha publicado ni enlazado el nuevo ejecutable desde la web.
