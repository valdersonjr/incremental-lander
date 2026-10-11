"""v21 — pista "Mais longe" (opção C da auditoria de clareza, escolhida pelo usuário em 2026-10-11).

Hipótese (antes de simular):
- Viagem = plataformas em sequência; com a nave inicial (tanque 100, ~20 de gás por salto de 150 m) o engajado faz
  ~5 pousos (~900 m) por viagem; galões estendem ~1 salto a cada ~450 m. Run do modelo ~2–3 min (alvo 45–240 s).
- Pagamento por x do começo: os pousos tardios valem 2–3× os primeiros -> ir longe é o que rende (o objetivo da C).
- Estrelas = nota do pouso (~2,2 por pouso no engajado) -> a Estrada de cada mundo precisa de ~2,5–3× as estrelas de
  hoje para manter os mundos perto de 0,4 / 1,2 / 1,9 / 2,6 / 3,1 h (v20).
- Sucesso: 1ª compra ≤ 240 s, intervalo mediano ≤ 6 min na 1ª hora, run 45–240 s, nenhuma peça > 55% dos níveis,
  expert > engajado > casual nos mundos, pulo de plataforma escolhido às vezes (não sempre, não nunca).
Rodar da raiz: python3 balance/sims/2026-10-11-v21-track.py [road_scale]
"""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import copy

E0 = load("data/economy.json")

TRACK = {
    "gap": [130, 220], "seed": 7, "rough_scale": 450, "pay_unit": 400,
    "can_first": 350, "can_every": 450, "can_scale": 1000, "can_frac": 0.35, "can_pick": 0.5,
    "skip_bonus": 0.25, "coin_frac": 0.1,
    "marker_every": 250, "marker_mult": 3.0,
    "stars": {"good": 0.6, "perfect": 0.85},
}


def v21(road_scale: float = 2.8) -> dict:
    E = copy.deepcopy(E0)
    E["contracts"]["track"] = dict(TRACK)
    E["contracts"]["run_fatigue"] = 1.0
    for p in E["planets"]:                     # gravidade baixa = saltos baratos: relevo sobe mais rapido
        if p["id"] == "nuvens":
            p["track"] = {"rough_scale": 220}
    for w, stops in E["progression"]["roads"].items():
        for s_ in stops:
            s_["stars"] = int(round(s_["stars"] * road_scale))
    return E


if __name__ == "__main__":
    rs = float(sys.argv[1]) if len(sys.argv) > 1 else 5.0
    E = v21(rs)
    st0 = ship_stats(E, {})
    import econ
    econ._FEEL = E
    for pid in ("luna", "jardim"):
        P = next(p for p in E["planets"] if p["id"] == pid)
        for prof in ("casual", "engaged", "expert"):
            r = do_run(E, P, st0, profile_from(E, prof), None, expected=True)
            print(f"{pid:8s} {prof:8s} nave inicial: pousos {r.deliveries} ate {r.max_distance:.0f} m, "
                  f"{r.rewards['credits']:.0f} moedas, {r.stars:.1f} estrelas, {r.time_s:.0f} s")
    # pulo de plataforma: fracao dos pousos que pularam uma (piloto do modelo, nave inicial e nave media)
    for lv in (0, 15, 35):
        st = ship_stats(E, {"thrust": lv, "tank": lv, "efficiency": lv, "gear": lv // 3})
        lg = []
        do_run(E, E["planets"][0], st, profile_from(E, "engaged"), None, expected=True, log=lg)
        print(f"   nave nivel {lv}: {len(lg)} pousos, {sum(1 for e in lg if e[5])} pulando, ate "
              f"{sum(e[0] for e in lg):.0f} m")
    for prof, (res, rep) in screen(E, hours=6, show=False).items():
        print(prof, {k: rep.get(k) for k in ("first_purchase_s", "gap_min_median", "gap_min_p90", "run_s_median",
                                              "deliveries_median", "crash_rate_pct", "planet_unlock_h",
                                              "levels_share_pct")})
        for w in rep.get("warnings", []):
            if "nunca comprados" not in w:
                print("   AVISO:", w)
        print("   melhor distancia por mundo:", {k: round(v) for k, v in res.final["world_best"].items()})
        mk = [e for e in res.events if e["type"] == "marker"]
        life = res.final['lifetime']['credits']
        print(f"   marcos: {len(mk)} ({100*sum(e['value'] for e in mk)/life:.0f}% das moedas); runs {res.final['runs']}; runs por mundo {res.final['world_runs']}")
