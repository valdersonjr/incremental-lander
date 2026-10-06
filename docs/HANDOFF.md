# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-10-06)
- **Fase 14 — Só a Lua + árvore de missões (2026-10-06)**. Pedidos: "polir ao máximo o primeiro [mundo] e ignorar os
  outros"; prestígio "era pra ter sido removido"; missões abstratas com estrelas.
  - **Etapa A ✅ (14.1)**: saíram prestígio (Poeira, loja, recomeço), Silvânia/Docelândia/Quarto (arte, ambiência,
    perigos, terreno, temas de UI), Expedição, minério e a tela final. Economia **v11** (Frota 8M, Piloto 16M pede
    1 drone); save **v2** com migração (descarta os campos antigos); hangar = NAVE + AJUDAS + faixa de RECORDES no topo;
    sandbox só na Lua. Verificado: 86 testes + integrações, paridade 18 grupos, demo sem erros, capturas do hangar
    (início e fim de jogo). O simulador `econ.py` segue genérico (planetas/prestígio) para quando os mundos voltarem.
  - **Etapa B ✅ (14.2)**: economia v12, `EconMath.mission_*`/`draw_mission`, `RunState` (offer_mission, estrelas, táxi
    `leg2_m`), `Flight` (regras por estrela, táxi em 2 trechos via `set_target(..., stage)`, Pesada = `Lander.load_div`),
    HUD (relógio/peso/passo do táxi), pedidos (figura da missão + estrelas dela), aba **PEDIDOS**, resumo "+N estrelas",
    save com `stars/mission_nodes/missions_new`. Verificado: 93 testes + integrações (fluxo estrela → liberar → destaque
    → jingle em release_fixes), paridade 24, demo com táxi/cabo/pesada/rápida/dupla sem erros, capturas da aba e do HUD.
    **Corrigido**: SaveManager ligava no executor de testes (lia o save real; um teste com sinal de save podia
    gravar por cima) → desligado para tudo de `res://tests/`; executor não trava mais com script que não compila.
    **Calibrar jogando**: o piloto do demo falha Rápida ★1 em saltos de ~9 km (prazo 1× = o antigo do sorvete) e o
    Cabo ★3 sempre racha; resgate ★1 o demo nunca pega (já era assim).
  - Tabela da v12 (detalhes no GDD):
    | Tipo | ★1 | ★2 | ★3 | Falhou |
    |---|---|---|---|---|
    | Simples (sempre) | ×1 | — | — | — |
    | Pesada (motor ÷) | ÷1,3 ×1,2 | ÷1,6 ×1,45 | ÷2,0 ×1,8 | (física) |
    | Pouso suave (V.VERT ≤ % do limite) | 70% ×1,2 | 50% ×1,4 | 35% ×1,7 | ×0,5 |
    | Rápida (relógio × tempo ideal) | 2× ×1,2 | 1,6× ×1,4 | 1,3× ×1,7 | ×0,6 |
    | Passageiro | resgate passando ×1,3 | táxi: pousar p/ buscar + deixar ×1,5 (2 trechos) | táxi parada longe/estreita ×1,8 | ×0,6 / 1º trecho |
    | Cabo | curto/leve ×1,4 | longo ×1,7 | longo/pesado ×2,0 | ×0,6 |
    | Dupla | 2 regras, mult somado (teto ×3) | | | a da regra que falhou |
    Estrelas: 1 ⭐ por entrega concluída sem batida; 3 ⭐ liberam um nó na aba PEDIDOS (árvore: ★1 de Pesada/Suave/Rápida
    abertas; Passageiro/Cabo ★1 pedem 2 tipos ★1; ★N pede ★N-1; Dupla pede ★3 em 2 tipos). Tipo recém-liberado aparece
    mais nas 2 runs seguintes. Números são ponto de partida (simular; calibrar a física jogando).
  - **Etapa C ✅ (14.3)**: 7 ratinhos (rat_simple/heavy/soft/fast/passenger/tow/double no atlas kids; aprovados) no
    pino/cartão do pedido e na aba PEDIDOS; ícones weight/clock/star no atlas das cargas (HUD e pinos); som `star`
    (opção A: sino duplo D6→A6, 0,55 s depois do "entregue"); liberar missão toca o jingle `unlock`.
    **Pendente**: o usuário ouvir A/B/C (arquivos enviados ao celular) e confirmar; 2–3 itens decorativos por tipo
    (ex.: suave = bolo/ovo/vaso) ficaram para depois (hoje cada tipo tem uma figura); calibrar Rápida/Cabo jogando.
  - (plano original da Etapa C): 6 ratinhos (Simples mineiro amarelo de capacete · Pesada ratão laranja de cinto · Suave
    confeiteira rosa · Rápida sorveteiro azul de boné · Passageiro de boné e bandeirinha · Cabo ratinha lilás com
    corda), 2–3 itens da Lua por tipo, ícones peso/relógio/estrela; sons de "ganhou estrela"/"liberou" (do goal.wav).
- **Presentes no alto do morro (2026-10-06, ROADMAP 13.4)**: usuário escolheu "interagir com coisas do mapa". Metade dos
  saltos tem galão de gás ou presentinho no ponto mais alto do relevo entre as plataformas; encostar devagar pega.
  Economia v10 (`contracts.gifts`), `Gifts` + Flight, arte nova no atlas de cargas (`gift`, `gas_can`, aprovação pendente),
  som reaproveitado (crystal_3). Verificado: 103 testes + 8 integrações, paridade 22, prévia `tests/visual/gift_preview`.
  **Pendente**: usuário jogar (raio 18 m / 6 m/s está bom? presente aparece demais/de menos?); som próprio de "pegou".
- **Fase 13 — Simples e com ajudas (2026-10-05)**: pedido "tirar essa porra de cristal e refinaria, não vi mta diversão"
  + árvore de atributos que facilita a vida (setinha → cor de chegando → rota traçada…); "a ideia do jogo é ser simples".
  - Economia **v9**: sem `contracts.pickups` e sem `refinery`; pay_base 9,5; 7 ajudas (`upgrades[].assist`), compra única,
    persistentes no prestígio, em cadeia (`requires_upgrade`). MC 3×3: término casual/engaged/expert 4,16/3,88/3,20 h.
  - Jogo: `Assists` (puro: arco ideal, queda prevista, veredito, cor, gás na chegada), `AssistView` no Flight, marquinha
    de gás no HUD, aba **AJUDAS** na oficina (`Hangar._add_assists` + `AssistIcon`), ligar/desligar em
    `GameState.assist_on/set_assist` (settings `assists_off`). Setinha grátis para todos.
  - Removidos: `crystals.gd`, integração crystal_flow, coluna `crystals` da telemetria, cartão da Refinaria.
    Sprites/sons de cristal seguem no disco (crystal_3 ainda toca no resgate do ratinho; crystal.png sem uso).
  - Verificado: 98 testes + 7 integrações verdes, paridade 20 grupos; capturas da aba AJUDAS e de um voo demo com
    todas as ajudas (seta muda de cor, rota dourada, queda prevista colorida, marquinha de gás).
  - **Pendente**: o usuário jogar e aprovar; figurinhas finais dos cartões (hoje `_draw`); ideia do usuário de
    **interagir com coisas do mapa por recompensa** (propostas levadas a ele, aguardando escolha — ROADMAP 13.4).
- **Fase 12 — Lua mais divertida (2026-10-05)**: pedido "o que não existir no nosso jogo, adicione de forma divertida e
  dada a temática do mapa (só a Lua)" + "tira todos coelhos e alienígena do mapa". Feito:
  - Economia **v8** (`contracts.cargo` só na Lua + habilidades `stabilizer`/`turbo`), espelho EconMath, paridade 21 grupos.
  - Pedidos para os **dois lados** (world.json `routes.luna.left_chance` 0,45; pinos na borda esquerda abaixo do HUD).
  - **Cargas**: bolo (pouso ≤ 3 m/s), sorvete (prazo real = 10 + 0,35·√d s, conta só voando), queijão no cabo
    (`CargoTow`, cabo 26 m, massa 0,6, racha > 6 m/s), ratinho (raio 20 m, velocidade < 4,5 m/s). Falhar paga menos.
  - **Habilidades**: Estabilizador (S/↓) e Turbo (Shift), remapeáveis, controle B / X+LT; botões embaixo da nave.
  - **Arte**: `art/src/sprites/cargo.py` → `assets/sprites/cargo.png` (cargas + versões estragadas + ícones); Lua sem
    coelhos (vila/parque dos ratinhos) e sem alienígenas (já não havia nave-mãe/discos; sprites war_* seguem no disco,
    sem uso: saucers 0).
  - Verificado: 95 testes + 8 integrações verdes; demo na Lua sem erros; capturas do queijão, do resgate, dos pinos à
    esquerda e da oficina. **Pendente**: o usuário jogar e aprovar (sensação do cabo, prazo, raio do resgate, arte das
    cargas); sons próprios (hoje reaproveita crystal_3/denied); o autopiloto do demo não pega o ratinho.
- **Trabalho anterior não commitado incluído no commit da Fase 12** (sessão de 2026-10-05 antes desta): menus para
  crianças (pedidos no mundo, oficina), nomes de atributo, mina de queijo (trecho 1), nuvens — ver DECISIONS 2026-10-05.
- **Direção de arte FOFA/COZY (2026-10-04)**: usuário quer o jogo "todo fofinho", referência Shelldiver. Teste de paleta
  (Resurrect 64 × comfy52) mostrou que a fofura vem do traço → **paleta mantida**. Regras em
  `.claude/skills/pixel-art/references/patterns/cute-style.md` (rosto, contorno escuro no primeiro plano, cor chapada,
  formas redondas, fundos simples). **Lander novo com gatinho astronauta aprovado e no jogo** (`art/src/sprites/lander_cute.py`
  → `assets/sprites/lander.png`; idle pisca; mesmo contrato 32×32, pés y=24, half_width 13 — sem mudança de física).
  **Lua refeita e aprovada no jogo** ("Lua de queijo", `art/src/bg/moon_cute.py --export`) com o método de
  `.claude/skills/pixel-art/references/cute-scene-method.md` (kit desenhado em meia resolução + Scale2x).
  Fundo dos morros em **3 trechos** (laço de 1920 px, `war.period` no JSON): mina dos ratinhos · vila dos coelhos ·
  parquinho (peças em `art/src/bg/moon_props.py`). Regra: todo objeto tem um porquê no lugar (escada desce num poço,
  varal preso nas duas pontas, balão amarrado).
  **Pendente**: plataforma de pouso e painel do HUD (aparecem na Lua no estilo antigo), depois Silvânia, Docelândia,
  O Quarto, perigos, UI e ícone do app.
- **Pouso mais tolerante (2026-10-04)**: limites 7 m/s vertical, 5 m/s lateral, ~20° (eram 3 / 2 / ~11°); a telemetria agora
  grava vy/vx/tilt/motivo de cada toque (o CSV antigo vira deliveries_old3.csv sozinho). Depois de jogar: conferir no CSV
  se as batidas caíram e recalibrar (Fase 10.1) — a qualidade média sobe com limites maiores (demo 0,87 → 0,94).
- **Auditoria de lançamento + correções (2026-10-03)**: auditoria (QA/produção) deu NÃO PRONTO; o usuário pediu "arrume
  todos os problemas". Feito (commits 2cfbd4b, 39047ed, 6dde4a1 + docs):
  - Desempenho: `rock_spots`/`height_at` eram quadráticos (4,5 s por reconstrução no fim de jogo) → busca binária,
    laços só na faixa afetada, pedras desenhadas só na tela, extensão de borda ¼ do mapa. Pior caso ~0,1 s; saída
    idêntica ao gerador antigo (100 casos).
  - Progressão: recomeço com Cartas de navegação deixava o jogador num mundo em que a nave não decola (run acabava na
    hora "sem gás") → volta para `Purchases.best_launchable`; hangar desliga DECOLAR com o motivo; resumo "sem_alcance".
  - Save: arquivo ilegível nunca é sobrescrito (vira save.unreadable.json + aviso no menu inicial); SaveData valida
    tipos; autosave a cada entrega; pasta de dados própria `IncrementalLander` (cópia automática da antiga — o save do
    usuário já foi copiado e conferido idêntico).
  - Input/UX: Espaço fora de ui_accept (não decola sem querer pelo hangar); R/E pedem 2 toques; R ignorado na tela
    final; hangar esconde as ofertas; Esc abre o menu com recomeço pendente; teclas remapeáveis (menu do jogo, coluna
    CONTROLES); controle (A/RT, analógico, LB/RB, Start); tela cheia (opção, F11, Alt+Enter); tremor de tela opcional;
    ofertas navegáveis por setas; menu do jogo em duas colunas.
  - Frota: relógio do run sem pausa; sair do voo pelo menu/R fecha a conta do run (sem entregas não conta).
  - Pós-jogo: recordes pessoais (final, resumo, aba PRESTÍGIO); texto final sem "protótipo".
  - Áudio (aprovado ouvindo): ambiência dos 4 mundos, música título/hangar + voo, alarme de gás, jingles.
  - Build: renderer Compatibility, versão 0.9.0, ícone (aprovado), export_presets.cfg (macOS/Windows/Linux, sem tests/),
    telemetria/logs/`--dev_*` só no build de depuração. `.pck` exportado e rodado: ok.
  - Testes: 81 unitários + integração `release_fixes` (todos verdes).
  - **Ainda pendente para lançar**: (1) templates de export 4.7.2 não instalados (pasta vazia) → gerar e testar os
    executáveis numa máquina limpa; (2) calibração com humanos (Fase 10.1); (3) nome final/logo (decisão do usuário);
    (4) aprovação no jogo da arte nova (plataformas, cristal, perigos); (5) não verificado: Cmd+Q salva no macOS, monitores
    120/144 Hz, Retina/telas pequenas, Windows.
- **Fase 11 — Voo com decisões (em andamento)**: pedido do usuário "faz tudo que for sabido que deixa os gamers felizes"
  (pagamento só por distância era sem graça; nada obrigava a voar alto; andar de lado era entediante).
  - 11.1 ✅ economia v7: plataformas normal/estreita/apertada (×1/×1,5/×2,2), combo de pousos bons, cristais no arco;
    `EconMath.delivery_pay/pickup_value/combo_mult/pad_tier/draw_pad_tier/combo_counts`. **O jogo ainda paga só por
    `contract_pay`** (pay_base caiu para 8,5) até a 11.3 ligar tipos e combo — ✅ ligado na 11.3.
  - 11.2 ✅ relevo com cristas entre plataformas + pico/vale por tipo (TerrainGen já aceita `pad_tiers`) + ar denso perto do
    chão (`LanderPhysics.drag_at`); autopiloto respeita o relevo na aproximação. Perfil: `tests/tools/dump_terrain.gd`.
  - 11.3 ✅ ofertas com tipo de plataforma (coluna "plat."), sprites estreita (âmbar, traços) e apertada (vermelha, listras de
    perigo) + "×N" escrito sob a plataforma, combo no HUD, aviso com ganho/plataforma/combo; pagamento já é `delivery_pay`.
    Telemetria ganhou coluna `tier`. **Arte das plataformas novas aguarda aprovação do usuário**
    (`art/previews/landing_pad_scene_zoom.png`). Invariante: plataforma criada nunca muda (teste).
  - 11.4 ✅ 3 cristais roxos por salto **sobre o arco ideal** (mostram o caminho eficiente; desviar custa gás), coleta com
    estouro + nota que sobe (crystal_1..3) + "+X" flutuante; estalo de combo (combo_2..5) ao pousar com combo ≥ 2;
    telemetria com `crystals`. O piloto automático do demo voa mais alto que o arco ideal e não pega cristais (ok: o
    teste `crystal_flow` cobre a coleta). Calibrar com humanos a fração de coleta (modelo assume = skill).
  - 11.5 ✅ perigos por mundo (sempre avisados; ciclos em segundos reais): Silvânia rajadas laterais na altura do arco
    (folhas douradas + traços; som gust); Docelândia gêiseres de calda do chão (bolhas antes; freiam e empurram; som
    geyser); Quarto ventilador gigante (coluna de ar que ajuda) + bloquinho caindo (sombra + "!" antes; destrói; som
    toy_fall). Lua sem perigo. Economia: neutros (o run acaba pelo teto de 6 entregas, não pelo gás) — spec v7.1.
    Prévia: `tests/visual/hazard_preview -- --planet= --zone= --phase=on|warn`.
  - Mapa sem fim (2026-10-03, pedido do usuário: "se eu for muito pra direita o mapa acaba"): o terreno cresce
    sozinho quando a nave chega perto da borda, para os dois lados; nada do que já existia muda (teste edge_flow).
  - **Fase 11 concluída.** Pendências: aprovação do usuário da arte nova (plataformas, cristal, perigos) e dos sons;
    calibrar com humanos (telemetria tier/crystals); autopiloto do demo não desvia de brinquedos nem pega cristais.
- **Takes de trailer (2026-10-03)**: 19 takes de 4–10 s (1080p60 com som) + montagem bruta de 90 s, lista e ordem em
  `trailer/TAKES.md` (vídeos fora do git). Diretor `tests/visual/trailer_director.tscn` (escolhe entregas, piloto pelo
  arco dos cristais, sincroniza perigos, sem HUD/zoom opcionais); gravação `tests/tools/trailer_capture.py` (Movie
  Maker + ffmpeg do `pip install imageio-ffmpeg`, janelas lado a lado para não congelar); montagem `trailer_montage.py`.
- **Fases 0–7 concluídas; Fase 8 (arte) em andamento.**
- **Direção de arte**: futurista na nave + **cenas ricas em camadas** (o usuário reprovou terreno minimalista como
  "muito feio"; aprovou a cena da Lua (hoje em cinza clássico): céu em faixas, Terra com halo, montanhas facetadas, terreno com
  estrias e pedregulhos). Regra registrada no style-guide da pixel-art.
- **No jogo**: lander futurista + **cena da Lua completa** (cinza clássico + terreno em blocos de basalto desde 2026-10-02; fundo `Backdrop` em parallax + terreno com faixas
  cisalhadas lit/flat/shade + pedregulhos) + **plataformas** (sprite animado; alvo com feixe de luz, pista
  iluminada e marcador) + **explosão na batida** (a entrega só termina depois dela) e **poeira em cada pouso**. **Mundos**: Lua (`moon_scene.py`), **Silvânia** = floresta fechada (id ares, `forest_scene.py`), **Docelândia** = planeta
  dos doces (id kronos, `candy_scene.py`), e **O Quarto** = quarto bagunçado (id titan, `room_scene.py`; meta final "Expedição ao Quarto"),
  todos **animados**.
- **Som (Fase 9 iniciada)**: propulsor plasma suave + pouso, batida, entrega, clique, compra, negado (autoload `Sound`).
- **Menus revisados (2026-10-02)**: hangar em abas NAVE/MUNDOS/PRESTÍGIO (Q/E), Expedição fixa no topo, menu do jogo no Esc
  (Esc); HUD com aviso central de pouso/batida. Prévia: `hangar_preview -- --late --top --tab=1|2`.
- **Menu inicial (2026-10-02)**: o jogo abre no título sobre a cena do mundo atual; Continuar/Novo jogo/Opções/Sair.
  Prévia: `tests/visual/title_preview -- --progress --planet=kronos`. O teste de controles passa pelo menu (Enter).
- **Auditoria de UX (2026-10-02)**: todas as telas revisadas só na apresentação/interação (padrões em
  `godot-dev/references/ui.md` §"Padrões de interação"); saída do demo idêntica antes/depois (nenhuma regra mudou).
  Prévias novas: `hangar_preview -- --late --top --pending|--keys`, `summary_preview -- --crash`.
- **Modo sandbox (2026-10-03)**: menu inicial → Sandbox (mundo + nave) → hangar com tudo liberado e recursos repostos;
  nada é salvo, sem telemetria; "Sair do sandbox" no menu do jogo devolve o jogo verdadeiro. `scripts/save/sandbox.gd`,
  `data/world.json > sandbox`. Teste `sandbox_flow`. Prévias: `title_preview -- --sandbox`, `flight_ui_preview -- --no_title
  --sandbox [--hangar|--hangar_menu]`.
- **Filtro CRT (2026-10-03)**: ligado por padrão (autoload `Crt`), "Filtro CRT Ligado/Desligado" nas opções do título e no
  menu do jogo; salvo em settings.json.
- **Esc no hangar (2026-10-03)**: sem botão "Menu" no canto (pedido do usuário); abre o menu do jogo (`PauseMenu` modo HANGAR) com o hangar escondido — o usuário reclamou
  que o Esc "mostrava o hangar" (a antiga aba OPÇÕES ficava dentro do hangar). Teste `tests/integration/esc_flow`.
  Prévia: `flight_ui_preview -- --no_title --hangar_menu [--confirm]`.
- **Menu inicial a partir do voo (2026-10-03)**: o usuário não tinha como voltar ao menu principal de dentro do voo; a
  PAUSA (Esc) agora tem "Menu inicial" (salva; o run acaba, as entregas feitas já foram pagas). "Novo jogo" segue só no
  hangar. `esc_flow` cobre (voo → Esc → Menu inicial → título, sem pausa presa).
- **Sem dica de teclas no voo (2026-10-03)**: o rodapé do HUD não mostra mais "W/Espaço: propulsor..." (pedido do usuário:
  "o menu do Esc já oferta todas as opções" — as teclas estão em CONTROLES); o rodapé só aparece com o resultado do pouso
  ou a marca SANDBOX. A dica da escolha de entrega no painel de ofertas continua (é instrução do momento).
- **2ª auditoria de UX (2026-10-02)**: pausa no voo (Esc ou janela sem foco; `game/pause/`), dica de teclas em painel,
  cabeçalho nas ofertas, foco no resumo, formatos do hangar unificados, `fmt(1e6)`="1.00M". Regras intactas (demo idêntico).
  Prévia: `tests/visual/flight_ui_preview -- --no_title [--pause] [--delivered|--crashed]`. `controls_test` cobre a pausa.
- **Vários jogos salvos (2026-10-02)**: 3 espaços; menu inicial → "Jogos salvos" (jogar / novo jogo / apagar). Jogo 1 =
  o save.json de sempre. Prévia: `title_preview -- --progress --saves [--confirm]`. Testes: save_roundtrip + slots_flow.
- **Interface**: kit pixel (fonte com acentos, painéis, botões, barras, ícones) em todos os menus; cor muda com o mundo
  (`UiKit.theme_for`). Prévias: `tests/visual/{hangar,summary,ending}_preview` (args `--planet=`, `--top`).
- **Travas da Regra 0**: hooks bloqueiam ações numa área sem a skill dela; pre-commit valida assets/economia.

## Próximo passo
- **Jogar a Lua nova** (Fase 12.6): conferir cabo/sorvete/ratinho/bolo e as habilidades; ajustar `data/world.json > cargo`.
  Capturas de verificação: `gdtool capture res://game/main.tscn -- --demo --planet=luna --dev_cargo=towed --dev_dir=-1`.
- **Arte fofa (2026-10-04)**: Lua ✅. Próximo: **plataforma de pouso** (normal/estreita/apertada + feixe + marcador)
  e **HUD** no estilo fofo; depois os outros mundos com a receita `cute-scene-method.md`. Mostrar sempre em página
  HTML aberta no Chrome, com capturas do jogo.
- **Lançamento**: instalar os templates de export (Editor → Gerenciar templates → Baixar 4.7.2), exportar macOS e
  Windows (`godot --headless --export-release "macOS" builds/mac/...`), testar numa máquina limpa; jogar 1–2 h e calibrar
  (Fase 10.1, telemetria em ~/Library/Application Support/IncrementalLander/telemetry/); decidir nome/logo.
0. **Lua em guerra (2026-10-02, feito)** — só cena de fundo, sem história/progressão (decisão do usuário).
   Opcional depois: sons distantes da batalha (sound-design).
1. ~~**Perigos por mundo**~~ ✅ feito na Fase 11.5 (2026-10-03). Próximo sugerido: jogar e calibrar (Fase 10.1) com a
   telemetria nova (tier, crystals); depois Fase 9 (som) continuação. Texto antigo do item:
   **Perigos por mundo (aprovado em princípio, 2026-10-01: "pode ser")** — Lua nenhum; Floresta galhos/cipós + vento;
   Doces calda que gruda e freia; Quarto objetos caindo + ventilador. Planejar com economy-balance (custo de gás/risco),
   godot-dev (física/obstáculos) e pixel-art (sprites). Antes: confirmar com o usuário que os controles funcionam.
   (Contexto: pergunta "o jogo é só sair de um lugar e pousar em outro?") —
   ver plano em `~/.claude/plans/a-ideia-do-jogo-cryptic-boot.md` e a resposta na conversa; definir com o usuário
   antes de seguir (envolve economy-balance + godot-dev + pixel-art).
2. Fase 9 — som, continuação: ambiência de cada mundo (Lua, floresta, doces, quarto), música, jingles,
   alarme de gás baixo. O usuário prefere não auditar som por som: gerar seguindo a skill e tocar um resumo.
Lua: terreno v3 (crosta + basalto) resolveu os cortes verticais. (Lua repintada em cinza clássico em 2026-10-02 —
opções descartadas em `art/previews/moon_recolor/grid.png`.)

## Como jogar no editor (lembrar o usuário)
- Play → **clicar dentro da tela do jogo** (o jogo roda embutido na aba Game do Godot 4.7) → escolher a entrega com
  **1–8, setas + Enter ou clique** → **W/Espaço** propulsor, **A/D** girar, **R R** reinicia, **E E** encerra o run
  (teclas remapeáveis no menu do Esc; controle também funciona). Dados do jogo: ~/Library/Application Support/IncrementalLander/.

## Pendências conhecidas
- Save do jogador sobrescrito por engano por uma prévia (2026-10-02): causa corrigida no SaveManager; o usuário já
  restaurou o save reconstruído (Lua, sem upgrades, 0 cr — como mostrava a telemetria).
- "Alcance max (ideal)" no hangar é otimista (delta-v ideal); ao saturar mostra "> 1000K m".
- Calibração: gasto de gás humano × modelo virá dos testes manuais (Fase 10).
- Terreno regenerado inteiro a cada entrega e a cada extensão de borda (sem chunks) — ok até ~30 km testados; rever se ficar lento.
- Telemetria antiga (antes da coluna pilot) misturava demo e humano: foi para `deliveries_old.csv` — não usar na calibração.
- Autopiloto do demo às vezes pousa fora da plataforma em Titan (gravidade 15) — só afeta verificação.
- Em aberto no design: pós-jogo, nome final (GDD §12). Menu inicial usa título em texto; logo em pixel art
  (pixel-art) e música de título (sound-design) ficam como polimento opcional.

## Como retomar (checklist de sessão nova)
1. Ler `CLAUDE.md` (carregado automaticamente) → este arquivo → `docs/ROADMAP.md`.
2. Identificar a skill da tarefa e ler o `SKILL.md` dela antes de agir (código → `godot-dev`).
3. `git log --oneline | head` para ver o último commit; `git status` para mudanças não commitadas.
4. `python3 .claude/skills/godot-dev/scripts/gdtool.py check && ... test` para confirmar que está tudo verde.
5. Clone novo? Ativar o pre-commit: `git config core.hooksPath .githooks` (os hooks do Claude Code já vêm em `.claude/settings.json`).
   Se uma ação for BLOQUEADA pela Regra 0, invoque a skill indicada (ferramenta Skill) e repita — não contorne a trava.
