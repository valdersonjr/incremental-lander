"""Trilha (padrão: patterns/soundtrack.md). Faixas em loop, -18 LUFS (o bus Music fica -6 dB no jogo):
  theme  — TEMA DO GATINHO, só na tela inicial (2026-10-09): D maior, 68 BPM (era 92) e bumbo bem leve, 24 compassos A B A', melodia
           cantarolável (motivo de 2 compassos pergunta/resposta), baixo com harmônico audível no notebook.
  title  — Mapa e NAVE (era também a tela inicial): D maior, 84 BPM, 32 compassos (~91 s; era 16): A A' + B (IV-V-iii-vi) + volta.
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
    # v2 (auditoria 2026-10-09): baixo com harmônico (o mesmo do tema) e 3 dB abaixo — a faixa tinha 68% da energia
    # < 120 Hz e perdia 4,4 dB no alto-falante de notebook
    song.add("baixo", _bass_inst(r=0.3), " ".join([bass_a, bass_a, bass_b, bass_a]), gain_db=-11)
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
    return song.render(loop=True, master_fx=lambda x: highpass(lowpass(reverb(x, size=0.8, damp=0.45, mix_=0.28),
                                                                       9000), 35))


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
    # v2 (auditoria 2026-10-09): baixo com harmônico e 3 dB abaixo (72% < 120 Hz; brigava com o propulsor no grave)
    song.add("baixo", _bass_inst(r=0.06), " ".join([bass, bass_fill, bass]), gain_db=-9)
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
    song.add("bumbo", drum_kick(f0=140, f1=55, tau=0.08), kick, drum=True, gain_db=-10)
    hat = "..x...x...x...x." * 16 + "..x.x.x...x.x.x." * 16 + "..x...x...x...x." * 16
    song.add("chimbal", drum_hat(), hat, drum=True, gain_db=-21)
    return song.render(loop=True, master_fx=_flight_master)


def _flight_master(x: np.ndarray) -> np.ndarray:
    return highpass(lowpass(reverb(x, size=0.7, damp=0.5, mix_=0.2), 10000), 35)


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


# --- tema do gatinho (tela inicial) ------------------------------------------------------------------------------

THEME_BPM = 68          # 2026-10-09: era 92; com a tela "Noite de história" o usuário escolheu 68 (canção de ninar)
THEME_DRUMS = "soft"    # só o bumbo bem baixinho
# 24 compassos: A (tema) · B (sobe, resposta) · A' (tema com final novo). I-IV-vi-V em D maior, cantarolável.
THEME_CHORDS = ["D", "G", "Bm", "A", "D", "G", "A", "D",
                "G", "A", "F#m", "Bm", "G", "A", "D", "D",
                "D", "G", "Bm", "A", "D", "G", "A", "D"]
THEME_TONES = {"D": ("D", "F#", "A"), "G": ("G", "B", "D"), "Bm": ("B", "D", "F#"), "A": ("A", "C#", "E"),
               "F#m": ("F#", "A", "C#")}


def _bar(*notes: tuple[str, int]) -> str:
    """Um compasso a partir de (nota|'.', passos); confere que soma 16."""
    assert sum(n for _, n in notes) == STEPS, notes
    return " ".join(" ".join([t] + (["-"] if t != "." else ["."]) * (n - 1)) for t, n in notes)


def _theme_melody() -> str:
    a = [_bar(("F#5", 4), ("A5", 4), ("B5", 2), ("A5", 2), ("F#5", 4)),      # motivo: pergunta
         _bar(("E5", 4), ("D5", 4), ("B4", 8)),
         _bar(("D5", 4), ("F#5", 4), ("A5", 4), ("F#5", 4)),
         _bar(("E5", 12), (".", 4)),
         _bar(("F#5", 4), ("A5", 4), ("B5", 2), ("A5", 2), ("F#5", 4)),      # motivo de novo: resposta
         _bar(("B5", 4), ("A5", 4), ("G5", 4), ("E5", 4)),
         _bar(("A5", 4), ("G5", 2), ("F#5", 2), ("E5", 8)),
         _bar(("D5", 12), (".", 4))]
    b = [_bar(("B5", 6), ("A5", 2), ("G5", 8)),
         _bar(("A5", 6), ("G5", 2), ("F#5", 8)),
         _bar(("A5", 4), ("C#6", 4), ("A5", 4), ("F#5", 4)),
         _bar(("B5", 12), (".", 4)),
         _bar(("D6", 4), ("B5", 4), ("G5", 4), ("B5", 4)),
         _bar(("C#6", 4), ("A5", 4), ("E5", 4), ("A5", 4)),
         _bar(("F#5", 4), ("A5", 4), ("D6", 8)),
         _bar((".", 16))]                                                   # respiro antes da volta
    a2 = a[:6] + [_bar(("A5", 4), ("B5", 2), ("A5", 2), ("G5", 4), ("E5", 4)),
                  _bar(("D5", 4), ("F#5", 4), ("D5", 8))]
    return " ".join(a + b + a2)


def _theme_bass() -> str:
    """Baixo saltitante (tônica, quinta, tônica oitava acima) — oitava 2-3 para ser ouvido no notebook."""
    out = []
    for c in THEME_CHORDS:
        r, _, f = THEME_TONES[c]
        lo = f"{r}2" if r in ("G", "A", "B", "F#") else f"{r}3"
        fifth = f"{f}3" if f not in ("D", "C#", "E") else f"{f}3"
        hi = lo[:-1] + str(int(lo[-1]) + 1)
        out.append(_bar((lo, 4), (fifth, 2), (lo, 2), (hi, 4), (fifth, 4)))
    return " ".join(out)


def _theme_strum(offbeat: bool) -> str:
    """Acompanhamento: arpejo dedilhado em colcheias (A) ou acorde 'pá' nos contratempos (B)."""
    out = []
    for c in THEME_CHORDS:
        r, t, f = THEME_TONES[c]
        n1, n2, n3 = f"{r}4", f"{t}4", f"{f}4"
        if offbeat:
            chord_ = "+".join([n1, n2, n3])
            out.append(_bar((".", 2), (chord_, 2), (".", 2), (chord_, 2), (".", 2), (chord_, 2), (".", 2), (chord_, 2)))
        else:
            out.append(_bar((n1, 2), (n2, 2), (n3, 2), (n2, 2), (n1, 2), (n2, 2), (n3, 2), (n2, 2)))
    return " ".join(out)


def _bass_inst(r: float = 0.05) -> Instrument:
    """Baixo triângulo + harmônico de pulso uma oitava acima (drive leve): o 'peso' continua audível no notebook."""
    tri = inst_triangle_bass(r=r)
    def play_(f, dur, vel):
        x = tri(f, dur, vel)
        h = pulse(f * 2, len(x) / SR, duty=0.5) * adsr(len(x) / SR, 0.003, 0.08, 0.4, 0.05) * vel
        return x + lowpass(drive(h, 1.5), 1800) * 0.35
    return play_


def _lead_marimba() -> Instrument:
    """Marimba/kalimba: triângulo + sobretom 4x (madeira) e 10x curtinho (toque), decaimento médio."""
    def play_(f, dur, vel):
        total = max(dur, 0.7)
        body = triangle(f, total) * decay(total, 0.32)
        wood = sine(f * 4, total) * decay(total, 0.05) * 0.35
        tick = sine(f * 10, total) * decay(total, 0.008) * 0.12
        return lowpass(body + wood + tick, 6000) * vel
    return play_


def _lead_ocarina() -> Instrument:
    """Ocarina/flauta: seno + um pouco de triângulo, sopro de ruído no ataque e vibrato que entra devagar."""
    def play_(f, dur, vel):
        total = dur + 0.12
        fr = vibrato(f, total, 5.0, 0.18, delay=0.18)
        tone = sine(fr, total) * 0.8 + triangle(fr, total) * 0.2
        breath = bandpass(noise(total, "pink", int(f) % 97), f * 0.8, f * 2.5) * decay(total, 0.06) * 0.25
        return (tone * adsr(total, 0.04, 0.1, 0.8, 0.12) + breath) * vel
    return play_


def _lead_epiano() -> Instrument:
    """Piano elétrico (FM tipo Rhodes): portadora com modulador 1:1 de índice caindo + 'tine' 14:1 no ataque."""
    def play_(f, dur, vel):
        total = max(dur, 0.9)
        body = fm(f, total, ratio=1.0, index=1.6 * decay(total, 0.35)) * decay(total, 0.7)
        tine = fm(f, total, ratio=14.0, index=0.8 * decay(total, 0.02)) * decay(total, 0.04) * 0.25
        return lowpass(body + tine, 5000) * vel
    return play_


def _lead_harp() -> Instrument:
    """Harpa: pulso 50% com passa-baixa que fecha rápido (dedilhado) + oitava de seno suave."""
    pl = inst_pluck(cutoff0=4500, cutoff1=700, tau=0.35, osc="pulse")
    def play_(f, dur, vel):
        x = pl(f, dur, vel)
        return x + sine(f * 2, len(x) / SR) * decay(len(x) / SR, 0.2) * 0.2 * vel
    return play_


# opção -> (instrumento da melodia, ganho dB, eco)
THEME_LEADS = {"C": (_lead_marimba, -4, 0.18), "D": (_lead_ocarina, -6, 0.22), "E": (_lead_epiano, -5, 0.18),
               "F": (_lead_harp, -6, 0.2)}


def theme(option: str = "A", bpm: float = THEME_BPM, drums: str = "full") -> np.ndarray:
    """Tema do gatinho. A = caixinha de música (sino + violãozinho + baixo + bumbo/chocalho leves);
    B = chiptune fofo (pulso com vibrato + 'pom-pá' de pulso + bateria de chip). bpm/drums: andamento e bateria
    ("full" | "soft" = só o bumbo bem baixo | "none") — a Noite de história pediu o tema mais lento (ninar)."""
    song = Song(bpm=bpm, bars=len(THEME_CHORDS))
    mel = _theme_melody()
    if option in THEME_LEADS:                                # mesmo arranjo da A, só troca o instrumento da melodia
        make, db, wet = THEME_LEADS[option]
        song.add("melodia", make(), mel, gain_db=db,
                 fx=lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.25, mix_=wet, pingpong=True))
        song.add("violao", inst_pluck(cutoff0=3500, cutoff1=500, tau=0.18, osc="pulse"), _theme_strum(False),
                 gain_db=-15, pan=-0.2)
        if drums != "none":
            song.add("bumbo", drum_kick(f0=110, f1=50, tau=0.08), "x.......x.......", drum=True,
                     gain_db=-13 if drums == "full" else -19)
        if drums == "full":
            song.add("chocalho", drum_hat(), "..x...x...x...x.", drum=True, gain_db=-22)
    elif option == "A":
        song.add("melodia", inst_bell(ratio=3.5, index=2.0, tau=0.45), mel, gain_db=-4,
                 fx=lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.25, mix_=0.2, pingpong=True))
        song.add("dobra", inst_pulse(duty=0.5, a=0.01, d=0.1, s=0.3, r=0.1), mel, gain_db=-20)   # corpo médio
        song.add("violao", inst_pluck(cutoff0=3500, cutoff1=500, tau=0.18, osc="pulse"), _theme_strum(False),
                 gain_db=-15, pan=-0.2)
        song.add("bumbo", drum_kick(f0=110, f1=50, tau=0.08), "x.......x.......", drum=True, gain_db=-13)
        song.add("chocalho", drum_hat(), "..x...x...x...x.", drum=True, gain_db=-22)
    else:
        song.add("melodia", inst_pulse(duty=0.25, a=0.006, d=0.12, s=0.55, r=0.1, vib=0.18), mel, gain_db=-6,
                 fx=lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.3, mix_=0.25, pingpong=True))
        song.add("eco", inst_bell(ratio=3.5, index=1.5, tau=0.3), _shift(mel, 12), gain_db=-22)   # brilho em cima
        song.add("pompa", inst_pulse(duty=0.125, a=0.003, d=0.06, s=0.2, r=0.04), _theme_strum(True),
                 gain_db=-16, pan=0.15)
        song.add("bumbo", drum_chip(f0=900, f1=55, t=0.1), "x.......x.......", drum=True, gain_db=-12)
        song.add("caixa", drum_snare(tone=210, tau=0.06), "....x.......x...", drum=True, gain_db=-20)
        song.add("chimbal", drum_hat(), "..x...x...x...x.", drum=True, gain_db=-24)
    song.add("baixo", _bass_inst(), _theme_bass(), gain_db=-8)
    return song.render(loop=True, master_fx=lambda x: lowpass(reverb(x, size=0.6, damp=0.5, mix_=0.18), 11000))


THEME_PICK = "D"        # escolhida pelo usuário ouvindo as 6 no navegador (2026-10-09): ocarina/flauta
# --- voo da Lua (2026-10-09) ------------------------------------------------------------------------------------
# Usuário: "gostaria de mudar essa música do primeiro planeta que fica tocando". A base do voo (arpejo chip constante
# + chimbal, loop de 115 s) cansa. Pesquisa (pattern luna-flight): música cozy de jogo = contenção, fica no fundo;
# loop longo (> 2 min) com A-B-A' e RESPIROS (tirar e devolver instrumentos); melodia com pausas. Forma de 44
# compassos: intro (pad) · A (motivo do tema do gatinho) · A' (sinos respondem) · B (melodia nova) · respiro (pad +
# sininhos, sem baixo/percussão) · A'' (resolve). Três "vestidos": A ocarina sonhadora, B lo-fi, C caixinha de música.
LUNA_SECTIONS = [("intro", ["D", "Gmaj7", "D", "A"]),
                 ("A", ["D", "Gmaj7", "Bm7", "A", "D", "Gmaj7", "Em7", "A"]),
                 ("A2", ["D", "Gmaj7", "Bm7", "A", "D", "Gmaj7", "Em7", "A"]),
                 ("B", ["G", "A", "F#m", "Bm", "G", "A", "D", "D"]),
                 ("pausa", ["D", "Gmaj7", "Bm7", "A", "D", "Gmaj7", "Em7", "A"]),
                 ("A3", ["D", "Gmaj7", "Bm7", "A", "D", "Gmaj7", "Em7", "A"])]
LUNA_TONES = {"D": ["D", "F#", "A", "E"], "Gmaj7": ["G", "B", "D", "F#"], "Bm7": ["B", "D", "F#", "A"],
              "A": ["A", "C#", "E", "B"], "Em7": ["E", "G", "B", "D"], "F#m": ["F#", "A", "C#", "E"],
              "G": ["G", "B", "D", "A"], "Bm": ["B", "D", "F#", "C#"]}
LUNA_OPTS = {"A": ("Ocarina sonhadora", 80.0), "B": ("Lo-fi da Lua", 82.0), "C": ("Caixinha de música", 72.0)}
_REST = (".", 16)
_MEL_A = [[("F#5", 4), ("A5", 4), ("B5", 2), ("A5", 2), ("F#5", 4)], [_REST],
          [("D5", 4), ("F#5", 4), ("E5", 8)], [_REST],
          [("F#5", 4), ("A5", 4), ("B5", 2), ("A5", 2), ("D6", 4)], [("B5", 8), ("A5", 8)],
          [("G5", 4), ("F#5", 4), ("E5", 8)], [_REST]]
_MEL_B = [[("B5", 6), ("A5", 2), ("G5", 8)], [("A5", 6), ("G5", 2), ("F#5", 8)],
          [("A5", 4), ("C#6", 4), ("A5", 4), ("F#5", 4)], [("B5", 12), (".", 4)],
          [("D6", 4), ("B5", 4), ("G5", 4), ("B5", 4)], [("C#6", 4), ("A5", 4), ("E5", 4), ("A5", 4)],
          [("F#5", 4), ("A5", 4), ("D6", 8)], [_REST]]
_MEL_A3_END = [("E5", 4), ("F#5", 4), ("D5", 8)]                # o A'' resolve na tônica
_ANSWER = [[_REST], [("B5", 4), ("A5", 4), (".", 8)], [_REST], [("A5", 4), ("E5", 4), (".", 8)],   # sinos no A'
           [_REST], [_REST], [_REST], [("C#6", 4), ("A5", 4), (".", 8)]]
_SPARKS = [[("D6", 8), (".", 8)], [_REST], [("F#6", 8), (".", 8)], [_REST], [("A5", 8), (".", 8)], [_REST],
           [("B5", 8), (".", 8)], [_REST]]                     # respiro: sininhos esparsos


def _luna_parts() -> dict:
    """Partes por compasso (strings de 16 passos) da forma inteira: melodia, resposta, pad, baixo, arpejo, chords."""
    mel, ans, pad, bass, arp, chord_hits, sec_of = [], [], [], [], [], [], []
    for name, chords in LUNA_SECTIONS:
        for i, c in enumerate(chords):
            sec_of.append(name)
            r, t, f, x = LUNA_TONES[c]
            if name in ("A", "A2", "A3"):
                bar = _MEL_A[i] if not (name == "A3" and i == 7) else _MEL_A3_END
            elif name == "B":
                bar = _MEL_B[i]
            else:
                bar = [_REST]
            mel.append(_bar(*bar))
            ans.append(_bar(*(_ANSWER[i] if name == "A2" else _SPARKS[i] if name == "pausa" else [_REST])))
            lo = f"{r}3" if r in ("D", "E", "F#") else f"{r}2" if r in ("G", "A", "B") else f"{r}3"
            pad.append(held(f"{r}3+{t}3+{f}3+{x}4", 1))
            if name in ("intro", "pausa"):
                bass.append(_bar((lo, 16)) if name == "pausa" and i % 2 == 0 else _bar(_REST))
            else:
                bass.append(_bar((lo, 8), (f"{f}2" if f in ("A", "B", "G") else f"{f}3", 8)))
            if name in ("A2", "B", "A3"):
                arp.append(_bar((f"{r}4", 4), (f"{t}4", 4), (f"{f}4", 4), (f"{t}4", 4)))
            else:
                arp.append(_bar(_REST))
            chord_hits.append(_bar((".", 2), (f"{r}4+{t}4+{f}4", 4), (".", 6), (f"{t}4+{f}4+{x}4", 4))
                              if name not in ("intro", "pausa") else _bar(_REST))
    j = " ".join
    return {"mel": j(mel), "ans": j(ans), "pad": j(pad), "bass": j(bass), "arp": j(arp), "hits": j(chord_hits),
            "sec": sec_of}


def _luna_drums(sec: list[str], groove: dict) -> dict:
    """Bateria por seção: groove = {nome: {secao: padrao de 16}}; sem entrada = silêncio naquele compasso."""
    return {k: "".join(v.get(name, "................") for name in sec) for k, v in groove.items()}


def flight_luna(opt: str = "A") -> np.ndarray:
    bpm = LUNA_OPTS[opt][1]
    P = _luna_parts()
    song = Song(bpm=bpm, bars=len(P["sec"]))
    eco = lambda w: (lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.25, mix_=w, pingpong=True))
    song.add("pad", inst_pad(voices=3, detune=10, cutoff=1400, a=0.8, r=1.4, osc="tri"), P["pad"], gain_db=-15)
    song.add("baixo", _bass_inst(r=0.2), P["bass"], gain_db=-11)
    if opt == "A":
        song.add("melodia", _lead_ocarina(), P["mel"], gain_db=-5, fx=eco(0.22))
        song.add("sinos", inst_bell(ratio=3.5, index=1.6, tau=0.5), P["ans"], gain_db=-12, fx=eco(0.25))
        song.add("marimba", _lead_marimba(), P["arp"], gain_db=-15, pan=-0.15)
        dr = _luna_drums(P["sec"], {"bumbo": {"A2": "x.......x.......", "B": "x.......x.......", "A3": "x.......x......."},
                                    "chocalho": {"B": "..x...x...x...x."}})
        song.add("bumbo", drum_kick(f0=110, f1=55, tau=0.08), dr["bumbo"], drum=True, gain_db=-16)
        song.add("chocalho", drum_hat(), dr["chocalho"], drum=True, gain_db=-25)
    elif opt == "B":
        song.add("melodia", inst_bell(ratio=3.5, index=1.8, tau=0.45), P["mel"], gain_db=-6, fx=eco(0.2))
        song.add("sinos", inst_bell(ratio=3.5, index=1.2, tau=0.4), P["ans"], gain_db=-14, fx=eco(0.25))
        song.add("piano", _lead_epiano(), P["hits"], gain_db=-13, pan=-0.1)
        lofi = {"A": "x.....x...x.....", "A2": "x.....x...x.....", "B": "x.....x...x.....", "A3": "x.....x...x....."}
        dr = _luna_drums(P["sec"], {"bumbo": lofi,
                                    "caixa": {k: "....x.......x..." for k in ("A", "A2", "B", "A3")},
                                    "chimbal": {k: "x.x.x.x.x.x.x.x." for k in ("A2", "B", "A3")}})
        song.add("bumbo", drum_kick(f0=100, f1=50, tau=0.09), dr["bumbo"], drum=True, gain_db=-15)
        song.add("caixa", drum_snare(tone=180, tau=0.05), dr["caixa"], drum=True, gain_db=-21)
        song.add("chimbal", drum_hat(), dr["chimbal"], drum=True, gain_db=-27)
    else:
        song.add("melodia", inst_bell(ratio=3.5, index=2.2, tau=0.55), P["mel"], gain_db=-5, fx=eco(0.25))
        song.add("sinos", _inst_celesta(), _shift(P["ans"], -12), gain_db=-14, fx=eco(0.3))
        song.add("harpa", _lead_harp(), P["arp"], gain_db=-13, pan=0.12)
    return song.render(loop=True, master_fx=lambda x: highpass(lowpass(reverb(x, size=0.7, damp=0.5, mix_=0.22),
                                                                       10000), 35))


# --- canções de ninar de domínio público (2026-10-09, prévia para o usuário escolher a melodia do voo da Lua) -----
# Melodias conferidas em partitura (Wikipédia, código LilyPond: Twinkle, Brahms Op. 49 nº 4, Frère Jacques) ou sabidas
# de cor (Au clair de la lune, 4 frases). Todas em Ré maior, tocadas por NÓS (só a melodia, sem letra nem gravação
# de terceiros). Compasso: 16 passos (4/4) ou 12 (3/4: Brahms). Notas: (nota, passos); "." = pausa.
LULLABIES = {
    "twinkle": {"name": "Brilha, brilha, estrelinha", "bpm": 84.0, "steps": 16, "bars": [
        [("D5", 4), ("D5", 4), ("A5", 4), ("A5", 4)], [("B5", 4), ("B5", 4), ("A5", 8)],
        [("G5", 4), ("G5", 4), ("F#5", 4), ("F#5", 4)], [("E5", 4), ("E5", 4), ("D5", 8)],
        [("A5", 4), ("A5", 4), ("G5", 4), ("G5", 4)], [("F#5", 4), ("F#5", 4), ("E5", 8)],
        [("A5", 4), ("A5", 4), ("G5", 4), ("G5", 4)], [("F#5", 4), ("F#5", 4), ("E5", 8)],
        [("D5", 4), ("D5", 4), ("A5", 4), ("A5", 4)], [("B5", 4), ("B5", 4), ("A5", 8)],
        [("G5", 4), ("G5", 4), ("F#5", 4), ("F#5", 4)], [("E5", 4), ("E5", 4), ("D5", 8)]],
        "chords": ["D", "G", "G", "A", "D", "D", "D", "A", "D", "G", "G", "A"]},
    "clair": {"name": "Au clair de la lune (À luz da Lua)", "bpm": 84.0, "steps": 16, "bars": [
        [("D5", 4), ("D5", 4), ("D5", 4), ("E5", 4)], [("F#5", 8), ("E5", 8)],
        [("D5", 4), ("F#5", 4), ("E5", 4), ("E5", 4)], [("D5", 16)],
        [("D5", 4), ("D5", 4), ("D5", 4), ("E5", 4)], [("F#5", 8), ("E5", 8)],
        [("D5", 4), ("F#5", 4), ("E5", 4), ("E5", 4)], [("D5", 16)],
        [("E5", 4), ("E5", 4), ("E5", 4), ("E5", 4)], [("B4", 8), ("B4", 8)],
        [("E5", 4), ("D5", 4), ("C#5", 4), ("B4", 4)], [("A4", 16)],
        [("D5", 4), ("D5", 4), ("D5", 4), ("E5", 4)], [("F#5", 8), ("E5", 8)],
        [("D5", 4), ("F#5", 4), ("E5", 4), ("E5", 4)], [("D5", 16)]],
        "chords": ["D", "D", "A", "D", "D", "D", "A", "D", "Em7", "Em7", "A", "A", "D", "D", "A", "D"]},
    "jacques": {"name": "Frère Jacques (Dorme, João)", "bpm": 88.0, "steps": 16, "canon": True, "bars": [
        [("D5", 4), ("E5", 4), ("F#5", 4), ("D5", 4)], [("D5", 4), ("E5", 4), ("F#5", 4), ("D5", 4)],
        [("F#5", 4), ("G5", 4), ("A5", 8)], [("F#5", 4), ("G5", 4), ("A5", 8)],
        [("A5", 2), ("B5", 2), ("A5", 2), ("G5", 2), ("F#5", 4), ("D5", 4)],
        [("A5", 2), ("B5", 2), ("A5", 2), ("G5", 2), ("F#5", 4), ("D5", 4)],
        [("D5", 4), ("A4", 4), ("D5", 8)], [("D5", 4), ("A4", 4), ("D5", 8)]],
        "chords": ["D", "D", "D", "D", "D", "D", "D", "D"]},
    "brahms": {"name": "Canção de ninar de Brahms", "bpm": 80.0, "steps": 12, "bars": [
        [("A5", 6), ("F#5", 2), ("F#5", 4)], [("A5", 4), (".", 4), ("F#5", 2), ("A5", 2)],
        [("D6", 4), ("C#6", 6), ("B5", 2)], [("B5", 4), ("A5", 4), ("E5", 2), ("F#5", 2)],
        [("G5", 4), ("E5", 4), ("E5", 2), ("F#5", 2)], [("G5", 4), (".", 4), ("E5", 2), ("G5", 2)],
        [("C#6", 2), ("B5", 2), ("A5", 4), ("C#6", 4)], [("D6", 4), (".", 4), ("D5", 2), ("D5", 2)],
        [("D6", 8), ("B5", 2), ("G5", 2)], [("A5", 8), ("F#5", 2), ("D5", 2)],
        [("G5", 4), ("A5", 4), ("B5", 4)], [("A5", 8), ("D5", 2), ("D5", 2)],
        [("D6", 8), ("B5", 2), ("G5", 2)], [("A5", 8), ("F#5", 2), ("D5", 2)],
        [("G5", 4), ("F#5", 4), ("E5", 4)], [("D5", 8), ("F#5", 2), ("F#5", 2)]],
        "chords": ["D", "D", "A", "A", "A", "A", "A", "D", "G", "D", "A", "D", "G", "D", "A", "D"]},
}


def _tokens(bar: list) -> str:
    out = []
    for note_, n in bar:
        out += ["."] * n if note_ == "." else [note_] + ["-"] * (n - 1)
    return " ".join(out)


def lullaby(key: str, reps: int = 2) -> np.ndarray:
    """Prévia da canção de ninar: melodia na ocarina, marimba nos acordes (semínimas), pad e baixo; reps voltas.
    Frère Jacques: na 2ª volta a marimba repete a melodia em cânone (2 compassos atrás)."""
    L = LULLABIES[key]
    st, bpm = L["steps"], L["bpm"]
    mel = " ".join(_tokens(b) for b in L["bars"])
    pad, bass, arp = [], [], []
    for c in L["chords"]:
        r, t, f, x = LUNA_TONES[c]
        pad.append(" ".join([f"{r}3+{t}3+{f}3"] + ["-"] * (st - 1)))
        lo = f"{r}2" if r in ("G", "A", "B") else f"{r}3"
        half = st // 2
        bass.append(" ".join([lo] + ["-"] * (half - 1) + [lo] + ["-"] * (st - half - 1)))
        notes = [f"{r}4", f"{t}4", f"{f}4", f"{t}4"][: st // 4]
        arp.append(" ".join(" ".join([n] + ["-"] * 3) for n in notes))
    total = len(L["bars"]) * st * reps
    song = Song(bpm=bpm, bars=total // 16)
    rep = lambda s_: " ".join([s_] * reps)
    song.add("melodia", _lead_ocarina(), rep(mel), gain_db=-5,
             fx=lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.22, mix_=0.2, pingpong=True))
    song.add("pad", inst_pad(voices=3, detune=10, cutoff=1400, a=0.6, r=1.2, osc="tri"), rep(" ".join(pad)), gain_db=-15)
    song.add("baixo", _bass_inst(r=0.2), rep(" ".join(bass)), gain_db=-12)
    if L.get("canon"):
        lag = " ".join(["."] * (2 * st))
        canon = (" ".join(["."] * len(L["bars"]) * st) + " " + mel).split()[: total]
        canon = " ".join(canon[: len(L["bars"]) * st] + (lag + " " + mel).split()[: total - len(L["bars"]) * st])
        song.add("marimba", _lead_marimba(), canon, gain_db=-9, pan=-0.2)
    else:
        song.add("marimba", _lead_marimba(), rep(" ".join(arp)), gain_db=-15, pan=-0.15)
    return song.render(loop=True, master_fx=lambda x: highpass(lowpass(reverb(x, size=0.7, damp=0.5, mix_=0.22),
                                                                       10000), 35))


# --- voo da Lua: "Passeio no queijo" (2026-10-11, escolhida pelo usuário entre 3 na rodada 2) ---------------
# Substitui flight + layer_luna só na Lua ("irritante com o tempo": arpejo sem parar, sino FM agudo, camada de
# 38 s). Violão abafado + ocarina, melodia nova, 86 BPM, 44 compassos (~2 min); sem arpejo contínuo, tudo < 3 kHz.
# Prévias da rodada: audio/previews/luna2/ (ninar, noite, passeio).

def felt_piano() -> Instrument:
    """Piano de feltro: FM 1:1 de índice baixo caindo + 2º harmônico curto + martelinho de ruído, passa-baixa 2,4 kHz."""
    def play_(f, dur, vel):
        total = max(dur, 1.4) + 0.3
        body = fm(f, total, ratio=1.0, index=0.9 * decay(total, 0.25)) * decay(total, 1.1)
        h2 = sine(f * 2, total) * decay(total, 0.35) * 0.22
        hammer = lowpass(noise(total, "pink", int(f) % 91), f * 3) * decay(total, 0.012) * 0.08
        return fade(lowpass(body + h2 + hammer, 2400), 0.002, 0.08) * vel
    return play_


def nylon() -> Instrument:
    """Violãozinho: pulso com passa-baixa fechando rápido, bem abafado."""
    return inst_pluck(cutoff0=2200, cutoff1=350, tau=0.3, osc="pulse")


def bars_of(pattern: str) -> list[str]:
    t = pattern.split()
    return [" ".join(t[i:i + 16]) for i in range(0, len(t), 16)]


def tones(c: str) -> tuple[str, str, str, str]:
    return tuple(LUNA_TONES[c])


def low(r: str) -> str:
    return f"{r}2" if r in ("G", "A", "B", "F#", "E") else f"{r}3"


def _luna_master(x: np.ndarray, lp: float = 7000) -> np.ndarray:
    return highpass(lowpass(reverb(x, size=0.75, damp=0.55, mix_=0.25), lp), 35)


# --- 3: passeio no queijo (violão + ocarina) ---------------------------------------------------------------------

P3_A = ([("D", [("A4", 4), ("D5", 4), ("F#5", 6), ("E5", 2)]), ("A", [("E5", 8), ("C#5", 4), (".", 4)]),
         ("Bm", [("D5", 4), ("F#5", 4), ("B5", 6), ("A5", 2)]), ("G", [("G5", 12), (".", 4)]),
         ("D", [("A5", 4), ("F#5", 4), ("D5", 4), ("F#5", 4)]), ("A", [("E5", 4), ("C#5", 4), ("A4", 8)]),
         ("G", [("B4", 4), ("D5", 4), ("G5", 4), ("F#5", 4)]), ("A", [("E5", 12), (".", 4)])])
P3_A2 = P3_A[:5] + [("G", [("B4", 4), ("D5", 4), ("G5", 8)]), ("A", [("E5", 4), ("C#5", 4), ("A4", 4), ("C#5", 4)]),
                    ("D", [("D5", 12), (".", 4)])]
P3_B = [("G", [("B5", 6), ("A5", 2), ("G5", 8)]), ("A", [("A5", 6), ("G5", 2), ("E5", 8)]),
        ("F#m", [("F#5", 4), ("A5", 4), ("C#6", 4), ("A5", 4)]), ("Bm", [("B5", 12), (".", 4)]),
        ("Em7", [("G5", 4), ("E5", 4), ("B4", 4), ("E5", 4)]), ("A", [("C#5", 4), ("E5", 4), ("A5", 8)]),
        ("D", [("F#5", 4), ("E5", 4), ("D5", 4), ("A4", 4)]), ("D", [("D5", 8), (".", 8)])]


def passeio() -> np.ndarray:
    bpm = 86
    gtr_only = lambda cs: [(c, None) for c in cs]
    form = ([("intro", x) for x in gtr_only(["D", "A", "G", "A"])] + [("A", x) for x in P3_A]
            + [("A2", x) for x in P3_A2] + [("B", x) for x in P3_B]
            + [("resp", x) for x in gtr_only(["G", "A", "Bm", "A"])] + [("A2b", x) for x in P3_A2]
            + [("outro", x) for x in gtr_only(["G", "A", "D", "D"])])
    oca, pno, gtr, bass, shk = [], [], [], [], []
    for sec, (c, m) in form:
        r, t, f, x = tones(c)
        bar_m = _bar(*m) if m else _bar(_REST)
        oca.append(bar_m if sec in ("A", "B", "A2b") else _bar(_REST))
        pno.append(bar_m if sec == "A2" else _shift_oct(bar_m) if sec == "A2b" else _bar(_REST))
        chord_ = f"{r}3+{t}3+{f}3" if r in ("D", "E", "F#") else f"{r}2+{t}3+{f}3"
        gtr.append(_bar((".", 4), (chord_, 4), (".", 4), (chord_, 4)))
        bass.append(_bar((low(r), 4), (".", 4), (f"{f}2" if f in ("A", "B", "G") else f"{f}3", 4), (".", 4)))
        shk.append("..x...x...x...x." if sec in ("B", "A2b") else "................")
    song = Song(bpm=bpm, bars=len(form))
    eco = lambda x: delay(x, time=60 / bpm * 0.75, feedback=0.2, mix_=0.15, pingpong=True)
    song.add("violao", nylon(), " ".join(gtr), gain_db=-12, pan=-0.2)
    song.add("baixo", _bass_inst(r=0.15), " ".join(bass), gain_db=-12)
    song.add("ocarina", _lead_ocarina(), " ".join(oca), gain_db=-6, pan=0.1, fx=eco)
    song.add("piano", felt_piano(), " ".join(pno), gain_db=-10, fx=eco)
    song.add("chocalho", drum_hat(), "".join(shk), drum=True, gain_db=-30)
    return song.render(loop=True, master_fx=_luna_master)


def _shift_oct(bar: str) -> str:
    """Uma oitava abaixo (piano dobrando a ocarina na última volta)."""
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    out = []
    for tok in bar.split():
        if tok in (".", "-"):
            out.append(tok)
        else:
            m = midi(tok) - 12
            out.append(f"{names[m % 12]}{m // 12 - 1}")
    return " ".join(out)



LUNA_PICK = "A"
TRACKS = {"title": title, "flight": flight, "theme": lambda: theme(THEME_PICK, THEME_BPM, THEME_DRUMS),
          "flight_luna": passeio}

if __name__ == "__main__":
    out = "assets/audio/music/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/music/title.wav assets/audio/music/flight.wav assets/audio/music/theme.wav
    # assets/audio/music/flight_luna.wav
    # assets/audio/music/layer_luna.wav assets/audio/music/layer_cogumelos.wav assets/audio/music/layer_bolhas.wav
    # assets/audio/music/layer_jardim.wav assets/audio/music/layer_sorvete.wav assets/audio/music/layer_nuvens.wav
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    names = [a for a in args if a in TRACKS] or ([] if args else list(TRACKS))
    for name in names:
        save_wav(f"{out}{name}.wav", TRACKS[name](), "music", loop=True)
    if "theme_options" in args:                              # prévia das opções do tema (não exporta)
        for opt in [a for a in args if a in THEME_LEADS] or ("A", "B"):
            save_wav(f"audio/previews/theme_{opt}.wav", theme(opt), "music", loop=True)
    if "luna_options" in args:                               # prévia das 3 opções do voo da Lua (não exporta)
        for opt in "ABC":
            save_wav(f"audio/previews/luna/flight_luna_{opt}.wav", flight_luna(opt), "music", loop=True)
    if "lullabies" in args:                                  # prévia das canções de ninar (não exporta)
        for k in LULLABIES:
            save_wav(f"audio/previews/luna/ninar_{k}.wav", lullaby(k), "music", loop=True)
    if "tempo_options" in args:                              # prévia do tema mais lento (Noite de história)
        for bpm, drums in ((76, "full"), (68, "soft"), (60, "none")):
            save_wav(f"audio/previews/theme_D_{bpm}.wav", theme("D", bpm, drums), "music", loop=True)
    if "layers" in args or not args:
        for w in LAYERS:
            save_wav(f"{out}layer_{w}.wav", layer(w), "music", loop=True, do_normalize=False)
