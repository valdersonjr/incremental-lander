# Ambiência dos mundos (Lua, Cogumelos, Bolhas, Jardim, Sorvete, Nuvens)

- **Slug**: world-ambience
- **kind**: ambience (estéreo, −24 LUFS, pico ≤ −3 dBTP, loop de 24 s)
- **Evento/frequência**: toca o tempo todo no mundo atual (voo, título e hangar mostram o mundo); troca com crossfade
  de 1,2 s (`Sound.ambience(planeta)`).
- **Assets** ← `audio/src/ambience/world_ambience.py --export [mundo]`: `assets/audio/ambience/luna.wav`,
  `assets/audio/ambience/cogumelos.wav`, `assets/audio/ambience/bolhas.wav`, `assets/audio/ambience/jardim.wav`,
  `assets/audio/ambience/sorvete.wav`, `assets/audio/ambience/nuvens.wav` (os mundos antigos Silvânia/Docelândia/Quarto
  saíram em 2026-10-06; a receita deles abaixo fica de referência)

## O que caracteriza o som (pesquisa)
- Duas famílias de camada: **cama contínua** (10–30 s, sem nada que "salte") + **eventos esparsos** (one-shots
  espalhados com intervalos, pan e volume variados) — é o que evita perceber a repetição.
- Loop da cama: crossfade na emenda; LFOs com número inteiro de ciclos no loop. Eventos: reverb e cauda dobrada.
- Variação nos eventos: pitch (na escala), volume e pan diferentes a cada ocorrência; nada rítmico (exceto o
  relógio do Quarto, que é a identidade do cômodo).
- Room tone (interiores) = zumbido elétrico + ar do cômodo + detalhes de objetos (relógio, rangidos).

## Receita final (camadas)
Mundos atuais (2026-10-09, auditoria de som; fofos, só cenário). Eventos espalhados em 0,8 s … LOOP−1,5 s (nada na
emenda), drone −18 dB nos mundos novos (o que caracteriza o mundo são os eventos), reverb nos eventos.
| Mundo | Cama | Eventos |
|---|---|---|
| Lua de queijo | unison seno D2 + triângulo A2 respirando −9 (sem ar: "vento chato", 2026-10-09) | 5 picaretas da mina (FM 2,76, 2–3 tlins) −10..−5; 3 sinos FM −11..−6; reverb 0,85 (sai a batalha) |
| Cogumelos | drone D2/A2 −18 + folhas (rosa LP 400–1400 respirando 4×) −9 | 7 passarinhos (2–4 piados 1,8–3,2 kHz na escala) −9..−3; 6 gotas (seno ×2) −12..−6 |
| Bolhas | drone D2/A2 −16 + água (marrom LP 180–420 respirando) −11 | 14 cachinhos de bolhas −4..0; 2 cantos de baleia (seno D3→A3→F#3, LP 900) −14..−10; reverb 0,9 |
| Jardim | drone D3/A3 −18 + brisa rosa LP 500–1800 −8 | 4 abelhas (serra BP 300–2,5k com AM 45 Hz, vibrato) −9..−4; 6 passarinhos −9..−4 |
| Sorvete | drone D3/A3 −18 + ar frio (rosa BP 1,5–3,5k) −10 + ar grave −12 | 7 tilintares de gelo (sinos FM 2–3,6 kHz) −9..−4; 2 rangidos (FM 1,41 220→160 Hz) −14..−10 |
| Nuvens | drone A2/D3 −18 + vento rosa LP 600–2200 −6 | 4 sinos de vento (3–5 sinos 1,2–2,6 kHz) −8..−3; 3 "bés" de carneirinho longe (LP 1,8k) −12..−8 |

Mundos antigos (referência):
| Mundo | Cama | Eventos |
|---|---|---|
| Lua | unison seno D2 + triângulo A2 (respira 2×/loop) −9 dB + ar rosa LP 220–700 Hz | 6 estrondos distantes (marrom LP 140–260 + sub 80→38 Hz) −10..−4; 3 pings FM na escala −14..−9; reverb 0,85 |
| Silvânia | vento rosa BP 350–1100 Hz respirando + folhas (branco HP 2,5k com AM³) −6 + zumbido D3 baixo | 9 grupos de 2–4 piados (seno curto, notas 2,2–3,6 kHz da escala) −20..−12; reverb 0,55 |
| Docelândia | pad triângulo D-F#-A LP 900 −10 + ar rosa | 10 grupos de bolhas (blips seno subindo ×1,6) −10..−5; 4 caixinhas de música (FM ratio 4) −15..−10; reverb 0,6 |
| O Quarto | marrom LP 220 (cômodo) + zumbido D2/D3/A3 −15 | tique-taque a cada 1 s (BP 2,6k/2,1k) −8; 4 rangidos (FM ratio 1,41 com tremolo) −14..−9; reverb 0,35 |

## Feedback do usuário (o que mudou e por quê)
- 2026-10-03: aprovado no resumo do pacote de áudio ("Aprovado, integra").
- 2026-10-09: auditoria de som — 5 dos 6 mundos estavam sem ambiência; a Lua perdeu os estrondos de batalha
  (não combinam com a Lua de queijo fofa) e ganhou picaretas da mina.

- 2026-10-09: "esse barulho de vento no fundo tá chato" (tela inicial, quando o volume voltou de 0) → a Lua perdeu o
  ar de ruído rosa e a tela inicial toca só o tema, sem ambiência. Ruído de ar contínuo cansa: usar só onde o vento
  é a identidade do mundo (Nuvens, Jardim), e baixo.

## Erros / avisos resolvidos
- Reverb aplicada depois de fechar o loop e cama somada duas vezes no início (salto de 76 dB na emenda) → cama fecha
  por `make_loop` (crossfade 1,5 s); só os eventos ganham reverb e `wrap_tail`.
- Graves dominando (95% < 250 Hz) escondiam os eventos → camas −6..−9 dB, eventos +6..+8 dB.

- Eventos caindo na emenda (aviso 4,3 dB / salto 0,05) → `_place` só espalha entre 0,8 s e LOOP − 1,5 s.
- Drone com 80% da energia escondia passarinhos/bolhas → drone −18, eventos +4..+6 dB.

## Fontes
- https://arxiv.org/pdf/2011.05538 — bolha: seno curto com pitch modulado (cachinhos de bolhas)
- https://splice.com/blog/audio-soundscape-for-video-games — cama de 10–30 s + one-shots esparsos; tirar o que "salta" da cama; crossfade
- https://audiokinetic.com/ko/blog/designing-ambience-systems-in-wwise — cama + spots aleatórios (acesso bloqueado; título/resumo da busca)
- https://designingsound.org/2012/11/15/room-tone-emotional-tone-the-importance-of-hearing-ambience — room tone: zumbido elétrico, ar, objetos
