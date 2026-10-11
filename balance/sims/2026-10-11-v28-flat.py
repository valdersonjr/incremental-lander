"""v28 — ideia do usuario: "por distancia ganha um valor fixo nao tao alto, mas ganha um multiplicador por plataforma
pousada". Metro paga per_m fixo (sem crescer com a distancia); cada pouso soma combo.step no multiplicador da viagem
(o acumulado entra no banco x multiplicador x nota x plataforma); sem bonus fixo por pouso.
Hipotese: com step ~0,5 o estilo pousar-seguido vence o cruzeiro; per_m acerta o ritmo das compras.
Rodar da raiz: python3 balance/sims/2026-10-11-v28-flat.py
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v28(per_m: float, step: float, mx: float = 1e12) -> dict:
    E = copy.deepcopy(E0)
    T = E["contracts"]["track"]
    T["per_m"] = per_m
    T["land_bonus"] = 0.0
    T["combo"] = {"step": step} if mx >= 1e11 else {"step": step, "max": mx}
    return E


def styles(E):
    econ._FEEL = E
    out = []
    for lv in (0, 20, 40):
        st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
        P = profile_from(E, "engaged")
        rates = {}
        for k in TRACK_STYLES:
            r = econ._do_run_track_k(E, E["planets"][0], st, P, None, True, None, k)
            rates[k] = (r.rewards["credits"] / r.time_s * 60, r.deliveries, r.max_distance)
        kb = max(rates, key=lambda k: rates[k][0])
        out.append(f"nivel {lv}: melhor k={kb} ({rates[kb][1]} pousos, {rates[kb][2]/1000:.1f} km)")
    return " | ".join(out)


if __name__ == "__main__":
    for step in (0.25, 0.5, 1.0):
        E = v28(1.0, step)
        print(f"step {step}:", styles(E))
