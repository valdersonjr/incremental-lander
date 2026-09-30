# Testes e verificação sem editor

Fontes: docs Godot (Command line tutorial: `--headless`, `--script`, `--check-only`, `--quit-after`,
`--write-movie`, `--fixed-fps`), GUT/GdUnit4 (alternativas avaliadas).

## Decisão: executor mínimo próprio (sem addon)
`tests/test_case.gd` (`class_name TestCase`) + `tests/run_tests.gd` (roda headless, código de saída 1 se falhar).
GUT/GdUnit4 são completos (mocks, relatórios JUnit), mas exigem addon e cuidados em headless (`-gexit` etc.);
o projeto não precisa disso agora. Reavaliar se surgirem testes com simulação de input complexos.

## Tipos de verificação
| O quê | Como | Quando |
|---|---|---|
| Sintaxe/tipos | `gdtool.py check` | sempre |
| Lógica pura (qualidade de pouso, gás, geração de terreno por seed, GameState) | `tests/unit/test_*.gd` com `assert_*` | toda lógica nova |
| Economia GDScript = Python | `tests/test_econ_parity.py` (roda em `gdtool.py test`) | mudou spec/fórmula |
| Cena roda sem erro | `gdtool.py run res://... --frames N [-- --demo]` | toda cena nova/alterada |
| Visual/comportamento | `gdtool.py capture ...` + Read na folha | toda mudança visível |

## Escrevendo testes
```gdscript
extends TestCase

func test_pouso_perfeito_tem_qualidade_1() -> void:
	var q := LandingRules.quality(0.0, 0.0, 0.0, 0.0)
	assert_almost(q, 1.0)
```
- Arquivo `tests/unit/<area>/test_<assunto>.gd`; métodos `test_<comportamento>()` em português descritivo.
- Testar funções puras/estáticas; para nós, instanciar a cena no teste só se necessário (`load(...).instantiate()`
  e `tree.root.add_child(...)`; lembrar de liberar).

## Modo demo e captura
- Cenas de gameplay leem `OS.get_cmdline_user_args()`; `--demo` ativa piloto automático simples e
  `--seed=N` fixa o terreno. Assim `run`/`capture` verificam o voo sem teclado.
- `capture` grava frames com tempo fixo (reprodutível), monta `.godot/captures/<cena>_sheet.png`.
  Abrir com Read e descrever: posições, HUD legível, pixels nítidos (sem borrão), cores da paleta.

## Cenas de prévia visual (`tests/visual/*_preview.tscn`)
Telas que só aparecem tarde no jogo (final, prestígio avançado) não devem ser verificadas gravando dezenas de
milhares de frames. Crie uma cena mínima que instancia só a tela com dados de exemplo e capture ~10 frames:
`gdtool.py capture res://tests/visual/ending_preview.tscn --frames 10 --every 10 --cols 1`.

## Testes de integração (`tests/integration/*.tscn`)
Para o que depende de autoloads/arquivos (save, fluxo entre telas): uma cena que monta o cenário, verifica e
imprime `<NOME>_TEST OK` (ou `FALHOU ...`) e chama `get_tree().quit()`. `gdtool.py test` roda todas com
`--no_save`. Nunca usar o save real: `SaveManager.set_dir("user://itest")`.
