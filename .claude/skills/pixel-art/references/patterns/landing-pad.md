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

## Tipos de plataforma (Fase 11, 2026-10-03)
- Script parametrizado (`Pad(kind)`): deck 64 (normal) / 40 (estreita) / 28 (apertada); sprite = deck + 16 px;
  contrato igual (topo do deck na linha 10, deck começa em x=8) → canto sup. esq. em (pad.x − half − 8, pad.y − 10).
  Feixe do alvo na largura do deck → (pad.x − half, pad.y − 84). A normal sai idêntica à aprovada (checado pixel a pixel).
- **Risco por cor + forma** (acessível a daltônicos: nunca só a cor): normal turquesa; estreita âmbar com **traços**
  na face do deck; apertada vermelha com **listras de perigo** amarelo/preto em diagonal. O jogo escreve o
  multiplicador ("×1,5"/"×2,2") junto da plataforma, como o Lunar Lander de 1979.
- O feixe do alvo continua turquesa em todos (cor = "alvo").
- Lição: só a faixa âmbar fina não se lia na cena → padrão próprio na face (traços) resolveu.

## Decisões do usuário
- 2026-10-01: pediu "algum brilhosinho pra deixar mais óbvio o lugar de pouso" → feixe de luz + pista iluminada no
  deck do alvo + marcador acima do feixe.

## Lições
- Feixe denso no miolo escondia o lander: miolo leve (26%), bordas fortes.
- Marcador dentro do feixe some: colocar acima.
- Prévias de assets novos: recompor a cena aprovada a partir das camadas (`moon_scene.load_layers()` +
  `ingame_preview(with_lander=False)`), nunca procurar o chão por cor (pegou o lander).

## Fontes
- https://en.wikipedia.org/wiki/Lunar_Lander_(1979_video_game) — multiplicador piscando, maior quanto mais estreita a área
- https://bugnet.io/blog/colorblind-friendly-game-design — nunca comunicar só por cor: somar forma/padrão/valor
- https://itch.io/devlog/534932/colour-coded-challenge-ranks.amp — verde/amarelo/vermelho como níveis de dificuldade
- https://www.slynyrd.com/blog/2018/12/12/pixelblog-12-to-the-stars — pintura em faixas fortes sobre base neutra
- https://assetstore.unity.com/packages/2d/environments/pixel-art-scifi-space-station-52070 — plataformas sci-fi side-view com luzes de status
- https://opengameart.org/content/sideview-sci-fi-patreon-collection — plataformas/ambientes sci-fi em vista lateral
- https://sunnyneo.com/tutorial/psblinkie.php — luzes piscando: quadro de pausa, velocidade variada por quadro
- https://community.aseprite.org/t/shading-metal-in-aseprite/4889 — painéis de metal pela rampa, não linha preta
