# Ciclo de verificação sem editor

- **Slug**: verification-loop
- **Onde no projeto**: `.claude/skills/godot-dev/scripts/gdtool.py`, `tests/`
- **Problema**: Claude não abre o editor nem joga; precisa saber se o código compila, se a cena roda e o que
  aparece na tela.

## Solução adotada (validada em 2026-09-30, Godot 4.7.2)
- `godot --headless --path . --script res://x.gd --check-only` → imprime `SCRIPT ERROR: Parse Error: ...`
  com arquivo:linha (tipagem incorreta e identificadores inexistentes detectados). `check` roda em paralelo
  e antes faz `--import` (atualiza `class_name` globais).
- `godot --headless --path . res://cena.tscn --quit-after N` → roda N frames sem janela.
- `godot --path . --write-movie /tmp/f.png --fixed-fps 60 --quit-after N --resolution 640x360 res://cena.tscn`
  → grava `f00000000.png`… (+ `f.wav`); abre janela ~1 s. Frames saem em 640×360 exatos.
- `godot --headless --doctool <dir>` → XML da API inteira da versão instalada (1.076 classes, ~1 s);
  `gdtool.py api` consulta com cache em `~/.cache/godot-api/<versão>`.
- Executor de testes próprio: saída `ok`/`FALHOU` por teste, código de saída 1 quando falha.

## Armadilhas
- `move_and_collide` não aparece em `CharacterBody2D`: está na base `PhysicsBody2D` (o `api` avisa a base).
- Em pipes de shell o código de saída é o do último comando — use o código do `gdtool.py` diretamente.
- Scripts novos com `class_name` só são reconhecidos após `--import` (o `check`/`test` já fazem).
- O Godot 4.4+ cria `<script>.gd.uid` para todo script: ao **apagar** um script (inclusive de teste/sondagem),
  apague também o `.uid`, senão ele fica órfão e acaba commitado. Conferir `git status` antes do commit.

- `--check-only` roda isolado e **não carrega autoloads**: `Identifier not found: Telemetry` (e erros em
  cascata "Failed to compile depended scripts") são falsos positivos. O `check` ignora nomes do `[autoload]`
  do project.godot; a prova final é o `run` (execução real).

- Headless **sem `--fixed-fps`** processa frames mais rápido que a física: `--quit-after 2400` cobriu só
  ~32 s de jogo em vez de 40 s (o demo "não pousava"). `gdtool run` usa `--fixed-fps 60` (determinístico).
- `move_and_collide` com `recovery_as_collision=false` (padrão) não reporta contato quando o corpo já está
  dentro da margem (descendo devagar encostado) — o lander usa `true` para detectar pousos lentos.

- Um teste que **aborta por erro de script** (ex.: dependência que não compila) não chama `assert` e o executor
  imprime "ok". O `gdtool test` marca como `FALHOU (erro de script)` todo teste precedido de SCRIPT ERROR e
  sai com código 1. Nunca confiar só na lista de "ok": olhar o resumo e o código de saída.
- `Array.map()` devolve `Array` sem tipo: `var x := arr.map(...)` não compila ("Cannot infer the type");
  declare `var x: Array = arr.map(...)`.

- **Captura congelada no macOS**: com a janela do Godot coberta/em segundo plano a gravação às vezes repete o
  mesmo quadro por centenas de frames (o jogo em si estava certo — o run sem janela era determinístico e entregava).
  `capture` agora usa `--always-on-top` e acusa `AVISO ... congelou` (código 1) se houver > 3 s de quadros
  idênticos. Com o aviso, refaça — nunca tire conclusões de uma folha congelada.

## Fontes
- https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html — flags de linha de comando
- `godot --help` (4.7.2) — confirmação local de `--write-movie`, `--quit-after`, `--fixed-fps`, `--check-only`

## Áudio em headless (2026-10-01)
- `--headless` usa o driver de áudio Dummy: sons tocando quando o `--quit-after` encerra deixam playbacks vivos →
  `ERROR: N resources still in use at exit`. Com driver real (janela/captura) **não** acontece. O `gdtool` trata isso
  como aviso explicado (`HEADLESS_AUDIO_EXIT`). Vazamento de verdade: conferir com `--verbose` ou rodando em janela.
- Caches estáticos (`static var`) que guardam recursos também acusam isso: limpar na saída (`UiKit.clear_cache()`
  no `_exit_tree` do autoload `Sound`).

## Prévias nunca tocam o save real (2026-10-02)
Uma prévia de `tests/visual/` que simulava uma compra (`--keys`) disparou o autosave (`Events.upgrade_bought`) e
**sobrescreveu `user://save.json` e o `save.bak`** do jogador com o estado falso da prévia. Correção: o `SaveManager`
se desliga (não carrega nem grava) quando a cena da linha de comando começa com `res://tests/visual/`; a prévia ainda
põe `SaveManager.enabled = false` por garantia. Regra: **toda cena de verificação que mexe no GameState roda com save
desligado** (`--no_save`, caminho `tests/visual/` ou `SaveManager.set_dir()` numa pasta própria nos testes de integração).

## Armadilha (2026-10-03): erro de parse num teste TRAVA o `test`
- Um `SCRIPT ERROR: Parse Error` num arquivo de `tests/unit/` faz o Godot headless parar no depurador esperando
  entrada: `gdtool.py test` fica minutos sem sair (0% de CPU). **Sempre `check` antes de `test`** (a ordem da skill)
  — o `check` mostra o erro com a linha em segundos. Ex.: `var x := float(a) + dx * b` com `dx` vindo de um array
  literal não tipado → "Cannot infer the type"; use `var x: float = ...`.

## Armadilha (2026-10-03): tempo do MODELO × tempo REAL
- A física corre em segundos do modelo (`time_scale` = 4,5× o tempo real). Tudo que o jogador precisa PERCEBER
  (avisos de perigo, ciclos, quedas) deve ser em segundos reais — com tempos do modelo, um aviso de 1,4 s durava
  0,3 s na tela. Forças continuam em m/s² do modelo (a física converte).
- Prévia de algo cíclico: procurar o INÍCIO da fase (sair da fase atual e entrar na pedida), senão pega o fim dela.
