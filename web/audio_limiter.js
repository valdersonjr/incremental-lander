/* audio-limiter: limitador do Master na web (auditoria de som v2, 2026-10-09). Em modo Sample o Godot nao aplica
   efeitos de bus (o HardLimiter do Master e so desktop), entao a soma de sons podia passar de 0 dBFS e estalar.
   Toda ligacao a saida do Web Audio passa por: pre-ganho 1/4 -> WaveShaper (linear ate -3 dBFS, joelho suave ate
   -0,3 dBFS, estouros de ate +12 dB) -> saida. Sem ganho de compensacao (DynamicsCompressor teria) e sem latencia.
   Sem oversample: o filtro de reamostragem do '2x' 'toca' depois do clip e passava de 0 dBFS (+1,7 dB medido).
   Fonte unica: web/audio_limiter.js; copiado no html/head_include do preset Web (tests/test_audio_assets.py confere). */
(function () {
  var connect = AudioNode.prototype.connect, chains = new WeakMap(), N = 4096, LIN = 0.708, TOP = 0.966;
  var curve = new Float32Array(N);
  for (var i = 0; i < N; i++) {
    var x = 4 * (2 * i / (N - 1) - 1), a = Math.abs(x);
    var y = a <= LIN ? a : LIN + (TOP - LIN) * Math.tanh((a - LIN) / (TOP - LIN));
    curve[i] = x < 0 ? -y : y;
  }
  AudioNode.prototype.connect = function (dest) {
    if (!(dest instanceof AudioDestinationNode)) return connect.apply(this, arguments);
    var ctx = dest.context, head = chains.get(ctx);
    if (!head) {
      head = ctx.createGain(); head.gain.value = 0.25;
      var shaper = ctx.createWaveShaper(); shaper.curve = curve; shaper.oversample = 'none';
      connect.call(head, shaper); connect.call(shaper, dest);
      chains.set(ctx, head);
    }
    return connect.call(this, head);
  };
})();
