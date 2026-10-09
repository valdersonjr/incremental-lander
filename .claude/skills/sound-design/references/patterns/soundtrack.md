# Trilha: título/hangar e voo

- **Slug**: soundtrack
- **kind**: music (estéreo, −18 LUFS; bus Music −6 dB no jogo; abaixa −9 dB durante jingles)
- **Evento/frequência**: `title` no menu inicial e no hangar; `flight` durante o run. Crossfade de 1,2 s; a mesma faixa
  não reinicia ao voltar (`Sound.music`).
- **Assets** ← `audio/src/music/soundtrack.py --export [title flight layers]`: `assets/audio/music/title.wav`,
  `assets/audio/music/flight.wav`, camadas `assets/audio/music/layer_luna.wav`, `assets/audio/music/layer_cogumelos.wav`,
  `assets/audio/music/layer_bolhas.wav`, `assets/audio/music/layer_jardim.wav`, `assets/audio/music/layer_sorvete.wav`,
  `assets/audio/music/layer_nuvens.wav`
- **2026-10-09 (auditoria)**: título 16 → 32 compassos (~91 s, parte B Gmaj7–A7–F#m7–Bm7); voo 16 → 48 compassos
  (~115 s, 3 blocos sobre a mesma progressão: A / A' com melodia nova e chimbal ativo / A'' sem bumbo nos 4 primeiros,
  arpejo invertido e a melodia antiga no fim); **camada do mundo** = contramelodia esparsa (tempos 2 e 4, nota longa
  no 2º compasso) de 16 compassos (1/3 do voo, cabe 3× exato: 1.693.440 × 3 amostras) em instrumento próprio, mono,
  −24 LUFS, tocada junto por `AudioStreamSynchronized` (Lua sinos FM · Cogumelos marimba · Bolhas seno que borbulha
  · Jardim flautinha de pulso 12,5% · Sorvete celesta FM 7 uma oitava acima · Nuvens pad de triângulo). O tema
  "troca de roupa" por mundo (Kirby/Mario/Banjo-Kazooie).

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
- 2026-10-09: auditoria — voo de 38 s igual em todos os mundos cansava; pedido "conserte tudo".

## Erros / avisos resolvidos
- Passa-baixa depois de `render(loop=True)` criou clique na emenda (filtro começa do zero) → filtro dentro do `master_fx`.
- Aviso "energia muda 11 dB na emenda" no voo: é o tempo 1 (bumbo + baixo) começando o loop — musical, não defeito
  (salto de amostra 0,0005).

- Aviso de loudness das camadas (−24 vs alvo −18 da música): proposital — são camada, não faixa.
- Emendas 3–6 dB nas camadas/título: nota do tempo 1 começando a frase (musical).

## Fontes
- https://splice.com/blog/adaptive-music-video-games/ — camadas por local (Banjo-Kazooie), música por fase (Mario)
- https://blog.criware.com/index.php/2020/04/20/dynamic-music-with-adx2-part1-vertical-layering/ — stems sincronizados, camadas entram/saem
- https://payhip.com/b/BdMWQ — música de idle: suave, não intrusiva, para sessões longas
- https://wondera.ai/tools/x-default/ugc/silent-snowfall-idle-game-ambient — BPM baixo, sino/kalimba, camadas que alternam
- https://payhip.com/b/cFzDI — trilha de idle em camadas que se combinam/alternam (trilha adaptativa sem fadiga)
