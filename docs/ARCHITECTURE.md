# Arquitetura do projeto

> Estrutura de pastas e responsabilidades. Padrões de **código Godot** (cenas, autoloads, sinais, save,
> testes) serão definidos pela skill `godot-dev` (ROADMAP 0.6) — até lá, o que está marcado
> *(proposta)* é provisório e deve ser revisto pela skill.

## Pastas (existentes)
```
CLAUDE.md                     # entrada de toda sessão: regras + protocolo + mapa
project.godot                 # config Godot (640x360, escala inteira, Nearest, snap)
default_bus_layout.tres       # buses: Master, Music, Ambience, SFX -> Engine, UI (skill sound-design)
data/economy.json             # SPEC ÚNICA da economia (jogo + simulador) — só alterar via economy-balance
scripts/economy/econ_math.gd  # fórmulas em GDScript (class_name EconMath), espelho do econ.py
tests/                        # test_econ_math.gd (Godot headless) + test_econ_parity.py (compara com Python)
docs/                         # GDD, ROADMAP, HANDOFF, DECISIONS, ARCHITECTURE
art/                          # .gdignore — src/**.py (scripts geradores de pixel art), previews/ (ignorado no git)
audio/                        # .gdignore — src/**.py (scripts geradores de som), previews/ (ignorado no git)
balance/                      # .gdignore — sims/ (experimentos), reports/, telemetry/, CHANGELOG.md
.claude/skills/               # pixel-art, sound-design, economy-balance (e godot-dev, a criar)
```

## Pastas (planejadas — *proposta*)
```
assets/sprites|tiles|fx|ui|bg/   # exports da skill pixel-art (PNG + .tres)
assets/audio/sfx|ui|ambience|music/  # exports da skill sound-design (WAV + .tres)
scenes/                          # cenas .tscn (main, flight, hangar, ui...)
scripts/                         # scripts .gd por domínio (economy/, flight/, ui/, state/...)
```

## Autoloads (*proposta*, a confirmar pela `godot-dev`)
- `GameState` — recursos, níveis de upgrades, loja, planetas, prestígio; usa `EconMath`.
- `SaveManager` — salvar/carregar com versão da spec (`meta.version`) e migração.
- `Telemetry` — grava CSV de entregas/runs para calibrar o modelo (`economy-balance`).
- `AudioManager` — players por bus; propulsor controlado pela potência (ver `sound-design/references/godot-audio.md`).

## Contratos entre sistemas
- **Economia**: todo número vem de `data/economy.json` via `EconMath` — nada de constantes de economia no código.
- **Física ↔ economia**: stats de `EconMath.ship_stats()` viram parâmetros físicos (Fase 3.2). A física real
  deve seguir o modelo do `run-model.md` ou o modelo deve ser recalibrado (Fase 10).
- **Arte/som**: só assets gerados pelas skills; scripts-fonte em `art/src/` e `audio/src/`.

## Testes
- `python3 tests/test_econ_parity.py` — obrigatório após qualquer mudança em `econ.py`, `econ_math.gd` ou na spec.
- Godot headless: `godot --headless --path . --script res://tests/<teste>.gd`.
