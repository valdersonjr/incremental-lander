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

## Pastas (planejadas pela skill godot-dev — ainda não criadas)
```
autoload/                        # events.gd, game_state.gd, save_manager.gd, telemetry.gd
game/<feature>/                  # cena + script juntos: main, flight, terrain, hud, hangar, prestige...
data/world.json                  # escala px↔m, tolerâncias de pouso, relevo por planeta (não economia)
assets/sprites|tiles|fx|ui|bg/   # exports da skill pixel-art
assets/audio/sfx|ui|ambience|music/  # exports da skill sound-design
```

## Autoloads (definidos pela `godot-dev`, a implementar)
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
