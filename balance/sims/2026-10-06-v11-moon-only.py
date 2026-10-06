"""v11: só a Lua. Sai prestígio, Silvânia/Docelândia/Quarto, Expedição e minério.
Frota/Piloto automático liberados por créditos (requires_upgrade em vez da loja)."""
import sys, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E = load("data/economy.json")


def moon_only(E, fleet_base=None, autopilot_base=None):
    E = copy.deepcopy(E)
    E.pop("prestige", None)
    E["planets"] = [p for p in E["planets"] if p["id"] == "luna"]
    E["upgrades"] = [u for u in E["upgrades"] if not u["id"].startswith("exp")]
    E["resources"] = [r for r in E["resources"] if r["id"] == "credits"]
    E["resource_value"] = {"credits": 1}
    for u in E["upgrades"]:
        u.pop("requires_shop", None)
        if u.get("persistent") and not u.get("assist"):
            u.pop("persistent", None)
    t = E["targets"]
    for k in ("goal", "planet_unlock_h", "first_prestige_h", "prestige_count", "finish_h"):
        t.pop(k, None)
    E["profiles_override"] = {}
    fl = next(u for u in E["upgrades"] if u["id"] == "fleet")
    ap = next(u for u in E["upgrades"] if u["id"] == "autopilot")
    if fleet_base: fl["cost"]["credits"]["base"] = fleet_base
    if autopilot_base: ap["cost"]["credits"]["base"] = autopilot_base
    ap["requires_upgrade"] = {"fleet": 1}
    E["meta"]["version"] = 11
    return E


if __name__ == "__main__":
    import sys as _s
    fb = float(_s.argv[1]) if len(_s.argv) > 1 and _s.argv[1] else None
    ab = float(_s.argv[2]) if len(_s.argv) > 2 and _s.argv[2] else None
    hours = float(_s.argv[3]) if len(_s.argv) > 3 else 4
    M = moon_only(E, fb, ab)
    for prof, (r, rep) in screen(M, hours=hours, show=False).items():
        fl = [round(e["t"] / 3600, 2) for e in r.events if e["type"] == "upgrade" and e["id"] == "fleet"][:3]
        ap = [round(e["t"] / 3600, 2) for e in r.events if e["type"] == "upgrade" and e["id"] == "autopilot"][:2]
        lv = r.final["levels"]
        print(f"== {r.profile}: runs {r.final['runs']} | dinheiro {fmt(r.final['lifetime']['credits'])} | frota {fl} piloto {ap}"
              f" | niveis motor {lv['thrust']} tanque {lv['tank']} efic {lv['efficiency']} rep {lv['contracts']}"
              f" | paredes {len(rep['walls'])} pior {max([w['gap_min'] for w in rep['walls']] or [0])} min"
              f" | run {rep.get('run_s_median')}s | idle {rep.get('idle_share_final_pct')}")
        for w in rep["warnings"]:
            print("   AVISO:", w)
