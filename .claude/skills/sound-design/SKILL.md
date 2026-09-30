---
name: sound-design
description: OBRIGATÓRIA para criar, editar ou ajustar QUALQUER áudio do jogo — efeito sonoro (SFX), som de UI (clique, compra, upgrade, notificação), propulsor, explosão, pouso, alarme, loop de motor, ambiência (drone, vento, espaço) e música/trilha/jingle. Sintetiza o som do zero em Python (estilo retro-synth espacial: pulso, triângulo, serra, ruído, FM, filtros, eco/reverb), travado na escala e nos alvos de loudness do projeto, pesquisando ANTES os padrões de sound design do objeto, validando por análise (LUFS, pico, espectrograma, emenda de loop) e tocando para o usuário aprovar via afplay. Exporta WAV + recursos Godot 4. Use sempre que o usuário pedir som, áudio, efeito sonoro, SFX, barulho, música, trilha, jingle ou ambiência — mesmo sem citar a skill.
---

# Sound Design — retro-synth espacial → Godot 4

Todo som do jogo é **sintetizado por código** com `scripts/soundkit.py`. O script gerador é a
"fonte" do som (como um projeto de DAW); o WAV é o export.

Jogo: **incremental estilo Lunar Lander, visão lateral, Godot 4.** Arte em pixel art (Resurrect 64).

## Regras invioláveis

1. **Todo áudio do projeto passa por esta skill.** Nada de samples baixados ou gerados por outro meio.
2. **Paleta sonora travada** (ver `references/style-guide.md`): só os timbres do soundkit
   (pulso, triângulo, serra, seno, ruídos, chip-noise, FM, filtros, drive, bitcrush, eco, reverb).
3. **Escala travada**: SFX com altura definida usam a escala do projeto (`snap()`, `SFX_SCALE`);
   música usa os modos permitidos no style-guide. Assim tudo soa bem junto.
4. **Loudness travado por categoria**: `save_wav(..., kind=...)` normaliza e valida (LUFS + true peak).
5. **Aprender antes de sintetizar.** Nenhum som é criado antes da Etapa 2 (pesquisa/biblioteca).
6. **Eu não escuto** — reviso por análise (relatório + gráfico com Read). **Quem aprova é o usuário,
   ouvindo** via `afplay`. Nunca declarar um som "bom" só pelos números.
7. **A biblioteca cresce.** Todo som termina atualizando `references/patterns/`.

## Pastas do projeto

```
audio/                        # tem .gdignore (Godot ignora)
  src/<categoria>/<nome>.py   # script gerador = fonte do som
  previews/                   # gráficos (onda + espectrograma + métricas)
assets/audio/                 # o que o Godot importa
  sfx/  ui/  ambience/  music/
```
Rodar a partir da raiz do projeto: `python3 audio/src/<cat>/<nome>.py`. Cabeçalho de todo script:
```python
import sys; sys.path.insert(0, ".claude/skills/sound-design/scripts")
from soundkit import *
```

## Categorias (`kind`) — alvos travados

| kind | Uso | LUFS | Teto | Duração | Canais |
|---|---|---|---|---|---|
| `ui` | clique, hover, compra, notificação | -20 | -1 dBTP | ≤ 0.35 s | mono |
| `sfx` | ações de gameplay (pouso, laser, coleta) | -16 | -1 | ≤ 2 s | mono |
| `impact` | explosões, colisões fortes | -12 | -1 | ≤ 3 s | mono |
| `jingle` | upgrade, desbloqueio, vitória, fanfarra | -16 | -1 | ≤ 4 s | mono |
| `loop` | propulsor, motor, alarme contínuo | -18 | -1 | loop | mono |
| `ambience` | drones, vento, zumbido do espaço | -24 | -3 | loop | estéreo |
| `music` | trilhas | -18 | -1 | loop | estéreo |

## Fluxo obrigatório

### Etapa 0 — Contexto
Leia `references/style-guide.md` (paleta sonora, escala, loudness, decisões) e veja o que já existe
em `assets/audio/` (o novo som precisa conviver com os outros: timbre, altura, volume).

### Etapa 1 — Briefing
Defina e confirme o que não estiver claro (AskUserQuestion só se houver dúvida real):
- O que é, qual evento dispara, **com que frequência toca** (a cada clique? uma vez por partida?).
  Sons frequentes → curtos, suaves, com variações (fadiga!).
- `kind`, duração, loop ou one-shot, precisa de variações? Muda com parâmetro do jogo
  (ex.: potência do propulsor → volume/filtro/pitch no Godot)?
- O que toca junto (música? propulsor?) — define que faixa de frequência está livre.
- Emoção/leitura: recompensa, perigo, neutro, épico, sutil.

### Etapa 2 — Aprender o padrão (OBRIGATÓRIA)
1. Leia **sempre** `references/fundamentals.md`.
2. Leia a referência do tipo: SFX/UI → `references/sfx-recipes.md`; música → `references/music.md`;
   ambiência/loops → `references/ambience-loops.md`. Integração → `references/godot-audio.md`.
3. Procure o som (ou um parente) em `references/patterns/INDEX.md`.
4. **Se não existir padrão, ou for raso, ou houver algo novo → pesquise:**
   - `WebSearch` ≥3 consultas em inglês, ex.: `"<som> sound design synthesis"`,
     `"retro game <som> sound effect sfxr"`, `"<som> sound design layers tutorial"`,
     para música: `"<gênero/humor> game music composition <modo> chord progression"`.
   - `WebFetch` em 1–3 fontes boas (tutoriais de síntese, GDC/gamedeveloper.com, docs do Godot,
     Designing Sound, análises de trilhas de jogos) extraindo **regras acionáveis**: camadas,
     faixas de frequência, envelope, duração, técnicas de síntese, erros comuns.
   - Rodada rasa? repita com `mode: "extended"`.
5. Escreva/atualize `references/patterns/<slug>.md` (modelo `_TEMPLATE.md`) com fontes; registre no INDEX.
6. Resuma ao usuário em 3–6 bullets o que aprendeu e como vai aplicar.

### Etapa 3 — Plano
Antes de codar, escreva (curto):
- **SFX**: tabela de camadas — função (transiente / corpo / sub / detalhe / cauda), oscilador/ruído,
  faixa de frequência, início e duração, envelope, curva de pitch/filtro. Nota(s) da escala.
- **Música**: modo, BPM, compassos, estrutura (A/B/variação), instrumentos por função (lead, arpejo,
  baixo, pad, percussão), progressão de acordes, loop.
- **Ambiência**: camadas, movimento lento (LFOs), eventos esporádicos, duração do loop.

### Etapa 4 — Construir em camadas
Crie `audio/src/<categoria>/<nome>.py`. Construa **uma camada por vez** e exporte cada uma
separada (`save_wav(..., do_normalize=False)` num caminho de rascunho em `audio/previews/`) quando
precisar isolar problema. Depois monte com `mix([(sinal, inicio_s, ganho_db), ...])`.
Presets (`PRESETS`, `p_coin`, `p_explosion`...) são **só pontos de partida** — sempre adapte.

### Etapa 5 — Validar (análise, loop até passar)
- `save_wav(path, x, kind, loop=...)` normaliza, grava e imprime o relatório + gera o gráfico.
- **Abra o gráfico com Read** (`audio/previews/<nome>.png`) e confira com o checklist.
- Corrija e repita até não haver avisos (ou justifique o aviso).

**Checklist de análise**
- [ ] Sem avisos (clipping, DC, silêncio inicial, corte no fim, emenda, loudness, duração)?
- [ ] O envelope na onda tem a forma planejada (ataque rápido? cauda do tamanho certo)?
- [ ] O espectrograma mostra as camadas nas faixas planejadas (sub embaixo, detalhe em cima)?
      Nenhuma faixa vazia que deveria ter energia, nem agudo excessivo (> 8k) em som frequente?
- [ ] Pitch/filtro seguem a curva planejada (subida = recompensa, queda = perda/impacto)?
- [ ] Loop: emenda contínua no zoom, sem mudança de energia?
- [ ] Som frequente: curto, sem agudos estridentes, com variações?

### Etapa 6 — Ouvir e aprovar (usuário)
- Gere **2–3 opções** (seeds/parâmetros diferentes) e toque em sequência:
  `play_sequence([a, b, c])` ou `python3 .claude/skills/sound-design/scripts/soundkit.py play a.wav b.wav c.wav`.
  Avise antes: "vou tocar A, B, C nesta ordem" e descreva o que muda entre elas.
- Para sons de contexto, toque também **junto** do que convive com ele (ex.: `mix` do clique sobre a
  música) para avaliar a mixagem.
- Ajuste pelo feedback ("mais grave", "mais curto", "menos agudo") e repita.

### Etapa 7 — Export e integração
- One-shot: `save_wav("assets/audio/<cat>/<nome>.wav", x, kind)`.
- Variações: `save_variations(make, "assets/audio/ui/click.wav", "ui", 3, tres_path="assets/audio/ui/click.tres")`
  → WAVs + `AudioStreamRandomizer` (sorteio + pitch/volume aleatórios).
- Loop: `save_wav(..., loop=True)` grava o loop no WAV (Godot detecta).
- Música: loop inteiro e/ou `song.stems()` para camadas adaptativas (ver godot-audio.md).
- Rode a análise final: `soundkit.py analyze <wav> <kind> [--loop]`.

### Etapa 8 — Alimentar a biblioteca
Atualize `references/patterns/<slug>.md`: receita final (camadas e parâmetros), o que o usuário
pediu para mudar, o que funcionou. Decisão global nova → `style-guide.md`.

## API rápida (`scripts/soundkit.py`)

```python
# notas / escala
note("D4"); mtof(62); snap(1000)             # snap -> nota mais próxima da escala SFX do projeto
degree(5, 4, "lydian"); chord("D4", "maj7"); scale_midis("sfx")
# osciladores (freq pode ser número OU array/curva)
sine(f, dur); triangle(f, dur, steps=16); saw(f, dur); pulse(f, dur, duty=0.25); square(f, dur)
noise(dur, "white"|"pink"|"brown", seed); chip_noise(f, dur, short=False, seed)
fm(f, dur, ratio=3.5, index=env_ou_num); unison(saw, f, dur, voices=4, detune_cents=12, stereo=True)
# curvas / envelopes
sweep(f0, f1, dur); vibrato(f, dur, rate, depth_semi); arp([f1, f2, f3], step, dur); lfo(dur, rate, lo, hi, shape)
adsr(dur, a, d, s, r); decay(dur, tau); punch(dur, amount); env([(t, v), ...], dur, "exp")
# filtros / efeitos
lowpass(x, fc); highpass(x, fc); bandpass(x, lo, hi); svf(x, cutoff_curva, q, "lp"|"hp"|"bp"|"notch")
drive(x, amt); bitcrush(x, bits); decimate(x, k); tremolo(x, rate, depth); pitch_shift(x, semi)
delay(x, time, feedback, mix_, pingpong=True); reverb(x, size, damp, mix_); pan(x, pos); fade(x, fi, fo)
# montagem
mix([(x, t0, db), ...]); concat(a, b, gap=0.05); trim(x); make_loop(x, dur, crossfade); wrap_tail(x, dur)
# música
song = Song(bpm=96, bars=8); song.add("baixo", inst_triangle_bass(), "D2 - . D2 | A1 - . .", gain_db=-3)
song.add("kick", drum_kick(), "x...x...", drum=True); mus = song.render(loop=True, master_fx=...)
inst_pulse / inst_triangle_bass / inst_pad / inst_bell / inst_pluck / drum_kick / drum_snare / drum_hat / drum_chip
# análise / export / ouvir
analyze(x, kind, loop); lufs(x); band_energy(x); plot(x, png)
save_wav(path, x, kind, loop=False); save_variations(make, path, kind, n, tres_path=...)
play(path); play_sequence([a, b, c])
```
CLI: `soundkit.py analyze x.wav [kind] [--loop] | play a.wav b.wav | preset <nome> out.wav <kind> [seed] | scale [modo] | targets`.
Scripts devem ser **determinísticos** (sempre `seed`).
