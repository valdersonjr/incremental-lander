"""Validacao final v6: frota + marcos + Expedicao (200B x1.7) + Ares 300K; metas de horario afrouxadas
(duracao total nao importa ao usuario; importa nao ter esperas)."""
import sys, json, copy, importlib.util; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
sp = importlib.util.spec_from_file_location("v6", "balance/sims/2026-09-29-expedition-v6.py"); v6 = importlib.util.module_from_spec(sp); sp.loader.exec_module(v6)
E = v6.build_v6(load("data/economy.json"), 2e11, 1.7)
set_path(E, "planets.ares.unlock.credits", 300000.0)
E["targets"].update({"finish_h": [3, 30], "first_prestige_h": [0.5, 6],
                     "planet_unlock_h": {"ares": [0.4, 2.5], "kronos": [1.5, 10], "titan": [3, 25]},
                     "max_gap_min": [{"until_h": 1, "minutes": 5}, {"until_h": 5, "minutes": 30},
                                     {"until_h": 15, "minutes": 45}, {"until_h": 40, "minutes": 60}]})
save(E, "balance/sims/economy-v6-candidate.json")
mc = monte_carlo(E, seeds=5, hours=40)
print(json.dumps(summarize_mc(E, mc), ensure_ascii=False))
for p, rs in mc.items():
    reps = [pacing_report(E, r) for r in rs]
    worst = max(max((w["gap_min"] for w in rp["walls"]), default=0) for rp in reps)
    print(f"{p:8s} fim {[rp['finished_at_h'] for rp in reps]} | prest {[len(rp['prestiges']) for rp in reps]} | "
          f"idle fim {[rp.get('idle_share_final_pct') for rp in reps]} | pior espera {worst} min | avisos {sorted({w for rp in reps for w in rp['warnings']})[:4]}")
E2 = copy.deepcopy(E); E2.pop("prestige")
E2["upgrades"] = [u for u in E2["upgrades"] if not u.get("requires_shop") and not u.get("requires_upgrade")]
t = next(p for p in E2["planets"] if p["id"] == "titan"); t.pop("requires_upgrade", None)
print("sem prestigio (sem loja/frota/expedicao) engaged fim:", simulate(E2, "engaged", 40, seed=0).finished_at_h)
print(write_report(E, [mc["engaged"][0], mc["casual"][0], mc["expert"][0]], "balance/reports/2026-09-29-v6-expedition",
                   title="v6 - frota + marcos + Expedicao a Titan"))
