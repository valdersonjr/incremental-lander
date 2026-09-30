"""v4: prestigio no padrao do genero - nivel passivo (+1%/ponto, nunca diminui) + loja da Poeira Estelar
(capital inicial, ficha de piloto, cartas de navegacao = manter planetas, motor de dobra = portao de Titan,
contratos premium repetivel). Formula achatada (pow 0.2) para 4-6 prestigios."""
import sys, copy, json; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

def build_v4(E):
    E = copy.deepcopy(E)
    P = E["prestige"]
    P.update({"formula": "pow", "exponent": 0.2, "scale": 100, "min_gain": 8,
              "bonuses": [{"stat": "pay_mult", "per_point": 0.01}, {"stat": "thrust", "per_point": 0.001}]})
    P["shop"] = [
        {"id": "capital", "name": "Capital inicial", "priority": 1, "max_level": 5,
         "cost": {"type": "exp", "base": 3, "growth": 2.0},
         "effect": {"type": "start_resources", "amounts": {"credits": 20000}}},
        {"id": "pilot_file", "name": "Ficha de piloto", "priority": 2, "max_level": 5,
         "cost": {"type": "exp", "base": 5, "growth": 2.0},
         "effect": {"type": "start_levels", "levels": {"thrust": 3, "tank": 3, "efficiency": 2}}},
        {"id": "star_charts", "name": "Cartas de navegacao (manter planetas)", "priority": 3, "max_level": 1,
         "cost": {"type": "exp", "base": 25, "growth": 1.0}, "effect": {"type": "keep", "what": "planets"}},
        {"id": "warp_drive", "name": "Motor de dobra (acesso a Titan)", "priority": 4, "max_level": 1,
         "cost": {"type": "exp", "base": 150, "growth": 1.0}, "effect": {"type": "unlock"}},
        {"id": "premium", "name": "Contratos premium", "priority": 5, "max_level": 40,
         "cost": {"type": "exp", "base": 10, "growth": 1.6},
         "effect": {"type": "stat", "stat": "pay_mult", "op": "mult", "value": 1.25}},
    ]
    set_path(E, "planets.titan.requires_shop", "warp_drive")
    E["targets"]["prestige_count"] = [4, 6]
    E["meta"]["version"] = 4
    return E

if __name__ == "__main__":
    E = build_v4(load("data/economy.json"))
    save(E, "balance/sims/economy-v4-candidate.json")
    for p in ("engaged", "casual", "expert"):
        r = simulate(E, p, 40, seed=1); rep = pacing_report(E, r)
        pres = [(round(e["t"]/3600, 2), e["gain"]) for e in r.events if e["type"] == "prestige"]
        shop_ev = [(round(e["t"]/3600, 2), e["id"], e["level"]) for e in r.events if e["type"] == "shop"]
        print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | run {rep.get('run_s_median')}s")
        print("   prestigios (h, pontos):", pres)
        print("   loja:", shop_ev[:14], "..." if len(shop_ev) > 14 else "")
        for w in rep["warnings"]: print("   AVISO:", w)
