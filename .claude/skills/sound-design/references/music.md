# Música (composição por código)

## Tonalidade do projeto (travada — ver style-guide)
- Centro tonal **D**. Modos permitidos:
  - **D lídio** (D E F# G# A B C#): exploração, espaço, maravilha (4ª aumentada = "sci-fi").
  - **D maior** (D E F# G A B C#): menus, progresso, vitória.
  - **B menor** (B C# D E F# G A — relativo de D maior): tensão, perigo, combustível acabando.
- Todos contêm a **pentatônica D E F# A B**, que é a escala dos SFX → SFX nunca desafinam.

## Estrutura para jogo
- Loops de **16–32 compassos** são o padrão para fases. Estrutura curta: A (8) + A' (8) ou A + B.
- "**Loop, depois varie**": repita o padrão 2x, mude uma nota, repita, mude outra → cativante sem cansar.
- Jogo incremental é jogado por horas: preferir **faixas calmas, sem melodia gritante**, com loops
  longos (≥ 60 s) ou camadas que entram/saem conforme o progresso.
- **Stems** (`song.stems()`): exporte faixas separadas para música adaptativa — ex.: camada de
  percussão entra quando o lander está em voo, pad some no menu.

## Arranjo de chip (NES: 2 pulsos + triângulo + ruído)
| Função | Instrumento soundkit | Dicas |
|---|---|---|
| Melodia | `inst_pulse(duty=.25/.125, vib=.2)` ou `inst_bell` | poucas notas, motivos curtos e repetíveis |
| Harmonia | arpejo rápido (`"D4 F#4 A4 C#5"` em 1/16) em `inst_pulse(.5)` | chips não tocam acordes: arpeje |
| Baixo | `inst_triangle_bass()` | tônica + quinta, ritmo simples; "melodia + baixo simples = 80% de um bom chiptune" |
| Percussão | `drum_chip` / `drum_kick` / `drum_snare` / `drum_hat` | bumbo = queda rápida de pitch |
| Espaço (nosso extra) | `inst_pad` + `reverb(size .7)` + `delay` pingpong no arpejo | é o que dá o "espacial" |
- Eco de chip: repetir a nota 1/8 depois com volume menor (ou `delay` na faixa).
- Duty cycle diferente por seção muda o timbre sem novo instrumento.

## Tempo e clima
| Clima | BPM | Modo | Instrumentação |
|---|---|---|---|
| Menu / hangar | 80–95 | D maior | pad + sino + baixo suave, sem bateria ou só hat |
| Exploração / voo | 90–110 | D lídio | arpejo com eco, pad, baixo, kick leve |
| Tensão (pouco combustível, perigo) | 110–130 | B menor | pulsos 12.5%, baixo mais ativo, hat 1/16 |
| Vitória / marco (jingle) | livre | D maior | arpejo ascendente + acorde final + sino |

## Progressões úteis (graus → acordes em D)
- Lídio flutuante: **D – E – D – E** (I–II maior: assinatura do lídio), ou D – E – Bm – A.
- Maior: D – A – Bm – G (I–V–vi–IV), D – G – A – D.
- Menor tenso: Bm – G – D – A, Bm – F#m (tensão por v menor), pedal em B.
- Space ambient: acordes maj7/add9 longos (`chord("D3","maj7")`), mudanças a cada 2–4 compassos.

## Loop técnico
- `song.render(loop=True)` dobra caudas (reverb/eco/release) para o início → emenda perfeita.
- Duração do loop = compassos exatos (`song.dur`). Conferir a emenda no gráfico (`loop=True`).
- Export: WAV com loop (Godot detecta). Sem ffmpeg não há OGG; WAV estéreo 44.1k ≈ 10 MB/min —
  aceitável para poucas faixas; para reduzir, importe no Godot com compressão QOA.

Fontes: wayline.io (chiptune), soundfly (arranging in four channels), chiptuna guides,
indietips (space soundtracks: Lydian, pads, arpeggiators, reverb/delay).
