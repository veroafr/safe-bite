// Safe-Bite: mejora la cámara del lector de códigos en la versión web.
//
// El lector (mobile_scanner + ZXing) pide la cámara sin indicar resolución
// ni enfoque, así que el navegador entrega una imagen de 640x480 y sin
// autoenfoque continuo: a la distancia de un código de barras se ve borrosa
// y ZXing no la reconoce. Este script intercepta el pedido de la cámara,
// solicita una resolución mayor y activa el enfoque continuo cuando el
// teléfono lo permite. No afecta a la foto de "Escanear paquete", que usa el
// selector de archivos del sistema.
(function () {
  var md = navigator.mediaDevices;
  if (!md || typeof md.getUserMedia !== 'function') return;

  var original = md.getUserMedia.bind(md);
  // La camara propia (camara-app.js) lo usa para reintentar sin estos ajustes.
  md.__safebiteGetUserMediaOriginal = original;

  md.getUserMedia = function (constraints) {
    var c = constraints;
    if (c && c.video) {
      var video = typeof c.video === 'object' ? Object.assign({}, c.video) : {};
      if (!video.width) video.width = { ideal: 1920 };
      if (!video.height) video.height = { ideal: 1080 };
      c = Object.assign({}, c, { video: video });
    }

    return original(c)
      .catch(function (error) {
        // Si el dispositivo no acepta esa resolución, se usa el pedido original.
        if (error && (error.name === 'OverconstrainedError' || error.name === 'ConstraintNotSatisfiedError')) {
          return original(constraints);
        }
        throw error;
      })
      .then(function (stream) {
        // Se guarda la pista de video para poder sacar una foto desde el
        // propio escaner (ver lector-foto.js), sin abrir la camara del
        // sistema, que en Android choca con la camara que ya esta en uso.
        try {
          var pista = stream.getVideoTracks()[0];
          if (pista) window.__safebitePista = pista;
        } catch (e) {}
        try {
          stream.getVideoTracks().forEach(function (track) {
            var caps = typeof track.getCapabilities === 'function' ? track.getCapabilities() : {};
            var ajustes = {};
            if (caps.focusMode && caps.focusMode.indexOf('continuous') !== -1) {
              ajustes.focusMode = 'continuous';
            }
            if (Object.keys(ajustes).length > 0) {
              track.applyConstraints({ advanced: [ajustes] }).catch(function () {});
            }
          });
        } catch (e) {
          // Nunca impedir que la cámara arranque por estos ajustes.
        }
        return stream;
      });
  };
})();
