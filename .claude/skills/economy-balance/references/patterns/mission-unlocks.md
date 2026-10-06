# Liberação gradual dos tipos de pedido (missões)

- **Slug**: mission-unlocks
- **Onde na spec**: (proposta) `contracts.cargo[].unlock`, `contracts.pad_tiers[].unlock`
- **Intenção de design**: o jogador começa só com pedidos simples (caixa, plataforma normal) e cada tipo novo
  chega como um "amigo novo" que ensina uma regra por vez; o jogo vira tutorial sem texto (público de 6 anos).

## Como jogos de referência fazem (pesquisa)
| Jogo | Fórmula / números | Observação |
|---|---|---|
| Slay the Spire | pontuação acumulada dos runs libera conteúdo em limiares (300, 750, 1000…) | liberar jogando, não comprando; nunca compete com o dinheiro do run |
| Hades II (Fated List) | lista de desafios; cada um dá recurso/desbloqueio | guia o jogador a experimentar mecânicas novas |
| Hades (armas) | armas compradas com Chaves (moeda própria), aspectos por desafio | variedade como "sidegrade", não potência |
| Death Stranding | Likes sobem a reputação; depois aparecem versões "premium" (sem dano, rápido) dos mesmos pedidos | dificuldade opcional sobre o pedido já conhecido |
| Good Pizza, Great Pizza | 100+ clientes, cada um com visual e personalidade; pedidos mais complexos com o tempo | o cliente É o sinal visual do tipo de pedido |
| Dead Cells | meta-progressão libera áreas e mecânicas novas cedo e rápido | a liberação de conteúdo é curta perto do resto da progressão |

## Armadilhas conhecidas
- Liberar comprando com o mesmo dinheiro dos upgrades cria escolha ruim ("variedade ou motor?") e o jogador
  pode nunca comprar o conteúdo, perdendo o tutorial.
- Liberar devagar demais deixa o começo monótono; o conteúdo novo precisa chegar cedo (Dead Cells).
- Tipos de pedido com multiplicador de pagamento: liberar depois reduz a renda do começo → simular.

## Modelagem aqui
- (pendente — aguardando decisão do usuário)

## Efeito medido (simulação)
| Métrica | Antes | Previsto | Depois |
|---|---|---|---|

## Decisões do usuário
- 2026-10-06: usuário propôs árvore de liberação de missões + ratinhos com visual distinto por tipo; método de
  liberação em aberto (pediu pesquisa).
- 2026-10-06: missões viram **regras abstratas** (não presas a um item): pesada (indicador de peso), pouso suave,
  rápida (relógio), táxi (2 passos, ida e volta), cabo. Cada uma com nível de dificuldade e recompensa que cresce
  com ele. Proposta: 3 estrelas por tipo + missões duplas no fim (aguardando aprovação/simulação).

## Fontes
- https://www.gamedeveloper.com/design/motivating-mechanics-in-game-design- — liberar aos poucos para apresentar mecânicas
- https://slaythespire.info/en/how-to-unlock-characters-cards-and-relics-spoiler-warning/ — limiares de pontuação acumulada
- https://hades.fandom.com/wiki/Fated_List_of_Minor_Prophecies/Hades_II — lista de desafios que guia a meta-progressão
- https://www.gamebrief.net/glossary/meta-progression — definição; Hades: armas por Chaves, aspectos por desafio
- https://blog.playstation.com/2019/11/07/hit-the-ground-running-with-these-day-one-death-stranding-tips/ — Likes → reputação; pedidos premium
- https://en.wikipedia.org/wiki/Good_Pizza,_Great_Pizza — clientes únicos com visual/personalidade
