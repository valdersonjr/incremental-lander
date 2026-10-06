"""v10 (2026-10-06): presentes no alto do morro entre as plataformas.
Usuario: "interacao com coisa do mapa para ganhar alguma recompensa e ajudar na progressao" -> escolheu a ideia 1
(pousar/encostar em lugares do cenario da um presente pequeno, opcional, uma vez por salto).
Mecanica: metade dos saltos tem um presente no ponto mais alto do relevo entre as plataformas (crista); encostar devagar
pega. Galao de gas (devolve 30% do tanque) ou presente (30% do pagamento-base da entrega). Buscar custa ~8% de gas a
mais no salto (descer na crista e subir de novo). Modelo: pega com chance = skill.
Previsao: engaged (skill ~0,7) ganha ~+5% de pagamento e ~+5% do tanque por salto -> runs do comeco fazem mais
entregas -> Ares ~5% mais cedo; fim igual (no meio/fim o run acaba pelo teto de 6 entregas). Expert ganha mais que
casual (habilidade conta).
Uso: python3 balance/sims/2026-10-06-v10-gifts.py [--base] [--save]
"""
import copy
import sys

sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E0 = load("data/economy.json")
E0["contracts"].pop("gifts", None)
E0["meta"]["version"] = 9
E = copy.deepcopy(E0)
E["meta"]["version"] = 10
E["meta"]["notes"] += " v10: presentes no alto do morro (contracts.gifts): encostar devagar pega gas ou creditos."
E["contracts"]["gifts"] = {
    "chance": 0.5,
    "dv_extra": 0.08,
    "kinds": [
        {"id": "gas", "name": "galão de gás", "weight": 0.5, "gas_frac": 0.3},
        {"id": "gift", "name": "presente", "weight": 0.5, "pay_frac": 0.3},
    ],
}

if __name__ == "__main__":
    for name in ("casual", "engaged", "expert"):
        print(name, "presente (pag, gas, dv):", [round(x, 3) for x in gift_expect(E, E["planets"][0], profile_from(E, name))])
    if "--base" in sys.argv:
        print("--- base v9"); screen(E0)
    print("--- v10"); screen(E)
    if "--save" in sys.argv:
        save(E, "data/economy.json")
        print("salvo data/economy.json")
