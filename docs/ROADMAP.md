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
- [x] FX: explosão da batida, poeira do pouso, estouro de cristal, perigos; tremor de tela opcional (2026-10-03)
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
- [x] Modo sandbox no menu inicial (mundo + nave, tudo liberado, recursos repostos, nada salvo, sem telemetria) (2026-10-03)
- [x] Filtro CRT ligado por padrão, com opção de desligar no título e no menu do jogo (2026-10-03)
- [x] Esc no hangar abre o **menu do jogo** (hangar escondido; volumes, controles, menu inicial, novo jogo), não mais uma
      "aba de opções" dentro do hangar; teste `esc_flow` (2026-10-03)
- [x] Vários jogos salvos: 3 espaços (jogo 1 = save.json antigo, sem migração), tela "Jogos salvos" no menu inicial
      (jogar / novo jogo / apagar com 2 cliques), opções e último jogo em `user://settings.json` (2026-10-02)

## Fase 9 — Áudio · skill: `sound-design` (obrigatória para TODO som)
- [x] Propulsor (plasma suave: ignição, loop, corte) · pouso · batida · entrega · UI (clique, compra, negado) (2026-10-01)
- [x] Jingles (marco de upgrade/etapa, mundo liberado, recomeço, final) · alarme de gás baixo · ambiências dos 4 mundos ·
      músicas de título/hangar e de voo (2026-10-03; aprovado ouvindo o resumo)

## Fase 14 — Só a Lua + árvore de missões (2026-10-06) · skills: todas
> Pedido: "polir ao máximo o primeiro [mundo] e ignorar os outros"; tirar o prestígio; missões abstratas (pesada, pouso
> suave, rápida, passageiro, cabo) com ★1–★3, recompensa pela dificuldade, ratinho próprio por tipo, liberadas por
> estrelas ganhas jogando (1 ⭐ por entrega, 3 ⭐ liberam). Plano: `docs/HANDOFF.md`.
- [x] 14.1 Etapa A: sai prestígio, Silvânia/Docelândia/Quarto, Expedição, minério, perigos e o final; Frota/Piloto por
      créditos (economia v11); save v2 com migração; hangar NAVE + AJUDAS com faixa de recordes (2026-10-06)
- [x] 14.2 Etapa B: missões abstratas + estrelas + aba PEDIDOS (economia v12; táxi em 2 trechos; Dupla) (2026-10-06)
- [x] 14.3 Etapa C: ratinhos das missões (aprovados) + ícones peso/relógio/estrela; som da estrela (opção A) e liberar = jingle unlock (2026-10-06)

## Fase 15 — Escolha intuitiva + cada missão no seu mapa (2026-10-06) · skills: `pixel-art`, `godot-dev`, `economy-balance`
> Pedido: o cartão do pedido não era intuitivo para criança (×1,5, barra de gás invertida, botão de partir feio, ninguém
> sabe o que cada ratinho quer) → versão D das maquetes (`art/previews/offer_card/`); e "cada missão iniciar de um lugar
> aleatório no mapa". Plano: `~/.claude/plans/planeje-essa-nova-ideia-cheeky-wolf.md` (resumo no HANDOFF).
- [x] 15.1 Figuras: plataformas pequenas (3), perto/médio/longe, certo/errado (atlas kids) + balão de fala 9-slice (2026-10-06)
- [x] 15.2 Tela de escolha: fila de ratinhos no alto + cartão (balão com a regra, 3 plataformas = botões de partir com o
      prêmio, estrelas); sem gás e sem botão "vamos"; `MissionText` único (cartão + oficina) (2026-10-06)
- [x] 15.3 Cada missão no seu mapa (seed por entrega) + tela escurece e a nave desce do céu; fundo mostra outro trecho (2026-10-06)
- [x] 15.4 Relevo pensado para cada regra (subida, mesa, cratera, degrau…) + conferir gás com a economia (≤1%: sem mudança) (2026-10-06)
- [x] 15.5 Telinha "Novo amiguinho!" ao liberar um tipo (ratinho, balão, certo × errado) (2026-10-06)
- [ ] 15.6 Aprovação do usuário jogando (cartão, descida, relevos; tamanho da cratera do Cabo em saltos curtos)
- [x] 15.8 Janela de conversa na escolha da missão: gatinho herói × ratinho de corpo inteiro (7 tipos), um balão (pedido
      + regra), colunas Distância/Plataforma/Dificuldade, "Você ganha" + ACEITAR MISSÃO; fila com todos os ratinhos
      (bloqueados em silhueta) (2026-10-07)
- [x] 15.7 Tela inicial própria (sem o mapa de voo): pesquisa de telas profissionais → 3 conceitos (Vitrine/Passeio/
      Plataforma) → escolhido A "Vitrine" v3 (gatinho herói acenando no morro de queijo, logo de doce, frase da proposta,
      Jogar com 3 estados, parallax/nuvens/estrelas) (2026-10-06)

## Fase 18 — Mundos novos (2026-10-07) · skills: `pixel-art`, `economy-balance`, `godot-dev`, `sound-design`
> Pedido do usuário: "ser sempre a Lua de queijo deixa desinteressante?" → pesquisa (novidade moderada; Hill Climb
> Racing 2: mapas paralelos com recorde próprio e bônus por bater a marca; Clash Royale: arenas como paradas grandes
> da trilha única; Cut the Rope: estrelas abrem mundos). Plano aprovado: mundos paralelos (mesma nave/moedas/ratinhos,
> física própria, renda até ~1,3× a da Lua), recordes por mundo + bônus de recorde, uma Estrada só com parada
> `world`, seletor de mundo na PROGRESSÃO. Mundos NOVOS (não os 3 antigos).
- [x] 18.1 Conceitos (pixel-art): `art/previews/mundos/mundos.html` (5 cenas animadas + preto e branco); o usuário
      ficou com **todos**, na ordem Nuvens (correntes que sobem) → Bolhas (bolhas empurram; mar = splash) →
      Cogumelos (chapéu-mola) → Sorvete (chão escorregadio) → Jardim (vento lateral) (2026-10-07)
- [x] 18.2 Economia (v16): 5 planets `road: true` (g 1,15/2,4/3,2/4,0/4,9; pay calibrado para 1,15× a Lua com a
      nave do fim), paradas `world_<id>` (24/44/66/88/110★), `record_bonus` 15% (1ª visita 40%); simulador com
      recorde por mundo; MC: Lua 25–29% dos runs, nenhum mundo domina; `RoadText` reconhece parada de mundo (2026-10-07)
- [x] 18.3 Multimundo no código: usuário escolheu o **Mapa das estrelas** (`art/previews/seletor/seletor.html`,
      variante C). `GameState.worlds/select_world/world_records` (recordes por mundo), save v5 (migra recordes para
      "luna"; guarda o mundo liberado), bônus de recorde pago na Main e mostrado no resumo, `WorldMap`
      (`game/worlds/world_map.gd`: caminho pontilhado, planetinhas 24 px provisórios, troféu/NOVO/cadeado, navezinha,
      VOAR EM …; DECOLAR abre o mapa quando há 2+ mundos), dados provisórios por mundo (world.json terrain.planets +
      routes), `RoadText` com parada de mundo; prévias `world_map_preview [-- --all]`, `flight_ui_preview --world=<id>`;
      integração `world_flow` (2026-10-07)
- [ ] 18.4 Mecânica de cada mundo (base Hazards/HazardView do commit 4ec1ea1)
- [ ] 18.5 Arte de cada mundo (cute-scene-method, validada no jogo)
- [ ] 18.6 Som: ambiência + som do elemento + jingle de mundo novo
- [ ] 18.7 Jogar e ajustar

## Fase 17 — Bata seu recorde + paisagens (2026-10-07) · skills: `economy-balance`, `godot-dev`, `pixel-art`
> Pedido do usuário: o run como meta imposta (teto de 6 entregas) não combina; "competir com ele mesmo": tanque cheio,
> quantas missões conseguir, guardar dinheiro/distância/entregas e evoluir a nave para bater recordes (padrão Hill Climb
> Racing / Learn to Fly). E "o relevo é muito igual": receita nova a cada missão. Plano aprovado em 2026-10-07.
- [x] 17.1 Run sem teto (economy-balance + godot-dev): sai `max_per_run`; `contracts.run_fatigue` 1,7 (gás do salto ×
      1,7^n; galão devolve gás / 1,7^n) garante que o run acaba; `econ.py`/`EconMath.run_fatigue_mult`, paridade 31;
      `RunState.fatigue()` (gás estimado), `Flight.set_fatigue` (eficiência da missão), HUD de entregas sem "/6";
      testes (sem teto; run sempre acaba). MC 3×3 6 h: entregas/run ~2 no começo → ~15 no fim; Gasolina/Eficiência
      compradas (nív. ~50/~34; antes ~14/~7) (2026-10-07)
- [x] 17.2 Recordes (godot-dev + pixel-art): `RunState.record_values` (dinheiro, entregas, distância, perfeitos, maior
      entrega); `GameState.RECORDS`/`record_text`; save v4 (migra best_run/best_perfect/longest_hop); HUD placar A
      (`Hud._build_score`/`set_records`), resumo "troféus" (`RunSummary._add_records`), troféu nos 2 atlas
      (`ui_kit.py`/`kids_ui.py`); prévias `flight_ui_preview -- --records`, `summary_preview [-- --first]` (2026-10-07).
      Pendente: som próprio de recorde (hoje: jingle milestone)
- [x] 17.3 Paisagens (godot-dev + pixel-art + economy-balance): 7 receitas em `world.json > terrain.landscapes`
      (`TerrainGen.landscape`/`pick_landscape`, ruído ridged, degraus, desnível ±, alvo em mesa/vale, 0–3 morros,
      crateras); `Flight.landscapes` (do `GameState.landscapes()`); 5 paradas `landscape` na Estrada (economy.json,
      rascunho) + ícones `land_*` no atlas kids; fundo segue o chão (`background.ground_follow`); plataforma no nível
      sem parede colada; prévia `landscape_preview [-- --near] [--seed=N]`; testes (8 seeds × 7 paisagens) (2026-10-07).
      Δv: o modelo da economia não usa o relevo (arco ideal); conferir jogando/telemetria

## Fase 16 — PROGRESSÃO: Estrada das Estrelas + Reputação (2026-10-07) · skills: `economy-balance`, `godot-dev`, `pixel-art`, `sound-design`
> Pedido do usuário: ver toda a progressão desde o início ("incita a querer chegar lá"). Escolheu, entre 3 protótipos
> HTML, a **Estrada das Estrelas** (padrão Trophy Road / passe de batalha). Protótipo: `art/previews/progressao/`.
> Regras em `docs/DECISIONS.md` (2026-10-07). **Economia fina depois, de acordo com a jogabilidade**: nesta fase os
> números novos são provisórios (marcados "rascunho" na spec), só o suficiente para jogar.
- [x] 16.1 Spec + espelho (economy-balance): `progression.road` em `economy.json` (paradas em ordem: Mineiro, ratinhos
      ★1–★3 e Dupla, Estabilizador, Turbo, 7 ajudas, Frota, Piloto automático, "Lua completa"; estrelas provisórias da
      curva do protótipo); `contracts.reputation` (+10%, substitui `combo`); sai o upgrade `contracts` (Reputação por
      moedas) e os marcos dele; `econ.py` + `econ_math.gd` (estrelas acumuladas liberam paradas; reputação) +
      `test_econ_parity.py`; `screen()` só para ver que nada quebrou (sem rebalancear); CHANGELOG + versão
- [x] 16.2 Estado e save (godot-dev): `GameState.stars` vira **total acumulado** (não se gasta);
      `road_reached` (ids) libera sozinho (ratinho → nó de missão; habilidade/ajuda → nível 1; Frota/Piloto → podem ser
      comprados); `reputation_ready` (bool, guardado entre runs); migração do save v2→v3 (total = estrelas + 3 × nós
      liberados; o que já foi comprado continua); testes unitários do save e da estrada
- [x] 16.3 Reputação no voo (godot-dev): pouso perfeito = inclinação ≤ 25% de `max_tilt` e V.vert ≤ 40% de `max_vy`
      (`data/world.json > landing.perfect`, calibrável) → próxima entrega +10%; outro pouso → sem; batida → perde a atual
      e a próxima; o painel COMBO do HUD vira o **selo de Reputação** (aceso/apagado + aviso "Pouso perfeito! próxima
      +10%"); "Você ganha" da escolha de missão mostra o selo; recorde "maior combo" sai (ou vira "pousos perfeitos
      seguidos"); testes de RunState
- [x] 16.4 Tela PROGRESSÃO (godot-dev): o hangar renomeado; **Estrada da Lua** no topo (rolagem por setas/roda/arrasto
      e teclado, nave na posição, próximo prêmio pulsando com "faltam N", balão ao clicar); aba NAVE = nave grande + 4
      cartões de peça em degraus de 10 (bolinhas, "Motor II!" com festinha, peça que brilha ao passar o mouse);
      Estabilizador/Turbo ganhos acima da nave; seletor ×1/×10/MÁX; aba AJUDAS (ligar/desligar; cadeado com "na
      estrada: N⭐"); aba FROTA (cadeado até a parada; pista de drones + Piloto automático); aba PEDIDOS sai;
      aviso "Na estrada: novo prêmio!" ao voltar do voo (substitui o MissionIntro de nó comprado); prévias
      `hangar_preview` (`--stars`, `--news`, `--sel`, `--tab`, `--late`) e integrações atualizadas (2026-10-07)
- [ ] 16.5 Arte (pixel-art): peças que crescem por degrau (chama, tanque, bocal, pés: 3–4 versões cada, encaixadas no
      `lander.png`), ícones da estrada que faltam (Estabilizador, ajudas, troféu "Lua completa"), selo de Reputação;
      sons (sound-design): parada da estrada alcançada, degrau de peça, pouso perfeito
- [ ] 16.6 Aprovação do usuário jogando → depois, fase de economia (estrelas por parada, preços sem o upgrade de
      Reputação, Gasolina/Eficiência pouco compradas, marcos alinhados aos degraus)

## Fase 13 — Simples e com ajudas ✅ (2026-10-05) · skills: `economy-balance`, `godot-dev`, `pixel-art`
> Pedido: "tirar essa porra de cristal e refinaria, não vi mta diversão" + árvore de atributos que facilita a vida
> (setinha → cor de chegando → rota traçada…). "A ideia do jogo é ser simples".
- [x] 13.1 Economia v9: sem cristais e sem Refinaria, pay_base 9,5, 7 ajudas (compra única, persistentes, pré-requisito) (2026-10-05)
- [x] 13.2 Ajudas no voo (AssistView + marquinha de gás no HUD) e aba AJUDAS na oficina (árvore, ligar/desligar) (2026-10-05)
- [ ] 13.3 Aprovação do usuário jogando + figurinhas finais dos cartões (hoje desenhadas em _draw) + som de "chegando"?
- [x] 13.4 Presentes no alto do morro (galão de gás / presentinho; encostar devagar) — economia v10, arte, testes (2026-10-06)

## Fase 12 — Lua mais divertida ✅ (2026-10-05) · skills: `economy-balance`, `godot-dev`, `pixel-art`
> Pedido: "o que não existir no nosso jogo, adicione de forma divertida e dada a temática do mapa (só a Lua)" + "tira
> todos coelhos e alienígena do mapa". Pesquisa: Space Taxi, Thrust/Solar Jetman, Lunar Lander Beyond, Death Stranding.
- [x] 12.1 Economia v8: cargas (multiplicador/falha/gás) + habilidades (modelo + espelho + paridade + screen) (2026-10-05)
- [x] 12.2 Pedidos para os dois lados (terreno, pinos na borda esquerda, autopiloto) (2026-10-05)
- [x] 12.3 Cargas no voo: bolo, sorvete, queijão no cabo (pêndulo), ratinho (resgate) + HUD + cartão (2026-10-05)
- [x] 12.4 Habilidades Estabilizador e Turbo (teclas remapeáveis, controle, botões na oficina) (2026-10-05)
- [x] 12.5 Arte: atlas de cargas/ícones; Lua sem coelhos e sem alienígenas (2026-10-05)
- [ ] 12.6 Aprovação do usuário jogando (sensação do cabo, prazo do sorvete, raio do resgate) + sons próprios (sound-design)

## Fase 11 — Voo com decisões ✅ (2026-10-03) · skills: `economy-balance`, `godot-dev`, `pixel-art`, `sound-design`
> Pedido do usuário (2026-10-03): pagamento só por distância é sem graça; nada obriga a voar alto; andar de lado é
> entediante → "faz tudo que for sabido que deixa os gamers felizes". Padrões: Lunar Lander 1979 (plataforma estreita
> = multiplicador), combos, coletáveis no arco, relevo que exige altitude.
- [x] 11.1 Economia: plataformas com multiplicador por dificuldade, combo de pousos bons, cristais no ar (modelo +
      espelho GDScript + simulação dos 3 perfis + spec v7) (2026-10-03)
- [x] 11.2 Relevo com verticalidade: cristas entre as plataformas (um arco bom passa, voar baixo não), plataformas
      em pico/platô e em vale; ar mais denso perto do chão nos mundos com atmosfera (2026-10-03)
- [x] 11.3 Plataformas difíceis no jogo (largura, multiplicador na oferta e no marcador) + combo no HUD + pop-ups (2026-10-03)
- [x] 11.4 Cristais no ar (coleta, bônus) + arte (pixel-art) + sons (sound-design) (2026-10-03)
- [x] 11.5 Perigos por mundo (Floresta vento; Doces calda; Quarto ventilador/objetos caindo) (2026-10-03)

## Fase 10 — Calibração, polimento e build · skills: `economy-balance` (Etapa 10), `godot-dev`
- [ ] 10.1 Jogar, exportar telemetria, `calibrate()` → `profiles_override` → re-simular (**precisa de sessões humanas**:
      a telemetria tem 16 entregas humanas; o modelo ainda avisa run de ~450 s e esperas de 10–17 min na 1ª hora)
- [x] 10.2 Game feel: tremor de tela (batida/pouso duro, opcional), jingles, alarme, feedback de compra (2026-10-03)
- [ ] 10.3 Export desktop: presets prontos (macOS universal, Windows x86_64, Linux; sem tests/), ícone, versão 0.9.0,
      renderer Compatibility; `.pck` exportado e testado (roda, JSON incluídos). **Falta**: instalar os templates de
      export 4.7.2 (Editor → Gerenciar templates de exportação → Baixar), gerar os executáveis e testar numa máquina
      limpa; assinatura/notarização do macOS se for distribuir fora do itch.io

## Auditoria de lançamento (2026-10-03) ✅ correções · skills: todas
- [x] Travadas do terreno no fim de jogo (4,5 s → ~0,1 s) · [x] recomeço preso em mundo impossível · [x] save ilegível
      protegido + aviso · [x] input (Espaço, R/E 2x, R no final, teclas atrás do hangar) · [x] relógio do run sem pausa ·
      [x] autosave por entrega · [x] teclas remapeáveis, controle, tela cheia · [x] pós-jogo (recordes) · [x] áudio completo
      · [x] ícone · [x] build (presets, renderer, pasta de dados, sem dev/telemetria no público)
