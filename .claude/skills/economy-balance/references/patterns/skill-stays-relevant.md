# Habilidade continua importando (upgrades não substituem pilotar)

- **Slug**: skill-stays-relevant
- **Onde na spec**: `contracts.quality_bonus`, `contracts.quality_exp`, `contracts.regenerate`,
  `contracts.max_per_run`, perfis (`waste`, `skill`)
- **Intenção de design**: pilotar bem sempre rende mais do que pilotar mal, do início ao fim. Upgrades
  ampliam o alcance; não tornam a precisão irrelevante.

## Como jogos de referência fazem (pesquisa)
| Fonte | Ideia | Observação |
|---|---|---|
| Design de multiplicadores | dividir a recompensa: base (volume) + multiplicador de habilidade | casual ganha a maior parte; habilidade dá o extra |
| Streaks / combos | multiplicador progressivo por acertos seguidos | recompensa consistência |
| Risco × recompensa | desafio maior oferece multiplicador maior | planetas difíceis pagam mais |
| GMTK (roguelites) | meta-progressão forte ⇒ "grind to win" e dificuldade invertida | upgrades modestos |
| Incrementais | automação/upgrades tornam o desafio inicial trivial | escalar o desafio com o poder |

## Armadilhas conhecidas
- **Saturação de alcance**: se os upgrades permitem fazer TODAS as entregas ofertadas, o gás deixa de
  ser o limite e o desperdício do piloto para de custar (rascunho v2: vantagem do expert caiu de
  2,9× na nave inicial para 1,3× no nível 10).
- Bônus de qualidade linear e pequeno (+50% no máximo) quase não diferencia um pouso ótimo de um médio.

## Modelagem aqui
- `contracts.regenerate = true` (nova oferta após cada entrega → o gás volta a ser o limite),
  `max_per_run = 20` (segura a duração do run), `quality_bonus = 1.5`, `quality_exp = 2`
  (q=0.9 → ×2.2; q=0.55 → ×1.45). Extensão em `econ.py` (`do_run`) e `econ_math.gd` (`contract_pay`).

## Efeito medido (simulação, 2026-09-29)
| Métrica | v2 | Previsto | Medido (candidato v3, MC 3 seeds) |
|---|---|---|---|
| Renda expert/casual, nave nível 0 → nível 10 | 2.9× → 1.3× | nível 10 ≥ 1.8× | 3.6× → 1.6× |
| Término casual / expert | 14.2 h / 13.9 h (1.02) | 1.25–1.6 | 18.4 h / 11.1 h (1.66) |
| Ordem de término | casual ≈ expert < engaged | expert < engaged < casual | 11.1 < 15.2 < 18.4 ✓ |
Lições: bônus de precisão linear (+50%) mal separa os jogadores; a saturação de alcance era a causa
principal da perda de vantagem; ofertas que se renovam mantêm o gás como limite.

## Fontes
- https://amara.org/v/C3BEW — GMTK, Roguelikes, Persistency and Progression
- https://www.kucoin.com/news/insight/STAR/6a9404c3dd2c0d0007d57269 — base (volume) + multiplicador de habilidade
- https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol — tensão entre upgrades e desafio
