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
- Sprites: luz vinda de **cima-esquerda** (`light_dir=(-1, -1)`). **(provisório)**
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
- Rocha lunar: `neutral`. Chama/propulsor: `fire`. Vidro/cockpit: `blue`. Casco do lander: **(a definir)**.
- Fundo espacial: `space` (+ estrelas `mist`/`white` esparsas, `scatter` com `min_dist`).

## Decisões registradas
<!-- Adicione aqui: data — decisão — motivo -->
- 2026-09-29 — resolução 640×360 e terreno em polígono irregular — respostas do usuário / padrão da skill (§7) + modelo de run da economy-balance
