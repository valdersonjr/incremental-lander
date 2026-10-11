# Incremental Lander — Documento de Design (GDD)

> Documento vivo. **Números** de economia NÃO moram aqui: a fonte única é `data/economy.json`
> (tabelas abaixo são um retrato da spec **v8**, 2026-10-05). Mudou a spec → atualize o retrato.

## 1. Conceito
Jogo **incremental** estilo **Lunar Lander**, **visão lateral**, feito em **Godot 4.7** para **computador**
(teclado). Cada **run** tem **gás limitado**; o jogador pilota um lander fazendo **entregas** entre
plataformas de pouso para ganhar dinheiro e melhorar a nave (motor/velocidade, tanque, eficiência…),
indo cada vez mais longe na **Lua de queijo** (por enquanto o único mundo — 2026-10-06), com tipos de entrega
liberados aos poucos e **automação** mais tarde (frota de drones). Prestígio, outros planetas e o megaprojeto final
saíram em 2026-10-06 (ficam no git para voltar depois).

Pilares:
1. **Pilotar bem sempre vale mais** — precisão paga até ×2,2; piloto ruim gasta mais gás. Upgrades ampliam, não substituem.
2. **Sem esperas** — sempre há algo para comprar em minutos; paredes curtas.
3. **Sempre algo novo** — tipos de entrega liberados aos poucos, cada um ensina uma regra.
4. **Duração total é flexível**; qualidade do ritmo > horas.

## 2a. ESTRUTURA ATUAL — "Mais longe" (v21, 2026-10-11; substitui o cartão de missões do §2 no jogo)
Auditoria de clareza (https://claude.ai/artifact/FxVbgBPYA478S6mdTL3rhT): um jogador experiente não entendeu
"planeta → mapas → missões". Usuário escolheu a opção C (estilo Hill Climb Racing):
- **1 tanque = 1 viagem** numa pista fixa por mundo, só para a frente. Sem cartão, sem trocar de mapa.
- Plataformas em sequência; pousar em qualquer uma à frente paga **pela distância do começo** (× qualidade × tamanho);
  pular uma e pousar na seguinte = +25%. Para trás não paga.
- O **relevo sobe** quanto mais longe (morros mais altos = cada salto custa mais gás): é o que encerra a viagem.
- **Galões** no ar pelo caminho (12 de gás, cada vez mais espaçados), **moedas no ar** entre as plataformas,
  **placas a cada 1 km** que pagam na 1ª vez em cada mundo, **bandeira do recorde** no chão.
- **Estrela = nota do pouso** (1 ok · 2 bom · 3 perfeito); as estrelas andam na Estrada do mundo e abrem o próximo.
- Batida acaba a viagem (o ganho fica); o aprendiz (< 10 estrelas) volta para a última plataforma.
- Fora no modo pista: cartão de missões, ratinhos/regras, minijogos, Reputação, presentes, cansaço 2×, bônus de
  recorde de dinheiro (voltam depois como trechos da pista, um de cada vez). Números: `data/economy.json > contracts.track`.

## 2. Loop principal
```
[Hangar/loja] → decolar → escolher entrega (distância × pagamento) → voar (salto balístico) →
pousar na plataforma (qualidade 0..1) → receber → próxima entrega … até o gás acabar (ou bater)
→ resumo do run → [Hangar/loja] comprar upgrades → …
```
- **Bata seu recorde (v15, 2026-10-07)**: o run **não tem teto de entregas**. Termina só quando o **tanque esvazia de
  verdade** (ou em batida; o que já foi ganho fica): pedido que parece longe demais fica em vermelho, mas pode ser tentado. A nave "cansa": cada missão do run gasta **2×** (v19; era 1,7×) o gás da
  anterior (`contracts.run_fatigue`; o galão devolve gás ÷ o mesmo fator) — o run sempre acaba, e Gasolina/Eficiência
  viram "mais entregas por run". A meta é do jogador: bater os próprios recordes (dinheiro do run em destaque).
- Entregas **se renovam**: a cada entrega feita, uma nova oferta aparece (o gás é sempre o limite).
- **Pagamento (v19, auditoria da progressão 2026-10-09)**: taxa fixa por entrega + distância suave
  (`pay_base × (0,3 + (d/100)^0,7)`); o gás cresce com `sqrt(g·d)`. Longe rende ~2× mais dinheiro por minuto, perto
  rende ~4–5× mais **estrelas** por minuto (entrega rápida) — troca visível "longe = dinheiro, perto = Estrada". Antes
  (`d^1,1`) longe + apertada pagava 17× por gás e nenhuma outra escolha fazia sentido.
- **Variedade das entregas (v7, 2026-10-03)** — cada oferta é uma escolha de risco, não só de distância:
  - **Plataformas**: normal ×1 · **estreita ×1,25** · **apertada ×1,5** (v19; prêmio de risco — padrão Lunar Lander: alvo pequeno paga mais).
  - **Reputação por ratinho** (v14, substitui o Combo; padrão Death Stranding/Stardew): cada ratinho (tipo de pedido)
    tem **3 corações** permanentes = **+10% / +20% / +30%** nos pedidos **dele**. Missão com a regra cumprida = 1 ponto,
    com **pouso perfeito** (reto e macio: inclinação ≤ 25% e V.vert ≤ 40% do limite, `world.json > landing.perfect`) =
    2 pontos; falhou ou bateu = 0. Limiares provisórios 5/15/30 pontos. No voo: rostinho + corações do ratinho da
    entrega; no "Você ganha": coração + bônus; ao subir: aviso "X gosta mais de você". Aba **REPUTAÇÃO** na PROGRESSÃO
    (cartão por ratinho, "faltam N", silhueta dos não liberados; nível máximo = escudinho "melhor amigo!").
  - **Presentes no alto do morro (v10, 2026-10-06)**: metade dos saltos tem um presente no ponto mais alto do relevo
    entre as plataformas. Encostar **devagar** pega (perto e < 6 m/s; não é pouso). **Galão de gás** devolve 30% do
    tanque na hora; **presentinho** vale 30% do pagamento-base, pago junto com a entrega (bater perde). Opcional: descer
    no morro custa gás e é arriscado. Salto de resgate não tem (o ratinho ocupa o meio).
  - ~~Cristais no arco~~ — removidos na v9 (2026-10-05): o usuário não viu diversão; o arco ideal virou ajuda de voo.
  - O relevo tem **cristas** entre as plataformas: um arco bom passa por cima, voar rente ao chão não compensa
  - ~~Perigos por mundo~~ (vento, gêiseres, ventilador, bloquinhos) — saíram com os outros mundos (2026-10-06).
- **Missões abstratas com estrelas (v12, 2026-10-06)** — substituem as cargas fixas (bolo/sorvete/queijão/ratinho).
  A missão é uma **regra**; o item só decora. Cada tipo tem ★1–★3 e paga mais quanto mais difícil (falhar paga menos,
  nunca acaba o run). Quem oferece é um **ratinho de visual próprio por tipo** (arte na Etapa C).
  | Tipo | ★1 | ★2 | ★3 |
  |---|---|---|---|
  | Simples | ×1 (sempre) | | |
  | Pesada (motor ÷, indicador de peso) | ÷1,3 ×1,2 | ÷1,6 ×1,45 | ÷2,0 ×1,8 |
  | Pouso suave (V.VERT ≤ % do limite) | 70% ×1,2 | 50% ×1,4 | 35% ×1,7 |
  | Rápida (relógio na tela) | 1× ×1,2 | 0,8× ×1,4 | 0,65× ×1,7 |
  | Passageiro | resgate passando devagar ×1,3 | táxi: pousa para buscar e leva de volta (2º trecho = metade) ×1,5 | táxi com busca na plataforma estreita e volta inteira ×1,8 |
  | Cabo (carga pendurada) | cabo curto/leve ×1,4 | longo ×1,7 | longo/pesado ×2,0 |
  | Dupla | duas regras juntas: 1 + soma dos extras (teto ×3) | | |
  **Pedidos (v12.1)**: **um pedido por ratinho** — o mineiro (Simples) oferece perto, médio e longe; cada ratinho
  liberado traz 1 pedido; entregou, o mesmo ratinho repõe. No cartão o jogador **escolhe o tamanho da plataforma**
  (normal ×1 · estreita ×1,25 · apertada ×1,5) e a **dificuldade** (estrelas liberadas); falhar a ★3 paga bem menos
  (×0,3) que a ★1 (×0,6). Teclado: cima/baixo = plataforma, Shift + cima/baixo = estrela; o jogo lembra a última escolha
  de cada ratinho.
  **Tela de escolha = janela de conversa (2026-10-07)**: no alto, a **fila com todos os ratinhos** do planeta, sempre na
  mesma ordem — um rostinho por tipo, com o prêmio da escolha marcada; os ainda não liberados ficam em **silhueta** (álbum
  de figurinhas). Embaixo, a **janela**: o **gatinho herói** conversa com o **ratinho** (corpo inteiro, segurando a
  carga) sobre um palco da Lua; **um balão** com o pedido ("Meu bolo é fofinho!") e a regra com certo × errado
  ("Pousa bem devagarinho, senão amassa!"). Escolhas em **colunas**: Distância (perto/médio/longe, quando o ratinho tem
  mais de um pedido — hoje o mineiro; no futuro qualquer um) | Tamanho da plataforma | Dificuldade (estrelas). Botões só
  com texto; embaixo só o **"Você ganha"** final + **ACEITAR MISSÃO** (gatinho faz joinha "Deixa comigo!", ratinho
  comemora). Gás pouco: o gatinho fica preocupado e avisa.
  **Cada missão no seu mapa (v15)**: ao escolher, a tela escurece e a nave desce do céu numa plataforma de um lugar novo
  (sem gastar gás). O relevo combina com a regra: Pesada = subida até o alvo; Pouso suave = alvo no alto de uma mesa;
  Rápida = caminho baixo; Cabo = cratera no meio; resgate = ratinho no fundo de uma cratera; táxi = busca num degrau.
  **Paisagens (v15, 2026-10-07)**: cada mapa sorteia uma paisagem liberada e varia altura, morros e desnível dentro dela —
  Planície e Colinas desde o início; Serra (8★), Vale (20★), Planalto (37★), Crateras (56★) e Degraus (78★) chegam
  pela Estrada das Estrelas (`world.json > terrain.landscapes`; preview aprovado `art/previews/paisagens/`). A regra da
  missão continua valendo por cima. O fundo acompanha a altura média do chão (vale não mostra o "pé" do cenário).
  O que liga as entregas do run é o tanque.
  **Liberação jogando** (padrão Hades/Dead Cells): cada entrega dá **1 estrela**; **3 estrelas** liberam um nó na aba
  **PEDIDOS** da oficina (★1 de Pesada/Suave/Rápida abertas; Passageiro e Cabo pedem 2 tipos ★1; ★N pede ★N-1; Dupla
  pede ★3 em 2 tipos).
- **Lua mais divertida (v8, 2026-10-05)** — *(as cargas viraram as missões da v12)* pesquisa do que falta no gênero (Space Taxi, Thrust, Lunar Lander Beyond,
  Death Stranding), aplicada só na Lua, no tema "Lua de queijo dos ratinhos":
  - **Pedidos para os dois lados**: ~45% dos pedidos nascem à esquerda (pino na coluna da borda esquerda); voltar por
    cima de plataformas antigas não muda nenhuma delas.
  - **Cargas com regra própria** (figura no pino, no cartão e no HUD; falhar paga menos mas **não acaba o run**):
    caixa de queijo (normal) · **bolo de queijo** (frágil: pouso bem suave, V.VERT fica mais exigente) · **sorvete**
    (prazo: barra derretendo enquanto voa) · **queijão no cabo** (pêndulo pendurado na nave, puxa e balança; não pode
    bater forte no chão) · **ratinho perdido** (no meio do caminho: passe devagar pertinho para ele pular na nave).
  - **Habilidades** compráveis na oficina (botões embaixo da nave): **Estabilizador** (segurar S/↓: a nave volta a
    ficar de pé) e **Turbo** (segurar Shift: motor com o dobro da força, gasta gás mais rápido).

## 3. Pilotagem (física) — **a implementar e calibrar**
- Controles (teclado): girar esquerda/direita, propulsor; Esc pausa o voo (volumes + lista de controles). (Detalhes finais na skill `godot-dev`/Fase 1.)
- Gravidade do planeta, arrasto/vento, gás consumido por Δv (`efficiency` = m/s por unidade de gás).
- Pouso: velocidade vertical/horizontal, ângulo e distância ao centro da plataforma → **qualidade q (0..1)**.
- **Sensação do voo (auditoria do voo, 2026-10-11)** — o pouso é o centro do jogo e tem que ser gostoso do começo ao fim:
  - **Giro com rampa**: toque gira devagar (ajuste fino, ~1,5 rad/s), segurar acelera até 4,2 rad/s em 0,22 s.
    **Ímã do em pé**: soltando as teclas a menos de ~6° da vertical, a nave assenta reta (ajuda escondida).
  - **Empuxo sentido com teto**: o voo usa `g + teto suave(a − g)` (até 3,5 m/s² igual, depois tende a 8). Motor forte
    não vira "toquinho de 1 quadro"; o Motor continua valendo para decolar em mundos pesados, carga Pesada e marcos.
    Turbo (×2) é o "força total" quando o jogador quer.
  - **Raspão quica**: encostar fora da plataforma devagar (até 9 m/s contra o chão × Resistência^0,5) quica, pisca e
    conta um amassado; 2 por salto, o 3º (ou um forte) explode.
  - **Pouso duro**: na plataforma, até 1,25× as tolerâncias vale como pouso (nota baixa, "tum" forte).
  - **Resistência** amplia as tolerâncias só ×gear^0,25 (máx ~×1,36; antes ×1,84) e vale mais no casco (raspão).
- O modelo econômico assume salto balístico: `Δv ≈ 2·sqrt(g·d)·(1 + 0.707·g/a)·(1+drag)·desperdício + 2·g·pairar`
  (ver `.claude/skills/economy-balance/references/run-model.md`). O jogo real deve **exportar telemetria**
  para calibrar esse modelo (Fase 10).

## 4. Terreno
**Polígono irregular** (padrão das skills: `pixel-art/references/terrain-tiles.md` §7 + modelo de run da
`economy-balance`): encostas em vários ângulos, **plataformas de pouso planas** como alvos, textura pixel
art contínua (`Polygon2D` com textura seamless) + faixa de superfície na borda.

## 5. Mundo — só a Lua por enquanto (v11, 2026-10-06)
**Decisão do usuário (2026-10-06): polir ao máximo o primeiro mundo e ignorar os outros por enquanto.** Silvânia,
Docelândia e O Quarto (com perigos, minério, Expedição e final) foram **removidos do jogo**; ficam no histórico do git
(commit anterior a "Só a Lua") para evoluir a ideia depois.
| Mundo | Gravidade | Arrasto | Distâncias | Pagamento |
|---|---|---|---|---|
| Lua (`luna`) | 1,62 | 0 | 100–15.000 m | ×1 |
Sem objetivo final por enquanto (decisão do usuário): o jogo é a Lua, as melhorias e os recordes pessoais.

**Cenas vivas de fundo (2026-10-02)** — só ambientação, **sem história nem progressão** (usuário: "não precisa
deixar com história forte... a ideia era só algo passando de fundo mesmo").
- **Lua — mina de queijo dos ratinhos** (2026-10-05): sem coelhos nem alienígenas (pedido do usuário); ratinhos
  minerando, vila e parquinho dos ratinhos, caminhão de queijo na estrada. Não interage com o jogo.
- Terreno da Lua: crosta de regolito com crateras sobre blocos de basalto (2026-10-02).

## 5b. PROGRESSÃO — Estrada das Estrelas (v13, 2026-10-07)
A tela entre runs (antes "Oficina") mostra **toda a progressão desde o início** (padrão Trophy Road / passe de batalha).
- **Estrada da Lua** no topo: 29 paradas em ordem (Mineiro → ratinhos ★1–★3 e Dupla, Estabilizador, Turbo, 7 ajudas,
  Frota, Piloto automático → "Lua completa!"). **Cada entrega dá 1 ⭐; as estrelas não se gastam**: andam com a
  navezinha e cada parada libera sozinha o prêmio (ratinho = tipo de pedido; habilidade/ajuda = já vem pronta;
  Frota/Piloto = passam a poder ser comprados). Próxima parada pulsa com "faltam N"; clicar abre balão (figura, o que
  traz, quanto falta). Ao voltar do voo a navezinha anda e cada parada nova faz festa (ratinho ★1 = "Novo amiguinho!").
  Estrelas por parada = **rascunho** (`economy.json > progression.road`).
- **Moedas compram só as 4 peças da nave** (Motor, Gasolina, Eficiência, Resistência) em **degraus de 10** (I, II, III…:
  10 bolinhas, festinha e a peça **cresce no desenho** da nave). Seletor ×1 / ×10 / MÁX. **A nave só evolui quando o
  degrau sobe** (v20, pedido do usuário): as bolinhas são parcelas do próximo degrau; o efeito vem inteiro ao completar.
- Abas NAVE · AJUDAS (ligar/desligar; as que faltam mostram o lugar na estrada) · FROTA (cadeado até a parada). A aba
  PEDIDOS saiu (os ratinhos estão na estrada).

## 6. Upgrades (créditos)
| Upgrade | Efeito | Observação |
|---|---|---|
| Motor | +6 m/s² por degrau (0,6 × 10; v20: só no degrau) | vence gravidades maiores; no voo, empuxo sentido com teto |
| Gasolina (tanque) | +80 de gás por degrau (v19: +8/nível; v20: só no degrau) | alcance e entregas por run |
| Eficiência (bocais) | +1,5 Δv por gás por degrau (v19: +0,15/nível; v20: só no degrau) | alcance |
| Resistência (trem de pouso) | casco: raspão mais forte quica; tolerâncias um pouco maiores (retorno decrescente) | só no degrau |
| Estabilizador (habilidade) | segurar S/↓: nave volta a ficar de pé | vem pela Estrada (v13) |
| Turbo (habilidade) | segurar Shift: empuxo ×2 | vem pela Estrada (v13) |
| Frota de drones | cada drone rende uma fração (8% → ~17% com o Piloto automático) da **sua** renda média | 8M créditos (v11), liberada pela Estrada (v13); até 10 |
| Piloto automático | melhora a fração da frota | 16M; liberado pela Estrada e pede 1 drone |
| ~~Marcos~~ (saíram na v29: o pagamento não sobe com o degrau das peças) | a cada **degrau** (10 níveis) de Motor/Gasolina/Eficiência: pagamento ×1,25 (v19) — o salto visível junto da peça crescendo no desenho; cada nível sozinho rende pouco | estilo AdVenture Capitalist |

## 6b. Painel de bordo — árvore de ajudas de voo (v9, 2026-10-05)
Compras **de informação**, não de potência: mostram, não pilotam (o pouso continua na mão do jogador; o pagamento não
muda). Vêm prontas pela Estrada das Estrelas (v13; antes compra única em créditos); cada uma pode ser desligada (aba AJUDAS da PROGRESSÃO).
| Galho | Ajudas (em ordem) |
|---|---|
| Onde ir | **Setinha** (grátis: seta em volta da nave aponta a plataforma) → Setinha colorida (80: azul longe, amarela, verde chegando + pulsa) → Rastro (800: pontinhos do arco ideal só à frente) → Rota completa (8K: o arco inteiro) |
| Pousar | Sombra (150: marca no chão + tracejado) → Nivelador (500: linha verde/amarela/vermelha da inclinação perto do chão) → Onde vou cair (5K: queda sem motor + X verde/amarelo/vermelho) |
| Gás | Dá pra chegar? (2K: marquinha na barra = gás que sobra ao chegar pelo arco ideal; vermelha = não chega) |

## 7. Prestígio e fase final — removidos (2026-10-06)
O usuário pediu tirar o prestígio (Poeira Estelar, loja, recomeço) e a fase final (Expedição ao Quarto). A Frota e o
Piloto automático continuam, liberados por créditos (§6). **Recordes pessoais (v15, "bata seu recorde")** — todos medidos num run: **dinheiro do run** (o principal),
entregas, distância voada, pousos perfeitos e maior entrega. No voo, o placar do canto (variante A) mostra o dinheiro
grande com a barra até o recorde (troféu) e os outros quatro como "valor/recorde"; o que passa fica dourado e o dinheiro
avisa "NOVO RECORDE!". No fim do run (variante "troféus"): dinheiro grande + cartões que viram troféu com "NOVO!".
Na PROGRESSÃO, a faixa de recordes (troféu + os 5 números) fica embaixo da nave.

## 8. Primeiros minutos (auditoria FTUE, 2026-10-08)
Relatório: https://claude.ai/artifact/Eme3BchGnN7iMng1rGbNSg (pesquisa: Andersen 2012, Passalacqua 2020, SDT, Hodent,
Daniel Cook, Nintendo, Pecorella, NN/g, Budge, Toca Boca). Regras em `data/world.json > onboarding` (não é economia).
- **Jogo novo abre o Mapa** (revisão 2026-10-09; antes começava voando e o jogador "caía" no voo sem saber onde
  estava): só a Lua aberta e o **passeio do Mapa** (abaixo) que termina em VOAR ("Voe!"). VOAR → o 1º salto já vem aceito (perto, 160 m; plataforma
  normal; chão quase plano; sem minijogo), sem a conversa da missão, e o aviso grande diz "Pouse! na plataforma do outro
  lado". **Toda chegada num mundo** mostra o nome dele no alto (★ LUA ★) por ~1,4 s. O fim do run volta ao Mapa (ou à
  NAVE se dá para comprar), também para o aprendiz.
- **Aprendiz** (menos de 5 entregas no jogo): bater ou ficar sem gás **não acaba o run**. A nave volta para a partida
  do mesmo salto com o gás do começo dele e o aviso "TENTE DE NOVO!" diz o jeito de acertar. Depois de 2 repetições
  (ou sem gás) o salto não repete mais: a nave volta para a partida e o cartão abre ("OUTRA MISSÃO!") — missão difícil
  demais nunca prende o jogador. O run do aprendiz também só acaba com o tanque vazio: um pedido que o gás não
  alcançava na escolha pode ser tentado, mas sem a proteção (bater ou ficar sem gás nele acaba o run).
  **Revisão (validação contra os mais vendidos, 2026-10-08)**: depois das repetições (ou sem gás) vem o **"Veja como!"**
  (Super Guide do New Super Mario Bros. Wii): o piloto automático voa o mesmo salto, apertar o motor ou girar devolve a
  nave e a entrega vale; só se o guia também falhar o cartão abre. Antes da 1ª entrega todo salto tem relevo baixo
  (quem desiste do 1º não ganha um mais difícil). O **Nivelador** fica emprestado durante o aprendiz (Smart Steering do
  Mario Kart). Ao fazer a 5ª entrega: **"PILOTO FORMADO!"** com festa (daqui em diante bater acaba a viagem).
  **"Tente de novo" sem texto**: depois da batida, uma nave pontilhada (fantasma) refaz o movimento certo em cima da
  plataforma alvo e ganha ✓; a nave volta para a partida com um **balão** mostrando a mesma cena em miniatura até
  decolar. O aviso diz só "TENTE DE NOVO!" (sem gás: só o balão, com o voo em arco). **Só na 1ª batida do jogo**
  (pedido do usuário); nas seguintes, "TENTE DE NOVO!" com a frase curta.
  **Sem "Veja como!"** (desligado a pedido do usuário: o jogo não pilota sozinho; `onboarding.guide` false): passou das
  repetições → cartão para escolher outra missão.
- **Passeios da 1ª vez** (revisão 2026-10-09, pedido do usuário: "explicar tudo no mapa de antemão"; protótipo
  `art/previews/map_tour/index.html`, opção A): na 1ª vez que cada tela aparece, um balão por elemento (figura + frase
  curta + "1/4"), clique ou tecla avança, Esc pula, uma vez só. **Mapa**: mundos → Estrada → moedas/estrelas → NAVE →
  "Voe!" (ou "Melhore!" na NAVE se já dá para comprar). **NAVE**: cartão da peça → 10 bolinhas = 1 degrau (a peça
  cresce no desenho) → abas (Q/E) → "Compre!" (ou "Decole!"). **AJUDAS** (ao abrir a aba): o que são e que vêm pela
  Estrada → LIGADA/DESLIGADA → a que ainda vai chegar. **REPUTAÇÃO** (ao abrir): o ratinho gosta mais a cada entrega →
  barra cheia = pedidos pagam mais. Regra da revisão: **dica só aponta ação que dá para fazer** — saíram "Mapa!" (NAVE),
  "Ajuda!" + "Liga/desliga" e o "Novo!" da REPUTAÇÃO; o "Novo!" da FROTA só quando dá para comprar o 1º drone.
- **Destaques de 1ª visita (histórico; o que segue valendo: "Aceite!", "Compre!", 2º mundo)** (só em menus, no máximo 2 passos por tela, cada um uma vez; protótipo aprovado
  `art/previews/menus_intro/menus_intro.html`): tela escura em xadrez menos o botão, moldura dourada, balão com figura
  + 1 palavra (e teclas, quando ensinam atalho) e mãozinha tocando. 1º cartão → ACEITAR MISSÃO ("Aceite!"); 1º Mapa →
  NAVE com "!" ("Melhore!") ou VOAR ("Voe!"); NAVE → a peça que dá para comprar ("Compre!") e depois o botão **MAPA**
  ("Mapa!", novo, ao lado do DECOLAR: antes só o Esc voltava); aba AJUDAS quando aparece ("Ajuda!") → LIGADA
  ("Liga/desliga"); abas novas REPUTAÇÃO e FROTA ("Novo!" + teclas Q/E); 2º mundo aberto → o planetinha ("Novo!" +
  setas ← →). "PILOTO FORMADO!" diz onde fica o Nivelador (é seu, na NAVE; ou ganhe de volta na Estrada). Clicar fora
  fecha (e encerra a fila daquela visita). Pousar devagar e reto
  fora da plataforma para a nave no chão ("decole de novo!"). Pedidos que o gás não alcança ficam escondidos.
- **Ensinar sem texto, só quando falta** (Coach): parado na partida → teclinha do motor "apertando" em cima da nave;
  no ar sem girar → as teclinhas de girar. Somem no 1º uso e nunca voltam. **Medidor de descida** ao lado da nave
  perto do chão (verde/amarelo/vermelho, todo jogador).
- **Uma coisa nova de cada vez**: minijogo a partir da 2ª entrega; placar de recordes depois do 1º run; corações de
  reputação, abas REPUTAÇÃO/FROTA depois do aprendiz; AJUDAS quando a Estrada dá a 1ª; ×10/MÁX depois de 5 níveis.
- **Caminho curto até a compra**: fim do run com dinheiro para uma peça → CONTINUAR abre a NAVE (a peça pulsa);
  aprendiz sem compra → voa de novo; senão o Mapa, que mostra as moedas e "!" na NAVE quando dá para comprar.
- **Batida que ensina**: o resumo diz o que deu errado e como acertar ("segure o motor perto do chão…").
- **Metas** (medir com `session.csv` + `godot-dev/scripts/ftue.py`): decolar ≤ 10 s, 1ª entrega ≤ 60 s, ≥ 70% dos
  novatos entregam no 1º run, 1ª compra ≤ 4 min, criança de 6 anos joga 10 min sem ajuda (`docs/PLAYTEST_KIDS.md`).

## 9. Ritmo esperado (simulado, spec v11 — só a Lua)
Primeira compra logo após o 1º run (novato simulado, 2026-10-08: mediana ~5 min com a regra do aprendiz; §8); Motor e Reputação chegam ao nível 80 em ~6–8 h; 1º drone ~2 h (engajado);
pior espera entre compras ~11–12 min na 1ª hora (≈ 1 run do modelo, que ainda dura ~9 min: calibração pendente).
Script: `balance/sims/2026-10-06-v11-moon-only.py`.

## 10. Direção de arte e som
- **Arte**: pixel art **fofa/cozy** (referência: Shelldiver; desde 2026-10-04) — o lander é pilotado por um **gatinho
  astronauta** numa cúpula de vidro sobre um disco branco + turquesa, propulsor de plasma ciano; personagem e
  primeiro plano com contorno escuro, cor chapada, formas redondas. Mundos de **conto de fadas**, não realistas:
  a Lua é a "Lua de queijo" (pôr do sol rosado, coelhinhos, Terra dormindo); demais mundos a refazer no mesmo método.
  Paleta **Resurrect 64** travada, lander 32×32, tiles/texturas 16×16, resolução
  interna **640×360** (escala inteira). Tudo via skill `pixel-art` (`references/style-guide.md`).
- **Som**: retro-synth espacial 100% sintetizado, escala em D, loudness por categoria, via skill
  `sound-design` (`references/style-guide.md`). Trilha: música calma de menu/hangar (D maior) e de voo (D lídio),
  ambiência da Lua, alarme de gás baixo que não irrita, jingles de marco/liberação/conquista.
  **Auditoria de som (2026-10-09)**: cada mundo com ambiência própria e a mesma música de voo (~2 min) com uma
  camada do mundo (o tema muda de instrumento: sinos, marimba, bolhas, flautinha, celesta, sopro); gramática de menu
  (mover quase mudo, confirmar sobe, voltar desce, balão "pop"), pausa abafa a música, cada coleta com som próprio,
  pouso e turbo com intensidade, jatinhos de giro, motor tossindo sem gás, sons das mecânicas (gelo, vento, bolhas),
  contagem do resumo com tiques e vinheta; batida **fofa** (puf + apito de desenho) para o público infantil.

## 11. Técnico
Godot 4.7.2 (renderer Compatibility) · desktop (Mac/PC/Linux; presets em export_presets.cfg) · teclado (teclas
remapeáveis) e controle (A/RT propulsor, analógico gira, LB/RB abas, Start menu) · tela cheia (opção, F11, Alt+Enter) ·
tremor de tela opcional · 640×360 viewport, escala inteira (janela 1280×720) ·
filtro Nearest · snap de pixel · buses de áudio Master/Music/Ambience/SFX→Engine/UI ·
**5 jogos salvos** independentes (menu inicial → Jogar → um cartão por jogo com tempo, créditos e estrelas; jogar, novo jogo; X ao lado apaga com 2 cliques), autosave no
jogo em uso; volumes e último jogo usado são globais ·
economia em `data/economy.json` + `scripts/economy/econ_math.gd` (paridade testada com o Python).

## 12. Em aberto
- Controles exatos e sensação de voo (Fase 1). · Geração dos mapas (procedural? quantos por planeta?).
- Nome final do jogo (o menu inicial usa "INCREMENTAL LANDER" provisório) e logo em pixel art.

## Minijogos dos mundos (v17; auditoria aplicada em 2026-10-08)
Um pedido-assinatura por mundo, jogado só com a nave. Regras de design (relatório: https://claude.ai/artifact/1kffVyZpAtd3MmubEaw7wg):
- **Falhar nunca acaba o run e paga pela parte feita** (crédito parcial), nunca tudo-ou-nada.
- **A estrela maior pede mais do minijogo** (mais itens, vão menor, baú mais fundo, menos tempo), nunca paga de graça.
- **Nada invisível**: vento com sementes, onde a nave para no gelo (pino), o baú pisca enquanto molha, seta para item
  fora da tela; acerto e erro com sons diferentes.
- **Só oferece a estrela que a nave controla** (folga de empuxo por mundo).
- Minijogo bem feito = selo ("MINIJOGO COMPLETO!", "minijogos completos n/N" no resumo); as estrelas da Estrada
  continuam 1 por entrega.
| Mundo | Minijogo | ★1 → ★3 |
|---|---|---|
| Lua | trilha de queijinhos (bônus 15/40/75% do pagamento-base × queijinhos) | 6/9/11 itens, arco até +120 m |
| Nuvens | fila de carneirinhos (cai = volta para o lugar) + correntes | 1/3/5; na ★3 um dentro da corrente |
| Cogumelos | escada de chapéus-mola até acima da casa (bônus 15%) + ovinho | 1/3/3 chapéus; pouso 0,7/0,5/0,35 × vy máx |
| Sorvete | curling na pista de gelo + relógio do picolé | anel pela plataforma; relógio 1/0,8/0,65 |
| Jardim | vãos entre caules + vento visível + mel pesado | 2/4/6 caules, vão 120/95/75 m, vento 1,5/2,3/2,8 |
| Bolhas | garra do baú + mar + bolhas | baú a 6/14/24 m do mar, 1,6/1,1/0,8 s para tirar |

