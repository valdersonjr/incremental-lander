# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-29)
- **Fase 0 concluída**, exceto **0.6 (criar a skill `godot-dev`)**.
- Skills prontas: `pixel-art`, `sound-design`, `economy-balance` (ver CLAUDE.md).
- Economia **v6** aplicada em `data/economy.json` (frota + marcos + Expedição a Titan; ~5 h até Titan;
  pior espera ≤ 30 min). Histórico em `balance/CHANGELOG.md`.
- Projeto Godot criado (`project.godot`, buses) — **ainda sem cenas**. `EconMath` validado contra o Python.
- Nenhum asset de arte/som gerado ainda (`assets/` não existe).

## Próximo passo
1. **ROADMAP 0.6 — criar a skill `godot-dev`** na mesma pegada das outras (perguntar o que for necessário
   → pesquisar muito → biblioteca de padrões → fluxo obrigatório). Deve cobrir: arquitetura de cenas e
   autoloads, física do lander (RigidBody2D × física própria), terreno em polígono + colisão, sinais,
   save/load com versão, telemetria CSV, testes headless, convenções de código e commits.
2. Depois: **Fase 1 — protótipo de voo** seguindo a `godot-dev`.

## Pendências conhecidas
- Economia: ~20 min juntando para Ares por volta de 1 h; runs de 6–8 min no modelo (calibrar com a escala
  real do mapa na Fase 10); prestígio obrigatório por design.
- Em aberto no design: controles exatos, geração de mapas, pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir.
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. Rodar `python3 tests/test_econ_parity.py` se for mexer em economia.
