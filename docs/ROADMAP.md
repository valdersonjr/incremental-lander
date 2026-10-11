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
- [x] 18.3b Minijogos — plano + protótipo jogável aprovado ("pode implementar"): `art/previews/minijogos/minijogos.html`
      (6 minijogos com a nave + autoteste) e `art/previews/hub/hub.html`; ordem Lua (trilha) → Nuvens (Snake) →
      Cogumelos (Doodle Jump) → Sorvete (curling) → Jardim (Flappy) → Bolhas (garra) (2026-10-07)
- [x] 18.3c Economia v17 + estado por mundo: Estrada por mundo (`progression.roads`), pedido-assinatura
      (`planets[].mission`), `GameState.world_stars/stars_in/world_done/worlds` (mundo completo abre o próximo), save v6,
      `RunState` só com os 3 pedidos do mundo, `RoadText` com a parada `complete`; testes e integrações atualizados (2026-10-07)
- [x] 18.3d Hub: Jogar/novo jogo/sandbox/fim do run abrem o **Mapa das estrelas** (tela principal); cartão do mundo com a
      Estrada dele (`RoadView`), recorde/estrelas e VOAR/NAVE; mundo completo = anel + bandeira; viagem animada ao
      completar (`WorldMap.open(travel_from)`); Esc na NAVE volta ao Mapa, Esc no Mapa abre o menu; sandbox com tudo
      liberado; resumo "CONTINUAR"; integrações adaptadas; prévia `world_map_preview [-- --all | --travel]` (2026-10-07).
      Pendente: a PROGRESSÃO ainda mostra a Estrada do mundo (duplicada com o cartão)
- [x] 18.4a Lua — trilha de queijinhos: `world.json > minigames.luna` (6/9/11 queijinhos, arco mais alto nas estrelas
      maiores), `scripts/world/minigames.gd` (`Minigames`), `Flight._setup_minigame/_tick_minigame/minigame_text/verb`,
      pagamento `EconMath.minigame_pay` (planets[].mission_bonus; paridade 40), verbo no HUD (`Hud.show_verb`), placar na
      linha da missão; testes `test_minigames` + integração `minigame_flow` (2026-10-07)
- [x] 18.4b Nuvens — fila de carneirinhos (Snake) + correntes de ar: `minigames.nuvens` (1/3/5 carneirinhos, colunas
      que empurram para cima via `Lander.env_accel`), fila segue o histórico da nave, encostar no chão perde o último,
      faltou carneirinho = Passageiro falhou (paga menos); resgate antigo desligado nas Nuvens; fala/regra do mundo em
      `minigames.<mundo>.ask/say` (`MissionText`); `RunState` garante o pedido do mundo; dev `--dev_world=<id>`;
      figura provisória (coelhinho) até a arte (2026-10-07)
- [x] 18.4c Cogumelos — chapéus-mola (Doodle Jump) + ovinho: `minigames.cogumelos` (1/3/3 chapéus em escada), caindo
      no chapéu a nave quica (`Minigames.hits_cap/bounce_vy`), placar de quiques; o ovinho é o Pouso suave que já existia;
      cogumelo desenhado provisório (2026-10-07)
- [x] 18.4d Sorvete — curling no gelo: alvo vira pista larga (`pad_tiers.rink` 220 m); a plataforma escolhida vira o
      tamanho dos anéis (normal 46 / estreita 32 / apertada 20 m, e continua multiplicando o pagamento); pousar de lado vale
      (`Lander.ice_pad_id/ice_vx_mult`); depois do pouso a nave desliza (`Minigames.slide_step`, atrito 0,6) e a qualidade
      é a distância ao centro (`curling_quality`); relógio da Rápida segue; prévia `minigame_preview -- --world=<id>` (2026-10-07)
- [x] 18.4e Jardim — caules das flores (Flappy Bird) + vento + mel pesado: `minigames.jardim` (2/4/6 caules, vão de
      120/95/75 m no arco ideal), vento lateral que vai e volta (`Minigames.wind_at`), bater no caule empurra de volta sem
      explodir e o caule não conta (`hits_stem`), faltou vão = Pesada paga menos (2026-10-07)
- [x] 18.4f Bolhas — garra do baú (máquina de garra/pescaria) + mar + bolhas: a corda começa com a garra leve
      (`minigames.bolhas.hook_mass`) e pega o baú ao encostar (vira carga com o peso da estrela); baú no mar por 0,6 s =
      molhou (Cabo falhou); nave no mar = splash; colunas de bolhas empurram nave e carga; mar atrás do relevo (só nos
      vales); chegou sem o baú = paga menos (2026-10-07). **18.4 completa: os 6 minijogos no voo** (figuras provisórias)
- [x] 18.5 Arte visual dos 5 mundos (pixel-art, 2026-10-07): cenários com o kit da Lua por tema
      (`art/src/bg/world_scene.py` → `assets/bg/<mundo>_*`, chão/pedras próprios), figuras dos minijogos
      (`minigame_props.py`: carneirinho, chapéus-mola, caule + flores, mar, gelo, bolhas, baú, garra, lufada),
      moradores de corpo inteiro na conversa + palco por mundo (`world_npcs.py`, `TalkArt`), rostinhos 24x24
      (`kids npc_<mundo>`), planetinhas do Mapa em 1x (`map_planets.py`). Página de aprovação
      `art/previews/mundos_arte/index.html` — **aguardando o usuário ver/jogar**
- [x] 18.5b Auditoria dos minijogos (2026-10-08, relatório https://claude.ai/artifact/1kffVyZpAtd3MmubEaw7wg) aplicada:
      telemetria dos minijogos; integração `minigame_geometry`; Jardim (vento visível, vão inteiro, calmaria); Bolhas
      (baú por estrela, corda 30 m, aviso de molhar); Cogumelos (escada até o alvo, n/N); Sorvete (pino-fantasma, deslize
      4 m/s); Nuvens (fila 14, volta ao cair, correntes com intenção); Lua (queijinho, trilha ≤ +120 m); economia v18
      (crédito parcial, estrela da Lua pelos queijinhos, bônus dos Cogumelos, takeoff_twr); placar em figuras, seta para
      item fora da tela, selo de minijogo completo; sons boing/bump/sheep/pass (aguardando aprovação ouvindo)
- [x] 18.5c Auditoria de UX/UI e direção de arte (2026-10-08) aplicada: vírgula decimal em todo número (`fmt` nos
      dois espelhos); sem dicas de tecla nos botões e no rodapé; tela "NAVE" com um nome só (aba PEÇAS, "VOLTAR À
      NAVE"); "Modo livre" no lugar de Sandbox; níveis em algarismo comum; HUD com DESCIDA/DE LADO/ALTURA, recorde com
      troféu (não "/8") e "!" quando rápido demais; resumo com figura da categoria + troféu; DimLabel steel (5,4:1) e
      texto desabilitado legível; botão de perigo vinho; verde = partir (VOAR, DECOLAR, ACEITAR); pausa em abas;
      estados bloqueado/silhueta/escurecer na paleta (`palette_fx.gdshader`); Mapa só explica o próximo cadeado;
      plataformas grande/média/pequena e "longe: falta gás"; jogos salvos com fundo ink no texto e "começou agora";
      contorno branco no lander; nave pôster 1x na tela NAVE; vazamentos de nós na saída corrigidos
- [x] 18.5d Auditoria dos primeiros minutos / FTUE (2026-10-08, relatório https://claude.ai/artifact/Eme3BchGnN7iMng1rGbNSg):
      pesquisa (Andersen 2012, Passalacqua 2020, SDT, Hodent, Cook, Nintendo, Pecorella, NN/g, Budge, Toca Boca) +
      jornada com capturas + simulação + telemetria → 15 achados, 31 heurísticas (9 cumpre · 9 parcial · 13 falha)
- [x] 18.5e Auditoria dos primeiros minutos aplicada (2026-10-08; regras em world.json > onboarding; GDD §8):
  - [x] M5 telemetria de sessão (`session.csv` + `godot-dev/scripts/ftue.py`)
  - [x] C1+A5+M1 jogo novo começa voando (1º salto já aceito, 160 m, chão quase plano, sem minijogo; "Pouse!");
        aprendiz não vê "falta gás" (plataforma normal: uma mais larga pediria arte nova)
  - [x] C2 aprendiz (< 5 entregas): batida/sem gás repete o salto com o gás dele; pouso devagar fora para no chão
  - [x] C3+A3 Coach sem texto (teclinha do motor/girar só quando falta) + medidor de descida — placeholder em `_draw`
        (protótipo HTML pulado: o usuário mandou aplicar tudo com a recomendação)
  - [x] A1+M3 CONTINUAR → NAVE quando dá para comprar; Mapa com moedas e "!"; NAVE só PEÇAS no começo, ×10/MÁX depois
  - [x] A2+M4 revelação por etapas (minijogo, recordes, reputação, abas); "Novo amiguinho!" também no Mapa
  - [x] A4 resumo/aviso dizem como acertar · C4 perfil novato no simulador · B1 `docs/PLAYTEST_KIDS.md` · B2 GDD §8
  - [ ] M2 janela de missão menor (mantida a maquete aprovada; o 1º salto mostra o mundo antes dela) — rever jogando
  - [ ] arte final do Coach (teclinha e medidor; pixel-art) e som de "tente de novo" (sound-design), se o usuário quiser
  - [ ] jogar e medir: funil `ftue.py` + 3 crianças (PLAYTEST_KIDS); novato simulado ainda ~5 min até a 1ª compra
- [x] 18.5f Aprendiz validado contra os jogos mais vendidos (2026-10-08; GDD §8, DECISIONS):
  - [x] relevo baixo em todo salto antes da 1ª entrega · "Veja como!" (piloto automático; o motor devolve a nave)
  - [x] Nivelador emprestado ao aprendiz · "PILOTO FORMADO!" na 5ª entrega · simulador: `guide_after` no novato
  - [x] retorno em figura em vez de texto: o usuário escolheu a recomendação B+C do protótipo
        `art/previews/dicas/dicas.html` → `RetryHint` (fantasma na plataforma + balão na nave até decolar), placeholder em `_draw`
  - [ ] arte final do fantasma/balão (pixel-art), se o usuário quiser
- [x] 18.5g Começo pelo Mapa + menus explicados (2026-10-09; usuário: "jogado no voo", "os menus não são explicados";
      protótipo aprovado `art/previews/menus_intro/menus_intro.html`; GDD §8, DECISIONS):
  - [x] jogo novo abre o Mapa ("Voe!"); nome do mundo na chegada; fim do run do aprendiz volta ao Mapa
  - [x] botão MAPA na NAVE + "Mapa!"; AJUDAS ("Ajuda!" → "Liga/desliga"); abas novas com Q/E; 2º mundo com ← →
  - [x] "PILOTO FORMADO!" diz onde fica o Nivelador; menu do Mapa: "VOLTAR AO MAPA"; balão do destaque por cima
        da tela escura (antes ficava sob o xadrez)
  - [ ] selinho "emprestado" do Nivelador no voo do aprendiz (ficou fora do protótipo; só se o usuário quiser)
- [x] 18.5h Auditoria de som aplicada (2026-10-09; "conserte tudo"; patterns ui-grammar, feedback-sfx, world-loops):
  - [x] gramática da UI (mover/voltar/balão/contagem) · pausa abafa · prévia de volume no próprio canal
  - [x] pouso pela descida + pancada · turbo · jatinhos de giro · tosse sem gás · batida fofa · tchibum no mar
  - [x] sons próprios: baú, galão, presente, ratinho, curling no alvo, regra falhou, A BORDO, TENTE DE NOVO, chegada
  - [x] resumo: contagem com tiques + ta-dá/recorde · INDEX da biblioteca limpo (sons de mundos antigos)
  - [ ] o usuário ouvir e aprovar (batida fofa vs explosão antiga; camadas por mundo)
- [x] 18.5i Sistema de áudio v2 (2026-10-09; auditoria técnica pedida pelo usuário; patterns mix-system, web-audio-sample):
  - [x] inventário medido dos 79 WAVs + eventos; recriados só os 16 com defeito medido (pouso×4, propulsor×3, tosse,
        tchibum, cristal 3, entrega, recorde, marco, grave das músicas do Mapa e do voo, ambiência da Lua)
  - [x] mixagem que funciona na web (modo Sample): variações, camada, ducking e pausa sem efeito de bus; limitador do
        Master (desktop + web); prioridade de vozes, limite por som/família, intervalo mínimo; opção "Geral"
  - [x] testes: tests/test_audio_assets.py, sound_flow ampliado, gravação da mixagem real (desktop) e autoteste web
  - [x] o usuário ouviu o A/B (`audio/previews/ab_v2/index.html`) e aprovou (2026-10-09: "Aprovo")
- [x] 18.6 Som por mundo (sound-design): ambiência dos 6 mundos ✔, sons das mecânicas (gelo/vento/bolhas) ✔, camada
      musical por mundo ✔ (18.5h); jingle de mundo completo ✔ (2026-10-09: motivo do tema na ocarina, opção A
      "caixinha" escolhida pelo usuário ouvindo `audio/previews/world_complete/index.html`)
- [x] 16.5 Arte (pixel-art): peças que crescem por degrau ✔ (2026-10-09: 4 versões de chama/tanque/bocal/pernas no voo e
      na NAVE, aprovadas na página `art/previews/lander_parts/index.html`; pattern ship-parts), ícones das 7 ajudas na
      Estrada ✔ (2026-10-09, `assist_icons.py`; Estabilizador, troféu e selo de Reputação já tinham arte);
      sons (sound-design) ✔ (2026-10-09, opção A de cada numa página no navegador; pattern step-sfx): parada da estrada
      alcançada (xilofone curto), degrau de peça (catraca + boing + sinos), pouso perfeito (ding duplo que sobe)
- [~] 16.7 Auditoria da progressão (2026-10-09; usuário: progressão fraca, "só pousar", missão longa dominante, peças
      fortes demais, ordem da Estrada; relatório `balance/reports/2026-10-09-auditoria-progressao/index.html`):
  - [x] etapa 1 — economia v19: distância equilibrada (taxa fixa + d^0,7), plataformas ×1,25/×1,5, gás escasso
        (tanque/eficiência aditivos), marcos ×1,25 no degrau, cansaço 2,0, Estrada pela necessidade
  - [ ] o usuário jogar a v19 (e religar a telemetria: não grava desde 03/10; na web não chega ao disco)
  - [ ] etapa 2 — mundos em escada (pagamento e distância crescendo; ofertas acompanhando o alcance), objetivos depois
        dos 6 mundos, 3 desafios ativos (estilo Jetpack Joyride) com protótipo de tela antes
- [x] 16.8 Passeios da 1ª vez (2026-10-09): Mapa, NAVE, AJUDAS e REPUTAÇÃO explicados na 1ª aparição (opção A do
      protótipo `art/previews/map_tour/index.html`); revisão das dicas: só apontam ação possível
- [x] 16.9 Auditoria do voo (2026-10-11; usuário: "a mecânica principal é o controle e o pouso, tem que ser divertido";
  relatório https://claude.ai/artifact/WueWN5jGevt2U69BmCSQz3): giro com rampa + ímã do em pé, empuxo sentido com teto
  (economia v20 `physics.feel`), raspão que quica (2 amassados por salto), pouso duro (1,25×), Resistência ^0,25 nas
  tolerâncias, peças só melhoram no degrau (v20 `effect.step`), telemetria sem os testes. **Pendente**: o usuário jogar;
  ideia "Socorro!" (abort do arcade de 1979) como habilidade.
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
