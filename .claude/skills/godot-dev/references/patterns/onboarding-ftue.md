# Primeiros minutos (FTUE): ensinar fazendo, sem punir quem aprende

Data: 2026-10-08 · Relatório: https://claude.ai/artifact/Eme3BchGnN7iMng1rGbNSg · Regras: `data/world.json > onboarding`

## Fontes
- Andersen et al. 2012 (CHI, 45 mil jogadores): tutorial só ajuda em jogo complexo; ajuda no contexto > manual.
  https://grail.cs.washington.edu/projects/game-abtesting/chi2012/
- Passalacqua et al. 2020: tutorial aumenta o flow de quem NÃO é experiente. https://www.mdpi.com/2414-4088/4/3/41/html
- Hodent (GDC 2016): aprender fazendo, ≤ 3 coisas novas por vez, não punir no aprendizado. https://celiahodent.com/gamers-brain-ux-onboarding/
- Nintendo Super Guide: ajuda aparece só depois de falhas. Celeste/Super Meat Boy: custo de errar baixo.

## Como ficou no jogo
- **Aprendiz** = `GameState.apprentice()` (estrelas < `apprentice_stars`; save antigo com estrelas já é veterano, sem
  migração). Batida/sem gás → `Main._retry_hop` → `Flight.retry_mission(gas do começo do salto)` (mesma seed = mesmo
  mapa). Pouso devagar fora da plataforma → `Lander.ground_rest` emite `rested` (nada de batida).
- **1º salto** (`GameState.first_hop()`): `Main` aceita o pedido mais perto sozinho; `Flight.gentle` = relevo baixo
  (`shape.land.amplitude_m`, crista 0, sem paisagem); `Flight.minigame_on = false`.
- **Coach** (`game/flight/coach.gd`, filho do Flight): teclinha desenhada (seta para Up/Left/Right; senão a 1ª tecla)
  só quando falta; aprendeu = `GameState.learn_tip` (salvo em `tips`, campo opcional do save). Medidor de descida
  para todos (verde/amarelo/vermelho iguais aos números do HUD).
- **Revelação por etapas**: `GameState.shows_minigame/records/reputation/bulk`; HUD, NAVE (abas, ×10/MÁX).
- **Funil**: `Telemetry.event()` → `user://telemetry/session.csv`; `godot-dev/scripts/ftue.py` mostra decolar /
  entrega / compra por jogo novo.

## Armadilhas
- Prévias e testes que esperam o cartão de missões precisam de um jogador **veterano** (`GameState.stars = 5`):
  `flight_ui_preview` já faz isso (`--new` = jogador novo); `controls_test` grava um jogo veterano antes.
- `SaveManager.delete_slot` do jogo em uso trava o autosave: para gravar um save de teste use `new_game(n)` + `save_game()`.
- A demo (`--demo`) começa com 0 estrelas: não tratar como aprendiz (minijogo ligado, sem retry).
