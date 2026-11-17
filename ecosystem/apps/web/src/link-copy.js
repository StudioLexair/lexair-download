document.querySelector('#copy').addEventListener('click', async () => {
 const value = document.querySelector('#link').value.trim(), status = document.querySelector('#copy-status');
 try { const u = new URL(value); if (!['http:', 'https:'].includes(u.protocol)) throw new Error(); await navigator.clipboard.writeText(value); status.textContent = 'Enlace copiado. Pégalo en Lexair Download.'; }
 catch (_) { status.textContent = 'Introduce un enlace válido o cópialo manualmente.'; }
});
