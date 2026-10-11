"""v29 — pedido do usuario: placas a cada 1 km (antes 250 m) e "o pagamento nao pode aumentar por causa do degrau das
pecas da nave" (saem os marcos x1,25 de pagamento por degrau de Motor/Gasolina/Eficiencia).
Hipotese: sem os marcos a renda do fim cai ~x14 (1,25^12 no nivel 40) -> as compras do meio/fim espacam muito; o
crescimento do custo (growth 1,16-1,20) precisa cair para compensar.
Rodar da raiz: python3 balance/sims/2026-10-11-v29-no-milestone.py [fator_growth]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy

E0 = load("data/economy.json")


def v29(gk: float = 1.0) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"]["marker_every"] = 1000
    for u in E["upgrades"]:
        if u["id"] in ("thrust", "tank", "efficiency"):
            u.pop("milestones", None)
            c = u["cost"]["credits"]
            c["growth"] = round(1 + (c["growth"] - 1) * gk, 4)
    return E


if __name__ == "__main__":
    for label, E in (("atual (v28)", copy.deepcopy(E0)), ("sem marcos", v29(1.0)), ("sem marcos, custo x0,7", v29(0.7)),
                     ("sem marcos, custo x0,5", v29(0.5))):
        print("==", label)
        for prof, (res, rep) in screen(E, hours=10, show=False).items():
            print("  ", prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90",
                                                        "run_s_median", "planet_unlock_h")})
