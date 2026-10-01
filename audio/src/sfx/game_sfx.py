"""SFX de gameplay: pouso (3 variações), explosão da batida, entrega concluída (jingle). Padrão: patterns/game-sfx.md.
Secos (sem reverb assado), tonais na escala do projeto (D pentatônica). Rodar da raiz: python3 audio/src/sfx/game_sfx.py
"""
import sys

sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *


def landing(seed: int) -> np.ndarray:
    """Pouso: thump grave + poeira curta + clanque leve do trem na plataforma (metal FM)."""
    base = p_landing(seed=seed, soft=True)
    rng = np.random.default_rng(seed)
    clank = fm(snap(rng.uniform(500, 700)), 0.18, 1.41, 2.0 * decay(0.18, 0.05)) * decay(0.18, 0.04)
    return fade(mix([(base, 0, 0), (clank, 0.012, -14)]), 0.002, 0.08)


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
    bell = inst_bell(tau=0.3)(note("D6"), 0.5, 1.0)
    return fade(mix([(arp_part, 0, 0), (bell, 3 * step, -6)]), 0.001, 0.15)


# caminhos literais gerados por save_variations (o pre-commit procura a fonte de cada asset pelo caminho):
# assets/audio/sfx/landing_01.wav assets/audio/sfx/landing_02.wav assets/audio/sfx/landing_03.wav

if __name__ == "__main__":
    save_variations(landing, "assets/audio/sfx/landing.wav", "sfx", 3, tres_path="assets/audio/sfx/landing.tres")
    save_wav("assets/audio/sfx/crash.wav", crash(), "impact")
    save_wav("assets/audio/sfx/delivered.wav", delivered(), "jingle")
