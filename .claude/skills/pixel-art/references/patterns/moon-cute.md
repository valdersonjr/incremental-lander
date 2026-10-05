# Lua fofa (cena completa no estilo cute-style)

- **Slug**: moon-cute
- **Tipo**: bg em camadas + terreno + sprites da guerra
- **Grade**: cena 640x360; mesmo contrato da Lua anterior (`moon-scene.md`, `moon-war.md`, `moon-ground.md`)
- **Assets** ← `art/src/bg/moon_cute.py --export`: `assets/bg/luna_{sky,planet,far,mid,plain}.png`,
  `assets/tiles/luna_ground_{lit,flat,shade}.png`, `luna_body.png`, `luna_depth.png`, `assets/sprites/luna_rocks.png`,
  `war_saucer.png`, `war_saucer_far.png`, `war_blast.png`; atualiza `assets/bg/luna_layers.json` (pos. da guerra).
  Prévia: `art/previews/moon_cute_2x.png` (sem exportar).

## Regras aplicadas (pesquisa + cute-style)
- Fundo: formas simples e chapadas, **sem pontilhado**; transições de faixa com **borda ondulada** (seno em laço).
- Tons frios no fundo; cores quentes só nas luzes (janelas, luzinhas, brasa) — budgetpixel "cozy scene".
- Terreno de plataforma: **linha escura em cima + destaque claro logo abaixo** = "dá para pisar"; cobertura ondulada
  (bolinhas de 32 px, fecha no laço de 128); corpo liso com crateras redondas; escurecimento em faixas onduladas.
- Montanhas em **gota** (perfil `1-(dx/w)^2` elevado a 0,7), face iluminada/sombra chapadas separadas por linha inclinada.
- Personagens de fundo (nave-mãe, discos) ganham **alienzinho com olhos grandes**; explosão = estrela → bola → pufes.
- Valores: céu ink → shadow → slate; colinas distantes shadow (silhueta contra o horizonte slate); montanhas
  lilac_grey/slate; planície shadow → ink; terreno lilac_grey com aro white/mist.

## Erros corrigidos na revisão
- Colinas distantes da mesma cor da faixa do céu sumiam → faixa slate começa mais alto (172).
- Fumaça em pufes soltos parecia pontos no ar → coluna contínua saindo da rachadura (4 pufes defasados).
- `charcoal` na planície puxava para verde → só shadow/ink.
- Manchas do chão em círculo perfeito pareciam buracos → elipses largas e achatadas.
- Crateras de elipse fina viraram "morcegos" → cratera de 3 linhas (fundo 5–7 px + lábio claro).

## v1 → v2 (usuário: "não ficou nada fofo, tudo muito sério; a Lua não precisa ser fiel à realidade")
- **Lição principal: traço fofo + cor escura/cinza continua sério.** Fofo pede **cor clara e pastel** e coisas
  "impossíveis" de conto de fadas, não fidelidade. A paleta cinza clássica (escolha de 2026-10-02) foi abandonada.
- v2: 3 temas (THEMES A algodão-doce, B queijo, C menta) com as mesmas formas; + coelhinhos da Lua (morrinhos e chão),
  Terra dormindo com bochecha, planetinha com anel, estrelas de 5 pontas com contorno, nuvenzinhas, contorno `ink`
  no topo das montanhas, chão claro com furinhos redondos (queijo/cratera fofa).
- Shaders (permitidos pelo usuário) ficam para movimento no jogo (balanço, pulsar, quicar) mantendo a paleta.

## v2 → v3 (usuário: "muito fofo, mas mal desenhado, como se uma criança tivesse feito")
- Causas do "amador": contorno `ink` em TUDO (livro de colorir), 2 tons cortados por reta, formas repetidas e
  perfeitas, sem perspectiva atmosférica, nuvem de 3 bolas chapadas, crateras em círculo perfeito espalhadas por igual.
- Correções: **contorno colorido** (tom escuro da rampa) no cenário e `ink` só em personagens; morro = **elipsoide**
  (normal de bola: brilho redondo no alto-esquerda; com `u = dx/largura_da_linha` vira "gomos" — errado), 4 tons +
  oclusão na base; **2 fileiras** (trás puxa para a cor do céu) com larguras assimétricas; céu em 5 faixas com
  transição curta em xadrez; nuvem = bolas com normal própria + base reta + contorno colorido; chão com estratos
  ondulados e crateras em **elipse** (perspectiva) com fundo escuro em cima e lábio claro embaixo.
- Crateras pequenas nos morros pareciam "olhinhos fechados" aleatórios → removidas.

## v3 → v4 (autoavaliação pedida pelo usuário; "então arruma tudo") — tema B "Lua de queijo"
- Problema de fundo: arte **gerada por fórmula** (mesma forma repetida, faixas iguais, elementos espalhados por igual).
- **Composição**: poucos elementos e maiores (2 coelhos 15x18, 3 bases 44x32, 3 nuvens, 5 brilhos sem contorno);
  nada de "poeira" de estrelinhas/discos.
- **Silhueta por morro** (altura, larguras esq/dir, expoente, topo achatado, calombos) em 2 fileiras; bases/coelhos
  apoiados SÓ nos topos da fileira da frente (senão flutuam sobre a de trás).
- **Sombreamento cel** que acompanha a silhueta (`cel()`): distância até a borda na direção da luz → faixa clara
  (largura ~30% da altura), borda oposta e base → sombra. Substitui o elipsoide (que fazia anéis/listras).
- **Céu** = degradê de 6 tons com transição bayer reta de 16 px (não listras onduladas serrilhadas).
- **Hierarquia de valor**: morros de trás quase da cor do horizonte e sem contorno; frente saturada com contorno colorido.
- **Contorno**: cenário = cor escura da própria rampa; personagens/veículos = ink.
- Fumaça = pufes grandes e sobrepostos (uma nuvem só); com raio pequeno e espaçamento grande vira "colar de contas".
- Rosto da Terra: bochecha logo abaixo do olho fechado lia como "boquinha" → bochecha por fora e abaixo.

## v4 → v5 APROVADA (kit desenhado + Scale2x, vista no jogo)
- Usuário perguntou se dava para fazer peças pequenas e ampliar: morros/nuvens viraram **peças de kit** com
  silhueta por pontos de controle em meia resolução, cel + contorno colorido, **Scale2x**. 1ª tentativa saiu com
  morros estreitos/pontudos e nuvens-caixa → x dos pontos ×1,7 e base da nuvem arredondada.
- Exportado e capturado **no jogo** (HUD, câmera, parallax): aprovado — "agora a gente tá conversando.. melhorou
  PARA UM CARALHO". Receita consolidada em `../cute-scene-method.md`.
- Pendentes no estilo antigo: plataforma de pouso (todas as variações) e o painel do HUD.

## Decisões do usuário
- 2026-10-04: "refaça a lua" no estilo fofo (depois de aprovar o gatinho).
- 2026-10-04: v1 cinza → "nada fofo, muito sério; a Lua não precisa ser fiel à realidade"; v2/v3 → "muito fofo mas
  mal desenhado"; v4 → autoavaliação e "arruma tudo"; v5 (kit + Scale2x, no jogo) **aprovada**. Tema escolhido:
  **B "Lua de queijo"**.

## Fontes
- https://budgetpixel.com/blog/how-to-create-a-cozy-pixel-art-scene-in-5-steps — cozy: formas simples, tons frios no fundo, quentes só nas luzes, 16–32 cores
- https://www.udemy.com/tutorial/create-stunning-pixel-art-tilesets-for-games/grass-tileset/ — tileset de plataforma: contorno escuro + destaque sob a linha de cima
- https://nesdev.org/wiki/Drawing_terrain — terreno legível: borda de cima marcada
- Capturas do Shelldiver enviadas pelo usuário — fundo em silhueta lisa, primeiro plano contornado
