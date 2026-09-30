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

## Jogo (Fases 1–7 — voo, run, hangar, planetas, prestígio, frota, Expedição, final, save/opções)
```
data/world.json               # escala (px_per_m=1), time_scale=4,5, rotate_speed=4, drag_scale, tolerâncias de pouso,
                              # relevo + cores provisórias (sky/fill/surface) por planeta, teclas (inclui end_run/confirm), demo
scripts/world/
  world_config.gd             # WorldConfig: lê world.json, m↔px, registra input (InputMap) a partir do JSON
  lander_physics.gd           # LanderPhysics.step(): gravidade + propulsor + arrasto; gás = Δv/eficiência (puro)
  landing_rules.gd            # LandingRules: tolerâncias (× gear^0.5), crash_reason(), quality() 0..1 (puro)
  terrain_gen.gd              # TerrainGen.generate(seed, planeta, distâncias): relevo + plataformas planas (puro)
  autopilot.gd                # Autopilot (--demo): decolagem → arco balístico (mira acima do alvo) → frenagem/pouso;
                              # motor por sigma-delta (fração exata de empuxo) — voa na Lua, Ares e Kronos
game/main.tscn/.gd            # Main → World + GUI; ORQUESTRA O RUN: ofertas → set_target → entrega → GameState.add_rewards
                              # → ofertas … → resumo → HANGAR → novo run. Args: --demo --seed=N --planet=id --hangar_wait=s.
                              # Demo libera planetas, compra o upgrade mais barato, vai ao melhor planeta voável; "HANGAR {json}".
                              # Args de dev: --dev_levels=id:n,... --dev_credits=N --dev_ore=N --dev_shop=id:n,...
                              # --dev_unlock=a,b --planet=id (validado). Imprime também GOAL_REACHED/PRESTIGE.
                              # Imprime "DELIVERY_RESULT {json}" e "RUN_SUMMARY {json}" (verificação automática)
game/flight/flight.tscn/.gd   # Flight: Terrain + Lander + Camera; start(planeta, seed, stats, demo); set_target(distância)
                              # cria a próxima plataforma a partir da atual e estende o terreno;
                              # sinais delivery_finished(result) (→ Telemetry) e stranded (pousou sem gás fora do alvo)
scripts/run/run_state.gd      # RunState (puro): ofertas (log-uniformes, regeneram), take_offer, complete_delivery
                              # (EconMath.contract_pay), crash, can_continue, best_offer (demo), summary
game/run/offer_panel.*        # OfferPanel: teclas 1–8 escolhem, E encerra; mostra distância, gás mínimo, pagamento
game/run/run_summary.*        # RunSummary: fim do run (motivo, entregas, qualidade média, ganhos); Enter = novo run
autoload/events.gd            # Events: resources_changed, run_started, run_finished, upgrade_bought, planet_unlocked, prestiged, goal_reached
autoload/game_state.gd        # GameState: recursos, níveis, loja, prestígio (cycle_earned, prestige_pending,
                              # begin_prestige/finish_prestige, buy_shop_item), planetas liberados, income_history,
                              # settle_run() (paga a frota ao fim do run), check_goal()/reached_goal; ship_stats(),
                              # buy_upgrade(), buy_upgrade_max(), upgrade_rows() (via Purchases/EconMath)
scripts/economy/fleet.gd      # Fleet (puro): average_income (últimos 5 runs), payout (EconMath.fleet_income_per_s)
scripts/economy/prestige.gd   # Prestige (puro): gain, can_prestige, collect → (loja) → reset, shop_rows, buy_shop
scripts/economy/purchases.gd  # Purchases (puro): can_afford, buy, buy_max, upgrade_rows, max_reach_m,
                              # can_fly (motor vence a gravidade), unlock_planet, planet_rows
game/ending/ending.*          # Ending: "VOCÊ CHEGOU A TITAN!" + resumo; Continuar jogando (Events.goal_reached)
game/hangar/hangar.*          # Hangar: EXPEDIÇÃO A TITAN (barra segmentada [###-----] + próxima etapa) + PLANETAS (liberar / voar em / motor fraco) + PRESTÍGIO (recomeçar com confirmação;
                              # modo 'recomeço em andamento' = só loja + CONCLUIR) + LOJA DA POEIRA + UPGRADES; DECOLAR
game/flight/lander.gd         # Lander (CharacterBody2D): física própria; sinais took_off, landed(pad,q,info), crashed(reason,info);
                              # visual = AnimatedSprite2D %Visual (assets/sprites/lander_frames.tres: idle/thrust)
assets/sprites/lander.*       # sprite futurista (pixel-art): lander.png (idle + thrust 4q), .json, lander_frames.tres
art/src/sprites/              # lander.py (fonte do sprite), lander_styles.py (5 estilos propostos), lander_apollo.py
game/terrain/terrain.tscn/.gd # Terrain: Polygon2D (Fill) + Line2D (Surface) + StaticBody2D com ConcavePolygonShape2D (segmentos); plataformas em _draw
game/hud/hud.tscn/.gd         # Hud: gás, V.VERT/V.HOR com cor de segurança, altitude, distância ao alvo, créditos, ENTREGA n/6, mensagem
autoload/telemetry.gd         # Telemetry: user://telemetry/deliveries.csv (formato da economy-balance + coluna pilot
                              # human/demo; demo só grava com --telemetry; cabeçalho antigo → deliveries_old.csv)
autoload/save_manager.gd      # SaveManager: user://save.json (JSON versionado, tmp→rename, save.bak), autosave em
                              # eventos + ao fechar; desligado em --demo/--dev_*/--no_save; new_game(); set_dir() p/ testes
scripts/save/save_data.gd     # SaveData (puro): serialize/deserialize com validação, migrações, ids removidos ignorados
tests/unit/world/             # test_lander_physics, test_landing_rules, test_terrain_gen
tests/unit/run/               # test_run_state, test_purchases, test_prestige, test_fleet
tests/visual/                 # cenas de prévia visual (ending_preview, hangar_preview) para gdtool capture
tests/unit/save/              # test_save_data
tests/integration/            # save_roundtrip.tscn (salva/carrega/backup numa pasta própria) — rodado por gdtool test
```
Placeholders desenhados com `_draw()`/Polygon2D em cores da Resurrect 64 — exceto o lander (sprite final).

## Pastas ainda não criadas (padrão godot-dev)
```
game/hangar/, game/prestige/ ...                      # Fases 3–6
assets/ (skills pixel-art / sound-design)             # Fases 8–9
```

## Autoloads
- **Implementados** (ordem no project.godot): `Events`, `GameState`, `Telemetry`, `SaveManager`.

Planejados (`godot-dev`):
- `Events` — event bus (sinais globais, sem estado).
- `GameState` — recursos, níveis de upgrades, loja, planetas, prestígio; usa `EconMath`.
- `SaveManager` — salvar/carregar com versão da spec (`meta.version`) e migração.
- `Telemetry` — grava CSV de entregas/runs para calibrar o modelo (`economy-balance`).
- `AudioManager` — players por bus; propulsor controlado pela potência (ver `sound-design/references/godot-audio.md`).

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
