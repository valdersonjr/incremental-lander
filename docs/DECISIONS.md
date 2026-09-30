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
| 2026-09-30 | Skill `godot-dev` criada; código segue seus padrões (arquitetura Main/World/GUI, sinais sobem/chamadas descem, event bus só entre ramos distantes) | regra de sempre seguir as skills | `.claude/skills/godot-dev/` |
| 2026-09-30 | Lander = `CharacterBody2D` com integração própria (não RigidBody2D) | gás = Δv/eficiência exato como o modelo econômico; pouso determinístico; demo/testes reproduzíveis | `godot-dev/references/lander-physics.md` |
| 2026-09-30 | Pastas por feature (`game/<feature>/` cena+script), `autoload/`, `data/world.json` para constantes de mundo | organização recomendada (docs Godot/GDQuest) | `godot-dev/references/architecture.md` |
| 2026-09-30 | Identificadores em inglês, comentários/docstrings em português; tipagem estática obrigatória | combina com a API; legível para o usuário | `godot-dev/references/gdscript-style.md` |
| 2026-09-30 | Testes com executor próprio mínimo (sem GUT/GdUnit4) | sem dependência, headless simples; reavaliar se precisar de mocks/input | `godot-dev/references/testing.md` |
| 2026-09-30 | Verificação sem editor: `gdtool.py` (api/check/test/run/capture) + modo `--demo` nas cenas de gameplay | Claude não abre o editor; frames capturados permitem revisão visual | `godot-dev/SKILL.md` |
| 2026-09-30 | Interpolação de física 2D ligada; aviso para declaração sem tipo | câmera suave com pixel snap; incentivar tipagem | `project.godot` |
| 2026-09-30 | Escala do mundo provisória: **1 px = 1 m do modelo**, tempo ×3 (`world.json`) | salto de 800 m ≈ 1,3 tela e ~30 s reais; Δv/gás iguais ao modelo (a escala de tempo não muda a trajetória) | `data/world.json`; recalibrar na Fase 10 |
| 2026-09-30 | Tolerâncias de pouso: V.VERT 3 m/s, V.HOR 2 m/s, inclinação 0,2 rad; trem de pouso amplia × gear^0,5; q = média ponderada (vert 35%, hor 25%, incl. 20%, centro 20%) | pouso exigente mas justo; q alimenta pagamento | `data/world.json`, `scripts/world/landing_rules.gd` |
| 2026-09-30 | Teclas registradas por código a partir do `world.json` (W/↑/Espaço propulsor, A/D/←/→ girar, R reiniciar) | escrever o input map à mão no project.godot é frágil | `WorldConfig.register_input()` |
| 2026-09-30 | Propulsor liga/desliga (sem acelerador analógico); rotação sem inércia; lander não gira pousado | simplicidade no protótipo; rever na Fase 10 (game feel) | `game/flight/lander.gd` |
| 2026-09-30 | Sensação de voo: tempo ×3 → ×4,5 e giro 2,5 → 4 rad/s | feedback do usuário: "motor fraco e giro pesado"; relação motor/gravidade é da economia e não mudou | `data/world.json` |
| 2026-09-30 | Entregas encadeadas: a próxima plataforma nasce a `d` metros à frente da atual e o terreno é regenerado (mesma seed ⇒ trecho já visto não muda) | segue o run-model (ofertas são distâncias); simples e determinístico | `game/flight/flight.gd` |
| 2026-09-30 | Colisão do terreno por segmentos (`ConcavePolygonShape2D`) em vez de polígono | leve e robusta para terrenos de vários km | `game/terrain/terrain.gd` |
| 2026-09-30 | Oferta mostra "mín ~X gás" (Δv ideal/eficiência, sem desperdício); demo exige folga 2,2× | o gasto real é maior que o ideal; evita o jogador achar que a estimativa é exata | `game/run/offer_panel.gd`, `RunState.best_offer` |
| 2026-09-30 | Lander só decola com uma entrega escolhida; pousar fora do alvo sem gás encerra o run ("sem gás") | fluxo claro de run | `game/flight/` |
| 2026-09-30 | Fluxo: 1º run começa direto; depois de cada run: resumo → hangar → decolar | o primeiro run não tem o que comprar | `game/main.gd` |
| 2026-09-30 | Hangar mostra "alcance max (ideal)" pelo Δv ideal | ensina o valor de tanque/eficiência; é otimista (sem desperdício) — rever com calibração | `game/hangar/hangar.gd` |
