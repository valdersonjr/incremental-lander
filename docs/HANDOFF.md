# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-10-11)
- **Música da Lua trocada** pela "Passeio no queijo" (`flight_luna.wav`; `Sound.music("flight", mundo)` usa
  `flight_<mundo>.wav` quando existe, senão base + camada). Outros mundos seguem com o voo antigo + camada.
- **Fase 19 "Mais longe" — jogável (usuário escolheu a opção C e aprovou as regras: "pode ser, faz que eu analiso")**.
  Economia v21 (`contracts.track`; relatório `balance/reports/2026-10-11-v21-track/`) + espelho `EconMath.track_*`
  (paridade 48). No jogo: a viagem é uma pista fixa por mundo, só para a frente, sem cartão: plataformas em sequência
  (pulo = +25%), pagamento pela distância do começo, relevo/morros crescendo com a distância (é o que encerra a
  viagem), galões, moedas no ar, placas a cada 250 m (bônus 1ª vez), bandeira do recorde, estrelas = nota do pouso
  (1/2/3 → Estrada ×5), HUD com distância + recorde, aprendiz (< 10 estrelas) volta à última plataforma. Verificado:
  check (106), 123 testes, integrações (onboarding_flow reescrito para a pista; controls/release_fixes adaptados),
  demo na Lua (7 pousos/1,1 km com galões) e no Jardim, capturas (moedas, placas, "POUSOU! +3 estrelas", "NOVO
  MARCO!"). **Para o usuário**: jogar e analisar. **Pendências**: 19.4 (mundos na NAVE em vez do Mapa, Estrada como
  barra, fim de viagem com distância em destaque), 19.5 (ratinhos/minijogos como trechos; arte própria de moeda/placa/
  bandeira e sons), calibrar `rough_scale`/gás com telemetria (o modelo é chute), tecla E (terminar viagem) sem uso
  na pista, publicar no Vercel quando o usuário pedir (reteste do amigo). Código antigo (cartão/missões/minijogos)
  continua no projeto, só não roda no modo pista.
  **Correções depois do 1º teste do usuário**: plaquinha "+N" (pouso bom) em cima das 6 próximas plataformas; ouro
  só no pouso (moedas no ar/marcos ficam "+N ao pousar"; distância = até onde pousou); crash ao aprimorar a nave
  (`ShipView._draw`: ternário com Array[Rect2] — bug antigo, só aparece com tela; teste novo `buy_flow` + captura).
  **Ouro acumulado (v22)**: o painel de cima mostra "+N a receber" crescendo com o chão novo (fronteira paga
  `track_banked_m`), o pouso paga acumulado × nota × plataforma; plaquinhas mostram o acumulado ao chegar em cada uma.
  Fim do "tente de novo" infinito (máx. 2 por salto). Contra o arremesso (2,9 km com 51 de gás no teste do usuário):
  teto (v23) e gasto por distância (v24) rejeitados; **v25**: tanque base 45, peças Gasolina/Eficiência a 30%, galão
  fixo 12, arremesso aceito como habilidade. Demo: 2 pousos/340 m/~350 de ouro no 1º voo. Modelo: viagem 0,8 → 6,8 km
  no jogo todo, compras a cada ~7,7 min (esperas de 7–12 min perto de 0,9 h). Calibrar com o próximo teste.
  Sem gás para a próxima plataforma (estimativa do piloto ideal + galões no caminho, folga 10%) = fim da viagem na
  hora ("O GÁS NÃO DÁ!"), e o aprendiz só repete o salto se o gás do começo dele alcança (`Flight.track_can_reach`).
  **v26–v27**: velocidade máxima 45 m/s (aviso "velocidade máxima!"), bônus fixo por pouso + sequência de pousos
  (HUD "a receber: pouse! sequência ×1,4"; aviso "124 ×2,9 = +358"). Modelo agora testa arremessos e estilos.
  **v28 (ideia do usuário)**: metro paga 0,3 fixo e cada plataforma pousada soma +1 no multiplicador da viagem.
  Dica: o log da sessão de jogo fica em `~/Library/Application Support/IncrementalLander/logs/`.
- **Auditoria de clareza (aguardando escolha do usuário)** — um amigo (jogador experiente) testou a web e não entendeu
  o loop ("planeta tem vários mapas, mapa tem missão"; só entendeu "1 tanque = 1 run, pontuação = moedas" pelo chat).
  Página `art/previews/clareza/index.html` (publicada: https://claude.ai/artifact/FxVbgBPYA478S6mdTL3rhT): diagnóstico
  (viagem sem começo/fim, cansaço 2× invisível, "estrela" com 3 sentidos, escolhas antes de entender, 20+ conceitos
  em 10 min) + 3 propostas com mini-protótipo jogável (A arrumar o atual · **B viagem contínua, recomendada** · C mais
  longe/distância). **Próximo**: o usuário escolhe → `economy-balance` simula a proposta → implementar em etapas →
  reteste com o amigo.
- **Destaque "Aceite!" deixa ler a missão** — usuário: a tela escurecia o cartão e o balão cobria as opções, sem dar
  para ver o que estava aceitando. `Spotlight.point(..., area)`: a luz cobre o cartão inteiro (`OfferPanel.card()`),
  dá para ler e escolher distância/plataforma; o botão ganha só a moldura dourada e a maozinha (sem balão). Verificado:
  check, 122 testes, 17 integrações, captura do cartão. **Publicado no Vercel** (com a auditoria do voo; pck
  idêntico ao local, autoteste de áudio até WEBTEST FIM).
- **Auditoria do voo aplicada (ROADMAP 16.9; economia v20)** — usuário: o controle e o pouso são o foco e têm que
  ser divertidos; pediu validação profissional + pesquisa ("faz o que precisar") e que **a nave só evolua quando o
  degrau sobe**. Relatório: https://claude.ai/artifact/WueWN5jGevt2U69BmCSQz3. Feito: giro com rampa + ímã do em pé
  (`world.json > rotation`); empuxo sentido com teto (`economy.json > physics.feel`, `EconMath.felt_thrust` =
  `econ.felt_thrust`); raspão que quica fora da plataforma (2 amassados por salto, pisca vermelho, som `bump`,
  `LandingRules.scrape_bounce`, `Lander.scraped`); pouso duro até 1,25×; `gear_exp` 0,25; peças só no degrau
  (`effect.step` 10; `Purchases.upgrade_rows` mostra o próximo degrau); testes/`--dev_*`/`--no_save` não gravam
  entregas (o CSV ganhou `scrapes`/`hard` → o arquivo poluído vira `deliveries_old*.csv` na próxima gravação).
  Medido (v20, 6 h): mundos ~15% mais tarde, paredes ≤ 10 min, 1ª compra igual. Verificado: check (106), 122 testes,
  17 integrações (nova `flight_feel`: raspão, 3º explode, forte explode, pouso duro vale, muito duro bate), paridade 44,
  demo (Lua/Sorvete com nave forte entregam). Já existia antes: o demo no Jardim com nave forte aceita 12,7 km Pesada
  e fica sem gás (só o piloto do demo). **Para o usuário**: jogar e dizer se o giro/raspão estão bons (números em
  `world.json`); ideia pendente "Socorro!" (abort de 1979) como habilidade.
- **Estrada das Estrelas só no Mapa** — usuário: a barra aparecia em todos os menus (alto da NAVE, nas 4 abas, + Mapa).
  Agora só no Mapa: balão da parada (`scripts/ui/stop_balloon.gd`, acima da parada), navezinha andando até as estrelas
  novas e festa das paradas novas (o Mapa já tinha `_celebrate_news`). NAVE: `SHOW_ROAD = false` esconde o painel e não
  festeja (voltar = true). Verificado: check (105), 116 testes, 16 integrações, demo, capturas (NAVE sem a faixa; balão
  no Mapa — `world_map_preview -- --sel=<parada>`). Também publicado no Vercel antes disso: os passeios da 1ª vez.
- **Passeios da 1ª vez (ROADMAP 16.8)** — usuário: o "Mapa!" da NAVE mandava ao Mapa sem nada para fazer; faltava explicar
  a NAVE e as AJUDAS. Protótipo `art/previews/map_tour/index.html` → opção A (passeio). `Spotlight.tour` (balões em
  sequência, clique/tecla avança, Esc pula, último passo = ação). Mapa (mundos → Estrada → moedas/estrelas → NAVE →
  Voe!), NAVE (peça → bolinhas/degrau → abas → Compre!/Decole!), AJUDAS e REPUTAÇÃO ao abrir a aba. Revisão de todos
  os fluxos: saíram "Mapa!", "Ajuda!"+"Liga/desliga", "Novo!" da REPUTAÇÃO; FROTA só quando dá para comprar.
  Corrigido também um erro de tipo no balão que só aparecia desenhando. Verificado: check (104), 116 testes, 16
  integrações (onboarding_flow cobre os passeios; esc_flow/controls_test como veteranos), capturas de todos os passos
  (`art/previews/map_tour/game/`). **Para o usuário**: ver no jogo (saves existentes também verão o passeio uma vez).
- **Auditoria da progressão — etapa 1 aplicada (economia v19; ROADMAP 16.7)**. Usuário jogou e achou: progressão
  fraca, "só pousar", missão longa dominante, peças fortes demais, ordem da Estrada estranha; pediu pesquisa. Relatório
  com medição + referências (apps de transporte, Euro Truck, AdCap, Lunar Lander Beyond, Jetpack Joyride):
  `balance/reports/2026-10-09-auditoria-progressao/index.html`; usuário aprovou o pacote. v19: pagamento = 43 × (0,3 +
  (d/100)^0,7), plataformas ×1,25/×1,5, tanque +8 e eficiência +0,15 por nível (aditivos), marcos ×1,25 a cada degrau
  de 10, cansaço do run 2,0, Estrada reordenada (Dá pra chegar? na Lua; Sombra/Rastro nas Nuvens; Turbo/Nivelador nos
  Cogumelos). Medido: longe+apertada 17× → ~2,7× por gás; run do modelo ~23 → ~4–5 min; intervalo entre compras
  19,5 → 5,6 min; MC 3×3 mundos 2,6/2,8/3,1 h (expert/engaged/casual). Verificado: paridade 43, 116 testes (2 testes
  de compras passaram a ler a spec), 16 integrações, demo, captura do cartão (perto +154; longe "falta gás" no começo).
  **Pendências**: (1) o usuário jogar a v19 — publicada no Vercel (hashes e autoteste conferidos); (2) telemetria só grava em build de
  desenvolvimento: para calibrar, uma sessão local (o voo real leva ~1,8× o modelo); (3) **etapa 2**: mundos em escada
  (ofertas acompanhando o alcance, faixas maiores), objetivos depois dos 6 mundos, 3 desafios ativos — protótipo de tela
  numa página antes.
- **Sons do progresso (fecha o ROADMAP 16.5)** — usuário escolheu "tudo letra A" na página `audio/previews/step/index.html`
  (atual/A/B, sozinho e no jogo): `road_stop` (xilofone curto) em toda parada nova da Estrada (Sound._on_road_reached,
  festa da NAVE e do Mapa; `unlock` fica só no 1º drone), `part_step` (catraca + boing + sinos) quando a peça sobe de
  degrau (milestone continua nos marcos), `Sound.perfect(sequência)` no pouso perfeito (sobe 0/2/4/7/9 semitons;
  `combo_2..5` apagados). Fonte `audio/src/sfx/step_sfx.py`, pattern step-sfx. Verificado: check (104), 116 testes,
  16 integrações (sound_flow: parada, perfeito 1 e 3), test_audio_assets (79 ok), demo. **Publicado no Vercel**
  (commit 3a68b8f; hashes conferidos e autoteste de áudio na URL pública). **Próximo**: 16.6 — o usuário joga e aprova.
- **Peças que crescem por degrau (ROADMAP 16.5, parte de arte)** — aprovadas pelo usuário na página interativa
  `art/previews/lander_parts/index.html` ("Boa, gostei"). Gasolina = bolotas nos ombros do disco; Eficiência = bocal
  sino → anel aqua → anel dourado + aletas; Resistência = sapata redonda → mola → almofada; Motor = chama maior.
  4 versões (degrau 0 / 1–2 / 3–5 / 6+; Resistência 1:1, `world.json ship_parts`). Voo: `Visual` toca
  `b_<tanque><bocal><pernas>` (lander_body_frames.tres) e `%Flame` (lander_flame_frames.tres) fica atrás, na boca do
  bocal; o Main manda `stats["parts"]` (o Flight continua sem ler o GameState). NAVE: `ShipView` desenha o pôster do
  atlas + chama, destaque dourado por peça (uma caixa por lado). Versão 0 = nave antiga pixel a pixel (assert no
  script). Verificado: check (104), 116 testes (novo `test_ship_art`), 16 integrações, demo, capturas do voo com tudo no
  máximo e da NAVE com destaque. Também: redeploy no Vercel (áudio v2 + jingle) verificado na URL pública.
  Ícones das 7 ajudas na Estrada também feitos e aprovados (`art/src/ui/assist_icons.py` → fim do `kids.png`;
  Estabilizador, troféu e selo de Reputação já tinham arte). **Próximo**: sons do 16.5 (parada alcançada, degrau de
  peça, pouso perfeito) — FEITO (ver item acima).
- **Jingle de mundo completo (ROADMAP 18.6 fechado)** — `world_complete.wav` (3,9 s): motivo do tema do gatinho na
  ocarina + marimba + cadência Lá → Ré + "ta-dá" de sinos. Toca na parada `complete_<mundo>` da Estrada (última estrela),
  no lugar do `unlock` (`Sound._on_road_reached`); a viagem no Mapa continua com o `goal`. Usuário escolheu a opção A
  ("caixinha") de 3 numa página no navegador (`audio/previews/world_complete/index.html`; B e C ficam no script,
  `progress_sfx.py --options`). **Regra nova do usuário**: escolha de som = página HTML aberta no Chrome (solo + no
  contexto), nunca afplay + pergunta no terminal. Verificado: check (102), 111 testes, 16 integrações (`sound_flow`:
  mundo completo toca o jingle, parada comum toca unlock), `test_audio_assets` (80 ok). **Próximo**: ver ROADMAP
  (16.5 arte das peças/ícones é o próximo item aberto); redeploy no Vercel só quando o usuário pedir.
- **Sistema de áudio v2 (ROADMAP 18.5i)** — usuário pediu auditoria técnica completa; aprovou "recriar só o que tem
  defeito medido" e "manter o modo Sample na web adaptando o sistema". Inventário medido dos 79 WAVs: 16 recriados
  (pouso×3 + forte, propulsor×3, tosse, tchibum, cristal 3, entrega, recorde, marco, grave de title/flight, ambiência
  da Lua); os outros 63 idênticos byte a byte (tema da ocarina intacto). Originais em `audio/previews/before/` (local)
  e no git. `Sound` reescrito por dentro (API igual): variações sem `.tres`, camada do mundo em player gêmeo, ducking e
  pausa por volume (web não tem efeito de bus), 10 vozes com prioridade, limite por som/família, intervalo mínimo,
  opção "Geral" (bus Master); HardLimiter no Master (desktop) e `web/audio_limiter.js` no `html/head_include` do preset
  Web. **Atenção**: o preset Web só existe na alteração NÃO commitada do usuário em `export_presets.cfg` (trocou
  macOS/Windows/Linux pelo Web); o arquivo ficou fora do commit e, no working tree, ganhou a linha `html/head_include`
  com o limitador. Ao commitar o preset Web, ela vai junto (o teste de áudio confere se houver preset Web). Verificado: check (102), 111 testes, 16
  integrações (`sound_flow` com 23 checagens), `tests/test_audio_assets.py` (79 ok; nos antigos acusa os 11 defeitos),
  hooks, demo; mixagem real gravada (desktop: +0,3 dBTP com 45 amostras clipadas → −0,8 dBTP, 0 clip); web local em
  Chrome headless (`?audiotest`): tudo como sample, camada alinhada 0,0 ms, ducking/pausa, rajadas limitadas, saída
  ≤ −0,3 dBFS por canal (entrada chegava a +2,6). **Aprovado pelo usuário ouvindo o A/B** ("Aprovo");
  redeploy no Vercel só quando pedir. Próximo: feito (jingle de mundo completo, acima).
- **Tela inicial nova: "Noite de história"** (usuário achou a Vitrine "pacata e não tão bonitinha"; 4 estilos no
  navegador `art/previews/title_styles/index.html` → escolheu a Noite; tema mais lento → 68 BPM em
  `title_styles/noite.html`). Gatinho sentado na lua crescente de queijo pescando uma estrelinha que dorme, ratinho de
  companhia, céu noturno, banco de nuvens. `art/src/title/title_night.py` (desenho em `title_styles.py`), TitleBackdrop
  reestruturado (Back = lua + pescador; Front = nuvens + banco), tudo no compasso do tema (68 BPM, `Sound.BPM`).
  Verificado: check, testes, `title_backdrop` (`pescador_na_lua`, `gato_no_ritmo_do_tema`), captura no jogo.
  **Para o usuário**: rodar e aprovar. Os assets da Vitrine ficaram no projeto (a NAVE usa `title_lander.png`).
- **Tela inicial no ritmo do tema** (usuário: "a tela inicial tá combinando com o ritmo da música?"). `Sound.music_beat()`
  (posição real + tempo desde a mixagem − latência); TitleBackdrop escolhe o quadro pela fase: gatinho 1 compasso,
  bandeira 2 tempos, luzinhas da nave 1 compasso, estrelas acendendo em colcheias, nuvens 4 compassos, estrela cadente
  no 1º tempo; logo sobe 1 px nos tempos 1 e 3. Ocarina + sem vento de fundo (tela inicial sem ambiência, Lua sem ar).
  Verificado: check, testes, `title_backdrop` (novo `gato_no_ritmo_do_tema`), captura. **Para o usuário**: ver/ouvir.
- **Tema do gatinho na tela inicial** (usuário: "a tela inicial do gatinho deveria ter uma música, não?"). Tocava a
  faixa calma do Mapa/NAVE, só pad + sino e 83% grave: no notebook parecia muda. Novo `theme.wav` (D maior, 92 BPM,
  24 compassos, melodia cantarolável, baixo com harmônico audível) só na tela inicial; Mapa e NAVE seguem com `title`.
  Usuário comparou 6 timbres no navegador (`audio/previews/theme_options.html`) e escolheu **D ocarina/flauta**
  ("MUUUITO melhor") — exportada. Verificado: check
  (102), 111 testes, integrações (release_fixes checa `tela_inicial_toca_o_tema`). Também: as opções do usuário estavam com Música e Ambiente em 0 desde 08/10 (por isso "não toca"); voltei para 100%
  no settings.json (cópia em settings.before_volume_fix.json).
- **Auditoria de som aplicada (ROADMAP 18.5h; adianta 18.6)** — usuário pediu a validação contra os melhores jogos e
  depois "conserte tudo". Feito: gramática da UI (`move` automático na seta/Tab, `Sound.back()`, `pop` nos balões,
  `Sound.tally` na contagem), pausa abafa música/ambiência (`Sound.muffle` pela visibilidade do PauseMenu), prévia do
  volume no próprio canal; pouso pela descida + `landing_heavy`; turbo (pitch/volume/passa-baixa do bus Engine),
  jatinhos de giro, tosse do motor sem gás; batida **fofa** `crash_soft` (a `crash.wav` antiga ficou guardada) e
  `splash` no mar; sons próprios no lugar do `crystal_3` (baú, galão, presente, ratinho, curling) e `oops` nas regras
  que falham; "TENTE DE NOVO"/"A BORDO"/"OUTRA MISSÃO"; vinheta de chegada no mundo; resumo com contagem + ta-dá/recorde;
  ambiência nos 6 mundos (Lua sem a batalha antiga); loops de gelo/vento/correntes/bolhas; título 91 s, voo 115 s +
  camada musical por mundo (`AudioStreamSynchronized`). Fontes: `audio/src/sfx/feedback_sfx.py`, `world_loops.py`,
  `ui/ui_sfx.py`, `ambience/world_ambience.py`, `music/soundtrack.py`; padrões `ui-grammar`, `feedback-sfx`,
  `world-loops` (INDEX limpo). Verificado: check (102), 111 testes, 16 integrações (nova `sound_flow`), paridade 43,
  demo 1500 quadros. **Para o usuário**: ouvir a prévia (`audio/previews/*_reel.wav`, tocada no fim da sessão) e jogar;
  aprovar a batida fofa (voltar à explosão = `crash_soft` → `crash` no `Flight._on_lander_crashed`) e as camadas.
  **Próximo**: retorno do usuário; jingle de mundo completo (resto do 18.6).
- **Começo pelo Mapa + menus explicados (ROADMAP 18.5g)** (usuário: "jogado no voo"; "menus não explicados").
  Novo jogo → Mapa com "Voe!" → 1º salto já aceito; nome do mundo (★ LUA ★) em toda chegada; fim do run do aprendiz
  volta ao Mapa. NAVE ganhou o botão **MAPA** (ícone de planeta `pin`, ao lado do DECOLAR). Destaques em fila de até
  2 por tela: Compre! → Mapa!, Ajuda! → Liga/desliga, abas novas com Q/E, 2º mundo com ← →. "PILOTO FORMADO!" diz onde
  fica o Nivelador. Menu do Mapa: "VOLTAR AO MAPA". Bug visual corrigido: o balão do destaque ficava sob a tela
  escura. Protótipo aprovado: `art/previews/menus_intro/menus_intro.html`. Verificado: check (101), 111 testes +
  15 integrações (`onboarding_flow`: Mapa → VOAR → nome do mundo → Compre! → Mapa! → botão MAPA → aprendiz volta ao
  Mapa; `slots_flow` atualizado), paridade 43, demo 900 quadros, capturas `flight_ui_preview -- --no_title --spot
  [--new] --map | --ship [--buy|--assists] [--tips_done=...] [--dev_stars=N]`.
  **Para o usuário**: jogar um jogo novo e aprovar o ritmo; o ícone do botão MAPA é o planetinha que já existia (pedir
  um ícone de mapa via pixel-art se ficar estranho). Fora: selinho "emprestado" no voo.
  **Próximo**: retorno do usuário; depois 18.6 som por mundo.
- **Aprendiz menos insistente + destaques de 1ª visita** (reclamação do usuário: tutorial a cada batida e o jogo
  pilotando sozinho). Fantasma/balão só na 1ª batida do jogo; "Veja como!" desligado (`onboarding.guide` false);
  `Spotlight` (balão C, um passo por tela) no 1º cartão (ACEITAR), 1ª NAVE com dinheiro (peça) e 1º Mapa (NAVE "!" ou
  VOAR). Verificado: check (101), 111 testes + integrações (`onboarding_flow` cobre tudo), paridade 43, capturas
  `flight_ui_preview -- --no_title --spot [--hangar]`. **Para o usuário**: jogar um jogo novo e dizer se o ritmo do
  começo ficou bom.
- **Correção: "ACABOU O GÁS!" com gás sobrando** (relato do usuário, aprendiz com 23 de gás e 2 entregas). Causa: regra
  "aprendiz sem pedido ao alcance acaba o run" da correção do loop. Agora o run do aprendiz só acaba com o tanque vazio;
  pedido fora do alcance pode ser tentado sem a proteção (`Main._hop_safe`). Teste novo no `onboarding_flow`.
- **Aprendiz validado contra os jogos mais vendidos (ROADMAP 18.5f)**. A base já seguia o padrão; aplicadas as 5
  lacunas: relevo baixo em todo salto antes da 1ª entrega; **"Veja como!"** (passou das repetições ou sem gás → o
  piloto automático voa o mesmo salto; motor/girar devolve a nave; a entrega vale; se o guia falhar → cartão);
  **Nivelador emprestado** ao aprendiz (`onboarding.lent_assists`); **"PILOTO FORMADO!"** na 5ª entrega. Simulador:
  `Profile.guide_after` (novato: mediana da 1ª compra igual, pior caso 682 → 354 s; `balance/sims/2026-10-08-novice-guide.py`).
  Verificado: check (99), 111 testes + todas as integrações (`onboarding_flow` cobre guia, assumir o controle, guia que
  pousa e entrega), paridade 43, capturas `flight_ui_preview -- --no_title --new --guide` (bateu → VEJA COMO! → pousa
  sozinho) e `--new --meter --graduate` (Nivelador + medidor; aviso de formatura).
  **"Tente de novo" em figura aplicado (B+C, pedido "faça o mais recomendado")**: `RetryHint` = fantasma pontilhado na
  plataforma alvo + balão com a cena em cima da nave até decolar; aviso só com o título. Verificado: check (100), 111
  testes + integrações (`onboarding_flow` agora a 8x: fantasma, balão, balão some ao decolar), paridade 43, demo 2400
  quadros, capturas `flight_ui_preview -- --no_title --new --retry=<motivo>`.
  **Para o usuário**: jogar um jogo novo e bater de propósito; aprovar o fantasma/balão (placeholder em `_draw`; arte
  final via pixel-art só se quiser). Aviso de formatura usa o jingle milestone e texto.
- **Bug do loop do aprendiz corrigido** (relato do usuário jogando um save novo): missão difícil demais prendia o
  jogador (a batida repetia o mesmo salto para sempre). Agora: no máximo 2 repetições (`retries_per_hop`), depois volta
  ao cartão com o gás do começo do salto ("OUTRA MISSÃO!"); sem pedido ao alcance, o run acaba. Verificado: check,
  111 testes, integrações (onboarding_flow cobre o caso; acelerado com `Engine.time_scale` 4 para caber nos 600 quadros).
- **Auditoria dos primeiros minutos APLICADA (ROADMAP 18.5e)**: "conserte todos pela ordem que preferir". Jogo novo
  começa voando no 1º salto já aceito (perto, chão quase plano, sem minijogo, "Pouse!"); aprendiz (< 5 entregas) não
  perde o run na batida (repete o salto com o gás dele) e pousa devagar fora da plataforma sem bater; Coach sem texto
  (teclinha do motor/girar só quando falta, some no 1º uso) + medidor de descida; revelação por etapas; CONTINUAR → NAVE
  quando dá para comprar; Mapa com moedas e "!"; resumo diz como acertar; telemetria de sessão (`session.csv`,
  `godot-dev/scripts/ftue.py`); perfil `novice` no simulador (1ª compra mediana ~5 min; sem o aprendiz o pior caso ia a
  ~9,5 min). Detalhes: GDD §8, ARCHITECTURE "Primeiros minutos", DECISIONS 2026-10-08. Verificado: check (99), 111
  testes, 15 integrações (nova `onboarding_flow`; controls_test/release_fixes/slots_flow no fluxo novo), paridade 43,
  demo 2400 quadros, capturas `flight_ui_preview -- --no_title --new [--meter]` e `world_map_preview`.
  **Para o usuário**: jogar um jogo novo e aprovar (teclinha e medidor são placeholder em `_draw`; arte/som só se
  quiser); rodar o teste com crianças (`docs/PLAYTEST_KIDS.md`) e o funil. Ficou como estava: janela de missão (M2,
  maquete aprovada). Decidido sem perguntar: teclinha do motor não conta como "dica óbvia"; aprendiz = 5 entregas.
  **Próximo**: retorno do usuário jogando; depois 18.6 som por mundo.
- **Auditoria dos primeiros minutos / FTUE (ROADMAP 18.5d)**. Relatório: https://claude.ai/artifact/Eme3BchGnN7iMng1rGbNSg.
  Veredito: o gancho visual é forte, mas o 1º minuto ensina pouco e pune muito. Jogo novo abre Mapa → conversa da
  missão antes do 1º toque no motor; ninguém mostra como pilotar; batida no 1º salto acaba o run com 0 moedas
  (telemetria humana com a nave inicial: 23/35 batidas, maioria "fora da plataforma"); CONTINUAR leva ao Mapa, que não
  mostra moedas. O simulador supõe ~1,8% de batidas para o casual (1ª compra 119–207 s em 3 perfis × 3 sementes), então
  não representa o novato. Nada de código mudou. **Próximo**: o usuário escolher a ordem (sugerida no relatório e na
  18.5e); começar pela telemetria de sessão (M5). C3 (ensinar sem texto) e A3 (medidor) vão primeiro para protótipo HTML
  com abas, porque esbarram na decisão "sem dicas óbvias".
- **Auditoria de UX/UI aplicada (ROADMAP 18.5c)**: 20 achados; lista e decisões em `docs/DECISIONS.md` (vírgula
  decimal, NAVE em todo lugar, verde = partir, estados na paleta via `palette_fx.gdshader`, pausa em abas, HUD sem
  abreviações, recordes com troféu, nave pôster 1x na tela NAVE, contorno branco no lander). Verificado: check, 111
  testes + integrações (esc_flow/sandbox_flow atualizados), paridade 43, demo 2400 quadros, capturas de todas as telas
  (`pause_preview` ganhou `--tab=controls|game`).
  **Para o usuário aprovar vendo**: botão vinho de "Novo jogo", contorno branco do lander, nave pôster na tela NAVE
  (menor que a antiga 3x, mas na escala do resto), cinza-frio dos bloqueados.
  **Ficou de fora (decisão sua)**: Estrada duplicada no Mapa e na tela NAVE (a da NAVE ancora balões e festas; tirar
  pede redesenho); faixa escura da planície em vales (ajuste de arte/parallax); som tocando na saída das capturas
  (vazamento de áudio do motor, já ignorado no `test`).
- **Apagar jogo salvo no menu inicial** (X ao lado de cada jogo, 2 cliques) e título do resumo pelo motivo
  ("ACABOU O GÁS!"...). Verificado: check, 111 testes, integração `slots_flow` (apagar, Esc, jogo em uso), capturas
  `title_preview -- --saves [--delete]` e `summary_preview [-- --crash]`.
- **Auditoria dos minijogos aplicada (ROADMAP 18.5b)**. Relatório: https://claude.ai/artifact/1kffVyZpAtd3MmubEaw7wg.
  O usuário pediu "definir uma ordem e implementar tudo"; decisões em aberto ficaram com a recomendação (selo no
  resumo em vez de estrela; crédito parcial em todos os mundos; Bolhas com g 2,4). Commits 15b544f → b104a4d. Verificado:
  check, 111 testes, todas as integrações (nova `minigame_geometry`), paridade 43, demo 2400 quadros, capturas
  `minigame_preview -- --world=jardim|bolhas|cogumelos|sorvete` e demo `--dev_world=nuvens`.
  **Pendências para o usuário**: (1) aprovar ouvindo os sons novos (`audio/previews/minigame_reel.wav`: 3 quiques,
  batida, 5 carneirinhos, 3 vãos); (2) aprovar a figura do queijinho e as sementes do Jardim (atlas `minigame_props`);
  (3) **carneirinhos decorativos do cenário das Nuvens são iguais aos do minijogo** — criança vai tentar pegar; proposta:
  trocar/esconder os do fundo (arte da 18.5, aguardando aprovação); (4) jogar e medir com a telemetria nova
  (critérios de aprovação no relatório). Economia v18: casual abre os mundos finais ±10% da v17; pior parede 46 min
  no engaged (= runs longos do modelo, calibração pendente).
  **Próximo**: retorno do usuário (sons, arte, carneirinhos do fundo); depois 18.6 som por mundo.
- **Fase 18 virou "viagem com minijogos" (2026-10-07)**: plano em `docs/DECISIONS.md`; protótipo jogável aprovado
  (`art/previews/minijogos/minijogos.html`). **18.3c ✅** economia v17 (Estrada por mundo, pedido-assinatura) + estado
  e save v6 por mundo. **18.3d ✅** hub: o jogo abre no Mapa (cartão do mundo
  com a Estrada, VOAR/NAVE, viagem animada ao completar). **18.4 ✅** os 6 minijogos no voo (Lua trilha · Nuvens fila +
  correntes · Cogumelos chapéu-mola · Sorvete curling · Jardim caules + vento · Bolhas garra + mar + bolhas), com testes
  (`minigame_flow`) e prévia (`minigame_preview -- --world=<id>`). **18.5 ✅** arte visual dos 5 mundos (cenários, figuras
  dos minijogos, moradores + palcos da conversa, rostinhos, planetinhas do Mapa) — página
  `art/previews/mundos_arte/index.html`, aguardando aprovação. **Próximo**: ajustes de arte pelo retorno do usuário;
  18.6 som (o usuário pediu para ver depois). Pendências: PROGRESSÃO ainda mostra a Estrada (duplicada com o cartão do Mapa); nave
  fraca num mundo de gravidade alta não decola (avisar no Mapa); calibração do tempo de run do modelo.
- **Fase 18 — Mundos novos (2026-10-07)**: plano aprovado (mundos paralelos, recordes por mundo + bônus de recorde,
  Estrada única com parada `world`, seletor). **18.1 ✅** o usuário ficou com os 5 conceitos de
  `art/previews/mundos/mundos.html` (git-ignorado): Nuvens → Bolhas → Cogumelos → Sorvete → Jardim.
  **18.2 ✅** economia v16 (`balance/sims/2026-10-07-v16-worlds.py`; padrão `economy-balance/.../parallel-worlds.md`).
  **18.3 ✅** multimundo: Mapa das estrelas (escolhido pelo usuário), save v5, recordes por mundo, bônus de recorde;
  mundos jogáveis com cores provisórias. Verificado: check, 108 testes + integrações (nova `world_flow`), demo,
  capturas `world_map_preview [--all]` e `flight_ui_preview -- --no_title --world=cogumelos`.
  **Próximo**: 18.4 mecânica de cada mundo (correntes, bolhas, cogumelo-mola, chão escorregadio, vento) — base no
  `Hazards`/`HazardView` do commit 4ec1ea1; depois 18.5 arte e 18.6 som.
- **Fase 17 — Bata seu recorde + paisagens (2026-10-07)**. Plano aprovado: run sem teto (meta = recordes pessoais;
  bater acaba o run; HUD com snapshot de todos os recordes, dinheiro em destaque) + relevo com receitas variadas por
  missão. **17.1 ✅** economia v15: sai `max_per_run`, entra `run_fatigue` 1,7 (gás × 1,7^n, galão ÷ 1,7^n; ver
  `economy-balance/references/patterns/run-fatigue-records.md`); `RunState.fatigue`, `Flight.set_fatigue`/`eff_stats`,
  HUD conta entregas sem "/6". Verificado: check, 102 testes, paridade 31, demo sem erros.
  **17.2 ✅** recordes do run: o usuário escolheu (protótipo `art/previews/recordes/recordes.html`, git-ignorado) o
  **placar no canto (A)** e o **resumo com troféus (2)**. `RunState.record_values`, `GameState.RECORDS`/`record_text`,
  save v4, `Hud._build_score`, `RunSummary._add_records`, troféu nos atlas `icons`/`kids`. Verificado: check, 104
  testes + integrações, demo, capturas `flight_ui_preview -- --no_title --records`, `summary_preview`, `hangar_preview -- --late`.
  Pendente: som próprio de recorde (hoje jingle milestone; sound-design).
  **Correção** (pedido do usuário): o run só acaba com o tanque vazio de verdade (`Main.GAS_EMPTY`); pedido longe
  demais fica vermelho mas pode ser tentado.
  **17.3 ✅** paisagens: 7 receitas (`world.json > terrain.landscapes`), 5 liberadas pela Estrada, ícones `land_*`,
  fundo segue o chão, plataforma no nível sem parede. Verificado: check, 108 testes (+ paisagens em 8 seeds), demo,
  capturas `landscape_preview` (visão geral e `--near`).
  **Próximo**: o usuário jogar a Fase 17 (run sem teto + recordes + paisagens); depois 16.5 (arte/sons pendentes,
  incluindo som de recorde) e a fase de economia (16.6: cansaço 1,7, Frota não comprada, estrelas das paradas).
  Visual pendente: plataforma bem abaixo da partida ainda mostra um pouco da planície escura do fundo.
- **PROGRESSÃO: Estrada das Estrelas + Reputação (2026-10-07, ROADMAP 16.1–16.4)**. Pedido: "o jogador deveria
  visualizar toda sua progressão desde o início"; o usuário escolheu, entre 3 protótipos HTML
  (`art/previews/progressao/progressao.html`), a estrada por estrelas ("liberar igual um battlepass"). Spec v13:
  `progression.road` (29 paradas, estrelas ACUMULADAS = rascunho), `contracts.reputation` (+10% na entrega seguinte a um
  pouso perfeito; substitui o combo), sai o upgrade Reputação. Jogo: GameState (stars total, road_reached/road_seen,
  reputation, can_buy), SaveData v3 (migra v2), LandingRules.is_perfect + `world.json > landing.perfect`, selo no HUD e no
  "Você ganha" (v14: virou Reputação por ratinho com 3 corações e aba REPUTAÇÃO), tela PROGRESSÃO (hangar reescrito: RoadView, ShipView, RoadText; abas NAVE/AJUDAS/FROTA; ×1/×10/MÁX;
  festa das paradas novas). Verificado: check, 100 testes + 11 integrações, paridade 28 grupos, demo 2400 quadros sem
  erro, capturas `hangar_preview` (--stars, --late, --news, --sel, --tab) e `flight_ui_preview -- --rep`.
  **Próximo**: 16.5 arte (peças que crescem: hoje placeholder em `ShipView._draw`; ícones da estrada; selo) e sons
  (parada alcançada, degrau, pouso perfeito: hoje usa unlock/milestone/combo_N) — precisam de aprovação do usuário;
  depois 16.6 jogar e a fase de economia (sem o upgrade de Reputação a renda do meio/fim cai: paredes de até 32 min no
  modelo; Frota/Piloto não comprados em 6 h).
- **Janela de conversa na escolha da missão (2026-10-07, ROADMAP 15.8)**. Pedido: "o gatinho laranja astronauta
  conversando com o ratinho e não apenas uma nave parada"; maquete aprovada após ajustes (só o valor final embaixo,
  rótulos em vez de perguntas, botões só texto, ACEITAR MISSÃO, um balão + colunas, um rostinho por ratinho, fila com
  todos os ratinhos e os bloqueados em silhueta). Arte: `art/src/sprites/mouse_hero.py` (7 ratinhos de corpo inteiro),
  `cat_hero.py` ganhou `thumb`/`worried`, `art/src/ui/mission_talk.py` exporta `talk_cat`, `talk_mouse_<tipo>`,
  `talk_stage_luna`, `button_go*`; `ui_kit.json` ganhou peach/purple/wine/crimson. Código: `OfferPanel` refeito (ver
  ARCHITECTURE), `MissionText.ask/say_rule`, tema `GoButton`; prévia `flight_ui_preview` ganhou `--no_offers`,
  `--select=slot`, `--peek=kind`, `--accept`. Verificado: check, 96 testes + 11 integrações (controls_test agora marca a
  plataforma e clica em Aceitar; variante `--numpad` = 1 + Enter), demo 2400 quadros sem erros, capturas (jogo novo,
  confeiteira com estrelas, longe sem gás, aceite, ratinho bloqueado). Pendência: o usuário jogar e aprovar; a carga
  na mão do ratinho é a figurinha de 16 px (pequena).
- **Escolha de missão mais clara (2026-10-07)**. Pedido: "não dá pra saber o que as coisas significam". Cartão do
  `OfferPanel` agora diz tudo em palavras simples: fala do ratinho + **nome do tipo** (spec), **regra curta**
  (`MissionText.rule`/`RULE`), cada plataforma com o nome (normal/estreita/apertada), rótulo "dificuldade:" nas
  estrelas, linha "clique numa plataforma para partir" (ou, em vermelho, "o gás pode não dar para chegar lá!"); na fila,
  o mineiro mostra "perto/médio/longe" em texto (saíram as figuras dist_*). O cartão subiu para logo abaixo da fila
  (não cobre mais a nave pousada — pendência da 15.6 resolvida). Verificado: check, 96 testes + integrações, capturas
  `flight_ui_preview -- --no_title --missions --select=soft|simple2`. Pendência: o usuário aprovar jogando.
- **Jogos salvos: lista compacta + Salvar no jogo (2026-10-07)**. Pedidos: "um embaixo do outro; horas jogadas, gold,
  estrela; tirar a barra; desenho do mapa atual no fundo"; depois "não precisa do botão de apagar, é só sobrescrever;
  tem que dar a opção de salvar dentro do jogo; ficou muito grande". Componente `game/title/save_slots.gd` (`SaveSlots`,
  modos PLAY/SAVE) usado no menu inicial e no menu do jogo (pausa e hangar: linha "Gravar o jogo" → Salvar abre a lista
  no lugar das colunas; por cima de outro jogo = 2 cliques; o espaço escolhido vira o jogo em uso). `SaveManager.save_to_slot`
  (guarda à parte um arquivo ilegível antes). Cartão 250x28 com a faixa `assets/ui/save_bg_luna.png`
  (`art/src/ui/save_card_bg.py`, recorte 244x22 das camadas do voo) + ícone `clock` no atlas kids. Saíram barra, runs
  e Apagar (o "Novo jogo" da pausa no hangar continua). Verificado: check, 96 testes, todas as integrações (slots_flow
  ganhou Salvar em vazio e por cima), capturas `title_preview -- --saves` e `pause_preview -- --saves [--overwrite]` (nova).
  Pendência: o usuário aprovar vendo no jogo; com os 5 espaços cheios, jogo novo só pelo "Novo jogo" do hangar.
- **Tela inicial própria (2026-10-06, ROADMAP 15.7)**: o título não monta mais o voo da Lua atrás. Cena
  `game/title/title_backdrop.*` (`TitleBackdrop`) com arte de `art/src/title/title_moon.py`: gatinho astronauta herói
  (102x115, `art/src/sprites/cat_hero.py`, k ajustável) acenando/respirando no morro de queijo, bandeira tremulando, nave
  "pôster" com luzinhas, Terra dormindo, ratinhos espiando, nuvens à deriva, estrelas cintilando, estrela cadente;
  parallax leve pelo mouse. Logo desenhado (`art/src/ui/logo.py` → `assets/ui/logo.png`) + frase "Pouse. Entregue.
  Evolua sua nave." + coluna de botões à esquerda; subtelas no painel do meio. `Main._show_title` = `_clear_run` (sem
  Flight); `_open_hangar` monta o mundo (`_build_hangar_world`) quando falta. PrimaryButton ganhou estado apertado.
  Verificado: check, 96 testes, 11 integrações (nova `title_backdrop`), demo sem erros, capturas `title_preview`
  (menu e `--saves`). Conceitos/histórico: `art/previews/title_concepts/` (`A_v3.html` = aprovado).
  Pendência: o usuário ver rodando no jogo (parallax/animações só aparecem ao vivo).
- **Menu inicial refeito (2026-10-06)**: só Jogar · Sandbox · Opções · Sair; Jogar abre 5 cartões de jogo salvo com a
  progressão (missões liberadas N/total + barra, créditos, runs, tempo). `SaveManager.SLOTS` = 5; `SaveData.summary`
  ganhou `stars`/`nodes`. Verificado: check, 96 testes, integrações slots_flow (5 cartões, destaque e progressão do jogo
  em uso), esc_flow, save_roundtrip, release_fixes; prévia `title_preview -- --saves [--confirm]`.
- **Corrigido: tela parada no 1º voo de um jogo novo** (só voltava a seguir com Esc). Camera2D da Flight nova não
  processava (interpolação de física + câmera do menu ainda atual) → `camera.make_current()` em
  `Flight._place_on_start_pad`. Teste `tests/integration/camera_follow` (mede o canvas). Padrão `godot-dev/.../camera-swap.md`.
- **Fase 15 — Escolha intuitiva + missão no seu mapa (2026-10-06)**. 15.1 ✅ figuras (pad_normal/narrow/tight,
  dist_1..3, check/cross no atlas kids; `assets/ui/balloon.png` + `balloon_tail.png` em `art/src/ui/ui_kit.py`).
  15.2 ✅ nova tela de escolha (`OfferPanel`: fila de chips + cartão com balão e 3 plataformas que partem;
  `MissionText`; `RunState.pay_for_tier`; tema `Balloon`/`BalloonLabel`; `UiKit.gold_frame`). Verificado: check,
  94 testes + integrações (controls_test clica numa plataforma), demo entregando, capturas
  `flight_ui_preview -- --no_title [--missions --select=soft]` (`--missions` novo: libera os ratinhos).
  15.3 ✅ cada missão no seu mapa: `Flight.begin_mission` (mapa novo pela seed `hash([_run_seed, entregas])`, partida
  em x=0) + `_arrive` (nave 90 px acima desce em 1,1 s com a chama, estado LANDED = sem física/gás; `Lander.arriving`;
  piloto do demo volta a "takeoff" ao tocar) + `Main._fade` (0,25 s); `world.json > missions.arrival`; fundo deslocado
  por mapa (`_bg_origin`); `offer_ground_screen` removido. Táxi: busca e volta no mesmo mapa. Teste novo
  `tests/integration/mission_map_flow` (partida x=0, descida sem gás, outra seed = outro mapa, mesma seed = mesmo).
  Demo: várias missões seguidas (simples, táxi 2 trechos, cabo, rápida) sem erros.
  15.4 ✅ relevo por tipo: `TerrainGen.generate(..., shape)` + `TerrainGen.mission_shape(missão, stage)`
  (`world.json > missions.<tipo>.terrain`): Pesada `rise_m` 80 (subida até o alvo), Suave `target_lift_m` 70 (mesa),
  Rápida `crest_scale` 0,35, Cabo sem crista + `basin_m` 60, resgate sem crista + cratera 45, táxi busca num degrau
  40; Dupla = maior de cada campo. Só mexe no trecho partida → 1ª entrega (o 2º trecho do táxi não muda nada).
  Economia: `tests/tools/mission_gas_probe` (piloto do demo, mesmas distâncias com/sem relevo) → diferença ≤ 1% (o arco
  já passa por cima da crista) → **sem mudança na spec**. Prévia dos perfis: `tests/tools/mission_terrain_dump`.
  Testes: `test_relevo_das_missoes*`.
  15.5 ✅ `game/run/mission_intro.*` (`MissionIntro`): a oficina instancia e abre ao `Events.mission_unlocked` de nó ★1
  (só com a oficina visível): "Novo amiguinho!", ratinho 2×, balão, nome, certo × errado com as figuras das cargas
  (`MissionIntro.PICS`; Pesada/Dupla só o certo) + check/cross; fecha com OBA!/Enter/Esc/clique depois de 0,4 s.
  Prévia: `hangar_preview -- --tab=1 --intro=soft`.
  **Próximo: 15.6** — o usuário jogar e aprovar (cartão, descida do céu, relevos). Pendências: em saltos curtos a
  cratera do Cabo fica rasa (limite 15% da distância); o cartão de baixo cobre parte da nave pousada na escolha.
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
  - **v12.1 ✅ (2026-10-06)**: um pedido por ratinho (Simples: perto/médio/longe) e escolha de plataforma + estrela no
    cartão do pedido (clique; cima/baixo e Shift + cima/baixo; lembra a última escolha por ratinho). **Pendente**: o
    modelo escolhe sempre a apertada (batida otimista) — calibrar com voos reais (Fase 10.1).
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
