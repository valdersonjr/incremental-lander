# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-10-01)
- **Fases 0–7 concluídas; Fase 8 (arte) em andamento.**
- **Direção de arte**: futurista na nave + **cenas ricas em camadas** (o usuário reprovou terreno minimalista como
  "muito feio"; aprovou a cena da Lua: céu em faixas roxo→magenta, Terra com halo, montanhas facetadas, terreno com
  estrias e pedregulhos). Regra registrada no style-guide da pixel-art.
- **No jogo**: lander futurista + **cena da Lua completa** (fundo `Backdrop` em parallax + terreno com faixas
  cisalhadas lit/flat/shade + pedregulhos) + **plataformas** (sprite animado; alvo com feixe de luz, pista
  iluminada e marcador) + **explosão na batida** (a entrega só termina depois dela) e **poeira em cada pouso**. Ares/Kronos/Titan ainda usam o placeholder (sem `<planeta>_layers.json`).
- **Travas da Regra 0**: hooks bloqueiam ações numa área sem a skill dela; pre-commit valida assets/economia.

## Próximo passo
**Continuar a Fase 8** (skill `pixel-art` → prévia → aprovação → `godot-dev` integra):
1. Cenas de Ares, Kronos e Titan no mesmo padrão de `art/src/bg/moon_scene.py` (gerar `<planeta>_layers.json`;
   regra do usuário: mesmo estilo, só a paleta Resurrect 64 — muda a rampa, não a paleta).
2. UI: fonte pixel, painéis do hangar/HUD, ícones de upgrade.
Refinos pendentes da Lua: cortes verticais na troca de face do terreno; planície pode ler como lago.

## Pendências conhecidas
- "Alcance max (ideal)" no hangar é otimista e satura em 1000 km (limite da busca) — melhorar texto.
- Calibração: gasto de gás humano × modelo virá dos testes manuais (Fase 10).
- Terreno regenerado inteiro a cada entrega (sem chunks) — ok até ~30 km testados; rever se ficar lento.
- Nomes dos upgrades/planetas na spec sem acento — ajustar via economy-balance numa passada de texto.
- Telemetria antiga (antes da coluna pilot) misturava demo e humano: foi para `deliveries_old.csv` — não usar na calibração.
- Autopiloto do demo às vezes pousa fora da plataforma em Titan (gravidade 15) — só afeta verificação.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
5. Clone novo? Ativar o pre-commit: `git config core.hooksPath .githooks` (os hooks do Claude Code já vêm em `.claude/settings.json`).
   Se uma ação for BLOQUEADA pela Regra 0, invoque a skill indicada (ferramenta Skill) e repita — não contorne a trava.
