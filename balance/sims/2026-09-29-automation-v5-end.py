"""v5 final: frota (iteracao 3) + Titan alcancavel logo apos a fase da frota (sem plato), ja que a
duracao total nao importa ao usuario. Mede paredes finais para 3 alvos de horario do Titan."""
import sys, copy, importlib.util; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
sp = importlib.util.spec_from_file_location("v5", "balance/sims/2026-09-29-automation-v5.py"); v5 = importlib.util.module_from_spec(sp); sp.loader.exec_module(v5)
base = v5.build_v5(load("data/economy.json"))
for target in (9.0, 10.0, 11.0):
    E = copy.deepcopy(base)
    v = solve(E, "planets.titan.unlock.credits", lambda e: planet_unlock_hour(e, "titan", hours=40), target, 1e10, 5e12)
    set_path(E, "planets.titan.unlock.credits", float(f"{v:.2g}"))
    print(f"\n### Titan engaged ~{target}h -> custo {fmt(v)}", flush=True)
    screen(E)
    save(E, f"balance/sims/economy-v5-titan{int(target)}h.json")
