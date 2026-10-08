#!/usr/bin/env python3
"""Funil dos primeiros minutos (auditoria FTUE, 2026-10-08).

Le user://telemetry/session.csv (Telemetry.event no jogo) e, para cada JOGO NOVO, mostra quanto tempo levou ate a
1a decolagem, a 1a entrega e a 1a compra, quantas batidas/tentativas houve antes da 1a entrega e onde a sessao
terminou. Metas (relatorio da auditoria): decolar <= 10 s, 1a entrega <= 60 s, 1a compra <= 240 s.

Uso: python3 .claude/skills/godot-dev/scripts/ftue.py [caminho/session.csv]
"""
import csv
import sys
from pathlib import Path

DEFAULT = Path.home() / "Library/Application Support/IncrementalLander/telemetry/session.csv"
GOALS = {"takeoff": 10.0, "delivery": 60.0, "buy": 240.0}


def funnels(rows: list[dict]) -> list[dict]:
    """Um funil por evento new_game (ate o proximo new_game ou o fim da sessao)."""
    out: list[dict] = []
    cur: dict | None = None
    for r in rows:
        ev = r["event"]
        t = float(r["t_s"])
        if ev == "new_game":
            cur = {"session": r["session"], "t0": t, "first": {}, "crashes": 0, "retries": 0, "rests": 0,
                   "runs_before_buy": None, "last": "new_game"}
            out.append(cur)
            continue
        if cur is None or r["session"] != cur["session"]:
            continue
        cur["last"] = ev
        for key in ("takeoff", "delivery", "buy", "nave", "map"):
            if ev == key and key not in cur["first"]:
                cur["first"][key] = t - cur["t0"]
                if key == "buy":
                    cur["runs_before_buy"] = int(r["runs"])
        if "delivery" not in cur["first"]:
            cur["crashes"] += ev == "crash"
            cur["retries"] += ev == "retry"
            cur["rests"] += ev == "rest"
    return out


def fmt(v: float | None, goal: float | None = None) -> str:
    if v is None:
        return "-"
    mark = "" if goal is None else (" ok" if v <= goal else " !")
    return f"{v:.0f}s{mark}"


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    if not path.exists():
        print(f"sem dados: {path} (jogue um jogo novo com o build de depuracao)")
        return
    rows = list(csv.DictReader(path.open(encoding="utf-8")))
    fs = funnels(rows)
    if not fs:
        print("nenhum jogo novo registrado")
        return
    print(f"{'sessao':>11} {'decolar':>9} {'entrega':>9} {'compra':>9} {'NAVE':>6} {'batidas':>7} "
          f"{'tentou':>6} {'runs':>4}  fim")
    for f in fs:
        g = f["first"]
        print(f"{f['session']:>11} {fmt(g.get('takeoff'), GOALS['takeoff']):>9} "
              f"{fmt(g.get('delivery'), GOALS['delivery']):>9} {fmt(g.get('buy'), GOALS['buy']):>9} "
              f"{fmt(g.get('nave')):>6} {f['crashes']:>7} {f['retries']:>6} "
              f"{'-' if f['runs_before_buy'] is None else f['runs_before_buy']:>4}  {f['last']}")


if __name__ == "__main__":
    main()
