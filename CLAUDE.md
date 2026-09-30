# Incremental Lander

Jogo incremental estilo Lunar Lander, visão lateral, **Godot 4.7** (instalado: `/Applications/Godot.app`
e CLI `godot`), para **computador** (teclado), resolução interna **640×360** com escala inteira.
Conceito completo: `docs/GDD.md`.

## Regra 0 — SEMPRE consultar as skills locais antes de qualquer operação
Antes de agir, identifique a skill da tarefa, **leia o `SKILL.md` dela e siga o fluxo e os padrões de
construção que ela propõe**. Não fuja desses padrões e não pergunte ao usuário o que uma skill já responde
(pergunte só quando a skill deixar a decisão explicitamente em aberto).

| Tarefa | Skill (obrigatória) |
|---|---|
| Qualquer imagem: sprite, tile, terreno, UI, FX, fundo, animação | `pixel-art` |
| Qualquer áudio: SFX, UI, propulsor, ambiência, música | `sound-design` |
| Qualquer número de economia/progressão: custos, efeitos, planetas, prestígio, ritmo | `economy-balance` |
| Código/cenas Godot, arquitetura, save, telemetria, testes, build | `godot-dev` |

Regras herdadas das skills:
- Arte: paleta **Resurrect 64** travada; fonte = scripts em `art/src/**.py`; exports em `assets/`; nunca
  editar PNG de `assets/` à mão.
- Áudio: 100% sintetizado (retro-synth espacial), escala em D, loudness por categoria; fonte em
  `audio/src/**.py`; aprovação do usuário ouvindo (`afplay`).
- Código: seguir `godot-dev` (arquitetura, estilo, física, verificação com `gdtool.py` antes de dizer que funciona).
- Economia: spec única `data/economy.json` (lida pelo jogo e pelo simulador); nada de números de economia
  hardcoded no GDScript; `scripts/economy/econ_math.gd` espelha `econ.py` — mudou um, mude o outro e rode
  `python3 tests/test_econ_parity.py`.

### Travas automáticas (não contornar)
- **Hooks do Claude Code** (`.claude/settings.json` → `.claude/hooks/skill_guard.py`): editar/rodar algo em `art/`,
  `assets/` → `pixel-art`; `audio/`, `assets/audio/` → `sound-design`; `data/economy.json`, `balance/`,
  `scripts/economy/` → `economy-balance`; `game/`, `scripts/`, `autoload/`, `tests/`, `*.gd/.tscn`, `gdtool` → `godot-dev`.
  Sem a skill invocada na sessão, a ação é **bloqueada**; após compactar o contexto, é preciso invocar de novo.
  Pedidos com palavras de arte/som/economia/código geram lembrete. Testes: `python3 .claude/hooks/test_skill_guard.py`.
  Comandos Bash que só **citam** esses caminhos em texto (ex.: heredoc editando docs) também são barrados —
  edite docs com a ferramenta Edit/Write.
- **Pre-commit** (`.githooks/`, ativar com `git config core.hooksPath .githooks`): PNG em `assets/` precisa de paleta
  Resurrect 64, script-fonte em `art/src/` e padrão no INDEX com `## Fontes` + URL (idem áudio); `economy.json` exige
  `balance/CHANGELOG.md` no commit + paridade. Testes: `python3 .claude/hooks/test_pre_commit.py`.

## Protocolo de sessão (continuidade)
**Início**: ler `docs/HANDOFF.md` (onde paramos + próximo passo) e `docs/ROADMAP.md`; `git log --oneline | head`.
**Durante**: registrar decisões novas em `docs/DECISIONS.md`; ao mudar design, atualizar `docs/GDD.md`.
**Fim de cada etapa** (item/fase do ROADMAP): marcar `[x]` no ROADMAP, atualizar `docs/HANDOFF.md`
(estado, próximo passo, pendências) e **fazer commit** (autorizado pelo usuário: commit ao fim de cada
etapa, mensagem em português, sem push — repositório só local).

## Mapa do projeto
- `docs/GDD.md` design · `docs/ROADMAP.md` fases/checklists · `docs/HANDOFF.md` estado e próximo passo ·
  `docs/DECISIONS.md` decisões · `docs/ARCHITECTURE.md` estrutura/contratos entre sistemas.
- `.claude/skills/` skills locais · `data/economy.json` economia · `balance/` simulações e histórico ·
  `art/`, `audio/` fontes dos assets (ignorados pelo Godot via `.gdignore`) · `tests/` testes.

## Preferências do usuário
- Não gosta de esperar scripts longos: otimize, paralelize, faça triagem barata antes de validação completa;
  avise antes se algo passar de ~1 min.
- A duração total do jogo é flexível; o que importa é ritmo sem esperas, habilidade e prestígio significativos.
- Responder em português.
