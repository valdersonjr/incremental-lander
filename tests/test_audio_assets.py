"""Teste dos assets de áudio (auditoria de som v2, 2026-10-09). Mede todo WAV de assets/audio/ e confere:
  - loudness da categoria (±1 LU), true peak abaixo do teto, nenhuma amostra clipada;
  - one-shots: duração máxima da categoria, sem silêncio no começo, sem corte no fim;
  - sons frequentes: pouco agudo (> 5 kHz) e audíveis no alto-falante de notebook (perda ao tirar < 200 Hz);
  - música e ambiência: o grave não pode ser o único lugar onde a faixa existe (mesma medida);
  - todo caminho res://assets/audio citado no código existe e todo WAV é usado (exceto os guardados de propósito);
  - o limitador web (web/audio_limiter.js) está igual no html/head_include do preset Web (export_presets.cfg).
Rodar da raiz: python3 tests/test_audio_assets.py   (≈ 6 s, em paralelo). Sai com código 1 se algo falhar.
"""
import glob
import os
import re
import sys
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, ".claude/skills/sound-design/scripts")
import numpy as np
import soundfile as sf
from soundkit import LOUDNESS_TARGETS, highpass, lufs, true_peak_db

AUDIO = "assets/audio"
JINGLES = {"delivered", "milestone", "unlock", "goal", "world_arrive", "summary_end", "record", "world_complete",
           "road_stop", "part_step"}
LOOPS = {"thruster_loop", "rcs_loop", "gas_alarm", "ice_slide", "wind_loop", "bubbles_loop"}
IMPACTS = {"crash"}
LAYER_LUFS = -24.0                      # camadas de mundo: 6 dB abaixo do voo (soundtrack.py, LAYER_LUFS)
# guardados de propósito (não tocam hoje): a explosão antiga, trocada pela batida fofa (crash_soft)
UNUSED_OK = {"sfx/crash.wav"}
# tocam muitas vezes por minuto: agudo controlado e audíveis em notebook
FREQUENT = re.compile(r"^(ui/.*|sfx/(landing_\d+|landing_heavy|delivered|crystal_\d|perfect|road_stop|sheep_\d|boing_\d|pass_\d|"
                      r"bump|star|gift_coin|thruster_\w+|sputter|aboard|retry))\.wav$")
MAX_HI_PCT = 15.0                       # % da energia acima de 5 kHz (som frequente)
MAX_LOSS_FREQUENT_DB = 5.0              # perda de loudness ao tirar < 200 Hz (alto-falante de notebook)
MAX_LOSS_TRACK_DB = 4.5                 # música e ambiência
TAIL_DB = -40.0                         # nível das últimas amostras de um one-shot (sem corte)
LEAD_MS = 10.0                          # silêncio máximo antes do ataque


def kind_of(rel: str) -> str:
    folder, name = rel.split("/")[0], os.path.basename(rel)[:-4]
    if folder in ("ui", "ambience", "music"):
        return folder
    if name in JINGLES:
        return "jingle"
    if name in LOOPS:
        return "loop"
    return "impact" if name in IMPACTS else "sfx"


def measure(path: str) -> dict:
    rel = os.path.relpath(path, AUDIO)
    x, sr = sf.read(path, always_2d=True)
    mono = x.mean(axis=1)
    sig = x if x.shape[1] > 1 else mono
    kind = kind_of(rel)
    a, _ = lufs(mono)
    b, _ = lufs(highpass(mono, 200))
    spec = np.abs(np.fft.rfft(mono)) ** 2
    f = np.fft.rfftfreq(len(mono), 1 / sr)
    absm = np.abs(mono)
    return {"rel": rel, "kind": kind, "dur": len(mono) / sr, "lufs": lufs(sig)[0], "tp": true_peak_db(sig),
            "clip": int((np.abs(x) >= 0.9999).sum()), "hi": 100 * spec[f > 5000].sum() / spec.sum(),
            "loss": b - a, "lead_ms": 1000 * int(np.argmax(absm > 1e-3)) / sr,
            "tail_db": 20 * np.log10(max(float(absm[-64:].max()), 1e-12))}


def check(m: dict) -> list[str]:
    rel, kind = m["rel"], m["kind"]
    t = LOUDNESS_TARGETS[kind]
    target = LAYER_LUFS if os.path.basename(rel).startswith("layer_") else t["lufs"]
    errs = []
    if abs(m["lufs"] - target) > 1.0:
        errs.append(f"loudness {m['lufs']:.1f} LUFS (alvo {target:.0f} ±1, {kind})")
    if m["tp"] > t["peak"] + 0.1:
        errs.append(f"true peak {m['tp']:.1f} dBTP > {t['peak']:.0f}")
    if m["clip"]:
        errs.append(f"{m['clip']} amostras clipadas")
    one_shot = kind not in ("loop", "ambience", "music")
    if one_shot:
        if t["max_dur"] and m["dur"] > t["max_dur"] + 0.01:
            errs.append(f"duração {m['dur']:.2f} s > {t['max_dur']} s")
        if m["lead_ms"] > LEAD_MS:
            errs.append(f"silêncio inicial {m['lead_ms']:.0f} ms")
        if m["tail_db"] > TAIL_DB:
            errs.append(f"corte no fim ({m['tail_db']:.0f} dB)")
    if FREQUENT.match(rel):
        if m["hi"] > MAX_HI_PCT:
            errs.append(f"agudo {m['hi']:.0f}% > {MAX_HI_PCT:.0f}% (som frequente: fadiga)")
        if m["loss"] < -MAX_LOSS_FREQUENT_DB:
            errs.append(f"some no notebook: perde {-m['loss']:.1f} dB sem o grave (máx {MAX_LOSS_FREQUENT_DB})")
    if kind in ("music", "ambience") and m["loss"] < -MAX_LOSS_TRACK_DB:
        errs.append(f"faixa só de grave: perde {-m['loss']:.1f} dB no notebook (máx {MAX_LOSS_TRACK_DB})")
    return errs


def references() -> tuple[set[str], set[str]]:
    """Caminhos citados no código (literais + padrões de camada/ambiência) e os que não existem."""
    cited: set[str] = set()
    for src in glob.glob("**/*.gd", recursive=True) + glob.glob("**/*.tscn", recursive=True) + \
            glob.glob("**/*.tres", recursive=True):
        if src.startswith((".godot", "builds", "addons")):
            continue
        cited |= set(re.findall(r"res://assets/audio/[\w/]+\.wav", open(src, encoding="utf-8").read()))
    cited = {c.removeprefix("res://assets/audio/") for c in cited}
    missing = {c for c in cited if not os.path.exists(f"{AUDIO}/{c}")}
    # Sound monta estes por nome do mundo (LAYER_DIR / AMBIENCE_DIR): todos os arquivos dessas famílias valem
    cited |= {os.path.relpath(p, AUDIO) for p in glob.glob(f"{AUDIO}/music/layer_*.wav")}
    cited |= {os.path.relpath(p, AUDIO) for p in glob.glob(f"{AUDIO}/ambience/*.wav")}
    return cited, missing


def web_limiter_ok() -> bool:
    """O preset Web injeta o limitador do Master (modo Sample não tem efeito de bus): igual à fonte única.
    Sem preset Web no export_presets.cfg (ele pode não estar versionado), não há o que conferir."""
    src = open("web/audio_limiter.js", encoding="utf-8").read()
    cfg = open("export_presets.cfg", encoding="utf-8").read() if os.path.exists("export_presets.cfg") else ""
    if 'platform="Web"' not in cfg:
        print("aviso: sem preset Web em export_presets.cfg — limitador web não conferido")
        return True
    want = '<script>\n' + src.replace("\\", "\\\\").replace('"', '\\"') + "</script>"
    return f'html/head_include="{want}"' in cfg


def main() -> int:
    files = sorted(glob.glob(f"{AUDIO}/**/*.wav", recursive=True))
    with ProcessPoolExecutor() as ex:
        rows = list(ex.map(measure, files))
    fails = 0
    for m in rows:
        errs = [] if m["rel"] in UNUSED_OK else check(m)       # guardado: não toca, não entra na mixagem
        fails += bool(errs)
        status = "FALHOU" if errs else "ok    "
        print(f"{status} {m['rel']:28} {m['kind']:8} {m['lufs']:6.1f} LUFS {m['tp']:5.1f} dBTP "
              f"agudo {m['hi']:4.1f}% notebook {m['loss']:5.1f} dB" + (" | " + "; ".join(errs) if errs else ""))
    cited, missing = references()
    for c in sorted(missing):
        print(f"FALHOU referência quebrada: res://assets/audio/{c}")
    unused = {m["rel"] for m in rows} - cited - UNUSED_OK
    for u in sorted(unused):
        print(f"FALHOU arquivo sem uso: assets/audio/{u}")
    fails += len(missing) + len(unused)
    if not web_limiter_ok():
        print("FALHOU limitador web: html/head_include do preset Web difere de web/audio_limiter.js")
        fails += 1
    print(f"\n{len(rows)} arquivos de áudio, {len(missing)} referências quebradas, {len(unused)} sem uso, "
          f"{fails} falhas")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
