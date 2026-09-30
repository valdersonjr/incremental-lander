"""Validacao do candidato v3: Monte Carlo 3 perfis x 3 seeds + relatorio + comparacao sem prestigio."""
import sys, json, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("balance/sims/economy-v3-candidate.json")
mc = monte_carlo(E, seeds=3, hours=40)
print(json.dumps(summarize_mc(E, mc), ensure_ascii=False), flush=True)
for p, rs in mc.items():
    for r in rs:
        rep = pacing_report(E, r)
        print(p, r.seed, "fim", rep["finished_at_h"], "1o prest", rep["prestiges"][0] if rep["prestiges"] else None,
              "run_s", rep.get("run_s_median"), "paredes", len(rep["walls"]), "avisos", len(rep["warnings"]), flush=True)
E2 = copy.deepcopy(E); E2.pop("prestige")
print("sem prestigio engaged:", simulate(E2, "engaged", 40, seed=1).finished_at_h, flush=True)
print(write_report(E, [mc["engaged"][0], mc["casual"][0], mc["expert"][0]], "balance/reports/2026-09-29-v3-skill-prestige",
                   title="v3 - habilidade x prestigio"))
