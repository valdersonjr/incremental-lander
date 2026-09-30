# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0, 1 e 2 concluídas.** Jogo roda com `godot --path .`: escolher entrega (1–8), voar, pousar, receber
  créditos, encadear até 6 entregas; o run acaba por falta de gás, batida, limite ou [E]; resumo; [Enter] novo run.
- Sensação ajustada pelo feedback do usuário (tempo ×4,5, giro 4 rad/s). Relação motor/gravidade é da economia.
- Créditos acumulam na sessão (`GameState`), **ainda não há onde gastar** (Fase 3) nem save (Fase 7).
- Demo (`-- --demo`): 5 runs seguidos sem erros; 1–2 entregas por run com a nave inicial, 54–537 créditos.
- Visual ainda é placeholder geométrico (usuário achou feio; arte fica para depois da mecânica — decisão dele).

## Próximo passo
**Fase 3 — Hangar e upgrades** (skills `godot-dev` + `economy-balance` + `pixel-art` só se precisar de imagem):
tela entre runs com os upgrades da spec (custo `EconMath.upgrade_cost`, comprar, comprar máx.), aplicar
`GameState.ship_stats()` ao voo (já é usado ao criar o run), mostrar alcance estimado.

## Pendências conhecidas
- Calibração: autopiloto gasta ~2× o gás mínimo ideal (desce devagar). Dados humanos virão dos testes (Fase 10).
- Terreno regenerado inteiro a cada entrega (sem chunks) — ok até agora; rever se ficar lento em 15–60 km.
- Economia: ~20 min juntando para Ares por volta de 1 h; prestígio obrigatório por design.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
