# Arquitetura do projeto

> Estrutura de pastas e responsabilidades **do projeto real**. Os padrões (como organizar cenas, autoloads,
> sinais, save, testes) estão na skill `godot-dev` (`references/architecture.md`); este arquivo registra o
> que **existe** — atualize a cada item do ROADMAP.

## Pastas (existentes)
```
CLAUDE.md                     # entrada de toda sessão: regras + protocolo + mapa
project.godot                 # config Godot (640x360, escala inteira, Nearest, snap, interpolação, aviso de tipagem)
default_bus_layout.tres       # buses: Master, Music, Ambience, SFX -> Engine, UI (skill sound-design)
data/economy.json             # SPEC ÚNICA da economia (jogo + simulador) — só alterar via economy-balance
scripts/economy/econ_math.gd  # fórmulas em GDScript (class_name EconMath), espelho do econ.py
tests/                        # test_case.gd + run_tests.gd (executor), unit/test_*.gd, test_econ_math.gd +
                              # test_econ_parity.py (paridade da economia com o Python) — rodar: gdtool.py test
docs/                         # GDD, ROADMAP, HANDOFF, DECISIONS, ARCHITECTURE
art/                          # .gdignore — src/**.py (scripts geradores de pixel art), previews/ (ignorado no git)
audio/                        # .gdignore — src/**.py (scripts geradores de som), previews/ (ignorado no git)
balance/                      # .gdignore — sims/ (experimentos), reports/, telemetry/, CHANGELOG.md
.claude/skills/               # pixel-art, sound-design, economy-balance, godot-dev (padrões + ferramentas)
```

## Jogo (Fases 1–7 — voo, run, hangar, frota, save/opções; só a Lua desde 2026-10-06)
```
data/world.json               # escala (px_per_m=1), time_scale=4,5, rotate_speed=4, drag_scale, tolerâncias de pouso,
                              # relevo + cores provisórias (sky/fill/surface) por planeta, teclas (inclui end_run/confirm), demo;
                              # terrain.crest (cristas entre plataformas), terrain.pad_tiers (largura/elevação por tipo),
                              # atmosphere (ar denso perto do chão)
scripts/world/
  world_config.gd             # WorldConfig: lê world.json, m↔px, registra input (InputMap) a partir do JSON
  lander_physics.gd           # LanderPhysics.step(): gravidade + propulsor + arrasto; gás = Δv/eficiência (puro);
                              # drag_at(drag_planeta, altitude, cfg): ar mais denso perto do chão (Lander usa a cada passo)
  landing_rules.gd            # LandingRules: tolerâncias (× gear^0.5), crash_reason(), quality() 0..1 (puro)
  terrain_gen.gd              # TerrainGen.generate(seed, planeta, distâncias, tipos=[]): relevo + CRISTA entre plataformas
                              # seguidas (12% da distância acima da mais alta; arco de 45° passa) + plataformas planas com
                              # largura/elevação do tipo (estreita num vale, apertada num pico); pad = {id,x,y,half_width,tier,lift};
                              # highest_between() p/ o autopiloto (puro); extend (px a esquerda/direita) estende o mapa — relevo ANCORADO
                              # em x = 0 (grade e limite de inclinação de 0 para cada lado): estender nunca muda o que existia;
                              # Flight._extend_terrain_if_near_edge cresce 2,4 km quando a nave chega a 800 m da borda
  autopilot.gd                # Autopilot (--demo): decolagem → arco balístico (mira acima do alvo) → frenagem/pouso;
                              # motor por sigma-delta (fração exata de empuxo) — voa na Lua, Ares e Kronos; na aproximação
                              # mira 30 m acima do ponto mais alto do relevo até o alvo (cristas/picos)
game/main.tscn/.gd            # Main → World + GUI; ORQUESTRA O RUN: ofertas → set_target → entrega → GameState.add_rewards
                              # → ofertas … → resumo → HANGAR → novo run. Args: --demo --seed=N --planet=id --hangar_wait=s.
                              # Demo libera planetas, compra o upgrade mais barato, vai ao melhor planeta voável; "HANGAR {json}".
                              # Args de dev: --dev_cargo=towed|fragile|urgent|rescue|box --dev_dir=-1|1 (pedidos iniciais),
                              # --dev_levels=id:n,... --dev_credits=N --dev_ore=N --dev_shop=id:n,...
                              # --dev_unlock=a,b --planet=id (validado). Imprime também GOAL_REACHED/PRESTIGE.
                              # Imprime "DELIVERY_RESULT {json}" e "RUN_SUMMARY {json}" (verificação automática)
game/flight/flight.tscn/.gd   # Flight: Terrain + Lander + Camera; start(planeta, seed, stats, demo); begin_mission(seed, d, tier,
                              # dir, missão, stage) = mapa novo + nave descendo do céu (_arrive, Lander.arriving; fundo
                              # deslocado por _bg_origin); set_target(distância) = alvo no mesmo mapa (2º trecho do táxi)
                              # cria a próxima plataforma a partir da atual e estende o terreno;
                              # sinais delivery_finished(result) (→ Telemetry) e stranded (pousou sem gás fora do alvo)
scripts/run/run_state.gd      # RunState (puro): ofertas (log-uniformes, regeneram) com tipo de plataforma (offer_tiers),
                              # take_offer (→ taken_tier), complete_delivery(d, q, gás, cargo_ok) via EconMath.delivery_pay;
                              # streak = combo de pousos bons; deliveries[-1] guarda mult/combo/carga p/ o HUD
                              # (EconMath.contract_pay), crash, can_continue, best_offer (demo), summary
                              # v15: sem teto; fatigue() = EconMath.run_fatigue_mult(entregas); record_values() (recordes do run)
game/hud/hud.*                # (Fase 11/v14) %RepPanel: rostinho do ratinho da entrega + corações (nível) + bônus; show_reputation_up(kind, lv), "ALVO x m ×N",
                              # show_delivery(entry, rep_next) chamado pelo Main: ganho + plataforma/reputação/carga e
                              # "POUSO PERFEITO! próxima +10%"; terrain.gd escreve o multiplicador sob plataformas difíceis
game/run/offer_panel.*        # OfferPanel (2026-10-07, janela de conversa): %Dim escurece o mapa; %Chips = TODOS os tipos de
                              # EconMath.mission_kinds (bloqueado = silhueta, _peek_locked no hover); pedidos agrupados por
                              # tipo (_groups kind -> índices perto→longe, _dsel = distância marcada). %Window: %Stage (palco
                              # talk_stage_luna + %Cat/%Mouse AnimatedSprite2D talk_*_frames + %MouseBalloon = MissionText.ask/
                              # say_rule + certo×errado de MissionIntro.PICS + %CatBalloon), %Columns (Distância/Tamanho da
                              # plataforma/Dificuldade; clicar só marca), %Total + %Accept (GoButton) → joinha/happy e
                              # offer_chosen(i) após ACCEPT_S. Teclas: ←/→ ratinho, ↑/↓ plataforma, Shift+↑/↓ estrela, 1–3
                              # distância, Enter aceita, E encerra (2 toques). Teste: pad_button_center/accept_button_center
scripts/world/terrain_gen.gd  # (v15) shape do relevo da missão: rise_m, target_lift_m, crest_scale, basin_m; mission_shape()
                              # shape["land"] = paisagem (landscape(id, seed) resolve as faixas; pick_landscape(liberadas, seed));
                              # _base_y (ridged), _terrace, mean_height (fundo segue o chão; Flight._bg_ground)
scripts/ui/mission_text.gd    # MissionText: fala curta (balloon), pedido/regra da janela (ask/say_rule), regra curta (rule) e
                              # explicação (tip/kind_tip) de cada tipo de missão
game/run/mission_intro.*      # MissionIntro (v15): "Novo amiguinho!" — a oficina abre ao liberar o nó ★1 de um tipo; show_kind(kind)
game/run/run_summary.*        # RunSummary (Control modal: fundo escurecido + painel central; v15 _add_records = dinheiro grande + 4 cartões-troféu): fim do run (motivo legível,
                              # entregas, qualidade média, ganhos em UiKit.stat_row); Enter/botão "IR AO HANGAR"
autoload/events.gd            # Events: resources_changed, run_started, run_finished, upgrade_bought, stars_changed, road_reached (parada da Estrada), reputation_up(kind, level), settings_changed
autoload/game_state.gd        # GameState: recursos, níveis, current_planet (sempre "luna"), income_history, recordes,
                              # settle_run() (paga a frota ao fim do run); ship_stats(), buy_upgrade(), buy_upgrade_max(),
                              # upgrade_rows(), locked_upgrades() (via Purchases/EconMath); opções (volumes, teclas, ajudas);
                              # v13: stars = total ACUMULADO; add_stars() anda na Estrada (_check_road: ratinho → mission_nodes,
                              # habilidade/ajuda → nível 1, Frota/Piloto → can_buy) e emite Events.road_reached; road_reached,
                              # road_seen, road_news(), mark_road_seen(); rep_points {tipo: pontos} + rep_level(kind) (v14); can_buy(id);
                              # missions_unlocked(), tick_missions_new() (fim do run)
scripts/economy/fleet.gd      # Fleet (puro): average_income (últimos 5 runs), payout (EconMath.fleet_income_per_s)
scripts/economy/purchases.gd  # Purchases (puro): can_afford, buy, buy_max, upgrade_rows, locked_upgrades (requires_upgrade:
                              # Piloto automático pede Frota), milestone_crossed, max_reach_m, can_fly, can_launch
game/title/title_backdrop.*   # TitleBackdrop: cena PRÓPRIA do título (não usa o voo): camadas assets/bg/title_{sky,clouds,
                              # back,front}.png + sprites title_{cat,flag,lander,star}, posições em assets/bg/title_layout.json
                              # (art/src/title/title_moon.py). Parallax leve pelo mouse (px inteiro; camadas com layer_pad
                              # de sobra), nuvens à deriva, estrelas cintilando (_draw), estrela cadente a cada 7–13 s.
game/title/title_screen.*     # TitleScreen: menu inicial (Main._show_title: _clear_run, sem Flight; fundo = TitleBackdrop;
                              # logo + frase + coluna de botões à esquerda; subtelas no painel do meio). Jogar · Sandbox ·
                              # Opções · Sair. Jogar abre a lista SaveSlots (PLAY) + Voltar. Sinais play_requested (continuar sem os cartões; só testes),
                              # slot_play_requested(n) (Main: load_slot → idem), new_game_requested(n), current_slot_changed
                              # (apagou o jogo em uso; o fundo não depende mais do save), quit_requested; opções = volumes.
                              # Main._open_hangar monta o mundo (_build_hangar_world) quando não há Flight (vindo do título).
                              # Main pula o menu com --demo, --dev_*, --no_title. Hangar.title_requested volta ao menu.
scripts/save/sandbox.gd       # Sandbox (estático): begin(planeta, forte) guarda o jogo (save + cópia em memória), liga
                              # SaveManager.sandbox (só grava opções) e desliga a telemetria; estado de teste de
                              # data/world.json > sandbox; top_up() a cada hangar (Main._open_hangar); end() devolve o jogo
                              # (Main._show_title). TitleScreen.sandbox_requested(planeta, forte) → Main.
autoload/crt.gd               # Crt (CanvasLayer 128 + ColorRect, game/screen/crt.gdshader): filtro CRT por cima de tudo;
                              # visível = GameState.crt_enabled() (settings "crt", padrão true); ouve Events.settings_changed
game/pause/pause_menu.*       # PauseMenu = menu do jogo (Control modal, PROCESS_MODE_ALWAYS). open(Mode.FLIGHT): "PAUSA",
                              # congela a árvore; Main abre com Esc no voo ou NOTIFICATION_APPLICATION_FOCUS_OUT (_can_pause);
                              # tem "Menu inicial" (despausa; o run acaba, entregas já pagas) mas não "Novo jogo".
                              # open(Mode.HANGAR): "MENU" (Hangar.menu_requested → Main esconde o hangar); sinais
                              # title_requested, new_game_requested (Main: SaveManager.new_game → hangar), closed → hangar.
game/title/save_slots.gd      # SaveSlots (VBox): 5 cartões compactos 250x28, um embaixo do outro: faixa do mapa do jogo
                              # no fundo (assets/ui/save_bg_<mundo>.png, sem escalar), "Jogo N" + tempo (despertador),
                              # créditos e estrelas; em uso = moldura dourada. SEM apagar. PLAY (menu inicial): com jogo →
                              # slot_play_requested, vazio → new_game_requested. SAVE (menu do jogo): grava o jogo em uso
                              # no espaço (SaveManager.save_to_slot; por cima de OUTRO jogo pede 2º clique) → slot_saved.
game/hangar/hangar.*          # Hangar = tela PROGRESSÃO (v13; raiz Control: %Frame + %Balloon + %Toast + MissionIntro): cabeçalho
                              # (abas, ×1/×10/MÁX, moedas, estrelas) | %Road (RoadView) | %Body por aba (Q/E): NAVE (ShipView +
                              # 4 cartões de peça em degraus de 10, habilidades em cima, recordes embaixo) | REPUTAÇÃO (cartão por ratinho:
                              # corações, bônus, "faltam N", silhueta/estrada, "melhor amigo!") | AJUDAS (grade 4×2,
                              # LIGADA/DESLIGADA ou "na estrada: N") | FROTA (cadeado até a parada; drones + Piloto). open():
                              # a navezinha anda das estrelas vistas até as de agora e as paradas novas festejam (_show_next_news:
                              # ratinho ★1 = MissionIntro, resto = toast + confete). Esc = fecha balão / menu do jogo.
game/hangar/road_view.gd      # RoadView: Estrada das Estrelas (todas as paradas, sem título nem barra, linha que enche, navezinha, "faltam N", rolagem por
                              # setas/roda/arrasto); rebuild(from_stars, recenter), stop_pressed(id), stop_anchor(), celebrate()
game/hangar/ship_view.gd      # ShipView: lander 3x com peças que crescem por degrau (placeholder _draw até a arte da 16.5); highlight(id)
scripts/ui/road_text.gd       # RoadText (puro): nome/figura/frase de cada parada e das peças; STAGE = 10; stage_of()
game/flight/lander.gd         # Lander (CharacterBody2D): física própria; sinais took_off, landed(pad,q,info), crashed(reason,info);
                              # visual = AnimatedSprite2D %Visual (assets/sprites/lander_frames.tres: idle/thrust)
assets/sprites/lander.*       # sprite futurista (pixel-art): lander.png (idle + thrust 4q), .json, lander_frames.tres
art/src/sprites/              # lander.py (fonte do sprite), lander_styles.py (5 estilos propostos), lander_apollo.py
game/terrain/terrain.tscn/.gd # Terrain: Polygon2D (Fill) + BodyBand (UV no mundo) + DepthBand (escurecimento) + BandLit/BandFlat/BandShade (faixas cisalhadas com arte) + Line2D (Surface,
                              # só placeholder) + StaticBody2D com ConcavePolygonShape2D (segmentos); pedregulhos em _draw;
                              # Pads (AnimatedSprite2D por plataforma: idle/target) + Beam/Marker no alvo (setter target_pad_id)
game/background/backdrop.*    # Backdrop (CanvasLayer -1): camadas sky/clouds/planet/far/mid/plain; setup(planeta, ref_y), follow(cam)
                              # (Flight passa cam.y - _bg_ground: altura média do chão perto da câmera, world.json background.ground_follow);
                              # anima quadros (meta anim) e rola nuvens
game/background/war_fx.gd     # WarFx (filho do Backdrop, logo após "mid"): guerra viva no fundo (discos, lasers, traçantes,
                              # abates, clarões); coordenadas da camada mid; contrato meta "war" (opcional por planeta)
scripts/world/cargo_tow.gd    # CargoTow (puro): queijao rebocado — ponto com massa + cabo de comprimento maximo (impulso
                              # dividido pelas massas), quica/rola no chao, damaged se bater acima de break_speed (Lua)
scripts/world/cargo_art.gd    # CargoArt: atlas assets/sprites/cargo.png (+ .json): tex(nome), icon(carga, falhou)
                              # Flight: set_target(d, tier, dir, cargo) + target_position_m (desvia de plataformas antigas);
                              # cargas: _setup_cargo/_tick_cargo/_judge_cargo; resultado ganha dir/cargo/cargo_ok;
                              # RunState: offer_dirs/offer_cargo (sorteador proprio), complete_delivery(..., cargo_ok);
                              # Lander: habilidades stabilizer (acao stabilize) e turbo (acao turbo) via stats
scripts/world/war_math.gd     # WarMath (puro): wrap_dx, screen_x (laço de 640), line_points (Bresenham)
scripts/world/camera_math.gd  # CameraMath.lift: câmera sobe perto do chão (mais céu, menos terreno)
scripts/world/terrain_art.gd  # TerrainArt (puro): PAD_FRAMES/BEAM_FRAMES por tipo; pad_origin/beam_origin pela meia-largura; load_meta, face_of, band (geometria das faixas), band_all (faixa única; UV do mundo ou cisalhado), rock_spots, layer_offset
assets/bg/luna_*              # cena da Lua (pixel-art): camadas + luna_layers.json (contrato de posições/tamanhos)
assets/tiles/luna_ground_*    # crosta do terreno lit/flat/shade (128x26, repetem em x; abaixo transparente)
assets/tiles/luna_body.png    # corpo em blocos de basalto (128x128, UV = mundo) — meta body_texture (opcional)
assets/tiles/luna_depth.png   # escurecimento com a profundidade (128x176 cisalhado) — meta depth_texture/depth_depth
assets/sprites/luna_rocks.png # atlas de pedregulhos (6 x 16x8)
assets/sprites/landing_pad*, target_beam*, target_marker* # plataforma + feixe + marcador ← art/src/sprites/landing_pad.py
assets/sprites/explosion*, landing_dust* # FX de batida e pouso ← art/src/fx/explosion.py (Flight._spawn_fx)
tests/visual/crash_preview.*  # prévia da batida (e da poeira com -- --dust) para gdtool capture
art/src/bg/moon_scene.py      # fonte da cena da Lua (prévia + --export); art/src/terrain/ = versões reprovadas
art/src/bg/anim_util.py       # quadros empilhados (camadas/enfeites animados) + GIF de prévia
art/src/ui/ui_kit.py          # kit de interface (+ pixel_font.py): fonte BMFont, painéis, botões, barras, ícones, cor por mundo
assets/ui/                    # font.fnt/.png, icons.png, bar_*.png fixos; <mundo>/ painéis, botões, barra; ui_kit.json
autoload/sound.gd             # Sound: ui(nome)/sfx(nome) one-shots (8 vozes); music("title"|"flight"|"") e ambience(mundo|"")
                              # com crossfade de 1,2 s (a mesma faixa não reinicia; um tween por par); jingle("milestone"|
                              # "unlock"|"goal") um por vez, música abaixa -9 dB (AudioEffectAmplify no bus Music). Main: título/hangar = "title", voo = "flight",
                              # ambiência = mundo atual. Propulsor e alarme de gás (<15% em voo, baixa após 3 s) no Lander
audio/src/sfx/, audio/src/ui/ # fontes dos sons (sound-design) -> assets/audio/sfx|ui
audio/src/ambience/world_ambience.py # ambiência da Lua -> assets/audio/ambience/<mundo>.wav (loops estéreo 24 s)
audio/src/music/soundtrack.py # música title (D maior 84 BPM) e flight (D lídio 100 BPM) -> assets/audio/music/
audio/src/sfx/progress_sfx.py # gas_alarm (loop) + jingles milestone/unlock/goal -> assets/audio/sfx/
art/src/ui/app_icon.py        # ícone do jogo -> assets/ui/icon.png (32) + icon_512.png (project.godot config/icon, presets)
export_presets.cfg            # macOS (universal, .zip), Windows (x86_64, pck embutido), Linux; exclui tests/ trailer/ docs/
                              # balance/ art/ audio/; inclui *.json de data/ e assets/. Saída em builds/ (ignorado no git)
scripts/ui/ui_kit.gd          # UiKit: theme_for(mundo) (inclui foco, DangerButton, tooltip, scrollbar), icon(nome), icon_label,
                              # color, volume_row(bus), toggle_row (crt_row, shake_row, fullscreen_row), key_row(ação)
                              # (remapear: clica e aperta a tecla; Esc desiste), stat_row, pulse (brilho), crash_text
game/hud/hud.tscn/.gd         # Hud: gás, V.VERT/V.HOR com cor de segurança, altitude, distância ao alvo, %Score = placar de recordes (v15:
                              # _build_score/set_records(início do run)/_update_score; dourado + pulso + "NOVO RECORDE!"), mensagem;
                              # seta do alvo vira para o lado da plataforma; %Toast central "ENTREGA!"/"BATEU!" (2,5 s)
autoload/telemetry.gd         # Telemetry (só no build de depuração/editor, ou com --telemetry; > 5 MB vira _old):
                              # user://telemetry/deliveries.csv (formato da economy-balance + coluna pilot
                              # human/demo + tier; demo só grava com --telemetry; cabeçalho antigo → deliveries_old[N].csv,
                              # nunca sobrescreve)
autoload/save_manager.gd      # SaveManager: pasta própria (project.godot custom_user_dir_name = IncrementalLander; na 1ª vez
                              # copia saves/opções/telemetria de Godot/app_userdata/Incremental Lander, sem sobrescrever);
                              # save ILEGÍVEL (danificado/versão futura) nunca é sobrescrito: guardado como
                              # save.unreadable[N].json antes do próximo save + load_warning mostrado no menu inicial;
                              # autosave também a cada entrega paga. SLOTS=5 jogos salvos (jogo 1 = user://save.json, N = save_N.json; tmp→rename,
                              # .bak), autosave do jogo em uso (slot) em eventos + ao fechar; user://settings.json = volumes
                              # + last_slot (globais); slot_summary(n), load_slot(n), new_game(n), delete_slot(n); desligado em --demo/--dev_*/--no_save e em cenas res://tests/visual/;
                              # new_game(); set_dir() p/ testes
scripts/save/save_data.gd     # SaveData (puro): serialize/deserialize com validação, migrações (v1→v2 2026-10-06: sai prestígio/mundos; v2→v3 2026-10-07: estrelas viram total = estrelas + 3 × nós; road_reached/road_seen/rep_points; recorde best_perfect; v3→v4 2026-10-07: recordes por run — run_money/run_deliveries/run_distance/run_perfect/best_delivery; v4→v5: recordes por mundo {planeta: {id: valor}} e current_planet guardado se liberado), ids removidos ignorados
tests/unit/world/             # test_lander_physics, test_landing_rules, test_terrain_gen (cristas, tipos de plataforma)
scripts/world/gifts.gd        # Gifts (puro, v10): place(pad_a, pad_b, ridge) ponto mais alto do meio do salto (world.json gifts.span);
                              # touches(pos, vel, gift) perto e devagar; rng_for(seed, pad) sorteador próprio. Flight: _setup_gift
                              # (EconMath.draw_gift; não em resgate) / _spawn_gift(kind) / _tick_gift (galão: gás na hora; presente:
                              # gift_pay no resultado → RunState.complete_delivery(..., gift_pay)); telemetria coluna gift
tests/integration/gift_flow   # galão enche o tanque 1x, rápido não pega, presente vai no resultado; tests/visual/gift_preview
scripts/world/assists.gd      # Assists (puro, v9): arc(pad_a, pad_b, n) arco ideal de 45° (world.json assists.arc_k);
                              # fall(pos, vel, params, ridge) queda sem motor; verdict() good/hard/miss; arrow_tier(); gas_left_at_arrival()
game/flight/assist_view.gd    # AssistView (Node2D no Flight, atrás do lander): Setinha/colorida, Rastro/Rota, Sombra, Nivelador, Onde vou
                              # cair — cada uma só se GameState.assist_on(id) (comprada e não desligada; nav_arrow grátis)
game/hangar/assist_icon.gd    # AssistIcon: figurinha 48x24 de cada ajuda (placeholder _draw, Resurrect 64) nos cartões da aba AJUDAS
                              # Hangar._add_assists: galhos da spec (upgrades 'assist'), cartões ligados por setas, LIGADA/DESLIGADA
                              # Hud._update_need_mark: marquinha "Dá pra chegar?" na barra de gás
tests/integration/edge_flow   # o mapa não acaba: 18 km à direita e 10 km à esquerda sempre com chão; partida igual
tests/unit/world/test_assists.gd # arco, queda prevista/veredito, cor da setinha, gás na chegada, árvore persistente
tests/tools/dump_terrain.gd   # imprime o contorno do terreno em JSON (TERRAIN_JSON=) para plotar fora do Godot
tests/unit/run/               # test_run_state, test_purchases, test_fleet, test_missions (árvore, sorteio, Dupla)
tests/visual/                 # cenas de prévia visual (hangar_preview --late/--tab=1/--assists/--keys,
                              # summary_preview --crash, title_preview --progress/--options/--confirm) para gdtool capture
tests/unit/save/              # test_save_data
tests/integration/release_fixes # correções da auditoria de lançamento: DECOLAR na Lua, hangar esconde ofertas, E 2x, Espaço fora do ui_accept, relógio
                              # do run parado na pausa, save ilegível guardado + aviso, recordes, música/ambiência/alarme/jingle
tests/integration/            # save_roundtrip.tscn (salva/carrega/backup + jogos salvos numa pasta própria), slots_flow.tscn
                              # (Main + menu: novo jogo no espaço 2, trocar de jogo) — rodados por gdtool test
```
Placeholders desenhados com `_draw()`/Polygon2D em cores da Resurrect 64 — exceto o lander e a cena da Lua (arte final).

## Pastas ainda não criadas (padrão godot-dev)
```
assets/ (skills pixel-art / sound-design)             # Fases 8–9
```

## Autoloads
- **Implementados** (ordem no project.godot): `Events`, `GameState`, `Telemetry`, `SaveManager`, `Sound`, `Crt`.
- `GameState.settings`: volumes, `crt`, `shake` (tremor), `fullscreen` (só aplica quando muda; F11/Alt+Enter na Main),
  `keys` (teclas remapeadas das ações `world.json > remappable`; `remap_key` tira a tecla de outras ações). `records`
  (recordes pessoais do pós-jogo) vai no save. `apply_settings()` registra o input (WorldConfig.register_input tira
  Espaço de ui_accept/ui_select; controle: world.json > joypad).

Planejados (`godot-dev`):
- `Events` — event bus (sinais globais, sem estado).
- `GameState` — recursos, níveis de upgrades, loja, planetas, prestígio; usa `EconMath`.
- `SaveManager` — salvar/carregar com versão da spec (`meta.version`) e migração.
- `Telemetry` — grava CSV de entregas/runs para calibrar o modelo (`economy-balance`).
- (o papel do `AudioManager` ficou com `Sound` + `Lander`).

## Regras de fluxo (auditoria de lançamento, 2026-10-03)
- `Main._abandon_run()`: R, voltar ao título ou trocar de jogo no meio do run fecham a conta como um fim normal
  (frota pelo tempo voado, conta como run) — sem entregas, não conta. O relógio do run (`_run_time`) só anda com o jogo
  despausado. `_open_hangar()` esconde HUD/ofertas/resumo (nada atrás do hangar recebe teclas).
- `Purchases.can_launch(mundo, stats)`: motor vence a gravidade e o tanque cheio alcança a entrega mais curta. O hangar
  desliga DECOLAR (com o motivo) se o mundo atual não passa; o recomeço com Cartas de navegação volta para
  `best_launchable`; run sem nenhuma entrega alcançável termina como "sem_alcance".
- `TerrainGen`: busca binária na altura e laços só na faixa afetada (mapas de centenas de km); `Terrain` desenha só as
  pedras na tela; a extensão de borda cresce com o mapa (¼ da largura).

## Contratos entre sistemas
- **Economia**: todo número vem de `data/economy.json` via `EconMath` — nada de constantes de economia no código.
- **Física ↔ economia**: stats de `EconMath.ship_stats()` viram parâmetros físicos (Fase 3.2). A física real
  deve seguir o modelo do `run-model.md` ou o modelo deve ser recalibrado (Fase 10).
- **Arte/som**: só assets gerados pelas skills; scripts-fonte em `art/src/` e `audio/src/`.

## Verificação (skill godot-dev)
```
G=.claude/skills/godot-dev/scripts/gdtool.py
python3 $G check      # sintaxe/tipos de todos os .gd
python3 $G test       # tests/unit + paridade da economia
python3 $G run res://game/main.tscn --frames 600 -- --demo
python3 $G capture res://game/main.tscn --frames 240 --every 40 -- --demo   # folha em .godot/captures/
```
Configurações do projeto já aplicadas: 640×360 escala inteira, Nearest, snap de pixel, interpolação de física
2D, aviso de declaração sem tipo, buses de áudio.

## Missões (v12, 2026-10-06)
```
data/economy.json contracts.missions # tipos/estrelas/mult, nodes (árvore), stars, new_boost, double
data/world.json missions             # física por estrela: soft.vy_frac, fast (prazo x factor), tow.levels, passenger
scripts/economy/econ_math.gd         # mission_kinds/kind/level/mult/thrust_div/dv_mult/leg2/has, mission_node_ok,
                                     # missions_unlocked, mission_node_cost, draw_mission(planeta, liberadas, boost, stats, rng)
scripts/run/run_state.gd             # offer_mission[], offer_slot[] (simple0..2 / tipo), set_choice(i, plataforma, estrela),
                                     # stars_for(i), taken_mission, stars, mission_gas(m, d), leg2_m(m, d)
game/flight/flight.gd                # mission/failed/taxi_stage; set_target(d, tier, dir, missao, stage, falhas);
                                     # _setup_mission/_tick_mission/_judge_mission; result: mission, failed, leg (1 = busca do taxi)
game/flight/lander.gd                # load_div (Pesada) divide o empuxo (e o do piloto do demo)
game/main.gd                         # _on_offer_chosen: _fade (ColorRect) escurece -> begin_mission(hash([_run_seed, entregas]))
                                     # taxi: leg 1 -> set_target(2o trecho, -dir, stage 2); estrelas por entrega; --dev_mission=
                                     # kind:estrela|double:a+b, --dev_missions=ids, --dev_stars=N
```
game/run/offer_panel.gd: cartão com seletores (_fill_choices/_choose/_remember; OfferPanel.last_choice por tipo; _input cima/baixo); RunState.pay_for_tier = prêmio de cada botão

## Mundos paralelos (v16, Fase 18)
- `GameState.worlds()` = Lua + mundos das paradas `world_<id>` alcançadas; `select_world(id)`; `records` = {planeta: {id: valor}},
  `world_records(planeta="")`, `note_record` grava no mundo atual.
- `game/worlds/world_map.gd` (`WorldMap`, montado em código): `open()`, sinais `fly_requested(id)` / `closed`;
  `planet_texture(id, locked)` desenha o planetinha 24 px com `world.json > terrain.planets.<id>.map` (placeholder até a arte).
- `Main._on_hangar_launch`: 2+ mundos → mapa; `_on_world_chosen` → `select_world` + run. `_end_run` paga
  `EconMath.record_bonus(dinheiro do run, recorde do mundo no início)`; `summary.record_bonus` aparece no resumo.
- Mundo sem arte: backdrop vazio, céu = `terrain.planets.<id>.sky`, chão placeholder `fill/surface`, tema da Lua.

