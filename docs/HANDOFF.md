# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fase 0 concluída** (inclui 0.6: skill `godot-dev` criada e validada).
- Skills prontas: `pixel-art`, `sound-design`, `economy-balance`, `godot-dev` (ver CLAUDE.md).
- Economia **v6** aplicada em `data/economy.json`. Histórico em `balance/CHANGELOG.md`.
- Projeto Godot: `project.godot` (640×360, escala inteira, Nearest, snap, interpolação de física, aviso de
  tipagem), buses de áudio, `EconMath` + testes (`tests/`: executor próprio + paridade). **Ainda sem cenas.**
- Ferramenta de verificação: `python3 .claude/skills/godot-dev/scripts/gdtool.py check|test|run|capture|api`.
- Nenhum asset de arte/som gerado ainda.

## Próximo passo
**Fase 1 — protótipo de voo**, seguindo a skill `godot-dev` (ler `SKILL.md` + `references/lander-physics.md`,
`terrain.md`, `architecture.md`, `testing.md`):
1. 1.1 `data/world.json` + `WorldConfig`; cena `game/flight/` com lander `CharacterBody2D` (placeholder `_draw()`),
   gravidade, rotação, propulsor, gás = Δv/eficiência. 2. 1.3 terreno em polígono por seed com plataformas.
3. 1.4 pouso/batida + qualidade q (função pura testada). 4. 1.5 câmera + escala `PX_PER_M` (registrar decisão).
5. 1.6 telemetria CSV. 6. 1.7 modo `--demo`. Verificar com `check`/`test`/`run`/`capture` a cada passo.

## Pendências conhecidas
- Economia: ~20 min juntando para Ares por volta de 1 h; runs de 6–8 min no modelo (calibrar com a escala
  real do mapa na Fase 10); prestígio obrigatório por design.
- Em aberto no design: controles exatos, geração de mapas, pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
