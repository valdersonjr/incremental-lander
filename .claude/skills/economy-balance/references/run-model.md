# Modelo do run (física → economia)

O run é o coração do jogo: **gás limitado → entregas → dinheiro**. O simulador precisa prever quanto um
run rende e quanto dura, dados os stats da nave, o planeta e o jogador.

## Salto (hop) de uma entrega
Entrega = salto balístico entre plataformas a distância `d`, gravidade `g`, aceleração do motor `a`.
- Velocidade de lançamento ótima (45°): `v0 = sqrt(g·d)`. Acelerar + frear: `2·v0`.
- Perda gravitacional nas queimas (motor fraco gasta mais): fator `1 + 0.707·g/a`.
- Arrasto/vento/atmosfera: `× (1 + drag)`. Piloto imperfeito: `× waste`.
- Pairar para pousar/decolar: `+ 2·g·hover_s`.
- **Δv = 2·sqrt(g·d)·(1 + 0.707·g/a)·(1 + drag)·waste + 2·g·hover_s**; impossível se `a ≤ 1.05·g`.
- Tempo: `sqrt(2)·v0/g` (voo) + `2·v0/a` (queimas) + `hop_overhead_s`.

Consequências de design (por que o modelo é bom para o jogo):
- Custo cresce com **sqrt(g·d)**, pagamento cresce com **d^distance_exp** (≈1.1) → ir mais longe é
  mais eficiente, mas exige gás num salto só → **tanque/eficiência viram "alcance"**.
- Gravidade forte (Ares g=5 vs Lua 1.62): ~1.8× gás por salto **e** exige motor mínimo (a > 1.05 g) →
  planeta novo é um portão natural de upgrade de motor ("velocidade").
- Motor fraco perto de g desperdiça muito (fator g/a) → upgrade de motor tem valor mesmo sem "velocidade".

## Gás
- `physics.mode = "arcade"` (padrão): massa constante, `gás = Δv / efficiency`.
- `physics.mode = "rocket"`: Tsiolkovsky, `Δv = ve·ln(m0/m1)`, `ve = efficiency`, massa do gás
  `gas_mass`/unidade; tanque maior pesa (retorno decrescente físico), carga pesada custa mais (use
  `contracts.cargo_mass`). Escolha o modo que **o jogo realmente implementa**.

## Pagamento
`pay = pay_base × (d/distance_unit)^distance_exp × planeta.pay_mult × stats.pay_mult × (1 + quality_bonus·q^quality_exp)`
- `q` = qualidade do pouso (0..1) do jogador (média `skill`, desvio `skill_sd`).
- `quality_exp` > 1 faz precisão alta valer desproporcionalmente mais (v3: bônus 1.5, expoente 2 →
  pouso q=0.9 paga ×2.2, q=0.55 paga ×1.45). Base + multiplicador de habilidade: casual ganha a maior
  parte, habilidade dá o extra (padrão `skill-stays-relevant`).
- Batida: probabilidade `crash_base × (1 − q) × 2 / gear` → perde a entrega e termina o run.
- Recompensas multi-recurso: `planeta.rewards = {"credits": 1, "ore": 0.02}` (fração do pagamento).

## Variedade das entregas (v7)
- `contracts.pad_tiers`: cada oferta sorteia um tipo de plataforma (peso `weight`) que multiplica o pagamento
  (`mult`). Plataforma estreita derruba a qualidade de quem pilota pior: `q − q_drop·(1 − skill)·2`, e a
  chance de batida × `crash_mult`. O piloto simulado escolhe pelo **valor esperado** por gás.
- `contracts.combo`: pousos bons seguidos no run (`q ≥ q_min`) dão `1 + step·min(streak, max_steps)`;
  pouso ruim zera. Runs "esperados" usam o streak médio: `E[s'] = P(bom)·(E[s] + 1)`.
- `contracts.pickups`: `per_hop` cristais no arco, cada um `value_frac` do pagamento-base; o modelo coleta a
  fração `skill` (o jogo coloca os cristais no caminho de um arco bom).
- Pagamento da entrega: `delivery_pay = contract_pay·(1 + quality_bonus·q^quality_exp)·tier.mult·combo_mult`
  (+ cristais). Espelho: `EconMath.delivery_pay / pickup_value / combo_mult / pad_tier`.

## Ofertas e escolha do piloto
- Cada run oferece `contracts_per_run` distâncias log-uniformes em `planeta.distance = [min, max]`.
- O piloto escolhe, entre as alcançáveis com o gás restante, a de **maior pagamento por gás**; repete
  até nada ser alcançável. (Se o jogo tiver rotas encadeadas/mapa, estenda `do_run`.)
- `contracts.regenerate = true`: cada entrega feita é substituída por uma oferta nova → o run só acaba
  quando o **gás** acaba (ou em `max_per_run` entregas). Sem isso, upgrades saturam o alcance (a nave faz
  todas as ofertas e sobra gás) e o desperdício do piloto para de custar — foi a causa da vantagem do
  expert cair de 2,9× para 1,3× no rascunho v2.
- `max_per_run` limita a duração do run (tanque grande não deve gerar runs de 15 min).

## Perfis de jogador (`PROFILES`)
| Perfil | skill | waste | hover_s | overhead por entrega | entre runs | prestígio quando ganho ≥ |
|---|---|---|---|---|---|---|
| casual | 0.55 | 1.6 | 2.5 s | 9 s | 35 s | 1.5 × pontos |
| engaged | 0.72 | 1.35 | 1.5 s | 6 s | 20 s | 1.0 × pontos |
| expert | 0.9 | 1.12 | 0.7 s | 4 s | 10 s | 0.7 × pontos (v3 da spec usa override 1.0: regra "dobrar") |
| novice | 0.45 | 1.8 | 3 s | 12 s | 40 s | — (fora do screen/mc; só para os primeiros minutos) |

**Novato** (2026-10-08, auditoria dos primeiros minutos): os perfis acima batem ~2% dos saltos, mas o humano com a
nave inicial bateu 23/35 (telemetria). O novato soma `crash_extra` 0,6 × exp(−tentativas / `learn_hops` 25) à
chance de batida (65% no 1º salto, metade em ~17 tentativas) e segue a regra do **aprendiz** do jogo
(`apprentice` = world.json `onboarding.apprentice_stars`): enquanto fez menos entregas que isso, bater custa `retry_s`
e o salto recomeça com o gás dele, sem acabar o run. Contadores (`attempts`, `delivered`) valem para o jogo todo
(`simulate` zera numa cópia do perfil). Recalibrar `crash_extra`/`learn_hops` com `session.csv` + deliveries.csv.
Estratégias de compra: `roi` (padrão, olha 1/2/4/8 níveis à frente e aceita algo acessível com ≥50%
do melhor ROI), `cheapest`, `random`. Planetas recebem bônus de prioridade (são o objetivo).
- Enquanto junta para a melhor opção (ex.: planeta), o jogador `roi` compra qualquer upgrade que **se
  paga antes** de conseguir juntar o valor da meta (payback < tempo para pagar). Sem isso, o simulado
  ficava horas só juntando (paredes falsas de 5–6 h antes de Titan na v4d).
- Prestígio: regra "dobrar" (`prestige_ratio`), **exceto** quando a meta final (`targets.goal.planet`)
  já está disponível e dá para pagá-la em menos de `targets.goal.hold_h` (padrão 2 h) — ninguém recomeça
  a 2 h do fim (sem isso, o expert fazia um reset tardio e terminava depois do engaged).
- Loja de prestígio: compra por `priority`; se o próximo item da fila não cabe, guarda poeira para ele
  (itens com `optional: true` são pulados em vez de bloquear a fila).

## Calibração (quando o jogo existir)
Os perfis são **chutes informados** até haver telemetria. O jogo deve registrar cada entrega
(`balance/telemetry/*.csv`, formato em godot-integration.md). `calibrate()` ajusta `waste`,
`hover_s`, `skill`, `hop_overhead_s` para o gás/tempo reais; grave em `E["profiles_override"]`.
Se o erro continuar alto (`fit_rmse_log > 0.3`), a física do jogo diverge do modelo: ajuste `hop_dv`
(e o espelho `estimated_hop_dv` no GDScript) para refletir a física real.

## Limites conhecidos do modelo
- Não modela terreno (obstáculos, altura das plataformas), vento variável, rotas encadeadas.
- Prestígio decidido por regra simples (ganho ≥ ratio × pontos atuais).
- Automação ainda não modelada (quando entrar: renda idle por segundo por lander automático).

## Campos da spec adicionados na v5/v6
| Campo | Onde | Efeito no simulador (e no espelho GDScript) |
|---|---|---|
| `milestones: [{every, stat, mult}]` | upgrade | a cada `every` níveis, `stat` × `mult` (marcos estilo AdCap) |
| `requires_upgrade: {id: nível}` | upgrade / planeta | só disponível com o upgrade no nível mínimo (etapas encadeadas) |
| `requires_shop: id` | upgrade / planeta | exige item da loja de prestígio |
| `progress: true` | upgrade | jogador virtual trata como meta (bônus de prioridade igual a planeta) |
| `persistent: true` | upgrade | não reseta no prestígio (`prestige_reset_state()["keep_upgrades"]` no GDScript) |
| `ship.base.drones` / `autopilot` | stats | renda da frota/s = drones × autopilot × renda média do jogador (`fleet_income_per_s`) |
| `targets.max_idle_share_pct` | metas | aviso se a frota passar dessa fatia da renda no fim |
