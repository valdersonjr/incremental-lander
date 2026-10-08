"""v17: um minijogo (pedido-assinatura) por mundo, uma Estrada por mundo, ordem do mais facil ao mais dificil.
Lua=simple (trilha), Nuvens=passenger (fila/Snake), Cogumelos=soft (quique), Sorvete=fast (curling),
Jardim=heavy (Flappy), Bolhas=tow (garra). Completar a Estrada de um mundo libera o proximo."""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
import copy, statistics as st
from econ import *
E0 = load("data/economy.json")
ORDER = ["luna", "nuvens", "cogumelos", "sorvete", "jardim", "bolhas"]
MISSION = {"luna": "simple", "nuvens": "passenger", "cogumelos": "soft", "sorvete": "fast", "jardim": "heavy",
           "bolhas": "tow"}
LATE = {"thrust": 55, "tank": 40, "efficiency": 30}
TARGET = 1.15
# paradas (id, tipo, estrelas NO MUNDO); a 1a e a estrela 1 do pedido-assinatura (vem com o mundo)
ROADS = {
    "luna": [("start", "start", 0), ("nav_color", "grant", 2), ("land_shadow", "grant", 5), ("simple2", "mission", 8),
             ("stabilizer", "grant", 11), ("simple3", "mission", 14), ("complete_luna", "complete", 18)],
    "nuvens": [("passenger1", "mission", 0), ("land_level", "grant", 3), ("turbo", "grant", 7),
               ("passenger2", "mission", 11), ("land_planalto", "landscape", 14), ("passenger3", "mission", 18),
               ("complete_nuvens", "complete", 22)],
    "cogumelos": [("soft1", "mission", 0), ("gas_need", "grant", 3), ("land_serra", "landscape", 7),
                  ("soft2", "mission", 11), ("nav_trail", "grant", 14), ("land_crateras", "landscape", 17),
                  ("soft3", "mission", 21), ("complete_cogumelos", "complete", 25)],
    "sorvete": [("fast1", "mission", 0), ("land_predict", "grant", 4), ("land_degraus", "landscape", 8),
                ("fast2", "mission", 12), ("fleet", "unlock", 16), ("fast3", "mission", 21),
                ("complete_sorvete", "complete", 26)],
    "jardim": [("heavy1", "mission", 0), ("nav_route", "grant", 4), ("land_vale", "landscape", 8),
               ("heavy2", "mission", 12), ("autopilot", "unlock", 17), ("heavy3", "mission", 22),
               ("complete_jardim", "complete", 27)],
    "bolhas": [("tow1", "mission", 0), ("tow2", "mission", 6), ("tow3", "mission", 13),
               ("complete_bolhas", "complete", 20)],
}


def build(scale=1.0, target=TARGET):
    E = copy.deepcopy(E0)
    M = E["contracts"]["missions"]
    k = {x["id"]: x for x in M["kinds"]}
    k["simple"]["levels"] = [{"mult": 1.0}, {"mult": 1.15}, {"mult": 1.3}]
    for lv, (fm, fp) in zip(k["heavy"]["levels"], [(0.6, 0.3), (0.45, 0.45), (0.3, 0.6)]):
        lv["fail_mult"], lv["fail_p"] = fm, fp           # Jardim: nao passou todos os vaos = paga menos
    for lv in k["passenger"]["levels"]:
        lv.pop("leg2", None)                             # Nuvens: estrelas = mais carneirinhos (sem taxi)
    nodes = {n["id"]: n for n in M["nodes"]}
    for s_ in (2, 3):
        nodes.setdefault(f"simple{s_}", {"id": f"simple{s_}", "kind": "simple", "star": s_})
    M["nodes"] = list(nodes.values())
    M["planets"] = list(ORDER)
    planets = {p["id"]: p for p in E["planets"]}
    E["planets"] = [planets[i] for i in ORDER]
    luna = planets["luna"]
    for p in E["planets"]:
        p.pop("road", None)
        p["mission"] = MISSION[p["id"]]
    luna["mission_bonus"] = 0.15                         # queijinhos da trilha (media de um piloto que pega todos)
    prof = profile_from(E, "engaged")
    stt = ship_stats(E, LATE)
    allm = {x: 3 for x in MISSION.values()}
    base = sum(expected_income(E, luna, stt, prof, missions=allm).values())
    for p in E["planets"]:
        if p["id"] == "luna":
            continue
        p["pay_mult"] = 1.0
        raw = sum(expected_income(E, p, stt, prof, missions=allm).values())
        p["pay_mult"] = round(target * base / raw, 3) if raw > 0 else 1.0
    E["progression"].pop("road", None)
    E["progression"]["roads"] = {w: [{"id": i, "type": t, "stars": max(0, round(s * scale)) if i not in ("start",) else 0}
                                     for i, t, s in stops] for w, stops in ROADS.items()}
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
        walls = [max((w["gap_min"] for w in pacing_report(E, r)["walls"]), default=0) for r in R]
        done = st.mean(len(r.final["done"]) for r in R)
        print(f"  {prof:8s} abre(h) " + " ".join(f"{k[:4]}={st.mean(v):.2f}" for k, v in opened.items())
              + f" | completos {done:.1f} | parede {max(walls):.0f}min | Motor {st.mean(r.final['levels']['thrust'] for r in R):.0f}")


if __name__ == "__main__":
    report(build(), "v17 rascunho")
