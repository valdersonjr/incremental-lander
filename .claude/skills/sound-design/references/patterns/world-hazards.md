# Perigos por mundo: rajada, gêiser de calda, assobio de queda

- **Assets** ← `audio/src/sfx/hazard_sfx.py --export`: `assets/audio/sfx/gust.wav`, `assets/audio/sfx/geyser.wav`,
  `assets/audio/sfx/toy_fall.wav` (sfx). Tocam quando o perigo LIGA a menos de ~1 tela da nave (aviso sonoro).

## Receita
- Rajada: ruído rosa → passa-banda (q 1,4) varrendo 300 → 1,4k → 500 Hz (exp) + volume subindo até 0,35 s e caindo; 0,95 s.
- Gêiser: baque senoidal 95 → 50 Hz (0,18 s) + 26 bolhas (seno 18 ms com o tom subindo ×1,5, notas da escala entre
  380 e 1500 Hz, a cada ~22 ms) + chiado HP 2,5k decaindo (−20 dB); LP 7k.
- Brinquedo: triângulo descendo A6 → D5 em 0,9 s com vibrato leve (7 Hz, 0,15 st); convenção de desenho animado.

## Pesquisa (regras)
- Vento/whoosh = ruído colorido + filtro varrendo (abre e fecha) + curva de volume; rosa soa menos áspero que branco.
- Líquido = muitas bolhas: seno curto (10–20 ms) com o tom modulado (subindo).
- Queda = assobio fino descendo; o slide de pitch faz todo o trabalho.

## Decisões do usuário
- Prefere não auditar som por som: tocados uma vez em sequência (2026-10-03).

## Fontes
- https://violetrecording.com/how-to-make-whoosh-sounds/ — whoosh: filtro varrendo + curva de volume + pitch
- https://www.kvraudio.com/forum/viewtopic.php?p=142567 — vento: LP ressonante sobre ruído, cutoff varrendo
- https://www.audiokinetic.com/en/generating-rain-with-pure-synthesis — gota/bolha = seno com pitch modulado, 10–20 ms
- https://morphic.com/resources/sounds/falling-sound-effect — assobio descendo = convenção de queda
