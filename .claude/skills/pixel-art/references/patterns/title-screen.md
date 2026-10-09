# Tela de título (key art + logo + gatinho herói)

- **Slug**: title-screen
- **Tipo**: bg + sprite + ui
- **Grade**: cena 640x360; gatinho herói 102x115 (k=1.6), nave "pôster" 80x70, logo 164x66
- **Assets**: `assets/bg/title_{sky,clouds,back,front}.png`, `assets/sprites/title_{cat,flag,lander,star}.png`
  (+ `_frames.tres`), `assets/ui/logo.png`, `assets/bg/title_layout.json` ← `art/src/title/title_moon.py` (usa
  `title_concepts.py`, `art/src/sprites/cat_hero.py`, `art/src/ui/logo.py`); conceitos em
  `art/previews/title_concepts/index.html`, versão final `A_v3.html`

## Por que o pedido
Usuário (2026-10-06): "planejar uma tela do menu iniciar própria pro jogo sem ter que usar o primeiro mapa";
"pesquise telas profissionais, o que geralmente tem e como ficar chamativo para vender a ideia de um jogo
sensacional"; "o gatinho astronauta tem que estar na tela, personagem principal" (grande, fora da nave); o nome do
jogo tem que estar na tela; botões em coluna à esquerda.

## O que as telas boas têm (pesquisa)
1. **Um foco forte que diz do que é o jogo** (Celeste: a montanha que se vai escalar, letras embaixo puxando o olho
   para cima; Xenoblade: espada vermelha num campo ao pôr do sol).
2. **O herói num momento de carisma/calma** (Witcher 3: Geralt meditando; Animal Crossing: um morador diferente a
   cada vez). Silhueta forte, 2–3 cores principais.
3. **Cena viva mas calma**: animações pequenas (piscar, aceno, brilhos, chama); Stardew tem animações escondidas.
4. **Botão de jogar dominante**, menu limpo e em lugar fixo (Apple WWDC17 "design for first impressions").
5. O estilo do título = o estilo do jogo (imersão imediata).

## Como construir
- **Gatinho herói** (`cat_hero.Cat(k)`): primitivas (esfera/cápsula) em coordenadas de desenho k=1, multiplicadas
  por k; contorno ink de 1 px no fim → mesma escala de pixel, mais detalhe. Detalhes do rosto com `n()` (tamanho
  inteiro, nunca menor que em k=1). Capacete-bolha (cabeça ≈ corpo), traje branco + faixa sea (= casco da nave),
  botinhas/luvas aqua, mochila, antena com bolinha rosa, **rabo laranja enrolado de ponta creme** (fica lindo e
  dá silhueta de gato mesmo de capacete).
- **Logo** (`logo.py`): glifo da fonte do jogo → engorda 1 px → Scale2x → degradê de doce (white→lemon→gold→amber→
  orange) + brilho no topo dos traços + base copper + contorno duplo (berry_dark + ink) + sombra sólida.
  **Palavra pequena NÃO engorda** (fecha os vãos de M/N): "INCREMENTAL" em escala 1 sem engordar, azul-gelo;
  "LANDER" escala 3 engordada (a palavra que se lembra).
- **Cena**: kit da Lua de queijo (`moon_cute`: sky_color, cloud, piece, planet, small_dome, scale2x) + morro-palco
  de queijo próprio (`cheese_hill`, furinhos depois do sombreado). Terço esquerdo calmo para logo + menu.
- Nave "pôster" 80x70 com cúpula VAZIA (o piloto está do lado de fora).

## Erros na revisão
- Gatinho em k=1 (64 px) pequeno demais para herói → k=1.6.
- Rostinhos de ratinho soltos no céu/morro = flutuando → só espiando por trás de um plano que os cobre.
- Nave encostando na Terra (tangente) e casinhas pairando sobre a encosta → apoiar com `tops_of` da peça.

## Decisões do usuário
- 2026-10-06: **A "Vitrine"** ("ficou de longe a mais legal, mas dá pra melhorar") + **logo desenhado**.
- v2 (autoavaliação): patinhas dos ratinhos na beira, sombra do gato, bandeira maior tremulando, rabo, luzinhas da
  nave, estrela cadente, queijo de perto no canto.
- v3 (crítica de UI trazida pelo usuário, "gostei, pode aplicar"): logo ~⅓ menor (LANDER escala 2) e respiro;
  frase da proposta; Jogar com 3 estados (foco = moldura, apertado = afunda); respiração do gato (capacete 1 px);
  nuvens à deriva e estrelas cintilando lentas. Frase SEM prometer planetas (o jogo hoje é só a Lua).
- "Arrume o morro": a base reta do morro de trás terminava solta no céu → morro a mais à esquerda + planície
  creme contínua até o chão (camada back).
- No jogo: camadas com 8 px de sobra nas laterais (borda repetida) para o parallax não abrir buraco.

## Fontes
- https://www.destructoid.com/welcome-to-the-game-world-how-video-game-title-screens-tell-their-own-stories/ — foco único, herói em calma, música
- https://developer.apple.com/videos/play/wwdc2017/811 — primeira impressão, CTA dominante, layout consistente
- https://medium.com/swlh/deceptively-simple-design-cabde40af87f — Stardew: o título define o tom
- https://www.gameuidatabase.com/gameData.php?id=53 — Celeste: montanha + letras puxando o olho
- https://www.indiedb.com/news/creating-the-main-menu — personagem vivo/idle no menu

## Fundo dos cartões de jogo salvo (2026-10-07)
Pedido: "lista vertical, com horas jogadas, gold, estrela (sem barra de progresso) e o desenho do mapa atual no fundo".
- `art/src/ui/save_card_bg.py` → `assets/ui/save_bg_<mundo>.png` (244x22 = miolo do cartão compacto 250x28 menos a
  borda de 3 px; o usuário achou a 1ª versão 330x44 grande demais). **Sem pintura nova**: monta o 1º quadro das camadas aprovadas do voo (céu, far, mid, plain) e recorta a faixa
  do horizonte. As camadas são repetidas na horizontal (como no parallax) para o recorte poder passar de x=640.
- Escolha do recorte (revisão em 3 tentativas): o morro de queijo cortado na borda e a mina/carrinho atrás do
  "Jogo N" poluíam; na versão compacta ficou x=420, y=240 (céu limpo à esquerda para o título, só os montinhos; sem cunha/trilho cortados na borda).
- Confirmação ("Gravar por cima?") em vermelho não lê sobre a arte: o cartão fica liso nesse estado.
- Texto sobre a arte: contorno `ink` de 4 (outline_size) nos rótulos — legível sem escurecer a arte.
- Exportar no tamanho exato do cartão e mostrar sem escalar (TextureRect KEEP_CENTERED num Control com clip).

## APROVADA: Noite de história (2026-10-09) — substitui a Vitrine no jogo
Usuário: "Gostei da noite de história" (+ tema a 68 BPM). `art/src/title/title_night.py` exporta em camadas:
`assets/bg/title_night_sky.png` (fixa), `assets/bg/title_night_moon.png` (back, com sobra de 8 px), grupo do pescador
`assets/sprites/title_fisher.png` (16 quadros, recortado na caixa-união; fica DENTRO da camada back para não escorregar
da lua no parallax), `assets/bg/title_night_clouds.png` + `assets/bg/title_night_bank.png` (front). Estrela cadente
reaproveitada. A Vitrine (`title_moon.py`) agora grava `title_vitrine_layout.json` para não sobrescrever o layout.

## 4 estilos novos (2026-10-09)
Pedido: "tela inicial bastante pacata e não tanto bonitinha — 1 melhoria na atual + 3 novas, estilos diferentes, no
navegador". `art/src/title/title_styles.py` → `art/previews/title_styles/index.html` (abas, tema tocando, quadro =
posição da música: 16 quadros por compasso de 92 BPM; com/sem menu).
1. **Festa na Lua** — Vitrine + ratinhos 2x pulando no tempo, balões 2x amarrados no pé da nave, bandeirinhas 2x do
   topo da bandeira à antena, planetinha de anel.
2. **Planetinha** — esfera de queijo r=122 (luz cima-esq., furinhos, borda rust), gato no topo, casinhas 2x na curva
   (base no ponto mais alto das duas laterais), órbita da nave em 2 compassos passando atrás do planeta.
3. **Noite de história** — crescente-barquinho (círculo menos círculo deslocado para cima), gato "hold" sentado com
   perninhas para fora pescando estrela dormindo; banco de nuvens contínuo (soma de círculos) — nuvens do kit
   soltas deixavam uma faixa lisa.
4. **Decolagem!** — nave pôster com a cabeça do gato (k=0,8) recortada na cúpula, rastro = pufes que abrem para baixo
   + núcleo de plasma, riscos diagonais, ratinhos 2x na plataforma, confete.
Revisão antes de mostrar: peças 1x somem perto do herói k=1,6 → Scale2x em ratinhos/balões/casinhas; pacote
pendurado dentro do jato (sem motivo) saiu; Terra cortada no canto → centro em (556, 74); céu com poucos tons
vira faixas largas → mais paradas.
Fontes extras: https://www.fortnite.com/create/creator-marketing-playbook/keyart (diagonal = dinâmico, foco único),
https://reverbinc.com/captivating-versatile-video-game-key-art/ (key art: um foco, cores contrastantes, sem poluição),
https://mori-seika.itch.io/star-planet-pixel-art-scene (planetinha com personagem e casinha)
