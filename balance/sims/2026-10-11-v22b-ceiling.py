"""v22b — teto de voo (track.ceiling_m). Jogo real (2026-10-11): o usuario arremessou 2,9 km com 51 de gas e fez
~8 mil no 1o voo; o modelo so olhava 1 plataforma a frente e nao via o arremesso. Agora o piloto do modelo pode
mirar ate 6 plataformas a frente e o teto torna o custo ~linear acima de 4 x teto.
Hipotese: sem teto o piloto do modelo arremessa longe e o 1o voo rende ~10x a v22; com teto 140 m volta a ~600-900 m
e o ritmo da v22.
Rodar da raiz: python3 balance/sims/2026-10-11-v22b-ceiling.py [teto_m] [rough_scale]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v22b(ceil: float, rough: float | None = None) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"]["ceiling_m"] = ceil
    if rough:
        E["contracts"]["track"]["rough_scale"] = rough
    return E


def first_runs(E):
    econ._FEEL = E
    out = []
    for prof in ("casual", "engaged", "expert"):
        lg = []
        r = do_run(E, E["planets"][0], ship_stats(E, {}), profile_from(E, prof), None, expected=True, log=lg)
        out.append(f"{prof}: {len(lg)} pousos ate {r.max_distance:.0f} m, {r.rewards['credits']:.0f} moedas "
                   f"(maior salto {max((e[0] for e in lg), default=0):.0f} m)")
    return out


if __name__ == "__main__":
    ceil = float(sys.argv[1]) if len(sys.argv) > 1 else 140.0
    rough = float(sys.argv[2]) if len(sys.argv) > 2 else None
    for label, E in (("sem teto", v22b(0.0, rough)), (f"teto {ceil:.0f} m", v22b(ceil, rough))):
        print("==", label)
        for l in first_runs(E):
            print("  ", l)
        for prof, (res, rep) in screen(E, hours=6, show=False).items():
            print("  ", prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "run_s_median",
                                                        "deliveries_median", "planet_unlock_h")})
