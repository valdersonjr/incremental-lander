# Automação: frota de drones que repete suas rotas

- **Slug**: automation-fleet
- **Onde na spec**: `ship.base.drones`, `ship.base.autopilot`, `upgrades.fleet`, `upgrades.autopilot`,
  `upgrades.<id>.requires_shop`, `targets.max_idle_share_pct`
- **Intenção de design**: preencher o fim do jogo (após o Motor de dobra) com uma **mudança de fase**
  (de pilotar tudo para comandar uma frota), sem tornar a pilotagem irrelevante.

## Como jogos de referência fazem (pesquisa)
| Fonte | Ideia | Números |
|---|---|---|
| Idle Mine (dev.to, "7 idle games in 30 days") | automação é transição de fase, não stat | 1º upgrade < 60 s; 1ª automação < 3 min (jogo curto) |
| dev.to / GridInc | estar presente > estar ausente; ausência não pode parecer perda | idle/offline ≈ 50% da taxa ativa; mix sugerido ~60% idle / 40% ativo (não confirmado na fonte primária) |
| Clicker Heroes | builds ativos × idle; híbrido começa ativo e passa a idle quando o progresso desacelera | cliques fortes no início, DPS idle domina no longo prazo |
| AdVenture Capitalist | gerentes automatizam cada negócio (compra única) | automação total, jogo idle puro |
| Boas práticas | não automatizar cedo demais; no meio do jogo dar escolhas novas, não só upgrades mais caros | — |

## Decisão de modelagem aqui
- A renda da frota é **proporcional à renda média do próprio jogador**:
  `renda_frota/s = drones × autopilot × renda_do_jogador/s` → um piloto melhor treina uma frota melhor
  (a habilidade continua importando mesmo no idle, padrão `skill-stays-relevant`).
- `autopilot` (eficiência por drone) começa baixa e tem teto (hyper) — cada drone rende bem menos que você.
- Liberada só após o Motor de dobra (fim do jogo), comprada com créditos → vira o dreno do platô final.
- Meta de mistura: a frota não passa de ~60% da renda no fim (`max_idle_share_pct`).

## Armadilhas conhecidas
- Automação forte demais ⇒ pilotar vira opcional (contraria o conceito do jogo).
- Automação cedo demais ⇒ o jogador nunca aprende a pilotar.
- Só "mais do mesmo" (drones +1, +1, +1) ⇒ precisa de marcos (ex.: cada 5 drones, algo novo).

## Efeito medido (simulação, triagem, 2026-09-29)
| Iteração | Parâmetros | Resultado |
|---|---|---|
| 1 | drone 5% da renda, 1º drone 100B (payback ~3,3 h) | **nunca comprada** — mais lenta que juntar para Titan |
| 2 | 1º drone 20B, 15%→30%, máx 5, custo ×2,5 | comprada em ~7,3 h (mudança de fase ✓), frota ~43% da renda; platô 474 → 248 min |
| 3 | 10 drones ×1,6, 8%→~17% | compras param em ~5 drones: cada drone soma valor fixo e custa 1,6× o anterior |
| + marcos 10 níveis ×1,5 | pay ×1,5 a cada 10 níveis (4 upgrades) + drones | **avalanche** (~×16.000): jogo acaba em 1,3 h; frota 65–74% |
| + marcos 25 níveis ×1,5 | AdCap-like | renda volta a crescer; frota ~54%; **mas a espera final antes de Titan persiste (300–450 min)** |
Lições: (1) automação precisa de payback curto no 1º item para ser "mudança de fase"; (2) itens que
somam valor fixo não sustentam crescimento — a renda do jogador achata ~7 h após o último multiplicador
(Kronos + Motor de dobra); (3) marcos são alavanca fortíssima — dose de AdCap (25 níveis) e nunca em
vários stats a cada 10; (4) **um objetivo final único e caro sempre gera uma longa fase de "só juntar"**,
independente do custo — o jogador racional para de comprar quando o payback passa do tempo até a meta.

## Fontes
- https://dev.to/aguier/i-built-7-idle-games-in-30-days-what-i-learned-about-incremental-design-5d3f — automação como transição de fase; offline a 50%
- https://gridinc.co.za/blog/idle-games-best-practices — presença > ausência; não automatizar cedo
- https://blog.clickerheroes.com/?p=1902 — ativo × idle, progressão offline pelo DPS idle
- https://steamcommunity.com/app/363970/discussions/0/617335934130334590 — builds idle/ativos/híbridos
- https://en.wikipedia.org/wiki/AdVenture_Capitalist — gerentes automatizam negócios
