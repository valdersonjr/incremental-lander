# Jingles de progresso: marco, mundo liberado, recomeço, final

- **Slug**: progress-jingles
- **kind**: jingle (mono, −16 LUFS, ≤ 4 s)
- **Evento/frequência** (raros → longos e brilhantes): `milestone` ao passar um marco de upgrade (a cada 25 níveis) ou
  comprar etapa da Expedição; `unlock` ao liberar mundo; `prestige` ao recomeçar; `goal` no final. Um por vez (o novo
  corta o anterior: liberar o Quarto toca `unlock` e o `goal` o substitui); a música abaixa −9 dB enquanto toca.
- **Mundo completo** (2026-10-09): `world_complete` na parada `complete_<mundo>` da Estrada (última estrela; 6 vezes no
  jogo), no lugar do `unlock` genérico (`Sound._on_road_reached`).
- **Assets** ← `audio/src/sfx/progress_sfx.py --export`: `assets/audio/sfx/world_complete.wav`, `assets/audio/sfx/milestone.wav`, `assets/audio/sfx/unlock.wav`,
  `assets/audio/sfx/prestige.wav`, `assets/audio/sfx/goal.wav`

## O que caracteriza o som (pesquisa)
- Subir = recompensa; frase de 4 notas com forma melódica vira assinatura da progressão; brilho no fim.
- Hierarquia: quanto mais raro, mais longo e rico (marco 1,7 s < mundo 2,8 s < recomeço 3,1 s < final 3,8 s).

## Receita final
- milestone: pulso 25% D5 E5 F#5 A5 B5 D6 (55 ms cada) + sino FM D6 + pulso 12,5% com vibrato; eco 0,16 s.
- unlock: arpejo D4 A4 D5 F#5 A5 (90 ms) → acorde D maior (pulso+triângulo) + sino A5 + baixo D3; eco 0,22 s.
- prestige: cascata de sinos em D lídio (D5…E6, 110 ms, com G#) + pad serra com filtro abrindo 400→3,5k; eco 0,19 s.
- goal: duas frases (D5 F#5 A5 F#5 A5 | B5 A5 B5 D6) com triângulo uma oitava abaixo → acorde D maior + sino D6 + D2.

- world_complete (opção A "caixinha", 3,9 s): motivo do tema do gatinho na ocarina do tema (`_lead_ocarina`)
  F#5 A5 B5 A5 F#5 | E5 → D5 (colcheia 0,13 s), marimba caminhando D–F#–A–F# em colcheias −10 dB, baixo do tema
  (D3 → A2 → D3: cadência V → I), "ta-dá" no acorde final: marimba dedilhada D4 F#4 A4 D5 (35 ms entre notas) + sinos
  FM A5/D6; eco 3 colcheias; passa-baixa 6 kHz. Opções B (pulso 25% dobrando uma oitava abaixo) e C (motivo nos sinos)
  ficam no script (`--options`).

## Feedback do usuário (o que mudou e por quê)
- world_complete: escolheu **A (caixinha)** ouvindo A/B/C numa página no navegador (sozinha + no voo com a música
  abaixada). Pediu que toda escolha de som seja sempre uma página aberta no navegador, não afplay + pergunta no terminal.

## Erros / avisos resolvidos
- world_complete passava de 4 s → nota final 10 → 8 colcheias, sinos 1,6/1,4 → 1,3/1,2 s.
- goal passava de 4 s → acorde final 1,9 → 1,6 s.

## Fontes
- https://morphic.com/resources/sounds/level-up-sound-effects — tipos de level-up: frase de 4 notas (assinatura), arpejo subindo, ping curto para upgrades frequentes
- https://opengameart.org/node/22618 — jingles chiptune curtos de vitória/desbloqueio
- https://www.mariowiki.com/Course_Clear_(Super_Mario_World) — o "Course Clear" é um arranjo do tema principal (Ground
  BGM): jingle de fase completa reaproveita a melodia do jogo → coesão com a trilha
- https://views.washingtonian.com/vie/super-mario-level-complete-the-cadence-of-cadence-roman-notes-guides-the-journey —
  a sensação de "completo" vem da cadência (fechamento na tônica)
- https://morphic.com/resources/sounds/level-up-sound-effects — frase de 4 notas com forma melódica vira assinatura; fanfarra
  subindo para os momentos que merecem aplauso (fase completa)

## Auditoria v2 (2026-10-09)
- milestone: pulso 25% no lugar de 12,5% e passa-baixa 5 kHz (agudo 22% → 12%). unlock/goal intactos. Ver `mix-system`.
