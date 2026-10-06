#!/usr/bin/env python3
"""Grava takes de trailer com o Movie Maker do Godot (tests/visual/trailer_director.tscn) e converte para MP4.

Cada take: frames 640x360 a 60 fps + audio do jogo -> MP4 1920x1080 (ampliacao inteira x3, pixels nitidos, H.264 + AAC)
e uma folha de quadros (para revisar sem abrir o video). Requer ffmpeg: `pip install imageio-ffmpeg` (ou no PATH).

  python3 tests/tools/trailer_capture.py --list                 # takes do roteiro (TAKES abaixo)
  python3 tests/tools/trailer_capture.py t01_lua_abertura ...   # grava so esses
  python3 tests/tools/trailer_capture.py --all [-j 2]          # grava todos (janelas do jogo abrem e fecham)
Saida: trailer/takes/<nome>.mp4 e trailer/takes/sheets/<nome>.png.
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCENE = "res://tests/visual/trailer_director.tscn"
OUT = os.path.join(ROOT, "trailer", "takes")
FPS = 60
STRONG = "--dev_levels=thrust:60,tank:30,efficiency:10,gear:10"
# janelas lado a lado (sobrepostas, o macOS "adormece" a de baixo e a gravacao congela)
SLOTS = ["0,40", "660,40", "0,440", "660,440"]

# nome: (argumentos do diretor, segundos gravados, corte inicial s, duracao final s)
TAKES: dict[str, tuple[list[str], float, float, float]] = {}


def take(name: str, args: str, rec: float, cut_in: float, dur: float) -> None:
    TAKES[name] = (args.split(), rec, cut_in, dur)


def ffmpeg() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        sys.exit("ffmpeg nao encontrado: pip install imageio-ffmpeg")


def godot() -> str:
    return shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot"


import queue
_free: "queue.Queue[str]" = queue.Queue()
for _s in SLOTS:
    _free.put(_s)


def record(name: str, tries: int = 2) -> str:
    slot = _free.get()
    try:
        out = ""
        for _ in range(tries):
            out = _record(name, slot)
            if "CONGELOU" not in out:
                break
        return out
    finally:
        _free.put(slot)


def _record(name: str, slot: str) -> str:
    args, rec, cut_in, dur = TAKES[name]
    tmp = tempfile.mkdtemp(prefix="take_")
    cmd = [godot(), "--path", ROOT, "--write-movie", os.path.join(tmp, "f.png"), "--fixed-fps", str(FPS),
           "--quit-after", str(int(rec * FPS)), "--resolution", "640x360", "--position", slot, "--always-on-top", SCENE, "--"] + args
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if "SCRIPT ERROR" in l or l.startswith("ERROR")
            and "resources still in use" not in l]
    frames = sorted(f for f in os.listdir(tmp) if f.endswith(".png"))
    if not frames:
        return f"{name}: FALHOU (sem quadros)\n" + (r.stdout + r.stderr)[-2000:]
    import hashlib
    hashes = [hashlib.md5(open(os.path.join(tmp, f), "rb").read()).hexdigest() for f in frames]
    longest, cur = 1, 1
    for h0, h1 in zip(hashes, hashes[1:]):
        cur = cur + 1 if h0 == h1 else 1
        longest = max(longest, cur)
    if longest > FPS * 1.5:                                    # quadros identicos demais: gravacao congelada
        shutil.rmtree(tmp, ignore_errors=True)
        return f"{name}: CONGELOU ({longest} quadros iguais)"
    os.makedirs(os.path.join(OUT, "sheets"), exist_ok=True)
    mp4 = os.path.join(OUT, f"{name}.mp4")
    wav = os.path.join(tmp, "f.wav")
    vin = ["-framerate", str(FPS), "-i", os.path.join(tmp, "f%08d.png")]
    ain = ["-i", wav] if os.path.exists(wav) else []
    enc = [ffmpeg(), "-y", "-loglevel", "error", *vin, *ain, "-ss", f"{cut_in}", "-t", f"{dur}",
           "-vf", "scale=1920:1080:flags=neighbor", "-c:v", "libx264", "-preset", "medium", "-crf", "14",
           "-pix_fmt", "yuv420p", "-movflags", "+faststart"]
    if ain:
        enc += ["-c:a", "aac", "-b:a", "192k", "-af", f"afade=t=in:st={cut_in}:d=0.15"]
    subprocess.run(enc + [mp4], check=True)
    _sheet(name, tmp, frames, cut_in, dur)
    shutil.rmtree(tmp, ignore_errors=True)
    return f"{name}: ok ({len(frames)} quadros){' ERROS: ' + ' | '.join(errs[:3]) if errs else ''}"


def _sheet(name: str, tmp: str, frames: list[str], cut_in: float, dur: float) -> None:
    from PIL import Image, ImageDraw
    a, b = int(cut_in * FPS), min(len(frames) - 1, int((cut_in + dur) * FPS))
    n = 8
    pick = [frames[a + (b - a) * i // (n - 1)] for i in range(n)]
    w, h = 640, 360
    sheet = Image.new("RGB", (4 * w, 2 * (h + 16)), (20, 16, 24))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(pick):
        x, y = (i % 4) * w, (i // 4) * (h + 16)
        sheet.paste(Image.open(os.path.join(tmp, f)).convert("RGB"), (x, y + 16))
        t = int(f[1:-4]) / FPS - cut_in
        d.text((x + 4, y + 2), f"{name}  t={t:.1f}s", fill=(230, 230, 230))
    sheet.save(os.path.join(OUT, "sheets", f"{name}.png"))


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("takes", nargs="*")
    p.add_argument("--all", action="store_true")
    p.add_argument("--list", action="store_true")
    p.add_argument("-j", type=int, default=1, help="gravacoes em paralelo (janelas sobrepostas podem congelar)")
    a = p.parse_args()
    if a.list:
        for k, v in TAKES.items():
            print(f"{k:28s} {v[3]:4.1f}s  {' '.join(v[0])}")
        return 0
    names = list(TAKES) if a.all else a.takes
    for n in names:
        if n not in TAKES:
            sys.exit(f"take desconhecido: {n}")
    with ThreadPoolExecutor(a.j) as ex:
        for line in ex.map(record, names):
            print(line, flush=True)
    return 0


# --- roteiro de takes ---------------------------------------------------------------------------------------------
# (args, gravado s, corte inicial s, duracao s). Nave forte (STRONG); seeds escolhidas na exploracao.
LUA = "--planet=luna"   # 2026-10-06: so a Lua (takes dos outros mundos estao no git)
CLEAN = "--no_hud"
take("t01_abertura_lua_guerra", f"{LUA} --seed=7 {STRONG} {CLEAN} --pad_wait=1.6 --hops=800:normal", 10, 0.4, 8.5)
take("t02_titulo_lua", "--world=luna", 6, 0.6, 5)
take("t06_escolha_entrega", f"{LUA} --seed=21 {STRONG} --offer_wait=2.2 --hops=700:tight", 8, 0.3, 6.5)
take("t07_cristais_no_arco", f"{LUA} --seed=7 {STRONG} --hops=1000:narrow", 9.5, 1.0, 8)
take("t08_pouso_estreita_lua", f"{LUA} --seed=7 {STRONG} --hops=1000:narrow", 15, 8.8, 6)
take("t14_batida_explosao", f"{LUA} --seed=7 {STRONG} {CLEAN} --no_summary --pilot=crash --hops=600:tight", 9, 3.0, 5.5)
take("t18_pouso_calmo_lua", f"{LUA} --seed=12 {STRONG} {CLEAN} --hops=500:normal", 12, 4.0, 7.5)


if __name__ == "__main__":
    sys.exit(main())
