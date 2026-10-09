# Jingles de progresso: marco, mundo liberado, recomeço, final

- **Slug**: progress-jingles
- **kind**: jingle (mono, −16 LUFS, ≤ 4 s)
- **Evento/frequência** (raros → longos e brilhantes): `milestone` ao passar um marco de upgrade (a cada 25 níveis) ou
  comprar etapa da Expedição; `unlock` ao liberar mundo; `prestige` ao recomeçar; `goal` no final. Um por vez (o novo
  corta o anterior: liberar o Quarto toca `unlock` e o `goal` o substitui); a música abaixa −9 dB enquanto toca.
- **Assets** ← `audio/src/sfx/progress_sfx.py --export`: `assets/audio/sfx/milestone.wav`, `assets/audio/sfx/unlock.wav`,
  `assets/audio/sfx/prestige.wav`, `assets/audio/sfx/goal.wav`

## O que caracteriza o som (pesquisa)
- Subir = recompensa; frase de 4 notas com forma melódica vira assinatura da progressão; brilho no fim.
- Hierarquia: quanto mais raro, mais longo e rico (marco 1,7 s < mundo 2,8 s < recomeço 3,1 s < final 3,8 s).

## Receita final
- milestone: pulso 25% D5 E5 F#5 A5 B5 D6 (55 ms cada) + sino FM D6 + pulso 12,5% com vibrato; eco 0,16 s.
- unlock: arpejo D4 A4 D5 F#5 A5 (90 ms) → acorde D maior (pulso+triângulo) + sino A5 + baixo D3; eco 0,22 s.
- prestige: cascata de sinos em D lídio (D5…E6, 110 ms, com G#) + pad serra com filtro abrindo 400→3,5k; eco 0,19 s.
- goal: duas frases (D5 F#5 A5 F#5 A5 | B5 A5 B5 D6) com triângulo uma oitava abaixo → acorde D maior + sino D6 + D2.

## Erros / avisos resolvidos
- goal passava de 4 s → acorde final 1,9 → 1,6 s.

## Fontes
- https://morphic.com/resources/sounds/level-up-sound-effects — tipos de level-up: frase de 4 notas (assinatura), arpejo subindo, ping curto para upgrades frequentes
- https://opengameart.org/node/22618 — jingles chiptune curtos de vitória/desbloqueio

## Auditoria v2 (2026-10-09)
- milestone: pulso 25% no lugar de 12,5% e passa-baixa 5 kHz (agudo 22% → 12%). unlock/goal intactos. Ver `mix-system`.
