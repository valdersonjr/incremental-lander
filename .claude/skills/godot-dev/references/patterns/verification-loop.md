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

## Fontes
- https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html — flags de linha de comando
- `godot --help` (4.7.2) — confirmação local de `--write-movie`, `--quit-after`, `--fixed-fps`, `--check-only`
