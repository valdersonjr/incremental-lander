"""v12: missoes abstratas com estrelas (substitui contracts.cargo). Compara com a v11 (cargas misturadas desde o
inicio). Rodar: python3 balance/sims/2026-10-06-v12-missions.py [horas] [--apply]"""
import sys, json, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E = load("data/economy.json")
MISSIONS = json.load(open("balance/sims/v12_missions.json"))


def v12(E, missions=MISSIONS):
    M = copy.deepcopy(E)
    M["contracts"].pop("cargo", None)
    M["contracts"]["missions"] = copy.deepcopy(missions)
    M["meta"]["version"] = 12
    return M


def show(tag, E, hours):
    out = screen(E, hours=hours, show=False)
    for prof, (r, rep) in out.items():
        ms = [(e["id"], round(e["t"] / 60)) for e in r.events if e["type"] == "mission"]
        lv = r.final["levels"]
        fl = next((round(e["t"] / 3600, 2) for e in r.events if e["type"] == "upgrade" and e["id"] == "fleet"), None)
        first = ", ".join(f"{i}@{m}m" for i, m in ms[:4])
        last = ms[-1] if ms else None
        print(f"{tag} {prof:8s} runs {r.final['runs']:3d} | $ {fmt(r.final['lifetime']['credits'])} | motor {lv['thrust']} rep {lv['contracts']}"
              f" | 1o drone {fl}h | paredes {len(rep['walls'])} pior {max([w['gap_min'] for w in rep['walls']] or [0])}m"
              f" | nos {len(ms)}/16 ({first} ... ult {last})")
    return out


if __name__ == "__main__":
    h = float(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else 6
    show("v11", E, h)
    M = v12(E)
    show("v12", M, h)
    if "--apply" in sys.argv:
        M["meta"]["notes"] += " v12: missoes abstratas com estrelas (contracts.missions substitui contracts.cargo)."
        save(M, "data/economy.json")
        print("aplicado")
