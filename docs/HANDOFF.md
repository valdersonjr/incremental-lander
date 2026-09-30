# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–5 concluídas.** Loop: runs → hangar (planetas, upgrades, **prestígio**: coletar Poeira Estelar →
  loja [capital, ficha de piloto, cartas de navegação, Motor de dobra, premium] → concluir recomeço).
  Nível de prestígio dá bônus passivo (já no ship_stats).
- Demo (`--demo --dev_credits=400000`) verifica: Lua → Ares → prestígio (38 Poeira) → run pós-prestígio rende
  128K cr (vs 290 no início do jogo).
- Sem frota/Expedição (Fase 6), sem save (Fase 7). Visual placeholder (arte depois, decisão do usuário).

## Próximo passo
**Fase 6 — Fase final** (skills `godot-dev` + `economy-balance`): upgrades `fleet`/`autopilot` já aparecem no
hangar após o Motor de dobra (via spec); falta a **renda da frota** durante o run
(`EconMath.fleet_income_per_s` × média da renda do jogador) e a **Expedição a Titan** (8 etapas persistentes,
barra segmentada no hangar) → liberar Titan → tela de final.

## Pendências conhecidas
- "Alcance max (ideal)" no hangar é otimista e satura em 1000 km (limite da busca) — melhorar texto.
- Calibração: gasto de gás humano × modelo virá dos testes manuais (Fase 10).
- Terreno regenerado inteiro a cada entrega (sem chunks) — ok até ~30 km testados; rever se ficar lento.
- Nomes dos upgrades/planetas na spec sem acento — ajustar via economy-balance numa passada de texto.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
