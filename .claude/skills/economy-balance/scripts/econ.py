"""
econ.py - modelagem, simulacao e relatorio da economia do Incremental Lander.

Fonte unica da verdade: data/economy.json (lido pelo jogo no Godot E por este simulador).

Uso tipico (script em balance/sims/<nome>.py, rodando da raiz do projeto):

    import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
    from econ import *

    E = load("data/economy.json")
    res = simulate(E, PROFILES["engaged"], hours=30, seed=1)
    rep = pacing_report(E, res)                 # metricas + avisos contra os alvos
    write_report(E, [res], "balance/reports/v1") # markdown + graficos PNG
    print(fmt(1.234e15))                        # '1.23Qa'

Modelo de um run (o coracao do jogo):
  gas limitado -> cada entrega e um 'salto' balistico entre plataformas; o custo em delta-v depende
  da gravidade, distancia, aceleracao do motor e habilidade do piloto; o pagamento cresce com a
  distancia. O run termina quando o gas nao alcanca mais nenhuma entrega (ou quando o lander bate).
  Upgrades mudam os stats da nave; planetas mudam a fisica e o pagamento; prestigio reseta com bonus.
"""
from __future__ import annotations

import copy
import csv
import json
import math
import os
import random
import statistics as st
from dataclasses import dataclass, field
from typing import Any, Callable

# ---------------------------------------------------------------------------
# Carregar / salvar / acessar a spec
# ---------------------------------------------------------------------------

def load(path: str) -> dict:
    with open(path) as f:
        E = json.load(f)
    validate(E)
    return E


def save(E: dict, path: str) -> str:
    validate(E)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w") as f:
        json.dump(E, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return path


def get_path(E: dict, path: str) -> Any:
    """get_path(E, 'planets.1.gravity') ou 'upgrades.tank.cost.credits.growth' (ids resolvem listas)."""
    cur = E
    for part in path.split("."):
        cur = _step(cur, part)
    return cur


def set_path(E: dict, path: str, value: Any) -> dict:
    parts = path.split(".")
    cur = E
    for part in parts[:-1]:
        cur = _step(cur, part)
    last = parts[-1]
    if isinstance(cur, list):
        idx = _list_index(cur, last)
        cur[idx] = value
    else:
        cur[last] = value
    return E


def _list_index(lst: list, key: str) -> int:
    if key.isdigit():
        return int(key)
    for i, it in enumerate(lst):
        if isinstance(it, dict) and it.get("id") == key:
            return i
    raise KeyError(f"id {key!r} nao encontrado")


def _step(cur, part):
    if isinstance(cur, list):
        return cur[_list_index(cur, part)]
    return cur[part]


def validate(E: dict) -> None:
    """Checagens estruturais basicas (falha cedo com mensagem clara)."""
    for k in ("resources", "ship", "upgrades", "planets", "contracts", "targets"):
        if k not in E:
            raise ValueError(f"economy.json sem a chave obrigatoria '{k}'")
    res_ids = {r["id"] for r in E["resources"]}
    stats = set(E["ship"]["base"])
    for u in E["upgrades"]:
        for c in u["cost"]:
            if c not in res_ids:
                raise ValueError(f"upgrade {u['id']}: custo em recurso desconhecido '{c}'")
        if u["effect"]["stat"] not in stats:
            raise ValueError(f"upgrade {u['id']}: stat desconhecido '{u['effect']['stat']}'")
    shop_ids = {it["id"] for it in shop_items(E)}
    for it in shop_items(E):
        t = it["effect"]["type"]
        if t not in ("stat", "start_levels", "start_resources", "keep", "unlock"):
            raise ValueError(f"item da loja {it['id']}: effect.type desconhecido '{t}'")
        if t == "stat" and it["effect"]["stat"] not in stats:
            raise ValueError(f"item da loja {it['id']}: stat desconhecido '{it['effect']['stat']}'")
    up_ids = {u["id"] for u in E["upgrades"]}
    for x in E["upgrades"] + E["planets"]:
        for rid in x.get("requires_upgrade", {}):
            if rid not in up_ids:
                raise ValueError(f"{x['id']}: requires_upgrade '{rid}' nao existe")
    for u in E["upgrades"]:
        if u.get("requires_shop") and u["requires_shop"] not in shop_ids:
            raise ValueError(f"upgrade {u['id']}: requires_shop '{u['requires_shop']}' nao existe na loja")
    for p in E["planets"]:
        if p.get("requires_shop") and p["requires_shop"] not in shop_ids:
            raise ValueError(f"planeta {p['id']}: requires_shop '{p['requires_shop']}' nao existe na loja")
        for c in p.get("unlock", {}):
            if c not in res_ids:
                raise ValueError(f"planeta {p['id']}: desbloqueio em recurso desconhecido '{c}'")
        for c in p.get("rewards", {"credits": 1}):
            if c not in res_ids:
                raise ValueError(f"planeta {p['id']}: recompensa em recurso desconhecido '{c}'")


# ---------------------------------------------------------------------------
# Curvas (custos, efeitos, prestigio)
# ---------------------------------------------------------------------------

def cost_at(spec: dict, level: int) -> float:
    """Custo do PROXIMO nivel, estando em `level`.
    type: exp (base*growth^level, padrao idle 1.07-1.15), poly (base*(level+1)^growth),
    linear (base + growth*level)."""
    t = spec.get("type", "exp")
    b, g = spec["base"], spec["growth"]
    if t == "exp":
        return b * g ** level
    if t == "poly":
        return b * (level + 1) ** g
    if t == "linear":
        return b + g * level
    raise ValueError(f"tipo de custo desconhecido: {t}")


def bulk_cost(spec: dict, level: int, n: int) -> float:
    """Custo de comprar n niveis a partir de `level` (formula fechada para exp)."""
    if spec.get("type", "exp") == "exp" and spec["growth"] != 1:
        b, r = spec["base"], spec["growth"]
        return b * r ** level * (r ** n - 1) / (r - 1)
    return sum(cost_at(spec, level + i) for i in range(n))


def max_affordable(spec: dict, level: int, money: float) -> int:
    """Quantos niveis da pra comprar com `money` (formula fechada para exp)."""
    if spec.get("type", "exp") == "exp" and spec["growth"] != 1:
        b, r = spec["base"], spec["growth"]
        x = money * (r - 1) / (b * r ** level) + 1
        return max(0, int(math.floor(math.log(x) / math.log(r) + 1e-9)))
    n = 0
    while bulk_cost(spec, level, n + 1) <= money:
        n += 1
    return n


def effect_value(eff: dict, level: int) -> float:
    """Contribuicao de um upgrade no nivel `level`.
    op: add (value*level), mult (value^level), hyper (max*level/(level+k): retorno decrescente
    com teto), milestone (multiplica `value` a cada `every` niveis - estilo AdCap x2 em 25/50/100)."""
    op = eff["op"]
    if op == "add":
        return eff["value"] * level
    if op == "mult":
        return eff["value"] ** level
    if op == "hyper":
        return eff["max"] * level / (level + eff["k"])
    if op == "milestone":
        return eff["value"] ** (level // eff["every"])
    raise ValueError(f"op desconhecida: {op}")


def prestige_gain(spec: dict, earned: float) -> float:
    """Moeda de prestigio por ganhos. formula: sqrt (AdCap: dobrar pede 4x), cbrt (Cookie Clicker:
    8x), pow (expoente livre, Egg Inc ~0.14), log10."""
    x = max(0.0, earned / spec["scale"])
    f = spec.get("formula", "sqrt")
    if f == "sqrt":
        v = math.sqrt(x)
    elif f == "cbrt":
        v = x ** (1 / 3)
    elif f == "pow":
        v = x ** spec["exponent"]
    elif f == "log10":
        v = math.log10(x) if x >= 1 else 0.0
    else:
        raise ValueError(f)
    return math.floor(v * spec.get("mult", 1.0))


# ---------------------------------------------------------------------------
# Stats da nave
# ---------------------------------------------------------------------------

def shop_items(E: dict) -> list[dict]:
    return E.get("prestige", {}).get("shop", [])


def ship_stats(E: dict, levels: dict[str, int], prestige_points: float = 0.0,
               shop: dict[str, int] | None = None) -> dict[str, float]:
    """Stats finais = base -> + somas (add/hyper) -> x multiplicadores (mult/milestone) -> x prestigio.
    Itens da loja de prestigio com effect.type == 'stat' entram como upgrades comuns."""
    s = dict(E["ship"]["base"])
    adds: dict[str, float] = {}
    mults: dict[str, float] = {}
    sources = [(u, levels.get(u["id"], 0)) for u in E["upgrades"]]
    sources += [(it, (shop or {}).get(it["id"], 0)) for it in shop_items(E) if it["effect"]["type"] == "stat"]
    for u, lv in sources:
        if lv == 0:
            continue
        eff = u["effect"]
        v = effect_value(eff, lv)
        if eff["op"] in ("add", "hyper"):
            adds[eff["stat"]] = adds.get(eff["stat"], 0.0) + v
        else:
            mults[eff["stat"]] = mults.get(eff["stat"], 1.0) * v
    # marcos (AdCap/Guan): a cada `every` niveis de um upgrade, `stat` e multiplicado por `mult`
    for u in E["upgrades"]:
        lv = levels.get(u["id"], 0)
        for m in u.get("milestones", []):
            if lv >= m["every"]:
                mults[m["stat"]] = mults.get(m["stat"], 1.0) * m["mult"] ** (lv // m["every"])
    for k, v in adds.items():
        s[k] += v
    for k, v in mults.items():
        s[k] *= v
    P = E.get("prestige")
    if P and prestige_points:
        for b in P["bonuses"]:
            s[b["stat"]] *= 1 + b["per_point"] * prestige_points
    return s


# ---------------------------------------------------------------------------
# Perfis de jogador
# ---------------------------------------------------------------------------

@dataclass
class Profile:
    """Como o jogador joga. skill 0..1 afeta desperdicio de gas, qualidade do pouso e batidas."""
    name: str
    skill: float = 0.7            # media de qualidade de pouso (0..1)
    skill_sd: float = 0.12        # variacao entre pousos
    waste: float = 1.35           # multiplicador de delta-v (trajetoria imperfeita); 1.0 = perfeito
    hover_s: float = 1.5          # segundos pairando por pouso/decolagem (custa g*hover_s de delta-v)
    hop_overhead_s: float = 6.0   # tempo extra por entrega (mirar, alinhar, descarregar)
    run_overhead_s: float = 20.0  # tempo entre runs (loja, menu, preparar)
    strategy: str = "roi"         # roi | cheapest | random
    prestige_ratio: float = 1.0   # faz prestigio quando o ganho >= ratio * pontos atuais (e >= min)
    session_minutes: float = 0    # 0 = continuo; senao simula sessoes (so para relatorio)
    # Novato (2026-10-08, auditoria dos primeiros minutos): batida extra no comeco que cai com a pratica
    # (crash_extra x exp(-tentativas / learn_hops)) e a regra do APRENDIZ do jogo (world.json > onboarding):
    # enquanto fez menos de apprentice entregas, bater nao acaba o run - tenta o mesmo salto de novo (retry_s).
    crash_extra: float = 0.0
    learn_hops: float = 1.0
    retry_s: float = 0.0
    apprentice: int = 0
    guide_after: int = 0          # falhas seguidas no salto antes do "Veja como!" (piloto automatico entrega); 0 = nunca
    attempts: int = 0             # contadores do jogo todo (simulate zera numa copia do perfil)
    delivered: int = 0


PROFILES: dict[str, Profile] = {
    "casual":  Profile("casual", skill=0.55, waste=1.6, hover_s=2.5, hop_overhead_s=9, run_overhead_s=35,
                       prestige_ratio=1.5),
    "engaged": Profile("engaged", skill=0.72, waste=1.35, hover_s=1.5, hop_overhead_s=6, run_overhead_s=20),
    "expert":  Profile("expert", skill=0.9, skill_sd=0.06, waste=1.12, hover_s=0.7, hop_overhead_s=4,
                       run_overhead_s=10, prestige_ratio=0.7),
    # novato real (telemetria humana com a nave inicial: 23/35 voos bateram): ~65% de batida no 1o salto, cai pela
    # metade em ~17 tentativas; aprendiz = world.json onboarding.apprentice_stars (load_onboarding). Fora do screen/mc.
    "novice":  Profile("novice", skill=0.45, skill_sd=0.15, waste=1.8, hover_s=3.0, hop_overhead_s=12,
                       run_overhead_s=40, crash_extra=0.6, learn_hops=25.0, retry_s=8.0, apprentice=-1),
}


def load_onboarding(path: str = "data/world.json") -> dict:
    """Regras do comeco do jogo (world.json > onboarding; nao sao economia). {} se o arquivo nao existe."""
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f).get("onboarding", {})
    except OSError:
        return {}


def profile_from(E: dict, name: str) -> Profile:
    """Perfil padrao com overrides opcionais de E['profiles_override'][name] (calibrados por telemetria)."""
    p = copy.deepcopy(PROFILES[name])
    if p.apprentice < 0:                                       # aprendiz do jogo: mesmo numero do world.json
        p.apprentice = int(load_onboarding().get("apprentice_stars", 0))
        onb = load_onboarding()                                # "Veja como!" so se ligado (guide; desligado em 2026-10-08)
        p.guide_after = int(onb.get("retries_per_hop", 0)) + 1 if onb.get("guide", False) else 0
    for k, v in E.get("profiles_override", {}).get(name, {}).items():
        setattr(p, k, v)
    return p


# ---------------------------------------------------------------------------
# Fisica do salto (modelo do run)
# ---------------------------------------------------------------------------

def hop_dv(planet: dict, d: float, stats: dict, prof: Profile) -> float:
    """Delta-v para uma entrega de distancia d.
    Salto balistico otimo (45 graus): v0 = sqrt(g*d); acelerar + frear = 2*v0.
    Perda gravitacional durante as queimas ~ 0.707*g/a por queima (motor fraco gasta mais).
    Arrasto/vento do planeta e desperdicio do piloto multiplicam; pairar custa g*hover_s em cada ponta.
    Se a aceleracao nao vence a gravidade, e impossivel (inf)."""
    g = planet["gravity"]
    a = stats["thrust"]
    if a <= g * 1.05:
        return math.inf
    v0 = math.sqrt(g * d)
    dv = 2 * v0 * (1 + 0.707 * g / a)
    dv *= (1 + planet.get("drag", 0.0)) * prof.waste
    # perigos do mundo (v7: vento, calda, ventilador): custo extra de correcao, maior para quem pilota pior
    dv *= 1 + planet.get("hazard", {}).get("dv", 0.0) * (1 - min(prof.skill, 1.0)) * 2
    dv += 2 * g * prof.hover_s
    return dv


def hop_time(planet: dict, d: float, stats: dict, prof: Profile) -> float:
    g, a = planet["gravity"], stats["thrust"]
    v0 = math.sqrt(g * d)
    return math.sqrt(2) * v0 / g + 2 * v0 / a + prof.hop_overhead_s


def gas_for(E: dict, dv: float, stats: dict, gas_left: float, cargo_mass: float = 0.0) -> float:
    """Gas gasto para um delta-v. physics.mode:
      arcade - massa constante: gas = dv / efficiency  (efficiency = m/s por unidade de gas)
      rocket - Tsiolkovsky: m1 = m0*exp(-dv/ve), ve = efficiency; tanque maior pesa (retorno decrescente)."""
    mode = E.get("physics", {}).get("mode", "arcade")
    eff = stats["efficiency"]
    if mode == "arcade":
        return dv / eff
    gm = E["physics"].get("gas_mass", 0.01)
    m0 = stats["dry_mass"] + cargo_mass + gas_left * gm
    m1 = m0 * math.exp(-dv / eff)
    return (m0 - m1) / gm


def crash_prob(planet: dict, stats: dict, quality: float) -> float:
    base = planet.get("crash_base", 0.02) + planet.get("hazard", {}).get("crash", 0.0)
    return min(0.95, base * (1 - quality) * 2 / max(stats.get("gear", 1.0), 1e-6))


def contract_pay(E: dict, planet: dict, d: float, stats: dict) -> float:
    C = E["contracts"]
    return C["pay_base"] * (d / C.get("distance_unit", 100.0)) ** C["distance_exp"] * planet.get("pay_mult", 1.0) \
        * stats.get("pay_mult", 1.0)


# --- Variedade das entregas (v7): plataformas com multiplicador (cristais sairam na v9) ---
# v14: Reputacao POR RATINHO (contracts.reputation): pontos permanentes por tipo de missao (missao cumprida = points_ok,
# com pouso perfeito = points_perfect; falhou/bateu = 0); niveis (levels[i].points) dao +bonus nos pedidos DAQUELE
# ratinho. Espelho GDScript: EconMath.pad_tier / reputation_* / delivery_pay. Spec sem as chaves = v6 intacta.

def pad_tier(E: dict, tier_id: str) -> dict:
    """Tipo de plataforma (contracts.pad_tiers): mult (pagamento), weight (chance na oferta),
    q_drop (perda de qualidade de um piloto mediano), crash_mult. Sem tipos -> plataforma normal x1."""
    for t in E["contracts"].get("pad_tiers", []):
        if t["id"] == tier_id:
            return t
    return {"id": "normal", "mult": 1.0, "weight": 1.0, "q_drop": 0.0, "crash_mult": 1.0}


def reputation_level(E: dict, points: float) -> int:
    """Nivel de reputacao (0..len(levels)) de um ratinho com `points` pontos acumulados."""
    r = E["contracts"].get("reputation") or {}
    return sum(1 for lv in r.get("levels", []) if points >= lv["points"])


def reputation_mult(E: dict, level: int) -> float:
    """Multiplicador do pagamento dos pedidos de um ratinho no nivel `level` (0 = x1)."""
    r = E["contracts"].get("reputation") or {}
    lvs = r.get("levels", [])
    return 1.0 if level <= 0 or not lvs else 1.0 + lvs[min(level, len(lvs)) - 1]["bonus"]


def reputation_points(E: dict, ok: bool, perfect: bool) -> int:
    """Pontos que uma entrega da ao ratinho: missao cumprida (+ pouso perfeito vale mais); falhou/bateu = 0."""
    r = E["contracts"].get("reputation") or {}
    if not ok:
        return 0
    return int(r.get("points_perfect", 2) if perfect else r.get("points_ok", 1))


def delivery_pay(E: dict, planet: dict, d: float, stats: dict, q: float, tier_id: str = "normal",
                 rep: int = 0, mission_m: float = 1.0) -> float:
    """Pagamento de uma entrega concluida: base x qualidade x plataforma x reputacao x carga (o jogo usa a mesma
    conta; mission_m = mission_mult(missao, falhas))."""
    C = E["contracts"]
    q = min(1.0, max(0.0, q))
    return contract_pay(E, planet, d, stats) * (1 + C.get("quality_bonus", 0.5) * q ** C.get("quality_exp", 1.0)) \
        * pad_tier(E, tier_id)["mult"] * reputation_mult(E, rep) * mission_m


# Missoes (v12, so nos planetas de contracts.missions.planets). Espelho GDScript: EconMath.mission_*.
# A missao e uma REGRA (Simples, Pesada, Pouso suave, Rapida, Passageiro, Cabo, Dupla) com estrelas 1..3; oferta =
# {"kind", "star", "parts": [{"kind", "star"}...]} (Simples: parts vazio; Dupla: 2 partes). Cumpriu -> mult da
# estrela; falhou -> x fail_mult (nunca acaba o run). Liberacao: estrelas (1 por entrega) compram nos da arvore.
_SIMPLE = {"id": "simple", "name": "Simples", "weight": 1.0, "levels": [{"mult": 1.0}]}


def mission_spec(E: dict) -> dict:
    return E["contracts"].get("missions") or {}


def mission_kinds(E: dict, planet_id: str) -> list[dict]:
    ms = mission_spec(E)
    if not ms or planet_id not in ms.get("planets", []):
        return []
    sig = next((p.get("mission") for p in E["planets"] if p["id"] == planet_id), None)
    if sig:                                               # v17: so o pedido-assinatura do mundo
        return [k for k in ms["kinds"] if k["id"] == sig]
    return ms["kinds"]


def mission_kind(E: dict, kind_id: str) -> dict:
    for k in mission_spec(E).get("kinds", []):
        if k["id"] == kind_id:
            return k
    return _SIMPLE


def mission_level(E: dict, kind_id: str, star: int) -> dict:
    lv = mission_kind(E, kind_id)["levels"]
    return lv[max(0, min(int(star), len(lv)) - 1)]


def fail_pay(level: dict, partial: float = 0.0) -> float:
    """v18: fator de pagamento de uma regra que falhou, com credito parcial: fail_mult + (1 - fail_mult) x parte
    cumprida (0..1; ex.: 3 de 5 carneirinhos = 0,6). partial 0 = o fail_mult de sempre (tudo-ou-nada)."""
    fm = level.get("fail_mult", 1.0)
    return fm + (1.0 - fm) * min(1.0, max(0.0, partial))


def mission_mult(E: dict, mission: dict, failed: tuple | list | set = (), partial: dict | None = None) -> float:
    """Multiplicador de pagamento. failed = kinds das partes cuja regra falhou; partial = {kind: parte cumprida}
    (v18: credito parcial do minijogo do mundo)."""
    parts = mission.get("parts", [])
    if not parts:
        return 1.0
    fail = 1.0
    for p in parts:
        if p["kind"] in failed:
            fail *= fail_pay(mission_level(E, p["kind"], p["star"]), (partial or {}).get(p["kind"], 0.0))
    if mission["kind"] == "double":
        mx = mission_spec(E).get("double", {}).get("max_mult", 3.0)
        m = min(mx, 1.0 + sum(mission_level(E, p["kind"], p["star"])["mult"] - 1.0 for p in parts))
    else:
        m = mission_level(E, parts[0]["kind"], parts[0]["star"])["mult"]
    return m * fail


def mission_thrust_div(E: dict, mission: dict) -> float:
    """Pesada: o motor rende thrust / thrust_div (a nave fica mais pesada)."""
    d = 1.0
    for p in mission.get("parts", []):
        d *= mission_level(E, p["kind"], p["star"]).get("thrust_div", 1.0)
    return d


def mission_dv_mult(E: dict, mission: dict) -> float:
    """Cabo: o pendulo custa um pouco mais de delta-v."""
    m = 1.0
    for p in mission.get("parts", []):
        m *= mission_level(E, p["kind"], p["star"]).get("dv_mult", 1.0)
    return m


def mission_leg2(E: dict, mission: dict) -> float:
    """Taxi (Passageiro 2-3): o 2o trecho tem leg2 x a distancia da oferta (0 = sem 2o trecho)."""
    if mission.get("kind") != "passenger":
        return 0.0
    return mission_level(E, "passenger", mission["parts"][0]["star"]).get("leg2", 0.0)


def mission_fail_p(level: dict, skill: float) -> float:
    """Chance de falhar a regra: fail_p x (1 - skill) x 2 (mesmo idioma do q_drop; expert quase nunca)."""
    return min(1.0, max(0.0, level.get("fail_p", 0.0) * (1 - min(skill, 1.0)) * 2))


def node_ok(E: dict, node: dict, owned: set) -> bool:
    """O no da arvore pode ser liberado? (requires = todos; requires_any = {n, of})."""
    if node["id"] in owned:
        return False
    if any(r not in owned for r in node.get("requires", [])):
        return False
    ra = node.get("requires_any")
    return not ra or sum(1 for r in ra["of"] if r in owned) >= ra["n"]


def missions_unlocked(E: dict, owned: set) -> dict[str, int]:
    """{kind: maior estrela liberada}; a Simples sempre vem."""
    out = {"simple": 1}
    for n in mission_spec(E).get("nodes", []):
        if n["id"] in owned:
            out[n["kind"]] = max(out.get(n["kind"], 0), n["star"])
    return out


def takeoff_twr(planet: dict, kind: str, star: int) -> float:
    """v18: folga minima de empuxo (motor / divisor > g x isto) para o pedido-assinatura do mundo aparecer nessa
    estrela (planets[].takeoff_twr, numero ou lista por estrela); outros pedidos: 1,05 (so precisa decolar)."""
    t = planet.get("takeoff_twr")
    if t is None or kind != planet.get("mission"):
        return 1.05
    return t[max(1, min(int(star), len(t))) - 1] if isinstance(t, list) else t


def mission_bonus_at(planet: dict, star: int = 1) -> float:
    """v18: bonus do minijogo do mundo na estrela (planets[].mission_bonus, numero ou lista por estrela)."""
    b = planet.get("mission_bonus", 0.0)
    return b[max(1, min(int(star), len(b))) - 1] if isinstance(b, list) else b


def _partial_model(planet: dict, kind: str) -> float:
    """v18: parte media cumprida quando a regra falha (credito parcial do minijogo; so o pedido do mundo)."""
    return planet.get("partial_frac_model", 0.0) if kind == planet.get("mission") else 0.0


def _heavy_factor(planet: dict, stats: dict, div: float, twr: float = 1.05) -> float:
    """Quanto o delta-v sobe com o motor dividido (perda gravitacional maior); inf se nao decola (ou se a folga
    de empuxo for menor que twr)."""
    g, a = planet["gravity"], stats["thrust"]
    if a / div <= g * twr:
        return math.inf
    return (1 + 0.707 * g / (a / div)) / (1 + 0.707 * g / a)


def mission_expect(E: dict, planet: dict, prof: Profile, stats: dict, unlocked: dict | None,
                   boost: dict | None = None) -> tuple[float, float, float]:
    """(pagamento medio, delta-v medio, tempo medio) das missoes liberadas, como multiplicadores do salto base.
    O modelo nao escolhe missao (media ponderada dos sorteios; estrela uniforme entre as liberadas).
    Taxi: paga os 2 trechos (1 + leg2^1.1) e gasta/demora 1 + sqrt(leg2). Dupla: 2 partes medias."""
    kinds = mission_kinds(E, planet["id"])
    if not kinds or not unlocked:
        return 1.0, 1.0, 1.0

    def single(kid, star):
        lv = mission_level(E, kid, star)
        pf = mission_fail_p(lv, prof.skill)
        pay = lv["mult"] * ((1 - pf) + pf * fail_pay(lv, _partial_model(planet, kid)))
        dv = lv.get("dv_mult", 1.0) * _heavy_factor(planet, stats, lv.get("thrust_div", 1.0),
                                                    takeoff_twr(planet, kid, star))
        leg = lv.get("leg2", 0.0)
        return pay * (1 + leg ** 1.1), dv * (1 + math.sqrt(leg)), 1 + math.sqrt(leg), lv, pf

    ms = mission_spec(E)
    rows = []
    for k in kinds:
        top = unlocked.get(k["id"], 0)
        if top <= 0:
            continue
        w = k.get("weight", 1.0) * ((boost or {}).get(k["id"], 0) > 0 and ms.get("new_boost", {}).get("weight_mult", 1.0) or 1.0)
        if k["id"] == "double":
            dbl = ms.get("double", {})
            parts = []
            for pk in dbl.get("parts_from", []):
                top_p = unlocked.get(pk, 0)
                if pk == "passenger":
                    top_p = min(top_p, dbl.get("passenger_max_star", 1))
                for s in range(1, top_p + 1):
                    _, dv, _, lv, pf = single(pk, s)
                    if math.isfinite(dv):
                        parts.append((lv["mult"] - 1, (1 - pf) + pf * lv.get("fail_mult", 1.0), dv))
            if len(parts) < 2:
                continue
            em = sum(x[0] for x in parts) / len(parts)
            ef = sum(x[1] for x in parts) / len(parts)
            ed = sum(x[2] for x in parts) / len(parts)
            rows.append((w, min(dbl.get("max_mult", 3.0), 1 + 2 * em) * ef * ef, ed * ed, 1.0))
            continue
        per = []
        for s in range(1, top + 1):
            pay, dv, tm, _, _ = single(k["id"], s)
            if math.isfinite(dv):
                per.append((pay, dv, tm))
        if per:
            n = len(per)
            rows.append((w, sum(x[0] for x in per) / n, sum(x[1] for x in per) / n, sum(x[2] for x in per) / n))
    tw = sum(r[0] for r in rows) or 1.0
    return (sum(r[0] * r[1] for r in rows) / tw, sum(r[0] * r[2] for r in rows) / tw,
            sum(r[0] * r[3] for r in rows) / tw)


# --- Presentes no alto do morro (v10): encostar devagar pega gas ou creditos ---
# Espelho GDScript: EconMath.gift_kinds / gift_value / gift_gas. Spec sem contracts.gifts = v9 intacta.

def gift_kinds(E: dict, planet_id: str) -> list:
    """Tipos de presente do planeta (contracts.gifts.kinds); [] se o planeta nao tem presentes."""
    G = E["contracts"].get("gifts")
    if not G or planet_id not in G.get("planets", [planet_id]):
        return []
    return G["kinds"]


def gift_value(E: dict, planet: dict, d: float, stats: dict, kind: dict) -> float:
    """Creditos de um presente pego no salto de distancia d: pay_frac x pagamento-base da entrega."""
    return kind.get("pay_frac", 0.0) * contract_pay(E, planet, d, stats)


def minigame_pay(E: dict, planet: dict, d: float, stats: dict, frac: float, star: int = 1) -> float:
    """v17: bonus do minijogo do mundo (planets[].mission_bonus x pagamento-base) pela fracao cumprida (0..1);
    v18: o bonus pode ser uma lista por estrela (Lua: a estrela maior vale pelos queijinhos)."""
    return mission_bonus_at(planet, star) * contract_pay(E, planet, d, stats) * min(1.0, max(0.0, frac))


def gift_gas(stats: dict, kind: dict) -> float:
    """Gas devolvido por um presente: gas_frac x tanque (o jogo nao passa do tanque cheio)."""
    return kind.get("gas_frac", 0.0) * stats["tank"]


def gift_expect(E: dict, planet: dict, prof: Profile) -> tuple[float, float, float]:
    """(fracao media do pagamento-base, fracao media do tanque, delta-v extra relativo) por salto, para o perfil.
    Pega o presente com chance = skill (encostar devagar no alto do morro); tentar custa dv_extra do salto."""
    kinds = gift_kinds(E, planet["id"])
    if not kinds:
        return 0.0, 0.0, 0.0
    G = E["contracts"]["gifts"]
    tw = sum(k["weight"] for k in kinds)
    pick = G["chance"] * min(1.0, prof.skill)
    pay = sum(k["weight"] * k.get("pay_frac", 0.0) for k in kinds) / tw
    gas = sum(k["weight"] * k.get("gas_frac", 0.0) for k in kinds) / tw
    return pick * pay, pick * gas, G["chance"] * G.get("dv_extra", 0.0)


def _draw_tier(E: dict, rng: random.Random) -> str:
    tiers = E["contracts"].get("pad_tiers")
    if not tiers:
        return "normal"
    r = rng.random() * sum(t["weight"] for t in tiers)
    for t in tiers:
        r -= t["weight"]
        if r <= 0:
            return t["id"]
    return tiers[-1]["id"]


def _q_on_tier(q: float, tier: dict, skill: float) -> float:
    """Plataforma estreita derruba a qualidade de quem pilota pior (expert quase nao sente)."""
    return min(1.0, max(0.0, q - tier.get("q_drop", 0.0) * (1 - skill) * 2))


def _p_good(prof: Profile, tier: dict, q_min: float) -> float:
    """Chance de um pouso ser perfeito para a Reputacao (q >= q_min), com q ~ Normal(skill, skill_sd)."""
    mu = _q_on_tier(prof.skill, tier, prof.skill)
    sd = max(prof.skill_sd, 1e-6)
    return 0.5 * (1 - math.erf((q_min - mu) / (sd * math.sqrt(2))))


def contracts_for(E: dict, planet: dict, rng: random.Random) -> list[float]:
    """Distancias ofertadas no run (log-uniforme entre min e max do planeta)."""
    C = E["contracts"]
    n = planet.get("contracts_per_run", C.get("per_run", 8))
    lo, hi = planet["distance"]
    return sorted(math.exp(rng.uniform(math.log(lo), math.log(hi))) for _ in range(n))


@dataclass
class RunResult:
    rewards: dict[str, float]
    time_s: float
    deliveries: int
    max_distance: float
    total_distance: float
    crashed: bool
    gas_left_pct: float


_STREAM_CACHE: dict = {}


def _offer_stream(E: dict, planet: dict, seed: int, extra: int = 256) -> tuple[list[float], list[float]]:
    """Ofertas iniciais (ordenadas) + distancias das ofertas regeneradas, na mesma ordem de sorteio que
    do_run faria com random.Random(seed). Runs 'esperados' so sorteiam distancias, entao reusar a
    sequencia da resultado identico e evita re-sortear centenas de milhares de vezes."""
    lo, hi = planet["distance"]
    n = planet.get("contracts_per_run", E["contracts"].get("per_run", 8))
    key = (id(E), planet["id"], seed, n, lo, hi, json.dumps(E["contracts"].get("pad_tiers"), sort_keys=True))
    st_ = _STREAM_CACHE.get(key)
    if st_ is None:
        rng = random.Random(seed)
        first = sorted(math.exp(rng.uniform(math.log(lo), math.log(hi))) for _ in range(n))
        more = [math.exp(rng.uniform(math.log(lo), math.log(hi))) for _ in range(extra)]
        trng = random.Random(seed * 7919 + 1)               # tipos de plataforma: sequencia propria
        tiers = [_draw_tier(E, trng) for _ in range(n + extra)]
        st_ = _STREAM_CACHE[key] = (first, more, tiers[:n], tiers[n:])
    return st_


def do_run(E: dict, planet: dict, stats: dict, prof: Profile, rng: random.Random, expected: bool = False,
           stream: tuple | None = None, log: list | None = None, missions: dict | None = None,
           boost: dict | None = None, rep: dict | None = None) -> RunResult:
    """Simula um run. Estrategia do piloto: dentre as entregas alcancaveis com o gas restante,
    pega a de maior pagamento esperado por gas (plataforma dificil paga mais, mas derruba a qualidade e
    aumenta a batida de quem pilota pior). Reputacao (v14): rep = {tipo: nivel} multiplica os pedidos de cada ratinho.
    expected=True usa valores medios (sem sorte) - para ROI. stream (so com expected) = ofertas
    pre-sorteadas (_offer_stream). log (opcional) recebe (distancia, tipo, q, combo) de cada entrega feita.
    missions = {kind: estrela} liberadas (v12; None = so Simples); boost = {kind: runs} recem-liberados."""
    if mission_kinds(E, planet["id"]):
        return _do_run_missions(E, planet, stats, prof, rng, expected, stream, log, missions, rep)
    gas = stats["tank"]
    C = E["contracts"]
    has_tiers = bool(C.get("pad_tiers"))
    if stream:
        offers = list(stream[0])
        tiers0 = list(stream[2])
    else:
        offers = contracts_for(E, planet, rng)
        tiers0 = [_draw_tier(E, rng) if has_tiers else "normal" for _ in offers]
    more_i = 0
    rewards_w = planet.get("rewards", {"credits": 1.0})
    total = {k: 0.0 for k in rewards_w}
    t = 0.0
    n = 0
    maxd = 0.0
    dist = 0.0
    crashed = False
    qbonus = C.get("quality_bonus", 0.5)
    qexp = C.get("quality_exp", 1.0)          # >1 = precisao alta vale desproporcionalmente mais
    regenerate = C.get("regenerate", False)   # nova oferta aparece apos cada entrega (gas vira o limite)
    max_per_run = C.get("max_per_run", 10 ** 9)
    lo_d, hi_d = planet["distance"]
    log_lo, log_hi = math.log(lo_d), math.log(hi_d)
    cargo = C.get("cargo_mass", 0.0)
    arcade = E.get("physics", {}).get("mode", "arcade") == "arcade"
    eff = stats["efficiency"]
    cg_pay, cg_dv, cg_t = mission_expect(E, planet, prof, stats, missions, boost)
    gf_pay, gf_gas, gf_dv = gift_expect(E, planet, prof)
    cg_dv *= 1.0 + gf_dv                      # buscar o presente custa um pouco de gas

    def info(d, tid):  # custo, pagamento e chances de uma oferta nao mudam durante o run: calcula uma vez so
        tier = pad_tier(E, tid)
        dv = hop_dv(planet, d, stats, prof) * cg_dv
        q_mu = _q_on_tier(prof.skill, tier, prof.skill)
        pc_mu = min(0.95, crash_prob(planet, stats, q_mu) * tier.get("crash_mult", 1.0))
        base = contract_pay(E, planet, d, stats)
        # valor esperado (para a escolha do piloto): qualidade media, plataforma e chance de bater
        ev = base * ((1 + qbonus * q_mu ** qexp) * tier["mult"] * cg_pay) * (1 - pc_mu)
        return (d, dv / eff if arcade else dv, base, tier, ev)

    items = [info(d, tid) for d, tid in zip(offers, tiers0)]
    while items and n < max_per_run:
        bi, best_score, best_gas = -1, 0.0, 0.0
        for i, it in enumerate(items):
            g_or_dv = it[1]
            g_need = g_or_dv if arcade else gas_for(E, g_or_dv, stats, gas, cargo)  # rocket: depende da massa
            if g_need <= gas:
                score = it[4] / max(g_need, 1e-9)
                if score > best_score:
                    bi, best_score, best_gas = i, score, g_need
        if bi < 0:
            break
        best, _, base, tier, _ = items.pop(bi)
        if regenerate:
            if stream and more_i < len(stream[1]):
                items.append(info(stream[1][more_i], stream[3][more_i]))
                more_i += 1
            else:
                nd = math.exp(rng.uniform(log_lo, log_hi))
                items.append(info(nd, _draw_tier(E, rng) if has_tiers else "normal"))
        gas -= best_gas
        q = prof.skill if expected else min(1.0, max(0.0, rng.gauss(prof.skill, prof.skill_sd)))
        q = _q_on_tier(q, tier, prof.skill)
        cm = 1.0
        pay = base * ((1 + qbonus * q ** qexp) * tier["mult"] * cg_pay + gf_pay)
        pc = min(0.95, crash_prob(planet, stats, q) * tier.get("crash_mult", 1.0))
        t += hop_time(planet, best, stats, prof) * cg_t
        if expected:
            pay *= (1 - pc)
        elif rng.random() < pc:
            crashed = True
            break
        if log is not None:
            log.append((best, tier["id"], q, cm))
        for k, w in rewards_w.items():
            total[k] += pay * w
        n += 1
        gas = min(stats["tank"], gas + gf_gas * stats["tank"])
        maxd = max(maxd, best)
        dist += best
    t += prof.run_overhead_s
    return RunResult(total, t, n, maxd, dist, crashed, 100 * gas / stats["tank"])


def slot_kind(slot: str) -> str:
    """Tipo de missao de um espaco ('simple0' / 'passenger2' -> tira o numero da faixa)."""
    return slot.rstrip("0123456789")


def mission_slots(E: dict, unlocked: dict | None, planet: dict | None = None) -> list[str]:
    """Espacos de pedido do run (v12.1): a Simples tem simple_offers faixas de distancia (perto -> longe) e cada outro
    tipo liberado tem 1 pedido (um por ratinho). Entregou -> o mesmo espaco ganha um pedido novo.
    v17 (minijogos): planeta com `mission` = so o pedido-assinatura daquele mundo, em simple_offers faixas."""
    ms = mission_spec(E)
    n = ms.get("simple_offers", 3)
    if planet and planet.get("mission"):
        return [f"{planet['mission']}{i}" for i in range(n)]
    out = [f"simple{i}" for i in range(n)]
    for k in ms.get("kinds", []):
        if k["id"] != "simple" and (unlocked or {}).get(k["id"], 0) > 0:
            out.append(k["id"])
    return out


def slot_distance(E: dict, planet: dict, slot: str, u: float) -> float:
    """Distancia de um espaco a partir de u em [0,1): Simples i = faixa i de simple_offers (em log); outros = faixa toda."""
    lo, hi = (math.log(x) for x in planet["distance"])
    if slot[-1:].isdigit():
        n = mission_spec(E).get("simple_offers", 3)
        i = int(slot[len(slot_kind(slot)):])
        return math.exp(lo + (hi - lo) * (i + u) / n)
    return math.exp(lo + (hi - lo) * u)


def _mission_choices(E: dict, planet: dict, stats: dict, prof: Profile, kind: str, unlocked: dict) -> list[dict]:
    """Opcoes que o jogador pode escolher no cartao para um tipo: (estrela, pagamento esperado x, falha, delta-v x,
    tempo x). Dupla: uma opcao media (partes = maior estrela que voa de cada regra)."""
    ms = mission_spec(E)
    out = []
    if kind == "double":
        dbl = ms.get("double", {})
        parts = []
        for pk in dbl.get("parts_from", []):
            top = unlocked.get(pk, 0)
            if pk == "passenger":
                top = min(top, dbl.get("passenger_max_star", 1))
            for s_ in range(top, 0, -1):
                lv = mission_level(E, pk, s_)
                hf = _heavy_factor(planet, stats, lv.get("thrust_div", 1.0))
                if math.isfinite(hf):
                    pf = mission_fail_p(lv, prof.skill)
                    parts.append((lv["mult"] - 1, (1 - pf) + pf * lv.get("fail_mult", 1.0), lv.get("dv_mult", 1.0) * hf))
                    break
        if len(parts) >= 2:
            em = sum(x[0] for x in parts) / len(parts)
            ef = sum(x[1] for x in parts) / len(parts)
            ed = sum(x[2] for x in parts) / len(parts)
            out.append({"star": 1, "pay": min(dbl.get("max_mult", 3.0), 1 + 2 * em) * ef * ef, "dv": ed * ed, "t": 1.0})
        return out
    for s_ in range(1, max(1, unlocked.get(kind, 1)) + 1):
        lv = mission_level(E, kind, s_)
        hf = _heavy_factor(planet, stats, lv.get("thrust_div", 1.0), takeoff_twr(planet, kind, s_))
        if not math.isfinite(hf):
            continue
        pf = mission_fail_p(lv, prof.skill)
        leg = lv.get("leg2", 0.0)
        bonus = mission_bonus_at(planet, s_) * min(1.0, prof.skill) if kind == planet.get("mission") else 0.0
        out.append({"star": s_, "pay": lv["mult"] * ((1 - pf) + pf * fail_pay(lv, _partial_model(planet, kind)))
                    * (1 + leg ** 1.1), "dv": lv.get("dv_mult", 1.0) * hf * (1 + math.sqrt(leg)),
                    "t": 1 + math.sqrt(leg), "bonus": bonus})
    return out


def run_fatigue_mult(E: dict, n: int) -> float:
    """v15: multiplicador do gas do salto depois de n entregas no run (contracts.run_fatigue ^ n; 1 = sem cansaco).
    Com tanque T e custo c, o maximo de entregas e ~ log(1 + T(k-1)/c) / log k: cresce com a nave, mas e finito."""
    return E["contracts"].get("run_fatigue", 1.0) ** n


CRASH_RISK_K = 3.0      # escolha de plataforma/estrela: (1 - chance de bater)^K (bater perde o resto do run)


def _do_run_missions(E: dict, planet: dict, stats: dict, prof: Profile, rng: random.Random | None, expected: bool,
                     stream: tuple | None, log: list | None, missions: dict | None,
                     rep: dict | None = None) -> RunResult:
    """Run com missoes (v12.1): um pedido por espaco (3 da Simples + 1 por ratinho liberado); o jogador escolhe no
    cartao o tamanho da plataforma e a estrela -> o modelo escolhe a combinacao de maior valor esperado por gas."""
    unlocked = missions or {"simple": 1}
    C = E["contracts"]
    gas = stats["tank"]
    eff = stats["efficiency"]
    qbonus = C.get("quality_bonus", 0.5)
    qexp = C.get("quality_exp", 1.0)
    max_per_run = min(C.get("max_per_run", 10 ** 9), 1000)   # 1000 = trava de seguranca do modelo (v15: sem teto)
    tiers = C.get("pad_tiers") or [{"id": "normal", "mult": 1.0}]
    gf_pay, gf_gas, gf_dv = gift_expect(E, planet, prof)
    rewards_w = planet.get("rewards", {"credits": 1.0})
    total = {k: 0.0 for k in rewards_w}
    slots = mission_slots(E, unlocked, planet)
    if planet.get("mission"):
        unlocked = dict(unlocked)
        unlocked[planet["mission"]] = max(1, unlocked.get(planet["mission"], 0))
    choices = {sl: _mission_choices(E, planet, stats, prof, slot_kind(sl), unlocked)
               for sl in slots}
    us = list(stream[0]) + list(stream[1]) if stream else None
    lo, hi = (math.log(x) for x in planet["distance"])
    ui = 0

    def next_u():
        nonlocal ui
        if us is not None:
            d = us[ui % len(us)]
            ui += 1
            return (math.log(d) - lo) / (hi - lo)
        return rng.random()

    def info(sl, d):  # melhor (plataforma x estrela) do pedido: valor esperado por gas
        base = contract_pay(E, planet, d, stats)
        best = None
        for ch in choices[sl]:
            for tier in tiers:
                dv = hop_dv(planet, d, stats, prof) * ch["dv"] * (1.0 + gf_dv)
                g_need = dv / eff
                q_mu = _q_on_tier(prof.skill, tier, prof.skill)
                pc = min(0.95, crash_prob(planet, stats, q_mu) * tier.get("crash_mult", 1.0))
                # bater acaba o run: o jogador pesa tambem as entregas que perderia (~CRASH_RISK_K entregas)
                ev = base * ((1 + qbonus * q_mu ** qexp) * tier["mult"] * ch["pay"] + ch.get("bonus", 0.0)) \
                    * (1 - pc) ** CRASH_RISK_K
                if best is None or ev / g_need > best[0]:
                    best = (ev / g_need, g_need, tier, ch)
        return best and (d, best[1], base, best[2], best[3])

    items = {sl: info(sl, slot_distance(E, planet, sl, next_u())) for sl in slots}
    t = 0.0
    n = 0
    maxd = dist = 0.0
    crashed = False
    fails = 0                                                  # aprendiz: batidas seguidas no salto atual
    while n < max_per_run:
        pick, best_score = None, 0.0
        fat = run_fatigue_mult(E, n)
        for sl, it in items.items():
            if it and it[1] * fat <= gas:
                score = it[2] * (it[3]["mult"] * it[4]["pay"] + it[4].get("bonus", 0.0)) / it[1]
                if score > best_score:
                    pick, best_score = sl, score
        if pick is None:
            break
        d, g_need, base, tier, ch = items[pick]
        items[pick] = info(pick, slot_distance(E, planet, pick, next_u())) if C.get("regenerate", True) else None
        gas -= g_need * fat
        q = prof.skill if expected else min(1.0, max(0.0, rng.gauss(prof.skill, prof.skill_sd)))
        q = _q_on_tier(q, tier, prof.skill)
        cm = reputation_mult(E, (rep or {}).get(slot_kind(pick), 0))
        pay = base * ((1 + qbonus * q ** qexp) * tier["mult"] * cm * ch["pay"] + gf_pay + ch.get("bonus", 0.0))
        pc = min(0.95, crash_prob(planet, stats, q) * tier.get("crash_mult", 1.0))
        t += hop_time(planet, d, stats, prof) * ch["t"]
        if expected:
            pay *= (1 - pc)
        else:
            if prof.crash_extra > 0:                           # novato: bate mais no comeco, aprende tentando
                pc = min(0.95, pc + prof.crash_extra * math.exp(-prof.attempts / prof.learn_hops))
                prof.attempts += 1
            guided = prof.guide_after > 0 and fails >= prof.guide_after
            if not guided and rng.random() < pc:
                if prof.delivered < prof.apprentice:           # aprendiz: o mesmo salto de novo, com o gas dele
                    gas += g_need * fat
                    t += prof.retry_s                  # (modelo: re-escolhe o pedido; o jogo repete o mesmo)
                    fails += 1
                    continue
                crashed = True
                break
            fails = 0                                          # "Veja como!": o piloto automatico entrega (paga igual)
            prof.delivered += 1
        if log is not None:
            log.append((d, tier["id"], q, cm, pick, ch["star"]))
        for k, w in rewards_w.items():
            total[k] += pay * w
        n += 1
        gas = min(stats["tank"], gas + gf_gas * stats["tank"] / fat)   # galao encolhe com o cansaco
        maxd = max(maxd, d)
        dist += d
    t += prof.run_overhead_s
    return RunResult(total, t, n, maxd, dist, crashed, 100 * gas / stats["tank"])


_INCOME_CACHE: dict = {}


def expected_income(E: dict, planet: dict, stats: dict, prof: Profile, samples: int = 4, seed: int = 999,
                    missions: dict | None = None) -> dict:
    """Renda media por segundo (por recurso) usando runs 'esperados' com ofertas fixas por seed.
    Memoizado por (spec, planeta, stats, perfil, missoes) - o simulador reavalia os mesmos estados muitas vezes."""
    key = (id(E), planet["id"], tuple(sorted((k, round(v, 9)) for k, v in stats.items())),
           tuple(sorted(vars(prof).items())), samples, seed, tuple(sorted((missions or {}).items())))
    if key in _INCOME_CACHE:
        return _INCOME_CACHE[key]
    out = _expected_income(E, planet, stats, prof, samples, seed, missions)
    if len(_INCOME_CACHE) > 200000:
        _INCOME_CACHE.clear()
    _INCOME_CACHE[key] = out
    return out


def _expected_income(E: dict, planet: dict, stats: dict, prof: Profile, samples: int, seed: int,
                     missions: dict | None = None) -> dict:
    tot: dict[str, float] = {}
    tt = 0.0
    for i in range(samples):
        r = do_run(E, planet, stats, prof, None, expected=True, stream=_offer_stream(E, planet, seed + i),
                   missions=missions)
        for k, v in r.rewards.items():
            tot[k] = tot.get(k, 0.0) + v
        tt += r.time_s
    return {k: v / tt for k, v in tot.items()}


# ---------------------------------------------------------------------------
# Simulacao do jogador ao longo de horas
# ---------------------------------------------------------------------------

@dataclass
class SimResult:
    profile: str
    seed: int
    events: list[dict] = field(default_factory=list)     # compras, desbloqueios, prestigios
    samples: list[dict] = field(default_factory=list)    # serie temporal por run
    finished_at_h: float | None = None
    final: dict = field(default_factory=dict)


def _value(E: dict, rewards_per_s: dict[str, float]) -> float:
    """Converte renda multi-recurso num valor escalar (pesos em E['resource_value'])."""
    w = E.get("resource_value", {})
    return sum(v * w.get(k, 1.0) for k, v in rewards_per_s.items())


def _affordable(cost: dict[str, float], money: dict[str, float]) -> bool:
    return all(money.get(k, 0.0) >= v for k, v in cost.items())


def _upgrade_cost(u: dict, lv: int) -> dict[str, float]:
    return {k: cost_at(spec, lv) for k, spec in u["cost"].items()}


def _requires_ok(x: dict, levels: dict[str, int] | None) -> bool:
    """requires_upgrade = {id: nivel_minimo} (ex.: etapa 3 do megaprojeto exige a etapa 2)."""
    return all((levels or {}).get(k, 0) >= v for k, v in x.get("requires_upgrade", {}).items())


def _available(u: dict, lv: int, unlocked: set[str], shop: dict[str, int] | None = None,
               levels: dict[str, int] | None = None) -> bool:
    if lv >= u.get("max_level", 10 ** 9):
        return False
    if not _requires_ok(u, levels):
        return False
    if u.get("requires_shop") and (shop or {}).get(u["requires_shop"], 0) == 0:
        return False
    req = u.get("requires_planet")
    return req is None or req in unlocked


def road_spec(E: dict, planet: str | None = None) -> list[dict]:
    """Estrada das Estrelas (v13, progression.road): paradas em ordem, cada uma com `stars` (total ACUMULADO de
    estrelas para chegar) e `type`: start | mission (no da arvore de missoes) | grant (upgrade de compra unica que
    vem pronto: habilidade/ajuda) | unlock (upgrade que passa a poder ser comprado: Frota, Piloto) | final.
    Espelho GDScript: EconMath.road / road_reached / road_can_buy."""
    P_ = E.get("progression") or {}
    if P_.get("roads"):                                   # v17: uma Estrada por mundo
        return list(P_["roads"].get(planet, [])) if planet else [s for r in P_["roads"].values() for s in r]
    return P_.get("road") or []


def record_bonus(E: dict, run_money: float, old_record: float) -> float:
    """v16 (mundos paralelos, padrao Hill Climb Racing 2): bonus em moedas por bater o recorde de dinheiro do run
    NUM MUNDO. Primeira visita (sem recorde) paga first_frac x dinheiro do run; bater a marca paga frac x dinheiro do
    run; nao bater = 0. contracts.record_bonus ausente = 0."""
    B = E["contracts"].get("record_bonus")
    if not B or run_money <= 0.0:
        return 0.0
    if old_record <= 0.0:
        return B.get("first_frac", 0.0) * run_money
    return B.get("frac", 0.0) * run_money if run_money > old_record else 0.0


def world_of_stop(stop: dict) -> str:
    """Planeta liberado por uma parada 'world' da Estrada (id world_<planeta>); '' se a parada nao e de mundo."""
    return str(stop["id"])[6:] if stop.get("type") == "world" else ""


def road_reached_now(E: dict, stars_total: float, reached: set, planet: str | None = None) -> list[dict]:
    """Paradas que o total de estrelas alcanca e ainda nao foram marcadas (na ordem da estrada). v17: planet = a
    Estrada daquele mundo (estrelas feitas nele)."""
    return [s for s in road_spec(E, planet) if s["id"] not in reached and stars_total >= s["stars"]]


def next_world(E: dict, planet: str) -> str:
    """Mundo seguinte na ordem da spec (o que a parada 'complete' do mundo libera); '' no ultimo."""
    ids = [p["id"] for p in E["planets"]]
    i = ids.index(planet) if planet in ids else -1
    return ids[i + 1] if 0 <= i < len(ids) - 1 else ""


def road_can_buy(E: dict, upgrade_id: str, reached: set) -> bool:
    """Com estrada: upgrade 'grant' nunca se compra (vem pronto); 'unlock' so depois da parada; o resto, sempre."""
    for s in road_spec(E):
        if s["id"] == upgrade_id:
            return s["type"] == "unlock" and upgrade_id in reached
    return True


def fleet_mult(stats: dict) -> float:
    """Renda total / renda do piloto. Frota: cada drone repete as rotas do jogador com eficiencia
    `autopilot` (fracao da renda media do proprio jogador)."""
    return 1.0 + stats.get("drones", 0.0) * stats.get("autopilot", 0.0)


def simulate(E: dict, prof: Profile | str, hours: float = 30.0, seed: int = 0, max_runs: int = 200000) -> SimResult:
    """Joga o jogo por `hours` com um perfil. Loop: run -> recebe -> compra (estrategia) -> talvez
    desbloqueie planeta / prestigie. Termina cedo se o objetivo final (targets.goal) for atingido."""
    prof = profile_from(E, prof) if isinstance(prof, str) else copy.deepcopy(prof)
    prof.attempts = prof.delivered = 0                         # contadores do novato: jogo novo
    _INCOME_CACHE.clear()
    rng = random.Random(seed)
    res = SimResult(prof.name, seed)
    money = {r["id"]: float(r.get("start", 0.0)) for r in E["resources"]}
    lifetime = {k: 0.0 for k in money}
    run_earned = {k: 0.0 for k in money}
    levels = {u["id"]: 0 for u in E["upgrades"]}
    planets = {p["id"]: p for p in E["planets"]}
    unlocked = {p["id"] for p in E["planets"] if not p.get("unlock") and not p.get("road")}
    world_rec: dict = {}   # v16: recorde de dinheiro do run por mundo (bonus de recorde)
    world_stars: dict = {}  # v17: estrelas feitas em cada mundo (andam a Estrada dele)
    done: set = set()       # v17: mundos completos
    world_runs: dict = {}  # runs jogados em cada mundo (relatorio)
    current = E["planets"][0]["id"]
    ppoints = 0.0          # poeira ganha na vida toda (nivel de prestigio: bonus passivo, nunca diminui)
    shop = {it["id"]: 0 for it in shop_items(E)}
    P = E.get("prestige")
    goal = E["targets"].get("goal", {})
    t = 0.0
    runs = 0
    last_buy_t = 0.0
    # missoes (v12): estrelas ganhas por entrega compram nos da arvore em ordem (jogador simulado libera assim
    # que pode); mu = {kind: estrela} liberadas, boost = {kind: runs com peso extra}
    MS = mission_spec(E)
    stars = 0
    owned: set = set()
    # estrada (v13, progression.road): estrelas ACUMULADAS (nao se gastam) liberam as paradas sozinhas
    road = road_spec(E)
    reached: set = set()
    rep_pts: dict = {}     # Reputacao por ratinho (v14): tipo -> pontos (permanentes)
    RQ = (E["contracts"].get("reputation") or {}).get("model_q_min", 2.0)
    mu = missions_unlocked(E, owned) if MS else None
    boost: dict = {}

    def stats_now():
        return ship_stats(E, levels, ppoints, shop)

    def shop_effect(kind: str) -> list[tuple[dict, int]]:
        return [(it, shop[it["id"]]) for it in shop_items(E) if it["effect"]["type"] == kind and shop[it["id"]] > 0]

    last_run_s = [120.0]

    def choose_world(stats):
        # v17: o jogador segue a viagem (o primeiro mundo liberado ainda nao completo); tudo completo = o melhor
        if (E.get("progression") or {}).get("roads"):
            for p in E["planets"]:
                if p["id"] in unlocked and p["id"] not in done:
                    return p["id"]
        return best_planet(stats)

    def best_planet(stats):
        # v16: renda esperada + bonus de recorde se o run esperado passar a marca daquele mundo
        B = E["contracts"].get("record_bonus") or {}

        def score(pid):
            inc = _value(E, expected_income(E, planets[pid], stats, prof, missions=mu))
            est = inc * last_run_s[0]
            rec = world_rec.get(pid, 0.0)
            bonus = B.get("first_frac", 0.0) if rec <= 0.0 else (B.get("frac", 0.0) if est > rec else 0.0)
            return inc * (1.0 + bonus)
        return max(unlocked, key=score)

    while t < hours * 3600 and runs < max_runs:
        stats = stats_now()
        rep_lv = {k: reputation_level(E, v) for k, v in rep_pts.items()}
        dlog: list = []
        r = do_run(E, planets[current], stats, prof, rng, missions=mu, boost=boost, rep=rep_lv, log=dlog)
        for entry in dlog[:r.deliveries]:          # entrega feita (modelo: falha de regra ja esta no pagamento medio)
            if len(entry) >= 6:
                kind = slot_kind(str(entry[4]))
                rep_pts[kind] = rep_pts.get(kind, 0) + reputation_points(E, True, entry[2] >= RQ)
        runs += 1
        last_run_s[0] = max(30.0, r.time_s)
        world_runs[current] = world_runs.get(current, 0) + 1
        rm = r.rewards.get("credits", 0.0)
        rb = record_bonus(E, rm, world_rec.get(current, 0.0))
        if rb > 0.0:
            money["credits"] = money.get("credits", 0.0) + rb
            lifetime["credits"] = lifetime.get("credits", 0.0) + rb
            res.events.append({"t": t, "type": "record_bonus", "id": current, "value": rb, "gap_s": 0.0})
        world_rec[current] = max(world_rec.get(current, 0.0), rm)
        if MS:
            boost = {k: v - 1 for k, v in boost.items() if v > 1}
            stars += r.deliveries * MS.get("stars", {}).get("per_delivery", 1)
            cost = MS.get("stars", {}).get("unlock_cost", 3)
            per_world = bool((E.get("progression") or {}).get("roads"))
            world_stars[current] = world_stars.get(current, 0) + r.deliveries * MS.get("stars", {}).get("per_delivery", 1)
            for stop in road_reached_now(E, world_stars[current] if per_world else stars, reached,
                                         current if per_world else None):
                reached.add(stop["id"])
                if stop["type"] == "mission":
                    owned.add(stop["id"])
                elif stop["type"] == "grant":
                    levels[stop["id"]] = max(levels[stop["id"]], 1)
                elif world_of_stop(stop) in planets:
                    unlocked.add(world_of_stop(stop))
                    res.events.append({"t": t, "type": "planet", "id": world_of_stop(stop), "cost": {}, "gap_s": 0.0})
                elif stop["type"] == "complete":
                    done.add(current)
                    nw = next_world(E, current)
                    if nw:
                        unlocked.add(nw)
                        res.events.append({"t": t, "type": "planet", "id": nw, "cost": {}, "gap_s": 0.0})
                res.events.append({"t": t, "type": "road", "id": stop["id"], "gap_s": 0.0})
            current = choose_world(stats_now())
            for node in ([] if road else MS.get("nodes", [])):
                if stars < node.get("cost", cost):
                    break
                if node_ok(E, node, owned):
                    stars -= node.get("cost", cost)
                    owned.add(node["id"])
                    boost[node["kind"]] = MS.get("new_boost", {}).get("runs", 0)
                    res.events.append({"t": t, "type": "mission", "id": node["id"], "gap_s": 0.0})
            mu = missions_unlocked(E, owned)
        t += r.time_s
        for k, v in r.rewards.items():
            money[k] += v
            lifetime[k] += v
            run_earned[k] += v
        fleet_val = 0.0
        fm = fleet_mult(stats) - 1.0
        if fm > 0:  # frota rendeu durante o run: fm x renda media esperada do piloto
            for k, v in expected_income(E, planets[current], stats, prof, missions=mu).items():
                gained = v * fm * r.time_s
                money[k] += gained
                lifetime[k] += gained
                run_earned[k] += gained
                fleet_val += gained * E.get("resource_value", {}).get(k, 1.0)
        res.samples.append({"t": t, "planet": current, "money": dict(money), "rewards": r.rewards, "fleet": fleet_val,
                            "run_s": r.time_s, "deliveries": r.deliveries, "max_d": r.max_distance,
                            "crashed": r.crashed, "stats": stats, "ppoints": ppoints})
        # ---- compras
        while True:
            stats = stats_now()
            base_inc = _value(E, expected_income(E, planets[current], stats, prof, missions=mu)) * fleet_mult(stats)
            opts = []
            for u in E["upgrades"]:
                lv = levels[u["id"]]
                if not _available(u, lv, unlocked, shop, levels):
                    continue
                if road and not road_can_buy(E, u["id"], reached):
                    continue
                cost = _upgrade_cost(u, lv)
                # olha alguns niveis a frente: ganhos de alcance sao 'degraus' (1 nivel pode nao bastar
                # para alcancar a proxima entrega). Valor = melhor ganho/custo entre k niveis, por nivel.
                best_ratio = 0.0
                for k in (1, 2, 4, 8):
                    if lv + k > u.get("max_level", 10 ** 9):
                        break
                    lv2 = dict(levels)
                    lv2[u["id"]] += k
                    s2 = ship_stats(E, lv2, ppoints, shop)
                    inc = max(_value(E, expected_income(E, planets[pid], s2, prof, missions=mu)) for pid in unlocked) * fleet_mult(s2)
                    ck = _value(E, {r: bulk_cost(spec, lv, k) for r, spec in u["cost"].items()})
                    best_ratio = max(best_ratio, (inc - base_inc) / (ck + 1e-9))
                score = best_ratio * _value(E, cost)
                if u.get("ability"):  # habilidade (v8): nao muda a renda no modelo; vale ~ability_value da renda
                    score = base_inc * u.get("ability_value", 0.03)
                if u.get("progress"):  # etapa de megaprojeto: vale como progressao (igual planetas)
                    score = max(score, 0.0) + base_inc * 0.5
                opts.append(("upgrade", u["id"], cost, score))
            for p in E["planets"]:
                if p["id"] in unlocked or not p.get("unlock"):
                    continue
                if p.get("requires") and p["requires"] not in unlocked:
                    continue
                if not _requires_ok(p, levels):
                    continue
                if p.get("requires_shop") and shop.get(p["requires_shop"], 0) == 0:
                    continue
                inc = _value(E, expected_income(E, p, stats, prof, missions=mu)) * fleet_mult(stats)
                # planetas tem valor de progressao alem da renda (sao o objetivo): bonus de prioridade
                opts.append(("planet", p["id"], dict(p["unlock"]), max(inc - base_inc, 0) + base_inc * 0.5))
            if not opts:
                break
            cost_val = lambda c: _value(E, c) + 1e-9
            if prof.strategy == "cheapest":
                opts.sort(key=lambda o: cost_val(o[2]))
                pick = opts[0] if _affordable(opts[0][2], money) else None
            elif prof.strategy == "random":
                aff = [o for o in opts if _affordable(o[2], money)]
                pick = rng.choice(aff) if aff else None
            else:  # roi: melhor ganho por custo; enquanto junta para o melhor, compra o que "se paga" antes
                scored = sorted(opts, key=lambda o: -o[3] / cost_val(o[2]))
                best = scored[0]
                pick = None
                if _affordable(best[2], money):
                    pick = best
                else:
                    # tempo para conseguir pagar o melhor com a renda atual
                    missing = sum(max(0.0, v - money.get(k, 0.0)) * E.get("resource_value", {}).get(k, 1.0)
                                  for k, v in best[2].items())
                    t_afford = missing / max(base_inc, 1e-9)
                    for o in scored[1:]:
                        if not _affordable(o[2], money) or o[3] <= 0:
                            continue
                        good_ratio = o[3] / cost_val(o[2]) >= 0.5 * best[3] / cost_val(best[2])
                        pays_back = cost_val(o[2]) / o[3] < t_afford  # se paga antes de juntar o valor da meta
                        if good_ratio or pays_back:
                            pick = o
                            break
            if pick is None:
                break
            kind, oid, cost, _ = pick
            for k, v in cost.items():
                money[k] -= v
            if kind == "upgrade":
                levels[oid] += 1
                res.events.append({"t": t, "type": "upgrade", "id": oid, "level": levels[oid], "cost": cost,
                                   "gap_s": t - last_buy_t})
            else:
                unlocked.add(oid)
                res.events.append({"t": t, "type": "planet", "id": oid, "cost": cost, "gap_s": t - last_buy_t})
            last_buy_t = t
            current = choose_world(stats_now())
        # ---- prestigio
        if P:
            gain = prestige_gain(P, run_earned[P.get("based_on", "credits")])
            req = P.get("requires_planet")
            # jogador racional nao recomeca quando a meta final esta perto (< goal_hold_h de juntar)
            near_goal = False
            gp = goal.get("planet")
            if gp and gp not in unlocked:
                gpl = planets[gp]
                # etapas de megaprojeto que faltam (progress) contam como parte do custo da meta
                todo = [u for u in E["upgrades"] if u.get("progress") and levels[u["id"]] < u.get("max_level", 1)]
                first_ok = all(_available(u, levels[u["id"]], unlocked, shop, levels) or levels[u["id"]] > 0
                               for u in todo[:1])
                avail = (not gpl.get("requires") or gpl["requires"] in unlocked) and \
                        (not gpl.get("requires_shop") or shop.get(gpl["requires_shop"], 0) > 0) and first_ok
                if avail:
                    inc_now = _value(E, expected_income(E, planets[current], stats_now(), prof, missions=mu)) * fleet_mult(stats_now())
                    need = dict(gpl.get("unlock", {}))
                    for u in todo:
                        for k, v in _upgrade_cost(u, levels[u["id"]]).items():
                            need[k] = need.get(k, 0.0) + v
                    missing = sum(max(0.0, v - money.get(k, 0.0)) * E.get("resource_value", {}).get(k, 1.0)
                                  for k, v in need.items())
                    near_goal = missing / max(inc_now, 1e-9) < goal.get("hold_h", 2.0) * 3600
            if not near_goal and gain >= max(P.get("min_gain", 1), prof.prestige_ratio * ppoints) \
                    and (req is None or req in unlocked):
                ppoints += gain
                money[P["resource"]] = money.get(P["resource"], 0.0) + gain
                res.events.append({"t": t, "type": "prestige", "gain": gain, "points": ppoints,
                                   "gap_s": t - last_buy_t})
                # loja: compra por prioridade; se o proximo item da fila nao cabe, guarda poeira para ele
                for it in sorted(shop_items(E), key=lambda x: x.get("priority", 99)):
                    while shop[it["id"]] < it.get("max_level", 1):
                        c = cost_at(it["cost"], shop[it["id"]])
                        if money[P["resource"]] < c:
                            break
                        money[P["resource"]] -= c
                        shop[it["id"]] += 1
                        res.events.append({"t": t, "type": "shop", "id": it["id"], "level": shop[it["id"]],
                                           "cost": {P["resource"]: c}, "gap_s": 0.0})
                    if shop[it["id"]] < it.get("max_level", 1) and not it.get("optional", False):
                        break
                keep = set(P.get("keep", [])) | {it["effect"]["what"] for it, _ in shop_effect("keep")}
                for k in money:
                    if k != P["resource"] and "money" not in keep:
                        money[k] = float(next(r.get("start", 0.0) for r in E["resources"] if r["id"] == k))
                for it, lv in shop_effect("start_resources"):
                    for k, v in it["effect"]["amounts"].items():
                        money[k] += v * lv
                if "upgrades" not in keep:  # upgrades 'persistent' (etapas do megaprojeto) sobrevivem
                    levels = {u["id"]: (levels[u["id"]] if u.get("persistent") else 0) for u in E["upgrades"]}
                    for it, lv in shop_effect("start_levels"):
                        for k, v in it["effect"]["levels"].items():
                            levels[k] = max(levels[k], v * lv)
                if "planets" not in keep:
                    unlocked = {p["id"] for p in E["planets"] if not p.get("unlock")}
                    current = E["planets"][0]["id"]
                else:
                    current = best_planet(stats_now())
                run_earned = {k: 0.0 for k in money}
                last_buy_t = t
        # ---- objetivo final
        if goal.get("planet") and goal["planet"] in unlocked and res.finished_at_h is None:
            res.finished_at_h = t / 3600
            if goal.get("stop", True):
                break
    res.final = {"t_h": t / 3600, "runs": runs, "levels": levels, "unlocked": sorted(unlocked), "shop": shop,
                 "world_runs": world_runs, "world_rec": world_rec, "world_stars": world_stars, "done": sorted(done),
                 "missions": sorted(owned) if MS else [], "stars": stars if MS else 0, "reputation": {k: reputation_level(E, v) for k, v in rep_pts.items()},
                 "money": money, "lifetime": lifetime, "prestige_points": ppoints, "stats": stats_now()}
    return res


# ---------------------------------------------------------------------------
# Relatorio de ritmo (pacing)
# ---------------------------------------------------------------------------

def _phase_limit(targets: dict, t_h: float) -> float:
    """Maior intervalo aceitavel entre compras (min) na fase atual."""
    for ph in targets.get("max_gap_min", []):
        if t_h <= ph["until_h"]:
            return ph["minutes"]
    return math.inf


def pacing_report(E: dict, res: SimResult) -> dict:
    T = E["targets"]
    ev = res.events
    buys = [e for e in ev if e["type"] in ("upgrade", "planet")]
    rep: dict[str, Any] = {"profile": res.profile, "seed": res.seed, "hours_simulated": round(res.final["t_h"], 2),
                           "runs": res.final["runs"], "finished_at_h": None if res.finished_at_h is None
                           else round(res.finished_at_h, 2)}
    w: list[str] = []
    # primeiro upgrade
    first = buys[0]["t"] if buys else None
    rep["first_purchase_s"] = None if first is None else round(first)
    if first is None or first > T.get("first_purchase_max_s", 90):
        w.append(f"primeira compra em {rep['first_purchase_s']}s (alvo <= {T.get('first_purchase_max_s', 90)}s)")
    # paredes
    walls = []
    for e in ev:
        lim = _phase_limit(T, e["t"] / 3600)
        if e["gap_s"] / 60 > lim:
            walls.append({"at_h": round(e["t"] / 3600, 2), "gap_min": round(e["gap_s"] / 60, 1), "limit_min": lim,
                          "before": e.get("id", e["type"])})
    rep["walls"] = walls
    if walls:
        worst = max(walls, key=lambda x: x["gap_min"])
        w.append(f"{len(walls)} paredes (intervalo acima do limite da fase); pior: {worst['gap_min']} min "
                 f"antes de '{worst['before']}' em {worst['at_h']}h (limite {worst['limit_min']} min)")
    gaps = [e["gap_s"] / 60 for e in buys if e["gap_s"] > 0 or e is buys[0]]  # momentos distintos de compra
    rep["gap_min_median"] = round(st.median(gaps), 2) if gaps else None
    rep["gap_min_p90"] = round(sorted(gaps)[int(0.9 * (len(gaps) - 1))], 2) if gaps else None
    # planetas
    unlock_times: dict[str, float] = {}
    for e in ev:  # primeiro desbloqueio (prestigio reseta e o planeta e desbloqueado de novo)
        if e["type"] == "planet":
            unlock_times.setdefault(e["id"], round(e["t"] / 3600, 2))
    rep["planet_unlock_h"] = unlock_times
    for pid, (lo, hi) in T.get("planet_unlock_h", {}).items():
        got = unlock_times.get(pid)
        if got is None:
            w.append(f"planeta '{pid}' nao desbloqueado (alvo {lo}-{hi}h)")
        elif not (lo <= got <= hi):
            w.append(f"planeta '{pid}' desbloqueado em {got}h (alvo {lo}-{hi}h)")
    # duracao total
    lo, hi = T.get("finish_h", [0, math.inf])
    if not T.get("goal"):
        pass  # sem objetivo final (jogo sem fim por enquanto): mede so o ritmo
    elif res.finished_at_h is None:
        w.append(f"objetivo final nao atingido em {rep['hours_simulated']}h (alvo {lo}-{hi}h)")
    elif not (lo <= res.finished_at_h <= hi):
        w.append(f"objetivo final em {res.finished_at_h:.1f}h (alvo {lo}-{hi}h)")
    # prestigio
    pres = [e for e in ev if e["type"] == "prestige"]
    rep["prestiges"] = [{"at_h": round(e["t"] / 3600, 2), "gain": e["gain"], "points": e["points"]} for e in pres]
    if E.get("prestige") and T.get("prestige_count") and res.finished_at_h is not None:
        lo_c, hi_c = T["prestige_count"]
        if not (lo_c <= len(pres) <= hi_c):
            w.append(f"{len(pres)} prestigios ate o fim (alvo {lo_c}-{hi_c})")
    rep["shop_final"] = res.final.get("shop", {})
    if E.get("prestige") and T.get("first_prestige_h"):
        lo, hi = T["first_prestige_h"]
        fp = pres[0]["t"] / 3600 if pres else None
        if fp is None or not (lo <= fp <= hi):
            w.append(f"primeiro prestigio em {None if fp is None else round(fp, 2)}h (alvo {lo}-{hi}h)")
    # uso dos upgrades
    spent: dict[str, float] = {}
    for e in buys:
        if e["type"] == "upgrade":
            spent[e["id"]] = spent.get(e["id"], 0.0) + _value(E, e["cost"])
    tot = sum(spent.values()) or 1.0
    rep["spend_share_pct"] = {k: round(100 * v / tot, 1) for k, v in sorted(spent.items(), key=lambda kv: -kv[1])}
    # niveis comprados (contagem): o gasto em creditos e dominado pelas compras caras do fim do jogo,
    # entao a dominancia e medida pela fracao de NIVEIS comprados
    cnt: dict[str, int] = {}
    for e in buys:
        if e["type"] == "upgrade":
            cnt[e["id"]] = cnt.get(e["id"], 0) + 1
    ctot = sum(cnt.values()) or 1
    rep["levels_share_pct"] = {k: round(100 * v / ctot, 1) for k, v in sorted(cnt.items(), key=lambda kv: -kv[1])}
    never = [u["id"] for u in E["upgrades"] if u["id"] not in cnt]
    if never:
        w.append(f"upgrades nunca comprados (inuteis ou caros demais?): {never}")
    dom = [k for k, v in rep["levels_share_pct"].items() if v > T.get("max_level_share_pct", 60)]
    if dom:
        w.append(f"estrategia dominante: {dom} recebe(m) > {T.get('max_level_share_pct', 60)}% dos niveis comprados")
    maxed = [u["id"] for u in E["upgrades"] if res.final["levels"].get(u["id"], 0) >= u.get("max_level", 10 ** 9)]
    rep["maxed_upgrades"] = maxed
    # run
    runs = res.samples
    if runs:
        rep["run_s_median"] = round(st.median(r["run_s"] for r in runs), 1)
        rep["deliveries_median"] = st.median(r["deliveries"] for r in runs)
        rep["crash_rate_pct"] = round(100 * sum(r["crashed"] for r in runs) / len(runs), 1)
        rlo, rhi = T.get("run_s", [0, math.inf])
        if not (rlo <= rep["run_s_median"] <= rhi):
            w.append(f"run mediano de {rep['run_s_median']}s (alvo {rlo}-{rhi}s)")
        zero = sum(1 for r in runs if r["deliveries"] == 0 and not r["crashed"])
        if zero:
            w.append(f"{zero} runs sem nenhuma entrega (gas nao alcanca nem a menor distancia?)")
        mx = max(max(r["money"].values()) for r in runs)
        rep["max_number"] = mx
        if mx > 1e300:
            w.append("numeros passam de 1e300: usar BigNumber no Godot (ver godot-integration.md)")
        rep["number_class"] = "float64 ok" if mx < 1e15 else ("float64 ok (formatar com sufixos)" if mx < 1e300
                                                              else "BigNumber")
    # fatia da renda vinda da frota (automacao): total e no ultimo quarto do jogo
    if runs and any(r.get("fleet", 0) for r in runs):
        def share(rs):
            fl = sum(r.get("fleet", 0.0) for r in rs)
            act = sum(_value(E, r["rewards"]) for r in rs)
            return round(100 * fl / max(fl + act, 1e-9), 1)
        tail = [r for r in runs if r["t"] >= 0.75 * runs[-1]["t"]]
        rep["idle_share_pct"] = share(runs)
        rep["idle_share_final_pct"] = share(tail)
        mx = T.get("max_idle_share_pct")
        if mx and rep["idle_share_final_pct"] > mx:
            w.append(f"frota gera {rep['idle_share_final_pct']}% da renda no fim (max {mx}%): pilotar perde peso")
    rep["warnings"] = w
    return rep


# ---------------------------------------------------------------------------
# Paralelismo (varios nucleos). Usa 'fork': a funcao e a spec sao herdadas pelos processos filhos,
# entao lambdas funcionam e nada precisa ser serializado na ida (so os resultados na volta).
# ---------------------------------------------------------------------------
_PAR_CTX: dict = {}


def _par_run(i: int):
    return _PAR_CTX["fn"](_PAR_CTX["items"][i])


def parallel_map(fn: Callable, items: list, workers: int | None = None) -> list:
    """map(fn, items) em paralelo (1 processo por nucleo). Cai para sequencial se 'fork' nao existir."""
    import multiprocessing as mp
    items = list(items)
    n = min(workers or os.cpu_count() or 1, len(items))
    if n <= 1:
        return [fn(x) for x in items]
    try:
        ctx = mp.get_context("fork")
    except ValueError:
        return [fn(x) for x in items]
    _PAR_CTX["fn"], _PAR_CTX["items"] = fn, items
    with ctx.Pool(n) as pool:
        return pool.map(_par_run, range(len(items)))


def simulate_many(E: dict, jobs: list[tuple[str, float, int]], workers: int | None = None) -> list[SimResult]:
    """Varias simulacoes em paralelo. jobs = [(perfil, horas, seed), ...]."""
    return parallel_map(lambda j: simulate(E, j[0], j[1], seed=j[2]), jobs, workers)


def screen(E: dict, profiles: tuple[str, ...] = ("engaged", "casual", "expert"), hours: float = 40.0,
           seed: int = 1, show: bool = True) -> dict[str, tuple[SimResult, dict]]:
    """Triagem rapida: 1 seed por perfil, todos em paralelo. Retorna {perfil: (resultado, relatorio)}."""
    rs = simulate_many(E, [(p, hours, seed) for p in profiles])
    out = {p: (r, pacing_report(E, r)) for p, r in zip(profiles, rs)}
    if show:
        for p, (r, rep) in out.items():
            print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | prestigios "
                  f"{len(rep['prestiges'])} | idle {rep.get('idle_share_final_pct')}% | paredes {len(rep['walls'])} "
                  f"(pior {max((w['gap_min'] for w in rep['walls']), default=0)} min) | run {rep.get('run_s_median')}s")
            for w in rep["warnings"]:
                print("   AVISO:", w)
    return out


def monte_carlo(E: dict, profiles: list[str] = ("casual", "engaged", "expert"), seeds: int = 5,
                hours: float = 40.0) -> dict[str, list[SimResult]]:
    """Varias seeds por perfil (em paralelo): mostra a dispersao (sorte, habilidade)."""
    jobs = [(p, hours, s) for p in profiles for s in range(seeds)]
    rs = simulate_many(E, jobs)
    out: dict[str, list[SimResult]] = {p: [] for p in profiles}
    for (p, _, _), r in zip(jobs, rs):
        out[p].append(r)
    return out


def summarize_mc(E: dict, mc: dict[str, list[SimResult]]) -> dict:
    out = {}
    for p, rs in mc.items():
        fin = [r.finished_at_h for r in rs if r.finished_at_h is not None]
        out[p] = {"finished": f"{len(fin)}/{len(rs)}",
                  "finish_h_median": round(st.median(fin), 2) if fin else None,
                  "finish_h_range": [round(min(fin), 2), round(max(fin), 2)] if fin else None}
        planets: dict[str, list[float]] = {}
        for r in rs:
            seen = set()
            for e in r.events:  # so o PRIMEIRO desbloqueio de cada planeta por simulacao
                if e["type"] == "planet" and e["id"] not in seen:
                    seen.add(e["id"])
                    planets.setdefault(e["id"], []).append(e["t"] / 3600)
        out[p]["planet_unlock_h_median"] = {k: round(st.median(v), 2) for k, v in planets.items()}
    return out


# ---------------------------------------------------------------------------
# Ajuste automatico (tuning)
# ---------------------------------------------------------------------------

def solve(E: dict, path: str, metric: Callable[[dict], float], target: float, lo: float, hi: float,
          iters: int = 10, log: bool = True, increasing: bool | None = None, workers: int | None = None,
          verbose: bool = False) -> float:
    """Acha o valor do parametro `path` para que metric(E) ~= target (nao altera E).
    metric recebe uma copia da spec (ex.: lambda e: planet_unlock_hour(e, 'ares')).
    Em rodadas paralelas: cada rodada avalia N valores (1 por nucleo) entre lo e hi, estreita o intervalo
    em torno do alvo e no fim interpola. `iters` = precisao equivalente a N passos de busca binaria
    (10 ~ intervalo reduzido 1000x), convertida no numero de rodadas necessario."""
    n = max(3, min(workers or os.cpu_count() or 4, 16))
    rounds = max(1, math.ceil(iters * math.log(2) / math.log(n - 1)))

    def at(v):
        e = copy.deepcopy(E)
        set_path(e, path, v)
        return metric(e)

    pts: dict[float, float] = {}
    a, b = lo, hi
    for _ in range(rounds):
        grid = [a * (b / a) ** (i / (n - 1)) if log else a + (b - a) * i / (n - 1) for i in range(n)]
        grid = [g for g in grid if g not in pts]
        pts.update(zip(grid, parallel_map(at, grid, workers=n)))
        xs = sorted(pts)
        fs = [pts[x] for x in xs]
        if verbose:
            print("  solve:", [(fmt(x), round(f, 2)) for x, f in zip(xs, fs)])
        brackets = [(xs[i], xs[i + 1]) for i in range(len(xs) - 1)
                    if (fs[i] - target) * (fs[i + 1] - target) <= 0]
        if brackets:
            a, b = brackets[0]
        else:  # alvo fora do intervalo: fica no extremo mais proximo
            j = min(range(len(xs)), key=lambda i: abs(fs[i] - target))
            return xs[j]
    fa, fb = pts[a], pts[b]
    if fb == fa:
        return math.sqrt(a * b) if log else (a + b) / 2
    u = (target - fa) / (fb - fa)
    return a * (b / a) ** u if log else a + (b - a) * u


def planet_unlock_hour(E: dict, pid: str, profile: str = "engaged", seed: int = 1, hours: float = 60) -> float:
    r = simulate(E, profile, hours, seed)
    for e in r.events:
        if e["type"] == "planet" and e["id"] == pid:
            return e["t"] / 3600
    return hours * 2


# ---------------------------------------------------------------------------
# Calibracao com telemetria do jogo real
# ---------------------------------------------------------------------------

def calibrate(E: dict, csv_path: str, profile: str = "engaged") -> dict:
    """Ajusta 'waste' e 'hover_s' do perfil comparando o gas previsto com o gas real por entrega.
    CSV (exportado pelo jogo): planet,distance,thrust,efficiency,tank,gas_used,hop_time_s,quality,crashed
    Retorna os overrides sugeridos para E['profiles_override'][profile]."""
    rows = list(csv.DictReader(open(csv_path)))
    planets = {p["id"]: p for p in E["planets"]}
    prof = profile_from(E, profile)
    best = (math.inf, prof.waste, prof.hover_s)
    for waste in [1.0 + i * 0.025 for i in range(41)]:
        for hover in [i * 0.25 for i in range(17)]:
            prof.waste, prof.hover_s = waste, hover
            err = 0.0
            for r in rows:
                s = {"thrust": float(r["thrust"]), "efficiency": float(r["efficiency"]), "tank": float(r["tank"]),
                     "dry_mass": E["ship"]["base"].get("dry_mass", 1.0)}
                pred = gas_for(E, hop_dv(planets[r["planet"]], float(r["distance"]), s, prof), s, float(r["tank"]))
                err += (math.log(max(pred, 1e-9)) - math.log(max(float(r["gas_used"]), 1e-9))) ** 2
            if err < best[0]:
                best = (err, waste, hover)
    q = [float(r["quality"]) for r in rows if r.get("quality")]
    out = {"waste": round(best[1], 3), "hover_s": best[2]}
    if q:
        out["skill"] = round(st.mean(q), 3)
        out["skill_sd"] = round(st.pstdev(q), 3)
    ht = [float(r["hop_time_s"]) for r in rows if r.get("hop_time_s")]
    if ht:
        pred_t = [hop_time(planets[r["planet"]], float(r["distance"]), {"thrust": float(r["thrust"])},
                           Profile("x", hop_overhead_s=0)) for r in rows]
        out["hop_overhead_s"] = round(max(0.0, st.mean(a - b for a, b in zip(ht, pred_t))), 2)
    out["fit_rmse_log"] = round(math.sqrt(best[0] / max(1, len(rows))), 3)
    return out


# ---------------------------------------------------------------------------
# Formatacao de numeros (mesma logica do GDScript exportado)
# ---------------------------------------------------------------------------
SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


def fmt(x: float, style: str = "suffix", digits: int = 3) -> str:
    """suffix: 1,23K ... 4,56Dc, depois letras aa, ab... | sci: 1.23e45 | eng: 123e42.
    Abaixo de 1000 mostra inteiro (ou 1 casa se < 10 e fracionario)."""
    if x != x:
        return "NaN"
    if math.isinf(x):
        return "inf"
    neg = x < 0
    x = abs(x)
    if x < 1000:
        s = f"{x:.1f}".replace(".", ",") if (x < 10 and x != int(x)) else f"{int(x)}"
        return ("-" if neg else "") + s
    e3 = int(math.floor(math.log10(x) / 3))
    if style == "sci":
        e = int(math.floor(math.log10(x)))
        s = f"{x / 10 ** e:.{digits - 1}f}e{e}"
    elif style == "eng":
        m = x / 10 ** (3 * e3)
        s = f"{m:.{max(0, digits - len(str(int(m))))}f}e{3 * e3}"
    else:
        m = x / 10 ** (3 * e3)
        if e3 < len(SUFFIXES):
            suf = SUFFIXES[e3]
        else:
            k = e3 - len(SUFFIXES)
            suf = chr(97 + (k // 26) % 26) + chr(97 + k % 26)
        s = f"{m:.{max(0, digits - len(str(int(m))))}f}{suf}"
    return ("-" if neg else "") + s.replace(".", ",")      # pt-BR: virgula decimal (igual ao jogo)


def fmt_time(seconds: float) -> str:
    s = int(seconds)
    if s < 60:
        return f"{s}s"
    if s < 3600:
        return f"{s // 60}m{s % 60:02d}s"
    return f"{s // 3600}h{(s % 3600) // 60:02d}m"


# ---------------------------------------------------------------------------
# Tabelas e graficos
# ---------------------------------------------------------------------------

def upgrade_table(E: dict, uid: str, levels: range = range(0, 21, 2)) -> str:
    """Tabela markdown nivel -> custo, valor do stat (para revisar a curva de um upgrade)."""
    u = next(x for x in E["upgrades"] if x["id"] == uid)
    head = "| nivel | " + " | ".join(f"custo {k}" for k in u["cost"]) + f" | {u['effect']['stat']} |\n"
    head += "|---" * (len(u["cost"]) + 2) + "|\n"
    rows = []
    for lv in levels:
        costs = " | ".join(fmt(cost_at(s, lv)) for s in u["cost"].values())
        stat = ship_stats(E, {uid: lv})[u["effect"]["stat"]]
        rows.append(f"| {lv} | {costs} | {stat:.3g} |")
    return head + "\n".join(rows)


_PAL = [(77, 155, 230), (251, 185, 84), (30, 188, 115), (240, 79, 120), (168, 132, 243), (48, 225, 185),
        (249, 194, 43), (232, 59, 59)]


def line_chart(series: dict[str, list[tuple[float, float]]], path: str, title: str = "", logy: bool = False,
               xlabel: str = "horas", markers: list[tuple[float, str]] | None = None, W: int = 1000,
               H: int = 420, stems: bool = False) -> str:
    """Grafico de linhas simples (PIL). markers = [(x, rotulo)] linhas verticais (desbloqueios/prestigio)."""
    from PIL import Image, ImageDraw
    img = Image.new("RGB", (W, H), (20, 16, 24))
    d = ImageDraw.Draw(img)
    L, R, Tp, B = 70, 20, 30, 40
    pts_all = [p for s in series.values() for p in s if (not logy or p[1] > 0)]
    if not pts_all:
        img.save(path)
        return path
    xs = [p[0] for p in pts_all]
    ys = [math.log10(p[1]) if logy else p[1] for p in pts_all]
    x0, x1 = min(xs), max(xs) or 1
    y0, y1 = min(ys), max(ys)
    if y1 == y0:
        y1 = y0 + 1
    X = lambda x: L + (x - x0) / ((x1 - x0) or 1) * (W - L - R)
    Y = lambda y: H - B - (y - y0) / (y1 - y0) * (H - Tp - B)
    d.text((10, 8), title, fill=(230, 230, 230))
    for i in range(6):
        yy = y0 + (y1 - y0) * i / 5
        d.line([(L, Y(yy)), (W - R, Y(yy))], fill=(46, 40, 56))
        lab = f"1e{yy:.0f}" if logy else fmt(yy)
        d.text((5, Y(yy) - 6), lab, fill=(150, 150, 165))
    for i in range(6):
        xx = x0 + (x1 - x0) * i / 5
        d.text((X(xx) - 10, H - B + 8), f"{xx:.1f}", fill=(150, 150, 165))
    d.text((W - 60, H - 18), xlabel, fill=(150, 150, 165))
    for (mx, lab) in markers or []:
        d.line([(X(mx), Tp), (X(mx), H - B)], fill=(98, 85, 101))
        d.text((X(mx) + 3, Tp + 2), lab, fill=(199, 220, 208))
    for i, (name, s) in enumerate(series.items()):
        col = _PAL[i % len(_PAL)]
        p = [(X(a), Y(math.log10(b) if logy else b)) for a, b in s if (not logy or b > 0)]
        if stems:  # barras verticais (eventos discretos, ex.: intervalo antes de cada compra)
            for px_, py_ in p:
                d.line([(px_ + i, H - B), (px_ + i, py_)], fill=col, width=1)
        elif len(p) > 1:
            d.line(p, fill=col, width=2)
        d.text((L + 10 + i * 150, Tp + 16), name, fill=col)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    img.save(path)
    return path


def write_report(E: dict, results: list[SimResult], out_dir: str, title: str = "Relatorio de balanceamento") -> str:
    """Gera <out_dir>/report.md + graficos (dinheiro log, renda/min, intervalos entre compras, stats)."""
    os.makedirs(out_dir, exist_ok=True)
    main_res = "credits"
    md = [f"# {title}\n", f"Versao da spec: {E.get('meta', {}).get('version', '?')}\n"]
    series_money, series_inc, series_gap = {}, {}, {}
    markers = []
    for r in results:
        key = f"{r.profile}#{r.seed}"
        series_money[key] = [(s["t"] / 3600, max(sum(s["money"].values()), 1e-9)) for s in r.samples]
        inc = []
        for s in r.samples:
            inc.append((s["t"] / 3600, sum(s["rewards"].values()) / s["run_s"] * 60))
        # media movel para legibilidade
        k = max(1, len(inc) // 150)
        series_inc[key] = [(inc[i][0], st.mean(v for _, v in inc[max(0, i - k):i + 1])) for i in range(0, len(inc), k)]
        series_gap[key] = [(e["t"] / 3600, e["gap_s"] / 60) for e in r.events if e["type"] in ("upgrade", "planet")]
        if r is results[0]:  # marcadores: 1o desbloqueio de cada planeta + prestigios ('P')
            seen: set[str] = set()
            for e in r.events:
                if e["type"] == "planet" and e["id"] not in seen:
                    seen.add(e["id"])
                    markers.append((e["t"] / 3600, e["id"]))
                elif e["type"] == "prestige":
                    markers.append((e["t"] / 3600, "P"))
    line_chart(series_money, os.path.join(out_dir, "money.png"), f"{main_res} + recursos em caixa (log)", True,
               markers=markers)
    line_chart(series_inc, os.path.join(out_dir, "income.png"), "renda por minuto (log)", True, markers=markers)
    line_chart(series_gap, os.path.join(out_dir, "gaps.png"), "minutos entre compras (paredes = picos)", False,
               markers=markers, stems=True)
    r0 = results[0]
    stat_names = list(E["ship"]["base"])
    series_stats = {n: [(s["t"] / 3600, s["stats"][n] / max(E["ship"]["base"][n], 1e-9)) for s in r0.samples]
                    for n in stat_names}
    line_chart(series_stats, os.path.join(out_dir, "stats.png"), "stats da nave (x base, log)", True, markers=markers)
    md.append("![dinheiro](money.png)\n![renda](income.png)\n![intervalos](gaps.png)\n![stats](stats.png)\n")
    for r in results:
        rep = pacing_report(E, r)
        md.append(f"## Perfil {r.profile} (seed {r.seed})\n")
        md.append(f"- Horas simuladas: {rep['hours_simulated']} | runs: {rep['runs']} | "
                  f"objetivo final: {rep['finished_at_h']}h")
        md.append(f"- Primeira compra: {rep['first_purchase_s']}s | intervalo mediano: {rep['gap_min_median']} min "
                  f"| p90: {rep['gap_min_p90']} min")
        md.append(f"- Run mediano: {rep.get('run_s_median')}s, {rep.get('deliveries_median')} entregas, "
                  f"batidas {rep.get('crash_rate_pct')}%")
        md.append(f"- Planetas: {rep['planet_unlock_h']}")
        md.append(f"- Prestigios: {rep['prestiges'][:6]}{' ...' if len(rep['prestiges']) > 6 else ''}")
        md.append(f"- Niveis comprados por upgrade (%): {rep['levels_share_pct']}")
        md.append(f"- Gasto por upgrade (%): {rep['spend_share_pct']}")
        md.append(f"- Maior numero: {fmt(rep.get('max_number', 0))} -> {rep.get('number_class')}")
        md.append("- **Avisos:**" if rep["warnings"] else "- Sem avisos")
        md += [f"  - {w}" for w in rep["warnings"]]
        md.append("")
    md.append("## Curvas dos upgrades\n")
    for u in E["upgrades"]:
        md.append(f"### {u.get('name', u['id'])}\n")
        md.append(upgrade_table(E, u["id"], range(0, min(u.get("max_level", 30), 30) + 1, 5)) + "\n")
    path = os.path.join(out_dir, "report.md")
    with open(path, "w") as f:
        f.write("\n".join(md))
    return path


def print_summary(E: dict, res: SimResult) -> dict:
    rep = pacing_report(E, res)
    keys = ["profile", "hours_simulated", "runs", "finished_at_h", "first_purchase_s", "gap_min_median",
            "gap_min_p90", "run_s_median", "deliveries_median", "crash_rate_pct", "planet_unlock_h", "prestiges",
            "levels_share_pct", "spend_share_pct", "idle_share_pct", "idle_share_final_pct", "number_class"]
    for k in keys:
        if k in rep:
            v = rep[k]
            if k == "prestiges":
                v = f"{len(v)} (primeiro: {v[0] if v else None})"
            print(f"{k:18s} {v}")
    for w in rep["warnings"]:
        print("  AVISO:", w)
    if not rep["warnings"]:
        print("  OK: sem avisos")
    return rep


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("uso: econ.py sim <economy.json> [perfil] [horas] [seed]\n"
              "     econ.py mc <economy.json> [seeds] [horas]\n"
              "     econ.py screen <economy.json> [horas]      (3 perfis em paralelo)\n"
              "     econ.py report <economy.json> <out_dir> [horas]\n"
              "     econ.py table <economy.json> <upgrade_id>\n"
              "     econ.py fmt <numero> [suffix|sci|eng]")
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd == "fmt":
        print(fmt(float(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else "suffix"))
        sys.exit(0)
    E_ = load(sys.argv[2])
    if cmd == "sim":
        print_summary(E_, simulate(E_, sys.argv[3] if len(sys.argv) > 3 else "engaged",
                                   float(sys.argv[4]) if len(sys.argv) > 4 else 40,
                                   int(sys.argv[5]) if len(sys.argv) > 5 else 1))
    elif cmd == "mc":
        mc_ = monte_carlo(E_, seeds=int(sys.argv[3]) if len(sys.argv) > 3 else 5,
                          hours=float(sys.argv[4]) if len(sys.argv) > 4 else 40)
        print(json.dumps(summarize_mc(E_, mc_), indent=2, ensure_ascii=False))
    elif cmd == "report":
        hrs = float(sys.argv[4]) if len(sys.argv) > 4 else 40
        rs_ = simulate_many(E_, [(p, hrs, 1) for p in ("engaged", "casual", "expert")])
        print(write_report(E_, rs_, sys.argv[3]))
    elif cmd == "screen":
        screen(E_, hours=float(sys.argv[3]) if len(sys.argv) > 3 else 40)
    elif cmd == "table":
        print(upgrade_table(E_, sys.argv[3]))
