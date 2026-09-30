#!/usr/bin/env python3
"""Trava da Regra 0 (CLAUDE.md): nenhuma operação numa área do projeto sem a skill dela invocada.

Chamado pelos hooks do Claude Code (.claude/settings.json) com o JSON do evento no stdin:
  mark     PostToolUse(Skill)      -> registra a skill invocada nesta sessão
  prompt   UserPromptSubmit        -> "/pixel-art ..." também registra; palavras-chave geram lembrete
  pre      PreToolUse(Write|Edit|NotebookEdit|Bash) -> bloqueia (exit 2) se a skill da área não foi invocada
  reset    SessionStart(compact|clear) -> apaga os registros (após perder contexto, reler as skills)

Registros: .claude/hooks/.state/<session_id> (uma skill por linha; pasta ignorada pelo git).
Teste manual: python3 .claude/hooks/test_skill_guard.py
"""
import json
import os
import re
import sys

ROOT = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STATE_DIR = os.path.join(ROOT, ".claude", "hooks", ".state")

# Área -> skill. Ordem importa: a primeira regra que casar vence (economia antes de godot em scripts/economy).
FILE_RULES = [
    ("sound-design", re.compile(r"^(audio/|assets/audio/)")),
    ("pixel-art", re.compile(r"^(art/|assets/)")),
    ("economy-balance", re.compile(r"^(data/economy\.json$|balance/|scripts/economy/)")),
    ("godot-dev", re.compile(r"^(game/|scripts/|autoload/|tests/|data/world\.json$|project\.godot$|default_bus_layout\.tres$)")),
]

# Bash: ferramentas das skills (qualquer uso exige a skill)...
BASH_TOOLS = [
    ("sound-design", re.compile(r"soundkit\.py|python3?\s+\S*audio/src/")),
    ("pixel-art", re.compile(r"pixelart\.py|python3?\s+(\./)?art/src/")),
    ("economy-balance", re.compile(r"econ\.py|balance/sims/|test_econ_parity")),
    ("godot-dev", re.compile(r"gdtool\.py|(^|[\s;&|(])godot(\s|$)")),
]
# ...e caminhos da área quando o comando escreve/move/apaga algo.
BASH_WRITES = re.compile(r">|\btee\b|sed\s+-i|\bmv\b|\bcp\b|\brm\b|\bmkdir\b|\btouch\b|\bpython3?\b|\bperl\b|\bdd\b|\binstall\b|\bln\b|\bchmod\b")
BASH_PATHS = [
    ("sound-design", re.compile(r"(^|[\s'\"=/])(audio/|assets/audio)")),
    ("pixel-art", re.compile(r"(^|[\s'\"=])(\./)?(art/|assets/(?!audio))")),
    ("economy-balance", re.compile(r"data/economy\.json|(^|[\s'\"=])(\./)?(balance/|scripts/economy/)")),
    ("godot-dev", re.compile(r"(^|[\s'\"=])(\./)?(game/|scripts/(?!economy)|autoload/|tests/|project\.godot|data/world\.json)|\.(gd|tscn)\b")),
]

KEYWORDS = [
    ("pixel-art", r"\b(arte|sprite|pixel|tile|tileset|textura|fundo|parallax|[ií]cone|imagem|anima[çc][ãa]o|explos[ãa]o|visual|paleta|fonte pixel|hud|ui|interface|tela)\b"),
    ("sound-design", r"\b(som|sons|[áa]udio|m[úu]sica|sfx|efeito sonoro|ru[íi]do|trilha|ambi[êe]ncia)\b"),
    ("economy-balance", r"\b(economia|pre[çc]o|custo|upgrade|pr[ée]stigio|balance|balancear|ritmo|progress[ãa]o|pagamento)\b"),
    ("godot-dev", r"\b(c[óo]digo|cena|godot|bug|script|save|teste|gdscript|controle)\b"),
]


def _state_path(session_id: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id or "sem_sessao")
    return os.path.join(STATE_DIR, safe)


def _marked(session_id: str) -> set:
    try:
        with open(_state_path(session_id)) as f:
            return {line.strip() for line in f if line.strip()}
    except FileNotFoundError:
        return set()


def _mark(session_id: str, skill: str) -> None:
    os.makedirs(STATE_DIR, exist_ok=True)
    if skill not in _marked(session_id):
        with open(_state_path(session_id), "a") as f:
            f.write(skill + "\n")


def _rel(path: str) -> str:
    path = os.path.normpath(path)
    if os.path.isabs(path):
        path = os.path.relpath(path, ROOT)
    return path.replace(os.sep, "/")


def required_for_file(path: str) -> set:
    rel = _rel(path)
    if rel.startswith(".."):
        return set()
    for skill, rx in FILE_RULES:
        if rx.search(rel):
            return {skill}
    if rel.endswith((".gd", ".tscn")):
        return {"godot-dev"}
    return set()


def required_for_bash(cmd: str) -> set:
    cmd = cmd.replace(ROOT.rstrip("/") + "/", "")  # caminhos absolutos do projeto viram relativos
    need = {skill for skill, rx in BASH_TOOLS if rx.search(cmd)}
    if BASH_WRITES.search(cmd):
        need |= {skill for skill, rx in BASH_PATHS if rx.search(cmd)}
    return need


def _block(missing: set, what: str) -> int:
    names = ", ".join(f"`{s}`" for s in sorted(missing))
    sys.stderr.write(
        f"BLOQUEADO pela Regra 0 (CLAUDE.md): {what} pertence à área da(s) skill(s) {names}, "
        f"que não foi(ram) invocada(s) nesta sessão (ou o contexto foi compactado). "
        f"Invoque a skill com a ferramenta Skill, leia o SKILL.md e siga o fluxo dela; depois repita a ação.\n")
    return 2


def cmd_pre(ev: dict) -> int:
    tool = ev.get("tool_name", "")
    inp = ev.get("tool_input", {}) or {}
    if tool == "Bash":
        need = required_for_bash(inp.get("command", ""))
        what = "este comando"
    else:
        path = inp.get("file_path") or inp.get("notebook_path") or ""
        need = required_for_file(path) if path else set()
        what = f"o arquivo {_rel(path)}" if path else ""
    missing = need - _marked(ev.get("session_id", ""))
    return _block(missing, what) if missing else 0


def cmd_mark(ev: dict) -> int:
    skill = str((ev.get("tool_input") or {}).get("skill", ""))
    skill = skill.split(":")[-1].strip().lstrip("/")
    if skill:
        _mark(ev.get("session_id", ""), skill)
    return 0


def cmd_prompt(ev: dict) -> int:
    prompt = ev.get("prompt", "") or ""
    sid = ev.get("session_id", "")
    m = re.match(r"\s*/([\w:-]+)", prompt)
    if m:  # o usuário invocou a skill direto (/pixel-art ...)
        _mark(sid, m.group(1).split(":")[-1])
    low = prompt.lower()
    hits = [s for s, rx in KEYWORDS if re.search(rx, low) and s not in _marked(sid)]
    if hits:
        names = ", ".join(f"`{s}`" for s in hits)
        print(f"Lembrete automático (Regra 0 do CLAUDE.md): este pedido parece envolver {names}. "
              f"Antes de agir nessas áreas, invoque a(s) skill(s) com a ferramenta Skill e siga o fluxo. "
              f"Um hook bloqueia edições em art/, assets/, audio/, data/economy.json, game/ etc. sem a skill.")
    return 0


def cmd_reset(ev: dict) -> int:
    try:
        os.remove(_state_path(ev.get("session_id", "")))
    except FileNotFoundError:
        pass
    return 0


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        ev = json.load(sys.stdin)
    except Exception:
        ev = {}
    handler = {"pre": cmd_pre, "mark": cmd_mark, "prompt": cmd_prompt, "reset": cmd_reset}.get(mode)
    return handler(ev) if handler else 0


if __name__ == "__main__":
    sys.exit(main())
