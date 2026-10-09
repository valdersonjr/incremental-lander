import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
# Validacao do aprendiz contra os mais vendidos: "Veja como!" (Super Guide) depois de retries_per_hop+1 batidas
# seguidas no mesmo salto, o piloto automatico entrega. 1a compra do novato com e sem o guia (1 h, seeds 1-5).
# Previsao: casual/engaged identicos (sem guia no perfil); novato igual ou mais rapido no pior caso.
from econ import *
E = load("data/economy.json")
jobs = []  # (rodada de 1 h acima no CHANGELOG; agora so as 20 sementes curtas)
for r, (p, _, s) in zip(simulate_many(E, jobs), jobs):
    print(f"{p:8s} s{s} first_buy={pacing_report(E, r)['first_purchase_s']}s")
nv = profile_from(E, "novice"); nv.guide_after = 0
# 20 sementes, so o comeco (0,15 h): o guia so dispara com 3 batidas seguidas no mesmo salto
import statistics
def fb(prof, s):
    return pacing_report(E, simulate(E, prof, 0.15, s))["first_purchase_s"] or 9999
with_g = [fb("novice", s) for s in range(1, 21)]
nv = profile_from(E, "novice"); nv.guide_after = 0
without = [fb(nv, s) for s in range(1, 21)]
print("com guia  mediana", statistics.median(with_g), "pior", max(with_g), "seeds diferentes", sum(a != b for a, b in zip(with_g, without)))
print("sem guia  mediana", statistics.median(without), "pior", max(without))
