# Arquitetura

Fontes: docs.godotengine.org → Best practices / Scene organization; GDQuest (signals good practices,
event bus); fórum Godot ("signal up, call down").

## Pastas (organizadas por feature: cena + script juntos)
```
autoload/            # singletons globais (poucos!): events.gd, game_state.gd, save_manager.gd, telemetry.gd
game/
  main.tscn/.gd      # entrada: Main → World + GUI; troca telas
  flight/            # cena de voo: flight.tscn/.gd, lander/, camera
  terrain/           # geração do terreno em polígono, plataformas
  hud/               # HUD do voo
  hangar/            # tela de upgrades entre runs
  prestige/          # tela de prestígio + loja da Poeira
  ...                # uma pasta por feature nova
scripts/             # lógica compartilhada sem cena: economy/econ_math.gd, util/
data/                # economy.json (economy-balance), world.json (godot-dev: escala, tolerâncias, input)
assets/              # SÓ exports das skills pixel-art / sound-design
tests/               # test_case.gd, run_tests.gd, unit/test_*.gd, paridade da economia
```
Arquivos em `snake_case`; nós em `PascalCase`; uma cena por arquivo; script ao lado da cena com o mesmo nome.

## Árvore principal
```
Main (Node, game/main.gd)            # controla fluxo: hangar ↔ voo ↔ prestígio
├── World (Node2D)                   # conteúdo trocável (cena de voo instanciada aqui)
└── GUI (CanvasLayer)                # HUD, hangar, telas, popups (sobrevive à troca do World)
```
Trocar de "nível"/tela = trocar os filhos de World/GUI; Main nunca é destruído.

## Comunicação
- **Dados descem, eventos sobem**: pai chama métodos/props dos filhos; filho emite **sinal no passado**
  (`landed`, `crashed`, `gas_depleted`) e o pai reage. Filho não conhece o pai.
- **Injeção de dependência** (ordem de preferência, docs oficiais): sinais → `Callable` atribuída pelo pai →
  referência atribuída pelo pai (`$Lander.terrain = $Terrain`) → `NodePath` exportado. Nada de caminhos
  absolutos (`get_node("/root/...")`).
- **Event bus** (`autoload/events.gd`): só para eventos entre ramos distantes (ex.: `run_finished`,
  `currency_changed`, `planet_unlocked`). Sinais do bus carregam **dados** (ids, números), não nós.
  O bus não guarda estado. Evitar conectar duas vezes (checar `is_connected` ou conectar no `_ready`).
- Use `%NomeUnico` (unique_name_in_owner) para nós internos da própria cena em vez de caminhos longos.

## Autoloads (só estes, salvo decisão registrada)
| Autoload | Papel | Regra |
|---|---|---|
| `Events` | sinais globais | sem estado |
| `GameState` | recursos, níveis, loja, planetas, prestígio, etapas; métodos `buy_upgrade()`, `can_afford()`... | toda regra numérica via `EconMath`; emite `Events.*_changed` |
| `SaveManager` | salvar/carregar `GameState` | ver `save-telemetry.md` |
| `Telemetry` | CSV de entregas/runs | ver `save-telemetry.md` |
| `AudioManager` (depois) | players por bus | ver `sound-design/references/godot-audio.md` |
`EconMath` é `class_name` estático (não autoload): `EconMath.load_spec()` no `GameState._ready()`.

## Estado vs. apresentação
- `GameState` é a verdade do progresso; telas leem dele e chamam seus métodos; nunca alteram dicionários
  diretamente.
- Cena de voo recebe os stats prontos (`EconMath.ship_stats(...)`) ao começar o run e devolve o resultado
  por sinal (`run_finished(result: Dictionary)`); não acessa `GameState` no meio do voo.

## Placeholders (antes da arte)
Sem arquivos de imagem: `_draw()` (formas), `Polygon2D`, `Line2D`, `ColorRect`, com cores da Resurrect 64
(ex.: `Color("#9babb2")` steel, `Color("#2e222f")` ink, `Color("#f79617")` amber). Trocar pelos assets da
`pixel-art` na Fase 8 sem mudar a lógica (sprite atrás de um nó `Visual`).

## Números
Tudo que é economia → `data/economy.json` via `EconMath`. Tudo que é mundo/sensação (escala px↔m, tolerâncias
de pouso, velocidade de rotação, câmera) → `data/world.json` lido por um `WorldConfig` estático. Nada mágico
espalhado em scripts (constantes locais só para detalhes visuais).
