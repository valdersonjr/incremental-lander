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

## Telemetria (calibra a economia — `economy-balance` Etapa 10)
- `Telemetry` (autoload) grava em `user://telemetry/deliveries.csv` e `runs.csv` com `FileAccess`
  (`store_csv_line`). Cabeçalhos:
  - entregas: `planet,distance,thrust,efficiency,tank,gas_used,hop_time_s,quality,crashed`
  - runs: `run_id,planet,duration_s,deliveries,earned,crashed,gas_left_pct`
- `distance` e `gas_used` nas **unidades do modelo** (converter px → m com `WorldConfig.PX_PER_M`).
- Ativa por padrão durante o desenvolvimento; copiar para `balance/telemetry/` e rodar
  `econ.calibrate(E, "balance/telemetry/deliveries.csv", "engaged")`.
- Caminho real de `user://` no Mac: `~/Library/Application Support/Godot/app_userdata/Incremental Lander/`.
