# Mundo 4 — Quarto bagunçado (id `titan`, o planeta "gigante")

- **Slug**: room-scene
- **Tipo**: fundo em camadas + terreno + enfeites (mesmo contrato), animado
- **Assets** ← `art/src/bg/room_scene.py --export`: `assets/bg/titan_{sky,planet,far,mid,plain}.png`,
  `assets/tiles/titan_ground_{lit,flat,shade}.png`, `assets/sprites/titan_rocks.png`, `assets/bg/titan_layers.json`.
  Prévias `art/previews/room_scene_2x.png`, `room_anim.gif`.

## Ideia
Exemplo do próprio usuário ("outro um quarto bagunçado"). A nave é minúscula num quarto enorme — combina com a
gravidade 15 do planeta "gigante". Proposto como padrão quando o usuário disse "continue" sem decidir o 4º mundo.

## Regras (pesquisa)
- Luz **motivada** por uma fonte: abajur com poça quente e queda suave (falloff), luar frio pela janela; longe da
  lâmpada, penumbra (cores descem para a rampa escura).
- Contraste de escala: objetos do dia a dia gigantes, silhuetas reconhecíveis (cama, estante, livros, cubos de letras,
  bola, bloquinhos de montar, robô, giz de cera).

## Como construir
- Parede (camada sky, fixa): listras + estampa de estrelinhas; luz do abajur (`warm()`: cada cor sobe na própria rampa
  quente com dither); luar diagonal; rodapé; prateleira + abajur (fonte da luz, fixo com a poça); pôster de foguete;
  poeira flutuando na luz (anim).
- Janela (camada planet): céu, estrelas cintilando (anim), lua com crateras, telhados com janelinhas, moldura, cortinas.
- Far: cama, estante com livros, guarda-roupa, baú; penumbra com transição **curta** perto da lâmpada.
- Mid: pilha de livros, cubos ABC, bola, torre de bloquinhos (pinos), robô (olho pisca, antena), giz de cera.
- Plain: assoalho (tábuas mais finas ao longe), aquecido perto da lâmpada.
- Chão de pouso: cobertor de tricô listrado (raspberry/cream/navy) com ponto em "V"; mais escuro na face de sombra.
- Enfeites: bloquinho, giz, bolinha de gude, moeda, botão, dado, lápis, pião girando (anim).

## Erros na revisão
- Guarda-roupa alto cobria a janela → janela mais alta e guarda-roupa mais baixo.
- Penumbra com mistura pontilhada larga deixava brinquedos/móveis "granulados" → brinquedos sem penumbra; móveis com
  transição curta.

## Decisões do usuário
- 2026-10-01: aprovado; nome exibido **O Quarto (mundo gigante)**; meta final vira "Expedição ao Quarto".

## No jogo
- A parede NÃO pode ser um céu preso à tela: os móveis sobem/descem e cobriam abajur/janela → `wall_mode` no
  `titan_layers.json`: parede e janela acompanham o horizonte como os móveis. A parede é exportada com 200 px a mais
  em cima (`sky_y` = -200), continuando até o teto (moldura), para não abrir buraco quando a nave sobe.

## Fontes
- https://omidsaffari.com/resources/visible-sources — luz noturna motivada por um abajur: queda, cor derramada, oclusão
- https://www.deviantart.com/vanmall/art/How-to-make-a-pixel-lamp-123100045 — abajur em pixel art (interiores)
- https://opengameart.org/content/pixel-art-parallax-background — fundos de parallax em pixel art
- https://itch.io/game-assets/newest/free/tag-pixel-art/tag-tiny — escala: personagem minúsculo em mundo grande
