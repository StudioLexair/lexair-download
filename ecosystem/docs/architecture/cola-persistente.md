# Cola persistente experimental

## Componentes
`storage_core` incorpora tabla SQLite mediante Drift y migración de esquema 1 a 2, conservando ajustes. `download_queue` conecta el repositorio con el motor; es un trabajador secuencial invocado explícitamente mediante `runNext()`, no un servicio autónomo ni una función integrada en la interfaz.

Se guardan URL, carpeta, nombre, límite, hash opcional y estado. FIFO por ID. Estados: queued, running, completed, failed, interrupted, cancelled. Se puede cancelar una tarea pendiente y reintentar manualmente una fallida o interrumpida; reintentar empieza desde cero. Las transiciones se condicionan al estado anterior; claimNext usa transacción.

## Recuperación y seguridad
Al iniciar, con ningún otro proceso/trabajador activo, llamar una vez a `recoverInterrupted()` antes de ejecutar el trabajador. No reintenta automáticamente. Usar una sola instancia de aplicación y un solo trabajador por base de datos; no hay bloqueo entre procesos ni coordinación de workers. Si el proceso muere después de escribir el archivo pero antes de guardar completed, quedará interrupted y el archivo puede existir; verificarlo manualmente antes de reintentar. El motor no sobrescribe archivos existentes. Una interrupción durante la copia final puede dejar un archivo incompleto: no asumir integridad solo por existencia. No se limpian automáticamente temporales de un proceso terminado abruptamente.

URLs y rutas se almacenan en texto claro; podrían incluir parámetros sensibles. La base debe quedar en un directorio privado y no deben registrarse URLs con tokens si no se acepta ese riesgo. No almacena contraseñas, cookies ni detalles de errores. El motor sigue validando URL y nombre al iniciar, no al encolar. Se heredan sus límites y riesgos, incluidos destino confiable y prohibición de redes privadas.

## Pendiente
Sin UI, progreso persistente, pausa, cancelación de tarea activa, reanudación Range, reintentos automáticos, ejecución en segundo plano, limpieza de temporales ni soporte multiinstancia. No usar en producción o con enlaces externos hasta ampliar pruebas y revisar seguridad. No se ha probado Windows.

## Actualización posterior
Existe un flujo experimental opcional de checkpoint y reanudación; el flujo ordinario continúa empezando de cero. Ver `checkpoints-cola.md`, que sustituye las afirmaciones anteriores de que la cola nunca puede reanudar.
