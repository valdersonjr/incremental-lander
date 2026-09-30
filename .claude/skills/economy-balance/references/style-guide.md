# Style guide da economia (decisões globais)

> Fonte da verdade para metas e filosofia. Itens **(provisório)** precisam de confirmação do usuário.
> As metas numéricas também estão em `data/economy.json → targets` (o simulador as usa); mantenha os dois iguais.

## Conceito (do usuário)
- Cada run tem gás limitado para se movimentar; faz entregas para ganhar dinheiro e melhorar a nave
  (velocidade/motor, gás/tanque, eficiência), indo cada vez mais longe até liberar novos planetas com
  desafios maiores (ex.: planeta 2 com gravidade forte que gasta mais gás).
- Renda híbrida: começa ativa (pousos), automação entra **mais tarde**.
- Sistemas desde o início: **prestígio/reset** e **múltiplos recursos**. Offline: não (por ora).
- Duração-alvo: **10–30 h** até o objetivo final — faixa larga: o usuário disse que a duração total "não importa muito" (2026-09-29). Priorizar qualidade do ritmo (sem paredes/platôs), habilidade e prestígio; não re-ajustar custos só para cravar horas.
- Números: a skill decide → float64 enquanto o maior número < 1e300.

## Metas de ritmo (espelhadas em targets) **(provisório)**
| Meta | Valor |
|---|---|
| Primeira compra | logo após o 1º run (≤ 240 s) |
| Run típico | 45–240 s |
| Intervalo máx. entre compras | ≤ 5 min até 1 h; ≤ 30 min até 5 h; ≤ 45 min até 15 h; ≤ 60 min depois (v6) |
| Planeta 2 (Ares) | 0.4–2.5 h (v6, faixa larga) |
| Planeta 3 (Kronos) | 1.5–10 h |
| Planeta 4 (Titan, objetivo) | 3–25 h |
| Fim | 3–30 h (duração não importa; importa não ter esperas) |
| 1º prestígio | 0.5–6 h |
| Nº de prestígios até o fim | 4–6 |
| Share máx. de níveis de um upgrade | 55% |

## Filosofia
- Pilotar bem **sempre** vale mais (menos gás gasto + bônus de qualidade); upgrades ampliam, não substituem.
- Planeta novo = choque de física + salto de pagamento (×10 ou mais) + recurso novo.
- Paredes só antes de planeta/prestígio, e mesmo essas dentro dos limites da fase.

## Estado da spec (v6, MC 3×5)
- Término expert / engaged / casual: 4,3 / 4,9 / 5,6 h; Ares ~0,7 h; Kronos ~2,7 h; 4 prestígios (casual 3–4).
- Fases: pilotar (Lua → Ares → Kronos) → prestígios com loja → Motor de dobra → **frota de drones** (mudança
  de fase, 45–54% da renda no fim) + **Expedição a Titan** em 8 etapas → Titan.
- Pior espera entre compras: ≤ 30 min (antes: 474 min).
- Pendências conhecidas: ~20 min juntando para Ares por volta de 1 h (acima do limite de 5 min da 1ª hora);
  runs de 6–8 min no modelo (calibrar com o mapa real); jogo curto (~5 h) — alongar exige conteúdo novo
  (ex.: mais planetas), não custos maiores.

## Decisões registradas
<!-- data — decisão — motivo — versão da spec -->
- 2026-09-29 — pilotar bem deve render mais que o timing do prestígio: ofertas se renovam (gás é o limite) e bônus de precisão 1.5·q² — casual terminava junto com expert — v3
- 2026-09-29 — prestígio no padrão dos incrementais: nível passivo + loja da Poeira Estelar (capital, ficha, manter planetas, Motor de dobra como portão de Titan, premium); 4–6 prestígios até o fim — pedido do usuário; ciclos da v3 eram repetitivos — v4
- 2026-09-29 — o fim do jogo (após o Motor de dobra) será preenchido com **automação** (piloto automático/frota), não com grind nem planeta extra — decisão do usuário — próxima versão
- 2026-09-29 — fim do jogo = frota de drones + marcos (25 níveis ×1,5) + Expedição a Titan em 8 etapas; metas de horário afrouxadas (usuário: duração não importa) — platô de horas antes de Titan — v6
