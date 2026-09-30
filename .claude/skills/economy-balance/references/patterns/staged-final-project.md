# Projeto final em etapas (megaprojeto)

- **Slug**: staged-final-project
- **Onde na spec**: upgrades com `progress: true`, `persistent: true`, `requires_upgrade`;
  `planets.titan.requires_upgrade`
- **Intenção de design**: trocar "uma compra gigante no fim" (que gera horas de só juntar dinheiro) por
  uma sequência de metas curtas e visíveis, cada uma com recompensa — a Expedição a Titan.

## Como jogos de referência fazem (pesquisa)
| Fonte | Ideia | Detalhe |
|---|---|---|
| Universal Paperclips | quando o crescimento achata, investir num "avanço" abre a próxima fase | 3 estágios com estilos de jogo diferentes; o último é exploração espacial com frota de drones |
| Space Station Designer | megaprojeto final ("Lunar Space Elevator") como série de marcos | cada marco pede várias moedas + tarefas; amarra todos os sistemas numa meta final |
| Efeito do gradiente de meta | motivação cresce perto da recompensa | segmentar a barra de progresso; 1ª etapa fácil ("freebie") dá impulso |

## Armadilhas conhecidas
- Objetivo final único e caro ⇒ fase longa de "só juntar" (medido: 250–450 min sem compras antes de Titan).
- Etapas sem recompensa própria viram só "um preço dividido em 8".
- Etapas que resetam no prestígio ⇒ jogador perde o megaprojeto; aqui elas são **persistentes**.

## Modelagem aqui (v6)
- 8 etapas = upgrades `max_level 1`, `progress: true` (o jogador virtual trata como meta de progressão),
  `persistent: true` (não resetam no prestígio), `requires_upgrade` = etapa anterior; a 1ª exige o Motor de
  dobra (`requires_shop`). Titan: `requires_upgrade = {exp8_aurora: 1}`, custo simbólico.
- Custos: 200B × 1,7^i créditos + minério (1% do valor) — o minério ganha uso no fim do jogo.
- Bônus por etapa: pagamento ×1,2 (1, 3, 5), tanque ×1,25, eficiência ×1,15, motor ×1,15,
  autopilot ×1,3, Aurora pagamento ×1,25.
- Nomes: Estação Orbital de Apoio → Tanques Criogênicos → Escudo Térmico Ablativo → Rede de Satélites
  de Navegação → Módulo de Habitação → Reator de Fusão Compacto → Âncora Gravitacional → Nave-mãe Aurora.

## Efeito medido (simulação, MC 3×5, 2026-09-29)
| Métrica | Antes (v4 / v5 exploração) | Previsto | Medido v6 |
|---|---|---|---|
| Pior espera antes de Titan (engaged) | 474 min (v4); 250–450 min (frota/marcos sem etapas) | < 60 min | ≤ 24 min (engaged), ≤ 30 min (expert) |
| Curvas testadas (triagem) | — | — | 100B×2,2: 40–70 min; 100B×2,6: 105–140 min; **200B×1,7: 31–43 min** (escolhida) |
| Etapas (engaged, seed 1) | — | a cada 10–30 min | 3,5 h → 5,7 h, espaçadas 10–40 min |
Lições: (1) a última etapa de uma série geométrica é a mais cara — crescimento ≤ 1,7–1,8 evita a parede
final; (2) etapas com bônus próprio mantêm a renda crescendo durante o megaprojeto; (3) com marcos +
etapas o jogo encurtou muito (~5 h) — alongar exige mais conteúdo, não custos maiores.

## Fontes
- https://universalpaperclips.fandom.com/wiki/Stages — estágios e avanços
- https://en.wikipedia.org/wiki/Universal_Paperclips — platôs exponenciais quebrados por projetos
- https://store.steampowered.com/app/4964260 — (resultado de busca) megaprojeto em marcos com várias moedas
- https://medium.com/design-bootcamp/goal-gradient-effect-and-the-psychology-of-progress-bars-df6fd889fd8e — gradiente de meta, barras segmentadas
- https://www.gamified.uk/2013/11/27/gamification-quests-objectives-goals-and-more/ — dividir metas grandes em submetas com recompensas
