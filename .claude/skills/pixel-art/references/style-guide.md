# Style guide do projeto (decisões globais)

> Fonte da verdade para decisões que valem para TODOS os assets. Itens marcados **(provisório)**
> devem ser confirmados com o usuário no primeiro asset do tipo e então atualizados aqui.

## Jogo
- Incremental estilo Lunar Lander, **visão lateral (side-view)**, Godot 4.7, **computador** (teclado).
- Paleta: Resurrect 64, travada. Transparência binária.
- **Resolução interna 640×360**, escala inteira (janela 1280×720 = ×2; 1920×1080 = ×3). Um lander de
  32 px ocupa ~9% da altura da tela — manter silhueta forte. (Decidido 2026-09-29.)
- **Terreno: polígono irregular** com plataformas de pouso planas (terrain-tiles.md §7): textura de
  preenchimento seamless + faixa de superfície; tileset blob47 só se surgir uso para blocos.

## Escala e grade
- Tile base: **16x16**. Lander/naves/sprites principais: **32x32**. Grandes: 64x64.
- Mesma escala de pixel para todos os assets (sem misturar resoluções na tela).

## Luz
- Sprites: luz vinda de **cima-esquerda** (`light_dir=(-1, -1)`) — confirmada com o lander (2026-09-30).
- Tiles: luz **de cima** (permite espelhar tiles horizontalmente).

## Contorno
- Sprites interativos (lander, pickups, perigos): selout + contorno externo `ink`; no lado da luz,
  contorno pode clarear para aparecer contra o espaço. **(provisório)**
- Tiles de terreno: sem contorno geral; borda da superfície marcada por faixa clara (`mist`/`steel`).
- Efeitos (fogo, explosão, fumaça): sem contorno.
- Fundos/parallax: sem contorno, contraste baixo.

## Orçamento de cores por asset
- 16x16: até 6–8 cores. 32x32: até 12–16. 64x64: até 24. Tileset inteiro: até 8–10.

## Materiais padrão (rampas)
- Rocha lunar: `neutral`. Vidro/visor: `teal` (aqua/teal). **Casco do lander: branco/`neutral` (white, mist, steel,
  lilac_grey) com faixa turquesa (`sea`)**. **Propulsor do lander: plasma ciano** (white → ice → aqua → sea → teal →
  deep_teal → navy), não fogo. `fire` fica para explosões/queima.
- **Direção de arte: FUTURISTA limpa** (escolhida pelo usuário entre 5 propostas: Apollo, Futurista, Industrial,
  Fofo/retrô, Vetorial — `art/previews/lander_styles_compare.png`). Formas pontiagudas/lisas, branco + turquesa,
  brilhos ciano; evitar ferrugem/sujeira e formas "fofas".
- Fundo espacial: `space` (+ estrelas `mist`/`white` esparsas, `scatter` com `min_dist`).

## ESTILO DO JOGO (regra do usuário, vale para TODO asset novo)
- **Referência visual obrigatória: a cena da Lua aprovada** (`art/previews/moon_scene_rich_2x.png`,
  padrão `patterns/moon-scene.md`) + o lander futurista. Todo asset novo (plataformas, FX, outros planetas, UI)
  segue a mesma linguagem: rico em detalhe, luz de cima-esquerda com faces luz/sombra marcadas, perspectiva
  atmosférica, céu em faixas pontilhadas, estrias e aglomerados no chão, brilhos turquesa/ciano na tecnologia.
- **Paleta: sempre e só a Resurrect 64 definida no início** (travada pela biblioteca e pelo pre-commit).
  Outros planetas mudam de rampa (ex.: Ares em rust/fire), nunca de paleta.
- Antes de mostrar um asset novo, compare-o lado a lado com a cena aprovada: se destoar, refaça.
- (Usuário, 2026-10-01: "lembre de sempre seguir o mesmo estilo de arte, porém mantendo a paleta definida inicialmente".)

## Decisões registradas
<!-- Adicione aqui: data — decisão — motivo -->
- 2026-09-30 — **riqueza de detalhe**: cenas em camadas com perspectiva atmosférica, céu em faixas, relevo facetado, textura no chão; arte minimalista/chapada foi reprovada ("muito feia", "todos horríveis") — referências do usuário em patterns/moon-scene.md
- 2026-09-30 — estilo futurista (lander B) define a arte do jogo; propulsor de plasma ciano — escolha do usuário entre 5 propostas
- 2026-09-29 — resolução 640×360 e terreno em polígono irregular — respostas do usuário / padrão da skill (§7) + modelo de run da economy-balance
