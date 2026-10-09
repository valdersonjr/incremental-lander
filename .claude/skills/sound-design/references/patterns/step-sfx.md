# Sons de progresso: parada da Estrada, degrau de peça, pouso perfeito

- **Slug**: step-sfx
- **kind**: jingle (road_stop, part_step) · sfx (perfect)
- **Evento/frequência**: `road_stop` a cada parada nova da Estrada (~29 por mundo: FREQUENTE); `part_step` quando uma peça
  sobe de degrau e cresce no desenho (a cada 10 níveis); `perfect` depois de cada pouso perfeito, subindo um grau da
  pentatônica a cada perfeito seguido no run (`Sound.perfect(sequência)`, `PERFECT_STEPS` 0/2/4/7/9 semitons).
- **Assets** ← `audio/src/sfx/step_sfx.py --export`: `assets/audio/sfx/road_stop.wav`, `assets/audio/sfx/part_step.wav`,
  `assets/audio/sfx/perfect.wav` (opções B no script: `--options`)

## O que caracteriza o som (pesquisa)
- Confirmação frequente = "quick ping up" de 2–3 notas, curto e claro, quieto o bastante para ouvir cem vezes.
- Recompensa de progresso = timbres tonais (sino, xilofone); recompensa maior = mais camadas/acorde.
- Sequência de acertos = cue sequencial (cada repetição sobe), "juice" só no acerto.

## Receita final (opção A de cada, escolhida pelo usuário)
| Som | Camadas | Duração |
|---|---|---|
| road_stop | marimba do tema D5 F#5 A5 (75 ms entre notas, cada uma +1 dB) + sininho FM A6 (−12 dB); passa-baixa 5 kHz | 0,85 s |
| part_step | 3 cliques de catraca (ruído em banda 900/1200/1500 Hz + triângulo) → "boing" triângulo D4→D5 → acorde de sinos D5 F#5 A5 | 1,24 s |
| perfect | 2 sinos FM rápidos A5 → D6 (índice 1,5/1,3) + brilho de ruído em banda 2,5–4,5 kHz; passa-baixa 4,5 kHz | 0,52 s |
- Substituem: `unlock` (fanfarra de 2,8 s) nas paradas comuns, `milestone` no degrau (continua nos marcos que não são
  degrau), `combo_2..5` no pouso perfeito (apagados; `reward_sfx.combo()` fica de referência).

## Feedback do usuário
- Escolheu **A, A, A** numa página no navegador com "atual (manter)", A e B de cada, sozinho e no jogo (sobre a música
  abaixada; pouso perfeito como 3 perfeitos seguidos subindo de tom).

## Erros / avisos resolvidos
- perfect A (28% > 5 kHz) e road_stop B (25%) passavam do limite de som frequente (15%) → índice FM menor e
  passa-baixa 4,2–4,5 kHz (7% e 6%).

## Fontes
- https://morphic.com/resources/sounds/level-up-sound-effects — "quick ping up" de duas notas para upgrades frequentes; brilho subindo para coletáveis
- https://sonilo.com/ai-music/ding-sound-effect-guide — o melhor "ding" é o mais curto e claro; quieto para ouvir cem vezes sem fadiga
- https://blog.criware.com/index.php/2023/08/23/reward-effects/ — recompensa: sinos/xilofone, acorde que cresce com a recompensa, cue sequencial
- https://mechanicsofmagic.com/2025/04/22/juiciness-and-world-of-goo-justin/ — juice só quando a ação do jogador acerta
