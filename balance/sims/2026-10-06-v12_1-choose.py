"""v12.1: um pedido por ratinho (Simples com 3 faixas) e o jogador escolhe plataforma + estrela no cartao.
Rodar: python3 balance/sims/2026-10-06-v12_1-choose.py [horas] [--apply]"""
import sys, json, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts"); sys.path.insert(0, "balance/sims")
from econ import *
import importlib.util
sp = importlib.util.spec_from_file_location("v12", "balance/sims/2026-10-06-v12-missions.py")
v12 = importlib.util.module_from_spec(sp); sp.loader.exec_module(v12)

E = load("data/economy.json")
M = copy.deepcopy(E)
M["contracts"]["missions"] = json.load(open("balance/sims/v12_1_missions.json"))
M["meta"]["version"] = 12
h = float(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else 6
v12.show("v12.1", M, h)
r = simulate(M, "engaged", 1.0, seed=3)
logs = []
for _ in range(3):
    lg = []
    do_run(M, M["planets"][0], r.final["stats"], profile_from(M, "engaged"), random.Random(5), log=lg,
           missions=missions_unlocked(M, set(r.final["missions"])))
    logs += lg
print("escolhas (d, plataforma, q, combo, espaco, estrela) depois de 1 h engaged:")
for x in logs[:10]:
    print("  ", round(x[0]), x[1], round(x[2], 2), x[4], x[5])
if "--apply" in sys.argv:
    M["meta"]["notes"] += " v12.1: um pedido por ratinho; jogador escolhe plataforma e estrela."
    save(M, "data/economy.json")
    print("aplicado")
