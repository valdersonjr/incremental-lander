# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0 e 1 concluídas.** Protótipo de voo jogável: `godot --path .` (ou F5 no editor).
  Controles: W/↑/Espaço propulsor, A/D/←/→ girar, R reinicia. `-- --demo` liga o piloto automático.
- O demo decola, cruza 800 m na Lua e pousa na plataforma alvo (qualidade ~95%, 58 de gás);
  a telemetria vai para `~/Library/Application Support/Godot/app_userdata/Incremental Lander/telemetry/deliveries.csv`.
- Economia v6 em `data/economy.json` (não mudou). Nenhum asset de arte/som ainda (placeholders geométricos).
- Verificação: `gdtool.py check` (19 scripts ok), `test` (14 testes + paridade), `run`/`capture` com `-- --demo`.

## Próximo passo
1. **Usuário testar o voo manual** e dar feedback de sensação (velocidade de rotação, força do motor, tolerâncias,
   tempo ×3) — ajustes em `data/world.json`.
2. **Fase 2 — loop do run** (skill `godot-dev` + `economy-balance`): ofertas de entrega (`EconMath.contract_pay`),
   encadear entregas até o gás acabar (teto 6), resumo do run, `GameState` + `Events`.

## Pendências conhecidas
- Calibração: o autopiloto gastou 58 de gás em 800 m (modelo prevê 35 expert / 43 engaged / 52 casual) —
  ele desce devagar demais; dado real do jogador humano virá dos testes manuais (Fase 10: `calibrate()`).
- Terreno ainda é um polígono único (sem chunks); ok para distâncias da Lua do protótipo, rever para 15–60 km.
- Economia: ~20 min juntando para Ares por volta de 1 h; prestígio obrigatório por design.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
