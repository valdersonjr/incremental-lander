# Perigos por mundo (rajada, gêiser de calda, ventilador, brinquedo caindo)

- **Slug**: world-hazards
- **Tipo**: efeitos + sprites animados (Fase 11.5)
- **Assets** ← `art/src/sprites/hazards.py --export`: assets/sprites/hazard_leaf.png, assets/sprites/hazard_streak.png,
  assets/sprites/syrup_column.png, assets/sprites/syrup_cap.png, assets/sprites/syrup_bubbles.png, assets/sprites/fan.png,
  assets/sprites/air_streak.png, assets/sprites/toy_block.png, assets/sprites/toy_shadow.png, assets/sprites/toy_alert.png

## Contrato com o jogo
- Tabela no docstring do script (tamanho, animação, ponto de ancoragem). Desenho em `game/flight/hazard_view.gd`.

## Características (pesquisa)
- Vento: folhas de 2–6 px tremulando em 4 posições + traços de ar em arco (swirl); cor chapada, sem sombreado
  (o movimento é a leitura). Folhas **claras e quentes** (limão/dourado) contra a floresta escura — verde some.
- Gêiser: borda ondulada que sobe com o fluxo + fio de brilho correndo → líquido, não pilar; bolhas no chão = aviso.
- Perigo justo = avisado antes do compromisso: sombra no chão + "!" piscando (com contorno) para o brinquedo.
- Escala do quarto: objetos do Quarto são gigantes — ventilador 96 px (com 48 px parecia rádio).
- O sprite do brinquedo tem o tamanho da área que destrói a nave (24 px ↔ raio 12 m): o que se vê é o que acerta.

## Lições (revisão)
- 1ª prévia: folhas verdes e traços 12 px sumiam; gêiser parecia pilar; ventilador minúsculo; "!" pequeno.

## Fontes
- https://slynyrd.com/blog/2021/7/16/pixelblog-33-wind-effects — folhas tremulando, swirls, cor chapada, 4 quadros
- https://www.construct.net/en/forum/construct-3/how-do-i-8/leafs-blow-right-left-139187 — folha = bala na direção do vento + seno vertical
- https://opengameart.org/content/large-bubble-and-some-bubbles-going-out-of-a-ground — bolhas brotando do chão
- https://bugnet.io/blog/how-to-design-environmental-hazards-that-are-fair — perigo legível e evitável, aviso antes
- https://kateplays.substack.com/p/telegraphing-danger — telegrafar: sombra onde o objeto vai cair, luz que muda de cor
