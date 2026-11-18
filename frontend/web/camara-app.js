// Safe-Bite: cámara propia de la versión web.
//
// Abre la cámara trasera en una pantalla completa dentro de la página, con
// un botón para sacar la foto. No usa el selector de archivos del sistema
// (<input type="file" capture>), que en algunos celulares no abre la cámara.
// Devuelve la foto como JPEG (Uint8Array) o null si se cancela.
//
// Si la cámara se abre pero no llega imagen (pantalla negra), prueba sola
// con otra configuración y con las otras cámaras traseras, y ofrece el
// botón "Cambiar cámara".
//
// Desde Dart: lib/core/web/lector_codigo_foto_web.dart -> sacarFotoConCamaraApp().
(function () {
  function crear(tag, estilo, texto) {
    var el = document.createElement(tag);
    if (estilo) el.style.cssText = estilo;
    if (texto) el.textContent = texto;
    return el;
  }

  function esperar(ms) {
    return new Promise(function (r) { setTimeout(r, ms); });
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

  // getUserMedia sin los ajustes de camara-enfoque.js (si está cargado).
  function pedirCamara(restricciones) {
    var md = navigator.mediaDevices;
    var fn = md.__safebiteGetUserMediaOriginal || md.getUserMedia.bind(md);
    return fn(restricciones);
  }

  window.safebiteCamaraDisponible = function () {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  };

  window.safebiteSacarFoto = function (titulo) {
    return new Promise(function (resolve) {
      var terminado = false;
      var stream = null;
      var camaras = [];      // cámaras de video disponibles (deviceId)
      var indiceCamara = -1; // -1 = la que elija el navegador ("trasera")

      var capa = crear('div',
        'position:fixed;inset:0;z-index:2147483000;background:#000;display:flex;flex-direction:column;' +
        'font-family:Roboto,Arial,sans-serif;touch-action:none');
      var cabecera = crear('div',
        'color:#fff;padding:14px 16px;font-size:16px;text-align:center;background:rgba(0,0,0,.6)',
        titulo || 'Sacá la foto');
      var video = crear('video', 'flex:1;min-height:0;width:100%;object-fit:contain;background:#000');
      video.setAttribute('playsinline', '');
      video.setAttribute('autoplay', '');
      video.setAttribute('muted', '');
      video.muted = true;
      var aviso = crear('div', 'color:#ddd;font-size:13px;text-align:center;padding:6px 16px', 'Abriendo la cámara...');
      var barra = crear('div',
        'display:flex;gap:10px;justify-content:center;align-items:center;flex-wrap:wrap;padding:14px 12px 26px;background:rgba(0,0,0,.6)');
      var estiloSecundario = 'padding:12px 16px;border-radius:24px;border:1px solid #fff;background:transparent;color:#fff;font-size:15px';
      var cancelar = crear('button', estiloSecundario, 'Cancelar');
      var cambiar = crear('button', estiloSecundario + ';display:none', 'Cambiar cámara');
      var disparar = crear('button',
        'padding:14px 24px;border-radius:28px;border:none;background:#2E8B4F;color:#fff;font-size:16px;font-weight:bold',
        'Sacar foto');
      disparar.disabled = true;
      barra.appendChild(cancelar);
      barra.appendChild(cambiar);
      barra.appendChild(disparar);
      capa.appendChild(cabecera);
      capa.appendChild(video);
      capa.appendChild(aviso);
      capa.appendChild(barra);
      document.body.appendChild(capa);

      function apagar() {
        try {
          if (stream) stream.getTracks().forEach(function (t) { t.stop(); });
        } catch (e) {}
        stream = null;
      }

      function cerrar(resultado) {
        if (terminado) return;
        terminado = true;
        apagar();
        capa.remove();
        resolve(resultado);
      }

      // Brillo medio del cuadro actual (0 = negro total).
      var muestra = document.createElement('canvas');
      muestra.width = 24;
      muestra.height = 24;
      function brillo() {
        try {
          var ctx = muestra.getContext('2d', { willReadFrequently: true });
          ctx.drawImage(video, 0, 0, 24, 24);
          var d = ctx.getImageData(0, 0, 24, 24).data;
          var suma = 0;
          for (var i = 0; i < d.length; i += 4) suma += d[i] + d[i + 1] + d[i + 2];
          return suma / (d.length / 4) / 3;
        } catch (e) {
          return -1;
        }
      }

      // ¿Llega imagen? La cámara puede "abrirse" y quedar negra si otra app
      // la tiene tomada. Devuelve 'ok', 'negro' (llegan cuadros negros) o 'nada'.
      async function hayImagen() {
        var vioCuadros = false;
        for (var i = 0; i < 14; i++) {
          if (terminado) return 'nada';
          await esperar(300);
          if (video.videoWidth > 0 && video.readyState >= 2) {
            vioCuadros = true;
            var b = brillo();
            if (b < 0 || b > 4) return 'ok';
          }
        }
        return vioCuadros ? 'negro' : 'nada';
      }

      async function abrir(restricciones) {
        apagar();
        var s = await pedirCamara(restricciones);
        if (terminado) {
          s.getTracks().forEach(function (t) { t.stop(); });
          return 'nada';
        }
        stream = s;
        video.srcObject = s;
        try { await video.play(); } catch (e) {}
        return hayImagen();
      }

      async function cargarCamaras() {
        try {
          var lista = await navigator.mediaDevices.enumerateDevices();
          camaras = lista.filter(function (d) { return d.kind === 'videoinput'; });
          if (camaras.length > 1) cambiar.style.display = '';
        } catch (e) {
          camaras = [];
        }
      }

      function listo() {
        var pista = stream && stream.getVideoTracks()[0];
        var cfg = pista && pista.getSettings ? pista.getSettings() : {};
        aviso.textContent = 'Acercá el teléfono a unos 15 cm y esperá a que se vea nítido.' +
          (cfg.width ? ' (' + cfg.width + 'x' + cfg.height + ')' : '');
        disparar.disabled = false;
      }

      // Intenta varias configuraciones hasta que llegue imagen.
      async function iniciar() {
        var intentos = [
          { audio: false, video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } } },
          { audio: false, video: { facingMode: { ideal: 'environment' } } },
          { audio: false, video: true }
        ];
        var ultimoError = null;
        var negro = null; // configuración que dio cuadros, pero negros
        for (var i = 0; i < intentos.length; i++) {
          if (terminado) return;
          if (i > 0) aviso.textContent = 'La cámara no muestra imagen, probando otra configuración...';
          try {
            var r = await abrir(intentos[i]);
            if (r === 'ok') { await cargarCamaras(); listo(); return; }
            if (r === 'negro' && !negro) negro = intentos[i];
          } catch (e) {
            ultimoError = e;
            if (e && e.name === 'NotAllowedError') break;
          }
        }
        // Se prueba con cada cámara, una por una.
        await cargarCamaras();
        for (var j = 0; j < camaras.length; j++) {
          if (terminado) return;
          aviso.textContent = 'Probando la cámara ' + (j + 1) + ' de ' + camaras.length + '...';
          try {
            var rc = await abrir({ audio: false, video: { deviceId: { exact: camaras[j].deviceId } } });
            if (rc === 'ok') {
              indiceCamara = j;
              listo();
              return;
            }
          } catch (e) {
            ultimoError = e;
          }
        }
        // Llegaban cuadros pero oscuros: puede ser un lugar sin luz. Se deja
        // usar igual, avisando.
        if (negro) {
          try {
            if ((await abrir(negro)) !== 'nada') {
              await cargarCamaras();
              listo();
              aviso.textContent = 'La imagen se ve negra. Si hay buena luz, otra app puede estar usando la cámara: ' +
                'cerrala o tocá "Cambiar cámara".';
              return;
            }
          } catch (e) {}
        }
        disparar.disabled = true;
        if (ultimoError && ultimoError.name === 'NotAllowedError') {
          aviso.textContent = 'No hay permiso para usar la cámara. Habilitalo en la configuración del navegador.';
        } else {
          aviso.textContent = 'La cámara no envía imagen. Cerrá otras apps o pestañas que la usen, o reiniciá el teléfono' +
            (ultimoError && ultimoError.name ? ' (' + ultimoError.name + ')' : '') + '.';
        }
      }

      cancelar.onclick = function () { cerrar(null); };

      cambiar.onclick = async function () {
        if (!camaras.length) return;
        disparar.disabled = true;
        indiceCamara = (indiceCamara + 1) % camaras.length;
        aviso.textContent = 'Cambiando a la cámara ' + (indiceCamara + 1) + ' de ' + camaras.length + '...';
        try {
          if ((await abrir({ audio: false, video: { deviceId: { exact: camaras[indiceCamara].deviceId } } })) === 'ok') {
            listo();
          } else {
            aviso.textContent = 'Esta cámara no muestra imagen. Tocá "Cambiar cámara" otra vez.';
          }
        } catch (e) {
          aviso.textContent = 'No se pudo abrir esta cámara (' + (e && e.name) + '). Tocá "Cambiar cámara" otra vez.';
        }
      };

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
          if (!video.videoWidth) throw new Error('sin imagen');
          cerrar(await aJpeg(video, video.videoWidth, video.videoHeight, 2000));
        } catch (e) {
          aviso.textContent = 'No se pudo sacar la foto. Probá de nuevo.';
          disparar.disabled = false;
        }
      };

      if (!window.safebiteCamaraDisponible()) {
        aviso.textContent = 'Este navegador no permite usar la cámara.';
        return;
      }
      iniciar();
    });
  };
})();
