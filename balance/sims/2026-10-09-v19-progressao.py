"""v19 (proposta aprovada 2026-10-09, etapa 1): distância com taxa fixa + d^0,5, plataformas como prêmio de risco
menor, tanque/eficiência aditivos (gás volta a ser escasso), marcos x1,25 a cada 10 níveis (o degrau). Compara com
a v18: escolhas (paga por gás e por segundo), elasticidade por nível e triagem nos 3 perfis."""
import sys, json
sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

def v19(E):
    E = json.loads(json.dumps(E))
    set_path(E, "contracts.distance_exp", float(sys.argv[3]) if len(sys.argv) > 3 else 0.7)
    E["contracts"]["pay_fixed"] = float(sys.argv[2]) if len(sys.argv) > 2 else 0.3
    set_path(E, "contracts.pay_base", float(sys.argv[1]) if len(sys.argv) > 1 else 68.0)
    for t in E["contracts"]["pad_tiers"]:
        t["mult"] = {"normal": 1.0, "narrow": 1.25, "tight": 1.5}[t["id"]]
    for u in E["upgrades"]:
        if u["id"] == "tank":
            u["effect"] = {"stat": "tank", "op": "add", "value": 8.0}
        if u["id"] == "efficiency":
            u["effect"] = {"stat": "efficiency", "op": "add", "value": 0.15}
        for m in u.get("milestones", []):
            m["every"], m["mult"] = 10, 1.25
        # (testado 2026-10-09: preços crescendo mais devagar NAO encurtaram as esperas — mediana 6,0 -> 6,55 min;
        # a espera vem da renda/min, nao do preço. Mantidos os crescimentos da v18.)
    return E

if __name__ == "__main__":
    E18 = load("data/economy.json"); E19 = v19(E18)
    luna = next(p for p in E19["planets"] if p["id"] == "luna"); prof = profile_from(E19, "engaged")
    lo, hi = luna["distance"]
    D = {"perto": lo * (hi / lo) ** (1 / 6), "medio": lo * (hi / lo) ** 0.5, "longe": lo * (hi / lo) ** (5 / 6)}
    for tag, E in (("v18", E18), ("v19", E19)):
        for label, lv in (("inicio", {}), ("meio", {"thrust": 10, "tank": 10, "efficiency": 10, "gear": 5}),
                          ("tarde", {"thrust": 40, "tank": 40, "efficiency": 40, "gear": 15})):
            st = ship_stats(E, lv)
            row = []
            for name, d in D.items():
                dv = hop_dv(luna, d, st, prof); g = gas_for(E, dv, st, st["tank"]); t = hop_time(luna, d, st, prof)
                for tier in ("normal", "tight"):
                    p = delivery_pay(E, luna, d, st, 0.7, tier)
                    row.append(f"{name[:2]}/{tier[:2]} {p/g:6.1f}g {p/t:6.1f}s")
            print(f"{tag} {label:6} tanque {st['tank']:7.0f} saltos-longos-por-tanque {st['tank']/max(g,1e-9):6.1f} | " + " | ".join(row))
    print("\nElasticidade v19 (renda/s, +1 nível):")
    for base_lv in (0, 9, 10, 30):
        base = {"thrust": base_lv, "tank": base_lv, "efficiency": base_lv, "gear": min(base_lv, 20)}
        i0 = expected_income(E19, luna, ship_stats(E19, base), prof)["credits"]
        out = []
        for uid in ("thrust", "tank", "efficiency"):
            lv = dict(base); lv[uid] += 1
            i1 = expected_income(E19, luna, ship_stats(E19, lv), prof)["credits"]
            out.append(f"{uid} {(i1/i0-1)*100:+6.1f}%")
        print(f"  nível {base_lv:2d} renda {i0:8.2f}/s  " + "  ".join(out))
    if "--screen" in sys.argv:
        for tag, E in (("v19", E19),):
            print(f"\n######## {tag}")
            screen(E)
