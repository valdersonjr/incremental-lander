"""v27 — SEQUENCIA de pousos (track.combo): o n-esimo pouso seguido multiplica o banco por min(max, 1 + step n).
Motivo: com vmax (v26) voar reto segurando a altura custa g/v por metro, ~3,5x menos que pousar a cada 200 m -> o
cruzeiro de km dominava e as plataformas viravam detalhe. O modelo agora escolhe o ESTILO (mirar ate k plataformas a
frente) pelo que rende mais por minuto.
Hipotese: com step 0,2 / max 3 o melhor estilo vira k=1..3 (pousar seguido) para engajado/expert; renda sobe ~1,5-2x ->
pay_base pode cair; intervalo mediano volta a ~6-8 min (limitado pela duracao da viagem).
Rodar da raiz: python3 balance/sims/2026-10-11-v27-combo.py [step] [max] [pay_base]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v27(step: float = 0.2, mx: float = 3.0, pay_base: float | None = None) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"]["combo"] = {"step": step, "max": mx}
    if pay_base:
        E["contracts"]["pay_base"] = pay_base
    return E


def styles(E):
    econ._FEEL = E
    out = []
    for lv in (0, 20, 40):
        st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
        for prof in ("engaged", "expert"):
            P = profile_from(E, prof)
            rates = {}
            for k in TRACK_STYLES:
                r = econ._do_run_track_k(E, E["planets"][0], st, P, None, True, None, k)
                rates[k] = (r.rewards["credits"] / r.time_s * 60, r.deliveries, r.max_distance)
            kb = max(rates, key=lambda k: rates[k][0])
            out.append(f"nivel {lv} {prof}: melhor k={kb} ({rates[kb][1]} pousos, {rates[kb][2]/1000:.1f} km, "
                       f"{rates[kb][0]:.0f}/min) | k=40: {rates[TRACK_LOOKAHEAD][0]:.0f}/min")
    return out


if __name__ == "__main__":
    a = [float(x) for x in sys.argv[1:]] + [None] * 3
    step, mx, pb = (a[0] or 0.2), (a[1] or 3.0), a[2]
    for label, E in (("sem sequencia", v27(0.0, 1.0, pb)), (f"sequencia {step}/{mx}", v27(step, mx, pb))):
        print("==", label)
        for l in styles(E):
            print("  ", l)
        for prof, (res, rep) in screen(E, hours=10, show=False).items():
            print("  ", prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90",
                                                        "run_s_median", "planet_unlock_h")})
