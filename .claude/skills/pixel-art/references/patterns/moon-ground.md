# Terreno da Lua v3 — crosta + blocos de basalto

- **Slug**: moon-ground
- **Tipo**: terreno em camadas (faixa cisalhada + tile no mundo)
- **Grade**: crosta 128x26 por face · escurecimento 128x176 · corpo 128x128 seamless
- **Assets**: `assets/tiles/luna_ground_{lit,flat,shade}.png` (crosta), `assets/tiles/luna_depth.png`,
  `assets/tiles/luna_body.png` ← `art/src/terrain/moon_ground.py` (variante D), exportados por `art/src/bg/moon_scene.py --export`

## Características visuais (pesquisa)
- Rocha em pixel art: formas angulosas e facetadas leem como "duro"; blocar massas antes de detalhar (Slynyrd #13).
- Corpo de chão em side-view não pode ser chapado: rochas incrustadas, rachaduras escuras com borda clara,
  brilho de 1 px onde a luz bate, peso visual distribuído por igual (sem destaque que denuncie a repetição).
- Crosta com espessura (perspectiva 3/4): faixa de cima clara = chão visto de leve por cima.

## Como construir (passes)
1. **3 camadas** (contrato `body_texture`/`depth_texture`/`depth_depth` em `assets/bg/luna_layers.json`):
   crosta cisalhada pelo relevo (borda por face; miolo igual nas 3 faces → sem cortes verticais na troca),
   faixa de escurecimento cisalhada (transparente até k=64, bayer de ink até sólido), corpo com UV = mundo (não deforma).
2. Crosta: borda 3 px por face, regolito lilac_grey→slate, crateras 3/4 (parede de cima em sombra, borda de baixo clara),
   pedrinhas; borda de baixo ondulada (ruído periódico) com lábio shadow/ink.
3. Corpo: Voronoi periódico com métrica angulosa (mistura de Chebyshev e Manhattan) e y × 1.5 (blocos mais largos);
   junta ink embaixo/direita, aresta clara em cima/esquerda, **faceta de cima-esquerda um tom acima** (corte diagonal
   por bloco), poros esparsos; tons slate/shadow (sem lilac_grey: competia com a crosta).

## Erros comuns / o que deu errado na revisão
- v2 antiga (faixa única cisalhada com estrias finas): parecia chuva/arranhões; pedras deformavam nas encostas.
- Blocos sem faceta: chapados ("vitral"). Faceta diagonal resolveu.
- Escurecimento começando cedo (k=40) virava pontilhado sobre os blocos perto do topo → k=64.
- Rochas redondas com sombreamento radial liam como bolhas/buracos (variante A) → sombreamento de gema por faces.

## Decisões do usuário
- 2026-10-02: "o terreno poderia ser mais bonito" → A (crosta + rochas) não convenceu; entre A/B (estratos)/
  C (planalto de crateras)/D (blocos de basalto) escolheu **D**.

## Fontes
- https://slynyrd.com/blog/2019/1/22/pixelblog-13-rocks — rochas angulosas, blocagem antes do detalhe
- https://www.slynyrd.com/blog/2020/5/21/pixelblog-28-side-view-tiles — borda 3/4, luz de cima, peso distribuído
- https://nickdablin.wordpress.com/2013/12/20/rock-tiles-pixel-art/ — rachaduras escuras com borda clara, brilho de 1 px, dither só para fundir
