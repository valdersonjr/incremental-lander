# Integração com o Godot 4

## Spec única
- `data/economy.json` fica **dentro** do projeto Godot (não ignorado) e é lido em runtime:
  `EconMath.load_spec()` (autoload ou no boot). JSON (e não `.tres`) porque é compartilhado com o
  Python; para edição no Inspector, gere Resources a partir dele se um dia precisar.
- `scripts/economy/econ_math.gd` (de `templates/econ_math.gd`): `cost_at`, `bulk_cost`,
  `max_affordable`, `effect_value`, `upgrade_cost`, `ship_stats`, `prestige_gain`, `contract_pay`,
  `estimated_hop_dv`, `fmt`. **Mesmas fórmulas do econ.py** — mudou lá, muda aqui.
- **Paridade verificada (2026-09-29)**: `python3 tests/test_econ_parity.py` roda o EconMath no Godot
  headless e compara 15 grupos de valores com o `econ.py` (custos, stats com marcos/loja/frota/etapas,
  pagamento, Δv, prestígio, disponibilidade, formatação). **Rode sempre** que mudar a spec, `econ.py` ou
  `econ_math.gd`; ao adicionar fórmula nova, adicione um caso ao teste.

## Números grandes
- Até ~1e300: `float` do Godot (64 bits) basta; formatação com `EconMath.fmt`.
- Se o relatório indicar `number_class = BigNumber`: usar **Idle Number Kit Lite** (GDScript, MIT,
  mantissa×10^expoente, formatador K/M/B/aa, serialização) ou **BigNumber** (GDExtension, mais rápido).
  Isso muda saves e UI — decidir cedo.

## Save
- Salvar: níveis de upgrades, recursos, planetas desbloqueados, pontos de prestígio, `meta.version` da
  spec. Ao carregar save de versão antiga: migrar (ex.: reembolsar upgrades removidos).

## Telemetria para calibração
Registrar cada entrega em CSV (`user://telemetry.csv`, copiar para `balance/telemetry/`):
```
planet,distance,thrust,efficiency,tank,gas_used,hop_time_s,quality,crashed
luna,1830.5,4.6,3.21,112,41.7,58.2,0.81,0
```
E por run: `run_id,planet,duration_s,deliveries,earned,crashed,gas_left_pct` (para comparar com
`do_run`). `econ.calibrate()` usa o CSV de entregas.
Métricas de funil úteis depois: tempo até cada planeta, abandono por fase (onde jogadores param).

## UI de economia (sugestões ligadas ao modelo)
- Mostrar **alcance estimado** com o gás atual (`estimated_hop_dv` inverso) → o jogador entende o
  valor de tanque/eficiência.
- Mostrar custo do próximo nível e "comprar máx." (`max_affordable`).
- Mostrar progresso para o próximo planeta (barra) — meta de médio prazo sempre visível.
