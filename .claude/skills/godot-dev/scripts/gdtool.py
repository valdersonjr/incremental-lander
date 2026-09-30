#!/usr/bin/env python3
"""
gdtool.py - verificacao do projeto Godot sem abrir o editor (usado pela skill godot-dev).

Rodar da raiz do projeto (onde esta project.godot):

  python3 .claude/skills/godot-dev/scripts/gdtool.py api CharacterBody2D [move_and_collide]
      Referencia da API da versao INSTALADA (gera cache com --doctool na 1a vez).
  python3 .claude/skills/godot-dev/scripts/gdtool.py check [arquivo.gd ...]
      Reimporta (atualiza class_name) e checa a sintaxe/tipos de todos os .gd (em paralelo).
  python3 .claude/skills/godot-dev/scripts/gdtool.py test
      Roda tests/run_tests.gd (unitarios) + tests/test_econ_parity.py (se existir).
  python3 .claude/skills/godot-dev/scripts/gdtool.py run res://scenes/x.tscn [--frames 300] [-- args do jogo]
      Roda a cena sem janela por N frames; falha se houver ERROR/SCRIPT ERROR (warnings listados).
  python3 .claude/skills/godot-dev/scripts/gdtool.py capture res://scenes/x.tscn [--frames 180] [--every 30]
                                                             [--scale 2] [--out DIR] [-- args do jogo]
      Grava frames reais (Movie Maker, abre janela ~1-3 s), monta folha de contato para revisar com Read.

Codigos de saida: 0 = ok, 1 = falhou (erros encontrados), 2 = uso errado / Godot nao encontrado.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

GODOT = os.environ.get("GODOT_BIN") or shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot"
ERR_RE = re.compile(r"^(SCRIPT ERROR|ERROR|USER ERROR|Parse Error)", re.M)
WARN_RE = re.compile(r"^(WARNING|USER WARNING)", re.M)
NOISE = ("Godot Engine v", "OpenGL API", "Vulkan", "Metal", "--- Debugging process", "Using ")


def die(msg: str, code: int = 2) -> None:
    print(msg, file=sys.stderr)
    sys.exit(code)


def project_root() -> str:
    d = os.getcwd()
    while d != os.path.dirname(d):
        if os.path.exists(os.path.join(d, "project.godot")):
            return d
        d = os.path.dirname(d)
    die("project.godot nao encontrado (rode da raiz do projeto)")


def godot(args: list[str], timeout: int = 300, cwd: str | None = None) -> subprocess.CompletedProcess:
    if not (os.path.exists(GODOT) or shutil.which(GODOT)):
        die(f"Godot nao encontrado ({GODOT}). Defina GODOT_BIN.")
    return subprocess.run([GODOT] + args, capture_output=True, text=True, timeout=timeout, cwd=cwd)


def clean(out: str) -> str:
    return "\n".join(l for l in out.splitlines() if l.strip() and not l.startswith(NOISE))


def godot_version() -> str:
    return godot(["--version"]).stdout.strip()


# ---------------------------------------------------------------- api
def api_dir() -> str:
    ver = godot_version().replace("/", "_") or "unknown"
    d = os.path.expanduser(f"~/.cache/godot-api/{ver}")
    if not os.path.isdir(os.path.join(d, "doc", "classes")):
        os.makedirs(d, exist_ok=True)
        godot(["--headless", "--doctool", d], timeout=120, cwd=tempfile.gettempdir())
    return d


def find_class_xml(name: str) -> str | None:
    root = api_dir()
    for dp, _, files in os.walk(root):
        if f"{name}.xml" in files:
            return os.path.join(dp, f"{name}.xml")
    return None


def _sig(m: ET.Element) -> str:
    ret = m.find("return")
    args = [f"{a.get('name')}: {a.get('type')}" + (f" = {a.get('default')}" if a.get("default") else "")
            for a in m.findall("param")]
    q = m.get("qualifiers") or ""
    return f"{m.get('name')}({', '.join(args)}) -> {ret.get('type') if ret is not None else 'void'} {q}".strip()


def cmd_api(a) -> int:
    path = find_class_xml(a.cls)
    if not path:
        die(f"classe '{a.cls}' nao existe na API {godot_version()}", 1)
    c = ET.parse(path).getroot()
    txt = lambda e: re.sub(r"\s+", " ", (e.text or "") if e is not None else "").strip()
    if a.member:
        found = False
        for tag in ("method", "member", "signal", "constant"):
            for e in c.iter(tag):
                if e.get("name") == a.member:
                    found = True
                    head = _sig(e) if tag in ("method", "signal") else f"{e.get('name')}: {e.get('type', '')} = {e.get('default', e.get('value', ''))}"
                    print(f"[{tag}] {a.cls}.{head}\n  {txt(e.find('description')) or txt(e)}"[:3000])
        if not found:
            die(f"'{a.member}' nao encontrado em {a.cls} (procure na classe base: {c.get('inherits')})", 1)
        return 0
    print(f"{a.cls} (herda de {c.get('inherits')}) — {txt(c.find('brief_description'))}  [{godot_version()}]")
    ms = c.find("methods")
    if ms is not None:
        print("\nmetodos:")
        for m in ms:
            print("  " + _sig(m))
    mb = c.find("members")
    if mb is not None:
        print("\npropriedades:")
        for m in mb:
            print(f"  {m.get('name')}: {m.get('type')} = {m.get('default')}")
    sg = c.find("signals")
    if sg is not None:
        print("\nsinais:")
        for s in sg:
            print("  " + _sig(s).replace(" -> void", ""))
    return 0


# ---------------------------------------------------------------- check
def gd_files(root: str, only: list[str]) -> list[str]:
    if only:
        return [os.path.relpath(os.path.abspath(p), root) for p in only]
    out = []
    for dp, dns, fs in os.walk(root):
        rel = os.path.relpath(dp, root)
        if rel.startswith((".godot", ".claude", ".git", "addons")) or os.path.exists(os.path.join(dp, ".gdignore")):
            dns[:] = []
            continue
        out += [os.path.relpath(os.path.join(dp, f), root) for f in fs if f.endswith(".gd")]
    return sorted(out)


def _section(path: str, name: str) -> str:
    txt = open(path).read()
    m = re.search(r"^\[%s\]\s*$(.*?)(?=^\[|\Z)" % re.escape(name), txt, re.M | re.S)
    return m.group(1) if m else ""


def cmd_check(a) -> int:
    root = project_root()
    imp = godot(["--headless", "--path", root, "--import"], timeout=600)
    imp_err = [l for l in clean(imp.stdout + imp.stderr).splitlines() if ERR_RE.match(l)]
    files = gd_files(root, a.files)

    def one(f):
        r = godot(["--headless", "--path", root, "--script", "res://" + f, "--check-only"], timeout=120)
        return f, clean(r.stdout + r.stderr)

    # --check-only roda isolado: autoloads nao existem -> "Identifier not found: <Autoload>" e erros em
    # cascata sao falsos positivos (em execucao real funcionam). Ignora esses; o resto e erro de verdade.
    autoloads = set(re.findall(r"^(\w+)=", _section(os.path.join(root, "project.godot"), "autoload"), re.M))
    fake = re.compile(r"Identifier not found: (%s)\b|Failed to compile depended scripts|Failed to load script"
                      % "|".join(map(re.escape, autoloads))) if autoloads else re.compile(r"$^")

    bad = 0
    with cf.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
        for f, out in ex.map(one, files):
            errs = [l for l in out.splitlines() if ERR_RE.match(l.strip()) or l.strip().startswith("at:")]
            real = [l for l in errs if ERR_RE.match(l.strip()) and not fake.search(l)]
            if real:
                bad += 1
                print(f"ERRO {f}\n  " + "\n  ".join(errs[:12]))
    for l in imp_err:
        print("IMPORT", l)
    print(f"{len(files)} scripts checados, {bad} com erro" + (f", {len(imp_err)} erros de import" if imp_err else ""))
    return 1 if (bad or imp_err) else 0


# ---------------------------------------------------------------- test
def cmd_test(a) -> int:
    root = project_root()
    rc = 0
    if os.path.exists(os.path.join(root, "tests", "run_tests.gd")):
        godot(["--headless", "--path", root, "--import"], timeout=600)
        # stderr junto do stdout NA ORDEM real (para saber qual teste gerou cada erro)
        r = subprocess.run([GODOT, "--headless", "--path", root, "--script", "res://tests/run_tests.gd"],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=600)
        out = clean(r.stdout)
        # GDScript nao tem try/catch: um teste que aborta por erro de script nao chama assert e o executor
        # imprime "ok". Aqui, erros de script vistos antes de um "ok" marcam aquele teste como FALHOU.
        lines, pending, script_fails = [], [], 0
        for l in out.splitlines():
            if ERR_RE.match(l.strip()):
                pending.append(l.strip())
                continue
            if l.startswith("ok ") and pending:
                lines.append(l.replace("ok ", "FALHOU (erro de script) ", 1) + "\n    " + "\n    ".join(pending[:4]))
                pending, script_fails = [], script_fails + 1
                continue
            if l.strip().startswith(("at:", "GDScript backtrace", "[")):
                continue
            lines.append(l)
        lines += [f"ERRO sem teste associado: {p}" for p in pending]
        if script_fails:
            lines.append(f"!! {script_fails} teste(s) abortaram por erro de script (contados como falha)")
        print("\n".join(lines))
        if r.returncode != 0 or "FALHOU" in out or ERR_RE.search(out):
            rc = 1
    # testes de integracao: cenas em tests/integration/ que imprimem "<NOME>_TEST OK" (ou FALHOU) e saem
    integ = os.path.join(root, "tests", "integration")
    if os.path.isdir(integ):
        for f in sorted(os.listdir(integ)):
            if not f.endswith(".tscn"):
                continue
            r = godot(["--headless", "--path", root, "--fixed-fps", "60", f"res://tests/integration/{f}",
                       "--quit-after", "600", "--", "--no_save"], timeout=300)
            out = clean(r.stdout + r.stderr)
            ok = re.search(r"_TEST OK", out) is not None
            errs = [l for l in out.splitlines() if ERR_RE.match(l.strip())]
            print(("ok     " if ok and not errs else "FALHOU ") + f"integracao {f}" +
                  ("" if ok else "\n    " + "\n    ".join((re.findall(r".*_TEST.*", out) + errs)[:4])))
            if not ok or errs:
                rc = 1
    parity = os.path.join(root, "tests", "test_econ_parity.py")
    if os.path.exists(parity):
        p = subprocess.run([sys.executable, parity], capture_output=True, text=True, cwd=root, timeout=600)
        print(p.stdout.strip() or p.stderr.strip())
        rc = rc or p.returncode
    return rc


# ---------------------------------------------------------------- run
def cmd_run(a) -> int:
    root = project_root()
    # --fixed-fps: sem ele, em headless os frames correm mais rapido que a fisica (N frames != N/60 s de jogo)
    args = ["--headless", "--path", root, "--fixed-fps", "60", a.scene, "--quit-after", str(a.frames)]
    if a.game_args:
        args += ["--"] + a.game_args
    r = godot(args, timeout=a.timeout)
    out = clean(r.stdout + r.stderr)
    errs = [l for l in out.splitlines() if ERR_RE.match(l.strip())]
    warns = [l for l in out.splitlines() if WARN_RE.match(l.strip())]
    if a.verbose or errs:
        print(out[-6000:])
    else:
        print("\n".join(l for l in out.splitlines()[-40:]))
    print(f"--- {a.scene}: {a.frames} frames, {len(errs)} erros, {len(warns)} warnings")
    return 1 if errs else 0


# ---------------------------------------------------------------- capture
def cmd_capture(a) -> int:
    from PIL import Image, ImageDraw
    root = project_root()
    tmp = tempfile.mkdtemp(prefix="gdcap_")
    # --always-on-top: no macOS uma janela coberta pode ser "adormecida" e a gravacao congela
    args = ["--path", root, "--write-movie", os.path.join(tmp, "f.png"), "--fixed-fps", str(a.fps),
            "--quit-after", str(a.frames), "--resolution", a.resolution, "--always-on-top", a.scene]
    if a.game_args:
        args += ["--"] + a.game_args
    r = godot(args, timeout=a.timeout)
    out = clean(r.stdout + r.stderr)
    errs = [l for l in out.splitlines() if ERR_RE.match(l.strip())]
    frames = sorted(f for f in os.listdir(tmp) if f.endswith(".png"))
    if not frames:
        print(out[-4000:])
        die("nenhum frame gravado", 1)
    # detector de congelamento: muitos quadros identicos seguidos = gravacao nao confiavel
    import hashlib
    hashes = [hashlib.md5(open(os.path.join(tmp, f), "rb").read()).hexdigest() for f in frames]
    longest, cur = 1, 1
    for h0, h1 in zip(hashes, hashes[1:]):
        cur = cur + 1 if h0 == h1 else 1
        longest = max(longest, cur)
    frozen = longest > a.fps * 3
    pick = frames[::max(1, a.every)]
    if frames[-1] not in pick:
        pick.append(frames[-1])
    out_dir = a.out or os.path.join(root, ".godot", "captures")
    os.makedirs(out_dir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(a.scene))[0]
    ims = [Image.open(os.path.join(tmp, f)).convert("RGB") for f in pick]
    w, h = ims[0].size
    s = a.scale
    cols = min(len(ims), a.cols)
    rows = (len(ims) + cols - 1) // cols
    pad = 18
    sheet = Image.new("RGB", (cols * w * s, rows * (h * s + pad)), (20, 16, 24))
    d = ImageDraw.Draw(sheet)
    for i, (im, f) in enumerate(zip(ims, pick)):
        x, y = (i % cols) * w * s, (i // cols) * (h * s + pad)
        sheet.paste(im.resize((w * s, h * s), Image.NEAREST), (x, y + pad))
        n = int(re.sub(r"\D", "", f) or 0)
        d.text((x + 4, y + 3), f"frame {n}  t={n / a.fps:.2f}s", fill=(230, 230, 230))
    sheet_path = os.path.join(out_dir, f"{stem}_sheet.png")
    sheet.save(sheet_path)
    last = os.path.join(out_dir, f"{stem}_last.png")
    ims[-1].resize((w * s, h * s), Image.NEAREST).save(last)
    shutil.rmtree(tmp, ignore_errors=True)
    for l in errs:
        print("ERRO", l)
    print(f"{len(frames)} frames gravados; folha: {sheet_path}\nultimo frame: {last}")
    if frozen:
        print(f"AVISO: {longest} quadros identicos seguidos (> 3 s) — a gravacao provavelmente congelou "
              f"(janela coberta/segundo plano no macOS). NAO confie nesta folha: refaca a captura.")
    return 1 if (errs or frozen) else 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = p.add_subparsers(dest="cmd", required=True)
    s = sp.add_parser("api"); s.add_argument("cls"); s.add_argument("member", nargs="?")
    s = sp.add_parser("check"); s.add_argument("files", nargs="*")
    sp.add_parser("test")
    for name in ("run", "capture"):
        s = sp.add_parser(name)
        s.add_argument("scene")
        s.add_argument("--frames", type=int, default=300 if name == "run" else 180)
        s.add_argument("--timeout", type=int, default=300)
        s.add_argument("game_args", nargs="*", help="argumentos do jogo (depois de --)")
        if name == "run":
            s.add_argument("-v", "--verbose", action="store_true")
        else:
            s.add_argument("--every", type=int, default=30)
            s.add_argument("--fps", type=int, default=60)
            s.add_argument("--scale", type=int, default=2)
            s.add_argument("--cols", type=int, default=3)
            s.add_argument("--resolution", default="640x360")
            s.add_argument("--out")
    a = p.parse_args()
    return {"api": cmd_api, "check": cmd_check, "test": cmd_test, "run": cmd_run, "capture": cmd_capture}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
