# Carga rebocada por cabo (pêndulo à la Thrust)

- **Onde**: `scripts/world/cargo_tow.gd` (puro, testado em `tests/unit/world/test_cargo_tow.gd`); ligado em
  `Flight._tick_cargo` (Lua, carga "towed", 2026-10-05).

## Solução
- A carga é **um ponto com massa** (não RigidBody2D): integra gravidade e posição nas mesmas unidades do Lander
  (px do mundo, m/s do modelo, dt do modelo = delta × time_scale).
- Cabo = restrição de **comprimento máximo**: se `dist > L`, projeta a carga de volta para `âncora + n·L` e, se a
  velocidade relativa ao longo de `n` está afastando, troca impulso `j = vr / (1/m + 1/1)` (nave = massa 1):
  carga perde `j/m`, nave ganha `j` (vai em `lander.vel_m +=`). Frouxo = sem força (cai/balança livre).
- Pousada, a nave é fixa (`anchor_free = false`): só a carga é corrigida.
- Chão: clamp no relevo (`TerrainGen.height_at`), quica (bounce) e atrito por segundo do modelo (`pow(f, dt)`);
  impacto vertical > `break_speed` → `damaged`.
- Ordem: `Flight._physics_process` roda antes do filho `Lander` → usa a posição do quadro anterior; sem instabilidade
  porque a correção é por posição (PBD), não mola.

## Armadilhas
- Teste de queda com âncora longe: o cabo esticado segura a carga e ela nunca toca o chão (o teste falhou por isso).
- Velocidade em m/s × dt do modelo = px por passo (px_per_m = 1): 9 m/s ≈ 0,7 px por quadro — testes precisam de
  centenas de passos para cair dezenas de px.

## Fontes
- https://www.love2d.org/forums/viewtopic.php?p=239411 — Thrust II: restrição de comprimento do cabo entre nave e orbe
- https://en.wikipedia.org/wiki/Thrust_(video_game) — nave e pod ligados por haste girando um em volta do outro
- https://forum.godotengine.org/t/help-needed-for-creating-swinging-ropes/130043 — cordas no Godot 4 (verlet/joints)
