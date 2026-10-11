"""v21b — ouro ACUMULADO por metro avancado, pago no pouso (pedido do usuario: "sempre mostrar o gold acumulado, o
quanto eu ja fiz ate agora, pra eu pousar na proxima").

Hipotese: hop de ~175 m paga ~o mesmo que na v21 (per_m_ref 175); pular uma plataforma paga ~2x os metros (sem
skip_bonus) por ~1,4x o gas (sqrt) -> o piloto do modelo pula mais (ok se nao for sempre: ~1/3 -> ~1/2); ritmo igual
(1a compra ~110 s, intervalo ~5 min, mundos 0,4-2,5 h engajado).
Rodar da raiz: python3 balance/sims/2026-10-11-v21b-accum.py [per_m_ref]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v21b(ref: float = 175.0) -> dict:
    E = copy.deepcopy(E0)
    T = E["contracts"]["track"]
    T.pop("skip_bonus", None)
    T["per_m_ref"] = ref
    return E


if __name__ == "__main__":
    E = v21b(float(sys.argv[1]) if len(sys.argv) > 1 else 175.0)
    econ._FEEL = E
    for lv in (0, 15, 35):
        st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
        lg = []
        r = do_run(E, E["planets"][0], st, profile_from(E, "engaged"), None, expected=True, log=lg)
        print(f"nave {lv}: {len(lg)} pousos ({sum(1 for e in lg if e[5])} pulando) ate {r.max_distance:.0f} m, "
              f"{r.rewards['credits']:.0f} moedas, {r.time_s:.0f} s")
    for prof, (res, rep) in screen(E, hours=6, show=False).items():
        print(prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90", "run_s_median",
                                              "deliveries_median", "crash_rate_pct", "planet_unlock_h")})
        for w in rep.get("warnings", []):
            if "nunca comprados" not in w:
                print("   AVISO:", w)
