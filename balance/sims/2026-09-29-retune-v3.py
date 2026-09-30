"""Reajuste de duracao apos A+B2: resolve custos de desbloqueio na ordem do jogo."""
import sys, copy, json, time; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")
set_path(E, "prestige.scale", 1e5); set_path(E, "prestige.min_gain", 10)
E["prestige"]["bonuses"] = [{"stat": "pay_mult", "per_point": 0.02}, {"stat": "thrust", "per_point": 0.002}]
C = E["contracts"]; C["regenerate"] = True; C["max_per_run"] = 20; C["quality_bonus"] = 1.5; C["quality_exp"] = 2.0
E["profiles_override"] = {"expert": {"prestige_ratio": 1.0}}
T = time.time()
for pid, target, lo, hi in [("ares", 1.5, 3e4, 3e6), ("kronos", 6.0, 1e6, 1e11), ("titan", 15.0, 1e8, 1e15)]:
    v = solve(E, f"planets.{pid}.unlock.credits", lambda e: planet_unlock_hour(e, pid, hours=40), target, lo, hi, iters=12)
    set_path(E, f"planets.{pid}.unlock.credits", float(f"{v:.2g}"))
    print(pid, "->", fmt(v), f"({round(time.time()-T)}s)", flush=True)
E["meta"]["version"] = 3
E["meta"]["notes"] = ("v3: prestigio forte (scale 1e5, +2%/ponto), habilidade relevante (ofertas regeneram, max 20/run, "
                      "bonus de precisao 1.5*q^2), expert segue regra 'dobrar'; unlocks re-resolvidos. Unidades: m, m/s, m/s2, gas.")
save(E, "balance/sims/economy-v3-candidate.json")
print_summary(E, simulate(E, "engaged", 40, seed=1))
