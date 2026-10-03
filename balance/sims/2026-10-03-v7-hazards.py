"""v7 + perigos por mundo (Fase 11.5): vento (Silvânia), gêiseres de calda (Docelândia), ventilador + brinquedos (Quarto).

Hipótese: planet.hazard = {dv, crash}; dv extra = hazard.dv x (1 - skill) x 2 (expert quase não sente);
crash soma ao crash_base. Silvânia dv .08, Docelândia dv .10, Quarto dv 0 (ventilador ajuda = compensa) + crash .02.
Previsto: casual ~5-8% mais lento, expert ~1-2%; ordem e término mantidos; batida no Quarto sobe pouco.
Rodar da raiz: python3 balance/sims/2026-10-03-v7-hazards.py
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E0 = load("data/economy.json")
HAZ = {"ares": {"dv": 0.08, "crash": 0.0}, "kronos": {"dv": 0.10, "crash": 0.0}, "titan": {"dv": 0.0, "crash": 0.02}}


def with_hazards(E0: dict) -> dict:
    E = copy.deepcopy(E0)
    for p in E["planets"]:
        if p["id"] in HAZ:
            p["hazard"] = dict(HAZ[p["id"]])
    return E


if __name__ == "__main__":
    for name, E in (("v7", E0), ("v7+perigos", with_hazards(E0))):
        s = summarize_mc(E, monte_carlo(E, seeds=3))
        print(name, {p: (v["finished"], v["finish_h_median"], v["planet_unlock_h_median"]) for p, v in s.items()})
