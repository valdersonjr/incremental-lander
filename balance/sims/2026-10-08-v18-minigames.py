"""v18 (auditoria dos minijogos, 2026-10-08): pagamento que acompanha o minijogo.
Mudancas:
  1. Credito parcial (Nuvens/Jardim/Bolhas): regra falhou paga fail_mult + (1 - fail_mult) x parte cumprida
     (planets[].partial_frac_model = parte media no modelo quando falha).
  2. Lua: a estrela da Simples vale pelos queijinhos: mult 1/1/1 e mission_bonus [0,15, 0,35, 0,6] x fracao.
  3. Cogumelos: mission_bonus 0,15 (chapeus quicados / total).
  4. takeoff_twr: Jardim 1,3 (Pesada so aparece se motor/div > 1,3 g); Bolhas [1,9, 2,1, 2,5] (carga no cabo).
PREVISAO (antes de simular):
  - Lua: ★3 deixa de ser escolha dominante para quem pega pouco; o casual (skill ~0,5) escolhe ★1/★2 com mais
    frequencia; renda na Lua do engaged -3 a -8%; Nuvens abre poucos minutos mais tarde.
  - Credito parcial: casual ganha +5 a +10% em Nuvens/Jardim; expert quase igual (falha pouco).
  - Cogumelos +~5% de renda.
  - takeoff_twr: Jardim ★2/★3 aparecem um pouco mais tarde (motor ~15+); Bolhas sem efeito (nave forte la).
  - Mundos abrem com diferenca < 10% da v17; nenhuma parede nova.
Rodar da raiz: python3 balance/sims/2026-10-08-v18-minigames.py [--save]"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
import copy
from econ import *
import math
from econ import _mission_choices, _heavy_factor

E0 = load("data/economy.json")


def build() -> dict:
    E = copy.deepcopy(E0)
    E["meta"]["version"] = 18
    k = {x["id"]: x for x in E["contracts"]["missions"]["kinds"]}
    k["simple"]["levels"] = [{"mult": 1.0}, {"mult": 1.0}, {"mult": 1.0}]
    P = {p["id"]: p for p in E["planets"]}
    P["luna"]["mission_bonus"] = [0.15, 0.4, 0.75]   # 0,35/0,6 deixava o casual 7% mais lento (seeds 1-5)
    P["cogumelos"]["mission_bonus"] = 0.15
    P["nuvens"]["partial_frac_model"] = 0.6
    P["jardim"]["partial_frac_model"] = 0.6
    P["bolhas"]["partial_frac_model"] = 0.5
    P["jardim"]["takeoff_twr"] = 1.3
    P["bolhas"]["takeoff_twr"] = [1.9, 2.1, 2.5]
    E["contracts"]["missions"]["notes_v18"] = (
        "v18 (auditoria dos minijogos): credito parcial (EconMath.fail_pay: fail_mult + (1 - fail_mult) x parte "
        "cumprida do minijogo; modelo usa planets[].partial_frac_model); planets[].mission_bonus pode ser lista por "
        "estrela (Lua: a estrela vale pelos queijinhos, Simples mult 1/1/1); planets[].takeoff_twr = folga de empuxo "
        "minima do pedido-assinatura (Jardim 1,3; Bolhas por estrela, inclui a carga no cabo).")
    return E


def worlds_open(E: dict, hours: float = 6, seeds=(1, 2)) -> dict:
    jobs = [(p, s) for p in ("casual", "engaged", "expert") for s in seeds]
    rs = parallel_map(lambda a: simulate(E, a[0], hours, a[1]), jobs)
    out = {}
    for prof in ("casual", "engaged", "expert"):
        R = [r for (pp, _), r in zip(jobs, rs) if pp == prof]
        opened: dict = {}
        for r in R:
            for e in r.events:
                if e["type"] == "planet":
                    opened.setdefault(e.get("planet", e.get("id")), []).append(e["t"] / 3600)
        rep = [pacing_report(E, r) for r in R]
        worst = max(max((w["gap_min"] for w in x["walls"]), default=0) for x in rep)
        money = sum(r.final.get("money", {}).get("credits", 0) if isinstance(r.final.get("money"), dict) else 0
                    for r in R) / len(R)
        out[prof] = ({w: round(sum(v) / len(v), 2) for w, v in opened.items()}, worst, money)
    return out


def luna_choice(E: dict, levels: dict) -> dict:
    """Valor esperado por gas de cada estrela da Simples na Lua (plataforma normal, d = 3000 m), por perfil."""
    planet = next(p for p in E["planets"] if p["id"] == "luna")
    stats = ship_stats(E, levels)
    out = {}
    for prof_id in ("casual", "engaged", "expert"):
        prof = profile_from(E, prof_id)
        base = contract_pay(E, planet, 3000.0, stats)
        row = {}
        for ch in _mission_choices(E, planet, stats, prof, "simple", {"simple": 3}):
            g = hop_dv(planet, 3000.0, stats, prof) * ch["dv"]
            row[ch["star"]] = round(base * ((1 + 1.5 * prof.skill ** 2) * ch["pay"] + ch.get("bonus", 0.0)) / g, 3)
        out[prof_id] = row
    return out


def jardim_stars(E: dict) -> list:
    """Estrelas da Pesada que aparecem no Jardim por nivel de Motor."""
    out = []
    for lv in (5, 10, 15, 20, 30):
        st = ship_stats(E, {"thrust": lv})
        out.append((lv, round(st["thrust"], 1), [s for s in (1, 2, 3)
                    if math.isfinite(_heavy_factor(next(p for p in E["planets"] if p["id"] == "jardim"), st,
                                                   mission_level(E, "heavy", s).get("thrust_div", 1.0),
                                                   takeoff_twr(next(p for p in E["planets"] if p["id"] == "jardim"),
                                                               "heavy", s)))]))
    return out


if __name__ == "__main__":
    E1 = build()
    print("Lua v17 (valor/gas por estrela):", luna_choice(E0, {"thrust": 20, "tank": 15, "efficiency": 8}))
    print("Lua v18 (valor/gas por estrela):", luna_choice(E1, {"thrust": 20, "tank": 15, "efficiency": 8}))
    print("Jardim v17 estrelas por motor:", jardim_stars(E0))
    print("Jardim v18 estrelas por motor:", jardim_stars(E1))
    for label, E in (("v17", E0), ("v18", E1)):
        for prof, (opened, worst, money) in worlds_open(E).items():
            print(f"{label} {prof:8s} mundos(h) {opened} | pior parede {worst} min")
    if "--save" in sys.argv:
        save(E1, "data/economy.json")
        print("salvo data/economy.json v18")
