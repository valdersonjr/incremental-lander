# Ambiência e loops contínuos

## Loops sem emenda
- Clique na emenda = salto entre o último e o primeiro sample (energia de banda larga).
- Técnicas:
  1. **Crossfade** (`make_loop(x, dur, crossfade)`): gere o som com `dur + crossfade` e mixe o excesso
     sobre o começo com curva de potência constante. Ruídos/drones: crossfade 0.1–1 s.
  2. **Cauda dobrada** (`wrap_tail(x, dur)`): para material com reverb/eco (música, pads).
  3. **Periodicidade exata**: LFOs com número inteiro de ciclos no loop (`rate = k / dur`) → a
     modulação também fecha o ciclo.
- Validação: `save_wav(..., loop=True)` → relatório (salto, energia) + zoom da emenda no gráfico.
- Fontes: habrador.com (seamless loop), Steinberg WaveLab (refining loops), fóruns KVR/Audacity.

## Loops de gameplay (propulsor, motor, alarme)
- Divida o espectro em camadas intercambiáveis (ronco grave / sopro médio / chiado agudo) — permite
  variar por upgrade e controlar cada uma no Godot.
- Motor com **eventos**: start (kick-up) → loop → stop (power-down). Pitch sobe na ignição e cai no corte.
- Controle em tempo real no Godot: volume e `pitch_scale` do AudioStreamPlayer + filtro de bus
  (`AudioEffectLowPassFilter.cutoff_hz`) seguindo a potência do propulsor — "cutoff mais baixo = motor
  em marcha lenta".
- Duração: 1–4 s basta se houver modulação aleatória suficiente e emenda boa.
- Fonte: moddb.com (Tutorial: engine thruster sounds), gamedeveloper.com (Procedural Audio in Unity).

## Ambiência espacial
- Camadas: **drone grave** (senos/triângulos desafinados em D, `unison`), **ar/ruído** (pink/brown com
  LP lento modulado), **textura** (pad filtrado, bandpass ressonante varrendo), **eventos raros**
  (sinos FM distantes com reverb, bips de rádio) — eventos em loop ≥ 20–30 s para não perceber repetição.
- Movimento lento: LFOs 0.02–0.2 Hz em filtro e volume; nada rítmico.
- Estéreo largo (`unison(..., stereo=True)`, reverb estéreo); loudness baixo (−24 LUFS) — fica
  embaixo de tudo.
- Tonal em D (drone na tônica/quinta) para casar com música e SFX.
