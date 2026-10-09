"""Ambiência de cada mundo (padrão: patterns/world-ambience.md). Loops estéreo de LOOP s, -24 LUFS, embaixo de tudo:
cama contínua (drone/ar) + eventos esparsos com variação (nunca rítmicos), tonal em D.
  luna      — Lua de queijo: drone espacial + picaretas da mina ao longe + sininhos (2026-10-09: sai a batalha e o vento)
  cogumelos — floresta morna: folhas, passarinhos, gotas
  bolhas    — fundo do mar: tudo abafado, bolhas, baleia bem longe
  jardim    — brisa, abelhinhas passando, passarinhos
  sorvete   — ar frio e fino, cristais de gelo tilintando, rangido raro
  nuvens    — vento alto e macio, sinos de vento, carneirinhos longe
Rodar da raiz: python3 audio/src/ambience/world_ambience.py [--export] [luna]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *

LOOP = 24.0          # s; LFOs com número inteiro de ciclos no loop
TAIL = 4.0           # s de cauda dobrada sobre o início (wrap_tail)


def _lfo_k(k: int, lo: float, hi: float, phase: float = 0.0) -> np.ndarray:
    """LFO senoidal com k ciclos exatos no loop (fecha a emenda), na duração com cauda."""
    return lfo(LOOP + TAIL, k / LOOP, lo, hi, "sine", phase)


def _bed_air(seed: int, lo: float, hi: float, k: int, db: float) -> np.ndarray:
    """Ar/ruído rosa com passa-baixa que respira devagar (k ciclos no loop), estéreo por seeds diferentes."""
    d = LOOP + TAIL
    out = []
    for ch in range(2):
        n = noise(d, "pink", seed=seed + ch)
        out.append(svf(n, _lfo_k(k, lo, hi, phase=0.25 * ch), q=0.6, mode="lp"))
    return np.stack(out, axis=1) * db_to_lin(db)


def _place(events: list, rng: np.random.Generator, count: int, make, db: tuple[float, float],
           span: tuple[float, float] = (0.8, LOOP - 1.5)) -> None:
    """Espalha `count` eventos sem ritmo no loop (intervalos irregulares), com pan e volume variados."""
    slots = np.sort(rng.uniform(span[0], span[1], count))
    for i, t in enumerate(slots):
        x = make(i, rng)
        events.append((pan(x, float(rng.uniform(-0.8, 0.8))), float(t), float(rng.uniform(*db))))


def _finish(beds: list, events: list, size: float, damp: float, wet: float) -> np.ndarray:
    """Cama contínua fecha por crossfade (LFOs com ciclos inteiros); eventos ganham espaço (reverb) e a cauda que
    passa do fim é dobrada sobre o início — nada corta na emenda."""
    bed = make_loop(to_stereo(mix(beds, LOOP + TAIL)), LOOP, crossfade=1.5)
    ev = reverb(to_stereo(mix(events, LOOP + TAIL)), size=size, damp=damp, mix_=wet)
    return bed + wrap_tail(to_stereo(ev), LOOP)


# --- eventos reutilizáveis (todos na escala, curtos, fofos) ------------------------------------------------------

def _chirp(i: int, r: np.random.Generator) -> np.ndarray:
    """Passarinho: 2-4 piados (seno com glissando + vibrato rápido) em notas da pentatônica aguda."""
    out = []
    for k in range(int(r.integers(2, 5))):
        f = snap(float(r.uniform(1800, 3200)))
        d = float(r.uniform(0.05, 0.09))
        g = sine(vibrato(sweep(f * 0.85, f, d), d, 25, 0.4), d) * adsr(d, 0.004, 0.02, 0.6, 0.03)
        out.append((g, k * float(r.uniform(0.09, 0.14)), 0))
    return lowpass(mix(out), 5000) * 0.5


def _bell_far(i: int, r: np.random.Generator, lo: float = 900, hi: float = 2000, dur: float = 1.4) -> np.ndarray:
    f = snap(float(r.uniform(lo, hi)))
    return lowpass(fm(f, dur, ratio=3.5, index=env([(0, 1.8), (dur, 0.1)], dur)) * decay(dur, dur * 0.3), 3500) * 0.5


def _chimes(i: int, r: np.random.Generator) -> np.ndarray:
    """Sinos de vento: 3-5 notas da pentatônica tocando quase juntas, como um móbile batendo com a brisa."""
    return mix([(_bell_far(i, r, 1200, 2600, 1.2), k * float(r.uniform(0.07, 0.2)), float(r.uniform(-6, 0)))
                for k in range(int(r.integers(3, 6)))])


def _bubble_burst(i: int, r: np.random.Generator) -> np.ndarray:
    """Cachinho de bolhas subindo (receita de bolha: seno curto com pitch subindo)."""
    out = []
    for k in range(int(r.integers(4, 9))):
        f0 = float(r.uniform(300, 900))
        d = float(r.uniform(0.04, 0.08))
        out.append((sine(sweep(f0, f0 * 2.3, d), d) * decay(d, d * 0.3), k * float(r.uniform(0.04, 0.12)),
                    float(r.uniform(-8, 0))))
    return lowpass(mix(out), 3000) * 0.6


def _drone(root: str, fifth: str, d: float, k: int, db_fifth: float = -15) -> np.ndarray:
    a = unison(sine, note(root), d, voices=4, detune_cents=7, stereo=True) * 0.5
    b = unison(triangle, note(fifth), d, voices=3, detune_cents=9, stereo=True) * db_to_lin(db_fifth)
    return (a + b) * _lfo_k(k, 0.55, 1.0)[:, None]


# --- Lua de queijo (mina, vila e parquinho dos ratinhos) -----------------------------------------------------------

def luna() -> np.ndarray:
    """Espaço calmo e aconchegante: drone em D + ar; ao longe, picaretas na mina de queijo (tlim metálico) e
    sininhos da vila. (Antes: estrondos de batalha — não combinam mais com a Lua fofa.)"""
    d = LOOP + TAIL
    rng = np.random.default_rng(101)
    beds = [(_drone("D2", "A2", d, 2), 0, -9)]                # sem o "ar" (ruído rosa): o usuário achou o vento chato
    events = []

    def pick(i: int, r: np.random.Generator) -> np.ndarray:      # picareta: 2-3 tlins secos de metal na escala
        f = snap(float(r.uniform(900, 1500)))
        hit = fm(f, 0.25, 2.76, 2.5 * decay(0.25, 0.04)) * decay(0.25, 0.05)
        return lowpass(mix([(hit, k * 0.42, -2 * k) for k in range(int(r.integers(2, 4)))]), 3000) * 0.5

    _place(events, rng, 5, pick, (-10, -5))
    _place(events, rng, 3, _bell_far, (-11, -6))
    return _finish(beds, events, 0.85, 0.5, 0.3)


# --- Cogumelos (floresta de cogumelos-mola) ------------------------------------------------------------------------

def cogumelos() -> np.ndarray:
    """Floresta morna: drone grave em D + folhas farfalhando (rosa com filtro lento) + passarinhos e gotas."""
    d = LOOP + TAIL
    rng = np.random.default_rng(201)
    beds = [(_drone("D2", "A2", d, 2, -12), 0, -18), (_bed_air(11, 400, 1400, 4, -9), 0, 0)]
    events = []

    def drip(i: int, r: np.random.Generator) -> np.ndarray:      # gota caindo do chapéu do cogumelo
        f0 = float(r.uniform(700, 1200))
        return sine(sweep(f0, f0 * 2.0, 0.05), 0.05) * decay(0.05, 0.015) * 0.6

    _place(events, rng, 7, _chirp, (-9, -3))
    _place(events, rng, 6, drip, (-12, -6))
    return _finish(beds, events, 0.7, 0.5, 0.25)


# --- Bolhas (fundo do mar) -----------------------------------------------------------------------------------------

def bolhas() -> np.ndarray:
    """Debaixo d'água: tudo abafado (passa-baixa), drone que ondula, cachinhos de bolhas e um canto de baleia
    bem longe (seno deslizando D3 -> A3 -> F#3)."""
    d = LOOP + TAIL
    rng = np.random.default_rng(301)
    water = np.stack([svf(noise(d, "brown", 302 + c), _lfo_k(3, 180, 420, 0.3 * c), 0.7, "lp") for c in range(2)],
                     axis=1)
    beds = [(_drone("D2", "A2", d, 3, -12), 0, -16), (water, 0, -11)]
    events = []

    def whale(i: int, r: np.random.Generator) -> np.ndarray:
        dur = 3.0
        f = env([(0, note("D3")), (1.2, note("A3")), (dur, note("F#3"))], dur)
        return lowpass(sine(vibrato(f, dur, 4, 0.15), dur), 900) * env([(0, 0), (0.6, 1), (2.4, 0.8), (dur, 0)], dur)

    _place(events, rng, 14, _bubble_burst, (-4, 0))
    _place(events, rng, 2, whale, (-14, -10), span=(2.0, LOOP - 4.0))
    return _finish(beds, events, 0.9, 0.6, 0.35)


# --- Jardim (flores, vento de dente-de-leão, mel) -------------------------------------------------------------------

def jardim() -> np.ndarray:
    """Jardim ensolarado: brisa média + abelhinhas passando (zumbido de serra filtrada com tremolo, panorama
    andando) + passarinhos."""
    d = LOOP + TAIL
    rng = np.random.default_rng(401)
    beds = [(_drone("D3", "A3", d, 2, -14), 0, -18), (_bed_air(21, 500, 1800, 3, -8), 0, 0)]
    events = []

    def bee(i: int, r: np.random.Generator) -> np.ndarray:
        dur = float(r.uniform(1.5, 2.5))
        f = vibrato(snap(float(r.uniform(180, 260))), dur, 5, 0.6)
        buzz = bandpass(saw(f, dur), 300, 2500) * (1 - 0.35 * np.sin(2 * np.pi * 45 * t_axis(dur)))
        return buzz * env([(0, 0), (dur * 0.5, 1), (dur, 0)], dur) * 0.4

    _place(events, rng, 4, bee, (-9, -4))
    _place(events, rng, 6, _chirp, (-9, -4))
    return _finish(beds, events, 0.6, 0.5, 0.2)


# --- Sorvete (pista de gelo) -----------------------------------------------------------------------------------------

def sorvete() -> np.ndarray:
    """Frio brilhante: ar fino e agudo (rosa em banda 1,5-4 kHz, bem baixo), cristais de gelo tilintando (sinos FM
    agudos) e um rangido de gelo grave e raro."""
    d = LOOP + TAIL
    rng = np.random.default_rng(501)
    cold = np.stack([svf(noise(d, "pink", 502 + c), _lfo_k(2, 1500, 3500, 0.4 * c), 0.9, "bp") for c in range(2)],
                    axis=1)
    beds = [(_drone("D3", "A3", d, 2, -12), 0, -18), (cold, 0, -10), (_bed_air(23, 250, 600, 3, -12), 0, 0)]
    events = []

    def tinkle(i: int, r: np.random.Generator) -> np.ndarray:
        return mix([(_bell_far(i, r, 2000, 3600, 0.8), k * float(r.uniform(0.05, 0.12)), -3 * k)
                    for k in range(int(r.integers(2, 4)))])

    def creak(i: int, r: np.random.Generator) -> np.ndarray:
        dur = 0.8
        return lowpass(fm(sweep(snap(220), snap(160), dur), dur, 1.41, 1.5), 1200) * env([(0, 0), (0.1, 1), (dur, 0)], dur) * 0.4

    _place(events, rng, 7, tinkle, (-9, -4))
    _place(events, rng, 2, creak, (-14, -10))
    return _finish(beds, events, 0.85, 0.35, 0.3)


# --- Nuvens (céu dos carneirinhos) -----------------------------------------------------------------------------------

def nuvens() -> np.ndarray:
    """Céu aberto: vento alto e macio que sobe e desce, sinos de vento e carneirinhos bem longe."""
    d = LOOP + TAIL
    rng = np.random.default_rng(601)
    beds = [(_drone("A2", "D3", d, 2, -12), 0, -18), (_bed_air(31, 600, 2200, 2, -6), 0, 0)]
    events = []

    def baa(i: int, r: np.random.Generator) -> np.ndarray:      # "bé" do carneirinho, longe e abafado
        f = snap(float(r.uniform(500, 700)))
        x = pulse(vibrato(f, 0.3, 9.0, 0.7), 0.3, duty=0.25) * adsr(0.3, 0.01, 0.05, 0.6, 0.12)
        return lowpass(x, 1800) * 0.4

    _place(events, rng, 4, _chimes, (-8, -3))
    _place(events, rng, 3, baa, (-12, -8))
    return _finish(beds, events, 0.9, 0.4, 0.35)


WORLDS = {"luna": luna, "cogumelos": cogumelos, "bolhas": bolhas, "jardim": jardim, "sorvete": sorvete,
          "nuvens": nuvens}

if __name__ == "__main__":
    out = "assets/audio/ambience/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/ambience/luna.wav assets/audio/ambience/cogumelos.wav assets/audio/ambience/bolhas.wav
    # assets/audio/ambience/jardim.wav assets/audio/ambience/sorvete.wav assets/audio/ambience/nuvens.wav
    names = [a for a in sys.argv[1:] if a in WORLDS] or list(WORLDS)
    for name in names:
        save_wav(f"{out}{name}.wav", WORLDS[name](), "ambience", loop=True)
