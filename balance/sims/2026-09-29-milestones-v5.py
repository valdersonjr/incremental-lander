"""v5 + marcos (iteracao 2: a cada 25 niveis, x1.5; sem marco nos drones). Antes: a cada 10 niveis de motor/tanque/eficiencia/reputacao, pagamento x1.5 (renda continua
crescendo no fim do jogo); a cada 5 drones, autopilot x1.5. Testa Titan em 3 alvos (so triagem)."""
import sys, copy, importlib.util; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
sp = importlib.util.spec_from_file_location("v5", "balance/sims/2026-09-29-automation-v5.py"); v5 = importlib.util.module_from_spec(sp); sp.loader.exec_module(v5)

def build_v5m(E0, mult=1.5):
    E = v5.build_v5(E0)
    for u in E["upgrades"]:
        if u["id"] in ("thrust", "tank", "efficiency", "contracts"):
            u["milestones"] = [{"every": 25, "stat": "pay_mult", "mult": mult}]
    return E

if __name__ == "__main__":
    base = build_v5m(load("data/economy.json"))
    print("### sem re-ajustar Titan (custo atual)"); screen(base)
    for target in (10.0, 13.0):  # faixa larga de custo
        E = copy.deepcopy(base)
        v = solve(E, "planets.titan.unlock.credits", lambda e: planet_unlock_hour(e, "titan", hours=40), target, 1e10, 1e20)
        set_path(E, "planets.titan.unlock.credits", float(f"{v:.2g}"))
        print(f"\n### Titan engaged ~{target}h -> custo {fmt(v)}", flush=True)
        screen(E)
        save(E, f"balance/sims/economy-v5m-titan{int(target)}h.json")
