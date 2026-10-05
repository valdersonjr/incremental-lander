"""v9 (2026-10-05): sai cristal e Refinaria; entra a arvore de ajudas de voo ("Painel de bordo").
Usuario: "tirar essa porra de cristal e refinaria, nao vi mta diversao" + arvore que facilita a vida
(setinha -> cor de chegando -> rota tracada ...). "A ideia do jogo e ser simples".
Pesquisa: meta-progressao de roguelite funciona melhor dando opcoes/acessibilidade do que poder bruto
(GMTK "Roguelikes, Persistency and Progression"); landers com modulos de radar/alerta/"look ahead".
Ajudas = compras unicas em creditos, persistentes (nao resetam no prestigio), com pre-requisito
(requires_upgrade); nao mudam stats -> no modelo valem como habilidade (ability_value pequeno).
Previsao: tirar cristais tira ate 15% x skill do pagamento-base (expert ~-12%, casual ~-6%) -> tudo ~5-10% mais
lento; pay_base 8,5 -> 9,5 devolve quase tudo (os cristais tinham entrado com pay_base 10 -> 8,5). Refinaria so
pesava no fim (eficiencia), sem efeito no ritmo porque o run acaba pelo teto de entregas. Ajudas custam ~16K no
total, compradas na 1a hora (atraso < 2 min).
Uso: python3 balance/sims/2026-10-05-v9-assists.py [--base] [--save]
"""
import copy
import sys

sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E0 = load("data/economy.json")
E = copy.deepcopy(E0)
E["meta"]["version"] = 9
E["meta"]["notes"] += (" v9: sem cristais (contracts.pickups) e sem Refinaria; pay_base 9,5; arvore de ajudas de voo"
                       " (upgrades assist: compra unica, persistente, requires_upgrade; nao mudam a fisica).")
E["contracts"].pop("pickups", None)
E["contracts"]["pay_base"] = 9.5
E["upgrades"] = [u for u in E["upgrades"] if u["id"] != "refinery"]

# (id, nome, galho, custo, pre-requisito)
ASSISTS = [
    ("nav_color", "Setinha colorida", "nav", 80, None),
    ("nav_trail", "Rastro", "nav", 800, "nav_color"),
    ("nav_route", "Rota completa", "nav", 8000, "nav_trail"),
    ("land_shadow", "Sombra", "land", 150, None),
    ("land_level", "Nivelador", "land", 500, "land_shadow"),
    ("land_predict", "Onde vou cair", "land", 5000, "land_level"),
    ("gas_need", "Dá pra chegar?", "gas", 2000, None),
]
for aid, name, branch, cost, req in ASSISTS:
    E["ship"]["base"][aid] = 0.0
    u = {"id": aid, "name": name, "assist": branch, "ability": True, "ability_value": 0.01, "persistent": True,
         "effect": {"stat": aid, "op": "add", "value": 1.0},
         "cost": {"credits": {"type": "exp", "base": cost, "growth": 1.0}}, "max_level": 1}
    if req:
        u["requires_upgrade"] = {req: 1}
    E["upgrades"].append(u)

if __name__ == "__main__":
    if "--base" in sys.argv:
        print("--- base v8"); screen(E0)
    print("--- v9"); screen(E)
    r = simulate(E, "engaged", 3, 1)
    ids = {a[0] for a in ASSISTS}
    print("compra das ajudas (min, id):", [(round(e['t'] / 60, 1), e.get('id')) for e in r.events if e.get('id') in ids])
    if "--save" in sys.argv:
        save(E, "data/economy.json")
        print("salvo data/economy.json")
