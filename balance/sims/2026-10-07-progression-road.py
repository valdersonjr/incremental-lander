# v13 — PROGRESSÃO: Estrada das Estrelas + Reputação (+10% após pouso perfeito).
# Só regras: os números da estrada são PROVISÓRIOS (curva do protótipo HTML); a economia fina vem depois, jogando.
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")

# 1) Reputação substitui o combo; sai o upgrade "Reputação" comprado com moedas (e os marcos dele)
C = E["contracts"]
C.pop("combo", None)
C["reputation"] = {"bonus": 0.10, "model_q_min": 0.85,
                   "notes": "v13: pouso perfeito (no jogo: reto e macio, world.json > landing.perfect) -> a PROXIMA "
                            "entrega vale +bonus; nao acumula; bater perde a atual e a proxima. model_q_min = so o "
                            "modelo (q do perfil) para estimar a chance de pouso perfeito."}
E["upgrades"] = [u for u in E["upgrades"] if u["id"] != "contracts"]

# 2) Estrada: ordem = ordem em que o jogador simulado (v12, engaged) alcançava cada coisa
order = [("start", "start"),
         ("heavy1", "mission"), ("stabilizer", "grant"), ("nav_color", "grant"), ("soft1", "mission"),
         ("fast1", "mission"), ("land_shadow", "grant"), ("turbo", "grant"), ("land_level", "grant"),
         ("heavy2", "mission"), ("soft2", "mission"), ("nav_trail", "grant"), ("gas_need", "grant"),
         ("land_predict", "grant"), ("nav_route", "grant"), ("passenger1", "mission"), ("fast2", "mission"),
         ("passenger2", "mission"), ("tow1", "mission"), ("heavy3", "mission"), ("soft3", "mission"),
         ("fast3", "mission"), ("tow2", "mission"), ("passenger3", "mission"), ("tow3", "mission"),
         ("double1", "mission"), ("fleet", "unlock"), ("autopilot", "unlock"), ("final", "final")]
n = len(order)
road = []
for i, (sid, typ) in enumerate(order):
    stars = 0 if i == 0 else max(1, round(1 + 123 * ((i - 1) / (n - 2)) ** 1.45))  # curva do protótipo (rascunho)
    road.append({"id": sid, "type": typ, "stars": stars})
E["progression"] = {"notes": "v13 (2026-10-07): Estrada das Estrelas (padrao Trophy Road). Estrelas ACUMULADAS (1 por "
                             "entrega, nao se gastam) liberam as paradas sozinhas. Estrelas por parada = RASCUNHO.",
                    "road": road}
E["meta"]["version"] = 13
E["meta"]["notes"] += (" v13: PROGRESSAO - estrada das estrelas (progression.road; estrelas acumuladas liberam ratinhos,"
                       " habilidades, ajudas, Frota e Piloto) e Reputacao +10% apos pouso perfeito (contracts.reputation"
                       " substitui combo); sai o upgrade Reputacao por creditos. Numeros provisorios.")
save(E, "data/economy.json")
print([(s["id"], s["stars"]) for s in road])
