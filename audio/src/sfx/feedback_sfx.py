"""Respostas de gameplay que faltavam (auditoria de som, 2026-10-09). Padrão: patterns/feedback-sfx.md.
Secos, tonais na escala do projeto (D pentatônica), fofos (público de 6 anos: nada estridente nem assustador).
  landing_heavy  camada extra do pouso forte (o jogo toca junto do landing quando a descida foi rápida)
  rcs_loop       chiado leve dos jatinhos de giro (loop; o jogo toca baixinho enquanto gira)
  sputter        motor tossindo quando o gás acaba no meio do voo
  chest          a garra pegou o baú (clanque de metal + sininho)
  gas_glug       galão de gás: glub-glub-glub subindo (tanque enchendo)
  gift_coin      presente de moedas (moeda dupla brilhante)
  squeak         ratinho pulou na nave (iic-iic feliz)
  target_hit     curling "no alvo!" (tim-tim, entre o cristal e a estrela)
  oops           regra da missão falhou / curling fora do alvo (uá-uá suave, sem assustar)
  splash         nave caiu no mar (Bolhas): tchibum + bolhas, no lugar da explosão
  retry          "tente de novo" (bip-bup-bip perguntando, encorajador)
  aboard         carga/passageiro a bordo (dois degraus subindo + brilho)
  world_arrive   chegada num mundo (cortina subindo + acorde de sino) — jingle
  summary_end    fim da contagem do resumo — jingle curto
  record         NOVO RECORDE no resumo — jingle
  crash_soft     batida fofa: "puf" + apito de desenho caindo (substitui a explosão pesada; a antiga fica em crash.wav)
Rodar da raiz: python3 audio/src/sfx/feedback_sfx.py [--export] [--reel]
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def landing_heavy() -> np.ndarray:
    """Pancada: thump mais fundo (75 -> 32 Hz) + metal do trem (FM ratio 1,41, não inteiro) + chocalho curto."""
    thump = sine(sweep(75, 32, 0.35), 0.35) * decay(0.35, 0.11)
    harm = triangle(sweep(150, 64, 0.2), 0.2) * decay(0.2, 0.05)            # harmônico: o peso aparece no notebook
    clank = fm(snap(380), 0.3, 1.41, 3.0 * decay(0.3, 0.06)) * decay(0.3, 0.07)
    rattle = bandpass(noise(0.18, "white", 31), 900, 3000) * decay(0.18, 0.04)
    return fade(lowpass(mix([(thump, 0, 0), (harm, 0, -2), (clank, 0.01, -6), (rattle, 0.015, -16)]), 5000),
                0.001, 0.06)


def rcs_loop() -> np.ndarray:
    """Jatinho de giro: sopro de ruído rosa em banda (1,2-3,5 kHz) com filtro respirando (2 ciclos no loop)."""
    loop, pre = 1.0, 0.3
    total = loop + 0.2 + pre
    cut = lfo(total, 2 / loop, 1600, 2600, "sine")
    x = svf(noise(total, "pink", 61), cut, 1.0, "bp") + highpass(noise(total, "white", 62), 3000) * 0.05
    return make_loop(tremolo(x, 30, 0.08)[ns(pre):], loop, crossfade=0.12)


def sputter() -> np.ndarray:
    """Tosse do motor: 3 estouros de ruído grave + tom de pulso caindo (cada um mais fraco e mais espaçado),
    e um último suspiro de ar. Pitch descendo = perda."""
    parts = []
    for i, (t, f) in enumerate([(0.0, 140), (0.15, 115), (0.36, 90)]):
        d = 0.11
        cough = lowpass(noise(d, "brown", 70 + i), 700) * decay(d, 0.03)
        tone = lowpass(pulse(sweep(f, f * 0.7, d), d, duty=0.25), 900) * decay(d, 0.035)
        parts += [(cough, t, -2 - 3 * i), (tone, t, -6 - 3 * i)]
    sigh = svf(noise(0.4, "pink", 75), sweep(1500, 300, 0.4), 0.8) * env([(0, 0), (0.05, 1), (0.4, 0)], 0.4)
    parts.append((sigh, 0.5, -14))
    return fade(mix(parts), 0.001, 0.08)


def chest() -> np.ndarray:
    """Garra pegou o baú: clanque metálico (FM 2,76) + baque de madeira + sininho A5 (pegou = bom)."""
    clank = fm(snap(620), 0.22, 2.76, 3.5 * decay(0.22, 0.04)) * decay(0.22, 0.05)
    wood = lowpass(noise(0.07, "brown", 81), 900) * decay(0.07, 0.02) + triangle(note("A3"), 0.07) * decay(0.07, 0.02)
    ding = fm(note("A5"), 0.3, 3.5, env([(0, 1.8), (0.3, 0.2)], 0.3)) * decay(0.3, 0.08)
    return fade(lowpass(mix([(clank, 0, -6), (wood, 0, -3), (ding, 0.07, -2)]), 6500), 0.001, 0.06)


def _bubble(f0: float, dur: float = 0.06) -> np.ndarray:
    """Bolha/gota: seno com pitch subindo rápido e decaindo (receita clássica de bolha sintetizada)."""
    return sine(sweep(f0, f0 * 2.4, dur), dur) * decay(dur, dur * 0.3)


def gas_glug() -> np.ndarray:
    """Galão: glub-glub-glub (bolhas graves subindo de altura) + nota D6 de "cheio"."""
    parts = [(_bubble(f, 0.09), t, -1) for t, f in [(0, 220), (0.1, 280), (0.2, 360)]]
    parts.append((triangle(note("D6"), 0.2) * decay(0.2, 0.06), 0.3, -8))
    return fade(lowpass(mix(parts), 5000), 0.001, 0.05)


def gift_coin() -> np.ndarray:
    """Presente de moedas: B5 -> E6 em pulso 50% (moeda retrô) + brilho FM curto na segunda nota."""
    a = pulse(note("B5"), 0.06, duty=0.5) * decay(0.06, 0.03)
    b = pulse(note("E6"), 0.22, duty=0.5) * decay(0.22, 0.07)
    shine = fm(note("E6") * 2, 0.15, 2.0, env([(0, 1.2), (0.15, 0.1)], 0.15)) * decay(0.15, 0.04)
    return fade(lowpass(mix([(a, 0, -2), (b, 0.06, 0), (shine, 0.06, -14)]), 6000), 0.001, 0.05)


def squeak() -> np.ndarray:
    """Ratinho feliz: dois "iic" (seno com glissando subindo + vibrato rápido) + nota alegre."""
    def chirp(f0: float, f1: float, d: float) -> np.ndarray:
        return sine(vibrato(sweep(f0, f1, d), d, 28, 0.6), d) * adsr(d, 0.004, 0.02, 0.7, 0.03)
    happy = triangle(note("A5"), 0.16) * decay(0.16, 0.05)
    x = mix([(chirp(1500, note("F#6"), 0.07), 0, 0), (chirp(1700, note("A6"), 0.08), 0.1, 0), (happy, 0.2, -6)])
    return fade(lowpass(x, 6000), 0.001, 0.04)


def target_hit() -> np.ndarray:
    """No alvo: tim-tim (dois sinos FM, F#5 -> A5)."""
    def bell(n: str) -> np.ndarray:
        return fm(note(n), 0.3, 3.5, env([(0, 2.0), (0.3, 0.2)], 0.3)) * decay(0.3, 0.08)
    return fade(lowpass(mix([(bell("F#5"), 0, -1), (bell("A5"), 0.1, 0)]), 6500), 0.001, 0.06)


def oops() -> np.ndarray:
    """Uá-uá suave: triângulo B4 -> A4 -> F#4 com cada nota escorregando um pouco para baixo; grave-médio, sem agudo."""
    parts = []
    for i, n in enumerate(["B4", "A4", "F#4"]):
        d = 0.14 if i < 2 else 0.26
        f = note(n)
        parts.append((triangle(sweep(f, f * 0.95, d), d) * adsr(d, 0.01, 0.04, 0.7, 0.06), i * 0.13, 0))
    return fade(lowpass(mix(parts), 2500), 0.002, 0.06)


def splash() -> np.ndarray:
    """Tchibum: estouro de ruído com passa-baixa caindo (água) + corpo grave + chuva de bolhas subindo depois."""
    rng = np.random.default_rng(91)
    d = 0.7
    hit = svf(noise(d, "white", 92), sweep(5000, 400, d), 0.8) * decay(d, 0.12)
    body = sine(sweep(120, 45, 0.3), 0.3) * decay(0.3, 0.08)
    parts = [(hit, 0, 0), (body, 0, -4)]
    for k in range(9):
        parts.append((_bubble(float(rng.uniform(300, 900)), float(rng.uniform(0.04, 0.08))),
                      0.15 + k * float(rng.uniform(0.05, 0.09)), -8 - k))
    return fade(lowpass(mix(parts), 7000), 0.001, 0.1)


def retry() -> np.ndarray:
    """Tente de novo: bip-bup-bip (A5, F#5, A5) em triângulo, a última subindo um pouquinho (pergunta, convite)."""
    a = triangle(note("A5"), 0.08) * decay(0.08, 0.03)
    b = triangle(note("F#5"), 0.08) * decay(0.08, 0.03)
    c = triangle(sweep(note("A5"), note("B5"), 0.16), 0.16) * decay(0.16, 0.06)
    return fade(lowpass(mix([(a, 0, 0), (b, 0.11, 0), (c, 0.22, 0)]), 4000), 0.001, 0.05)


def aboard() -> np.ndarray:
    """A bordo: D5 -> A5 em pulso 25% (dois degraus subindo) + brilho curto."""
    a = pulse(note("D5"), 0.07, duty=0.25) * decay(0.07, 0.03)
    b = pulse(note("A5"), 0.16, duty=0.25) * decay(0.16, 0.05)
    shine = sine(note("A6"), 0.12) * decay(0.12, 0.03)
    return fade(lowpass(mix([(a, 0, 0), (b, 0.07, 0), (shine, 0.07, -12)]), 5500), 0.001, 0.05)


def _bell(n: str, dur: float, index: float = 2.2) -> np.ndarray:
    return fm(note(n), dur, ratio=3.5, index=env([(0, index), (dur, 0.2)], dur)) * decay(dur, dur * 0.35)


def world_arrive() -> np.ndarray:
    """Chegada: cortina subindo (glissando de triângulo na pentatônica, 0,4 s) + acorde de sino D-F#-A-D com eco."""
    sc = [m for m in scale_midis("sfx") if midi("D4") <= m <= midi("D6")]
    step = 0.4 / len(sc)
    rise = mix([(triangle(mtof(m), 0.08) * decay(0.08, 0.03), i * step, -2) for i, m in enumerate(sc)])
    chord_ = mix([(_bell(n, 1.3), 0.42 + 0.02 * i, -3) for i, n in enumerate(["D5", "F#5", "A5", "D6"])])
    x = mix([(rise, 0, 0), (chord_, 0, 0)])
    return fade(lowpass(delay(x, 0.21, 0.3, 0.25, pingpong=False), 7000), 0.001, 0.3)


def summary_end() -> np.ndarray:
    """Fim da contagem: ta-dá (A5 curto -> D6 com sino)."""
    a = pulse(note("A5"), 0.08, duty=0.25) * decay(0.08, 0.03)
    b = pulse(note("D6"), 0.3, duty=0.25) * decay(0.3, 0.1)
    x = mix([(a, 0, -2), (b, 0.1, 0), (_bell("D6", 0.7), 0.1, -4)])
    return fade(lowpass(x, 7000), 0.001, 0.15)


def record() -> np.ndarray:
    """Novo recorde: arpejo D-F#-A-D-F# rápido + trinado brilhante (A6/B6) + sino final com eco."""
    notes = ["D5", "F#5", "A5", "D6", "F#6"]
    parts = [(pulse(note(n), 0.08, duty=0.25) * decay(0.08, 0.03), i * 0.06, -3) for i, n in enumerate(notes)]
    trill = mix([(sine(note("A6" if k % 2 == 0 else "B6"), 0.05) * decay(0.05, 0.02), 0.32 + k * 0.05, -10)
                 for k in range(8)])
    parts += [(trill, 0, 0), (_bell("D6", 1.2), 0.3, -2)]
    return fade(lowpass(delay(mix(parts), 0.18, 0.28, 0.22, pingpong=False), 7500), 0.001, 0.3)


def crash_soft() -> np.ndarray:
    """Batida fofa: "puf" (ruído com passa-baixa caindo, sem estalo agudo) + baque grave + apito de desenho caindo
    (seno 1400 -> 300 Hz com vibrato) + 3 pedacinhos tilintando. Mantém a leitura de perda (tudo desce)."""
    d = 0.6
    puff = svf(noise(d, "pink", 101), sweep(2500, 150, d), 0.7) * decay(d, 0.14)
    thud = sine(sweep(100, 38, 0.35), 0.35) * decay(0.35, 0.1)
    whistle = sine(vibrato(sweep(1400, 300, 0.7), 0.7, 7, 0.3), 0.7) * env([(0, 0), (0.03, 1), (0.55, 0.7), (0.7, 0)], 0.7)
    bits = mix([(triangle(note(n), 0.08) * decay(0.08, 0.02), 0.75 + 0.09 * i, -8)
                for i, n in enumerate(["F#5", "D5", "A4"])])
    return fade(lowpass(mix([(puff, 0, 0), (thud, 0, -2), (whistle, 0.06, -9), (bits, 0, 0)]), 6000), 0.001, 0.08)


ONE_SHOTS = {"landing_heavy": ("sfx", landing_heavy), "sputter": ("sfx", sputter), "chest": ("sfx", chest),
             "gas_glug": ("sfx", gas_glug), "gift_coin": ("sfx", gift_coin), "squeak": ("sfx", squeak),
             "target_hit": ("sfx", target_hit), "oops": ("sfx", oops), "splash": ("impact", splash),
             "retry": ("sfx", retry), "aboard": ("sfx", aboard), "world_arrive": ("jingle", world_arrive),
             "summary_end": ("jingle", summary_end), "record": ("jingle", record), "crash_soft": ("sfx", crash_soft)}

if __name__ == "__main__":
    out = "assets/audio/sfx/" if "--export" in sys.argv else "audio/previews/"
    # caminhos literais (o pre-commit liga cada asset ao script-fonte):
    # assets/audio/sfx/landing_heavy.wav assets/audio/sfx/rcs_loop.wav assets/audio/sfx/sputter.wav
    # assets/audio/sfx/chest.wav assets/audio/sfx/gas_glug.wav assets/audio/sfx/gift_coin.wav assets/audio/sfx/squeak.wav
    # assets/audio/sfx/target_hit.wav assets/audio/sfx/oops.wav assets/audio/sfx/splash.wav assets/audio/sfx/retry.wav
    # assets/audio/sfx/aboard.wav assets/audio/sfx/world_arrive.wav assets/audio/sfx/summary_end.wav
    # assets/audio/sfx/record.wav assets/audio/sfx/crash_soft.wav
    names = [a for a in sys.argv[1:] if a in ONE_SHOTS] or list(ONE_SHOTS)
    for name in names:
        kind, fn = ONE_SHOTS[name]
        save_wav(f"{out}{name}.wav", fn(), kind)
    if not [a for a in sys.argv[1:] if a in ONE_SHOTS]:
        save_wav(f"{out}rcs_loop.wav", rcs_loop(), "loop", loop=True)
