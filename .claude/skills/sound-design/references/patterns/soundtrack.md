# Trilha: título/hangar e voo

- **Slug**: soundtrack
- **kind**: music (estéreo, −18 LUFS; bus Music −6 dB no jogo; abaixa −9 dB durante jingles)
- **Evento/frequência**: `title` no menu inicial e no hangar; `flight` durante o run. Crossfade de 1,2 s; a mesma faixa
  não reinicia ao voltar (`Sound.music`).
- **Assets** ← `audio/src/music/soundtrack.py --export`: `assets/audio/music/title.wav`, `assets/audio/music/flight.wav`

## O que caracteriza o som (pesquisa)
- Jogo incremental = sessões longas: música calma, sem melodia gritante, BPM baixo; "loop, depois varie" (A A' B A'').
- Instrumentos melódicos suaves (sino/vibrafone-like) acalmam sem tirar o foco; camadas que entram e saem seguram a
  atenção sem fadiga.
- D lídio = espaço/maravilha (II maior E); D maior = menu/progresso.

## Música
- **title**: D maior, 84 BPM, 16 compassos (45,7 s). Pad Dmaj7–Bm7–Gmaj7–A(add9) (2 compassos cada) −7, baixo triângulo
  −8, sino FM com motivo de 8 compassos respondido (A A') + eco pingue-pongue de 3/4 de tempo −12, sem bateria;
  reverb 0,8 + LP 9k no master.
- **flight**: D lídio, 100 BPM, 16 compassos (38,4 s) = D D E E ×2 | Bm Bm A A | D D E E. Arpejo pulso 25% em colcheias com
  eco pingue-pongue −13, pad −11, baixo triângulo sincopado −6, bumbo nos tempos 1 e 3 −9, chimbal em contratempo −21;
  melodia de pulso 12,5% só nos compassos 13–16 (variação) −15.

## Feedback do usuário (o que mudou e por quê)
- 2026-10-03: aprovado no resumo do pacote de áudio.

## Erros / avisos resolvidos
- Passa-baixa depois de `render(loop=True)` criou clique na emenda (filtro começa do zero) → filtro dentro do `master_fx`.
- Aviso "energia muda 11 dB na emenda" no voo: é o tempo 1 (bumbo + baixo) começando o loop — musical, não defeito
  (salto de amostra 0,0005).

## Fontes
- https://payhip.com/b/BdMWQ — música de idle: suave, não intrusiva, para sessões longas
- https://wondera.ai/tools/x-default/ugc/silent-snowfall-idle-game-ambient — BPM baixo, sino/kalimba, camadas que alternam
- https://payhip.com/b/cFzDI — trilha de idle em camadas que se combinam/alternam (trilha adaptativa sem fadiga)
