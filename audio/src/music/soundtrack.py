"""Trilha (padrão: patterns/soundtrack.md). Duas faixas em loop, estéreo, -18 LUFS (o bus Music fica -6 dB no jogo):
  title  — menu inicial e hangar: D maior, 84 BPM, 16 compassos. Pad + sino FM esparso + baixo triângulo, sem bateria
           (calma: o jogador passa muito tempo no hangar; nada de melodia gritante).
  flight — voo: D lídio, 100 BPM, 16 compassos A A' B A''. Arpejo com eco pingue-pongue, pad, baixo, bumbo e chimbal leves;
           melodia de pulso só na volta (variação), para não cansar em horas de jogo.
Rodar da raiz: python3 audio/src/music/soundtrack.py [--export] [title flight]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

STEPS = 16  # passos por compasso (4/4, semicolcheias)


def held(token: str, bars: float) -> str:
    """Nota/acorde sustentado por `bars` compassos."""
    n = int(bars * STEPS)
    return " ".join([token] + ["-"] * (n - 1))


def rest(bars: float) -> str:
    return " ".join(["."] * int(bars * STEPS))


def arp_bar(notes: list[str], pattern: tuple[int, ...] = (0, 1, 2, 3, 2, 1, 2, 3)) -> str:
    """Um compasso de arpejo em colcheias (8 notas, cada uma = 2 passos)."""
    return " ".join(f"{notes[i]} -" for i in pattern)


# --- título / hangar ----------------------------------------------------------------------------------------------

def title() -> np.ndarray:
    song = Song(bpm=84, bars=16)
    prog = ["D3+F#3+A3+C#4", "B2+D3+F#3+A3", "G2+B2+D3+F#3", "A2+C#3+E3+B3"]   # Dmaj7 Bm7 Gmaj7 A(add9)
    song.add("pad", inst_pad(voices=4, detune=12, cutoff=1500, a=0.9, r=1.6),
             " ".join(held(c, 2) for c in prog * 2), gain_db=-7)
    roots = ["D2", "B1", "G1", "A1"]
    bass = " ".join(" ".join([held(r, 0.5), held(r, 0.5), held(r, 0.5), held(r if r != "A1" else "E2", 0.5)])
                    for r in roots) * 1
    song.add("baixo", inst_triangle_bass(r=0.3), " ".join([bass, bass]), gain_db=-8)
    # sino: motivo de 8 compassos na pentatônica, respondido com variação (A A')
    m1 = " ".join([held("F#5", 0.75), held("A5", 0.25), held("E5", 1), rest(1), held("D5", 0.5), held("E5", 0.5),
                   held("B4", 1), rest(1), held("A4", 0.5), held("B4", 0.5), held("D5", 2)])
    m2 = " ".join([held("F#5", 0.75), held("A5", 0.25), held("B5", 1), rest(1), held("A5", 0.5), held("F#5", 0.5),
                   held("E5", 1), rest(1), held("D5", 0.5), held("E5", 0.5), held("D5", 2)])
    song.add("sino", inst_bell(ratio=3.5, index=2.2, tau=0.9), " ".join([m1, m2]), gain_db=-12,
             fx=lambda x: delay(x, time=60 / 84 * 0.75, feedback=0.35, mix_=0.3, pingpong=True))
    # filtro dentro do master_fx (antes de dobrar a cauda): filtrar depois do loop pronto cria clique na emenda
    return song.render(loop=True, master_fx=lambda x: lowpass(reverb(x, size=0.8, damp=0.45, mix_=0.28), 9000))


# --- voo ----------------------------------------------------------------------------------------------------------

def flight() -> np.ndarray:
    song = Song(bpm=100, bars=16)
    D = ["D4", "F#4", "A4", "C#5"]
    E = ["E4", "G#4", "B4", "D5"]          # II maior: a assinatura do lídio (G#)
    Bm = ["B3", "D4", "F#4", "A4"]
    A = ["A3", "C#4", "E4", "B4"]
    sect_a = [D, D, E, E] * 2
    sect_b = [Bm, Bm, A, A]
    bars = sect_a + sect_b + [D, D, E, E]
    song.add("arpejo", inst_pulse(duty=0.25, a=0.004, d=0.12, s=0.25, r=0.08),
             " ".join(arp_bar(c) for c in bars), gain_db=-13, pan=-0.1,
             fx=lambda x: delay(x, time=60 / 100 * 0.75, feedback=0.38, mix_=0.32, pingpong=True))
    chords = {"D": "D3+F#3+A3+E4", "E": "E3+G#3+B3+F#4", "Bm": "B2+D3+F#3+C#4", "A": "A2+C#3+E3+B3"}
    pad = " ".join(held(chords[k], 2) for k in ["D", "E", "D", "E", "Bm", "A", "D", "E"])
    song.add("pad", inst_pad(voices=4, detune=14, cutoff=1300, a=0.6, r=1.4), pad, gain_db=-11)
    roots = {"D": ("D2", "A2"), "E": ("E2", "B2"), "Bm": ("B1", "F#2"), "A": ("A1", "E2")}
    bar_names = ["D", "D", "E", "E"] * 2 + ["Bm", "Bm", "A", "A"] + ["D", "D", "E", "E"]
    bass = " ".join(f"{roots[k][0]} - - . {roots[k][0]} - . . {roots[k][1]} - - . {roots[k][0]} - . ."
                    for k in bar_names)
    song.add("baixo", inst_triangle_bass(r=0.06), bass, gain_db=-6)
    # melodia de pulso 12,5% só na volta (compassos 13-16): variação que segura a atenção sem cansar
    lead = " ".join([rest(12), held("A5", 0.5), held("F#5", 0.25), held("E5", 0.25), held("D5", 1),
                     held("E5", 0.5), held("G#5", 0.5), held("F#5", 1)])
    song.add("melodia", inst_pulse(duty=0.125, a=0.01, d=0.2, s=0.5, r=0.2), lead, gain_db=-15, pan=0.15,
             fx=lambda x: delay(x, time=60 / 100 * 0.5, feedback=0.3, mix_=0.25, pingpong=True))
    song.add("bumbo", drum_kick(f0=120, f1=45, tau=0.1), "x.......x.......", drum=True, gain_db=-9)
    song.add("chimbal", drum_hat(), "..x...x...x...x.", drum=True, gain_db=-21)
    return song.render(loop=True, master_fx=lambda x: lowpass(reverb(x, size=0.7, damp=0.5, mix_=0.2), 10000))


TRACKS = {"title": title, "flight": flight}

if __name__ == "__main__":
    out = "assets/audio/music/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/music/title.wav assets/audio/music/flight.wav
    names = [a for a in sys.argv[1:] if a in TRACKS] or list(TRACKS)
    for name in names:
        save_wav(f"{out}{name}.wav", TRACKS[name](), "music", loop=True)
