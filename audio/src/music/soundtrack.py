"""Trilha (padrão: patterns/soundtrack.md). Faixas em loop, -18 LUFS (o bus Music fica -6 dB no jogo):
  title  — menu inicial e hangar: D maior, 84 BPM, 32 compassos (~91 s; era 16): A A' + B (IV-V-iii-vi) + volta.
           Pad + sino FM esparso + baixo triângulo, sem bateria (calma: muito tempo no hangar).
  flight — voo: D lídio, 100 BPM, 48 compassos (~115 s; era 38 s) = 3 blocos de 16 sobre a MESMA progressão
           (A: arpejo/pad/baixo · A': melodia nova, chimbal mais ativo · A'': respiro sem bumbo, arpejo invertido e a
           melodia original). Auditoria 2026-10-09: 38 s repetindo em todos os mundos cansava.
  layer_<mundo> — camada do mundo (mono, 16 compassos = 1/3 do voo, toca junto em loop por AudioStreamSynchronized):
           a mesma contramelodia em instrumento próprio de cada mundo (o tema varia de roupa, como Kirby/Mario).
           Cada camada fica em -24 LUFS (6 dB abaixo do voo) e não passa pelo normalize de música.
Rodar da raiz: python3 audio/src/music/soundtrack.py [--export] [title flight layers]
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
    song = Song(bpm=84, bars=32)
    prog = ["D3+F#3+A3+C#4", "B2+D3+F#3+A3", "G2+B2+D3+F#3", "A2+C#3+E3+B3"]   # Dmaj7 Bm7 Gmaj7 A(add9)
    prog_b = ["G2+B2+D3+F#3", "A2+C#3+E3+G3", "F#2+A2+C#3+E3", "B2+D3+F#3+A3"]  # Gmaj7 A7 F#m7 Bm7 (parte B)
    song.add("pad", inst_pad(voices=4, detune=12, cutoff=1500, a=0.9, r=1.6),
             " ".join(held(c, 2) for c in prog * 2 + prog_b + prog), gain_db=-7)
    def bass_of(roots: list[str]) -> str:
        return " ".join(" ".join([held(r, 0.5), held(r, 0.5), held(r, 0.5), held(r, 0.5)]) for r in roots)
    bass_a = bass_of(["D2", "B1", "G1", "A1"])
    bass_b = bass_of(["G1", "A1", "F#1", "B1"])
    song.add("baixo", inst_triangle_bass(r=0.3), " ".join([bass_a, bass_a, bass_b, bass_a]), gain_db=-8)
    # sino: motivo de 8 compassos na pentatônica, respondido com variação (A A')
    m1 = " ".join([held("F#5", 0.75), held("A5", 0.25), held("E5", 1), rest(1), held("D5", 0.5), held("E5", 0.5),
                   held("B4", 1), rest(1), held("A4", 0.5), held("B4", 0.5), held("D5", 2)])
    m2 = " ".join([held("F#5", 0.75), held("A5", 0.25), held("B5", 1), rest(1), held("A5", 0.5), held("F#5", 0.5),
                   held("E5", 1), rest(1), held("D5", 0.5), held("E5", 0.5), held("D5", 2)])
    # parte B: o sino responde mais grave e esparso (respiro), depois volta o motivo A com final novo
    m3 = " ".join([held("D5", 1), held("B4", 1), rest(1), held("E5", 0.75), held("C#5", 0.25), rest(1)])   # 5 compassos
    # m1 (9) + m2 (9) + m3 (5) + m4 (9) = 32 compassos
    m4 = " ".join([held("F#5", 0.75), held("A5", 0.25), held("E5", 1), rest(1), held("D5", 0.5), held("E5", 0.5),
                   held("B4", 1), rest(1), held("E5", 0.5), held("C#5", 0.5), held("D5", 2)])
    song.add("sino", inst_bell(ratio=3.5, index=2.2, tau=0.9), " ".join([m1, m2, m3, m4]), gain_db=-12,
             fx=lambda x: delay(x, time=60 / 84 * 0.75, feedback=0.35, mix_=0.3, pingpong=True))
    # filtro dentro do master_fx (antes de dobrar a cauda): filtrar depois do loop pronto cria clique na emenda
    return song.render(loop=True, master_fx=lambda x: lowpass(reverb(x, size=0.8, damp=0.45, mix_=0.28), 9000))


# --- voo ----------------------------------------------------------------------------------------------------------

FLIGHT_BARS = ["D", "D", "E", "E"] * 2 + ["Bm", "Bm", "A", "A"] + ["D", "D", "E", "E"]   # 16 compassos (todo bloco)
TONES = {"D": ["D4", "F#4", "A4", "C#5"], "E": ["E4", "G#4", "B4", "D5"],      # E = II maior: assinatura do lídio
         "Bm": ["B3", "D4", "F#4", "A4"], "A": ["A3", "C#4", "E4", "B4"]}
FLIGHT_BPM = 100


def _flight_song(bars: int) -> Song:
    return Song(bpm=FLIGHT_BPM, bars=bars)


def flight() -> np.ndarray:
    song = _flight_song(48)
    arp_a = " ".join(arp_bar(TONES[k]) for k in FLIGHT_BARS)
    arp_inv = " ".join(arp_bar(TONES[k], (3, 2, 1, 2, 0, 1, 2, 1)) for k in FLIGHT_BARS)   # A'': desce em vez de subir
    song.add("arpejo", inst_pulse(duty=0.25, a=0.004, d=0.12, s=0.25, r=0.08), " ".join([arp_a, arp_a, arp_inv]),
             gain_db=-13, pan=-0.1, fx=lambda x: delay(x, time=60 / 100 * 0.75, feedback=0.38, mix_=0.32, pingpong=True))
    chords = {"D": "D3+F#3+A3+E4", "E": "E3+G#3+B3+F#4", "Bm": "B2+D3+F#3+C#4", "A": "A2+C#3+E3+B3"}
    pad = " ".join(held(chords[k], 2) for k in ["D", "E", "D", "E", "Bm", "A", "D", "E"])
    song.add("pad", inst_pad(voices=4, detune=14, cutoff=1300, a=0.6, r=1.4), " ".join([pad] * 3), gain_db=-11)
    roots = {"D": ("D2", "A2"), "E": ("E2", "B2"), "Bm": ("B1", "F#2"), "A": ("A1", "E2")}
    bass = " ".join(f"{roots[k][0]} - - . {roots[k][0]} - . . {roots[k][1]} - - . {roots[k][0]} - . ."
                    for k in FLIGHT_BARS)
    bass_fill = " ".join(f"{roots[k][0]} - - . {roots[k][1]} - . {roots[k][0]} {roots[k][1]} - - . {roots[k][0]} - "
                         f"{roots[k][1]} ." for k in FLIGHT_BARS)
    song.add("baixo", inst_triangle_bass(r=0.06), " ".join([bass, bass_fill, bass]), gain_db=-6)
    # bloco 2: melodia nova (pulso 12,5%, vibrato leve); bloco 3: a melodia original só no fim (compassos 45-48)
    lead_b = " ".join([held("F#5", 0.75), held("A5", 0.25), held("D6", 1), held("B5", 0.5), held("G#5", 0.5),
                       held("E5", 1), held("A5", 0.75), held("F#5", 0.25), held("D5", 1), held("E5", 0.5),
                       held("F#5", 0.5), held("G#5", 1), held("F#5", 1), held("D5", 0.5), held("B4", 0.5),
                       held("C#5", 0.5), held("E5", 0.5), held("A5", 1), held("F#5", 0.5), held("E5", 0.5),
                       held("D5", 1), held("E5", 1.5), rest(0.5)])
    lead_c = " ".join([rest(12), held("A5", 0.5), held("F#5", 0.25), held("E5", 0.25), held("D5", 1),
                       held("E5", 0.5), held("G#5", 0.5), held("F#5", 1)])
    song.add("melodia", inst_pulse(duty=0.125, a=0.01, d=0.2, s=0.5, r=0.2, vib=0.15),
             " ".join([rest(16), lead_b, lead_c]), gain_db=-15, pan=0.15,
             fx=lambda x: delay(x, time=60 / 100 * 0.5, feedback=0.3, mix_=0.25, pingpong=True))
    kick = "x.......x......." * 16 + "x.......x......." * 16 + "................" * 4 + "x.......x......." * 12
    song.add("bumbo", drum_kick(f0=120, f1=45, tau=0.1), kick, drum=True, gain_db=-9)
    hat = "..x...x...x...x." * 16 + "..x.x.x...x.x.x." * 16 + "..x...x...x...x." * 16
    song.add("chimbal", drum_hat(), hat, drum=True, gain_db=-21)
    return song.render(loop=True, master_fx=_flight_master)


def _flight_master(x: np.ndarray) -> np.ndarray:
    return lowpass(reverb(x, size=0.7, damp=0.5, mix_=0.2), 10000)


# --- camada de cada mundo (contramelodia, mesma em todos, instrumento próprio) ----------------------------------

def _counter() -> str:
    """Resposta esparsa nos tempos 2 e 4 (fica entre as colcheias do arpejo): 2 compassos por par de acordes."""
    pick = {"D": ("A5", "F#5", "C#6"), "E": ("B5", "G#5", "E6"), "Bm": ("F#5", "D5", "A5"), "A": ("E5", "C#5", "A5")}
    out = []
    for i in range(0, 16, 2):
        a, b, c = pick[FLIGHT_BARS[i]]
        out.append(" ".join([". . . .", a, "- - .", ". . . .", b, "- - .",            # compasso 1: tempos 2 e 4
                             ". . . .", c, "- - - - - - - . . . ."]))             # compasso 2: nota longa no tempo 2
    return " ".join(out)


def _inst_bubble() -> Instrument:
    """Bolhas: seno que 'borbulha' para a nota (sobe 3 semitons no ataque) + vibrato largo."""
    def play_(f, dur, vel):
        total = dur + 0.2
        bend = f * 2 ** (-3 / 12 * np.exp(-t_axis(total) / 0.03))
        return sine(vibrato(bend, total, 6.5, 0.35), total) * adsr(total, 0.01, 0.1, 0.6, 0.2) * vel
    return play_


def _inst_celesta() -> Instrument:
    """Sorvete: celesta de gelo (FM ratio 7, agudo, decaimento curto)."""
    def play_(f, dur, vel):
        total = max(dur, 0.8)
        return fm(f, total, 7.0, 2.0 * decay(total, 0.08)) * decay(total, 0.25) * vel
    return play_


def _inst_marimba() -> Instrument:
    """Cogumelos: marimba de madeira (triângulo + sobretom 4x curtinho, decaimento rápido)."""
    def play_(f, dur, vel):
        total = max(dur, 0.5)
        x = triangle(f, total) * decay(total, 0.18) + sine(f * 4, total) * decay(total, 0.02) * 0.3
        return x * vel
    return play_


# mundo -> (instrumento, oitava em semitons, ganho dB)
LAYERS = {
    "luna": (inst_bell(ratio=3.5, index=2.0, tau=0.5), 0, -13),                    # sinos de queijo
    "cogumelos": (_inst_marimba(), -12, -9),                                       # madeira quicando
    "bolhas": (_inst_bubble(), -12, -12),                                          # bolha que canta
    "jardim": (inst_pulse(duty=0.125, a=0.03, d=0.1, s=0.7, r=0.15, vib=0.25), 0, -16),   # flautinha
    "sorvete": (_inst_celesta(), 12, -15),                                         # celesta de gelo
    "nuvens": (inst_pad(voices=3, detune=10, cutoff=2200, a=0.08, r=0.6, osc="tri"), 0, -10),   # sopro macio
}


def _shift(pattern: str, semis: int) -> str:
    if semis == 0:
        return pattern
    out = []
    for t in pattern.split():
        if t in (".", "-", "|"):
            out.append(t)
        else:
            m = midi(t) + semis
            names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            out.append(f"{names[m % 12]}{m // 12 - 1}")
    return " ".join(out)


LAYER_LUFS = -24.0      # 6 dB abaixo do voo (-18): presente como identidade do mundo, sem brigar com a melodia


def layer(world: str) -> np.ndarray:
    inst, semis, db = LAYERS[world]
    song = _flight_song(16)
    song.add(world, inst, _shift(_counter(), semis), gain_db=db,
             fx=lambda x: delay(x, time=60 / 100 * 0.75, feedback=0.3, mix_=0.25, pingpong=False))
    x = to_mono(song.render(loop=True, master_fx=_flight_master))
    return x * db_to_lin(LAYER_LUFS - lufs(x)[0])


TRACKS = {"title": title, "flight": flight}

if __name__ == "__main__":
    out = "assets/audio/music/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/music/title.wav assets/audio/music/flight.wav
    # assets/audio/music/layer_luna.wav assets/audio/music/layer_cogumelos.wav assets/audio/music/layer_bolhas.wav
    # assets/audio/music/layer_jardim.wav assets/audio/music/layer_sorvete.wav assets/audio/music/layer_nuvens.wav
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    names = [a for a in args if a in TRACKS] or ([] if args else list(TRACKS))
    for name in names:
        save_wav(f"{out}{name}.wav", TRACKS[name](), "music", loop=True)
    if "layers" in args or not args:
        for w in LAYERS:
            save_wav(f"{out}layer_{w}.wav", layer(w), "music", loop=True, do_normalize=False)
