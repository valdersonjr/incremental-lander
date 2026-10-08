# Sons dos minijogos (acerto ≠ erro)

**Assets:** assets/audio/sfx/boing_1..3.wav, bump.wav, sheep_1..5.wav, pass_1..3.wav — fonte `audio/src/sfx/minigame_sfx.py`.
**Uso:** `Flight._tick_caps` (boing do degrau i), `_tick_stems` (bump / pass_n), `_tick_sheep` (sheep_n).

## Regras aprendidas
- Acerto e erro nunca com o mesmo som (antes: quique e batida = pouso; carneirinho e vão = cristal).
- Erro no meio da tentativa (bater no caule) = curto e quase plano (tenta de novo); queda até sumir = derrota.
- "Boing": a nota estica (sobe uma quinta em 60 ms) e oscila rápido até assentar (16 Hz, ±2,5 semitons decaindo);
  com ±1,2 semitom a oscilação quase não aparecia no espectrograma.
- Cadeias sobem um grau da pentatônica de Ré por item (a escada dos cogumelos e a fila "se ouvem").

## Receita final
| som | camadas |
|---|---|
| boing_n | triângulo D5/F#5/A5 → +quinta, oscilação 16 Hz, ADSR 4 ms/80 ms/0,5/150 ms + clique de pulso 25% (−14 dB), LP 5 kHz |
| bump | triângulo A3→F#3 (decay 50 ms) + ruído marrom LP 600 Hz (−6 dB), LP 1,8 kHz (98% em 60–250 Hz) |
| sheep_n | pulso 25% com vibrato 9 Hz ±0,7 st, duas sílabas (nota e +2 st), E5…D6 |
| pass_n | ruído rosa em passa-banda subindo 800→3000 Hz (−6 dB) + sino FM 3:1 em A5/B5/D6 |

## Fontes
- https://voxbooster.com/blog/boing-sound-effect/
- https://morphic.com/resources/sounds/fail-sound-effect
- https://code.tutsplus.com/quick-tip-make-retro-low-fi-game-sound-effects-with-bfxr--gamedev-11579t

Status: tocado para o usuário no resumo `audio/previews/minigame_reel.wav` (2026-10-08) — aguardando aprovação.
