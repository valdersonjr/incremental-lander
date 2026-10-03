# Save/load e telemetria

Fontes: docs Godot (Saving games, FileAccess, user://), práticas de versionamento/migração de saves.

## Save
- Arquivo `user://save.json` (JSON legível; fácil de migrar e depurar). `SaveManager` (autoload).
- Conteúdo: `save_version` (esquema do save), `spec_version` (`meta.version` da economia), recursos, níveis
  de upgrades, loja, planetas, pontos de prestígio, etapas da Expedição, estatísticas. **Nunca salvar valores
  derivados** (stats, custos) — recalcular com `EconMath` ao carregar.
- **Escrita atômica**: gravar `save.json.tmp`, depois renomear sobre `save.json`; manter `save.bak` anterior.
- **Migração**: `const MIGRATIONS := {1: _migrate_1_to_2, ...}` aplicadas em sequência até a versão atual;
  ids removidos da spec → reembolsar/ignorar com `push_warning`.
- Validar tipos ao carregar (dados de fora são não confiáveis); arquivo corrompido → usar `save.bak`.
- Autosave: fim de run, compra, prestígio, sair do jogo (`NOTIFICATION_WM_CLOSE_REQUEST`).
- **Vários jogos salvos** (feito 2026-10-02): `SaveManager.SLOTS`; caminho por espaço (`slot_files(n)`; o jogo 1 mantém
  o nome antigo para não migrar); a tela de seleção lê só o resumo (`slot_summary` → `SaveData.summary`, puro e
  testado) sem trocar o jogo em uso; **opções fora do save** (`settings.json`, com `last_slot`) para não mudarem ao
  trocar de jogo. UX: apagar exige 2 cliques + Esc cancela; espaço ocupado nunca é sobrescrito direto (apagar antes).
  Fontes: [GDQuest — Save and Load cheat sheet](https://www.gdquest.com/library/cheatsheet_save_systems/),
  [Bugnet — game save best practices Godot](https://bugnet.io/blog/game-save-best-practices-godot),
  [Godot forum — dynamic save slot system](https://forum.godotengine.org/t/better-way-to-make-a-dynamic-save-slot-system/142808).
- Testes nunca usam o `user://` real: `SaveManager.set_dir("user://itest...")`; prévias `tests/visual/` têm o save desligado.

## Telemetria (calibra a economia — `economy-balance` Etapa 10)
- `Telemetry` (autoload) grava em `user://telemetry/deliveries.csv` e `runs.csv` com `FileAccess`
  (`store_csv_line`). Cabeçalhos:
  - entregas: `planet,distance,thrust,efficiency,tank,gas_used,hop_time_s,quality,crashed`
  - runs: `run_id,planet,duration_s,deliveries,earned,crashed,gas_left_pct`
- `distance` e `gas_used` nas **unidades do modelo** (converter px → m com `WorldConfig.PX_PER_M`).
- Ativa por padrão durante o desenvolvimento; copiar para `balance/telemetry/` e rodar
  `econ.calibrate(E, "balance/telemetry/deliveries.csv", "engaged")`.
- Caminho real de `user://` no Mac: `~/Library/Application Support/IncrementalLander/` (desde 2026-10-03:
  `config/use_custom_user_dir` — renomear o jogo não muda a pasta; o SaveManager copia uma vez a pasta antiga
  `Godot/app_userdata/Incremental Lander/`, nunca sobrescrevendo). Telemetria só no build de depuração ou com `--telemetry`.
- **Save ilegível nunca é sobrescrito** (2026-10-03): `load_game` marca o espaço; o próximo `save_game` renomeia os
  arquivos para `save.unreadable[N].json/.bak` antes de gravar e o menu inicial mostra `SaveManager.load_warning`.
  Versão de save maior que a do jogo = ilegível (nunca interpretar um save do futuro). Autosave também a cada entrega.
- Validação: `SaveData._num/_flag` — só int/float/texto numérico (NaN/inf = 0); objeto ou lista no lugar de número
  não pode derrubar o carregamento.
