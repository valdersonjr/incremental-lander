# Plataforma de pouso + feixe e marcador do alvo

- **Slug**: landing-pad
- **Tipo**: sprite + animação (pad: idle/target · feixe: pulse · marcador: bob)
- **Grade**: pad 80x28 (deck de 64 = largura de pouso), feixe 64x84, marcador 11x9
- **Assets**: `assets/sprites/landing_pad.png`, `assets/sprites/target_beam.png`, `assets/sprites/target_marker.png`
  (+ `_frames.tres`) ← `art/src/sprites/landing_pad.py --export`

## Contrato com o jogo
- Pad: topo do deck na linha 10 → canto sup. esq. em (pad.x - 40, pad.y - 10). Comum = `idle`; alvo = `target`.
- Feixe: linha de baixo encostada no topo do deck → (pad.x - 32, pad.y - 84). Só no alvo, atrás do lander.
- Marcador: acima do feixe → (pad.x - 5, pad.y - 92). Só no alvo.

## Características (pesquisa)
- Base neutra + faixa de cor forte (mesma linguagem do casco do lander: branco + `sea`).
- Linhas de painel em metal pela rampa (borda clara + sulco escuro), não preto; luz de cima-esquerda.
- Luzes de status: comum apagada (teal escuro), alvo viva; pisca acesa só ~25% do ciclo, com pausa e tempos variados.
- **Brilho com transparência binária**: feixe "translúcido" por dither bayer contra transparente; mais forte nas
  bordas (parede do feixe) e na base, some no alto; partículas subindo.

## Decisões do usuário
- 2026-10-01: pediu "algum brilhosinho pra deixar mais óbvio o lugar de pouso" → feixe de luz + pista iluminada no
  deck do alvo + marcador acima do feixe.

## Lições
- Feixe denso no miolo escondia o lander: miolo leve (26%), bordas fortes.
- Marcador dentro do feixe some: colocar acima.
- Prévias de assets novos: recompor a cena aprovada a partir das camadas (`moon_scene.load_layers()` +
  `ingame_preview(with_lander=False)`), nunca procurar o chão por cor (pegou o lander).

## Fontes
- https://www.slynyrd.com/blog/2018/12/12/pixelblog-12-to-the-stars — pintura em faixas fortes sobre base neutra
- https://assetstore.unity.com/packages/2d/environments/pixel-art-scifi-space-station-52070 — plataformas sci-fi side-view com luzes de status
- https://opengameart.org/content/sideview-sci-fi-patreon-collection — plataformas/ambientes sci-fi em vista lateral
- https://sunnyneo.com/tutorial/psblinkie.php — luzes piscando: quadro de pausa, velocidade variada por quadro
- https://community.aseprite.org/t/shading-metal-in-aseprite/4889 — painéis de metal pela rampa, não linha preta
