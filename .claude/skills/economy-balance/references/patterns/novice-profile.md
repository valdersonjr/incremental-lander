# Perfil novato e regra do aprendiz (primeiros minutos)

Data: 2026-10-08 · Mecânica: perfil de simulação + regra de jogo (não mexe em preço)

## Problema
Os perfis casual/engaged/expert batem ~2% dos saltos; a telemetria humana com a nave inicial bateu 23/35. A meta
`first_purchase_max_s` passava no modelo sem dizer nada do jogador novo de verdade.

## Padrão
- Curva de aprendizado: chance extra de batida `crash_extra · exp(−tentativas / learn_hops)` (prática, Bandura 1977:
  sucesso cedo cria confiança).
- Falhar barato no começo (Celeste, Super Meat Boy, Super Guide): enquanto `delivered < apprentice`, bater repete o
  salto com o gás dele (custa `retry_s`), sem acabar o run.

## Números e efeito medido (1 h, seeds 1–5)
crash_extra .6, learn_hops 25, retry_s 8, apprentice 5 (world.json). 1ª compra do novato: 129–354 s (mediana ~5 min);
sem o aprendiz 122–580 s. Casual/engaged idênticos ao modelo anterior.

## Decisão / pendência
O usuário mandou aplicar a auditoria. O novato ainda passa de 4 min em 3/5 seeds porque a 1ª compra só vem no fim
do 1º run. Medir com `session.csv` antes de baixar preço ou encurtar o 1º run.
