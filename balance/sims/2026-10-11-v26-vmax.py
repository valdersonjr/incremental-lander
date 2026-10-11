"""v26 — velocidade maxima da nave (track.vmax). Jogo real (2026-10-11): o usuario arremessou 12,8 km em 3 pousos e
fez 370 mil na 9a viagem (~7,6 min de jogo): distancia ~ impulso^2 no arremesso e o ouro acumulado ~ distancia^1,7.
O piloto do modelo agora considera ate TRACK_LOOKAHEAD plataformas a frente (via o arremesso).
Hipotese: sem vmax o modelo tambem estoura (nivel 20 -> 10+ km por viagem); com vmax 45 o alcance de um salto fica
~1,2 km e a viagem volta a crescer ~linear com o impulso.
Rodar da raiz: python3 balance/sims/2026-10-11-v26-vmax.py [vmax]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v26(vmax: float) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"]["vmax"] = vmax
    return E


if __name__ == "__main__":
    vm = float(sys.argv[1]) if len(sys.argv) > 1 else 45.0
    for label, E in (("sem vmax", v26(0.0)), (f"vmax {vm:.0f}", v26(vm))):
        econ._FEEL = E
        print("==", label)
        for lv in (0, 10, 20, 30, 40):
            st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
            lg = []
            r = do_run(E, E["planets"][0], st, profile_from(E, "expert"), None, expected=True, log=lg)
            print(f"   expert nave {lv}: {r.deliveries} pousos ate {r.max_distance/1000:.1f} km (maior salto "
                  f"{max((e[0] for e in lg), default=0)/1000:.1f} km), {r.rewards['credits']:.0f} moedas, {r.time_s/60:.1f} min")
        for prof, (res, rep) in screen(E, hours=10, show=False).items():
            print("  ", prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90",
                                                        "run_s_median", "planet_unlock_h")})
