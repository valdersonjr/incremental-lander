# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–7 concluídas + Fase 8 iniciada.** Mecânica completa, save e opções.
- **Arte**: usuário escolheu a **direção futurista** (entre 5 propostas; folha em `art/previews/lander_styles_compare.png`).
  Lander futurista (branco + turquesa, propulsor de plasma ciano) **já está no jogo** (AnimatedSprite2D).
  Terreno, plataformas, céu, HUD e telas ainda são placeholders.
- Ferramenta: `gdtool capture` agora usa `--always-on-top` e detecta gravação congelada (macOS).

## Próximo passo
**Continuar a Fase 8 — arte** (skill `pixel-art`, estilo futurista do style-guide; mostrar prévia e pedir aprovação):
1. Terreno por planeta (polígono: textura de preenchimento seamless + faixa de superfície) — Lua primeiro.
2. Plataformas de pouso (luzes/sinalização turquesa) e fundo espacial (estrelas, parallax).
3. Explosão da batida e poeira do pouso; depois UI (fonte pixel, painéis do hangar).
Integração no Godot pela skill `godot-dev` (trocar os `_draw()`/Polygon2D pelos assets).

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
