# Terreno da Lua (polígono irregular)

- **Slug**: moon-terrain
- **Tipo**: textura seamless (fill) + faixa de superfície (surface)
- **Grade**: fill 64x64 (área grande: período maior esconde repetição) · surface 64x16 (período longo na borda)
- **Assets**: (aguardando aprovação) `assets/tiles/moon_fill.png`, `assets/tiles/moon_surface.png` ← `art/src/terrain/moon.py`
  · prévia em jogo: `art/previews/moon_scene_2x.png`

## Características visuais (pesquisa)
- Lunar Lander clássico: vista lateral de relevo recortado com poucas áreas planas (plataformas) — o terreno é cenário,
  as plataformas são o destaque interativo.
- Superfície lunar não é cor chapada: saliências e fendas; bordas de cratera com espessura variável, às vezes somem.
  Nada perfeito/simétrico — imperfeição torna a textura crível.
- Side-view (Slynyrd): borda de cima com leve 3/4 (faixa clara = chão visto de cima), luz sempre de cima,
  clusters gordinhos que atravessam as bordas do tile, peso distribuído, sem feature no centro, "poucas cores bastam".

## Como construir (passes)
1. **Integração define a forma**: a faixa é aplicada **coluna a coluna** abaixo do contorno (cisalhada, não girada):
   coluna x recebe a coluna x%64 da faixa a partir da altura do relevo. Encostas continuam pixel-perfect (nada de
   Line2D girando pixels). O corpo usa a textura com UV = coordenada do mundo.
2. Cores (rampa neutral): corpo `shadow`; rochas `slate`; topo das rochas `lilac_grey`; fenda `ink`.
   Faixa: `mist` (borda) → `steel` → `lilac_grey` → `slate` → `shadow`. 6 cores no conjunto.
3. Luz de cima: topo parcial das rochas clareia (75%, sem pillow shading); sombra de contato embaixo (60%).
4. Textura: rochas em bloco (3 grandes, 4 médias, 5 pequenas) com assimetria esquerda/direita e inclinação aleatórias.
5. Faixa: profundidade de cada tom **ondula** ao longo de x (soma de senos periódicos em 64 → seamless), borda `mist`
   interrompida por trechos `steel`; 2 crateras rasas; pedrinhas na transição com o corpo.

## Erros comuns / o que deu errado na revisão
- v1: estratos em lentes finas em fileiras → "tracinhos"/chuva/tijolo (ruído + banding). Trocado por rochas em bloco.
- v1: faixa com camadas retas de largura igual = banding clássico. Trocado por profundidades onduladas.
- v1: crateras desenhadas como frestas escuras (liam como buracos). Agora bacia pequena com borda de baixo clara.
- v2: rochas todas com o mesmo "losango" → bolinhas repetidas. Assimetria + inclinação por rocha resolveu.
- Faixa de 14 px deixava pouco espaço para a transição; 16 px.

## Decisões do usuário
- (pendente)

## Fontes
- https://community.aseprite.org/t/moon-surface-texture/11887 — crateras: anéis de luz suave, bordas com espessura variável, dither entre crateras, evitar perfeição
- https://www.slynyrd.com/blog/2020/5/21/pixelblog-28-side-view-tiles — borda 3/4, luz de cima, clusters gordinhos que dão a volta no tile, variantes, poucas cores
- https://en.wikipedia.org/wiki/Lunar_Lander_(1979_video_game) — relevo recortado com poucas áreas planas destacadas
- https://mattwalkden.itch.io/lunar-battle-pack — referência de pacote lunar 16-bit: terreno claro contra espaço escuro, parallax de superfície/estrelas, plataformas como estruturas
- https://docs.godotengine.org/en/stable/classes/class_line2d.html — Line2D com textura em tile gira a textura pelos segmentos (motivo de usar faixa cisalhada)
