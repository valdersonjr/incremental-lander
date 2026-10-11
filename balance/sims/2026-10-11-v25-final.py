"""v25 final — "dificulta o maximo que der sem deixar o jogo ruim; se o jogador usar o arremesso e habilidade dele".
Tanque base 45; Gasolina/Eficiencia com 30% da forca (+2,4 / +0,045 por nivel); galao fixo (can_gas); sem teto e sem
gasto por distancia (rough_scale sai do modelo; o relevo crescente do jogo vira hill_scale, so visual/pilotagem).
Hipotese: viagem ~1 -> ~5 km no jogo todo; intervalo entre compras sobe (~8-9 min) -> pay_base sobe ate voltar a
~5-6 min na 1a hora sem a 1a compra ficar instantanea.
Rodar da raiz: python3 balance/sims/2026-10-11-v25-final.py [pay_base] [can_gas]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy
import econ

E0 = load("data/economy.json")


def v25(pay_base: float = 43.0, can_gas: float = 12.0) -> dict:
    E = copy.deepcopy(E0)
    T = E["contracts"]["track"]
    T["hill_scale"] = T.pop("rough_scale", 450.0)
    T.pop("ceiling_m", None)
    T.pop("can_frac", None)
    T["can_gas"] = can_gas
    for p in E["planets"]:
        if "track" in p:
            p["track"].pop("rough_scale", None)
            if not p["track"]:
                p.pop("track")
    E["ship"]["base"]["tank"] = 45.0
    for u in E["upgrades"]:
        if u["id"] in ("tank", "efficiency"):
            u["effect"]["value"] = round(u["effect"]["value"] * 0.3, 4)
    E["contracts"]["pay_base"] = pay_base
    return E


if __name__ == "__main__":
    pb = float(sys.argv[1]) if len(sys.argv) > 1 else 43.0
    cg = float(sys.argv[2]) if len(sys.argv) > 2 else 12.0
    E = v25(pb, cg)
    econ._FEEL = E
    for lv in (0, 20, 40):
        st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
        r = do_run(E, E["planets"][0], st, profile_from(E, "engaged"), None, expected=True)
        print(f"nave {lv}: {r.deliveries} pousos ate {r.max_distance/1000:.1f} km, {r.time_s/60:.1f} min")
    for prof, (res, rep) in screen(E, hours=10, show=False).items():
        print(prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90", "run_s_median",
                                              "planet_unlock_h")})
        for w in rep["warnings"]:
            if "nunca" not in w:
                print("   AVISO:", w)
