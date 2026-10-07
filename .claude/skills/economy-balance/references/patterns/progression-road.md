# Estrada das Estrelas (Trophy Road / passe de batalha)

- **Slug**: progression-road
- **Onde na spec**: `progression.road`, `contracts.reputation`
- **Intenção de design**: o jogador **vê toda a progressão desde o início** e sempre sabe qual é o próximo prêmio e
  quanto falta ("incita a querer chegar lá"). As moedas compram potência (peças); as estrelas (jogar) abrem novidades.

## Como jogos de referência fazem (pesquisa)
| Jogo | Fórmula / números | Observação |
|---|---|---|
| Clash Royale (Trophy Road) | troféus acumulados → prêmios em posições fixas, todos visíveis | prêmio seguinte em destaque; a trilha é o "mapa" do jogo |
| Fortnite / passes de batalha | 100+ níveis, um prêmio a cada nível, barra sempre na tela | ninguém gosta de deixar trilha incompleta; progresso mesmo em partida ruim |
| Hades / Rogue Legacy 2 | moeda de meta-progressão ganha em toda run | run ruim ainda conta; desbloqueio de conteúdo, não só número |
| Kingdom Rush | degraus com o próximo aceso | caminho inteiro visível |

## Armadilhas conhecidas
- Paradas espaçadas por igual cansam: use curva crescente (as primeiras saem a cada voo; gradiente de meta).
- Trilha por **alcance** (metros) trava na Lua: o alcance satura em ~14,6 km aos 42 min (simulação v12).
- Duas moedas para a mesma coisa confundem criança: estrela = novidade, moeda = peça.
- Sem a Reputação comprada, a renda do meio/fim cai muito (ela era ×1,1⁸⁰ e marcos ×1,5).

## Modelagem aqui
- Parâmetros (v13, rascunho): 29 paradas; estrelas 1 + 123·f^1,45 (1 → 124); tipos start/mission/grant/unlock/final.
- Reputação (v14): POR RATINHO, permanente: 5/15/30 pontos → +10/20/30% nos pedidos dele; cumprida = 1, pouso perfeito = 2 (modelo: q ≥ 0,85). (v13 tinha +10% na entrega seguinte: trocado no mesmo dia.)
- Extensões: `econ.road_spec/road_reached_now/road_can_buy/reputation_mult`; `EconMath.road/road_reached_now/
  road_can_buy/road_stop/reputation_mult/reputation_bonus`.

## Efeito medido (simulação)
| Métrica | Antes (v12.1) | Previsto | Depois (v13) |
|---|---|---|---|
| Estrada completa (engaged) | — | ~4 h | ~3,5 h |
| 1º drone (engaged) | 1,6 h | mais tarde | não compra em 6 h |
| Pior parede (engaged) | 10–13 min | maior | 32 min |

## Decisões do usuário
- 2026-10-07: Reputação por ratinho (Death Stranding/Stardew) no lugar do bônus por pouso.
- 2026-10-07: escolheu a estrada por estrelas entre 3 protótipos HTML; Reputação = +10% por pouso perfeito (reto,
  macio), bater perde a atual e a próxima; economia fina depois, jogando.

## Fontes
- https://www.gamedeveloper.com/game-platforms/let-s-talk-battle-passes-part-1 — trilha com prêmio a cada nível
- https://www.psychologyofgames.com/2019/07/the-psychology-of-fortnite-s-battle-pass/ — progresso visível, trilha incompleta incomoda
- https://www.ggrecon.com/guides/rogue-legacy-2-skill-tree/ — progressão que vira um desenho que cresce
- https://www.noobfeed.com/articles/death-stranding-2-guide-5-star-connection-levels-unlock-items — conexão por cliente, entrega boa conta mais
