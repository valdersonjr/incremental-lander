# Interface "para crianças" — atlas kids (células 24x24)

- Fonte: `art/src/ui/kids_ui.py` → `assets/ui/kids.png` + `assets/ui/kids.json` (nomes na ordem das células).
- Peças: pinos de pedido, rostinhos de clientes, estrelas, moedas, figuras antes → depois das melhorias,
  e (2026-10-05) **`lock`** (cadeado) e **`mystery`** (bolacha com "?") para mostrar o que ainda vai liberar.
- Novas células vão **sempre no fim** de `NAMES`, para não mudar os índices das existentes.

## Cadeado / mistério (2026-10-05)
- Pedido do usuário: o jogador precisa ver que existem coisas futuras (frota, planetas, prestígio).
- Padrão do gênero: o próximo desbloqueio fica visível, apagado e com cadeado, com o que falta para liberar.
  Itens distantes aparecem como silhueta + "?".
- Cadeado: alça de 1 px em arco desenhada à mão com `paint` (a 1ª versão, com elipse por distância, ficou
  "cheia" e parecia uma cúpula), alça em steel/lilac_grey e corpo gold com luz lemon (em cima e à esquerda) e
  sombra amber. A fechadura é um buraco redondo com fenda, desenhado em ASCII (com `disc` ficava parecendo uma cruz).
- Mistério: `badge` cinza (lilac_grey/slate) com "?" branco de 2 px de traço.
- No jogo, a silhueta da peça é feita em runtime (`modulate = BLACK` no ícone 12x12); não precisa de asset.

## Fontes
- https://www.shadcn.io/icon/game-icons-padlock (forma clássica do cadeado: alça em arco + corpo + fechadura)
- https://itch.io/post/16155772 (idle: mostrar o próximo desbloqueio para o jogador poder se planejar)
