#!/usr/bin/env python3
"""Testes do skill_guard.py (rodar da raiz: python3 .claude/hooks/test_skill_guard.py)."""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GUARD = os.path.join(HERE, "skill_guard.py")
SID = "teste-skill-guard"


def call(mode: str, ev: dict) -> subprocess.CompletedProcess:
    ev = {"session_id": SID, **ev}
    return subprocess.run([sys.executable, GUARD, mode], input=json.dumps(ev), capture_output=True, text=True,
                          env={**os.environ, "CLAUDE_PROJECT_DIR": ROOT})


def pre(tool: str, **inp) -> int:
    return call("pre", {"tool_name": tool, "tool_input": inp}).returncode


fails = 0


def check(name: str, got, want) -> None:
    global fails
    ok = got == want
    fails += not ok
    print(("ok     " if ok else "FALHOU ") + f"{name} (obtido {got!r}, esperado {want!r})")


call("reset", {})
art = os.path.join(ROOT, "art/src/terrain/moon.py")
check("Write em art/ sem skill bloqueia", pre("Write", file_path=art), 2)
check("Edit em assets/ sem skill bloqueia", pre("Edit", file_path=os.path.join(ROOT, "assets/sprites/x.png")), 2)
check("Bash rodando script de arte bloqueia", pre("Bash", command="python3 art/src/sprites/lander.py"), 2)
check("Bash com sed -i em assets bloqueia", pre("Bash", command="sed -i '' s/a/b/ assets/sprites/lander.json"), 2)
check("Bash só lendo art/ passa", pre("Bash", command="ls art/src; cat art/src/sprites/lander.py"), 0)
check("Write em docs/ passa", pre("Write", file_path=os.path.join(ROOT, "docs/HANDOFF.md")), 0)
check("Edit em data/economy.json sem skill bloqueia", pre("Edit", file_path=os.path.join(ROOT, "data/economy.json")), 2)
check("Edit em game/ sem skill bloqueia", pre("Edit", file_path=os.path.join(ROOT, "game/main.gd")), 2)
check("Write em assets/audio exige sound-design", pre("Write", file_path=os.path.join(ROOT, "assets/audio/a.wav")), 2)
check("gdtool sem godot-dev bloqueia", pre("Bash", command="python3 .claude/skills/godot-dev/scripts/gdtool.py check"), 2)
check("Bash com caminho absoluto em assets bloqueia",
      pre("Bash", command=f"cp /tmp/x.png {ROOT}/assets/sprites/x.png"), 2)
check("git status passa", pre("Bash", command="git status --short"), 0)

call("mark", {"tool_name": "Skill", "tool_input": {"skill": "pixel-art"}})
check("Write em art/ com pixel-art passa", pre("Write", file_path=art), 0)
check("Bash de arte com pixel-art passa", pre("Bash", command="python3 art/src/sprites/lander.py"), 0)
check("assets/audio ainda exige sound-design", pre("Write", file_path=os.path.join(ROOT, "assets/audio/a.wav")), 2)
check("game/ ainda exige godot-dev", pre("Edit", file_path=os.path.join(ROOT, "game/main.gd")), 2)

r = call("prompt", {"prompt": "/godot-dev ajustar a cena"})
check("/godot-dev no prompt registra a skill", pre("Edit", file_path=os.path.join(ROOT, "game/main.gd")), 0)
r = call("prompt", {"prompt": "quero um som de explosão"})
check("prompt sobre som gera lembrete", "sound-design" in r.stdout, True)

call("reset", {})
check("após compactar, pixel-art precisa ser invocada de novo", pre("Write", file_path=art), 2)
call("reset", {})

print(f"\n{'TUDO OK' if not fails else f'{fails} FALHA(S)'}")
sys.exit(1 if fails else 0)
