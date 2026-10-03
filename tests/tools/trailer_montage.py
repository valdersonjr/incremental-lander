#!/usr/bin/env python3
"""Montagem bruta (referencia de ritmo) a partir dos takes de trailer/takes/: corta cada take no trecho indicado e
concatena na ordem sugerida em trailer/TAKES.md. Saida: trailer/montagem_sugerida.mp4 (1920x1080, 60 fps).
  python3 tests/tools/trailer_montage.py
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from trailer_capture import OUT, ROOT, ffmpeg  # noqa: E402

# (take, inicio s, fim s) — abertura -> exploracao -> gameplay -> variedade -> impacto -> climax -> encerramento
EDIT = [
    ("t01_abertura_lua_guerra", 0.0, 5.5), ("t02_titulo_lua", 0.0, 3.0),
    ("t03_silvania_voo", 1.0, 6.0), ("t04_docelandia_voo", 0.5, 5.5), ("t05_quarto_voo", 0.0, 5.0),
    ("t06_escolha_entrega", 0.0, 4.5), ("t07_cristais_no_arco", 0.5, 6.0), ("t08_pouso_estreita_lua", 2.5, 5.5),
    ("t10_rajada_silvania", 1.0, 6.0), ("t11_geiser_docelandia", 1.5, 6.0), ("t12_brinquedo_por_um_triz", 1.0, 5.5),
    ("t13_hangar_upgrades", 0.0, 5.0),
    ("t14_batida_explosao", 2.0, 5.5), ("t15_brinquedo_acerta", 0.5, 3.5),
    ("t09_combo_sequencia", 1.0, 8.0), ("t16_quarto_apertada_combo", 2.0, 9.0), ("t17_docelandia_numeros", 5.5, 9.0),
    ("t18_pouso_calmo_lua", 1.0, 7.0), ("t19_titulo_docelandia", 0.0, 5.0),
]


def main() -> int:
    ins, parts = [], []
    for i, (name, a, b) in enumerate(EDIT):
        ins += ["-i", os.path.join(OUT, f"{name}.mp4")]
        d = b - a
        parts.append(f"[{i}:v]trim={a}:{b},setpts=PTS-STARTPTS[v{i}];"
                     f"[{i}:a]atrim={a}:{b},asetpts=PTS-STARTPTS,afade=t=in:d=0.06,afade=t=out:st={d - 0.08}:d=0.08[a{i}];")
    n = len(EDIT)
    graph = "".join(parts) + "".join(f"[v{i}][a{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=1[v][a]"
    out = os.path.join(ROOT, "trailer", "montagem_sugerida.mp4")
    subprocess.run([ffmpeg(), "-y", "-loglevel", "error", *ins, "-filter_complex", graph, "-map", "[v]", "-map", "[a]",
                    "-c:v", "libx264", "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p", "-c:a", "aac",
                    "-b:a", "192k", "-movflags", "+faststart", out], check=True)
    print(out, f"{sum(b - a for _, a, b in EDIT):.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
