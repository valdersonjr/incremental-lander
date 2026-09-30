# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–6 concluídas: o jogo tem começo, meio e fim (mecânica completa, visual placeholder).**
  Runs de entrega → hangar (planetas, upgrades, prestígio + loja da Poeira, **frota de drones**, **Expedição a
  Titan** em 8 etapas persistentes com barra segmentada) → liberar Titan → **tela de final** (pode continuar).
- Demo com recursos de dev verifica a reta final: frota rende ~53% da renda, 8 etapas sobrevivem ao prestígio,
  GOAL_REACHED ao liberar Titan. 38 testes + paridade da economia; zero erros em 40.000 frames.
- Falta: save/opções (Fase 7), arte (Fase 8), som (Fase 9), calibração/polimento/build (Fase 10).

## Próximo passo
**Fase 7 — Save/load e opções** (skill `godot-dev`, `references/save-telemetry.md`): `SaveManager` (autoload)
com JSON versionado em `user://save.json` (escrita atômica + backup + migração), autosave no fim do run/compra/
prestígio/sair; carregar ao abrir. Opções: volume por bus (Music/SFX/UI/Ambience). Depois: arte (usuário pediu
mecânica antes da arte) e som.

## Pendências conhecidas
- "Alcance max (ideal)" no hangar é otimista e satura em 1000 km (limite da busca) — melhorar texto.
- Calibração: gasto de gás humano × modelo virá dos testes manuais (Fase 10).
- Terreno regenerado inteiro a cada entrega (sem chunks) — ok até ~30 km testados; rever se ficar lento.
- Nomes dos upgrades/planetas na spec sem acento — ajustar via economy-balance numa passada de texto.
- Autopiloto do demo às vezes pousa fora da plataforma em Titan (gravidade 15) — só afeta verificação.
- Em aberto no design: pós-jogo, menus, nome final (GDD §12).

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
