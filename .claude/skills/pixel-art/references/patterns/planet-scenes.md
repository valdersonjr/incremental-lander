# Cenas de Ares, Kronos e Titan (mesmo estilo da Lua, outras rampas)

- **Slug**: planet-scenes
- **Tipo**: fundo em camadas + terreno (mesmo contrato de `moon-scene.md`)
- **Assets** ← `art/src/bg/planet_scenes.py [planeta] --export`: `assets/bg/<p>_{sky,planet,far,mid,plain}.png`,
  `assets/tiles/<p>_ground_{lit,flat,shade}.png`, `assets/sprites/<p>_rocks.png`, `assets/bg/<p>_layers.json`
  (p = ares, kronos, titan). Comparação: `art/previews/planet_scenes_compare.png` (com a Lua aprovada).

## Regra
Usuário: "sempre seguir o mesmo estilo de arte, porém mantendo a paleta definida inicialmente". As técnicas são as da
Lua (montanhas facetadas, perspectiva atmosférica, céu em faixas bayer, estrias, pedregulhos, faixas por inclinação);
cada planeta troca só o **tema** (rampas da Resurrect 64). A Lua fica congelada em `moon_scene.py`.

## Temas (pesquisa)
| Planeta | Céu | Objeto | Chão |
|---|---|---|---|
| Ares (gravidade forte) | anoitecer empoeirado ink → plum_dark → wine → rust → terracotta → copper; poucas estrelas | sol pálido baixo com brilho de poeira + 2 luas pequenas | rust/copper, borda peach/honey |
| Kronos (atmosfera densa) | neblina charcoal → deep_sage → sage → lichen → bone; quase sem estrelas | gigante gasoso com anéis (warm_rock + anel metal) | sage/deep_sage, estrias olive (toque tóxico) |
| Titan (gelo) | noite ink → navy → indigo → blue → sky + **aurora** (teal → emerald → leaf) | lua pálida com halo | gelo white/pale_sky/sky/blue, pedras de gelo |
- Neblina densa (Kronos): planos distantes ficam **mais claros** (perspectiva atmosférica de dia/névoa) — correto.
- Aurora: cortinas verticais pontilhadas que ondulam, fortes na base da cortina.

## Erros na revisão
- Kronos com borda oliva/musgo: trechos planos viravam blocos amarelos soltos → borda em sálvia, oliva só nas estrias.
- `t ** 1.5` com t negativo (aurora) e `sqrt` com arredondamento → clamps.
- Listras aparentes em Ares eram só a escala reduzida da folha (2x está limpo) — sempre conferir em 2x.

## Decisões do usuário
- (pendente)

## Fontes
- https://www.cubebrush.co/maru_98/products/gqryxg/mars-surface-pack-16x16-top-down-pixel-art-terrain-paths-rocks-craters — Marte em pixel art: rocha ferrugem, crateras
- https://aengel-studio.itch.io/sos-mars — paisagem marciana em pixel art: céu laranja empoeirado, sol pequeno
- https://opengameart.org/content/ice-planet-landscape-layered-looping — planeta gelado em camadas de parallax
- https://plasmator-games.itch.io/pixel-planet-creator — atmosferas densas/tóxicas, planetas com anéis
- https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds — perspectiva atmosférica (névoa clareia ao longe)
