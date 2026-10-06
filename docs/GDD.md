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

## 2. Loop principal
```
[Hangar/loja] → decolar → escolher entrega (distância × pagamento) → voar (salto balístico) →
pousar na plataforma (qualidade 0..1) → receber → próxima entrega … até o gás acabar (ou bater)
→ resumo do run → [Hangar/loja] comprar upgrades → …
```
- Run termina quando o gás não alcança nenhuma entrega, após **6 entregas** (teto) ou em batida
  (o que já foi ganho fica).
- Entregas **se renovam**: a cada entrega feita, uma nova oferta aparece (o gás é sempre o limite).
- Pagamento cresce com a distância (`d^1.1`), custo em gás cresce com `sqrt(g·d)` → ir mais longe
  compensa, mas exige gás num salto só.
- **Variedade das entregas (v7, 2026-10-03)** — cada oferta é uma escolha de risco, não só de distância:
  - **Plataformas**: normal ×1 · **estreita ×1,5** · **apertada ×2,2** (padrão Lunar Lander: alvo pequeno paga mais).
  - **Combo**: cada pouso bom seguido (q ≥ 0,55) soma +10% no pagamento, até +50%; pouso ruim zera.
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
  (normal ×1 · estreita ×1,5 · apertada ×2,2) e a **dificuldade** (estrelas liberadas); falhar a ★3 paga bem menos
  (×0,3) que a ★1 (×0,6). Teclado: cima/baixo = plataforma, Shift + cima/baixo = estrela; o jogo lembra a última escolha
  de cada ratinho.
  **Tela de escolha (v15, 2026-10-06)**: no alto, a **fila de rostinhos** (um por pedido, com o prêmio; o mineiro mostra
  perto/médio/longe em figura; cinza = o gás não chega). Embaixo, o **cartão** do escolhido: ratinho + carga, **balão de
  fala** com a regra em 2–3 palavras ("Devagarinho!", "Tá pesado!"…) e as **3 plataformas como botões de partir**, cada
  uma com o prêmio — clicar já parte. Sem barra de gás e sem botão "vamos" no cartão.
  **Cada missão no seu mapa (v15)**: ao escolher, a tela escurece e a nave desce do céu numa plataforma de um lugar novo
  (sem gastar gás). O relevo combina com a regra: Pesada = subida até o alvo; Pouso suave = alvo no alto de uma mesa;
  Rápida = caminho baixo; Cabo = cratera no meio; resgate = ratinho no fundo de uma cratera; táxi = busca num degrau.
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

## 6. Upgrades (créditos)
| Upgrade | Efeito | Observação |
|---|---|---|
| Motor | +0,6 m/s² por nível | vence gravidades maiores, menos perda por gravidade |
| Gasolina (tanque) | ×1,12 gás por nível | alcance |
| Eficiência (bocais) | ×1,07 Δv por gás | alcance |
| Reputação | ×1,1 pagamento | — |
| Resistência (trem de pouso) | reduz batidas (retorno decrescente) | — |
| Estabilizador (habilidade) | segurar S/↓: nave volta a ficar de pé | compra única (Lua em diante) |
| Turbo (habilidade) | segurar Shift: empuxo ×2 | compra única |
| Frota de drones | cada drone rende uma fração (8% → ~17% com o Piloto automático) da **sua** renda média | 8M créditos (v11); até 10 |
| Piloto automático | melhora a fração da frota | 16M; pede 1 drone |
| **Marcos** | a cada 25 níveis de Motor/Gasolina/Eficiência/Reputação: pagamento ×1,5 | estilo AdVenture Capitalist |

## 6b. Painel de bordo — árvore de ajudas de voo (v9, 2026-10-05)
Compras **de informação**, não de potência: mostram, não pilotam (o pouso continua na mão do jogador; o pagamento não
muda). Compra única em créditos, cada uma pode ser desligada (aba AJUDAS da oficina).
| Galho | Ajudas (em ordem) |
|---|---|
| Onde ir | **Setinha** (grátis: seta em volta da nave aponta a plataforma) → Setinha colorida (80: azul longe, amarela, verde chegando + pulsa) → Rastro (800: pontinhos do arco ideal só à frente) → Rota completa (8K: o arco inteiro) |
| Pousar | Sombra (150: marca no chão + tracejado) → Nivelador (500: linha verde/amarela/vermelha da inclinação perto do chão) → Onde vou cair (5K: queda sem motor + X verde/amarelo/vermelho) |
| Gás | Dá pra chegar? (2K: marquinha na barra = gás que sobra ao chegar pelo arco ideal; vermelha = não chega) |

## 7. Prestígio e fase final — removidos (2026-10-06)
O usuário pediu tirar o prestígio (Poeira Estelar, loja, recomeço) e a fase final (Expedição ao Quarto). A Frota e o
Piloto automático continuam, liberados por créditos (§6). Recordes pessoais (maior entrega, salto mais longo, maior
combo, run mais rico) ficam numa faixa no topo da oficina e como "NOVO RECORDE" no resumo do run.

## 9. Ritmo esperado (simulado, spec v11 — só a Lua)
Primeira compra logo após o 1º run; Motor e Reputação chegam ao nível 80 em ~6–8 h; 1º drone ~2 h (engajado);
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

## 11. Técnico
Godot 4.7.2 (renderer Compatibility) · desktop (Mac/PC/Linux; presets em export_presets.cfg) · teclado (teclas
remapeáveis) e controle (A/RT propulsor, analógico gira, LB/RB abas, Start menu) · tela cheia (opção, F11, Alt+Enter) ·
tremor de tela opcional · 640×360 viewport, escala inteira (janela 1280×720) ·
filtro Nearest · snap de pixel · buses de áudio Master/Music/Ambience/SFX→Engine/UI ·
**5 jogos salvos** independentes (menu inicial → Jogar → um cartão por jogo com a progressão: missões liberadas, créditos, runs, tempo; jogar, novo jogo, apagar com 2 cliques), autosave no
jogo em uso; volumes e último jogo usado são globais ·
economia em `data/economy.json` + `scripts/economy/econ_math.gd` (paridade testada com o Python).

## 12. Em aberto
- Controles exatos e sensação de voo (Fase 1). · Geração dos mapas (procedural? quantos por planeta?).
- Nome final do jogo (o menu inicial usa "INCREMENTAL LANDER" provisório) e logo em pixel art.
