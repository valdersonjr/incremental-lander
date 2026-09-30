# Registro de decisões

> Uma linha por decisão: data · decisão · motivo · onde está detalhado. Decisões de arte/som/economia
> também constam nos style-guides das skills; aqui fica o índice geral do projeto.

| Data | Decisão | Motivo | Detalhe |
|---|---|---|---|
| 2026-09-29 | Toda imagem via skill `pixel-art`; paleta **Resurrect 64** travada | consistência visual | `.claude/skills/pixel-art/` |
| 2026-09-29 | Engine **Godot 4** (instalado 4.7.2); perspectiva **side-view** | pedido do usuário | GDD §11 |
| 2026-09-29 | Todo áudio via skill `sound-design`; estilo **retro-synth espacial**, 100% sintetizado, escala em D | combina com pixel art, sem fadiga | `.claude/skills/sound-design/references/style-guide.md` |
| 2026-09-29 | Aprovação de áudio ouvindo via `afplay` | Claude não ouve | skill `sound-design` |
| 2026-09-29 | Economia via skill `economy-balance`; spec única `data/economy.json` | uma fonte de números para jogo e simulador | `.claude/skills/economy-balance/` |
| 2026-09-29 | Conceito: runs com gás limitado, entregas, upgrades (velocidade, gás, eficiência), planetas com física mais dura | ideia do usuário | GDD §1 |
| 2026-09-29 | Renda híbrida; prestígio + múltiplos recursos desde o início; automação mais tarde; sem offline | respostas do usuário | GDD §7–8 |
| 2026-09-29 | Pilotar bem > timing de prestígio (ofertas se renovam; bônus de precisão 1,5·q²) | casual terminava junto com expert | economy v3 |
| 2026-09-29 | Prestígio no padrão dos incrementais: nível passivo + loja da Poeira Estelar; 4–6 prestígios | ciclos repetitivos na v3 | economy v4 |
| 2026-09-29 | Fim do jogo = frota de drones + marcos (25 níveis ×1,5) + Expedição a Titan em 8 etapas | platô de horas antes de Titan | economy v6 |
| 2026-09-29 | **Duração total do jogo é flexível** (hoje ~5 h) | usuário: "não importa muito" | memória + style-guide economia |
| 2026-09-29 | **Terreno em polígono irregular** com plataformas planas | padrão das skills (`terrain-tiles.md` §7 + modelo de run) | GDD §4 |
| 2026-09-29 | Plataforma: **computador** (teclado); resolução interna **640×360**, escala inteira | respostas do usuário | GDD §11, `project.godot` |
| 2026-09-29 | Git local com **commit ao fim de cada etapa** | não perder progresso entre sessões | CLAUDE.md |
| 2026-09-29 | **Sempre consultar as skills locais antes de qualquer operação**; não fugir dos padrões delas | pedido do usuário | CLAUDE.md |
| 2026-09-29 | Scripts longos incomodam o usuário → simulador otimizado/paralelo; triagem antes de validação | preferência do usuário | memória + `economy-balance/SKILL.md` |
