# Cristal flutuante (coletável no arco)

- **Slug**: crystal-pickup
- **Tipo**: sprite + animação (spin 8 quadros em laço · pop 4 quadros sem laço)
- **Grade**: 16x16 (guia: pickups = 16), centro em (8, 8)
- **Assets**: `assets/sprites/crystal.png` (+ `_frames.tres`) ← `art/src/sprites/crystal.py --export`

## Contrato com o jogo
- Sprite centrado na posição do cristal; `spin` enquanto flutua; ao coletar toca `pop` e some.

## Características (pesquisa)
- Bipirâmide hexagonal alongada (ponta curta em cima, longa embaixo) com **cinturão** claro: lê como gema, não pedra.
- Rotação falsa: a **aresta** entre a faceta clara e a escura anda de um lado ao outro (vai e volta), largura fixa.
- Brilho branco forte demais é o erro mais citado → faísca curta só em 2 de 8 quadros; facetas em lavender/violet.
- Cor fora das usadas no jogo (roxo): não confunde com o alvo turquesa nem com os mundos (cinza, verde, rosa, azul).
- Estouro sem contorno (efeito): núcleo claro → faíscas em estrela abrindo, cores esfriando até violet.

## Lições
- 7 cores no quadro (rampa purple + ink + white na faísca) bastam; selout + contorno ink seguram contra o céu escuro.

## Fontes
- https://opengameart.org/content/rotating-crystal-animation-8-step — rotação em 8 passos por deslocamento do brilho; crítica a brilho branco forte
- https://opengameart.org/content/animated-spinning-gems — gemas girando como coletáveis
- https://frakassets.itch.io/shiny-gems-pack-1 — gemas giratórias em 12 quadros, versões acesa/apagada
- https://photonstorm.com/art/tutorials-art/16x16-pixel-art-tutorial — sprite 16x16: sombras com versões escuras da base, luz de cima
