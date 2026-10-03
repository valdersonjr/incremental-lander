# Ambiência dos mundos (Lua, Silvânia, Docelândia, O Quarto)

- **Slug**: world-ambience
- **kind**: ambience (estéreo, −24 LUFS, pico ≤ −3 dBTP, loop de 24 s)
- **Evento/frequência**: toca o tempo todo no mundo atual (voo, título e hangar mostram o mundo); troca com crossfade
  de 1,2 s (`Sound.ambience(planeta)`).
- **Assets** ← `audio/src/ambience/world_ambience.py --export`: `assets/audio/ambience/luna.wav`,
  `assets/audio/ambience/ares.wav`, `assets/audio/ambience/kronos.wav`, `assets/audio/ambience/titan.wav`

## O que caracteriza o som (pesquisa)
- Duas famílias de camada: **cama contínua** (10–30 s, sem nada que "salte") + **eventos esparsos** (one-shots
  espalhados com intervalos, pan e volume variados) — é o que evita perceber a repetição.
- Loop da cama: crossfade na emenda; LFOs com número inteiro de ciclos no loop. Eventos: reverb e cauda dobrada.
- Variação nos eventos: pitch (na escala), volume e pan diferentes a cada ocorrência; nada rítmico (exceto o
  relógio do Quarto, que é a identidade do cômodo).
- Room tone (interiores) = zumbido elétrico + ar do cômodo + detalhes de objetos (relógio, rangidos).

## Receita final (camadas)
| Mundo | Cama | Eventos |
|---|---|---|
| Lua | unison seno D2 + triângulo A2 (respira 2×/loop) −9 dB + ar rosa LP 220–700 Hz | 6 estrondos distantes (marrom LP 140–260 + sub 80→38 Hz) −10..−4; 3 pings FM na escala −14..−9; reverb 0,85 |
| Silvânia | vento rosa BP 350–1100 Hz respirando + folhas (branco HP 2,5k com AM³) −6 + zumbido D3 baixo | 9 grupos de 2–4 piados (seno curto, notas 2,2–3,6 kHz da escala) −20..−12; reverb 0,55 |
| Docelândia | pad triângulo D-F#-A LP 900 −10 + ar rosa | 10 grupos de bolhas (blips seno subindo ×1,6) −10..−5; 4 caixinhas de música (FM ratio 4) −15..−10; reverb 0,6 |
| O Quarto | marrom LP 220 (cômodo) + zumbido D2/D3/A3 −15 | tique-taque a cada 1 s (BP 2,6k/2,1k) −8; 4 rangidos (FM ratio 1,41 com tremolo) −14..−9; reverb 0,35 |

## Feedback do usuário (o que mudou e por quê)
- 2026-10-03: aprovado no resumo do pacote de áudio ("Aprovado, integra").

## Erros / avisos resolvidos
- Reverb aplicada depois de fechar o loop e cama somada duas vezes no início (salto de 76 dB na emenda) → cama fecha
  por `make_loop` (crossfade 1,5 s); só os eventos ganham reverb e `wrap_tail`.
- Graves dominando (95% < 250 Hz) escondiam os eventos → camas −6..−9 dB, eventos +6..+8 dB.

## Fontes
- https://splice.com/blog/audio-soundscape-for-video-games — cama de 10–30 s + one-shots esparsos; tirar o que "salta" da cama; crossfade
- https://audiokinetic.com/ko/blog/designing-ambience-systems-in-wwise — cama + spots aleatórios (acesso bloqueado; título/resumo da busca)
- https://designingsound.org/2012/11/15/room-tone-emotional-tone-the-importance-of-hearing-ambience — room tone: zumbido elétrico, ar, objetos
