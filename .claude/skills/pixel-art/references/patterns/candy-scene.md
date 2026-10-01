# Mundo 3 — Planeta dos doces (id `kronos`)

- **Slug**: candy-scene
- **Tipo**: fundo em camadas + terreno + enfeites (mesmo contrato de `moon-scene.md`)
- **Assets** ← `art/src/bg/candy_scene.py --export`: `assets/bg/kronos_{sky,planet,far,mid,plain}.png`,
  `assets/tiles/kronos_ground_{lit,flat,shade}.png`, `assets/sprites/kronos_rocks.png` (enfeites 8 x 16x16, base 14),
  `assets/bg/kronos_layers.json` (`rock_spacing` [10, 30]). Prévia `art/previews/candy_scene_2x.png`.

## Regras (pesquisa)
- Mundos de doce em plataforma: chão = bolo em camadas (cobertura, pão de ló, recheio, chocolate), granulado,
  pirulitos, bengalas, cupcakes, gomas; céu pastel com nuvens de algodão-doce.
- Nuvem: bloco da forma → luz no topo/bordas → sombra embaixo (base achatada).
- Mesma técnica da Lua: perspectiva atmosférica (névoa lilás na base das camadas), luz de cima-esquerda.

## Como construir
1. Céu pastel plum → purple → violet → lavender → pink → peach; brilhinhos; nuvens = 6 bolhas, **cada bolha com
   luz própria** (fofa), base achatada sombreada; rosa (white/lavender/pink/rose) e azul (white/pale_sky/violet/purple).
2. Objeto: planeta-rosquinha (anel achatado: massa honey/copper/terracotta + cobertura white/pink/rose escorrendo +
   granulado) com halo lavender.
3. Far: colinas de goma (salmon/pink/rose/berry) com cobertura lavender escorrendo; névoa lavender.
4. Mid: morros de chocolate (sand/rosewood/mauve/plum_dark) com glacê escorrendo; pirulitos com espiral
   (ângulo + distância), brilho na borda iluminada; bengalas listradas na diagonal com gancho; névoa lavender.
5. Plain: rio de chocolate com correnteza brilhante (peach/sand) e marshmallows na margem.
6. Chão: bolo — cobertura (por inclinação) escorrendo, pão de ló com furinhos, **faixa de geleia** (red/crimson),
   chocolate, plum_dark no fundo; granulado na cobertura.
7. Enfeites: pirulito, bengala, bala de goma, cupcake, bombom, rosquinha, sorvete, marshmallows.

## Erros na revisão
- `shade_blob` direcional com degraus duros deixava nuvens e morros com um corte diagonal reto (chapado) →
  sombreamento com **transição bayer entre os tons** + aro claro nas bordas de cima/esquerda; nuvem por bolha.

## Decisões do usuário
- (pendente)

## Fontes
- https://gatdesucre.itch.io/sugarland-tileset — mundo de doces em plataforma: terreno + decorações
- https://opengameart.org/content/strawberry-cake-platform-tileset — chão de bolo em camadas
- https://opengameart.org/node/121753 — tiles de bolo, panqueca, biscoito, brownie, sorvete, gelatina
- https://helloshiki.itch.io/sugoi-delight-asset-pack — doces em pixel art 32x32
- https://piepzeru.digitalpress.blog/how-to-create-pixel-art-clouds/ — nuvens: forma, luz nas bordas, sombra embaixo
