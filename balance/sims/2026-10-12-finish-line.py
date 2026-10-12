"""Linha de chegada da Lua (2026-10-12): onde pôr a distância que COMPLETA o mundo.
Usuário: "tem que completar por distância, faz uma análise matemática e defina onde deve ser".
Método: a Lua fica presa (parada complete_luna com estrelas infinitas) e o modelo joga 6 h; o recorde de distância
(max_d de cada viagem) ao longo do tempo diz em que hora cada perfil alcança D. Os ossos do céu (2026-10-11) impedem
o cruzeiro alto: o alcance por salto é limitado (TRACK_STYLES) — 3 cenários: sem limite (modelo antigo), até 5
plataformas (~1 km) e até 3 (~500 m, arco abaixo da faixa livre de 150 m).
Rodar da raiz: python3 balance/sims/2026-10-12-finish-line.py
"""
import copy
import json
import sys

sys.path.insert(0, ".claude/skills/economy-balance/scripts")
import econ
from econ import *

E0 = load("data/economy.json")
DS = [3000, 4000, 5000, 6000, 7000, 8000, 10000, 12000, 15000]
HOURS = 6.0


def locked(E):
    E = copy.deepcopy(E)
    for stop in E["progression"]["roads"]["luna"]:
        if stop["type"] == "complete":
            stop["stars"] = 10 ** 9
    return E


def job(args):
    styles, prof, seed = args
    econ.TRACK_STYLES = styles
    econ._TRACK_K_CACHE.clear()
    r = simulate(locked(E0), prof, hours=HOURS, seed=seed)
    best, out, runs = 0.0, {}, 0
    curve = []
    for s in r.samples:
        if s["planet"] != "luna":
            continue
        runs += 1
        best = max(best, s["max_d"])
        curve.append((round(s["t"] / 3600, 3), round(best)))
        for d in DS:
            if best >= d and d not in out:
                out[d] = (round(s["t"] / 3600, 2), runs)
    return styles, prof, seed, out, curve


if __name__ == "__main__" and "--v30" not in sys.argv:
    SC = {"sem limite": econ.TRACK_STYLES, "ate 5": (1, 2, 3, 5), "ate 3": (1, 2, 3)}
    items = [(st, p, sd) for st in SC.values() for p in ("casual", "engaged", "expert") for sd in (1, 2, 3)]
    res = parallel_map(job, items)
    name = {v: k for k, v in SC.items()}
    table = {}
    for styles, prof, seed, out, curve in res:
        table.setdefault((name[styles], prof), []).append(out)
    print("hora em que o recorde passa de D (mediana de 3 seeds; '-' = nao chega em 6 h)")
    print("cenario     perfil   " + " ".join(f"{d/1000:>6.0f}km" for d in DS))
    for (sc, prof), outs in sorted(table.items()):
        cells = []
        for d in DS:
            hs = sorted(o[d][0] for o in outs if d in o)
            cells.append(f"{hs[len(hs)//2]:>7.2f}" if len(hs) >= 2 else "      -")
        print(f"{sc:11s} {prof:8s} " + " ".join(cells))
    json.dump({f"{name[st]}|{p}|{sd}": {"out": {str(k): v for k, v in o.items()}, "curve": c}
               for st, p, sd, o, c in res}, open("balance/reports/2026-10-12-finish-line.json", "w"))


def done_at(args):
    """Com a spec v30 (chegada por distância): hora em que complete_luna acontece."""
    styles, prof, seed = args
    econ.TRACK_STYLES = styles
    econ._TRACK_K_CACHE.clear()
    r = simulate(load("data/economy.json"), prof, hours=8, seed=seed)
    ev = [e["t"] / 3600 for e in r.events if e["type"] == "road" and e["id"] == "complete_luna"]
    return styles, prof, seed, (round(ev[0], 2) if ev else None)


if __name__ == "__main__" and "--v30" in sys.argv:
    SC = {"sem limite": (1, 2, 3, 5, econ.TRACK_LOOKAHEAD), "ate 5": (1, 2, 3, 5), "ate 3": (1, 2, 3)}
    name = {v: k for k, v in SC.items()}
    res = parallel_map(done_at, [(st, p, sd) for st in SC.values() for p in ("casual", "engaged", "expert") for sd in (1, 2, 3)])
    print("v30: Lua completa (chegada 4 km) — horas por seed")
    for (sc, p) in [(a, b) for a in SC for b in ("casual", "engaged", "expert")]:
        print(f"{sc:11s} {p:8s}", [r[3] for r in res if name[r[0]] == sc and r[1] == p])
