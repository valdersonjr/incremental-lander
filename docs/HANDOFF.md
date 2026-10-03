# HANDOFF — onde paramos

> Atualizar ao **fim de toda sessão/etapa** (antes do commit). Uma sessão nova deve conseguir continuar
> lendo só este arquivo + CLAUDE.md + ROADMAP.

## Estado atual (2026-10-03)
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
- **2ª auditoria de UX (2026-10-02)**: pausa no voo (Esc ou janela sem foco; `game/pause/`), dica de teclas em painel,
  cabeçalho nas ofertas, foco no resumo, formatos do hangar unificados, `fmt(1e6)`="1.00M". Regras intactas (demo idêntico).
  Prévia: `tests/visual/flight_ui_preview -- --no_title [--pause] [--delivered|--crashed]`. `controls_test` cobre a pausa.
- **Vários jogos salvos (2026-10-02)**: 3 espaços; menu inicial → "Jogos salvos" (jogar / novo jogo / apagar). Jogo 1 =
  o save.json de sempre. Prévia: `title_preview -- --progress --saves [--confirm]`. Testes: save_roundtrip + slots_flow.
- **Interface**: kit pixel (fonte com acentos, painéis, botões, barras, ícones) em todos os menus; cor muda com o mundo
  (`UiKit.theme_for`). Prévias: `tests/visual/{hangar,summary,ending}_preview` (args `--planet=`, `--top`).
- **Travas da Regra 0**: hooks bloqueiam ações numa área sem a skill dela; pre-commit valida assets/economia.

## Próximo passo
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
  **1–8 ou clique** → **W/Espaço** propulsor, **A/D** girar, **R** reinicia, **E** encerra o run.

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
