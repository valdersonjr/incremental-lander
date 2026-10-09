# Peças da nave que crescem por degrau

- **Slug**: ship-parts
- **Tipo**: sprites modulares (corpo pré-montado por combinação + chama em camada) — voo 32x32 e pôster da NAVE 80x70
- **Assets**: `assets/sprites/lander_body.png` (+ `lander_body_frames.tres`, 64 animações `b_<tanque><bocal><pernas>`
  com piscar), `assets/sprites/lander_flame.png` (+ `lander_flame_frames.tres`, `flame_<motor>`, 32x24),
  `assets/sprites/ship_poster.png` (atlas 8x8 de 80x70), `assets/sprites/ship_poster_flame.png` (80x60, linha = motor),
  `assets/sprites/lander_parts.json` (bocas do bocal, caixas das peças) ← `art/src/sprites/lander_parts.py --export`.
  O `lander.png` antigo continua (versão 0; prévias de cena e o fantasminha do "tente de novo").

## Pesquisa (2026-10-09)
- Jogos costumam ter **~3 variantes visuais** por nave/peça para mostrar progresso.
- A melhoria precisa ser **evidente na silhueta** (sprite pequeno em movimento: forma antes de cor e detalhe —
  "three-read rule": silhueta → blocos de cor → detalhe).
- **Peças modulares** separadas (casco, motor, tanque…) para trocar/combinar ("bigger thrusters = more speed").

## Receita final
| Peça | Versão 1 | Versão 2 | Versão 3 |
|---|---|---|---|
| Gasolina | bolotas aqua nos ombros do disco (fora da cúpula) | maiores | maiores + faixa dourada |
| Eficiência | bocal vira sino (abre para baixo) | sino largo + anel aqua | anel/garganta dourada + aletas |
| Resistência | sapata redonda 2 linhas | mola aqua em zigue-zague | mola + almofada gordinha 3 linhas |
| Motor | chama +3 px | +6 px e mais larga | +9 px, miolo afinando, faisquinhas |
- Degrau → versão em `data/world.json > ship_parts` (0 / 1–2 / 3–5 / 6+; Resistência 1:1). Só visual.
- **Contrato da física intocado**: sapatas sempre na linha y=24, pés em x3..28 (voo); pôster com fundo da sapata em y=61.
- **Contorno**: o corpo é montado JÁ com tanque/bocal/pernas e contornado de uma vez (contorno da união, sem linha
  `ink` entre casco e peça). Por isso 64 combinações pré-renderizadas em vez de camadas soltas; a chama (efeito, sem
  contorno) é a única camada separada, posicionada pela boca do bocal (`nozzle_mouth`).
- **Regressão**: versão 0 de tudo = `lander_cute.body()`/`thrust(i)` pixel a pixel (assert no `__main__`).

## Revisão (o que mudou vendo a folha)
- Gasolina v1: cápsulas finas nas pontas do disco liam como alças/haltere → bolotas redondas sentadas nos ombros
  (fofo, gordinho; pôster com `moon_cute.sphere`).
- Chama v2–3: miolo branco largo virou bloco quadrado → miolo estreito que afina.
- Pôster v3: aletas pequenas sumiam → triângulos maiores com aresta `mist`.
- No jogo: destaque de peça em par (tanques, pernas) precisa de **uma caixa por lado** (a caixa única cobria o disco).

## Decisões do usuário
- 2026-10-09: aprovou a proposta interativa (`art/previews/lander_parts/index.html`: seletor por peça, voo e NAVE,
  "Sobe tudo") — "Boa, gostei".

## Fontes
- https://transfinity-assets.itch.io/pixelart-space — naves com 3 variantes visuais para progressão/upgrades
- https://richtergames.itch.io/blazend/devlog/171507/ship-designs-and-new-logo — partes bem distinguíveis porque o loot vira upgrade visível (propulsor maior = mais velocidade)
- https://babel.speldesign.uu.se/?p=4078 — upgrade visual tem que ser aparente, senão perde o propósito
- https://www.slynyrd.com/blog/2018/12/12/pixelblog-12-to-the-stars — naves modulares: versões de cada parte para combinar
