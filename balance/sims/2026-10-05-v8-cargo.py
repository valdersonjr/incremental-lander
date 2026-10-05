"""v8 (2026-10-05): cargas com regra propria na Lua + habilidades compraveis.
Usuario: "o que nao existir no nosso jogo, adicione de forma divertida e dada a tematica do mapa (so a Lua)".
Pesquisa: Space Taxi (passageiro/rota), Thrust/Solar Jetman (carga rebocada), Death Stranding (carga fragil e
prazo: entrega limpa paga mais), Lunar Lander Beyond (objetivos variados: resgate).
Variantes (triagem casual/engaged/expert x 2 seeds): bonus cheios + gas x1,25 -> parede de 21,7 min antes de Ares no
casual; escolhida "B": bonus x0,7 e roda rebocada gas x1,1 (paredes ~11 min, como a v7).
Previsao: media de pagamento das cargas ~x1,15 para o engaged (bonus menos falhas) e +4% de gas (roda rebocada)
-> Ares ~5-8% mais cedo; Kronos/Titan iguais (cargas so na Lua). Habilidades compradas na 1a meia hora.
Uso: python3 balance/sims/2026-10-05-v8-cargo.py [--save]
"""
import copy
import sys

sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E0 = load("data/economy.json")
# a spec salva ja e v8: tira as adicoes para comparar com a v7.1 e o script continuar reproduzivel
E0["upgrades"] = [u for u in E0["upgrades"] if not u.get("ability")]
E0["contracts"].pop("cargo", None)
for _k in ("stabilizer", "turbo"):
    E0["ship"]["base"].pop(_k, None)
E0["meta"]["version"] = 7
E = copy.deepcopy(E0)
E["meta"]["version"] = 8
E["contracts"]["cargo"] = {
    "planets": ["luna"],
    "kinds": [
        {"id": "box", "name": "caixa de queijo", "mult": 1.0, "weight": 0.32},
        {"id": "fragile", "name": "bolo de queijo", "mult": 1.35, "weight": 0.18, "fail_mult": 0.5, "fail_p": 0.45},
        {"id": "urgent", "name": "sorvete", "mult": 1.3, "weight": 0.18, "fail_mult": 0.6, "fail_p": 0.35},
        {"id": "towed", "name": "queijão no cabo", "mult": 1.5, "weight": 0.16, "fail_mult": 0.6, "fail_p": 0.45,
         "dv_mult": 1.1},
        {"id": "rescue", "name": "ratinho perdido", "mult": 1.4, "weight": 0.16, "fail_mult": 0.715, "fail_p": 0.4},
    ],
}
E["ship"]["base"].update({"stabilizer": 0.0, "turbo": 0.0})
E["upgrades"] += [
    {"id": "stabilizer", "name": "Estabilizador", "ability": True, "ability_value": 0.04,
     "effect": {"stat": "stabilizer", "op": "add", "value": 1.0},
     "cost": {"credits": {"type": "exp", "base": 250, "growth": 1.0}}, "max_level": 1},
    {"id": "turbo", "name": "Turbo", "ability": True, "ability_value": 0.04,
     "effect": {"stat": "turbo", "op": "add", "value": 1.0},
     "cost": {"credits": {"type": "exp", "base": 1500, "growth": 1.0}}, "max_level": 1},
]

if __name__ == "__main__":
    for name in ("casual", "engaged", "expert"):
        pay, dv = cargo_expect(E, E["planets"][0], profile_from(E, name))
        print(f"cargas {name}: pagamento x{pay:.3f}  gas x{dv:.3f}")
    if "--base" in sys.argv:
        print("--- base v7.1"); screen(E0)
    print("--- v8"); screen(E)
    r = simulate(E, "engaged", 3, 1)
    buys = [(round(e['t'] / 60, 1), e.get('id')) for e in r.events if e.get('id') in ("stabilizer", "turbo")]
    print("compra das habilidades (min, id):", buys)
    if "--save" in sys.argv:
        save(E, "data/economy.json")
        print("salvo data/economy.json")
