# Reanudación HTTP: primitiva experimental

Esta fase implementa exclusivamente una operación independiente para completar un archivo parcial de confianza. **No implementa todavía pausa/reanudación de extremo a extremo**: el motor inicial descarta su temporal; la cola no captura ni persiste checkpoints y continúa reiniciando desde cero. No hay interfaz, control de pausa, generación automática del checkpoint ni publicación del parcial en el destino final.

## Protocolo
`ResumeEngine.resume` requiere que el integrador proporcione un `ResumeCheckpoint` confiable: URL original, ETag fuerte exacto registrado en la respuesta original, tamaño total, longitud y SHA-256 del parcial. El llamador es responsable de obtenerlos de una misma respuesta original, guardarlos de manera segura y vincularlos al archivo. Construir un checkpoint arbitrario a partir de un archivo sin verificar su procedencia NO demuestra que el prefijo pertenezca al recurso.

Valida longitud y hash del parcial, pide `Range` y `If-Range`, sin redirecciones, con `Accept-Encoding: identity`; exige 206, ETag fuerte idéntico incluso si el servidor omite legítimamente el ETag, `Content-Range` exacto hasta final y longitud coherente. 200, 416 y cualquier anomalía se rechazan, no se reinicia ni se agrega contenido. Servidores sin tamaño conocido, sin ETag fuerte o que omiten ETag en 206 no son compatibles. Se verifica el largo recibido y opcionalmente el SHA-256 completo; la comprobación de ETag no sustituye un SHA-256 conocido de origen confiable. El sufijo se recibe por separado y se comprueba antes de añadirlo al parcial.

La fuente pública utiliza la misma validación de IP/DNS y conexión fijada que el motor, sin proxy. Inyección de fuentes permitida solo a código de confianza. El archivo y el directorio deben ser privados y no modificarse concurrentemente. No se resuelven carreras de symlink o cambios concurrentes. Una caída durante la adición final puede modificar el parcial parcialmente: el checkpoint anterior dejará de coincidir y se rechazará el siguiente intento; no se garantiza recuperación ni sincronización atómica. Los temporales pueden permanecer tras caída abrupta. La función no publica ni renombra el resultado y no es apta para producción todavía.

## Próximos pasos
Diseñar escritura duradera y control de exclusividad, capturar y persistir el checkpoint con el parcial desde la descarga inicial, resolver recuperación tras caídas en todas las fases, integrar con la cola e interfaz, probar en Windows y analizar seguridad.

Referencia: RFC 9110, secciones 13.1.5 y 14: https://www.rfc-editor.org/rfc/rfc9110.html

## Integración posterior con cola
Existe un nuevo flujo explícito de creación de checkpoint y reanudación tras reapertura de SQLite. No afecta a la descarga ordinaria. Sustituye únicamente la limitación anterior sobre ausencia total de integración; todas las demás advertencias siguen vigentes. Véase `checkpoints-cola.md`.
