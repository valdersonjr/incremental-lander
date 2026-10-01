# Mundo 2 — Floresta fechada (id `ares`)

- **Slug**: forest-scene
- **Tipo**: fundo em camadas + terreno + enfeites (mesmo contrato de `moon-scene.md`)
- **Assets** ← `art/src/bg/forest_scene.py --export`: `assets/bg/ares_{sky,planet,far,mid,plain}.png`,
  `assets/tiles/ares_ground_{lit,flat,shade}.png`, `assets/sprites/ares_rocks.png` (enfeites 8 x 16x16, base linha 14),
  `assets/bg/ares_layers.json` (com `rock_spacing` [6, 22]: enfeites mais densos). Prévia `art/previews/forest_scene_2x.png`.

## Por que existe
Usuário reprovou recolorir a Lua: cada planeta tem que ser um mundo totalmente diferente ("um lua, outro floresta
fechada, outro planeta dos doces, outro um quarto bagunçado"). Mesma técnica da Lua, formas da floresta.

## Regras (pesquisa)
- Folhagem: sugerir, não detalhar cada folha; aglomerados consistentes (variação demais = ruído); deixar galhos
  aparecerem por dentro da copa; abraçar a abstração (Slynyrd, Pixelblog 15).
- Florestas em parallax: camadas de silhuetas com névoa; chão com moitas, cogumelos, samambaias, tufos.
- Perspectiva atmosférica igual à da Lua: plano do meio não pode ser mais vivo que o chão.

## Como construir
1. Céu: faixas ink → deep_sage → sage → lichen → bone → cream (luz dourada filtrando); raios de luz diagonais
   (dither claro, somem para baixo); **copa fechada** no topo (massa ink + bolhas de folhas, contraluz pine) + cipós.
2. Objeto: sol baixo dourado com halo (fica atrás dos pinheiros).
3. Far: ~34 pinheiros em níveis serrilhados (lichen/sage/deep_sage, aro bone), névoa lichen na base.
4. Mid: 4 árvores gigantes — tronco com sulcos de casca (olive/umber/charcoal), raízes abrindo, galhos; copa = blobs
   sombreados (emerald → deep_sage, modo `dir`) + tufos de 3 px (leaf na luz, deep_sage na sombra); cipós;
   pinheiros médios atrás; névoa sage na base.
5. Plain: sub-bosque (moitas apoiadas na linha do horizonte + fileira menor atrás), estrias, vaga-lumes (lemon/lime).
6. Chão: borda de grama (sprout/leaf/emerald por inclinação) com franja descendo, terra umber → charcoal → ink,
   raízes serpenteando, pedrinhas.
7. Enfeites (ASCII, `paint`): tufo de grama, capim alto, samambaia, cogumelo vermelho de bolinhas, cogumelo que
   brilha (aqua), flores, moita, cogumelos marrons.

## Erros na revisão
- Copas com `leaf` como tom base ficaram mais vivas que o chão (profundidade invertida) → base emerald, leaf só nos tufos.
- Moitas espalhadas no meio da planície pareciam pedras flutuando → apoiadas na linha do horizonte.

## Decisões do usuário
- 2026-10-01: aprovado; nome exibido **Silvânia**. Pediu o mapa animado ("árvores balançando, pirulitos girando").
## Animação (pedido do usuário: "o mapa se mexer")
- Quadros empilhados na vertical num PNG (`art/src/bg/anim_util.py`); metas `anim` (camadas) e `rock_frames`/`rock_ms`
  (enfeites) no `<planeta>_layers.json`. Loop curto (6 quadros), balanço de 1–2 px, sem dither animado piscando.
- Vento: copas balançam (topo da copa mais que a base), cipós com a ponta balançando mais, vaga-lumes piscando fora
  de fase, grama/capim/samambaia/flores cisalhados pelo vento, cogumelo de luz pulsando. 6 quadros × 180 ms.
- Copa inteira pulando 2 px parecia tremida → amplitude 1,6 (passos de 1 px) e parte de baixo da copa pela metade.
- `sorted()` dentro do laço dos tufos custava 23 s → ordenar uma vez (6 s no total).
- Relevo fundo deixava bloco escuro → raízes e pedrinhas até o fim da faixa.


## Fontes
- https://www.slynyrd.com/blog/2019/3/7/pixelblog-15-plant-life — folhagem por sugestão, aglomerados consistentes, galhos aparecendo
- https://slynyrd.com/blog/2023/5/22/pixelblog-44-top-down-trees — árvores modulares, coníferas, unidade de textura de folhas
- https://myaumya.itch.io/forest-mountain-fjord-background-asset-pack/devlog/1136765/fjord-forest-background-2d-pixel-art — floresta em camadas de parallax
- https://val-demar.itch.io/dark-forest — floresta escura em 5 camadas, silhuetas e névoa
- https://mutterpixel.itch.io/cozy-forest-builder-pixel-asset-pack — chão da floresta: cogumelos, samambaias, tufos, troncos
