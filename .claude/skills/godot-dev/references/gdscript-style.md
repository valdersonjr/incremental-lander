# Estilo GDScript (oficial Godot 4 + decisões do projeto)

Fonte: docs.godotengine.org → GDScript style guide (4.x).

## Ordem dentro do arquivo
1. `@tool`, `@icon`, `@static_unload` · 2. `class_name` · 3. `extends` · 4. docstring `##`
5. `signal`s · 6. `enum`s · 7. `const` · 8. `static var` · 9. `@export var` · 10. `var` · 11. `@onready var`
12. `_static_init()` · 13. outros estáticos · 14. virtuais: `_init`, `_enter_tree`, `_ready`, `_process`,
`_physics_process`, demais · 15. métodos públicos · 16. privados (`_nome`) · 17. classes internas.

## Nomes
| Tipo | Convenção | Exemplo |
|---|---|---|
| arquivo | snake_case | `lander.gd`, `flight.tscn` |
| class_name / nó | PascalCase | `class_name Lander`, nó `Lander` |
| função / variável | snake_case | `apply_thrust()`, `gas_left` |
| privado | prefixo `_` | `_integrate()`, `var _velocity` |
| sinal | snake_case, **passado** | `landed`, `gas_depleted`, `upgrade_bought` |
| constante / membro de enum | CONSTANT_CASE | `const MAX_TILT := 0.35`, `enum State {FLYING, LANDED}` |
| enum | PascalCase | `enum State` |
Identificadores em **inglês** (combina com a API); comentários e docstrings em **português**.

## Tipagem (obrigatória)
- Declarar tipos: `var gas: float = 0.0`, `func apply(amount: float) -> void:`; `:=` quando o tipo é óbvio.
- `@onready var hud: Hud = %Hud` ou `... as Hud`. Arrays/dicionários tipados quando possível (`Array[Vector2]`).
- Sem `Variant` implícito em código de jogo. `project.godot` deve ter
  `debug/gdscript/warnings/untyped_declaration=1` (aviso) — tratar todo aviso novo como bug.

## Formatação
Tabs; linhas < 100 colunas; um espaço em volta de operadores e após vírgulas; aspas duplas; floats com
zero (`0.5`, `13.0`); `and`/`or`/`not`; uma instrução por linha; comentário com espaço após `#`.

## Boas práticas do projeto
- Funções curtas; lógica pura em funções estáticas testáveis (ex.: `LandingRules.quality(...)`).
- `_physics_process` para física/movimento; `_process` para visual/UI.
- Nada de `get_node("../../..")`; ver `architecture.md`.
- Docstring `##` em toda classe e método público (vira documentação via `--gdscript-docs`).
- Erros de dados (spec faltando campo) → `push_error()` com mensagem clara + valor seguro.
