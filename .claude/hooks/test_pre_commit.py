#!/usr/bin/env python3
"""Testa .githooks/pre-commit num clone descartável (rodar da raiz: python3 .claude/hooks/test_pre_commit.py)."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
fails = 0


def sh(*args: str, cwd: str) -> int:
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True).returncode


def commit(repo: str, msg: str, *paths: str) -> bool:
    sh("git", "add", *paths, cwd=repo)
    r = subprocess.run(["git", "commit", "-qm", msg], cwd=repo, capture_output=True, text=True)
    ok = r.returncode == 0
    if not ok:
        if "-v" in sys.argv:
            print(r.stderr)
        sh("git", "reset", "-q", cwd=repo)
    return ok


def check(name: str, got: bool, want: bool) -> None:
    global fails
    fails += got != want
    print(("ok     " if got == want else "FALHOU ") + f"{name} (commit {'aceito' if got else 'bloqueado'})")


with tempfile.TemporaryDirectory() as tmp:
    repo = os.path.join(tmp, "repo")
    subprocess.run(["git", "clone", "-q", ROOT, repo], check=True)
    os.makedirs(os.path.join(repo, ".githooks"), exist_ok=True)
    shutil.copy(os.path.join(ROOT, ".githooks", "pre-commit"), os.path.join(repo, ".githooks", "pre-commit"))
    sh("git", "config", "core.hooksPath", ".githooks", cwd=repo)
    from PIL import Image

    fake = os.path.join(repo, "assets/sprites/fake.png")
    Image.new("RGBA", (4, 4), (1, 2, 3, 255)).save(fake)
    check("PNG fora da paleta, sem fonte e sem padrão", commit(repo, "t1", "assets/sprites/fake.png"), False)
    os.remove(fake)

    lander = os.path.join(repo, "assets/sprites/lander.png")
    Image.open(lander).save(lander, optimize=True)
    check("PNG do lander (paleta ok, fonte e padrão com Fontes)", commit(repo, "t2", "assets/sprites/lander.png"), True)

    with open(os.path.join(repo, "data/economy.json"), "a") as f:
        f.write(" ")
    check("economy.json sem CHANGELOG", commit(repo, "t3", "data/economy.json"), False)
    with open(os.path.join(repo, "balance/CHANGELOG.md"), "a") as f:
        f.write("\n")
    check("economy.json com CHANGELOG e paridade ok", commit(repo, "t4", "data/economy.json", "balance/CHANGELOG.md"), True)

print(f"\n{'TUDO OK' if not fails else f'{fails} FALHA(S)'}")
sys.exit(1 if fails else 0)
