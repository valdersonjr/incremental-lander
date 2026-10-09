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

## Cartão do pedido (2026-10-06)
- Usuário escolheu a maquete D (`art/previews/offer_card/`, script `art/src/ui/offer_card_mockups.py`): as 3
  plataformas são os botões de partir, com o prêmio de cada uma; sem gás e sem botão de ir ("nave verde é feia").
- Células novas (no fim de `NAMES`): `pad_normal/pad_narrow/pad_tight` (meia largura 10/7/4, receita de `pad()`),
  `dist_1..3` (perto/médio/longe: caminho pontilhado da plataforminha até a bandeira; a 1ª versão com 1/2/3 pegadas
  não dava para distinguir — o que lê é a **bandeira mais longe**), `check`/`cross` (traço de 3 px; 2 px sumia).
- Balão de fala: `assets/ui/balloon.png` (9-slice 16, margem 5, creme com luz white em cima-esquerda e sombra peach)
  + `balloon_tail.png` (6x9, encaixa por cima da borda esquerda em x = balão - 5). Fonte em `art/src/ui/ui_kit.py`.
  O 1º rabinho (fino, 1 px de ponta) parecia solto: gordinho de 4 px na base.
- Fonte extra: https://icelivin.itch.io/dialog-bubbles (balões de diálogo pixel em 9-slice, rabinho como peça à parte)

## Badge da Reputação (2026-10-07)
- Pedido: "o indicador de reputação na tela poderia ser um badge". 3 propostas em HTML (medalha com coração, roseta com
  estrela, escudinho do ratinho), cada uma acesa/apagada e montada sobre a captura do HUD. **Escolhido: escudinho do
  ratinho** (`art/src/ui/rep_badge.py`, células `rep_on`/`rep_off` do atlas kids). Apagado = mesma forma em cinza
  (mist/steel), o padrão de buff ativo/inativo; ao acender dá um pulinho (UiKit.pulse).
- Corações (2026-10-07): `heart_on`/`heart_off` 13x11 no atlas kids (Reputação por ratinho, padrão Stardew); o
  escudinho virou o selo de "melhor amigo!" no nível máximo.
- Lição: fitas de medalha em 24 px somem atrás do disco; forma de escudo lê melhor e o rostinho conversa com os ratinhos.

## Fontes
- https://www.shadcn.io/icon/game-icons-padlock (forma clássica do cadeado: alça em arco + corpo + fechadura)
- https://itch.io/post/16155772 (idle: mostrar o próximo desbloqueio para o jogador poder se planejar)
- https://icelivin.itch.io/dialog-bubbles (balão de fala pixel em 9-slice)

## Despertador (2026-10-07)
`clock`: tempo jogado nos cartões de save. Sininhos gold nos cantos de cima, disco `sky` + mostrador branco/mist,
ponteiros ink (12h e 3h) com pino raspberry; lê bem em 16 px.
- https://design.tutsplus.com/tutorials/quick-tip-create-a-nice-award-medal-icon--vector-4433 — anatomia de medalha (disco + fitas)

## Ícones das ajudas de voo (2026-10-09, ROADMAP 16.5)
- `art/src/ui/assist_icons.py` → 7 células no fim do atlas (`assist_color`, `assist_trail`, `assist_route`,
  `assist_shadow`, `assist_level`, `assist_predict`, `assist_gas`); `RoadText.stop_icon` usa nas paradas da Estrada.
- Regra: cada ícone mostra **o que a ajuda desenha no voo** (seta tricolor, pontinhos do arco, arco entre plataformas,
  sombra no chão, régua de nível, X da queda, marquinha na barra de gás). Nave = **mini lander 11x8 com o gatinho**
  (o ícone "navezinha" foi reprovado pelo usuário). Chão de queijo (honey/amber) = Lua.
- Acrescentar sempre no FIM da lista (as células antigas ficam idênticas; conferido comparando com o HEAD).
- Usuário aprovou a página antes/depois nas bolinhas da Estrada (`art/previews/assist_icons/index.html`): "ok".

