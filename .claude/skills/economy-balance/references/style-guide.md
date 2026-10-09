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

## Metas de ritmo (espelhadas em targets) — revistas em 2026-10-09 (v19)
| Meta | Valor |
|---|---|
| Primeira compra | logo após o 1º run (≤ 240 s) |
| Run típico | 45–240 s no modelo (o voo real leva ~1,8× o modelo: telemetria 30/09–03/10) |
| Intervalo entre compras | mediana ≤ 5–6 min na 1ª hora; nenhum degrau de peça "caindo do céu" |
| Escolha de distância | nenhuma combinação distância × plataforma > ~3× a renda por gás das outras |
| +1 nível de peça | ganho pequeno (≤ ~10%); o salto vem no **degrau** (10 níveis) e no mundo novo |
| Mundos (6, em sequência pela Estrada) | todos em 2–4 h hoje; etapa 2 da auditoria: mundos em escada + objetivos depois deles |
| Share máx. de níveis de um upgrade | 55% |

## Filosofia
- Pilotar bem **sempre** vale mais (menos gás gasto + bônus de qualidade); upgrades ampliam, não substituem.
- Planeta novo = choque de física + salto de pagamento (×10 ou mais) + recurso novo.
- Paredes só antes de planeta/prestígio, e mesmo essas dentro dos limites da fase.

## Estado da spec (v19, 2026-10-09)
- Jogo atual: 6 mundos paralelos liberados em sequência pela Estrada das Estrelas (1 estrela por entrega), minijogo por
  mundo, Reputação por ratinho, presentes, recordes; sem prestígio (saiu na v11); Frota/Piloto automático no fim.
- v19 (auditoria da progressão): pagamento = taxa fixa + d^0,7; plataformas ×1,25/×1,5; tanque/eficiência aditivos;
  marcos ×1,25 a cada degrau de 10; cansaço do run 2,0; Estrada pela necessidade. Medido (engaged, 6 h): run do
  modelo ~23 min → ~4–5 min; intervalo mediano entre compras 19,5 → 5,6 min; longe+apertada 17× → ~2,7× por gás.
- Pendências: depois dos 6 mundos (~3 h) só sobra a Frota (esperas de horas) → etapa 2 (mundos em escada, objetivos,
  desafios ativos); telemetria do jogo não grava desde 03/10 (o usuário joga na web) → calibrar de novo.

## Decisões registradas
<!-- data — decisão — motivo — versão da spec -->
- 2026-09-29 — pilotar bem deve render mais que o timing do prestígio: ofertas se renovam (gás é o limite) e bônus de precisão 1.5·q² — casual terminava junto com expert — v3
- 2026-09-29 — prestígio no padrão dos incrementais: nível passivo + loja da Poeira Estelar (capital, ficha, manter planetas, Motor de dobra como portão de Titan, premium); 4–6 prestígios até o fim — pedido do usuário; ciclos da v3 eram repetitivos — v4
- 2026-09-29 — o fim do jogo (após o Motor de dobra) será preenchido com **automação** (piloto automático/frota), não com grind nem planeta extra — decisão do usuário — próxima versão
- 2026-09-29 — fim do jogo = frota de drones + marcos (25 níveis ×1,5) + Expedição a Titan em 8 etapas; metas de horário afrouxadas (usuário: duração não importa) — platô de horas antes de Titan — v6
- 2026-10-09 — v19: escolha de distância equilibrada (taxa fixa + d^0,7: longe = dinheiro, perto = estrelas), peças com ganho pequeno por nível e salto no degrau, gás escasso de novo, Estrada pela necessidade — auditoria da progressão aprovada pelo usuário (pattern progression-audit) — v19
