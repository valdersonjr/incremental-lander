# Variedade na recompensa das entregas (além da distância)

- **Slug**: delivery-reward-variety
- **Onde na spec**: `contracts` (hoje: `pay_base × (d/unidade)^1.1 × (1 + 1.5·q²)`)
- **Intenção de design**: cada oferta ser uma escolha interessante (risco, tipo de pouso, carga), não só
  "qual é a mais longe que o gás alcança". Status: **aplicado na spec v7 (2026-10-03)**.

## Como jogos de referência fazem (pesquisa)
| Jogo | Fórmula / números | Observação |
|---|---|---|
| Lunar Lander (Atari, 1979) | pouso bom 50 pts, duro 15, batida 5; plataforma piscando ×2…×5, **maior quanto mais estreita** | a dificuldade do local é o multiplicador |
| Jupiter Lander | plataformas ×2, ×5, ×10 (as de ×10 são as mais difíceis) | mesmo padrão: alvo pequeno = mais pontos |
| Cargo, Please! | carga com tipo, fragilidade e janela de entrega; dirigir mal = multa/carga quebrada, devagar = perde a janela | cada entrega vira um julgamento risco × tempo |
| Space Station 14 (proposta de correio) | carga frágil quebra com impacto → desconto pequeno, **nunca prejuízo** | a penalidade não pode transformar a entrega em perda |
| Prosperous Universe (sugestão) | bônus opcional por entregar dentro de uma janela de tempo | prazo como extra, não como regra |
| Roguelites (bounties) | fase mais difícil → recompensa maior (×2, ×3); modificadores/mutators aleatórios por run | variedade vem de combinações, não de quantidade |

## Armadilhas conhecidas
- Modificador sempre melhor que os outros vira regra (dominância) → todos devem custar algo (gás, risco, precisão).
- Penalidade que zera ou dá prejuízo frustra o casual (o pilar "pilotar bem vale mais" é bônus, não punição).
- Mais variáveis na oferta = mais leitura na tela de escolha; mostrar o pagamento final, não a fórmula.
- Prazo em jogo de física pode virar pressa → mais batidas; o prazo precisa caber num voo "bom", não perfeito.

## Modelagem aqui
- Parâmetros finais (spec v7): tipos normal ×1 (.5) / estreita ×1,5 (.33, q_drop .06, batida ×1,3) / apertada ×2,2
  (.17, q_drop .12, batida ×1,7); combo +10% por pouso bom (q ≥ .55, até 5); cristais 3 × 5% do pagamento-base;
  pay_base 10 → 8,5 (compensa a renda extra para o casual manter o ritmo da v6).
- Extensões: `econ.py` (pad_tier, combo_mult, pickup_value, delivery_pay, _draw_tier, _q_on_tier, _p_good; do_run
  com tipos/combo/cristais e `log`) e `EconMath` (mesmas funções + draw_pad_tier, combo_counts). Paridade testada.

## Efeito medido (simulação, MC 3×4)
| Métrica | v6 | Previsto | v7 |
|---|---|---|---|
| Término casual / engaged / expert | 5,25 / 5,13 / 4,16 h | casual ≈ igual, expert mais rápido | 5,39 / 4,28 / 3,24 h |
| Razão casual/expert | 1,26 | 1,35–1,5 | 1,66 |
| Escolha de plataformas (Lua) | — | nenhuma domina | 31% / 38% / 30% |
Lições: multiplicador alto + combo forte (variante a: ×2,5, +15%) dispara o expert (razão 1,98); batida em
plataforma difícil gera variância de renda por run (paredes curtas de ~1 run).

## v8 (2026-10-05): cargas com regra própria (só Lua)
`contracts.cargo = {planets: ["luna"], kinds: [...]}`; cada carga: `mult` (cumpriu), `fail_mult` (falhou: paga
mult×fail_mult, **nunca acaba o run**), `fail_p` (chance de falhar = fail_p×(1−skill)×2, mesmo idioma do q_drop),
`dv_mult` (gás extra: queijão rebocado ×1,1). Modelo: média ponderada (`cargo_expect`) multiplica pagamento e Δv
(o piloto virtual não escolhe carga). Habilidades (`ability: true`, max_level 1): o modelo não vê efeito na renda;
compra quando `ability_value`×renda/custo vence os outros upgrades.
| Métrica (screen, 1 seed) | v7.1 | Previsto | v8 |
|---|---|---|---|
| Pagamento médio das cargas casual/engaged/expert | — | ~×1,15 | ×1,12 / ×1,17 / ×1,23 |
| Ares casual/engaged/expert | 0,81/0,69/0,54 h | 5–8% antes | 0,73/0,71/0,45 h |
| Pior parede casual na 1ª hora | 15,2 min | igual | 11,3 min |
Lição: bônus cheios (×1,5–1,7) + gás ×1,25 criaram parede de 21,7 min antes de Ares no casual (renda maior →
compra mais upgrades de alcance antes de juntar para o planeta); bônus ×0,7 e gás ×1,1 resolveram.

## Decisões do usuário
- 2026-10-03: gostou do multiplicador por plataforma; pediu "tudo que for sabido que deixa os gamers felizes".

## Fontes
- https://en.wikipedia.org/wiki/Lunar_Lander_(1979_video_game) — pontos por pouso e multiplicadores por plataforma estreita
- https://www.pixelatedarcade.com/games/jupiter-lander — plataformas ×2/×5/×10
- https://www.gamespress.com/Cargo-Please-Turns-Deliveries-Into-High-Speed-Cop-Dodging-Chaos-This-A — carga, fragilidade, janelas
- https://docs.spacestation14.com/en/space-station-14/departments/cargo/proposals/mail-delivery.html — frágil sem prejuízo
- https://com.prosperousuniverse.com/t/shipping-bonuses-for-lm-ads-optional/6049 — bônus por prazo opcional
- https://www.wayline.io/blog/blessing-roulette-boosts-roguelite-engagement — modificadores por run
- https://deathstrandingpc.505games.com/porters-advice-for-improving-your-delivery-score/ — carga danificada/prazo reduzem a nota da entrega
- https://www.c64-wiki.com/wiki/Space_Taxi — passageiro paga menos quanto mais demora; rotas para todos os lados
