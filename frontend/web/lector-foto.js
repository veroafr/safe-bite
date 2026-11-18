// Safe-Bite: lee el código de barras en una FOTO (no en el video en vivo).
//
// La foto que saca la cámara del teléfono tiene mucha más resolución y mejor
// enfoque que el video del navegador, así que es la forma más confiable de
// leer el código. Se usa desde el botón "Foto del código" del escáner.
//
// Orden: 1) detector nativo del navegador (BarcodeDetector, Chrome en
// Android), 2) ZXing a varios tamaños y también girada 90°, por si el código
// está vertical. Devuelve el texto del código o null.
(function () {
  var FORMATOS_NATIVOS = ['ean_13', 'ean_8', 'upc_a', 'upc_e', 'code_128', 'itf'];

  function cargarZxing() {
    if (window.ZXing && window.ZXing.MultiFormatReader) return Promise.resolve();
    return new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = 'zxing/index.min.js';
      s.onload = function () { resolve(); };
      s.onerror = function () { reject(new Error('No se pudo cargar ZXing')); };
      document.head.appendChild(s);
    });
  }

  function conZxing(imagen) {
    var Z = window.ZXing;
    var hints = new Map();
    hints.set(Z.DecodeHintType.TRY_HARDER, true);
    hints.set(Z.DecodeHintType.POSSIBLE_FORMATS, [
      Z.BarcodeFormat.EAN_13, Z.BarcodeFormat.EAN_8, Z.BarcodeFormat.UPC_A,
      Z.BarcodeFormat.UPC_E, Z.BarcodeFormat.CODE_128, Z.BarcodeFormat.ITF
    ]);
    var lector = new Z.MultiFormatReader();
    lector.setHints(hints);

    var anchos = [1600, 1100, 800, 500];
    for (var i = 0; i < anchos.length; i++) {
      var escala = Math.min(1, anchos[i] / imagen.width);
      var w = Math.max(1, Math.round(imagen.width * escala));
      var h = Math.max(1, Math.round(imagen.height * escala));
      for (var giro = 0; giro < 2; giro++) {
        var lienzo = document.createElement('canvas');
        lienzo.width = giro ? h : w;
        lienzo.height = giro ? w : h;
        var ctx = lienzo.getContext('2d', { willReadFrequently: true });
        if (giro) {
          ctx.translate(h, 0);
          ctx.rotate(Math.PI / 2);
        }
        ctx.drawImage(imagen, 0, 0, w, h);
        try {
          var fuente = new Z.HTMLCanvasElementLuminanceSource(lienzo);
          var r = lector.decode(new Z.BinaryBitmap(new Z.HybridBinarizer(fuente)));
          if (r && r.getText()) return r.getText();
        } catch (e) {
          // No lo encontró en este tamaño o giro: se prueba el siguiente.
        }
      }
    }
    return null;
  }

  function pistaActiva() {
    var p = window.__safebitePista;
    return p && p.readyState === 'live' ? p : null;
  }

  // ¿Hay una camara del escaner encendida de la que sacar la foto?
  window.safebitePuedeFotografiarVideo = function () {
    return !!pistaActiva();
  };

  async function reducir(fuente, maxLado) {
    var w = fuente.width || fuente.videoWidth;
    var h = fuente.height || fuente.videoHeight;
    var escala = Math.min(1, maxLado / Math.max(w, h));
    var lienzo = document.createElement('canvas');
    lienzo.width = Math.round(w * escala);
    lienzo.height = Math.round(h * escala);
    lienzo.getContext('2d').drawImage(fuente, 0, 0, lienzo.width, lienzo.height);
    var blob = await new Promise(function (r) { lienzo.toBlob(r, 'image/jpeg', 0.9); });
    return blob ? new Uint8Array(await blob.arrayBuffer()) : null;
  }

  // Saca una foto con la camara que ya usa el escaner. Con ImageCapture
  // (Chrome en Android) la foto sale a resolucion completa y enfocada; si no,
  // se copia el cuadro actual del video. Devuelve un JPEG o null.
  window.safebiteTomarFotoDelVideo = async function () {
    var pista = pistaActiva();
    if (!pista) return null;
    if (typeof window.ImageCapture === 'function') {
      try {
        var foto = await new window.ImageCapture(pista).takePhoto();
        var bmp = await createImageBitmap(foto);
        return await reducir(bmp, 2000);
      } catch (e) {
        // Se usa el cuadro del video.
      }
    }
    var videos = document.querySelectorAll('video');
    for (var i = 0; i < videos.length; i++) {
      if (videos[i].videoWidth > 0) {
        try { return await reducir(videos[i], 2000); } catch (e) {}
      }
    }
    return null;
  };

  window.safebiteLeerCodigoEnFoto = async function (bytes) {
    var imagen;
    try {
      imagen = await createImageBitmap(new Blob([bytes]));
    } catch (e) {
      return null;
    }

    if (typeof window.BarcodeDetector === 'function') {
      try {
        var detector = new window.BarcodeDetector({ formats: FORMATOS_NATIVOS });
        var codigos = await detector.detect(imagen);
        if (codigos && codigos.length > 0 && codigos[0].rawValue) return codigos[0].rawValue;
      } catch (e) {
        // Se sigue con ZXing.
      }
    }

    try {
      await cargarZxing();
      return conZxing(imagen);
    } catch (e) {
      return null;
    }
  };
})();
