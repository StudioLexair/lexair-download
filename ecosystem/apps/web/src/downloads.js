
document.querySelectorAll('.download').forEach(button => button.addEventListener('click', async () => {
  const container = button.closest('.hero-grid > div, .link-box > div, .cta');
  const status = container.querySelector('.download-status');
  const file = button.dataset.file;
  button.disabled = true;
  status.textContent = 'Preparando la descarga…';
  try {
    const response = await fetch('downloads/' + encodeURIComponent(file), {cache:'no-store'});
    if (!response.ok || response.type === 'opaque') throw new Error('No disponible');
    const data = await response.blob();
    if (!data.size || !['application/zip', 'application/octet-stream', 'application/x-zip-compressed'].some(type => data.type.toLowerCase().startsWith(type))) throw new Error('Archivo no disponible');
    const objectUrl = URL.createObjectURL(data);
    const a = document.createElement('a'); a.href = objectUrl; a.download = file; document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(objectUrl), 60000);
    status.textContent = 'Descarga preparada. Revisa las descargas de tu navegador.';
  } catch (_) { status.textContent = 'La descarga está temporalmente desactivada o no está disponible. Inténtalo de nuevo más tarde.'; }
  finally { button.disabled = false; }
}));
