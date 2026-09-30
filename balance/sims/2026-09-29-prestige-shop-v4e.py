"""v4e: min_gain 20 (1o prestigio mais tarde) + Kronos e Titan re-resolvidos + validacao MC + relatorio."""
import sys, time, json, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("balance/sims/economy-v4d-candidate.json"); T = time.time()
set_path(E, "prestige.min_gain", 20)
for pid, target, lo, hi in [("kronos", 6.0, 1e7, 1e10), ("titan", 15.0, 1e11, 1e14)]:
    v = solve(E, f"planets.{pid}.unlock.credits", lambda e: planet_unlock_hour(e, pid, hours=40), target, lo, hi, iters=10)
    set_path(E, f"planets.{pid}.unlock.credits", float(f"{v:.2g}"))
    print(pid, "->", fmt(v), f"({round(time.time()-T)}s)", flush=True)
E["meta"]["notes"] = ("v4: prestigio no padrao do genero - nivel passivo (+1%/ponto) + loja da Poeira Estelar (capital, ficha de "
                      "piloto, cartas de navegacao=manter planetas, motor de dobra=acesso a Titan, contratos premium); formula "
                      "pow 0.25; max 6 entregas/run. Unidades: m, m/s, m/s2, gas.")
save(E, "balance/sims/economy-v4e-candidate.json")
mc = monte_carlo(E, seeds=3, hours=40)
print(json.dumps(summarize_mc(E, mc), ensure_ascii=False), flush=True)
for p, rs in mc.items():
    for r in rs:
        rep = pacing_report(E, r)
        print(p, r.seed, "fim", rep["finished_at_h"], "| prestigios", len(rep["prestiges"]), "1o", rep["prestiges"][0]["at_h"] if rep["prestiges"] else None,
              "| run", rep.get("run_s_median"), "| paredes", len(rep["walls"]), "pior", max((w["gap_min"] for w in rep["walls"]), default=0), "min", flush=True)
        for w in rep["warnings"]: print("     AVISO:", w, flush=True)
print(write_report(E, [mc["engaged"][0], mc["casual"][0], mc["expert"][0]], "balance/reports/2026-09-29-v4-prestige-shop",
                   title="v4 - loja de prestigio"), flush=True)
