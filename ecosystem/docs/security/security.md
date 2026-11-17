# Seguridad: criterios de aceptación futuros

La foundation no realiza solicitudes de descarga ni implementa estas protecciones todavía. No se considerará listo el motor sin validación HTTP/HTTPS estricta, bloqueo de localhost/redes privadas y direcciones especiales, validación de cada salto de redirección, defensa contra DNS rebinding que compruebe la IP realmente conectada, límites de tamaño/tiempo/conexiones, rutas de destino seguras y escritura sin sobrescritura. Los proxies deberán respetar la misma política o deshabilitarse.

La comprobación SHA-256 identifica integridad solo si el hash esperado proviene de una fuente confiable; no determina si un ejecutable es seguro. Se advertirá antes de guardar ejecutables. La función de reanudación comprobará Range y validadores de contenido. Mensajes de Native Messaging exigirán extensión autorizada y validación de esquema y longitud. No almacenar secretos en Git ni capturar credenciales de navegador.
