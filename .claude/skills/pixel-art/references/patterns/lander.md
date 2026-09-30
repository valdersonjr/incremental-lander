# Lander (nave do jogador)

- **Slug**: lander
- **Tipo**: sprite + animação (idle, thrust)
- **Grade**: 32x32 (sprite principal; silhueta + cabine + pernas + bocal)
- **Assets**: `assets/sprites/lander.png` (+ `.json`, `_frames.tres`) ← `art/src/sprites/lander.py` (estilo B em
  `lander_styles.py`; alternativas A/C/D/E também lá; Apollo antigo em `lander_apollo.py`)

## Características visuais (pesquisa)
- Silhueta Apollo LM: "inseto" sem aerodinâmica — estágio de subida (cabine angular com janelas) sobre estágio
  de descida (folha térmica dourada), 4 pernas abertas com sapatas, bocal no centro embaixo.
- Base neutra (metal) + cor de destaque forte (folha dourada) = identidade (Slynyrd: pintura sobre base neutra).
- 32x32: 3 estágios de sombra (luz, base, sombra), sombras frias (hue shift); contorno escuro consistente + selout.
- Chama: molde de forma, núcleo claro junto ao bocal (white/lemon/gold), meio amber/orange, pontas brick/maroon;
  3–4 quadros de 50–90 ms variando comprimento/largura.

## Contrato com o jogo (godot-dev)
- Origem no centro do sprite (Sprite2D centered): pixel (16,16) = origem do corpo.
- Sapatas na linha y = 24 (feet_offset_m = 8 no world.json).
- Largura das pernas define `lander.half_width_m` no world.json.

## Fontes
- https://opengameart.org/content/apollo-moon-landing-sprites — LEM em grade de 20 px (CC0), animações simples
- https://www.slynyrd.com/blog/2018/12/12/pixelblog-12-to-the-stars — naves: silhueta livre, pintura sobre base neutra
- https://pixnote.net/en/learn/shading — 3 estágios em 32x32, hue shift nas sombras
- https://opengameart.org/content/rocket-thruster-effect-animations — quadros de chama de propulsor
- https://babel.speldesign.uu.se/?p=21849 — molde de forma da chama reaproveitado entre quadros

## Decisões do usuário (2026-09-30)
- 1ª proposta (Apollo, metal + folha dourada) → "ajustar"; pediu **opções de estilo**. Gerei 5 (A Apollo, B Futurista,
  C Industrial, D Fofo/retrô, E Vetorial) no mesmo contrato e numa folha comparativa com céu da Lua, parado + propulsor.
- **Escolheu B Futurista**: casco branco pontiagudo, visor aqua/teal, faixa `sea`, pernas `lilac_grey`
  (slate sumia no céu escuro), chama de plasma ciano. 11 cores, lint limpo.

## Lições
- Duas janelas espelhadas viram "olhos" (cara de robô); bocal largo e escuro vira "boca". Janela única fora do centro.
- Oferecer variações de estilo cedo (folha comparativa) é mais rápido que iterar um estilo que o usuário não quer.
- Pernas escuras somem no céu `ink`: usar tons médios (`lilac_grey`) em partes finas.
- Estilo vetorial: desenhar bordas externas E entre materiais (senão vira "fantasma").
