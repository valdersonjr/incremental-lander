# Estrela de missão

- **Slug**: mission-star
- **kind**: sfx (mono, −16 LUFS, ~0,4 s)
- **Evento/frequência**: a cada entrega concluída (ganha 1 estrela), ~0,55 s depois do "entregue" — frequente: curta,
  suave, sem agudo estridente, reconhecível (não randomizar demais: é a "moeda" da árvore de PEDIDOS).
- **Asset** ← `audio/src/sfx/star_sfx.py --export`: `assets/audio/sfx/star.wav`. Liberar missão = jingle `unlock`.

## Pesquisa
- Coleta clássica: duas notas rápidas subindo (sfxr COIN); estrela/brilho: sino fino + cauda de ar cintilante.
- Som frequente cansa: variação leve de pitch/volume no motor (AudioStreamRandomizer), mas manter a identidade.

## Opções (2026-10-06)
- A: sino duplo D6→A6 (seno + 2º harmônico) + ruído rosa 5–8 kHz com tremolo 22 Hz a −20 dB.
- B: três pulsos 12,5% F#6 A6 D7 + eco 90 ms (48% de energia em 3–8 kHz: agudo demais para som frequente).
- C: triângulo deslizando D6→A6 + sino A6 por cima (mais redondo).

## Decisões do usuário
- 2026-10-06: usuário pediu para continuar sem ouvir no Mac (arquivos enviados ao celular); ficou a **A** (recomendada) — trocar = CHOSEN em star_sfx.py + --export.

## Fontes
- https://pyfxr.readthedocs.io/en/stable/generating.html — preset COIN do sfxr: dois blips subindo
- https://elevenlabs.io/sound-effects/collect — sparkle: ping de sino fino com cauda de ar
- https://sounddesign.irpr.agency/guides/why-is-my-game-audio-repetitive/ — fadiga: variação de pitch/volume, mas o "som da moeda" precisa de reconhecimento
