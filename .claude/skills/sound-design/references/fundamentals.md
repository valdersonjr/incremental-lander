# Fundamentos de sound design para jogos (ler SEMPRE)

## 1. Anatomia de um som: transiente → corpo → cauda
- **Transiente (ataque)**: os primeiros 1–30 ms. É o que o ouvido lê como "impacto" e **resposta
  imediata**. SFX de gameplay precisam de ataque rápido e zero silêncio inicial (< 10 ms).
- **Corpo**: a parte que identifica O QUE é o som (timbre, altura).
- **Cauda**: como o som morre (decay, reverb, detritos). Em ação rápida, **cauda curta**: caudas
  longas embolam quando o som se repete.
- Fonte: wayline.io (Game Audio), morphic.com (layering)

## 2. Camadas (layering) por faixa de frequência
| Camada | Faixa | Função | No soundkit |
|---|---|---|---|
| **Sub** | 30–80 Hz | peso, "thump" | `sine(sweep(110, 40, .3))` |
| **Grave/corpo** | 80–400 Hz | massa, ronco | `lowpass(noise(..,"brown"))`, `triangle` |
| **Médio (identidade)** | 400 Hz–3 kHz | o "o que é" | `pulse`, `saw` filtrado, `fm` |
| **Detalhe/definição** | 3–8 kHz | clique, crack, brilho | `highpass(noise)`, `chip_noise` |
| **Ar** | > 8 kHz | faísca, chiado | pouco! cansa em sons frequentes |
- Cada camada tem um trabalho; **não empilhe duas camadas na mesma faixa** sem motivo (embola).
- Camadas começam em tempos diferentes (crack 0 ms, corpo +5 ms, cauda +20 ms) → som que "se desdobra".
- Explosão = crack + pressão (corpo) + peso (sub) + detritos + espaço + decaimento.
  O crack é o que se lê como potência, não o volume.

## 3. Altura e movimento (linguagem emocional)
- **Pitch subindo** = ganho, sucesso, energia (coleta, upgrade, power-up).
- **Pitch descendo** = perda, dano, desligar, cair (hit, erro, motor desligando).
- **Intervalos**: quinta/quarta = positivo e estável; terça maior = alegre; segunda menor/trítono =
  tensão/erro. Arpejo ascendente na escala = recompensa.
- **Filtro abrindo** (cutoff subindo) = aproximação, carga, potência aumentando.
- SFX tonais **sempre na escala do projeto** (`snap`) → nunca desafinam contra a música.

## 4. Sons frequentes e fadiga (crítico em jogo incremental)
- Clique/compra podem tocar centenas de vezes por sessão. Eles devem ser: **curtos (40–150 ms),
  suaves (pouco > 5 kHz), sem transiente agressivo**, e com **2–3 variações** + pitch aleatório ±5%
  (`save_variations` + `AudioStreamRandomizer`).
- Recompensa grande (upgrade, marco) pode ser mais longa e brilhante — é rara.
- Hierarquia: quanto mais raro e importante o evento, mais longo/rico/alto o som.
- Fonte: discussões de design de idle/clicker (itch.io), gamedevacademy (AudioStreamRandomizer)

## 5. Loudness e mixagem
- Medida: **LUFS** (loudness percebido, ITU-R BS.1770) + **true peak** (picos entre amostras).
- Referências da indústria: ASWG-R001 (Sony) −24 LUFS para o jogo inteiro; assets individuais
  por volta de −16 (SFX/UI/música), picos < −3 dB (console). Indie varia muito.
- Este projeto usa os alvos por categoria do style-guide; o mix final é feito nos **buses do Godot**
  (Master/Music/SFX/UI/Ambience), não assando volume nos arquivos.
- Música no jogo fica mais baixa que num álbum: precisa deixar espaço para os SFX.
- Se o som não alcança o alvo de LUFS sem estourar o teto → ele tem picos demais (crest alto).
  Adense: `drive(x, 1.5–3)`, encurte o transiente ou reduza a camada de pico.
- Fonte: audiokinetic.com (loudness best practices), krotos.studio

## 6. Cliques e artefatos (evitar)
- **Clique no início/fim**: forma de onda começando/terminando longe do zero → sempre envelope com
  ataque ≥ 1–2 ms e fim em zero (`decay`, `fade`, `trim` já fazem isso).
- **Clique na emenda de loop**: descontinuidade entre último e primeiro sample → `make_loop`
  (crossfade) ou `wrap_tail` (música). Conferir no zoom da emenda.
- **DC offset**: onda deslocada do centro (pulso com duty ≠ 50%, ruído browniano) → highpass 20 Hz
  (o `normalize` já aplica).
- **Aliasing**: ondas ricas em harmônicos em notas agudas geram chiado metálico → soundkit usa
  PolyBLEP em `saw`/`pulse`; para "sujeira chip" proposital use `aa=False`, `decimate`, `bitcrush`.

## 7. Estética retro-synth espacial (nossa paleta)
- Base de chip: pulso (duty 12.5/25/50%), triângulo, ruído de chip → casa com a pixel art.
- Espaço: eco (`delay`), reverb grande (`reverb(size=.7+)`) e pads desafinados só em **música e
  ambiência**. SFX de gameplay ficam secos (reverb no Godot, via bus, se precisar).
- FM para sinos/metal/cristal (UI de recompensa, pickups raros).
- Ruído filtrado para tudo que é físico: propulsor, poeira, explosão, vento.

## 8. Como eu (Claude) reviso sem ouvir
- **Relatório**: LUFS, true peak, crest, centróide (brilho médio), % por banda, silêncio inicial, nível final, emenda.
- **Gráfico**: forma de onda (envelope), espectrograma log (camadas no tempo × frequência), zoom da emenda.
- Traduções úteis: centróide > 4 kHz = brilhante/estridente; banda "brilho>8k" > 10% em som frequente = cansativo;
  crest > 15 dB = pontudo (difícil de ouvir alto); sub+grave > 80% = abafado/pesado.
- Os números não substituem o ouvido: **a aprovação é sempre do usuário**.
