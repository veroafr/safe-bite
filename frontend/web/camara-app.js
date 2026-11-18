// Safe-Bite: cámara propia de la versión web.
//
// Abre la cámara trasera en una pantalla completa dentro de la página, con
// un botón para sacar la foto. No usa el selector de archivos del sistema
// (<input type="file" capture>), que en algunos celulares y navegadores no
// abre la cámara. Devuelve la foto como JPEG (Uint8Array) o null si se cancela.
//
// Desde Dart: lib/core/web/lector_codigo_foto_web.dart -> sacarFotoConCamaraApp().
(function () {
  function crear(tag, estilo, texto) {
    var el = document.createElement(tag);
    if (estilo) el.style.cssText = estilo;
    if (texto) el.textContent = texto;
    return el;
  }

  async function aJpeg(fuente, ancho, alto, maxLado) {
    var escala = Math.min(1, maxLado / Math.max(ancho, alto));
    var lienzo = document.createElement('canvas');
    lienzo.width = Math.round(ancho * escala);
    lienzo.height = Math.round(alto * escala);
    lienzo.getContext('2d').drawImage(fuente, 0, 0, lienzo.width, lienzo.height);
    var blob = await new Promise(function (r) { lienzo.toBlob(r, 'image/jpeg', 0.9); });
    return blob ? new Uint8Array(await blob.arrayBuffer()) : null;
  }

  window.safebiteCamaraDisponible = function () {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  };

  window.safebiteSacarFoto = function (titulo) {
    return new Promise(function (resolve) {
      var terminado = false;
      var stream = null;

      var capa = crear('div',
        'position:fixed;inset:0;z-index:2147483000;background:#000;display:flex;flex-direction:column;' +
        'font-family:Roboto,Arial,sans-serif;touch-action:none');
      var cabecera = crear('div',
        'color:#fff;padding:14px 16px;font-size:16px;text-align:center;background:rgba(0,0,0,.6)',
        titulo || 'Sacá la foto');
      var video = crear('video', 'flex:1;width:100%;object-fit:contain;background:#000');
      video.setAttribute('playsinline', '');
      video.setAttribute('autoplay', '');
      video.muted = true;
      var aviso = crear('div', 'color:#ddd;font-size:13px;text-align:center;padding:6px 16px', 'Abriendo la cámara...');
      var barra = crear('div',
        'display:flex;gap:12px;justify-content:center;align-items:center;padding:16px 16px 28px;background:rgba(0,0,0,.6)');
      var cancelar = crear('button',
        'padding:12px 18px;border-radius:24px;border:1px solid #fff;background:transparent;color:#fff;font-size:15px',
        'Cancelar');
      var disparar = crear('button',
        'padding:14px 26px;border-radius:28px;border:none;background:#2E8B4F;color:#fff;font-size:16px;font-weight:bold',
        'Sacar foto');
      disparar.disabled = true;
      barra.appendChild(cancelar);
      barra.appendChild(disparar);
      capa.appendChild(cabecera);
      capa.appendChild(video);
      capa.appendChild(aviso);
      capa.appendChild(barra);
      document.body.appendChild(capa);

      function cerrar(resultado) {
        if (terminado) return;
        terminado = true;
        try {
          if (stream) stream.getTracks().forEach(function (t) { t.stop(); });
        } catch (e) {}
        capa.remove();
        resolve(resultado);
      }

      cancelar.onclick = function () { cerrar(null); };

      disparar.onclick = async function () {
        disparar.disabled = true;
        aviso.textContent = 'Sacando la foto...';
        var pista = stream && stream.getVideoTracks()[0];
        // Con ImageCapture (Chrome en Android) la foto sale a resolución
        // completa y con enfoque; si no, se usa el cuadro del video.
        if (pista && typeof window.ImageCapture === 'function') {
          try {
            var blob = await new window.ImageCapture(pista).takePhoto();
            var bmp = await createImageBitmap(blob);
            cerrar(await aJpeg(bmp, bmp.width, bmp.height, 2000));
            return;
          } catch (e) {}
        }
        try {
          cerrar(await aJpeg(video, video.videoWidth, video.videoHeight, 2000));
        } catch (e) {
          cerrar(null);
        }
      };

      if (!window.safebiteCamaraDisponible()) {
        aviso.textContent = 'Este navegador no permite usar la cámara.';
        return;
      }

      navigator.mediaDevices.getUserMedia({
        audio: false,
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } }
      }).then(function (s) {
        if (terminado) {
          s.getTracks().forEach(function (t) { t.stop(); });
          return;
        }
        stream = s;
        video.srcObject = s;
        var p = video.play();
        if (p && p.catch) p.catch(function () {});
        aviso.textContent = 'Acercá el teléfono a unos 15 cm y esperá a que se vea nítido.';
        disparar.disabled = false;
      }).catch(function (e) {
        var nombre = e && e.name;
        aviso.textContent = nombre === 'NotAllowedError'
          ? 'No hay permiso para usar la cámara. Habilitalo en la configuración del navegador.'
          : 'No se pudo abrir la cámara (' + (nombre || 'error') + ').';
      });
    });
  };
})();
