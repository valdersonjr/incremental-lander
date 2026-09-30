---
name: economy-balance
description: OBRIGATÓRIA para criar, alterar ou avaliar QUALQUER número da economia/progressão do jogo — preços e curvas de custo de upgrades, efeitos de upgrades (motor, tanque, eficiência...), pagamento de entregas/contratos, planetas (gravidade, custo de desbloqueio, recompensa), recursos e conversões, prestígio/reset, ritmo (pacing), paredes de progressão, duração do jogo e formatação de números grandes. Modela o jogo (run com gás limitado → entregas → dinheiro → upgrades → planetas → prestígio) em Python, simula jogadores virtuais (casual/engajado/expert, Monte Carlo), mede ritmo contra metas, ajusta parâmetros automaticamente, pesquisa ANTES os padrões de jogos incrementais/roguelite e exporta a spec única (data/economy.json) + fórmulas GDScript para o Godot 4. Use sempre que o usuário falar de balanceamento, economia, progressão, preço, custo, recompensa, upgrade, prestígio, "está fácil/difícil/lento/rápido demais" — mesmo sem citar a skill.
---

# Economy Balance — Incremental Lander

A economia vive em **uma spec única**: `data/economy.json`. O jogo (Godot) lê esse arquivo e o
simulador (`scripts/econ.py`) também — nunca existem dois conjuntos de números.

Jogo: **incremental por runs, estilo Lunar Lander, visão lateral, Godot 4.** Cada run tem gás limitado;
o jogador faz entregas (pagamento cresce com a distância), compra upgrades (motor/velocidade, tanque,
eficiência, ...) para ir cada vez mais longe, desbloqueia planetas com física mais dura (ex.: gravidade
forte gasta mais gás), tem múltiplos recursos e prestígio; automação vem mais tarde. Meta: 10–30 h.

## Regras invioláveis

1. **Todo número de economia passa por esta skill** e mora em `data/economy.json`. Nada de constante
   de preço/efeito escondida no código do jogo.
2. **Pesquisar antes de mudar.** Nenhuma mecânica nova é modelada antes da Etapa 2 (padrões de jogos reais).
3. **Simular antes de afirmar.** Nunca dizer "está balanceado" sem rodar simulação (3 perfis, ≥ 3 seeds)
   e ler o relatório + gráficos.
4. **Previsão antes do teste.** Escreva o efeito esperado de cada mudança antes de simular; compare depois
   (é assim que o modelo mental melhora).
5. **Python e GDScript espelhados.** Mudou fórmula em `econ.py` → mude em `scripts/economy/econ_math.gd`
   (modelo em `templates/econ_math.gd`) na mesma tarefa.
6. **Decisões de design são do usuário.** A skill mostra números, trade-offs e recomendações; o usuário aprova.
7. **A biblioteca cresce.** Todo trabalho termina atualizando `references/patterns/` e `balance/CHANGELOG.md`.

## Pastas do projeto

```
data/economy.json            # SPEC ÚNICA (o Godot lê; NÃO ignorar no Godot)
scripts/economy/econ_math.gd # espelho das fórmulas (copiado de templates/econ_math.gd)
balance/                     # tem .gdignore
  sims/<nome>.py             # scripts de experimento/ajuste (reprodutíveis, com seed)
  reports/<data>-<nome>/     # report.md + money.png, income.png, gaps.png, stats.png
  telemetry/*.csv            # dados reais exportados pelo jogo (calibração)
  CHANGELOG.md               # versão da spec -> o que mudou, por quê, efeito medido
```
Se `data/economy.json` não existir: copie `templates/economy.template.json` (rascunho já ajustado por
simulação para ~15 h) e confirme com o usuário os nomes/planetas/upgrades.
Cabeçalho de todo script em `balance/sims/`:
```python
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")
```

## Fluxo obrigatório

### Etapa 0 — Contexto
Leia `references/style-guide.md` (metas de ritmo e decisões), `data/economy.json`, o último relatório em
`balance/reports/` e o fim do `balance/CHANGELOG.md`. Rode a linha de base:
`python3 .claude/skills/economy-balance/scripts/econ.py sim data/economy.json engaged 40 1`.

### Etapa 1 — Briefing
Entenda o pedido e a **intenção de design** (confirme com AskUserQuestion só se houver dúvida real):
- É mecânica nova (upgrade, planeta, recurso, camada de prestígio, automação) ou ajuste de ritmo?
- Qual sensação se quer (ex.: "planeta 2 deve ser um choque, depois vira rotina")?
- Quais metas do style-guide são afetadas? Alguma meta nova?

### Etapa 2 — Aprender o padrão (OBRIGATÓRIA)
1. Leia **sempre** `references/fundamentals.md`.
2. Leia o que for relevante: `references/run-model.md` (física do run, perfis, calibração),
   `references/prestige-resources.md` (prestígio, múltiplos recursos, conversões, automação),
   `references/godot-integration.md` (export, números grandes, telemetria).
3. Procure em `references/patterns/INDEX.md` a mecânica (ou parente).
4. **Se não existir padrão, for raso, ou a mecânica for nova → pesquise:**
   - `WebSearch` ≥3 consultas em inglês, ex.: `"<mecânica> incremental game design balance"`,
     `"<jogo de referência> <mecânica> formula"`, `"idle game <mecânica> math"`,
     `"roguelite meta progression <mecânica>"`. Referências fortes: Kongregate "Math of Idle Games"
     (gamedeveloper.com), Eric Guan (idle design), GMTK (roguelites), wikis de AdCap, Cookie Clicker,
     Antimatter Dimensions, Realm Grinder, Egg Inc, Idle Planet Miner, Learn to Fly, Frontier Lander.
   - `WebFetch` em 1–3 fontes, extraindo **fórmulas, números e armadilhas** (não só descrições).
   - Rodada rasa? `mode: "extended"`.
5. Registre em `references/patterns/<slug>.md` (modelo `_TEMPLATE.md`) com fontes; atualize o INDEX.
6. Resuma ao usuário em 3–6 bullets o que aprendeu e como aplica aqui.

### Etapa 3 — Hipótese e plano
Escreva (curto): parâmetros que vão mudar, **efeito previsto** em cada métrica (ex.: "tank growth
1.16→1.20 deve atrasar Ares ~20 min e reduzir tank no share de níveis"), e o que seria sucesso.

### Etapa 4 — Modelar
Crie `balance/sims/<data>-<nome>.py` que carrega a spec, aplica as mudanças (`set_path`), simula e salva.
Mecânica que o modelo ainda não cobre → estenda `econ.py` (mantendo a API) **e** o espelho GDScript.
Suba `meta.version` e registre no `balance/CHANGELOG.md`.

### Etapa 5 — Simular
- Triagem: `screen(E)` (3 perfis em paralelo) na linha de base e em cada proposta → diferença limpa.
- `monte_carlo(E, seeds=5)` + `summarize_mc` → dispersão entre casual/engaged/expert.
- Para acertar uma meta, use `solve(E, "planets.ares.unlock.credits", metric, alvo, lo, hi)` em vez de
  chutar (resolva em ordem: o que vem antes no jogo primeiro). Só re-resolva quando a meta sair da faixa.
- `write_report(E, [resultados], "balance/reports/<data>-<nome>")`.

### Etapa 6 — Analisar (loop até passar)
Abra `report.md` e os PNGs com Read. **Checklist**:
- [ ] Sem avisos, ou cada aviso restante tem justificativa de design escrita?
- [ ] Primeira compra logo após o primeiro run; compras frequentes no início (intervalo mediano baixo)?
- [ ] Paredes (gaps.png) só onde são intencionais (antes de planeta/prestígio) e dentro dos limites da fase?
- [ ] Planetas e objetivo final dentro das janelas-alvo nos 3 perfis?
- [ ] Nenhum upgrade dominante (> limite de share de níveis) nem inútil (nunca comprado)?
- [ ] Habilidade importa, mas não é obrigatória: expert mais rápido que casual, casual ainda termina?
      (se casual termina antes do expert → prestígio/estratégia pesa mais que pilotar: rever)
- [ ] Prestígio: primeiro dentro da janela; ganho cresce; não vira "resetar a cada 5 min"?
- [ ] Renda/min (income.png) cresce em degraus perceptíveis (planeta, marco), sem platôs longos?
- [ ] Maior número dentro de float64 (senão BigNumber)?

### Etapa 7 — Apresentar e decidir
Mostre ao usuário: tabela antes/depois das métricas-chave, 1–2 gráficos (caminhos), avisos restantes,
**decisões de design pendentes** com recomendação. Ajuste pelo feedback e volte à Etapa 5.

### Etapa 8 — Exportar
- `save(E, "data/economy.json")` (valida a spec).
- Primeira vez: copie `templates/econ_math.gd` → `scripts/economy/econ_math.gd`. Fórmula mudou → atualize.
- CHANGELOG: versão, mudanças, métricas medidas (antes → depois).

### Etapa 9 — Alimentar a biblioteca
Atualize `references/patterns/<slug>.md` (o que funcionou, números finais, efeito medido, decisão do
usuário) e `style-guide.md` se surgiu decisão global (meta nova, filosofia de prestígio...).

### Etapa 10 — Calibrar com o jogo real (quando houver build jogável)
O jogo exporta telemetria de entregas (`balance/telemetry/*.csv`, formato em `godot-integration.md`).
`calibrate(E, csv, "engaged")` ajusta desperdício/pairar/overhead do perfil → grave em
`E["profiles_override"]` → re-simule. Diferença grande entre modelo e jogo = revisar `run-model.md`.

## API rápida (`scripts/econ.py`)

```python
E = load(path); save(E, path); get_path(E, "planets.ares.gravity"); set_path(E, "upgrades.tank.cost.credits.growth", 1.18)
cost_at(spec, lv); bulk_cost(spec, lv, n); max_affordable(spec, lv, dinheiro); effect_value(eff, lv); prestige_gain(P, ganho)
ship_stats(E, {"tank": 5}, prestige_points)            # stats finais
profile_from(E, "engaged")  # PROFILES: casual | engaged | expert (+ overrides calibrados)
hop_dv(planeta, d, stats, perfil); gas_for(E, dv, stats, gas); do_run(E, planeta, stats, perfil, rng)
expected_income(E, planeta, stats, perfil)             # renda/s esperada
r = simulate(E, "engaged", hours=40, seed=1)           # SimResult: events, samples, final
rep = pacing_report(E, r); print_summary(E, r)         # métricas + avisos contra E["targets"]
screen(E)                                              # triagem: 3 perfis em paralelo (~5 s)
simulate_many(E, [("engaged", 40, 1), ("expert", 40, 2)]); parallel_map(fn, itens)
mc = monte_carlo(E, seeds=5); summarize_mc(E, mc)      # paralelo nos nucleos
v = solve(E, path, lambda e: planet_unlock_hour(e, "ares"), 1.5, lo, hi)   # rodadas paralelas + interpolacao
write_report(E, [r1, r2], "balance/reports/x"); upgrade_table(E, "tank")
calibrate(E, "balance/telemetry/runs.csv", "engaged")
fmt(1.5e15) -> "1.50Qa"; fmt(x, "sci"); fmt_time(s)
```
CLI: `econ.py sim <spec> [perfil] [horas] [seed] | screen <spec> [horas] | mc <spec> [seeds] [horas] | report <spec> <dir> [horas] | table <spec> <upgrade> | fmt <n> [estilo]`.
Tempos (8 núcleos): 1 simulação de 40 h ~3–5 s; `screen` ~5 s; Monte Carlo 3×3 ~15 s; `solve` ~40 s.
Tudo determinístico por seed. **O usuário não gosta de esperar scripts**: sempre prefira `screen` para
descartar ideias, deixe Monte Carlo para a versão final e não re-resolva custos a cada iteração
(a duração total do jogo é só uma faixa larga — ver style-guide). Se algo passar de ~1 min, avise antes.
