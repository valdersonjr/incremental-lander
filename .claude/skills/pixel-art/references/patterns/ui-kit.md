# Kit de interface (fonte, painéis, botões, barras, ícones)

- **Slug**: ui-kit
- **Tipo**: ui
- **Assets** ← `art/src/ui/ui_kit.py --export` (fonte em `art/src/ui/pixel_font.py`): `assets/ui/font.png` + `font.fnt`
  (BMFont), `panel.png`, `panel_header.png` (9-slice 26 px, margem 8), `button_{normal,hover,pressed,disabled,primary,
  primary_hover}.png` (20x16, margens 6/5), `bar_{bg,fill,warn,danger,xp}.png` (12x8, margem 3), `icons.png` (18 x 12x12),
  contrato `assets/ui/ui_kit.json`. Prévias: `art/previews/ui_kit_sheet.png`, `ui_sample_2x.png`, `font_test.png`.

## Regras (pesquisa)
- Fonte pixel: usar no tamanho exato ou múltiplo inteiro; 1 px entre letras; minúsculas com cara de minúsculas
  (x-height e ascendentes/descendentes próprios), não maiúsculas encolhidas.
- 9-slice: cantos fixos, bordas e miolo esticam/repetem; miolo com padrão que repete sem costura.
- Botões em 4 estados (normal, hover, pressionado, desabilitado) + destaque para a ação principal.
- Ícones 16x16 ou menores: silhueta legível antes do detalhe; borda escura + um brilho; ≤ 5–6 cores.
- UI "lê na hora, não briga com a arte do jogo e pertence ao mesmo mundo": uma paleta, uma luz, uma escala.

## Como foi feito
- Fonte: grade de 11 linhas (2 de acento de maiúscula + 7 de corpo + 2 de descendente), maiúsculas 7 px, x-height 5,
  proporcional, acentos do português compostos (agudo, grave, circunflexo, til, cedilha). Export BMFont texto.
- Painel: fundo ink com grade de pontos shadow a cada 5 px (miolo de 10 repete), borda sea (luz) / teal, filete
  interno deep_teal/navy, cantos chanfrados de 3 px com colchetes aqua (HUD futurista, igual à nave/plataforma).
- Botões: deep_teal com bevel (sea em cima, navy embaixo); hover teal; pressionado invertido; desabilitado cinza;
  principal sea/aqua/ice (texto escuro).
- Barras: fundo navy; preenchimento ciano / aviso âmbar / perigo vermelho / XP violeta.
- Ícones: créditos, minério, poeira estelar, gás, motor, tanque, bocais, reputação, trem de pouso, refinaria, frota,
  piloto automático, planeta, prestígio, expedição, opções, distância, qualidade.

## Erros na revisão
- `inside()` do painel sem checar limites → a borda nunca era desenhada (painel invisível sobre o céu escuro).
- Borda deep_teal sumia no céu → borda sea/teal.

## Decisões do usuário
- 2026-10-01: "Tem que mudar de acordo com o mapa... dado cada mapa novo" → **destaque por mundo** (`WORLDS` em
  ui_kit.py; troca a rampa turquesa tom por tom): Lua turquesa, Silvânia verde, Docelândia rosa, O Quarto âmbar.
  Todo mundo novo ganha uma entrada em `WORLDS`. Fixos: fundo escuro, dourado (dinheiro), vermelho (perigo), âmbar
  (gás acabando), **barra de gás sempre ciano** (rosa nos doces confundia com perigo), ícones.
- Assets por mundo em `assets/ui/<mundo>/` (painéis, botões, barra de progresso); fixos em `assets/ui/`.
- (pendente: aprovação do estilo do kit)

## Fontes
- https://www.wayline.io/learn/game-ui-art — 9-slice; ícone = silhueta primeiro; borda escura + um brilho; uma paleta/luz/escala
- https://community.aseprite.org/t/how-to-make-buttons/10584 — botões: tamanho de pixel consistente, cores da paleta do jogo, 9-slice
- https://ome6a1717.itch.io/ui-background-nine-slices — painéis 9-slice (inclusive sci-fi)
- https://glyphsapp.com/learn/pixelfont — fonte pixel: grade, x-height, ascendente/descendente
- https://biim-games.itch.io/5x7-tiny-sprite-font — fonte 5x7: 1 px entre letras (largura por caractere)
- https://www.sprite-ai.art/guides/how-to-create-16x16-pixel-art — 16x16: silhueta, ≤ 5–6 cores, contorno seletivo
