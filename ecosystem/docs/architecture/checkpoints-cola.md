# Integración experimental: cola y checkpoint

## Flujo implementado
1. `checkpointNext(privateRoot, afterBytes)` reclama una tarea FIFO y efectúa una petición inicial con el motor de red. Requiere longitud conocida y ETag fuerte. Guarda exactamente la cantidad solicitada en un directorio nuevo dentro de `privateRoot`; `privateRoot` debe ser privado y confiable. Es un corte programado por bytes, **no** una pausa interactiva.
2. Calcula el SHA-256 del parcial y guarda su ruta, ETag, longitud y hash en SQLite, en la misma transacción que marca la tarea `interrupted`. Esquema v3 migra desde v1 o v2.
3. Tras cerrar/reabrir la base, `retry(id)` vuelve a encolar. `runNext()` detecta el checkpoint, verifica el parcial, completa mediante Range/If-Range y copia el resultado a destino mediante creación exclusiva. No sobrescribe. El hash esperado opcional se verifica antes de publicar.

## Límites importantes
- La descarga ordinaria de `runNext()` sigue sin producir checkpoints. Un cierre inesperado durante ella **no puede reanudarse**. Solo se puede reanudar el checkpoint creado mediante el flujo explícito anterior.
- `flush` no garantiza durabilidad ante pérdida de energía; no se ha implementado fsync ni atomicidad entre sistema de archivos y SQLite. Fallos entre creación de archivo y commit pueden dejar huérfanos. Si se interrumpe al completar el parcial, el hash/longitud del checkpoint anterior deja de coincidir y el siguiente intento falla de forma conservadora. Si se interrumpe la copia al destino, puede quedar un destino incompleto; no debe considerarse válido solo por existir. Si se termina la copia pero no el estado SQLite, se requiere revisión manual, y no se sobrescribe en reintento.
- No se limpian automáticamente parciales ni registros de checkpoint, incluso tras completar o cancelar. Pueden consumir espacio y contener datos sensibles; requiere limpieza controlada futura. Si se ha completado el parcial y luego falla la copia, el checkpoint original queda obsoleto y no permite reintentar automáticamente. Sin función de descartar checkpoint o reiniciar selectivamente.
- Un único proceso/trabajador por base, sin otros modificando el parcial o destino. No protege contra enlaces simbólicos, reemplazos concurrentes ni una base alterada; rutas y datos son de confianza. La carpeta debe tener permisos privados configurados por la aplicación; el código no los establece. URLs se guardan en texto claro.
- Si el servidor no ofrece ETag fuerte y tamaño, el checkpoint no se crea. Si responde 200/416, cambia de ETag o envía rangos inconsistentes, se rechaza y no se reinicia automáticamente. Un ETag no es un hash criptográfico de confianza.
- `checkpointNext` y `runNext` solo devuelven si tomaron una tarea; consultar su estado para detectar fallo. No se guardan detalles del error. Sin UI, cancelación activa, servicio de fondo, checkpoints periódicos, limpieza ni protección multiinstancia.
- No usar en producción o enlaces externos hasta auditoría y más pruebas. No se ha probado Windows ni cortes reales del proceso o alimentación.

## Actualización: pausa cooperativa
Además del corte fijo, `runNextPausable` permite pedir una pausa durante la transferencia inicial; sigue siendo una API experimental, no un botón de interfaz. Ver `pausa-cooperativa.md`. El flujo ordinario `runNext` no es pausable; `runNextPausable` admite también reanudación con pausa.
