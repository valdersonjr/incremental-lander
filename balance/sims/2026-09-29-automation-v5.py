"""v5 (iteracao 3: curva longa - 10 drones a 1.6x, drone 8% -> ~15% com autopilot; teto 1.5x): automacao no fim do jogo - Frota de drones que repete as rotas do jogador (renda = drones x autopilot x
renda do jogador), liberada pelo Motor de dobra. Preenche o plato final; Titan re-resolvido para engaged ~15h."""
import sys, time, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

def build_v5(E):
    E = copy.deepcopy(E)
    E["ship"]["base"].update({"drones": 0.0, "autopilot": 0.08})
    E["upgrades"] += [
        {"id": "fleet", "name": "Frota de drones", "requires_shop": "warp_drive",
         "effect": {"stat": "drones", "op": "add", "value": 1.0},
         "cost": {"credits": {"type": "exp", "base": 2e10, "growth": 1.6}}, "max_level": 10},
        {"id": "autopilot", "name": "Software de piloto automatico", "requires_shop": "warp_drive",
         "effect": {"stat": "autopilot", "op": "hyper", "max": 0.09, "k": 6},
         "cost": {"credits": {"type": "exp", "base": 4e10, "growth": 1.7}}, "max_level": 15},
    ]
    E["targets"]["max_idle_share_pct"] = 60
    E["meta"]["version"] = 5
    return E

def screen(E, profs=("engaged", "casual", "expert")):
    for p in profs:
        r = simulate(E, p, 40, seed=1); rep = pacing_report(E, r)
        fleet_ev = [(round(e["t"]/3600, 2), e["id"], e["level"]) for e in r.events if e["type"] == "upgrade" and e["id"] in ("fleet", "autopilot")]
        print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | prestigios {len(rep['prestiges'])} "
              f"| idle total/fim {rep.get('idle_share_pct')}/{rep.get('idle_share_final_pct')}% | paredes {len(rep['walls'])} "
              f"pior {max((w['gap_min'] for w in rep['walls']), default=0)} min", flush=True)
        print("   frota:", fleet_ev[:24], flush=True)
        for w in rep["warnings"]: print("   AVISO:", w, flush=True)

if __name__ == "__main__":
    import copy
    E = build_v5(load("data/economy.json"))
    print("--- triagem antes de re-resolver Titan (engaged)", flush=True)
    screen(E, ("engaged",))
    T = time.time()
    v = solve(E, "planets.titan.unlock.credits", lambda e: planet_unlock_hour(e, "titan", hours=40), 15.0, 5e11, 1e15, iters=10)
    set_path(E, "planets.titan.unlock.credits", float(f"{v:.2g}"))
    print("titan ->", fmt(v), f"({round(time.time()-T)}s)", flush=True)
    save(E, "balance/sims/economy-v5-candidate.json")
    print("--- triagem depois", flush=True)
    screen(E)
