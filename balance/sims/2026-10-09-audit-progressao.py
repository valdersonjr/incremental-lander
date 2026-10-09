"""Auditoria da progressão (pedido do usuário 2026-10-09): (1) a missão longa domina? (2) cada nível de peça rende
demais? Mede, na Lua e com o perfil engaged, pagamento por gás e por segundo de cada escolha (perto/médio/longe ×
plataforma) e a elasticidade da renda por nível de cada peça (renda com +1 nível / renda sem) contra o aumento do preço."""
import sys, math
sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")
luna = next(p for p in E["planets"] if p["id"] == "luna")
prof = profile_from(E, "engaged")
lo, hi = luna["distance"]
D = {"perto": lo * (hi / lo) ** (1 / 6), "medio": lo * (hi / lo) ** 0.5, "longe": lo * (hi / lo) ** (5 / 6)}

def choice_table(levels):
    st = ship_stats(E, levels)
    out = []
    for name, d in D.items():
        dv = hop_dv(luna, d, st, prof)
        gas = gas_for(E, dv, st, st["tank"])
        t = hop_time(luna, d, st, prof)
        for tier in ("normal", "narrow", "tight"):
            pay = delivery_pay(E, luna, d, st, 0.7, tier)
            reach = gas <= st["tank"]
            out.append((name, int(d), tier, pay, gas, pay / gas, pay / t, reach))
    return st, out

for label, lv in (("inicio (tudo 0)", {}), ("meio (10 cada)", {"thrust": 10, "tank": 10, "efficiency": 10, "gear": 5}),
                  ("tarde (40 cada)", {"thrust": 40, "tank": 40, "efficiency": 40, "gear": 15})):
    st, rows = choice_table(lv)
    print(f"\n== {label}: tanque {st['tank']:.0f} gas, eficiencia {st['efficiency']:.2f}, motor {st['thrust']:.1f}")
    print(f"{'escolha':8} {'dist m':>7} {'plataf.':8} {'paga':>9} {'gas':>8} {'paga/gas':>9} {'paga/s':>8} alcança")
    for r in rows:
        print(f"{r[0]:8} {r[1]:7d} {r[2]:8} {r[3]:9.0f} {r[4]:8.1f} {r[5]:9.2f} {r[6]:8.1f} {'sim' if r[7] else 'NAO'}")

print("\n== Elasticidade: renda esperada/s com +1 nivel vs preço desse nivel (Lua, engaged)")
for base_lv in (0, 10, 30):
    base = {"thrust": base_lv, "tank": base_lv, "efficiency": base_lv, "gear": min(base_lv, 20)}
    inc0 = expected_income(E, luna, ship_stats(E, base), prof)["credits"]
    for uid in ("thrust", "tank", "efficiency", "gear"):
        u = next(x for x in E["upgrades"] if x["id"] == uid)
        lv = dict(base); lv[uid] += 1
        inc1 = expected_income(E, luna, ship_stats(E, lv), prof)["credits"]
        c0, c1 = cost_at(u["cost"]["credits"], base[uid]), cost_at(u["cost"]["credits"], base[uid] + 1)
        payback = c1 / max(inc1 - inc0, 1e-9)
        print(f"nivel {base_lv:2d} {uid:10} renda {inc0:9.2f}/s -> {inc1:9.2f}/s ({(inc1/inc0-1)*100:+5.1f}%)"
              f"  preço {c1:10.0f} (+{(c1/c0-1)*100 if c0 else 0:4.1f}%)  paga-se em {fmt_time(payback)}")
