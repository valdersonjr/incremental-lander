"""v7 — variedade nas entregas: plataformas com multiplicador (Lunar Lander), combo de pousos bons, cristais no ar.

Hipotese (escrita antes de simular):
- tipos normal/estreita/apertada (peso .5/.33/.17, x1/x1.6/x2.5), combo +15%/pouso bom (q>=.6, ate 5),
  cristais 3 x 5% do pagamento-base -> renda do engaged ~+50%; sem compensar, o jogo encurta ~20%.
- expert ganha mais que casual (combo quase sempre; estreita quase nao derruba a qualidade dele):
  razao termino casual/expert sobe de 1.22 para ~1.35-1.5. Casual continua terminando.
- compensar com pay_base x ~0.7 devolve o engaged a ~4.9 h.
Sucesso: expert < engaged < casual, casual termina, sem paredes novas, nenhum tipo de plataforma "sempre" escolhido.
Rodar da raiz: python3 balance/sims/2026-10-03-v7-variety.py [escala_pay ...]
"""
import collections
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E0 = load("data/economy.json")


VARIANTS = {
    # a: primeira proposta (expert disparou: casual/expert 1.98)
    "a": {"tiers": [(1.0, .5, 0, 1), (1.6, .33, .08, 1.6), (2.5, .17, .16, 2.5)], "combo": (.6, .15, 5)},
    # b: menos risco de batida nas dificeis, combo mais suave e mais facil de manter
    "b": {"tiers": [(1.0, .5, 0, 1), (1.5, .33, .06, 1.3), (2.2, .17, .12, 1.7)], "combo": (.55, .1, 5)},
}


def v7(pay_scale: float = 1.0, variant: str = "b") -> dict:
    E = copy.deepcopy(E0)
    C = E["contracts"]
    V = VARIANTS[variant]
    C["pad_tiers"] = [{"id": tid, "name": nm, "mult": t[0], "weight": t[1], "q_drop": t[2], "crash_mult": t[3]}
                      for (tid, nm), t in zip((("normal", "normal"), ("narrow", "estreita"), ("tight", "apertada")),
                                              V["tiers"])]
    C["combo"] = {"q_min": V["combo"][0], "step": V["combo"][1], "max_steps": V["combo"][2]}
    C["pickups"] = {"per_hop": 3, "value_frac": 0.05}
    C["pay_base"] = round(E0["contracts"]["pay_base"] * pay_scale, 4)
    E["meta"]["version"] = 7
    return E


def choices(E: dict, prof_name: str, planet_id: str = "luna", runs: int = 300) -> dict:
    """Escolhas do piloto: % de cada tipo de plataforma, combo medio e taxa de batida por run."""
    P = {p["id"]: p for p in E["planets"]}[planet_id]
    st_ = ship_stats(E, {"thrust": 4, "tank": 6, "efficiency": 4})
    prof = profile_from(E, prof_name)
    rng = random.Random(5)
    log: list = []
    crashes = 0
    for _ in range(runs):
        crashes += do_run(E, P, st_, prof, rng, log=log).crashed
    cnt = collections.Counter(x[1] for x in log)
    tot = max(1, len(log))
    return {"tipos_%": {k: round(100 * v / tot) for k, v in cnt.items()},
            "combo_medio": round(sum(x[3] for x in log) / tot, 2), "batida_run_%": round(100 * crashes / runs)}


if __name__ == "__main__":
    # uso: [variante] [escala_pay ...]
    var = sys.argv[1] if len(sys.argv) > 1 else "b"
    scales = [float(x) for x in sys.argv[2:]] or [1.0]
    for prof in ("casual", "engaged", "expert"):
        print(prof, choices(v7(1.0, var), prof))
    for sc in scales:
        print(f"\n### v7{var} pay_scale {sc}")
        screen(v7(sc, var))
