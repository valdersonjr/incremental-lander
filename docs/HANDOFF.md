# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-10-03)
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
