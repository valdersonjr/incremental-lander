# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–3 concluídas.** Loop jogável completo na Lua: run (ofertas 1–8, voar, pousar, encadear, fim) →
  resumo → **hangar** (comprar upgrades da spec: motor, tanque, bocais, reputação, trem de pouso; "max") → decolar.
- Demo (`-- --demo`) prova a progressão: ganhos por run 312 → 1.760 → 3.988 cr com upgrades comprados sozinho.
- Sem save (Fase 7), sem outros planetas (Fase 4), sem prestígio (Fase 5). Visual placeholder (arte depois).

## Próximo passo
**Fase 4 — Planetas** (skills `godot-dev` + `economy-balance`): desbloqueio de Ares/Kronos no hangar (custo da
spec, Kronos exige Ares + minério), seleção de planeta, física do planeta no voo (gravidade/arrasto já vêm da
spec), relevo por planeta (`world.json`), minério nas recompensas (já sai do RunState) e refinaria.

## Pendências conhecidas
- "Alcance max (ideal)" no hangar é otimista (ex.: 29 km com 176 de gás; o autopiloto gasta ~2× o ideal).
- Calibração: autopiloto gasta ~2× o gás mínimo ideal. Dados humanos virão dos testes (Fase 10).
- Terreno regenerado inteiro a cada entrega (sem chunks) — rever se ficar lento em 15–60 km.
- Nomes dos upgrades na spec estão sem acento ("Tanque de gas") — ajustar via economy-balance numa passada de texto.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
