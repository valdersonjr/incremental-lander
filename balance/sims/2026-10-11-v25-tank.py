"""v25 — tanque menor no lugar do gasto que cresce com a distancia (usuario: "a gasolina hoje me permite ir uma
distancia; se fosse menor, eu ia menos longe"; nao quer gasto variando na pista). O jogo nao tem custo extra por
distancia (so o relevo) -> o modelo tira o rough_scale do gas e o tanque base cai.
Hipotese: sem o rough, a nave melhorada vai MUITO longe (delta-v cresce com tanque x eficiencia e a distancia de um
arremesso com o quadrado dele) -> runs longos no fim; o tanque menor so encurta o comeco. Medir runs e mundos.
Rodar da raiz: python3 balance/sims/2026-10-11-v25-tank.py
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v25(tank: float, rough: float = 1e12) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"]["rough_scale"] = rough
    E["contracts"]["track"].pop("ceiling_m", None)
    E["ship"]["base"]["tank"] = tank
    for p in E["planets"]:
        p.get("track", {}).pop("rough_scale", None)
    return E


if __name__ == "__main__":
    for tank in (100.0, 60.0, 45.0):
        E = v25(tank)
        econ._FEEL = E
        print(f"== tanque {tank:.0f}, sem gasto por distancia")
        for lv in (0, 20, 40):
            st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
            lg = []
            r = do_run(E, E["planets"][0], st, profile_from(E, "engaged"), None, expected=True, log=lg)
            print(f"   nave {lv}: {len(lg)} pousos ate {r.max_distance:.0f} m, {r.rewards['credits']:.0f} moedas, {r.time_s:.0f} s")
        for prof, (res, rep) in screen(E, hours=6, show=False).items():
            print("  ", prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "run_s_median",
                                                        "deliveries_median", "planet_unlock_h")})
