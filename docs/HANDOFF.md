# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-09-30)
- **Fases 0–7 concluídas: mecânica completa + save + opções** (visual e som ainda placeholders/ausentes).
  O progresso agora é salvo em `~/Library/Application Support/Godot/app_userdata/Incremental Lander/save.json`
  (autosave; "Novo jogo" no hangar apaga). Demo/dev nunca salvam.
- Verificação: `gdtool.py check` (39 scripts), `test` (41 unitários + integração do save + paridade da economia).

## Próximo passo
**Fase 8 — Arte** (skill `pixel-art`, obrigatória para toda imagem; usuário quis mecânica antes e achou o
placeholder feio): começar por lander 32×32 (+ chama do propulsor animada), textura de terreno por planeta
(polígono: preenchimento seamless + faixa de superfície), plataformas, fundo espacial; depois UI (fonte pixel,
painéis). Seguir o fluxo da skill: pesquisa → prévia → aprovação do usuário → integrar trocando os `_draw()`.
Alternativa: Fase 9 (som, skill `sound-design`).

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
