"""SFX de gameplay: pouso (3 variações), explosão da batida, entrega concluída (jingle). Padrão: patterns/game-sfx.md.
Secos (sem reverb assado), tonais na escala do projeto (D pentatônica). Rodar da raiz: python3 audio/src/sfx/game_sfx.py
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def landing(seed: int) -> np.ndarray:
    """Pouso: thump grave + "tuc" de corpo (triângulo A3 -> D3, 150-650 Hz) + poeira em banda + clanque do trem.
    Auditoria 2026-10-09 (v2): o thump puro tinha 93% da energia < 120 Hz e sumia no alto-falante de notebook (-10 dB);
    o corpo em triângulo carrega o peso por harmônicos (fundamental ausente) e libera o sub para a música."""
    rng = np.random.default_rng(seed)
    thump = sine(sweep(90, 45, 0.22), 0.22) * decay(0.22, 0.06)
    body = triangle(sweep(note("A3"), note("D3"), 0.12), 0.12) * decay(0.12, 0.035)
    dust = bandpass(noise(0.4, "pink", seed), 250, 1500) * decay(0.4, 0.09)
    clank = fm(snap(rng.uniform(500, 700)), 0.18, 1.41, 2.0 * decay(0.18, 0.05)) * decay(0.18, 0.04)
    x = mix([(thump, 0, -8), (body, 0, 0), (dust, 0.008, -9), (clank, 0.012, -11)])
    return fade(lowpass(x, 5000), 0.002, 0.08)


def crash() -> np.ndarray:
    """Batida: zap de plasma rompendo (FM descendo, casa com o flash ciano) + explosão em camadas."""
    zap = fm(sweep(2200, 180, 0.16), 0.16, 1.5, 3.0 * decay(0.16, 0.05)) * decay(0.16, 0.06)
    boom = drive(p_explosion(seed=7, size=1.1), 1.6)
    return fade(mix([(zap, 0, -6), (boom, 0.02, 0)]), 0.001, 0.3)


def delivered() -> np.ndarray:
    """Entrega concluída: arpejo subindo na escala (D-F#-A-D) + sino FM na nota final. Curto: toca a cada entrega."""
    notes = [note("D5"), note("F#5"), note("A5"), note("D6")]
    step = 0.07
    arp_part = mix([(pulse(f, 0.12, duty=0.25) * decay(0.12, 0.05), i * step, -4) for i, f in enumerate(notes)])
    bell = inst_bell(tau=0.18)(note("D6"), 0.4, 1.0)
    # v2 (auditoria 2026-10-09): 16% da energia > 5 kHz num som que toca a cada entrega -> passa-baixa 4,5 kHz e sino
    # mais curto (o combo entra 0,35 s depois por cima: a cauda não pode embolar com ele)
    return fade(lowpass(mix([(arp_part, 0, 0), (bell, 3 * step, -8)]), 4500), 0.001, 0.15)


# caminhos literais gerados por save_variations (o pre-commit procura a fonte de cada asset pelo caminho):
# assets/audio/sfx/landing_01.wav assets/audio/sfx/landing_02.wav assets/audio/sfx/landing_03.wav

if __name__ == "__main__":
    only = [a for a in sys.argv[1:] if not a.startswith("--")]      # nomes = exporta só esses (landing, crash, delivered)
    if not only or "landing" in only:
        save_variations(landing, "assets/audio/sfx/landing.wav", "sfx", 3)  # sorteio no Sound.VARIANTS (sem .tres: web)
    if not only or "crash" in only:
        save_wav("assets/audio/sfx/crash.wav", crash(), "impact")
    if not only or "delivered" in only:
        save_wav("assets/audio/sfx/delivered.wav", delivered(), "jingle")
