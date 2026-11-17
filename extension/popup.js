const status = document.querySelector('#status');
const results = document.querySelector('#results');
document.querySelector('#scan').addEventListener('click', async () => {
  results.replaceChildren();
  status.textContent = 'Buscando…';
  try {
    const [tab] = await chrome.tabs.query({active: true, currentWindow: true});
    if (!tab?.id) throw new Error('No se puede acceder a esta pestaña.');
    const [{result}] = await chrome.scripting.executeScript({target: {tabId: tab.id}, func: () => {
      const urls = new Set();
      const add = (value) => { try { const u = new URL(value, location.href); if (['http:', 'https:'].includes(u.protocol)) urls.add(u.href); } catch (_) {} };
      document.querySelectorAll('video, audio').forEach(el => { if (el.currentSrc) add(el.currentSrc); if (el.src) add(el.src); });
      document.querySelectorAll('video source[src], audio source[src]').forEach(el => add(el.src));
      document.querySelectorAll('a[href]').forEach(el => { if (/\.(mp4|webm|m4a|mp3|ogg|wav)(\?|#|$)/i.test(el.href)) add(el.href); });
      return [...urls].slice(0, 30);
    }});
    if (!result.length) { status.textContent = 'No se encontraron enlaces directos visibles. Puedes copiar la dirección de la página y probarla en Lexair.'; return; }
    status.textContent = `${result.length} enlace(s) encontrado(s).`;
    result.forEach(url => { const li = document.createElement('li'); const text = document.createElement('span'); text.textContent = url; const button = document.createElement('button'); button.textContent = 'Copiar enlace'; button.addEventListener('click', async () => { try { await navigator.clipboard.writeText(url); button.textContent = 'Copiado'; } catch (_) { status.textContent = 'No se pudo copiar; selecciona el enlace manualmente.'; } }); li.append(text, button); results.append(li); });
  } catch (_) { status.textContent = 'No se puede examinar esta página. Prueba en una página web normal.'; }
});
