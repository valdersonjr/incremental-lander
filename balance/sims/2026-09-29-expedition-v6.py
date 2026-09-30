"""v6: frota (it.3) + marcos (25 niveis x1.5) + Expedicao a Titan em 8 etapas persistentes (megaprojeto)."""
import sys, copy, importlib.util; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
sp = importlib.util.spec_from_file_location("m", "balance/sims/2026-09-29-milestones-v5.py"); m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)

STAGES = [  # (id, nome, stat, mult)
    ("exp1_station", "Estacao Orbital de Apoio", "pay_mult", 1.20),
    ("exp2_cryo", "Tanques Criogenicos", "tank", 1.25),
    ("exp3_shield", "Escudo Termico Ablativo", "pay_mult", 1.20),
    ("exp4_satnet", "Rede de Satelites de Navegacao", "efficiency", 1.15),
    ("exp5_habitat", "Modulo de Habitacao", "pay_mult", 1.20),
    ("exp6_fusion", "Reator de Fusao Compacto", "thrust", 1.15),
    ("exp7_anchor", "Ancora Gravitacional", "autopilot", 1.30),
    ("exp8_aurora", "Nave-mae Aurora", "pay_mult", 1.25),
]

def build_v6(E0, c1=1e11, r=2.2, ore_frac=0.01):
    E = m.build_v5m(E0)
    prev = None
    for i, (sid, name, stat, mult) in enumerate(STAGES):
        c = c1 * r ** i
        u = {"id": sid, "name": f"Expedicao Titan {i+1}/8: {name}", "progress": True, "persistent": True,
             "max_level": 1, "effect": {"stat": stat, "op": "mult", "value": mult},
             "cost": {"credits": {"type": "exp", "base": float(f"{c:.3g}"), "growth": 1.0},
                      "ore": {"type": "exp", "base": float(f"{c * ore_frac / E['resource_value']['ore']:.3g}"), "growth": 1.0}}}
        if prev: u["requires_upgrade"] = {prev: 1}
        else: u["requires_shop"] = "warp_drive"
        E["upgrades"].append(u); prev = sid
    t = next(p for p in E["planets"] if p["id"] == "titan")
    t["unlock"] = {"credits": 1.0}; t["requires_upgrade"] = {prev: 1}; t.pop("requires_shop", None)
    E["meta"]["version"] = 6
    E["meta"]["notes"] = ("v6: v4 + frota de drones (renda = drones x autopilot x renda do jogador) + marcos (25 niveis x1.5 "
                          "no pagamento) + Expedicao a Titan (8 etapas persistentes; a ultima libera Titan). Unidades: m, m/s, m/s2, gas.")
    return E

if __name__ == "__main__":
    E0 = load("data/economy.json")
    for c1, r in [(1e11, 2.2), (3e11, 2.0), (1e11, 2.6)]:
        E = build_v6(E0, c1, r)
        print(f"\n### etapa1 {fmt(c1)}, x{r}/etapa (total {fmt(sum(c1*r**i for i in range(8)))})", flush=True)
        out = screen(E)
        r0 = out["engaged"][0]
        print("   etapas engaged (h):", [(e["id"][:4], round(e["t"]/3600, 2)) for e in r0.events if e["type"] == "upgrade" and e["id"].startswith("exp")])
        save(E, f"balance/sims/economy-v6-c{c1:.0e}-r{r}.json")
