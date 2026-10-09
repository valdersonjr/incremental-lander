# Loops das mecânicas dos mundos: gelo, vento/correntes, bolhas

- **Slug**: world-loops
- **kind**: loop (mono, −18 LUFS); o jogo controla volume (e pitch) pela intensidade da mecânica
- **Evento/frequência**: enquanto a mecânica age na nave — Sorvete: deslizando no gelo (volume e pitch pela
  velocidade); Jardim: vento de dente-de-leão (volume pela força da rajada, mesmo pousado); Nuvens: dentro de uma
  corrente (mesmo vento, pitch 1,33); Bolhas: dentro de uma coluna de bolhas.
- **Assets** ← `audio/src/sfx/world_loops.py --export`: `assets/audio/sfx/ice_slide.wav`,
  `assets/audio/sfx/wind_loop.wav`, `assets/audio/sfx/bubbles_loop.wav`

## O que caracteriza o som (pesquisa)
- Loop de mecânica = camada contínua cujo **volume segue a força** (como o propulsor segue a potência): o jogador
  "ouve" a rajada chegando e a nave freando no gelo.
- Emenda: descartar o aquecimento dos filtros (PRE) e fechar com crossfade; LFOs com ciclos inteiros no loop.
- Vento = ruído rosa em passa-banda que respira; patins/gelo = chiado agudo com grão irregular + rumor do casco;
  bolhas = muitas bolhinhas (seno curto com pitch subindo) espalhadas sem ritmo sobre um borbulhar grave.

## Receita final (camadas)
| Loop | Camadas | Duração |
|---|---|---|
| ice_slide | branco BP 2,5–6k × grão aleatório 14 Hz + marrom LP 260 + triângulo D3 LP 400 (−22) | 1,5 s |
| wind_loop | rosa BP 500–1600 Hz respirando 3×/loop (q 1,4) + seno A4 com vibrato, volume 0–0,06 no mesmo LFO | 4 s |
| bubbles_loop | marrom LP 400 pulsando 6×/loop + 30 bolhas (350–1100 Hz ×2,2, 30–70 ms, −10…−3) | 2 s |

## Integração (Godot)
- `Flight._update_env_sound(delta)`: um `AudioStreamPlayer` (bus SFX); nível 0..1 suavizado (6/s), `linear_to_db`;
  para abaixo de 0,02. Gelo: |v| / 8 m/s e pitch 0,8…1,15. Jardim: |vento| / vento máximo da estrela.

## Feedback do usuário (o que mudou e por quê)
- 2026-10-09: auditoria de som — as mecânicas dos mundos eram mudas.

## Erros / avisos resolvidos
- Nenhum aviso (emendas 0,4–0,7 dB).

## Fontes
- https://www.audiokinetic.com/en/generating-rain-with-pure-synthesis — água/vento por síntese pura, camadas por intensidade
- https://graphics.stanford.edu/papers/coupledbubbles — bolhas como osciladores senoidais com pitch modulado
- https://www.hackster.io/nowickam/what-is-in-the-shell-ocean-7ce990 — bolha: seno com FM controlada por LFO
