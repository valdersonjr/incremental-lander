"""v16: 5 mundos paralelos (planets road-gated), paradas 'world' na Estrada, bonus de recorde por mundo.
pay_mult de cada mundo calibrado para renda ~TARGET x Lua com a nave tipica da hora em que o mundo abre."""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
import copy, statistics as st
from econ import *
E0 = load("data/economy.json")
TARGET = 1.15
LATE = {"thrust": 55, "tank": 40, "efficiency": 30}
WORLDS = [  # id, nome, gravidade, drag, hazard, estrelas da parada, nave tipica na abertura
    ("nuvens", "Reino das Nuvens", 1.15, 0.0, {"crash": 0.02}, 24, {"thrust": 15, "tank": 12, "efficiency": 8}),
    ("bolhas", "Mar das Bolhas", 2.4, 0.05, {"crash": 0.02}, 44, {"thrust": 25, "tank": 18, "efficiency": 12}),
    ("cogumelos", "Floresta dos Cogumelos", 3.2, 0.05, {"crash": 0.01}, 66, {"thrust": 35, "tank": 24, "efficiency": 16}),
    ("sorvete", "Planeta Sorvete", 4.0, 0.0, {"crash": 0.02}, 88, {"thrust": 45, "tank": 30, "efficiency": 20}),
    ("jardim", "Jardim Gigante", 4.9, 0.1, {"dv": 0.08}, 110, {"thrust": 55, "tank": 36, "efficiency": 24}),
]


def build(bonus=(0.25, 0.5), target=TARGET):
    E = copy.deepcopy(E0)
    luna = E["planets"][0]
    prof = profile_from(E, "engaged")
    E["contracts"]["missions"]["planets"] = ["luna"] + [w[0] for w in WORLDS]
    for wid, name, g, drag, hz, stars, lv in WORLDS:
        p = copy.deepcopy(luna)
        p.update({"id": wid, "name": name, "gravity": g, "drag": drag, "hazard": hz, "road": True, "pay_mult": 1.0})
        stt = ship_stats(E, LATE)                              # nave do fim do jogo (gravidade pesa menos com motor forte)
        base = sum(expected_income(E, luna, stt, prof).values())
        raw = sum(expected_income(E, p, stt, prof).values())
        p["pay_mult"] = round(target * base / raw, 3) if raw > 0 else 1.0
        E["planets"].append(p)
        E["progression"]["road"].append({"id": "world_" + wid, "type": "world", "stars": stars})
    E["progression"]["road"].sort(key=lambda s: (s["stars"], s["type"] != "start"))
    if bonus:
        E["contracts"]["record_bonus"] = {"frac": bonus[0], "first_frac": bonus[1]}
    return E


def report(E, label, hours=6, seeds=(1, 2)):
    jobs = [(p, s) for p in ("casual", "engaged", "expert") for s in seeds]
    rs = parallel_map(lambda a: simulate(E, a[0], hours, a[1]), jobs)
    print("==", label, {p["id"]: p["pay_mult"] for p in E["planets"]})
    for prof in ("casual", "engaged", "expert"):
        R = [r for (pp, _), r in zip(jobs, rs) if pp == prof]
        opened = {}
        for r in R:
            for e in r.events:
                if e["type"] == "planet":
                    opened.setdefault(e["id"], []).append(e["t"] / 3600)
        share = {}
        for r in R:
            tot = sum(r.final["world_runs"].values())
            for k, v in r.final["world_runs"].items():
                share[k] = share.get(k, 0) + v / tot / len(R)
        walls = [max((w["gap_min"] for w in pacing_report(E, r)["walls"]), default=0) for r in R]
        bonus = sum(e["value"] for r in R for e in r.events if e["type"] == "record_bonus") / len(R)
        life = st.mean(r.final["lifetime"]["credits"] for r in R)
        print(f"  {prof:8s} abre(h) " + " ".join(f"{k[:4]}={st.mean(v):.1f}" for k, v in opened.items())
              + " | runs% " + " ".join(f"{k[:4]}={100*v:.0f}" for k, v in sorted(share.items(), key=lambda x: -x[1]))
              + f" | parede {max(walls):.0f}min | bonus {100*bonus/max(life,1):.0f}% da renda")


if __name__ == "__main__":
    if "--final" in sys.argv:
        report(build((0.15, 0.4)), "bonus 15%/40% (MC 3 seeds)", seeds=(1, 2, 3))
    else:
        report(build(None), "sem bonus")
        for bb in ((0.25, 0.5), (0.15, 0.4), (0.10, 0.3)):
            report(build(bb), "bonus %d%%/%d%%" % (bb[0] * 100, bb[1] * 100))
