# Cloudflare Pages — despliegue directo

La web usa Vite con módulos; se construye a `dist`, el formato de salida que Pages sirve. Sin cuenta/token válidos, no se crea ningún proyecto ni URL. `lexair-download` es solo un nombre deseado y puede estar ocupado. Mantener la web anterior hasta verificar el nuevo despliegue.

Requisitos: Node 20+, una cuenta Cloudflare, ID de cuenta y un token activo con Account → Cloudflare Pages → Edit para dicha cuenta. El token es un secreto: no guardarlo en el repositorio ni en este documento.

```sh
cd apps/web
npm ci
npm run build
# El usuario debe proporcionar estas variables de forma segura, no dentro del repo.
# CLOUDFLARE_API_TOKEN y CLOUDFLARE_ACCOUNT_ID
npx wrangler pages project create lexair-download --production-branch main
npx wrangler pages deploy dist --project-name lexair-download --branch main
```

Si el proyecto existe o el nombre está ocupado, inspeccionar la cuenta antes de elegir otro. Comprobar la URL que devuelve Cloudflare, probar el botón de descarga sin ZIP y con ZIP de prueba, y solo entonces retirar GitHub Pages tras autorización ya concedida para una migración verificada. La página actualmente comunica que la versión nueva está en desarrollo; no se ha publicado un paquete Windows nuevo. No insertar enlaces a binarios de la versión vieja haciéndolos pasar por la nueva.

## Primer despliegue verificado

Proyecto `lexair-download`, producción: https://lexair-download.pages.dev/ . El 17 de noviembre de 2026 se comprobó la respuesta HTTP 200 de la página, el icono y los recursos JS/CSS. Cloudflare Pages devuelve el HTML del SPA para rutas desconocidas: el código del botón comprueba el tipo MIME y muestra que la descarga no está disponible en lugar de guardar HTML como ZIP. Todavía no existe un ZIP nuevo de Windows publicado en Cloudflare. La web anterior se mantiene hasta disponer de un paquete nuevo verificado y evitar dejar al usuario sin descarga.
