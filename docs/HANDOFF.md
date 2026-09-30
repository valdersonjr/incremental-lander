# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–4 concluídas.** Jogo: runs de entrega → hangar (upgrades + **planetas**: liberar Ares/Kronos com custo
  da spec, trocar de planeta, aviso de motor fraco) → decolar. Cada planeta tem gravidade/arrasto da spec, relevo
  e cores provisórias próprias; Ares/Kronos pagam minério (refinaria aparece com Ares).
- Demo verifica a progressão Lua → Ares (com `--dev_credits`): 6 entregas por run em Ares, qualidade 0,85–0,98.
- Autopiloto reescrito (arco balístico + motor sigma-delta): entrega nos três planetas testados.
- Sem prestígio (Fase 5), sem frota/Expedição (Fase 6), sem save (Fase 7). Visual placeholder (arte depois).

## Próximo passo
**Fase 5 — Prestígio e loja da Poeira Estelar** (skills `godot-dev` + `economy-balance`): botão de prestígio no
hangar (após Ares) com ganho previsto (`EconMath.prestige_gain` sobre créditos do ciclo), reset via
`EconMath.prestige_reset_state` (mantém etapas persistentes), nível passivo (bônus já entra em `ship_stats`),
loja (capital, ficha, cartas, motor de dobra, premium) com `EconMath.shop_cost`.

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
