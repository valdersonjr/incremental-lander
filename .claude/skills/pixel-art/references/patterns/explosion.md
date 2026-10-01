# Explosão da batida + poeira do pouso

- **Slug**: explosion
- **Tipo**: fx (animações sem loop)
- **Grade**: explosão 64x64 (2x o lander, centro = posição do lander) · poeira 48x16 (linha 15 = chão)
- **Assets**: `assets/sprites/explosion.png`, `assets/sprites/landing_dust.png` (+ `_frames.tres`)
  ← `art/src/fx/explosion.py --export`

## Características (pesquisa + references/animation.md)
- Explosão: flash de 1 quadro com maior contraste → bola de fogo cresce → fragmenta (buracos, pedaços deslocados) →
  fumaça escura se dissipa. 6–10 quadros, 40–80 ms no início e 100+ ms na fumaça. Sem contorno; contraste de valor.
- Método saint11: começar com forma cheia (círculo/elipse) com brilhos, depois apagar seções e mover subseções.
- Fogo na rampa `fire`, mais claro perto da fonte; fumaça `neutral`. Destroços 1–2 px voando para fora.
- Poeira: 4–6 quadros, 80–120 ms, expande, clareia e some; clusters, não dither.

## Como foi feito
- Flash = núcleo de plasma da nave rompendo (white + anel ice + raios aqua) → liga a explosão ao estilo futurista.
- Fogo: sombreamento **radial** (emite luz do miolo). Fumaça e poeira: sombreamento **direcional** (corpo plano,
  borda de cima-esquerda clara) — radial deixava a fumaça com cara de bolha/esfera.
- Fragmentação: buracos aleatórios na bola + tufos de fumaça separados saindo por cima (cortar a bola por uma
  linha reta deixava uma "tampa" cinza estranha).
- Destroços do casco (white/mist/sea/steel) em arco balístico com gravidade.
- Poeira achatada na horizontal (cauda mais longa para fora), rente ao chão.

## Erros na revisão
- Núcleo extra desenhado por cima da bola virava quadrados brancos → removido; o gradiente radial já dá o núcleo.
- Poeira redonda/alta parecia fumaça subindo → achatada.

## Decisões do usuário
- 2026-10-01: aprovado na primeira prévia.

## Fontes
- https://blog.0x17.de/post/pixel_animations/ — reprodução dos tutoriais do saint11: forma primitiva + brilhos, depois erodir e mover subseções
- https://opengameart.org/content/pixel-explosion-12-frames — referência de explosão em 12 quadros
- https://weentermakesgames.itch.io/dust-cloud-pixel-art-particles — tipos de poeira (horizontal, para cima, pouso)
- https://kiddolink.itch.io/vfx-collection-vol-8-pixel-art-effects/purchase — referência de VFX (explosão, fumaça, energia)
