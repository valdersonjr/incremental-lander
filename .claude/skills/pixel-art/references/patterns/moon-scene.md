# Cena da Lua em camadas (céu + planeta + montanhas + planície + terreno jogável)

- **Slug**: moon-scene
- **Tipo**: fundo em camadas de parallax + terreno de primeiro plano
- **Grade**: cena 640x360 (resolução interna); cada camada é um laço horizontal de 640 px
- **Assets** ← `art/src/bg/moon_scene.py --export` (contrato `assets/bg/luna_layers.json`):
  `assets/bg/luna_{sky,planet,far,mid,plain}.png` (camadas de parallax, laço de 640 px),
  `assets/tiles/luna_ground_{lit,flat,shade}.png` (faixa 128x176 aplicada cisalhada por segmento conforme a
  inclinação), `assets/sprites/luna_rocks.png` (atlas 6 pedregulhos, célula 16x8, base na linha 6).
  Prévias: `art/previews/moon_scene_rich_2x.png` (aprovada) e `moon_ingame_2x.png` (recomposta a partir dos assets).

## Por que existe
O usuário reprovou o terreno minimalista (v1 em `moon-terrain.md` e os 5 estilos de `terrain_styles.py`) como
"muito feio" e pediu **mais riqueza de detalhe**, mostrando referências: montanha facetada com céu e nuvens,
noite roxa com montanhas e faixas de céu até o magenta no horizonte, lago noturno com lua de halo.
**Regra global que isso gerou (style-guide): cenas ricas e em camadas; nada de arte minimalista/chapada.**

## Regras (pesquisa)
- **Perspectiva atmosférica**: plano mais perto = mais saturado e maior contraste luz/sombra; cada plano
  mais distante perde saturação e contraste e puxa o matiz para a cor do céu. **Faixa de névoa na base** das montanhas.
- Sombras de montanha em matiz frio/azulado; reutilizar cores do céu no sombreamento dos planos distantes.
- Ordem: faixas horizontais de cor (céu/horizonte/chão) → camadas de relevo → detalhes → efeitos.
- Céu em faixas com o horizonte mais claro; transição pontilhada (bayer), não degradê liso.
- Textura de chão coerente em escala: estrias horizontais grossas perto, finas e claras longe.
- Parallax: camadas equilibradas, sem ponto dominante (laço sem costura); cada camada em laço de W px.

## Como construir (passes, como no script)
1. Céu: stops ink → navy → plum_dark → plum → berry → rose (horizonte), transições bayer de até 22 px.
   Estrelas com densidade caindo perto do horizonte, 5 brilhos; 6 cintilantes em cruz.
2. Planeta (Terra): esfera com luz de cima-esquerda, oceano/continentes/nuvens por ruído, terminador pontilhado,
   borda iluminada, **halo** em anéis pontilhados.
3. Montanhas distantes: plum/purple, sem ravinas, névoa berry na base.
4. Montanhas do meio: **facetadas** (face esquerda iluminada até uma crista em zigue-zague; face direita navy),
   face iluminada clareia no pico e escurece para a base; ravinas descendo pela encosta com borda clara; névoa plum.
5. Planície distante: plum → navy com estrias horizontais.
6. Terreno jogável: borda muda com a inclinação (encosta virada para a luz = white/mist; plana = mist/steel;
   sombra = steel/lilac), corpo em gradiente pontilhado até plum_dark, estrias, pedregulhos com luz e sombra
   projetada, crateras pequenas.

## Erros comuns / o que deu errado na revisão
- v1 da cena: face iluminada violeta chapada e mais clara que o chão → inverte a profundidade. Corrigido com
  gradiente vertical (ridge → lit → mid) e paleta mais escura no plano do meio.
- Picos como triângulos iguais → crista com ruído de várias frequências e alturas variadas.
- Ravinas diagonais para o lado errado pareciam riscos → descem pela encosta, 2 px, com borda clara.
- Faixas do céu duras → transições longas.
- Pendente: a planície com estrias pode ler como lago; borda do terreno em encosta íngreme forma "gotas" verticais.

## Decisões do usuário
- 2026-09-30: estilos minimalistas reprovados ("todos horríveis"); quer riqueza de detalhe (referências acima).
- 2026-10-01: cena aprovada ("agora sim ficou massa").

## Export e jogo
- Nomes dos assets usam o **id do planeta no jogo** (`luna_*`), não o nome em inglês — o Godot procura por id.
- No jogo a câmera centraliza a nave: o terreno ocupa metade da tela. A faixa de 88 px deixava um bloco plum_dark
  chapado → faixa de 176 px com estrias fundas que escurecem até sumir.
- Lint acusa ~6% de "órfãos" nas faixas: é o dither bayer intencional das transições (igual à cena aprovada).
- Pendente: cortes verticais onde um segmento muda de face (lit/flat/shade); plataformas ainda placeholder.

## Fontes
- https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds — perspectiva atmosférica por plano, névoa na base, faixas de horizonte, escala de textura, 15–16 cores
- https://www.slynyrd.com/blog/2019/11/12/pixelblog-23-parallax-scrolling — camadas em laço, velocidades inteiras, camadas equilibradas sem ponto dominante
- https://tips.clip-studio.com/en-us/articles/3603 — céu noturno: evitar preto puro, horizonte mais claro, brilho em volta da lua
- https://opengameart.org/content/background-clouds-and-mountains-parallax — referência de pacote de montanhas em camadas
