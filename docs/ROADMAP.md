# Roadmap de construção

> Marque `[x]` ao concluir, com data. Ao fim de cada **etapa** (fase ou bloco grande): atualizar
> `docs/HANDOFF.md`, fazer commit (ver CLAUDE.md). Cada fase lista a(s) **skill(s) obrigatória(s)**.
> Arte e som podem ser intercalados a partir da Fase 1 (placeholders geométricos até lá — sem imagens
> fora da skill `pixel-art`).

## Fase 0 — Fundação ✅ (2026-09-29/30)
- [x] 0.1 Skills: `pixel-art`, `sound-design`, `economy-balance` (com biblioteca de padrões)
- [x] 0.2 Economia v6 aplicada em `data/economy.json` (simulada e validada)
- [x] 0.3 Git local + `.gitignore`
- [x] 0.4 `project.godot` (640×360, escala inteira, Nearest, snap) + `default_bus_layout.tres`
- [x] 0.5 `scripts/economy/econ_math.gd` validado contra o Python (`python3 tests/test_econ_parity.py`)
- [x] 0.6 Skill `godot-dev` (2026-09-30): arquitetura, estilo, física do lander, terreno, UI, save/telemetria,
      testes; ferramenta `gdtool.py` (api/check/test/run/capture); executor de testes em `tests/`
- [x] 0.7 Documentação de continuidade (CLAUDE.md, GDD, ROADMAP, HANDOFF, DECISIONS, ARCHITECTURE)

## Fase 1 — Protótipo de voo (sem arte final) ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance` (física ↔ modelo)
- [x] 1.1 Cena de voo: lander `CharacterBody2D` com integração própria (godot-dev `lander-physics.md`), gravidade, girar + propulsor; `data/world.json` + `WorldConfig`
- [x] 1.2 Consumo de gás por Δv (`efficiency`), tanque, HUD mínimo (gás, velocidade, altitude)
- [x] 1.3 Terreno em polígono irregular gerado (encostas + plataformas planas), colisão
- [x] 1.4 Detecção de pouso/batida + **qualidade q (0..1)** (velocidades, ângulo, centro da plataforma)
- [x] 1.5 Câmera lateral acompanhando o salto; escala do mundo `PX_PER_M` decidida e registrada em DECISIONS
- [x] 1.6 **Telemetria** de cada entrega → CSV (formato em `economy-balance/references/godot-integration.md`)
- [x] 1.7 Modo `--demo` (piloto automático) para verificação com `gdtool.py run/capture`
- Pronto quando: dá para decolar, voar até uma plataforma a X m, pousar/bater, o CSV registra o salto, e `check`/`test`/`run`/`capture` passam.

## Fase 2 — Loop do run ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance`
- [x] 2.1 Ofertas de entrega (distância × pagamento via `EconMath.contract_pay`), escolha pelo jogador
- [x] 2.2 Encadear entregas no mesmo run, renovação de ofertas, teto de 6, fim por gás/batida
- [x] 2.3 Resumo do run (entregas, qualidade média, créditos)
- [x] 2.4 `GameState` (autoload): recursos, níveis, planetas; formatação `EconMath.fmt`

## Fase 3 — Hangar e upgrades ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance`, `pixel-art` (UI)
- [x] 3.1 Tela de hangar entre runs: lista de upgrades, custo, comprar, comprar máx.
- [x] 3.2 Mapear `EconMath.ship_stats` → parâmetros físicos (thrust→aceleração, tank→gás, efficiency→Δv/gás, gear→tolerância)
- [x] 3.3 Mostrar "alcance estimado" com o gás atual

## Fase 4 — Planetas ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance`, `pixel-art`
- [x] 4.1 Parâmetros por planeta (gravidade, arrasto/vento, distâncias) vindos da spec
- [x] 4.2 Desbloqueio de Ares/Kronos, seleção de planeta, minério

## Fase 5 — Prestígio e loja da Poeira Estelar ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance`
- [x] 5.1 Tela de prestígio (ganho previsto, confirmação), reset via `EconMath.prestige_reset_state`
- [x] 5.2 Loja da Poeira (capital, ficha, cartas, motor de dobra, premium)

## Fase 6 — Fase final ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance`, `pixel-art`, `sound-design`
- [x] 6.1 Frota de drones (renda = drones × autopilot × média da renda do jogador)
- [x] 6.2 Expedição a Titan (8 etapas persistentes, barra segmentada) → Titan → final

## Fase 7 — Save/load e opções ✅ (2026-09-30) · skill: `godot-dev`
- [x] 7.1 Save (versão da spec + migração), autosave · [x] 7.2 Opções (volume por bus, controles)

## Fase 8 — Arte · skill: `pixel-art` (obrigatória para TODA imagem)
- [x] Lander 32×32 futurista + propulsor de plasma (2026-09-30; estilo escolhido entre 5 propostas)
- [x] Lua: cena rica em camadas (céu, Terra, montanhas facetadas em parallax, terreno com faixas por inclinação, pedregulhos) (2026-10-01; minimalista reprovado, rica aprovada)
- [x] Plataformas de pouso + feixe de luz, pista iluminada e marcador no alvo (2026-10-01; brilho pedido pelo usuário)
- [x] Explosão da batida + poeira do pouso (2026-10-01)
- [x] ~~Cenas de Ares, Kronos e Titan recoloridas~~ → reprovadas como conceito: cada planeta é um mundo diferente
- [x] Mundo 2 **Silvânia** (floresta fechada, id ares) e mundo 3 **Docelândia** (planeta dos doces, id kronos) (2026-10-01)
- [x] Mapa animado: vento na floresta, pirulitos girando, nuvens passando, estrelas cintilando (2026-10-01)
- [x] Mundo 4 **O Quarto** (quarto bagunçado, id titan), animado (2026-10-01)
- [ ]
      FX
- [x] Interface: fonte pixel com acentos, painéis, botões, barras e ícones; cor de destaque por mundo; todos os
      menus (HUD, entregas, resumo, hangar, final) (2026-10-01)
- [x] Menu inicial: título sobre a cena do mundo atual (nave na plataforma), Continuar/Jogar, Novo jogo (confirma),
      Opções (volumes), Sair; "Menu inicial" nas opções do hangar (2026-10-02)
- [x] Auditoria de UX de todas as telas (só apresentação/interação; regras intactas — saída do demo idêntica):
      foco de teclado visível e preservado, tooltips/rolagem no tema, volume com -/+ igual no título e no hangar,
      brilho de compra, "faltam X" nos custos, ações destrutivas em vermelho + Esc cancela, resumo/final modais com
      fundo escurecido, "IR AO HANGAR", motivo da batida legível, aviso central com painel (2026-10-02)
- [x] 2ª auditoria de UX (só apresentação/interação; saída do demo idêntica): pausa no voo (Esc / janela sem foco) com
      volumes e controles; dica de teclas do HUD em painel; cabeçalho de colunas nas ofertas; foco visível (com atraso) no
      resumo; modais bloqueiam clique atrás; números do hangar num só formato, "MÁX"; `fmt(1e6)` = "1.00M" (era "1000K");
      glifo inexistente "—" trocado; prévia `flight_ui_preview` (2026-10-02)
- [x] Filtro CRT ligado por padrão, com opção de desligar no título e no menu do jogo (2026-10-03)
- [x] Esc no hangar abre o **menu do jogo** (hangar escondido; volumes, controles, menu inicial, novo jogo), não mais uma
      "aba de opções" dentro do hangar; teste `esc_flow` (2026-10-03)
- [x] Vários jogos salvos: 3 espaços (jogo 1 = save.json antigo, sem migração), tela "Jogos salvos" no menu inicial
      (jogar / novo jogo / apagar com 2 cliques), opções e último jogo em `user://settings.json` (2026-10-02)

## Fase 9 — Áudio · skill: `sound-design` (obrigatória para TODO som)
- [x] Propulsor (plasma suave: ignição, loop, corte) · pouso · batida · entrega · UI (clique, compra, negado) (2026-10-01)
- [ ] Jingles (upgrade grande, planeta, prestígio) · alarme de gás baixo · ambiências por mundo · músicas

## Fase 10 — Calibração, polimento e build · skills: `economy-balance` (Etapa 10), `godot-dev`
- [ ] 10.1 Jogar, exportar telemetria, `calibrate()` → `profiles_override` → re-simular
- [ ] 10.2 Game feel (tremor, partículas, feedback) · 10.3 Export desktop (Mac/PC)
