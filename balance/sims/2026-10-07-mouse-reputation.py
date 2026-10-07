# v14 — Reputação POR RATINHO (pedido do usuário): pontos permanentes por tipo de missão; 3 níveis +10/+20/+30% nos
# pedidos daquele ratinho. Missão cumprida = 1 ponto, com pouso perfeito = 2; falhou/bateu = 0 (padrão Death Stranding:
# entrega em bom estado e nota S contam mais). Limiares PROVISÓRIOS (economia fina depois, jogando).
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")
E["contracts"]["reputation"] = {
    "notes": "v14: Reputacao por ratinho (tipo de missao), permanente. Entrega com a regra cumprida = points_ok; com "
             "pouso perfeito (world.json > landing.perfect: reto e macio) = points_perfect; falhou ou bateu = 0. "
             "levels: pontos acumulados -> +bonus nos pedidos DAQUELE ratinho. model_q_min = so o modelo (q do perfil "
             "como pouso perfeito). Limiares provisorios.",
    "points_ok": 1, "points_perfect": 2, "model_q_min": 0.85,
    "levels": [{"points": 5, "bonus": 0.10}, {"points": 15, "bonus": 0.20}, {"points": 30, "bonus": 0.30}]}
E["meta"]["version"] = 14
E["meta"]["notes"] += (" v14: Reputacao por ratinho (contracts.reputation.levels: 5/15/30 pontos -> +10/20/30% nos pedidos"
                       " daquele ratinho; cumprida = 1, pouso perfeito = 2); sai o +10% na entrega seguinte.")
save(E, "data/economy.json")
r = simulate(E, "engaged", hours=6, seed=1)
print("reputacao em 6h:", r.final["reputation"])
