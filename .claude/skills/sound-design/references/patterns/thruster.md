# Propulsor do lander (ignição + loop + corte)

- **Slug**: thruster · **kind**: loop (+ sfx para ignição/corte)
- **Assets** ← `audio/src/sfx/thruster.py --export A`: `assets/audio/sfx/thruster_loop.wav` (2 s, loop no WAV),
  `thruster_start.wav`, `thruster_stop.wav`. Prévias: `audio/previews/thruster_{A,B,C}_demo.wav`.

## Pesquisa
- Dividir o motor em camadas por faixa (ronco grave / sopro médio / detalhe) que não brigam e podem variar por upgrade.
- Eventos: ignição (pitch sobe, whoosh) → loop → corte (pitch cai). Modulação lenta (phaser/filtro) evita fadiga.
- Controle no jogo: volume/pitch/filtro pela potência (bus Engine com LowPassFilter).

## Receita escolhida (A, plasma suave)
- Zumbido: `unison(triangle, D2, 3 vozes, 9 cents)` LP 320 Hz · sopro: ruído pink em `svf` passa-banda com cutoff
  `lfo(2 ciclos/loop, 900–2200 Hz)` · brilho: FM em A5 HP 2 kHz bem baixo · `tremolo` 18 Hz 10%.
- **Descartar 0,3 s iniciais** (aquecimento dos filtros) antes de `make_loop`, senão a emenda salta ~8 dB.
- Ignição: ruído pink com filtro 200→3k + thump sub, fim suave; toca **por cima** do loop (não encadeado).
- Corte: `pitch_shift(-5)` + filtro fechando 3k→200 em 0,35 s (cortar o tamanho pelo sinal real: o pitch_shift
  pode encurtar 1 amostra).

## Integração (Godot)
- `Lander`: `ThrustLoop` (AudioStreamPlayer2D, bus Engine) + `ThrustFx` (start/stop). O autopiloto pulsa o motor
  (sigma-delta): ignição só se o motor ficou parado > 0,25 s; loop só para após 0,12 s desligado.

## Decisões do usuário
- 2026-10-01: 3 opções (A plasma suave, B foguete grave, C chip retrô); o usuário pediu "escolhe qualquer 1" → A.

## Fontes
- https://www.moddb.com/tutorials/tutorial-engine-thruster-sounds — 8 loops por faixa, kick-up/power-down, camadas trocáveis por upgrade
- https://blog.criware.com/index.php/2022/12/12/designing-spaceship-engines/ — camadas por RPM, curvas de volume/pitch, phaser/flanger contra fadiga
- https://synthanatomy.com/2018/10/spacemotors-is-a-sci-fi-vehicle-synthesizer-for-complex-dynamic-engine-sounds.html — motores sci-fi sintetizados

## Auditoria v2 (2026-10-09)
- Zumbido saiu do D2 (87% < 120 Hz, mascarava o baixo da música e sumia no notebook) para D2 fino + D3 + quinta A3 (passa-alta 55 Hz, passa-baixa 480 Hz): 14% < 120 Hz. Ignição ganhou "fup" de triângulo A3→D3 e o thump sub −5 dB; o corte deriva do loop novo (perda no notebook 11 → 3,6 dB). Mesmo caráter plasma suave (opção A). Ver `mix-system`.
