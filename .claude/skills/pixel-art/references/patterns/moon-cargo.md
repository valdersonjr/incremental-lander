# Cargas da Lua + ícones de habilidade

- **Slug**: moon-cargo
- **Tipo**: sprites (atlas de células 16x16) — cargas no mundo, no HUD, nos pedidos e ícones da oficina
- **Grade**: 16x16 (item/pickup do guia de tamanhos); queijão com raio 6 px centrado em (7.5, 7.5)
- **Assets**: `assets/sprites/cargo.png` + `cargo.json` (nomes das células) ← `art/src/sprites/cargo.py`

## Por que o pedido
Usuário (2026-10-05): "o que não existir no nosso jogo, adicione de forma divertida e dada a temática do mapa
(faça apenas para a lua)". Tema = Lua de queijo / mina dos ratinhos → cargas: caixa de queijo, bolo de queijo
(frágil), sorvete (derrete), queijão no cabo (rebocado, à la Thrust), ratinho perdido (resgate).

## Regras aplicadas
- Cada carga tem a **versão estragada** (bolo amassado, sorvete derretido, queijo rachado): a criança entende o
  resultado sem ler (público de 6 anos).
- Rostinho (olhos 1x2 afastados, bochecha rosa) no bolo e no sorvete; triste na versão estragada.
- Queijão: casca âmbar fina, massa dourada, **furinhos escuros (terracotta/rust) com borda clara** — v1 tinha brilho
  lemon grande e furos âmbar sem contraste e parecia uma laranja.
- Ratinho de frente: sem boca (só focinho rosa) — v1 com sorriso + focinho ficou embolado.
- Contorno ink em tudo (primeiro plano), 2–3 tons por material.

## Decisões do usuário
- (pendente) aprovação no jogo.

## Fontes
- https://artforkidshub.com/how-to-draw-an-ice-cream-cone-pixel-art/ — casquinha + bolas simples para criança
- https://photonstorm.com/art/tutorials-art/16x16-pixel-art-tutorial — ordem contorno → base → sombra em 16x16
- https://chip-plays.itch.io/50-pixel-food-icons-16x16 — referência de comida legível em 16x16
- https://en.wikipedia.org/wiki/Thrust_(video_game) — carga rebocada por haste (pod) como mecânica
